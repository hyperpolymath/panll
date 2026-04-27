// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ProvisionerEngine — Pure computation for portfolio provisioning.
///
/// Provides the built-in portfolio catalogue, isolation tier helpers,
/// configuration defaults, filtering, and installation state management.
/// All functions are pure — side effects happen in ProvisionerCmd.

open ProvisionerModel

/// Category tab labels for the Provisioner panel UI.
let categoryLabel = (cat: provisionerCategory): string => {
  switch cat {
  | Portfolios => "Portfolios"
  | PluginBundles => "Plugin Bundles"
  | Configurator => "Configurator"
  | Installed => "Installed"
  | CustomPortfolio => "Custom"
  | CustomPluginBundle => "Custom Plugin"
  | DeploymentBundles => "Deployments"
  }
}

/// Human-readable label for a panel isolation tier.
let isolationLabel = (tier: panelIsolation): string => {
  switch tier {
  | Native => "Native (in-process)"
  | StandardPod => "Standard Pod (Alpine)"
  | HardenedPod => "Hardened Pod (Chainguard)"
  }
}

/// Short label for compact display of isolation tier.
let isolationShortLabel = (tier: panelIsolation): string => {
  switch tier {
  | Native => "Native"
  | StandardPod => "Pod"
  | HardenedPod => "Hardened"
  }
}

/// CSS colour class for an isolation tier indicator.
let isolationColour = (tier: panelIsolation): string => {
  switch tier {
  | Native => "text-green-400"
  | StandardPod => "text-blue-400"
  | HardenedPod => "text-purple-400"
  }
}

// ============================================================================
// Plugin Bundle Helpers
// ============================================================================

/// Human-readable label for plugin trust tier.
let trustTierLabel = (tier: pluginTrustTier): string => {
  switch tier {
  | Teranga => "Teranga (Core)"
  | Shield => "Shield (Security)"
  | Ayo => "Ayo (Community)"
  }
}

/// Short label for plugin trust tier.
let trustTierShortLabel = (tier: pluginTrustTier): string => {
  switch tier {
  | Teranga => "Core"
  | Shield => "Security"
  | Ayo => "Community"
  }
}

/// CSS colour class for plugin trust tier.
let trustTierColour = (tier: pluginTrustTier): string => {
  switch tier {
  | Teranga => "text-yellow-400"
  | Shield => "text-red-400"
  | Ayo => "text-blue-400"
  }
}

/// Compose Groove services from a deployment bundle.
let composeGrooveServices = (bundle: deploymentBundle): array<grooveService> => {
  // Add services from panels
  let panelServices = bundle.panels->Array.map(panelId => {
    // In real implementation, look up panel capabilities
    // For now, create a basic UI service
    {
      id: panelId ++ "-ui",
      name: panelId ++ " UI",
      capabilities: ["ui", "panel"],
      endpoint: "/panels/" ++ panelId,
      sourceType: PanelSource(panelId),
      trustTier: None,
    }
  })

  // Add services from plugins
  let pluginServices = bundle.plugins->Array.flatMap(pluginId => {
    // In real implementation, look up plugin capabilities
    // For now, create services for common capabilities
    [
      {
        id: pluginId ++ "-main",
        name: pluginId ++ " Main",
        capabilities: ["backend", "api"],
        endpoint: "/plugins/" ++ pluginId,
        sourceType: PluginSource(pluginId),
        trustTier: Some(Ayo), // Default to community tier
      }
    ]
  })

  panelServices->Array.concat(pluginServices)
}

/// Create a configuration graph from panel and plugin configs.
let createConfigurationGraph = (
  panelConfigs: array<panelConfig>,
  pluginConfigs: array<pluginConfig>,
): configurationGraph => {
  panelConfigs->Array.map(config => PanelConfigNode(config))
  ->Array.concat(pluginConfigs->Array.map(config => PluginConfigNode(config)))
}

/// Get plugin bundle by ID.
let getPluginBundle = (
  bundles: array<pluginBundle>,
  bundleId: string,
): option<pluginBundle> => {
  bundles->Array.find(bundle => bundle.id === bundleId)
}

/// Check if a plugin bundle is installed.
let isPluginBundleInstalled = (
  bundle: pluginBundle,
  installStatuses: array<(string, panelInstallStatus)>,
): bool => {
  bundle.plugins->Array.every(pluginId => {
    installStatuses->Array.some(((id, status)) => {
      id === pluginId && status === Installed
    })
  })
}

