// SPDX-License-Identifier: PMPL-1.0-or-later

//! VM Inspector Tauri commands — in-process virtual machine with stepping,
//! reverse execution, program loading, and state export.
//!
//! The VM maintains a ring buffer of snapshots (max 10,000) so that
//! `step_backward` can restore previous states. Instructions are parsed
//! from a simple assembly text format and tagged with tier assignments
//! (0..4) for the five-tier instruction taxonomy used by the panel.
//!
//! Commands:
//!   - `vm_inspector_read_state`: Return current VM state as JSON.
//!   - `vm_inspector_step_forward`: Execute one instruction forward.
//!   - `vm_inspector_step_backward`: Reverse one instruction.
//!   - `vm_inspector_run`: Run until breakpoint or end of program.
//!   - `vm_inspector_load_program`: Parse assembly text into instructions.
//!   - `vm_inspector_export_snapshot`: Export full VM state dump.
//!   - `vm_inspector_read_file`: Read VM state from a JSON file on disk.

use std::collections::VecDeque;
use std::fs;
use std::sync::Mutex;

use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Maximum number of snapshots retained for reverse execution.
const MAX_HISTORY: usize = 10_000;

/// Memory size in cells.
const MEMORY_SIZE: usize = 256;

/// A single VM instruction with its mnemonic, optional operand, and tier.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Instruction {
    /// The instruction mnemonic (e.g. "PUSH", "ADD").
    pub mnemonic: String,
    /// Optional operand (e.g. the value for PUSH).
    pub operand: Option<i64>,
    /// Tier assignment (0..4) for the five-tier instruction taxonomy.
    pub tier: u8,
}

/// A snapshot of VM state captured before each instruction execution,
/// enabling reverse stepping.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Snapshot {
    /// Program counter at the time of the snapshot.
    pub pc: usize,
    /// Stack contents.
    pub stack: Vec<i64>,
    /// Memory contents.
    pub memory: Vec<i64>,
    /// Total steps executed.
    pub total_steps: u64,
    /// Per-tier execution counts.
    pub tier_counts: [u64; 5],
    /// Channel buffer contents.
    pub channels: Vec<i64>,
}

/// Full VM state held in the static mutex.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VmState {
    /// Program counter — index into `instructions`.
    pub pc: usize,
    /// Operand stack.
    pub stack: Vec<i64>,
    /// Flat memory array (256 cells).
    pub memory: Vec<i64>,
    /// Loaded instruction sequence.
    pub instructions: Vec<Instruction>,
    /// Whether the VM is currently running (not halted).
    pub running: bool,
    /// Total instructions executed since last reset.
    pub total_steps: u64,
    /// Per-tier execution counts (tiers 0..4).
    pub tier_counts: [u64; 5],
    /// Ring buffer of pre-execution snapshots for reverse stepping.
    pub history: VecDeque<Snapshot>,
    /// Channel buffer for SEND/RECV inter-VM communication (FIFO queue).
    pub channels: Vec<i64>,
}

impl Default for VmState {
    fn default() -> Self {
        Self {
            pc: 0,
            stack: Vec::new(),
            memory: vec![0i64; MEMORY_SIZE],
            instructions: Vec::new(),
            running: false,
            total_steps: 0,
            tier_counts: [0u64; 5],
            history: VecDeque::new(),
            channels: Vec::new(),
        }
    }
}

