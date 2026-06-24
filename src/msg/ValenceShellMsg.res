// SPDX-License-Identifier: MPL-2.0

/// Valence Shell messages -- terminal PTY lifecycle, input handling,
/// session recording, checkpoint management, approval gate, and Claude
/// Code integration for the embedded terminal panel.

open Model

type valenceShellMsg =
  /// Switch the active category tab.
  | SetShellCategory(valenceShellCategory)
  /// Update the text input line.
  | UpdateInput(string)
  /// Submit the current input line (Enter key).
  | SubmitInput
  /// Select a completion from the popup.
  | SelectCompletion(string)
  /// Toggle the completions popup visibility.
  | ToggleCompletions
  /// PTY spawned (or failed).
  | PtySpawned(result<string, string>)
  /// Terminal output received from the PTY.
  | PtyOutput(string, bool)
  /// PTY exited.
  | PtyExited
  /// Check if Valence shell binary is available.
  | CheckValenceAvailability
  /// Valence availability result.
  | ValenceAvailabilityResult(result<string, string>)
  /// Launch Claude Code in the terminal.
  | LaunchClaudeCode
  /// Start recording a terminal session.
  | StartRecordingSession
  /// Stop the current recording.
  | StopRecordingSession
  /// Recording started (or failed).
  | RecordingStarted(result<string, string>)
  /// Recording stopped and saved (or failed).
  | RecordingStopped(result<string, string>)
  /// Load the list of saved recordings.
  | LoadRecordings
  /// Recordings loaded (or failed).
  | RecordingsLoaded(result<string, string>)
  /// Delete a recording by ID.
  | DeleteRecordingById(string)
  /// Recording deleted (or failed).
  | RecordingDeleted(result<string, string>)
  /// Export a recording in the given format (html, json, cast).
  | ExportRecordingAs(string, string)
  /// Recording exported (or failed).
  | RecordingExported(result<string, string>)
  /// Create a Valence filesystem checkpoint with the given label.
  | CreateCheckpointWithLabel(string)
  /// Checkpoint created (or failed).
  | CheckpointCreated(result<string, string>)
  /// Restore a checkpoint by ID.
  | RestoreCheckpointById(string)
  /// Checkpoint restored (or failed).
  | CheckpointRestored(result<string, string>)
  /// Load the list of checkpoints.
  | LoadCheckpoints
  /// Checkpoints loaded (or failed).
  | CheckpointsLoaded(result<string, string>)
  /// Take a screenshot of the terminal state.
  | ScreenshotTerminal
  /// Screenshot captured (or failed).
  | ScreenshotCaptured(result<string, string>)
  /// Set the approval gate mode.
  | SetApprovalGate(approvalGateMode)
  /// Approve a pending command by index.
  | ApproveCommand(int)
  /// Reject a pending command by index.
  | RejectCommand(int)
  /// Toggle split view mode.
  | ToggleSplitView
  /// Dismiss the error banner.
  | DismissError
  /// TypeLL cross-panel type check result for command types.
  | TypeCheckResult(result<string, string>)