/// Get plugin install status.
let getPluginInstallStatus = (
  installStatuses: array<(string, panelInstallStatus)>,
  pluginId: string,
): panelInstallStatus => {
  installStatuses->Array.find(((id, _status)) => id === pluginId)
  ->Option.map(((_, status)) => status)
  ->Option.getOr(NotInstalled)
}

// ============================================================================
// Deployment Bundle Helpers
// ============================================================================

/// Create a deployment bundle from panels and plugins.
let createDeploymentBundle = (
  name: string,
  panels: array<string>,
  plugins: array<string>,
  panelConfigs: array<panelConfig>,
  pluginConfigs: array<pluginConfig>,
): deploymentBundle => {
  {
    id: name->String.toLowerCase->String.replace(" ", "-"),
    name: name,
    panels: panels,
    plugins: plugins,
    grooveServices: composeGrooveServices({
      id: "temp",
      name: name,
      panels: panels,
      plugins: plugins,
      grooveServices: [],
      dependencies: [],
      configuration: createConfigurationGraph(panelConfigs, pluginConfigs),
      installStatus: BundleNotInstalled,
    }),
    dependencies: [],
    configuration: createConfigurationGraph(panelConfigs, pluginConfigs),
    installStatus: BundleNotInstalled,
  }
}

/// Check if a deployment bundle is fully installed.
let isDeploymentBundleInstalled = (bundle: deploymentBundle): bool => {
  switch bundle.installStatus {
  | BundleInstalled => true
  | _ => false
  }
}

// ============================================================================
// Plugin Management Helpers
// ============================================================================

/// Find panels that require a specific plugin.
let findPanelsRequiringPlugin = (
  pluginId: string,
  state: provisionerState,
): array<string> => {
  state.portfolios
  ->Array.filter(portfolio =>
    portfolio.panels->Array.some(panelId => {
      // In real implementation, check panel metadata
      // For now, simulate with some hardcoded dependencies
      (panelId === "Minter" && pluginId === "minter-plugin") ||
      (panelId === "Provisioner" && pluginId === "provisioner-plugin") ||
      (panelId === "Configurator" && pluginId === "config-plugin")
    })
  )
  ->Array.flatMap(portfolio => portfolio.panels)
  ->Array.reduce([], (acc, id) =>
    if acc->Array.includes(id) { acc } else { acc->Array.concat([id]) }
  )
}

/// Check if a plugin is safe to disable (not required by any panels).
let isSafeToDisablePlugin = (
  pluginId: string,
  state: provisionerState,
): bool => {
  let requiredByPanels = findPanelsRequiringPlugin(pluginId, state)->Array.length > 0
  let isCore = pluginId === "groove-core" || pluginId === "mcp-core"
  !requiredByPanels && !isCore
}

/// Check if a plugin is a core plugin (always loaded).
let isCorePlugin = (pluginId: string): bool => {
  pluginId === "groove-core" || pluginId === "mcp-core" || pluginId === "safety-core"
}

/// Get plugin configuration.
let getPluginConfig = (
  pluginId: string,
  state: provisionerState,
): option<pluginConfig> => {
  state.pluginConfigs->Array.find(config => config.pluginId === pluginId)
}

/// Check if plugin should be auto-loaded.
let shouldAutoLoadPlugin = (
  pluginId: string,
  state: provisionerState,
): bool => {
  // Auto-load if:
  // 1. It's a core plugin
  // 2. It's configured to auto-start
  // 3. It's required by any active panels
  isCorePlugin(pluginId) ||
  (getPluginConfig(pluginId, state)->Option.map(c => c.autoStart)->Option.getOr(false)) ||
  (findPanelsRequiringPlugin(pluginId, state)->Array.length > 0)
}

// ============================================================================
// Transitive Dependency Management
// ============================================================================

/// Get all dependencies (direct + transitive) for a plugin.
/// Uses iterative BFS via ref cells to avoid while-loop shadowing issues.
let getAllDependencies = (
  pluginId: string,
  state: provisionerState,
): array<string> => {
  let allDeps: ref<array<string>> = ref([])
  let visited: ref<array<string>> = ref([])
  let queue: ref<array<string>> = ref([pluginId])

  while (queue.contents->Array.length > 0) {
    let current = queue.contents->Array.getUnsafe(0)
    queue := queue.contents->Array.sliceToEnd(~start=1)
    if !(visited.contents->Array.includes(current)) {
      visited := visited.contents->Array.concat([current])

      // Find direct dependencies of current plugin
      let directDeps = state.pluginBundles
        ->Array.flatMap(bundle => bundle.dependencies)
        ->Array.filter(dep => dep.pluginId === current)
        ->Array.map(dep => dep.pluginId)

      allDeps := allDeps.contents->Array.concat(directDeps)
      queue := queue.contents->Array.concat(directDeps)
    }
  }

  allDeps.contents->Array.reduce([], (acc, id) =>
    if acc->Array.includes(id) { acc } else { acc->Array.concat([id]) }
  )
}