/// Global VM state, shared across all Tauri command invocations.
static VM: Lazy<Mutex<VmState>> = Lazy::new(|| Mutex::new(VmState::default()));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Serialise the current VM state to a JSON string for the frontend.
/// Excludes the full history to keep the payload small.
fn state_to_json(vm: &VmState) -> Result<String, String> {
    let payload = serde_json::json!({
        "pc": vm.pc,
        "stack": vm.stack,
        "memory": vm.memory,
        "instructions": vm.instructions,
        "running": vm.running,
        "total_steps": vm.total_steps,
        "tier_counts": vm.tier_counts,
        "history_len": vm.history.len(),
        "channels": vm.channels,
    });
    serde_json::to_string(&payload)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Capture a pre-execution snapshot and push it onto the history ring buffer.
fn capture_snapshot(vm: &mut VmState) {
    let snap = Snapshot {
        pc: vm.pc,
        stack: vm.stack.clone(),
        memory: vm.memory.clone(),
        total_steps: vm.total_steps,
        tier_counts: vm.tier_counts,
        channels: vm.channels.clone(),
    };
    if vm.history.len() >= MAX_HISTORY {
        vm.history.pop_front();
    }
    vm.history.push_back(snap);
}

/// Assign a tier (0..4) based on the instruction mnemonic.
///
/// Tier taxonomy:
///   0 — Data movement: PUSH, POP, LOAD, STORE, SWAP
///   1 — Arithmetic:    ADD, SUB, MUL, DIV, NEGATE
///   2 — Bitwise/logic: XOR, AND, OR, FLIP, ROL, ROR
///   3 — Control flow:  IF_ZERO, IF_POS, LOOP, CALL, NOOP
///   4 — Communication: SEND, RECV
fn tier_for_mnemonic(mnemonic: &str) -> u8 {
    match mnemonic {
        "PUSH" | "POP" | "LOAD" | "STORE" | "SWAP" => 0,
        "ADD" | "SUB" | "MUL" | "DIV" | "NEGATE" => 1,
        "XOR" | "AND" | "OR" | "FLIP" | "ROL" | "ROR" => 2,
        "IF_ZERO" | "IF_POS" | "JNZ" | "JLE" | "LOOP" | "CALL" | "NOOP" => 3,
        "SEND" | "RECV" => 4,
        _ => 3, // Default unknown mnemonics to control tier
    }
}

/// Execute one instruction on the VM. Returns `Ok(())` on success,
/// `Err(reason)` if the VM should halt (e.g. end of program, stack
/// underflow, division by zero).
fn execute_one(vm: &mut VmState) -> Result<(), String> {
    if vm.pc >= vm.instructions.len() {
        vm.running = false;
        return Err("End of program".to_string());
    }

    let instr = vm.instructions[vm.pc].clone();
    let tier = instr.tier as usize;

    match instr.mnemonic.as_str() {
        "PUSH" => {
            let val = instr.operand.unwrap_or(0);
            vm.stack.push(val);
        }
        "POP" => {
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on POP".to_string());
            }
            vm.stack.pop();
        }
        "ADD" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on ADD".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let b = vm.stack.pop().expect("ADD: stack len >= 2");
            let a = vm.stack.pop().expect("ADD: stack len >= 2");
            vm.stack.push(a.wrapping_add(b));
        }
        "SUB" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on SUB".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let b = vm.stack.pop().expect("SUB: stack len >= 2");
            let a = vm.stack.pop().expect("SUB: stack len >= 2");
            vm.stack.push(a.wrapping_sub(b));
        }
        "NOOP" => {
            // No operation — just advances the program counter.
        }
        "SWAP" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on SWAP".to_string());
            }
            let len = vm.stack.len();
            vm.stack.swap(len - 1, len - 2);
        }
        "NEGATE" => {
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on NEGATE".to_string());
            }
            let len = vm.stack.len();
            vm.stack[len - 1] = vm.stack[len - 1].wrapping_neg();
        }
        "MUL" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on MUL".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let b = vm.stack.pop().expect("MUL: stack len >= 2");
            let a = vm.stack.pop().expect("MUL: stack len >= 2");
            vm.stack.push(a.wrapping_mul(b));
        }
        "DIV" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on DIV".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let b = vm.stack.pop().expect("DIV: stack len >= 2");
            if b == 0 {
                vm.running = false;
                return Err("Division by zero".to_string());
            }
            let a = vm.stack.pop().expect("DIV: stack len >= 2");
            vm.stack.push(a.wrapping_div(b));
        }
        "LOAD" => {
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on LOAD".to_string());
            }
            // SAFETY: non-empty checked above.
            let addr = vm.stack.pop().expect("LOAD: stack non-empty") as usize;
            if addr >= MEMORY_SIZE {
                vm.running = false;
                return Err(format!("LOAD address out of bounds: {addr}"));
            }
            vm.stack.push(vm.memory[addr]);
        }
        "STORE" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on STORE".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let addr = vm.stack.pop().expect("STORE: stack len >= 2") as usize;
            let val = vm.stack.pop().expect("STORE: stack len >= 2");
            if addr >= MEMORY_SIZE {
                vm.running = false;
                return Err(format!("STORE address out of bounds: {addr}"));
            }
            vm.memory[addr] = val;
        }
        "XOR" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on XOR".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let b = vm.stack.pop().expect("XOR: stack len >= 2");
            let a = vm.stack.pop().expect("XOR: stack len >= 2");
            vm.stack.push(a ^ b);
        }
        "AND" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on AND".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let b = vm.stack.pop().expect("AND: stack len >= 2");
            let a = vm.stack.pop().expect("AND: stack len >= 2");
            vm.stack.push(a & b);
        }
        "OR" => {
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on OR".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let b = vm.stack.pop().expect("OR: stack len >= 2");
            let a = vm.stack.pop().expect("OR: stack len >= 2");
            vm.stack.push(a | b);
        }
        "FLIP" => {
            // Bitwise NOT of top of stack.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on FLIP".to_string());
            }
            let len = vm.stack.len();
            vm.stack[len - 1] = !vm.stack[len - 1];
        }
        "ROL" => {
            // Rotate left by 1 bit.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on ROL".to_string());
            }
            let len = vm.stack.len();
            vm.stack[len - 1] = vm.stack[len - 1].rotate_left(1);
        }
        "ROR" => {
            // Rotate right by 1 bit.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on ROR".to_string());
            }
            let len = vm.stack.len();
            vm.stack[len - 1] = vm.stack[len - 1].rotate_right(1);
        }
        "IF_ZERO" => {
            // Conditional jump — skip next instruction if TOS != 0.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on IF_ZERO".to_string());
            }
            // SAFETY: non-empty checked above.
            let val = vm.stack.pop().expect("IF_ZERO: stack non-empty");
            if val != 0 {
                // Skip next instruction by incrementing pc an extra time.
                vm.pc += 1;
            }
        }
        "IF_POS" => {
            // Conditional jump — skip next instruction if TOS <= 0.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on IF_POS".to_string());
            }
            // SAFETY: non-empty checked above.
            let val = vm.stack.pop().expect("IF_POS: stack non-empty");
            if val <= 0 {
                vm.pc += 1;
            }
        }
        "JNZ" => {
            // Jump if Not Zero — pop TOS, if non-zero jump to operand address.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on JNZ".to_string());
            }
            // SAFETY: non-empty checked above.
            let val = vm.stack.pop().expect("JNZ: stack non-empty");
            if val != 0 {
                let target = instr.operand.unwrap_or(0) as usize;
                if target > vm.instructions.len() {
                    vm.running = false;
                    return Err(format!("JNZ target out of bounds: {target}"));
                }
                // Set pc to target - 1 because pc is incremented after match.
                vm.pc = target.wrapping_sub(1);
            }
        }
        "JLE" => {
            // Jump if Less or Equal — pop two values, if top <= second jump
            // to operand address.
            if vm.stack.len() < 2 {
                vm.running = false;
                return Err("Stack underflow on JLE".to_string());
            }
            // SAFETY: length >= 2 checked above.
            let top = vm.stack.pop().expect("JLE: stack len >= 2");
            let second = vm.stack.pop().expect("JLE: stack len >= 2");
            if top <= second {
                let target = instr.operand.unwrap_or(0) as usize;
                if target > vm.instructions.len() {
                    vm.running = false;
                    return Err(format!("JLE target out of bounds: {target}"));
                }
                // Set pc to target - 1 because pc is incremented after match.
                vm.pc = target.wrapping_sub(1);
            }
        }
        "LOOP" => {
            // Decrement TOS and loop — if TOS > 0 after decrement, jump to
            // operand address; otherwise pop and fall through.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on LOOP".to_string());
            }
            let len = vm.stack.len();
            vm.stack[len - 1] = vm.stack[len - 1].wrapping_sub(1);
            if vm.stack[len - 1] > 0 {
                let target = instr.operand.unwrap_or(0) as usize;
                if target > vm.instructions.len() {
                    vm.running = false;
                    return Err(format!("LOOP target out of bounds: {target}"));
                }
                // Set pc to target - 1 because pc is incremented after match.
                vm.pc = target.wrapping_sub(1);
            } else {
                // Counter exhausted — pop and continue.
                vm.stack.pop();
            }
        }
        "CALL" => {
            // Subroutine call — push return address (pc + 1) onto stack,
            // then jump to operand address.
            let target = instr.operand.unwrap_or(0) as usize;
            if target > vm.instructions.len() {
                vm.running = false;
                return Err(format!("CALL target out of bounds: {target}"));
            }
            // Push return address (the instruction after this CALL).
            vm.stack.push((vm.pc + 1) as i64);
            // Set pc to target - 1 because pc is incremented after match.
            vm.pc = target.wrapping_sub(1);
        }
        "SEND" => {
            // Send to channel — pop TOS and push it onto the channel buffer.
            if vm.stack.is_empty() {
                vm.running = false;
                return Err("Stack underflow on SEND".to_string());
            }
            // SAFETY: non-empty checked above.
            let val = vm.stack.pop().expect("SEND: stack non-empty");
            vm.channels.push(val);
        }
        "RECV" => {
            // Receive from channel — pop first value from channel buffer
            // and push onto stack. If channel is empty, pushes 0.
            let val = if vm.channels.is_empty() {
                0
            } else {
                vm.channels.remove(0)
            };
            vm.stack.push(val);
        }
        other => {
            return Err(format!("Unknown instruction: {other}"));
        }
    }

    vm.pc += 1;
    vm.total_steps += 1;
    if tier < 5 {
        vm.tier_counts[tier] += 1;
    }

    Ok(())
}

