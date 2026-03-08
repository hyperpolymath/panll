// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL VM Inspector Engine — pure computation and helpers for the
/// reversible VM visual debugger panel.

open VmInspectorModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: vmInspectorCategory): string =>
  switch cat {
  | InspectorDebugger => "Debugger"
  | InspectorTimeline => "Timeline"
  | InspectorCallGraph => "Call Graph"
  | InspectorPortIO => "Port I/O"
  | InspectorStatistics => "Statistics"
  }

/// Human-readable labels for instruction tiers.
let tierLabel = (tier: vmInstructionTier): string =>
  switch tier {
  | TierArithmetic => "Tier 0: Arithmetic"
  | TierConditionals => "Tier 1: Conditionals"
  | TierStackMemory => "Tier 2: Stack/Memory"
  | TierSubroutines => "Tier 3: Subroutines"
  | TierIO => "Tier 4: I/O"
  }

/// Short tier labels for compact display.
let tierShortLabel = (tier: vmInstructionTier): string =>
  switch tier {
  | TierArithmetic => "T0"
  | TierConditionals => "T1"
  | TierStackMemory => "T2"
  | TierSubroutines => "T3"
  | TierIO => "T4"
  }

/// CSS colour class for each tier (Tailwind).
let tierColour = (tier: vmInstructionTier): string =>
  switch tier {
  | TierArithmetic => "text-blue-400"
  | TierConditionals => "text-amber-400"
  | TierStackMemory => "text-emerald-400"
  | TierSubroutines => "text-purple-400"
  | TierIO => "text-red-400"
  }

/// Human-readable connection mode label.
let connectionLabel = (conn: vmConnectionMode): string =>
  switch conn {
  | VmLiveConnection => "Live (inter-webview)"
  | VmFileConnection(path) => `File: ${path}`
  | VmDisconnected => "Disconnected"
  }

/// Format a stack as a displayable string (top-of-stack on right).
let formatStack = (stack: array<int>): string =>
  if Array.length(stack) === 0 {
    "(empty)"
  } else {
    stack->Array.map(v => Int.toString(v))->Array.join(", ")
  }

/// Default state for the VM Inspector panel.
let defaultState: vmInspectorState = {
  connection: VmDisconnected,
  activeCategory: InspectorDebugger,
  pc: 0,
  stack: [],
  memory: [],
  instructions: [],
  history: [],
  timelinePosition: 0,
  breakpoints: [],
  portLog: [],
  running: false,
  totalSteps: 0,
  instructionCounts: [],
  tierCounts: [0, 0, 0, 0, 0],
  error: None,
  loading: false,
  multiVmView: false,
}
