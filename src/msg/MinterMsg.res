// SPDX-License-Identifier: PMPL-1.0-or-later

/// Panel Minter messages -- wizard state transitions for creating new panel
/// modules with accessibility and proof hooks baked in by default.

open Model

type minterMsg =
  /// Update the panel name (triggers live PascalCase validation).
  | SetPanelName(string)
  /// Update the short name (panel bar label, max ~8 chars).
  | SetShortName(string)
  /// Update the one-line description.
  | SetDescription(string)
  /// Update the icon identifier.
  | SetIcon(string)
  /// Select the backend kind (NoBackend, FilesystemBackend, HttpBackend, DatabaseBackend).
  | SetBackendKind(panelBackendKind)
  /// Select the accessibility level (Standard or Enhanced).
  | SetAccessibility(accessibilityLevel)
  /// Update the endpoint URL (relevant for HTTP/Database backends).
  | SetEndpoint(string)
  /// Add a new empty capability declaration.
  | AddCapability
  /// Remove a capability by index.
  | RemoveCapability(int)
  /// Advance to the next wizard step.
  | NextStep
  /// Go back to the previous wizard step.
  | PrevStep
  /// Trigger the minting operation via Gossamer backend.
  | ExecuteMint
  /// Result of the minting operation (success or error).
  | MintResult(result<string, string>)
  /// Reset the minter to its initial state for another panel.
  | ResetMinter
  /// Export current minter config to ENSAID_CONFIG.a2ml (adds panel entry).
  | ExportToEnsaidConfig
  /// TypeLL cross-panel type check result for panel spec types.
  | TypeCheckResult(result<string, string>)
