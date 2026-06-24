// SPDX-License-Identifier: MPL-2.0

/// Provenance Map messages -- code trust surface lifecycle.
/// The provenance map is ambient (always visible), not a panel overlay.
/// These messages handle file analysis, palette switching, and hostile UX.

open Model

type provenanceMsg =
  /// Analyse a file's provenance via git blame.
  | AnalyseFile(string, string) // repoPath, filePath
  /// Blame analysis result.
  | AnalysisResult(result<string, string>)
  /// Unsound marker scan result.
  | UnsoundScanResult(result<string, string>)
  /// Switch the accessibility palette.
  | SetPalette(accessibilityPalette)
  /// Toggle hostile UX suppression (the "pull the battery" action).
  | ToggleHostileUx
  /// Acknowledge a specific unreviewed AI region (dismiss its warning).
  | AcknowledgeRegion(string, int) // filePath, startLine
  /// Enable or disable the provenance overlay entirely.
  | SetEnabled(bool)
  /// TypeLL cross-panel type check result for provenance types.
  | TypeCheckResult(result<string, string>)