/// Check for circular dependencies.
let hasCircularDependencies = (
  pluginId: string,
  state: provisionerState,
): bool => {
  let visited: ref<array<string>> = ref([])
  let recursionStack: ref<array<string>> = ref([])

  let rec checkCircular = (id: string): bool => {
    if (recursionStack.contents->Array.includes(id)) {
      true  // Circular dependency found
    } else if (visited.contents->Array.includes(id)) {
      false  // Already checked, no circle
    } else {
      visited := visited.contents->Array.concat([id])
      recursionStack := recursionStack.contents->Array.concat([id])

      // Get direct dependencies
      let directDeps = state.pluginBundles
        ->Array.flatMap(bundle => bundle.dependencies)
        ->Array.filter(dep => dep.pluginId === id)
        ->Array.map(dep => dep.pluginId)

      // Check each dependency
      directDeps->Array.some(depId => checkCircular(depId))
    }
  }

  checkCircular(pluginId)
}

/// Impact analysis - what breaks if we disable this plugin?
type impactAnalysis = {
  directUsers: array<string>,
  transitiveUsers: array<string>,
  totalImpact: int,
  safeToDisable: bool,
}

let getImpactOfDisablingPlugin = (
  pluginId: string,
  state: provisionerState,
): impactAnalysis => {
  let directUsers = findPanelsRequiringPlugin(pluginId, state)
  let transitiveUsers = state.portfolios
    ->Array.filter(portfolio =>
      portfolio.panels->Array.some(panelId =>
        getAllDependencies(panelId, state)->Array.includes(pluginId)
      )
    )
    ->Array.flatMap(portfolio => portfolio.panels)
    ->Array.reduce([], (acc, id) =>
      if acc->Array.includes(id) { acc } else { acc->Array.concat([id]) }
    )

  {
    directUsers: directUsers,
    transitiveUsers: transitiveUsers,
    totalImpact: directUsers->Array.length + transitiveUsers->Array.length,
    safeToDisable: directUsers->Array.length === 0 && transitiveUsers->Array.length === 0,
  }
}

/// Build dependency graph for visualization.
type dependencyGraphNode = {
  id: string,
  name: string,
  dependencies: array<string>,
  dependents: array<string>,
}

let buildDependencyGraph = (
  state: provisionerState,
): array<dependencyGraphNode> => {
  // Collect all plugins
  let allPlugins = state.pluginBundles
    ->Array.flatMap(bundle => bundle.plugins)
    ->Array.concat(state.pluginConfigs->Array.map(c => c.pluginId))
    ->Array.reduce([], (acc, id) =>
      if acc->Array.includes(id) { acc } else { acc->Array.concat([id]) }
    )

  allPlugins->Array.map(pluginId => {
    let directDeps = state.pluginBundles
      ->Array.flatMap(bundle => bundle.dependencies)
      ->Array.filter(dep => dep.pluginId === pluginId)
      ->Array.map(dep => dep.pluginId)

    let dependents = state.portfolios
      ->Array.flatMap(portfolio => portfolio.panels)
      ->Array.filter(panelId => 
        findPanelsRequiringPlugin(pluginId, state)->Array.includes(panelId)
      )

    {
      id: pluginId,
      name: pluginId,  // Would use plugin name in real implementation
      dependencies: directDeps,
      dependents: dependents,
    }
  })
}

// ============================================================================
// Version Resolution System
// ============================================================================

/// Semantic version components
type semver = {
  major: int,
  minor: int,
  patch: int,
  preRelease: option<string>,
  build: option<string>,
}

/// Parse semantic version string
let parseSemver = (version: string): option<semver> => {
  // Simple parser - would use regex in real implementation
  try {
    let parts = version
      ->String.split("-")
      ->Array.getUnsafe(0)
      ->String.split("+")
      ->Array.getUnsafe(0)
      ->String.split(".")

    if (parts->Array.length < 3) {
      None
    } else {
      Some({
        major: int_of_string(parts->Array.getUnsafe(0)),
        minor: int_of_string(parts->Array.getUnsafe(1)),
        patch: int_of_string(parts->Array.getUnsafe(2)),
        preRelease: parts->Array.length > 3 ? Some(parts->Array.getUnsafe(3)) : None,
        build: None,
      })
    }
  } catch {
  | _ => None
  }
}

