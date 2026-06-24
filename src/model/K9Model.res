// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// PanLL K9 Model — state for the K9 Manager panel.
///
/// Tracks loaded K9 contractile files, their validation results, and the
/// current security level. Used by K9Manager.res for rendering the panel
/// and by the update loop for dispatching K9Cmd operations.
///
/// Dependency: K9Engine (for types only — no circular imports).

/// A loaded K9 file entry with path and validation result.
type k9FileEntry = {
  /// Filesystem path to the .k9.ncl file.
  path: string,
  /// Parsed contractile data (None if not yet validated).
  contractile: option<K9Engine.k9Contractile>,
  /// Whether the file is currently being validated.
  validating: bool,
}

/// Root state for the K9 Manager panel.
type k9ManagerState = {
  /// All loaded K9 files with their validation status.
  loadedFiles: array<k9FileEntry>,
  /// The current effective security level across loaded files.
  currentLevel: K9Engine.k9SecurityLevel,
  /// Error from the last operation (dismissed by user).
  error: option<string>,
  /// Whether a load or validate operation is in progress.
  loading: bool,
}

/// Initial K9 Manager state — no files loaded, Kennel (safest) level.
let init: k9ManagerState = {
  loadedFiles: [],
  currentLevel: K9Engine.Kennel,
  error: None,
  loading: false,
}
