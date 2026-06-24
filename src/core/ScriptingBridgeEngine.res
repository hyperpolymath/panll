// SPDX-License-Identifier: MPL-2.0

/// PanLL Scripting Bridge Engine — pure computation and helpers for the
/// Scripting Bridge panel. Provides default state, tab metadata, instruction
/// tier counting, saved script aggregation, and REPL entry formatting.

open ScriptingBridgeModel

/// Default state for the Scripting Bridge panel.
/// Starts on the REPL tab with empty instruction, script, and history lists.
let defaultState: scriptingBridgeState = {
  activeTab: Repl,
  replHistory: [],
  instructions: [],
  savedScripts: [],
  selectedScript: None,
  executing: false,
  replInput: "",
  analysisFindings: [],
  error: None,
}

/// Human-readable label for each tab in the Scripting Bridge panel.
let tabLabel = (tab: scriptingBridgeTab): string =>
  switch tab {
  | Repl => "REPL"
  | Instructions => "Instructions"
  | Scripts => "Scripts"
  | Analysis => "Analysis"
  }

/// All tabs in display order.
let allTabs: array<scriptingBridgeTab> = [Repl, Instructions, Scripts, Analysis]

/// Count instructions belonging to a given privilege tier.
let countInstructionsByTier = (instructions: array<instruction>, tier: instructionTier): int =>
  instructions->Array.filter(i => i.tier === tier)->Array.length

/// Count instructions that are currently allowed in the sandbox.
let countAllowedInstructions = (instructions: array<instruction>): int =>
  instructions->Array.filter(i => i.allowed)->Array.length

/// Human-readable label for an instruction tier.
let tierLabel = (tier: instructionTier): string =>
  switch tier {
  | TierSafe => "Tier 0 (Safe)"
  | TierControlled => "Tier 1 (Controlled)"
  | TierPrivileged => "Tier 2 (Privileged)"
  | TierSystem => "Tier 3 (System)"
  }

/// Count the total number of saved scripts.
let countSavedScripts = (state: scriptingBridgeState): int => Array.length(state.savedScripts)

/// Format a REPL entry as a human-readable string.
/// Shows a success/failure prefix followed by the input and output.
let formatReplEntry = (entry: scriptReplEntry): string => {
  let prefix = if entry.success {
    ">"
  } else {
    "!"
  }
  `${prefix} ${entry.input}\n  ${entry.output}`
}

/// Count REPL entries that resulted in errors.
let countReplErrors = (history: array<scriptReplEntry>): int =>
  history->Array.filter(e => !e.success)->Array.length

/// Count analysis findings by severity.
let countFindingsBySeverity = (findings: array<analysisFinding>, severity: analysisSeverity): int =>
  findings->Array.filter(f => f.severity === severity)->Array.length

/// Human-readable label for an analysis severity.
let analysisSeverityLabel = (severity: analysisSeverity): string =>
  switch severity {
  | AnalysisError => "Error"
  | AnalysisWarning => "Warning"
  | AnalysisInfo => "Info"
  | AnalysisOptimisation => "Optimisation"
  }
