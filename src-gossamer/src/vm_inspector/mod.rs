// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL VM Inspector Module — Rust backend for the VM Inspector panel.
//!
//! Provides an in-process virtual machine with stepping, reverse execution,
//! program loading, and state export. The VM state is held in a static
//! `Mutex<VmState>` so that step_forward/step_backward persist across
//! individual Tauri command invocations.
//!
//! Commands:
//!   - `vm_inspector_read_state`: Return current VM state as JSON.
//!   - `vm_inspector_step_forward`: Execute one instruction forward.
//!   - `vm_inspector_step_backward`: Reverse one instruction.
//!   - `vm_inspector_run`: Run until breakpoint or end of program.
//!   - `vm_inspector_load_program`: Parse assembly text into instructions.
//!   - `vm_inspector_export_snapshot`: Export full VM state dump.
//!   - `vm_inspector_read_file`: Read VM state from a JSON file on disk.

pub mod commands;
