// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Minter Model — types for the Panel Minter system.
///
/// The Minter generates new panel modules from templates, ensuring every
/// panel starts with accessibility, proof hooks, and agent integration
/// baked in by default. It is structurally harder to create an inaccessible
/// panel than an accessible one.
///
/// The Minter also patches the 6 global wiring files (PanelSwitcherModel,
/// PanelRegistry, Model, Msg, View, Update) so the new panel is immediately
/// routable and renderable.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Backend type for the panel — determines what kind of Rust backend
/// and Tauri commands are scaffolded.
type panelBackendKind =
  /// No backend — pure frontend panel (e.g. documentation viewer).
  | NoBackend
  /// Filesystem-only backend — reads local files, no HTTP (e.g. Farm, Plaza).
  | FilesystemBackend
  /// HTTP API backend — connects to an external service (e.g. CloudGuard, Hypatia).
  | HttpBackend
  /// Database backend — connects to a database via existing DB module.
  | DatabaseBackend

/// Accessibility level baked into the generated template.
/// All levels include keyboard navigation and screen reader semantics.
/// Higher levels add more ARIA attributes and contrast compliance.
type accessibilityLevel =
  /// Standard: keyboard nav, role attributes, aria-label on interactive elements.
  | StandardAccessibility
  /// Enhanced: adds aria-live regions, focus management, skip links.
  | EnhancedAccessibility

/// A single capability declaration for the new panel.
type minterCapability = {
  /// Machine-readable identifier (e.g. "repo-inventory").
  id: string,
  /// Human-readable label (e.g. "Repository Inventory").
  label: string,
}

/// Validation result for a panel name — checked before generation.
type nameValidation =
  /// Name is valid and available.
  | NameValid
  /// Name conflicts with an existing panel.
  | NameConflict(string)
  /// Name contains invalid characters (must be PascalCase, alphanumeric).
  | NameInvalid(string)

/// The form state for creating a new panel.
type minterForm = {
  /// PascalCase panel name (e.g. "Wharf", "Statistease", "Fleet").
  panelName: string,
  /// Short human-readable name for the panel bar (max ~8 chars).
  shortName: string,
  /// One-line description of what this panel does.
  description: string,
  /// Icon identifier for the panel bar.
  icon: string,
  /// What kind of backend this panel needs.
  backendKind: panelBackendKind,
  /// Accessibility level for the generated templates.
  accessibility: accessibilityLevel,
  /// Declared capabilities (user adds these interactively).
  capabilities: array<minterCapability>,
  /// Validation state for the panel name.
  nameValidation: nameValidation,
  /// Whether the panel connects to an external endpoint.
  endpoint: string,
}

/// Result of a minting operation — returned by the Tauri backend.
type mintResult = {
  /// Whether the operation succeeded.
  success: bool,
  /// Files that were created.
  filesCreated: array<string>,
  /// Files that were patched (modified).
  filesPatched: array<string>,
  /// Any warnings encountered during generation.
  warnings: array<string>,
  /// Error message if the operation failed.
  error: option<string>,
}

/// Root state for the Panel Minter.
type minterState = {
  /// The current form being filled out.
  form: minterForm,
  /// Whether a minting operation is in progress.
  minting: bool,
  /// Result of the last minting operation.
  lastResult: option<mintResult>,
  /// Error from the last operation.
  error: option<string>,
  /// Step in the multi-step minting wizard (0 = name, 1 = config, 2 = capabilities, 3 = review).
  wizardStep: int,
}