// ---------------------------------------------------------------------------
// Tauri commands
// ---------------------------------------------------------------------------

/// Read the current VM state. Returns JSON with pc, stack, memory, running
/// status, instruction list, step counts, and history length.
#[tauri::command]
pub async fn vm_inspector_read_state() -> Result<String, String> {
    let vm = VM.lock().map_err(|e| format!("Lock poisoned: {e}"))?;
    state_to_json(&vm)
}

/// Execute one instruction forward. Captures a snapshot before execution
/// so that `step_backward` can restore it.
#[tauri::command]
pub async fn vm_inspector_step_forward() -> Result<String, String> {
    let mut vm = VM.lock().map_err(|e| format!("Lock poisoned: {e}"))?;
    capture_snapshot(&mut vm);
    execute_one(&mut vm)?;
    state_to_json(&vm)
}

/// Reverse one instruction by restoring the most recent snapshot from
/// the history ring buffer.
#[tauri::command]
pub async fn vm_inspector_step_backward() -> Result<String, String> {
    let mut vm = VM.lock().map_err(|e| format!("Lock poisoned: {e}"))?;
    let snap = vm.history.pop_back()
        .ok_or_else(|| "No history to reverse".to_string())?;
    vm.pc = snap.pc;
    vm.stack = snap.stack;
    vm.memory = snap.memory;
    vm.total_steps = snap.total_steps;
    vm.tier_counts = snap.tier_counts;
    vm.channels = snap.channels;
    state_to_json(&vm)
}

