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
  | Configurator => "Configurator"
  | Installed => "Installed"
  | CustomPortfolio => "Custom"
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
  configs: [
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
  installStatus: [
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
}
