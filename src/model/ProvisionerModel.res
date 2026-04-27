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
  /// Runs directly in the PanLL Gossamer process. Fastest, full trust.
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
  /// Browse available plugin bundles.
  | PluginBundles
  /// View and edit per-panel configuration.
  | Configurator
  /// View installed panels and their isolation tiers.
  | Installed
  /// Create a custom portfolio.
  | CustomPortfolio
  /// Create a custom plugin bundle.
  | CustomPluginBundle
  /// Create mixed deployment bundles.
  | DeploymentBundles

/// Provisioning target type - what are we provisioning?
type provisioningTarget =
  /// Traditional PanLL panels
  | PanelTarget
  /// Plugin cartridges
  | PluginTarget
  /// Mixed panel/plugin bundles
  | MixedTarget

/// Plugin trust tiers for security classification
type pluginTrustTier =
  /// Core plugins, always available, high trust
  | Teranga
  /// Security-critical plugins, elevated trust
  | Shield
  /// Community-contributed plugins, standard trust
  | Ayo

/// Plugin dependency declaration
type pluginDependency = {
  /// Plugin identifier
  pluginId: string,
  /// Required version
  version: string,
  /// Trust tier requirement
  tier: pluginTrustTier,
}

/// Sandbox policy for plugin isolation
type sandboxPolicy = {
  /// Network access permission
  networkAccess: bool,
  /// Filesystem access permission
  filesystemAccess: bool,
  /// Allowed capabilities
  allowedCapabilities: array<string>,
}

/// Plugin configuration
type pluginConfig = {
  /// Plugin unique identifier
  pluginId: string,
  /// Backend endpoint URL
  endpoint: string,
  /// Enabled capabilities
  capabilities: array<string>,
  /// Sandbox security policy
  sandboxPolicy: sandboxPolicy,
  /// Isolation tier
  isolation: panelIsolation,
  /// Custom environment variables
  envVars: array<(string, string)>,
  /// Auto-start on PanLL launch
  autoStart: bool,
}

/// Plugin bundle - curated collection of plugins
type pluginBundle = {
  /// Unique bundle identifier (kebab-case)
  id: string,
  /// Human-readable bundle name
  name: string,
  /// One-line description
  description: string,
  /// Plugins included in this bundle
  plugins: array<string>,
  /// Plugin dependencies
  dependencies: array<pluginDependency>,
  /// Overall trust tier (highest of included plugins)
  trustTier: pluginTrustTier,
  /// Recommended isolation tier
  defaultIsolation: panelIsolation,
  /// Whether this is a built-in bundle
  builtIn: bool,
  /// Icon identifier
  icon: string,
  /// Target audience
  audience: string,
}

/// Source type for Groove services
type sourceType =
  /// Service provided by a panel
  | PanelSource(string)  // panelId
  /// Service provided by a plugin
  | PluginSource(string)  // pluginId

/// Groove service descriptor for unified discovery
type grooveService = {
  /// Service identifier
  id: string,
  /// Human-readable name
  name: string,
  /// Provided capabilities
  capabilities: array<string>,
  /// Endpoint URL
  endpoint: string,
  /// Source type (panel or plugin)
  sourceType: sourceType,
  /// Trust tier (for plugins)
  trustTier: option<pluginTrustTier>,
}

/// Bundle installation status
type bundleInstallStatus =
  /// Not installed
  | BundleNotInstalled
  /// Installing components
  | BundleInstalling(int, int)  // (installed, total)
  /// Fully installed
  | BundleInstalled
  /// Installation failed
  | BundleInstallFailed(string)

/// Configuration graph node
type configNode =
  /// Panel configuration
  | PanelConfigNode(panelConfig)
  /// Plugin configuration
  | PluginConfigNode(pluginConfig)
  /// Dependency reference
  | DependencyConfigNode(string)

/// Configuration graph - connects configs and dependencies
type configurationGraph = array<configNode>

/// Dependency declaration (panel or plugin)
type dependency =
  /// Panel dependency
  | PanelDependency(string)  // panelId
  /// Plugin dependency
  | PluginDependency(pluginDependency)

/// Deployment bundle - mixed panels and plugins
type deploymentBundle = {
  /// Bundle identifier
  id: string,
  /// Bundle name
  name: string,
  /// Panels in this deployment
  panels: array<string>,
  /// Plugins in this deployment
  plugins: array<string>,
  /// Unified Groove services
  grooveServices: array<grooveService>,
  /// Dependency graph
  dependencies: array<dependency>,
  /// Configuration graph
  configuration: configurationGraph,
  /// Installation status
  installStatus: bundleInstallStatus,
}

/// The complete Provisioner state.
type provisionerState = {
  /// Available portfolios (built-in + user-created).
  portfolios: array<portfolio>,
  /// Available plugin bundles.
  pluginBundles: array<pluginBundle>,
  /// Per-panel configurations.
  panelConfigs: array<panelConfig>,
  /// Per-plugin configurations.
  pluginConfigs: array<pluginConfig>,
  /// Installation status per panel name.
  panelInstallStatus: array<(string, panelInstallStatus)>,
  /// Installation status per plugin name.
  pluginInstallStatus: array<(string, panelInstallStatus)>,
  /// Current portfolio installation progress (if installing).
  installProgress: option<portfolioInstallProgress>,
  /// Current plugin bundle installation progress.
  pluginInstallProgress: option<portfolioInstallProgress>,
  /// Deployment bundles (mixed panels/plugins).
  deploymentBundles: array<deploymentBundle>,
  /// Active category tab.
  activeCategory: provisionerCategory,
  /// Current provisioning target.
  provisioningTarget: provisioningTarget,
  /// Text filter for searching portfolios/panels/plugins.
  filterText: string,
  /// Loading state.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Custom portfolio being built.
  customName: string,
  customPanels: array<string>,
  /// Custom plugin bundle being built.
  customPluginBundleName: string,
  customPluginBundlePlugins: array<string>,
  /// Custom deployment bundle being built.
  customDeploymentBundleName: string,
  customDeploymentPanels: array<string>,
  customDeploymentPlugins: array<string>,
}