/// Run the VM until end of program or error (simulates hitting a
/// breakpoint). Executes up to 100,000 instructions to prevent
/// infinite loops.
#[tauri::command]
pub async fn vm_inspector_run() -> Result<String, String> {
    let mut vm = VM.lock().map_err(|e| format!("Lock poisoned: {e}"))?;
    vm.running = true;

    let max_steps = 100_000u64;
    let mut steps_this_run = 0u64;

    while vm.running && steps_this_run < max_steps {
        capture_snapshot(&mut vm);
        match execute_one(&mut vm) {
            Ok(()) => {}
            Err(_) => break,
        }
        steps_this_run += 1;
    }

    vm.running = false;
    state_to_json(&vm)
}

/// Parse assembly text into an instruction list and load it into the VM.
/// Resets VM state (pc, stack, memory, history) but preserves nothing from
/// the previous program.
///
/// Each line is one instruction: `MNEMONIC [OPERAND]`.
/// Blank lines and lines starting with `#` or `;` are skipped.
///
/// Supported mnemonics: ADD, SUB, PUSH, POP, LOAD, STORE, SWAP, NEGATE,
/// NOOP, XOR, FLIP, ROL, ROR, AND, OR, MUL, DIV, IF_ZERO, IF_POS, JNZ,
/// JLE, LOOP, CALL, SEND, RECV.
///
/// Returns a JSON array of `Instruction` objects with tier assignments.
#[tauri::command]
pub async fn vm_inspector_load_program(assembly: String) -> Result<String, String> {
    let mut instructions = Vec::new();

    for (line_num, raw_line) in assembly.lines().enumerate() {
        let line = raw_line.trim();

        // Skip blank lines and comments.
        if line.is_empty() || line.starts_with('#') || line.starts_with(';') {
            continue;
        }

        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }

        let mnemonic = parts[0].to_uppercase();

        // Validate mnemonic.
        let valid = matches!(
            mnemonic.as_str(),
            "ADD" | "SUB" | "PUSH" | "POP" | "LOAD" | "STORE" | "SWAP"
            | "NEGATE" | "NOOP" | "XOR" | "FLIP" | "ROL" | "ROR"
            | "AND" | "OR" | "MUL" | "DIV" | "IF_ZERO" | "IF_POS"
            | "JNZ" | "JLE" | "LOOP" | "CALL" | "SEND" | "RECV"
        );
        if !valid {
            return Err(format!(
                "Line {}: unknown mnemonic '{}'",
                line_num + 1,
                mnemonic
            ));
        }

        // Parse optional operand.
        let operand = if parts.len() > 1 {
            Some(parts[1].parse::<i64>().map_err(|e| {
                format!("Line {}: invalid operand '{}': {e}", line_num + 1, parts[1])
            })?)
        } else {
            None
        };

        let tier = tier_for_mnemonic(&mnemonic);
        instructions.push(Instruction {
            mnemonic,
            operand,
            tier,
        });
    }

    // Reset VM state with new program.
    let mut vm = VM.lock().map_err(|e| format!("Lock poisoned: {e}"))?;
    *vm = VmState {
        instructions: instructions.clone(),
        ..VmState::default()
    };

    serde_json::to_string(&instructions)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Export the full current VM state as JSON, including the complete
