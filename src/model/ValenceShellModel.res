// SPDX-License-Identifier: MPL-2.0

/// PanLL Valence Shell Model — types for the embedded terminal panel.
///
/// The Valence Shell panel provides a formally verified reversible shell
/// embedded in PanLL via PTY allocation. It integrates Claude Code for
/// AI-assisted development, session recording for teaching and sharing,
/// and an approval gate for collaborative parent-child workflows.
///
/// The shell connects to the Valence shell binary (formally verified
/// reversible filesystem operations) or falls back to the system shell
/// (bash/zsh) when Valence is not installed.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Which shell backend is active.
type shellBackend =
  /// Valence shell — formally verified reversible ops, MAA audit trail.
  | ValenceShell
  /// System shell fallback (bash, zsh, fish) when Valence is not installed.
  | SystemShell(string)

/// Terminal session recording state.
type shellRecordingState =
  /// Not recording.
  | RecordingIdle
  /// Actively recording terminal output to an asciinema .cast file.
  | RecordingActive(float)
  /// Recording paused (timestamp of pause start).
  | RecordingPaused(float)

/// A single recorded terminal session, stored as an asciinema .cast file.
type terminalRecording = {
  /// Unique identifier for this recording.
  id: string,
  /// Human-readable name for the recording.
  name: string,
  /// Absolute path to the .cast file on disk.
  path: string,
  /// Duration in seconds.
  durationSecs: float,
  /// When the recording was created (Unix timestamp).
  createdAt: float,
  /// Number of bytes in the .cast file.
  sizeBytes: int,
}

/// Approval gate mode for collaborative sessions.
/// When enabled, commands typed by the child must be approved by the
/// parent before execution. This is a safety feature, not a restriction —
/// it creates a teaching moment for every command.
type approvalGateMode =
  /// Approval gate disabled — commands execute immediately.
  | GateDisabled
  /// Approval gate enabled — commands queue for review.
  | GateEnabled
  /// Approval gate in learning mode — approved commands build a whitelist,
  /// and future identical commands auto-approve.
  | GateLearning

/// A command pending approval in the gate queue.
type pendingCommand = {
  /// The raw command string as typed.
  command: string,
  /// Who typed it (for multi-user sessions).
  author: string,
  /// When it was submitted (Unix timestamp).
  submittedAt: float,
}

/// A Valence filesystem checkpoint — a named save point that can be
/// restored with formal proof of reversibility.
type valenceCheckpoint = {
  /// Checkpoint identifier.
  id: string,
  /// Human-readable label.
  label: string,
  /// When the checkpoint was created (Unix timestamp).
  createdAt: float,
  /// Number of filesystem operations since last checkpoint.
  opsSinceCheckpoint: int,
}

/// Category tabs for the Valence Shell panel.
type valenceShellCategory =
  /// Main terminal view with PTY.
  | ShellTerminal
  /// Session recordings browser — replay, export, share.
  | ShellRecordings
  /// Valence checkpoints — filesystem save/restore points.
  | ShellCheckpoints
  /// Command history with reversibility annotations.
  | ShellHistory
  /// Settings — shell backend, approval gate, appearance.
  | ShellSettings

/// A line in the terminal output buffer.
type terminalLine = {
  /// The text content of the line.
  content: string,
  /// Whether this line is from stdout (true) or stderr (false).
  isStdout: bool,
  /// Unix timestamp when the line was received.
  timestamp: float,
}

/// Root state for the Valence Shell panel.
type valenceShellState = {
  /// Which shell backend is active (Valence or system shell).
  backend: shellBackend,
  /// Whether the Valence shell binary is available on PATH.
  valenceAvailable: bool,
  /// Whether the terminal PTY is connected and running.
  ptyConnected: bool,
  /// Current working directory in the shell.
  cwd: string,
  /// Terminal output buffer (ring buffer, last 1000 lines).
  outputBuffer: array<terminalLine>,
  /// Current input line (what the user is typing).
  inputLine: string,
  /// Command history (for up/down arrow navigation).
  commandHistory: array<string>,
  /// Index into command history (-1 = current input).
  historyIndex: int,
  /// Active category tab.
  activeCategory: valenceShellCategory,
  /// Session recording state.
  recording: shellRecordingState,
  /// List of saved recordings.
  recordings: array<terminalRecording>,
  /// Approval gate mode.
  approvalGate: approvalGateMode,
  /// Commands pending approval.
  pendingCommands: array<pendingCommand>,
  /// Whitelist of auto-approved commands (built in GateLearning mode).
  approvedCommands: array<string>,
  /// Valence filesystem checkpoints.
  checkpoints: array<valenceCheckpoint>,
  /// Whether Claude Code is currently running in the terminal.
  claudeCodeActive: bool,
  /// Error message (if any).
  error: option<string>,
  /// Loading state for async operations (checkpoint creation, recording save).
  loading: bool,
  /// Whether the terminal is in split view mode.
  splitView: bool,
  /// IDApTIK-aware command completions.
  completions: array<string>,
  /// Whether the completions popup is visible.
  completionsVisible: bool,
}
