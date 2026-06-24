// SPDX-License-Identifier: MPL-2.0

/// PanLL Valence Shell Engine — pure computation and helpers for the
/// embedded terminal panel.
///
/// Contains default state, label helpers, and IDApTIK-aware command
/// completions. No side effects — all I/O goes through ValenceShellCmd.

open ValenceShellModel

/// Human-readable labels for the category tabs.
let categoryLabel = (cat: valenceShellCategory): string =>
  switch cat {
  | ShellTerminal => "Terminal"
  | ShellRecordings => "Recordings"
  | ShellCheckpoints => "Checkpoints"
  | ShellHistory => "History"
  | ShellSettings => "Settings"
  }

/// Icon identifiers for each category tab.
let categoryIcon = (cat: valenceShellCategory): string =>
  switch cat {
  | ShellTerminal => "terminal"
  | ShellRecordings => "video"
  | ShellCheckpoints => "save"
  | ShellHistory => "clock"
  | ShellSettings => "settings"
  }

/// Human-readable label for the shell backend.
let backendLabel = (backend: shellBackend): string =>
  switch backend {
  | ValenceShell => "Valence Shell (formally verified)"
  | SystemShell(name) => `System Shell (${name})`
  }

/// Human-readable label for the approval gate mode.
let gateLabel = (gate: approvalGateMode): string =>
  switch gate {
  | GateDisabled => "Disabled"
  | GateEnabled => "Enabled (review all)"
  | GateLearning => "Learning (builds whitelist)"
  }

/// IDApTIK-specific command completions — common development commands.
/// These appear in the command palette when the user starts typing.
let idaptikCompletions: array<string> = [
  "deno task dev",
  "deno task build",
  "deno task res:build",
  "deno task res:dev",
  "deno task res:clean",
  "deno task dev:all",
  "deno task sync-server",
  "deno task lint",
  "deno task dev:vite",
  "./start-game-only.sh",
  "./start-dev.sh",
  "claude",
  "claude --help",
  "git status",
  "git diff",
  "git log --oneline -20",
  "git add -p",
  "valence checkpoint create",
  "valence checkpoint list",
  "valence checkpoint restore",
  "valence undo",
  "valence redo",
  "valence audit",
]

/// Filter completions by prefix match.
let filterCompletions = (input: string, completions: array<string>): array<string> => {
  if String.length(input) === 0 {
    []
  } else {
    Array.filter(completions, c =>
      String.startsWith(String.toLowerCase(c), String.toLowerCase(input))
    )
  }
}

/// Default state for the Valence Shell panel.
let defaultState: valenceShellState = {
  backend: SystemShell("bash"),
  valenceAvailable: false,
  ptyConnected: false,
  cwd: ".",
  outputBuffer: [],
  inputLine: "",
  commandHistory: [],
  historyIndex: -1,
  activeCategory: ShellTerminal,
  recording: RecordingIdle,
  recordings: [],
  approvalGate: GateDisabled,
  pendingCommands: [],
  approvedCommands: [],
  checkpoints: [],
  claudeCodeActive: false,
  error: None,
  loading: false,
  splitView: false,
  completions: idaptikCompletions,
  completionsVisible: false,
}