/// history buffer.
#[tauri::command]
pub async fn vm_inspector_export_snapshot() -> Result<String, String> {
    let vm = VM.lock().map_err(|e| format!("Lock poisoned: {e}"))?;
    serde_json::to_string(&*vm)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Read VM state from a JSON file on disk. Parses the file as a
/// `VmState` and loads it into the global VM, replacing the current
/// state entirely.
#[tauri::command]
pub async fn vm_inspector_read_file(path: String) -> Result<String, String> {
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Cannot read '{}': {e}", path))?;
    let loaded: VmState = serde_json::from_str(&content)
        .map_err(|e| format!("Cannot parse VM state: {e}"))?;

    let mut vm = VM.lock().map_err(|e| format!("Lock poisoned: {e}"))?;
    *vm = loaded;

    state_to_json(&vm)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use once_cell::sync::Lazy;

    /// Serialise tests that share the global VM to prevent race conditions.
    static TEST_LOCK: Lazy<std::sync::Mutex<()>> = Lazy::new(|| std::sync::Mutex::new(()));

    /// Helper: reset the global VM to default state.
    /// Recovers from a poisoned mutex (previous test panic).
    fn reset_vm() {
        let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
        *vm = VmState::default();
    }

    /// Helper: load a program into the global VM from a vec of instructions.
    /// Recovers from a poisoned mutex (previous test panic).
    fn load_instructions(instrs: Vec<Instruction>) {
        let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
        *vm = VmState {
            instructions: instrs,
            ..VmState::default()
        };
    }

    /// Helper: create an instruction with no operand.
    fn instr(mnemonic: &str) -> Instruction {
        Instruction {
            mnemonic: mnemonic.to_string(),
            operand: None,
            tier: tier_for_mnemonic(mnemonic),
        }
    }

    /// Helper: create an instruction with an operand.
    fn instr_op(mnemonic: &str, operand: i64) -> Instruction {
        Instruction {
            mnemonic: mnemonic.to_string(),
            operand: Some(operand),
            tier: tier_for_mnemonic(mnemonic),
        }
    }

    #[test]
    fn test_default_state() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        let vm = VM.lock().unwrap_or_else(|e| e.into_inner());
        assert_eq!(vm.pc, 0);
        assert!(vm.stack.is_empty());
        assert_eq!(vm.memory.len(), MEMORY_SIZE);
        assert!(!vm.running);
        assert_eq!(vm.total_steps, 0);
    }

    #[test]
    fn test_push_and_pop() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 42),
            instr_op("PUSH", 17),
            instr("POP"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap();
            assert_eq!(vm.stack, vec![42]);

            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap();
            assert_eq!(vm.stack, vec![42, 17]);

            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap();
            assert_eq!(vm.stack, vec![42]);
        }
    }

    #[test]
    fn test_add() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 10),
            instr_op("PUSH", 20),
            instr("ADD"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![30]);
            assert_eq!(vm.total_steps, 3);
        }
    }

    #[test]
    fn test_sub() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 50),
            instr_op("PUSH", 8),
            instr("SUB"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![42]);
        }
    }

    #[test]
    fn test_swap() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 1),
            instr_op("PUSH", 2),
            instr("SWAP"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![2, 1]);
        }
    }

    #[test]
    fn test_noop() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![instr("NOOP"), instr("NOOP")]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap();
            assert_eq!(vm.pc, 1);
            assert!(vm.stack.is_empty());
        }
    }

    #[test]
    fn test_negate() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![instr_op("PUSH", 7), instr("NEGATE")]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..2 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![-7]);
        }
    }

    #[test]
    fn test_step_backward_restores_state() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 100),
            instr_op("PUSH", 200),
            instr("ADD"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            // Execute all three instructions, capturing snapshots.
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![300]);
            assert_eq!(vm.pc, 3);

            // Step backward once — should undo the ADD.
            let snap = vm.history.pop_back().unwrap();
            vm.pc = snap.pc;
            vm.stack = snap.stack;
            vm.total_steps = snap.total_steps;
            assert_eq!(vm.stack, vec![100, 200]);
            assert_eq!(vm.pc, 2);
        }
    }

    #[test]
    fn test_load_and_store() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 99),   // value to store
            instr_op("PUSH", 10),   // address
            instr("STORE"),         // mem[10] = 99
            instr_op("PUSH", 10),   // address to load
            instr("LOAD"),          // push mem[10] → 99
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..5 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![99]);
            assert_eq!(vm.memory[10], 99);
        }
    }

    #[test]
    fn test_stack_underflow_error() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![instr("POP")]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            let result = execute_one(&mut vm);
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("underflow"));
        }
    }

    #[test]
    fn test_div_by_zero_error() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 10),
            instr_op("PUSH", 0),
            instr("DIV"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap();
            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap();
            let result = execute_one(&mut vm);
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Division by zero"));
        }
    }

    #[test]
    fn test_tier_assignments() {
        assert_eq!(tier_for_mnemonic("PUSH"), 0);
        assert_eq!(tier_for_mnemonic("POP"), 0);
        assert_eq!(tier_for_mnemonic("LOAD"), 0);
        assert_eq!(tier_for_mnemonic("STORE"), 0);
        assert_eq!(tier_for_mnemonic("SWAP"), 0);
        assert_eq!(tier_for_mnemonic("ADD"), 1);
        assert_eq!(tier_for_mnemonic("SUB"), 1);
        assert_eq!(tier_for_mnemonic("MUL"), 1);
        assert_eq!(tier_for_mnemonic("DIV"), 1);
        assert_eq!(tier_for_mnemonic("NEGATE"), 1);
        assert_eq!(tier_for_mnemonic("XOR"), 2);
        assert_eq!(tier_for_mnemonic("AND"), 2);
        assert_eq!(tier_for_mnemonic("OR"), 2);
        assert_eq!(tier_for_mnemonic("FLIP"), 2);
        assert_eq!(tier_for_mnemonic("ROL"), 2);
        assert_eq!(tier_for_mnemonic("ROR"), 2);
        assert_eq!(tier_for_mnemonic("IF_ZERO"), 3);
        assert_eq!(tier_for_mnemonic("IF_POS"), 3);
        assert_eq!(tier_for_mnemonic("JNZ"), 3);
        assert_eq!(tier_for_mnemonic("JLE"), 3);
        assert_eq!(tier_for_mnemonic("NOOP"), 3);
        assert_eq!(tier_for_mnemonic("CALL"), 3);
        assert_eq!(tier_for_mnemonic("LOOP"), 3);
        assert_eq!(tier_for_mnemonic("SEND"), 4);
        assert_eq!(tier_for_mnemonic("RECV"), 4);
    }

    #[test]
    fn test_tier_counts_tracked() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 5),  // tier 0
            instr_op("PUSH", 3),  // tier 0
            instr("ADD"),         // tier 1
            instr("NOOP"),        // tier 3
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..4 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.tier_counts[0], 2); // two PUSHes
            assert_eq!(vm.tier_counts[1], 1); // one ADD
            assert_eq!(vm.tier_counts[2], 0); // no bitwise
            assert_eq!(vm.tier_counts[3], 1); // one NOOP
            assert_eq!(vm.tier_counts[4], 0); // no comms
        }
    }

    #[test]
    fn test_end_of_program_halts() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![instr("NOOP")]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap(); // executes NOOP, pc=1
            let result = execute_one(&mut vm); // pc=1, no instruction
            assert!(result.is_err());
            assert!(!vm.running);
        }
    }

    #[test]
    fn test_history_ring_buffer_limit() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            // Fill beyond MAX_HISTORY.
            for _ in 0..MAX_HISTORY + 50 {
                capture_snapshot(&mut vm);
            }
            assert_eq!(vm.history.len(), MAX_HISTORY);
        }
    }

    #[test]
    fn test_xor_and_or() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 0xFF),
            instr_op("PUSH", 0x0F),
            instr("XOR"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![0xF0]);
        }
    }

    #[test]
    fn test_bitwise_flip() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![instr_op("PUSH", 0), instr("FLIP")]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..2 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![-1]); // !0 == -1 in two's complement
        }
    }

    #[test]
    fn test_mul() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 6),
            instr_op("PUSH", 7),
            instr("MUL"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![42]);
        }
    }

    #[test]
    fn test_state_serialisation() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        {
            let vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            let json = state_to_json(&vm).unwrap();
            let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
            assert_eq!(parsed["pc"], 0);
            assert_eq!(parsed["running"], false);
            assert_eq!(parsed["total_steps"], 0);
            assert!(parsed["stack"].as_array().unwrap().is_empty());
        }
    }

    #[test]
    fn test_jnz_jumps_when_nonzero() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        // PUSH 1, JNZ 4, PUSH 99, NOOP, PUSH 42
        load_instructions(vec![
            instr_op("PUSH", 1),   // 0: push 1
            instr_op("JNZ", 3),    // 1: TOS=1 != 0, jump to 3
            instr_op("PUSH", 99),  // 2: should be skipped
            instr_op("PUSH", 42),  // 3: lands here
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            // Stack: [42] — the PUSH 99 was skipped.
            assert_eq!(vm.stack, vec![42]);
        }
    }

    #[test]
    fn test_jnz_no_jump_when_zero() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![
            instr_op("PUSH", 0),   // 0: push 0
            instr_op("JNZ", 3),    // 1: TOS=0, no jump
            instr_op("PUSH", 99),  // 2: executed
            instr_op("PUSH", 42),  // 3: also executed
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..4 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            // Stack: [99, 42] — both pushes executed.
            assert_eq!(vm.stack, vec![99, 42]);
        }
    }

    #[test]
    fn test_jle_jumps_when_le() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        // PUSH 5, PUSH 3, JLE 4 → top=3 <= second=5 → jump
        load_instructions(vec![
            instr_op("PUSH", 5),
            instr_op("PUSH", 3),
            instr_op("JLE", 4),
            instr_op("PUSH", 99),  // 3: skipped
            instr_op("PUSH", 42),  // 4: lands here
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..4 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            assert_eq!(vm.stack, vec![42]);
        }
    }

    #[test]
    fn test_loop_counts_down() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        // PUSH 3, LOOP back to 1 → decrements 3→2→1→0, pops on 0
        load_instructions(vec![
            instr_op("PUSH", 3),  // 0: counter = 3
            instr_op("LOOP", 1),  // 1: decrement, loop if > 0
            instr("NOOP"),        // 2: after loop
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            // Execute: PUSH(3), LOOP(3→2, jump), LOOP(2→1, jump), LOOP(1→0, pop), NOOP
            for _ in 0..5 {
                capture_snapshot(&mut vm);
                if execute_one(&mut vm).is_err() { break; }
            }
            // Counter was popped when it reached 0.
            assert!(vm.stack.is_empty());
        }
    }

    #[test]
    fn test_call_pushes_return_address() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        // CALL 2, NOOP, PUSH 42
        load_instructions(vec![
            instr_op("CALL", 2),  // 0: push return addr 1, jump to 2
            instr("NOOP"),        // 1: skipped (would be return target)
            instr_op("PUSH", 42), // 2: subroutine body
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..2 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            // Stack: [1, 42] — return address 1, then PUSH 42.
            assert_eq!(vm.stack, vec![1, 42]);
        }
    }

    #[test]
    fn test_send_recv_channel() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        // PUSH 77, SEND, RECV — should round-trip through channel.
        load_instructions(vec![
            instr_op("PUSH", 77),
            instr("SEND"),
            instr("RECV"),
        ]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            for _ in 0..3 {
                capture_snapshot(&mut vm);
                execute_one(&mut vm).unwrap();
            }
            // Value went stack→channel→stack.
            assert_eq!(vm.stack, vec![77]);
            assert!(vm.channels.is_empty());
        }
    }

    #[test]
    fn test_recv_empty_channel_gives_zero() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_vm();
        load_instructions(vec![instr("RECV")]);
        {
            let mut vm = VM.lock().unwrap_or_else(|e| e.into_inner());
            capture_snapshot(&mut vm);
            execute_one(&mut vm).unwrap();
            assert_eq!(vm.stack, vec![0]);
        }
    }
}
