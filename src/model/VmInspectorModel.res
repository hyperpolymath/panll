// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL VM Inspector Model — types for the reversible VM visual debugger.
///
/// The VM Inspector provides a visual debugger for IDApTIK's reversible
/// computation engine. It renders stack state, memory cells, the instruction
/// pointer with assembly listing, and supports stepping forward AND backward
/// (leveraging the VM's reversibility).
///
/// The inspector connects to the running game's VM state via Gossamer
/// inter-webview messaging or serialised JSON file (decoupled mode).
///
/// Dependency: leaf module — no imports from other PanLL models.

/// VM instruction tier — the 5-tier hierarchy from the IDApTIK VM.
type vmInstructionTier =
  /// Tier 0: Arithmetic (ADD, SUB, SWAP, NEGATE, NOOP, XOR, FLIP, ROL, ROR, AND, OR, MUL, DIV).
  | TierArithmetic
  /// Tier 1: Conditionals (IF_ZERO, IF_POS, LOOP).
  | TierConditionals
  /// Tier 2: Stack/Memory (PUSH, POP, LOAD, STORE).
  | TierStackMemory
  /// Tier 3: Subroutines (CALL).
  | TierSubroutines
  /// Tier 4: I/O (SEND, RECV).
  | TierIO

/// A single VM instruction in the listing.
type vmInstruction = {
  /// Instruction index (program counter value).
  index: int,
  /// Instruction mnemonic (e.g., "ADD", "PUSH 42", "IF_ZERO").
  mnemonic: string,
  /// Which tier this instruction belongs to.
  tier: vmInstructionTier,
  /// Whether this instruction has a breakpoint set.
  hasBreakpoint: bool,
  /// Number of times this instruction has been executed.
  executionCount: int,
}

/// A memory cell in the VM's addressable memory.
type vmMemoryCell = {
  /// Memory address (0-based index).
  address: int,
  /// Current value stored at this address.
  value: int,
  /// Whether this cell was recently read (for highlighting).
  recentRead: bool,
  /// Whether this cell was recently written (for highlighting).
  recentWrite: bool,
}

/// A port I/O buffer entry for SEND/RECV monitoring.
type vmPortEntry = {
  /// Port number.
  port: int,
  /// Direction: true = sent, false = received.
  isSend: bool,
  /// The value sent/received.
  value: int,
  /// When this I/O occurred (execution step number).
  atStep: int,
}

/// A snapshot of the VM state at a specific execution step.
type vmSnapshot = {
  /// Execution step number (monotonically increasing).
  step: int,
  /// Current program counter.
  pc: int,
  /// Stack contents (top of stack is last element).
  stack: array<int>,
  /// Memory cells.
  memory: array<vmMemoryCell>,
  /// Which instruction was executed at this step.
  instructionMnemonic: string,
}

/// Breakpoint configuration.
type vmBreakpoint =
  /// Break when the program counter reaches this instruction index.
  | BreakAtInstruction(int)
  /// Break when a memory address is read.
  | BreakOnMemoryRead(int)
  /// Break when a memory address is written.
  | BreakOnMemoryWrite(int)
  /// Break when stack depth reaches a threshold.
  | BreakOnStackDepth(int)

/// VM connection mode — how the inspector gets VM state.
type vmConnectionMode =
  /// Live connection via Gossamer inter-webview messaging.
  | VmLiveConnection
  /// File-based: reads serialised VM state from a JSON file (watcher picks up changes).
  | VmFileConnection(string)
  /// Disconnected — no VM state available.
  | VmDisconnected

/// Category tabs for the VM Inspector panel.
type vmInspectorCategory =
  /// Main debugger view (stack + memory + instructions + controls).
  | InspectorDebugger
  /// Execution timeline scrubber — drag to any point in history.
  | InspectorTimeline
  /// Subroutine call graph visualisation.
  | InspectorCallGraph
  /// Port I/O monitoring (SEND/RECV buffers).
  | InspectorPortIO
  /// Instruction statistics (most executed, cycle count, tier usage).
  | InspectorStatistics

/// Root state for the VM Inspector panel.
type vmInspectorState = {
  /// How the inspector connects to the VM.
  connection: vmConnectionMode,
  /// Active category tab.
  activeCategory: vmInspectorCategory,
  /// Current program counter.
  pc: int,
  /// Current stack (top of stack is last element).
  stack: array<int>,
  /// Memory cells (fixed-size array, typically 256 cells).
  memory: array<vmMemoryCell>,
  /// Instruction listing (the loaded program).
  instructions: array<vmInstruction>,
  /// Execution history (ring buffer, last 10000 snapshots).
  history: array<vmSnapshot>,
  /// Current position in the execution timeline (index into history).
  timelinePosition: int,
  /// Active breakpoints.
  breakpoints: array<vmBreakpoint>,
  /// Port I/O log.
  portLog: array<vmPortEntry>,
  /// Whether the VM is currently executing (running to next breakpoint).
  running: bool,
  /// Total execution steps so far.
  totalSteps: int,
  /// Per-instruction execution counts (for statistics).
  instructionCounts: array<int>,
  /// Per-tier execution counts.
  tierCounts: array<int>,
  /// Error message (if any).
  error: option<string>,
  /// Loading state.
  loading: bool,
  /// Whether multi-VM view is active (shows multiple VMs for multiplayer).
  multiVmView: bool,
  /// Route DAP operations through BoJ's dap-mcp cartridge instead of direct Gossamer.
  bojRouting: bool,
}