/// Compare two semantic versions
let compareSemver = (a: semver, b: semver): int => {
  // Major version
  if (a.major > b.major) { 1 }
  else if (a.major < b.major) { -1 }
  // Minor version
  else if (a.minor > b.minor) { 1 }
  else if (a.minor < b.minor) { -1 }
  // Patch version
  else if (a.patch > b.patch) { 1 }
  else if (a.patch < b.patch) { -1 }
  // Pre-release
  else if (a.preRelease->Option.isSome && b.preRelease->Option.isNone) { -1 }
  else if (a.preRelease->Option.isNone && b.preRelease->Option.isSome) { 1 }
  else { 0 }
}

/// Check if version satisfies requirement
let satisfiesSemver = (version: string, requirement: string): bool => {
  let v = parseSemver(version)
  let r = parseSemver(requirement)
  
  if (v->Option.isNone || r->Option.isNone) {
    false
  } else {
    let v = v->Option.getExn
    let r = r->Option.getExn
    
    // Exact match
    if (requirement->String.startsWith("=")) {
      compareSemver(v, r) === 0
    }
    // Greater than or equal
    else if (requirement->String.startsWith(">=")) {
      compareSemver(v, r) >= 0
    }
    // Greater than
    else if (requirement->String.startsWith(">")) {
      compareSemver(v, r) > 0
    }
    // Less than or equal
    else if (requirement->String.startsWith("<=")) {
      compareSemver(v, r) <= 0
    }
    // Less than
    else if (requirement->String.startsWith("<")) {
      compareSemver(v, r) < 0
    }
    // Caret (^1.2.3 = >=1.2.3 <2.0.0)
    else if (requirement->String.startsWith("^")) {
      let reqParts = requirement->String.slice(~start=1, ~end=String.length(requirement))->String.split(".")
      compareSemver(v, r) >= 0 &&
      (v.major === r.major || (reqParts->Array.length === 1))
    }
    // Tilde (~1.2.3 = >=1.2.3 <1.3.0)
    else if (requirement->String.startsWith("~")) {
      let reqParts = requirement->String.slice(~start=1, ~end=String.length(requirement))->String.split(".")
      compareSemver(v, r) >= 0 &&
      v.major === r.major &&
      (reqParts->Array.length <= 2 || v.minor === r.minor)
    }
    // Default: exact match
    else {
      compareSemver(v, r) === 0
    }
  }
}

/// Get latest version satisfying requirement
let getLatestSatisfyingVersion = (
  pluginId: string,
  requirement: string,
  state: provisionerState,
): option<string> => {
  // In real implementation, would query plugin registry
  // For now, simulate with some mock versions
  let mockVersions = ["1.0.0", "1.2.0", "1.2.3", "2.0.0", "2.1.0"]
  
  let filtered = mockVersions->Array.filter(version => satisfiesSemver(version, requirement))
  filtered->Array.sort((a, b) => {
    let aParsed = parseSemver(a)->Option.getExn
    let bParsed = parseSemver(b)->Option.getExn
    Int.toFloat(-compareSemver(aParsed, bParsed))  // Descending
  })
  filtered->Array.get(0)
}

/// Resolve plugin version from multiple requirements
let resolvePluginVersion = (
  pluginId: string,
  requirements: array<string>,
  state: provisionerState,
): option<string> => {
  // If no requirements, use latest
  if (requirements->Array.length === 0) {
    getLatestSatisfyingVersion(pluginId, ">=0.0.0", state)
  } else if (requirements->Array.length === 1) {
    // If single requirement, use that
    getLatestSatisfyingVersion(pluginId, requirements->Array.getUnsafe(0), state)
  } else {
    // Multiple requirements - find common version
    let mockVersions = ["1.0.0", "1.2.0", "1.2.3", "2.0.0", "2.1.0"]
    let satisfying = mockVersions->Array.filter(version =>
      requirements->Array.every(req => satisfiesSemver(version, req))
    )
    satisfying->Array.sort((a, b) => {
      let aParsed = parseSemver(a)->Option.getExn
      let bParsed = parseSemver(b)->Option.getExn
      Int.toFloat(-compareSemver(aParsed, bParsed))  // Descending
    })
    satisfying->Array.get(0)
  }
}

