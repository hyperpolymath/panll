// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ProvisionerModel — Portfolio provisioning and panel configuration types.
///
/// The Provisioner is the system that bundles panels into coherent portfolios,
/// manages per-panel configuration, and handles installation/removal of panel
/// groups. It expresses the "WHAT" (which panels do you need) while the
/// Configurator expresses the "HOW" (how each panel connects to its backend).
///
/// Three-tier panel isolation maps here too:
///   Native   — runs in PanLL process (core 13, trusted panels)
///   Standard — Alpine + Podman container (community panels)
///   Hardened — Stapeln + Chainguard pod (enterprise, untrusted)
///
/// ON EXHAUSTIVE ISOLATION: The `panelIsolation` variant below has exactly three
/// constructors. Every `switch` on isolation tier in the codebase MUST handle all
/// three — the compiler enforces this. When we eventually add a fourth tier (say,
/// `RemoteHost` for distributed panels), the compiler will flag every location
/// that needs updating. In Python or Go, this would be a string enum that silently
/// falls through to a default case, and you'd discover the missing handler in
/// production. ReScript doesn't have a `default` case for variants — you handle
/// everything or you don't compile. That's the difference between "type-safe" as
/// marketing and type-safe as engineering practice.

/// Panel isolation tier — determines how a panel runs.
type panelIsolation =
  /// Runs directly in the PanLL Tauri process. Fastest, full trust.
  | Native
  /// Runs in a standard Alpine + Podman OCI container. Good isolation,
  /// quick startup, clean uninstall by deleting the pod.
  | StandardPod
  /// Runs in a hardened Stapeln + Chainguard (Wolfi-base) container.
  /// Signed image, SBOM included, zero CVE baseline. Enterprise grade.
  | HardenedPod

/// Installation status of a panel within a portfolio.
type panelInstallStatus =
  /// Not installed — available for installation.
  | NotInstalled
  /// Currently downloading/building the container image.
  | Installing
  /// Installed and ready to use.
  | Installed
  /// Installation failed — error message attached.
  | InstallFailed(string)
  /// Marked for removal.
  | Removing

/// A panel's configuration — its connection to a backend service.
/// The Configurator manages these. Users don't need to touch this
/// to get started (provisioner sets sensible defaults).
type panelConfig = {
  /// The panel's unique identifier (matches panelId from PanelSwitcherModel).
  panelName: string,
  /// Backend endpoint URL (empty for filesystem-only panels).
  endpoint: string,
  /// Whether the panel should auto-connect on startup.
  autoConnect: bool,
  /// The isolation tier for this panel.
  isolation: panelIsolation,
  /// Custom environment variables passed to the panel's container (if podded).
  envVars: array<(string, string)>,
  /// Whether the panel is enabled (visible in the panel bar).
  enabled: bool,
}

/// A portfolio — a curated bundle of panels for a specific use case.
///
/// Portfolios are the "WHAT": they answer "what panels do I need for X?"
/// Users browse portfolios, pick one, and the provisioner installs all
/// the panels in the bundle with sensible default configurations.
type portfolio = {
  /// Unique portfolio identifier (kebab-case).
  id: string,
  /// Human-readable portfolio name.
  name: string,
  /// One-line description.
  description: string,
  /// The panels included in this portfolio (by panel name).
  panels: array<string>,
  /// The recommended isolation tier for this portfolio's panels.
  defaultIsolation: panelIsolation,
  /// Whether this is a built-in portfolio (shipped with PanLL) or user-created.
  builtIn: bool,
  /// Icon identifier for the portfolio card.
  icon: string,
  /// Target audience description.
  audience: string,
}

/// Installation progress for a portfolio (tracks per-panel progress).
type portfolioInstallProgress = {
  /// Portfolio being installed.
  portfolioId: string,
  /// Total panels in the portfolio.
  totalPanels: int,
  /// Panels successfully installed so far.
  installedPanels: int,
  /// Panels that failed installation.
  failedPanels: int,
  /// Current panel being installed (if any).
  currentPanel: option<string>,
}

/// Category tabs for the Provisioner panel.
type provisionerCategory =
  /// Browse available portfolios.
  | Portfolios
  /// View and edit per-panel configuration.
  | Configurator
  /// View installed panels and their isolation tiers.
  | Installed
  /// Create a custom portfolio.
  | CustomPortfolio

/// The complete Provisioner state.
type provisionerState = {
  /// Available portfolios (built-in + user-created).
  portfolios: array<portfolio>,
  /// Per-panel configurations.
  configs: array<panelConfig>,
  /// Installation status per panel name.
  installStatus: array<(string, panelInstallStatus)>,
  /// Current portfolio installation progress (if installing).
  installProgress: option<portfolioInstallProgress>,
  /// Active category tab.
  activeCategory: provisionerCategory,
  /// Text filter for searching portfolios/panels.
  filterText: string,
  /// Loading state.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Custom portfolio being built (name, selected panels).
  customName: string,
  customPanels: array<string>,
}
