// SPDX-License-Identifier: PMPL-1.0-or-later

/// ENSAID_CONFIG messages -- cross-panel config generation and I/O.
/// Any panel can trigger a full ENSAID_CONFIG export; the engine assembles
/// state from Provisioner, Workspace, and Automation Router into one file.

type ensaidConfigMsg =
  /// Generate and write ENSAID_CONFIG.a2ml to the current repo.
  | GenerateAndWrite
  /// Preview the generated content (no disk write).
  | PreviewConfig
  /// Config preview ready (content string).
  | PreviewReady(string)
  /// Config written successfully.
  | ConfigWritten(result<string, string>)
  /// Read existing config from repo.
  | ReadFromRepo
  /// Config read from repo.
  | ConfigRead(result<string, string>)
  /// Dismiss error.
  | DismissConfigError
  /// TypeLL cross-panel type check result for ENSAID config types.
  | TypeCheckResult(result<string, string>)
