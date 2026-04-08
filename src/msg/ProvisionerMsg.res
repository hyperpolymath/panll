// SPDX-License-Identifier: PMPL-1.0-or-later

/// Provisioner messages -- portfolio bundling, panel configuration,
/// installation lifecycle, and isolation tier management.

open Model

type provisionerMsg =
  /// Switch category tab.
  | SetProvCategory(provisionerCategory)
  /// Update filter text.
  | SetProvFilter(string)
  /// Install all panels in a portfolio.
  | InstallPortfolio(string)
  /// Install a single panel.
  | InstallPanel(string)
  /// Remove a single panel (clean uninstall for pods).
  | RemovePanel(string)
  /// Installation result for a panel.
  | InstallResult(string, result<string, string>)
  /// Removal result for a panel.
  | RemoveResult(string, result<string, string>)
  /// Toggle a panel's enabled state.
  | TogglePanelEnabled(string)
  /// Set a panel's isolation tier.
  | SetPanelIsolation(string, panelIsolation)
  /// Update custom portfolio name.
  | SetCustomName(string)
  /// Toggle a panel in/out of the custom portfolio.
  | ToggleCustomPanel(string)
  /// Save the custom portfolio.
  | SaveCustomPortfolio
  /// Export panel configs and portfolios to ENSAID_CONFIG.a2ml.
  | ExportProvisionerConfig
  /// Toggle plugin auto-start setting.
  | TogglePlugin(string, bool)
  /// Install a plugin bundle.
  | InstallPluginBundle(string)
  /// Install a single plugin.
  | InstallPlugin(string)
  /// Remove a single plugin.
  | RemovePlugin(string)
  /// Installation result for a plugin.
  | PluginInstallResult(string, result<string, string>)
  /// Removal result for a plugin.
  | PluginRemoveResult(string, result<string, string>)
  /// Update custom plugin bundle name.
  | SetCustomPluginBundleName(string)
  /// Toggle a plugin in/out of the custom plugin bundle.
  | ToggleCustomPluginBundle(string)
  /// Save the custom plugin bundle.
  | SaveCustomPluginBundle
  /// Create a new deployment bundle.
  | CreateDeploymentBundle(deploymentBundle)
  /// TypeLL cross-panel type check result for portfolio config types.
  | TypeCheckResult(result<string, string>)