/// Check if all plugin dependencies can be satisfied
type resolutionResult =
  | Resolved(array<(string, string)>)
  | Conflict(array<string>)
  | NotFound(array<string>)

/// Check if OPSM is available for advanced resolution
let isOpsmAvailable = (): bool => {
  // In real implementation, would check via RuntimeBridge
  // For now, return false (no OPSM)
  false
}

/// Resolve with OPSM (if available) as fallback
let resolveWithOpsmFallback = (
  pluginId: string,
  requirements: array<string>,
  state: provisionerState,
): option<string> => {
  if (isOpsmAvailable()) {
    // Would call OPSM resolver via RuntimeBridge
    // For now, simulate with simple resolution
    resolvePluginVersion(pluginId, requirements, state)
  } else {
    resolvePluginVersion(pluginId, requirements, state)
  }
}

let resolveAllDependencies = (
  pluginId: string,
  state: provisionerState,
): resolutionResult => {
  // Get all transitive dependencies
  let allDeps = getAllDependencies(pluginId, state)
  
  // Deduplicate dependency list
  let depsByPlugin = allDeps->Array.reduce([], (acc, depId) =>
    if acc->Array.includes(depId) { acc } else { acc->Array.concat([depId]) }
  )

  // For each plugin, get requirements and resolve
  let results = depsByPlugin->Array.map(depId => {
    let requirements = state.pluginBundles
      ->Array.flatMap(bundle => bundle.dependencies)
      ->Array.filter(dep => dep.pluginId === depId)
      ->Array.map(dep => dep.version)
    (depId, resolveWithOpsmFallback(depId, requirements, state))
  })

  // Check for failures
  let failures = results->Array.filter(((_, result)) => result->Option.isNone)

  if (failures->Array.length > 0) {
    NotFound(failures->Array.map(((depId, _)) => depId))
  } else {
    Resolved(results->Array.map(((depId, result)) => (depId, result->Option.getExn)))
  }
}

/// Human-readable label for panel installation status.
let installStatusLabel = (status: panelInstallStatus): string => {
  switch status {
  | NotInstalled => "Not installed"
  | Installing => "Installing..."
  | Installed => "Installed"
  | InstallFailed(e) => `Failed: ${e}`
  | Removing => "Removing..."
  }
}

/// CSS colour class for install status.
let installStatusColour = (status: panelInstallStatus): string => {
  switch status {
  | NotInstalled => "text-gray-500"
  | Installing => "text-amber-400"
  | Installed => "text-green-400"
  | InstallFailed(_) => "text-red-400"
  | Removing => "text-amber-400"
  }
}

/// The built-in portfolio catalogue — ships with PanLL.
///
/// Each portfolio bundles panels that make sense together for a specific
/// workflow or audience. Users can also create custom portfolios.
let builtInPortfolios: array<portfolio> = [
  {
    id: "security-ops",
    name: "Security Operations",
    description: "Domain security, network diagnostics, and vulnerability management",
    panels: ["CloudGuard", "Aerie", "Fleet", "Hypatia"],
    defaultIsolation: Native,
    builtIn: true,
    icon: "shield",
    audience: "Security engineers and DevSecOps teams",
  },
  {
    id: "repo-governance",
    name: "Repository Governance",
    description: "Repo inventory, RSR compliance, licensing, and bot orchestration",
    panels: ["Farm", "Reposystem", "Plaza", "Fleet"],
    defaultIsolation: Native,
    builtIn: true,
    icon: "git-branch",
    audience: "Maintainers managing large repo collections",
  },
  {
    id: "formal-verification",
    name: "Formal Verification",
    description: "Theorem proving, ABI/FFI inventory, server assembly, and proof provenance",
    panels: ["VAB", "Interfaces", "Playgrounds"],
    defaultIsolation: Native,
    builtIn: true,
    icon: "check-circle",
    audience: "Developers working with formal methods and proven code",
  },
  {
    id: "neurosymbolic-dev",
    name: "Neurosymbolic Development",
    description: "Full neurosymbolic stack: scanning, fleet dispatch, database tools, playgrounds",
    panels: ["Hypatia", "Fleet", "Playgrounds", "Databases"],
    defaultIsolation: Native,
    builtIn: true,
    icon: "brain",
    audience: "Developers building AI-integrated systems with safety constraints",
  },
  {
    id: "full-stack",
    name: "Full Stack (All Panels)",
    description: "Everything PanLL offers — all 13 panels. For power users who want the complete control surface.",
    panels: [
      "VAB",
      "CloudGuard",
      "Farm",
      "Plaza",
      "Minter",
      "Fleet",
      "Hypatia",
      "Reposystem",
      "Databases",
      "Aerie",
      "Interfaces",
      "Playgrounds",
    ],
    defaultIsolation: Native,
    builtIn: true,
    icon: "layers",
    audience: "Power users and the hyperpolymath ecosystem",
  },
  {
    id: "getting-started",
    name: "Getting Started",
    description: "A gentle introduction: repo overview, code playground, and panel creation",
    panels: ["Farm", "Playgrounds", "Minter"],
    defaultIsolation: Native,
    builtIn: true,
    icon: "rocket",
    audience: "New users exploring PanLL for the first time",
  },
]

