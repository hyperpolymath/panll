// SPDX-License-Identifier: PMPL-1.0-or-later

/// SystemUpdateModule — PanLL panel harness for system component updates.
///
/// Treats every updatable component on the system as a data source:
///   - rpm-ostree (Fedora Atomic base OS layer)
///   - Flatpak (sandboxed desktop apps)
///   - asdf plugins (33 language toolchains)
///   - Cargo binaries (Rust CLI tools)
///   - Deno/Bun (JS runtimes)
///   - GHCup (Haskell toolchain)
///   - opam (OCaml packages)
///   - mix (Elixir hex/rebar)
///   - Julia packages
///   - pipx (Python CLI tools)
///   - fwupd (firmware)
///
/// Each component exposes:
///   - Current version
///   - Latest available version
///   - Update status (up-to-date, update-available, updating, failed)
///   - Last checked timestamp
///   - Update action
///
/// The panel renders as a three-panel view:
///   Panel-L: Component registry with version constraints and compatibility rules
///   Panel-N: Update dependency analysis (which updates are safe to apply together)
///   Panel-W: Live update progress, logs, and history
///
/// PanelHarness discovers this via panels/manifest.json and wires it into
/// any PanLL workspace automatically.

/// Update status for a single component.
type updateStatus =
  | UpToDate
  | UpdateAvailable(string) // new version string
  | Updating
  | Failed(string) // error message
  | Unknown

/// Component category — groups components in the UI.
type componentCategory =
  | BaseOS // rpm-ostree
  | Desktop // Flatpak
  | Toolchain // asdf-managed language runtimes
  | PackageManager // cargo, mix, opam, etc.
  | Runtime // deno, bun
  | Firmware // fwupd

/// A single updatable component.
type component = {
  id: string,
  name: string,
  category: componentCategory,
  currentVersion: string,
  latestVersion: option<string>,
  status: updateStatus,
  lastChecked: option<string>,
  managed_by: string, // "asdf", "rpm-ostree", "flatpak", "cargo", etc.
}

/// Summary of all component states.
type updateSummary = {
  totalComponents: int,
  upToDate: int,
  updatesAvailable: int,
  updating: int,
  failed: int,
  lastFullUpdate: option<string>,
}

/// Actions available for the update panel.
type updateAction =
  | CheckAll // Scan all components for available updates
  | CheckComponent(string) // Scan a single component by ID
  | UpdateAll // Apply all available updates
  | UpdateComponent(string) // Apply update to a single component
  | UpdateCategory(componentCategory) // Update all in a category
  | ViewLogs // Show update log history
  | ViewSummary // Show last update summary

/// Gossamer command names for the Rust backend.
/// Each maps to a command in src-gossamer/src/system_update/commands.rs
module Commands = {
  /// List all components with current/latest versions.
  /// Returns: array<component>
  let listComponents = "system_update_list_components"

  /// Check for updates on all components.
  /// Returns: updateSummary
  let checkAll = "system_update_check_all"

  /// Check a single component for updates.
  /// Arg: component_id (string)
  /// Returns: component
  let checkComponent = "system_update_check_component"

  /// Apply update to a single component.
  /// Arg: component_id (string)
  /// Returns: {success: bool, output: string}
  let updateComponent = "system_update_apply_component"

  /// Apply all available updates.
  /// Returns: {success: bool, output: string, summary: updateSummary}
  let updateAll = "system_update_apply_all"

  /// Get asdf plugin details.
  /// Returns: array<{plugin: string, installed: string, latest: string}>
  let asdfStatus = "system_update_asdf_status"

  /// Get update log history.
  /// Returns: array<{timestamp: string, summary: string}>
  let logs = "system_update_logs"

  /// Get last summary.
  /// Returns: string (content of last-summary.txt)
  let lastSummary = "system_update_last_summary"
}

/// Module configuration for PanLL registration.
let moduleConfig = {
  "id": "system-update",
  "name": "System Update",
  "description": "Component update management — asdf, rpm-ostree, flatpak, cargo, and more",
  "clade": "infrastructure/system-maintenance",
  "icon": "system-software-update",
  "capabilities": [
    "component-listing", // List all updatable components
    "version-checking", // Check current vs latest versions
    "update-execution", // Apply updates
    "log-history", // View past update logs
    "category-management", // Group and filter by category
    "asdf-integration", // Deep asdf plugin management
  ],
}

/// Category display names for the UI.
let categoryLabel = (cat: componentCategory) => {
  switch cat {
  | BaseOS => "Base OS (rpm-ostree)"
  | Desktop => "Desktop Apps (Flatpak)"
  | Toolchain => "Toolchains (asdf)"
  | PackageManager => "Package Managers"
  | Runtime => "Runtimes"
  | Firmware => "Firmware"
  }
}

/// Category sort order for the UI.
let categorySortOrder = (cat: componentCategory) => {
  switch cat {
  | BaseOS => 0
  | Firmware => 1
  | Toolchain => 2
  | Runtime => 3
  | PackageManager => 4
  | Desktop => 5
  }
}

/// Status badge color for the UI.
let statusColor = (status: updateStatus) => {
  switch status {
  | UpToDate => "#2ecc71" // green
  | UpdateAvailable(_) => "#f39c12" // amber
  | Updating => "#3498db" // blue
  | Failed(_) => "#e74c3c" // red
  | Unknown => "#95a5a6" // grey
  }
}

/// Status label for display.
let statusLabel = (status: updateStatus) => {
  switch status {
  | UpToDate => "Up to date"
  | UpdateAvailable(v) => "Update available: " ++ v
  | Updating => "Updating..."
  | Failed(e) => "Failed: " ++ e
  | Unknown => "Unknown"
  }
}
