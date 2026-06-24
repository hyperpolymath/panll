// SPDX-License-Identifier: MPL-2.0

/// VM Inspector messages -- VM state reading, step execution, breakpoint
/// management, timeline navigation, and state export for the reversible
/// VM visual debugger panel.

open Model

type vmInspectorMsg =
  /// Switch the active category tab.
  | SetInspectorCategory(vmInspectorCategory)
  /// Read the current VM state from the running game.
  | ReadVmState
  /// VM state received.
  | VmStateReceived(result<string, string>)
  /// Step the VM forward by one instruction.
  | StepForward
  /// Step the VM backward by one instruction (reverse execution).
  | StepBackward
  /// Step result received.
  | StepResult(result<string, string>)
  /// Run the VM until the next breakpoint or end.
  | RunVm
  /// Pause the running VM.
  | PauseVm
  /// Run/pause result.
  | RunResult(result<string, string>)
  /// Reset the VM to initial state.
  | ResetVm
  /// Toggle a breakpoint at the given instruction index.
  | ToggleBreakpoint(int)
  /// Seek to a position in the execution timeline.
  | SeekTimeline(int)
  /// Export the current VM state as JSON.
  | ExportSnapshot
  /// Snapshot exported (or failed).
  | SnapshotExported(result<string, string>)
  /// Toggle multi-VM view (for multiplayer debugging).
  | ToggleMultiVm
  /// Dismiss the error banner.
  | DismissVmError
  /// Toggle BoJ routing for DAP operations (dap-mcp cartridge).
  | ToggleVmBojRouting
  /// TypeLL cross-panel type check result for VM state types.
  | TypeCheckResult(result<string, string>)