/// Generate default configuration for a panel.
///
/// Core panels (the 13 built-in) default to Native isolation.
/// Everything else defaults to StandardPod for safety.
let defaultConfig = (panelName: string): panelConfig => {
  let corePanel =
    panelName === "VAB" ||
    panelName === "CloudGuard" ||
    panelName === "Farm" ||
    panelName === "Plaza" ||
    panelName === "Minter" ||
    panelName === "Fleet" ||
    panelName === "Hypatia" ||
    panelName === "Reposystem" ||
    panelName === "Databases" ||
    panelName === "Aerie" ||
    panelName === "Interfaces" ||
    panelName === "Playgrounds"

  {
    panelName,
    endpoint: "",
    autoConnect: false,
    isolation: corePanel ? Native : StandardPod,
    envVars: [],
    enabled: true,
  }
}

/// Filter portfolios by search text (matches name or description).
let filterPortfolios = (portfolios: array<portfolio>, filterText: string): array<portfolio> => {
  if filterText === "" {
    portfolios
  } else {
    let lower = String.toLowerCase(filterText)
    portfolios->Array.filter(p =>
      String.includes(String.toLowerCase(p.name), lower) ||
      String.includes(String.toLowerCase(p.description), lower)
    )
  }
}

/// Get the install status for a panel by name.
let getInstallStatus = (
  statuses: array<(string, panelInstallStatus)>,
  panelName: string,
): panelInstallStatus => {
  switch statuses->Array.find(((name, _)) => name === panelName) {
  | Some((_, status)) => status
  | None => NotInstalled
  }
}

/// Count installed panels.
let countInstalled = (statuses: array<(string, panelInstallStatus)>): int => {
  statuses->Array.filter(((_, status)) => status === Installed)->Array.length
}

/// Count panels by isolation tier.
let countByIsolation = (configs: array<panelConfig>, tier: panelIsolation): int => {
  configs->Array.filter(c => c.isolation === tier && c.enabled)->Array.length
}

/// Default provisioner state with built-in portfolios and core panel configs.
let defaultState: provisionerState = {
  portfolios: builtInPortfolios,
  panelConfigs: [
    defaultConfig("VAB"),
    defaultConfig("CloudGuard"),
    defaultConfig("Farm"),
    defaultConfig("Plaza"),
    defaultConfig("Minter"),
    defaultConfig("Fleet"),
    defaultConfig("Hypatia"),
    defaultConfig("Reposystem"),
    defaultConfig("Databases"),
    defaultConfig("Aerie"),
    defaultConfig("Interfaces"),
    defaultConfig("Playgrounds"),
  ],
  panelInstallStatus: [
    ("VAB", Installed),
    ("CloudGuard", Installed),
    ("Farm", Installed),
    ("Plaza", Installed),
    ("Minter", Installed),
    ("Fleet", Installed),
    ("Hypatia", Installed),
    ("Reposystem", Installed),
    ("Databases", Installed),
    ("Aerie", Installed),
    ("Interfaces", Installed),
    ("Playgrounds", Installed),
  ],
  installProgress: None,
  activeCategory: Portfolios,
  filterText: "",
  loading: false,
  error: None,
  customName: "",
  customPanels: [],
  // Plugin bundle defaults
  pluginBundles: [],
  pluginConfigs: [],
  pluginInstallStatus: [],
  pluginInstallProgress: None,
  customPluginBundleName: "",
  customPluginBundlePlugins: [],
  // Deployment bundle defaults
  deploymentBundles: [],
  customDeploymentBundleName: "",
  customDeploymentPanels: [],
  customDeploymentPlugins: [],
  // Default provisioning target
  provisioningTarget: PanelTarget,
}
