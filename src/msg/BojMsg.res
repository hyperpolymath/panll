// SPDX-License-Identifier: MPL-2.0

/// BoJ messages -- Bundle of Joy cartridge server interaction.

open Model

type bojMsg =
  /// Switch the active category tab.
  | SetBojCategory(bojCategory)
  /// Refresh BoJ server health check.
  | RefreshHealth
  /// Health check result.
  | HealthResult(result<string, string>)
  /// Refresh cartridge list.
  | RefreshCartridges
  /// Cartridge list result.
  | CartridgesResult(result<string, string>)
  /// Select a cartridge for detail view.
  | SelectCartridge(string)
  /// Load a cartridge into the runtime.
  | LoadCartridge(string)
  /// Unload a cartridge from the runtime.
  | UnloadCartridge(string)
  /// Load/unload result.
  | CartridgeActionResult(string, result<string, string>)
  /// Refresh topology data.
  | RefreshTopology
  /// Topology result.
  | TopologyResult(result<string, string>)
  /// Refresh Umoja federation status.
  | RefreshUmoja
  /// Umoja status result.
  | UmojaResult(result<string, string>)
  /// Disconnect a peer from the Umoja federation.
  | UmojaDisconnectPeer(string)
  /// Sync catalogue with a specific peer.
  | UmojaSyncCatalogue(string)
  /// View metrics for a specific peer.
  | UmojaPeerMetrics(string)
  /// Update the add-peer input field.
  | UmojaAddPeerInput(string)
  /// Add a new peer to the Umoja federation.
  | UmojaAddPeer(string)
  /// Trigger a manual gossip round.
  | UmojaTriggerGossip
  /// Result of adding a peer.
  | UmojaAddPeerResult(result<string, string>)
  /// Result of disconnecting a peer.
  | UmojaDisconnectPeerResult(result<string, string>)
  /// Result of triggering gossip round.
  | UmojaTriggerGossipResult(result<string, string>)
  /// Result of catalogue sync.
  | UmojaSyncCatalogueResult(result<string, string>)
  /// Result of peer metrics query.
  | UmojaPeerMetricsResult(result<string, string>)
  /// Set the cartridge for invocation.
  | SetInvokeCartridge(string)
  /// Set the tool name for invocation.
  | SetInvokeTool(string)
  /// Set the args JSON for invocation.
  | SetInvokeArgs(string)
  /// Execute the invocation.
  | ExecuteInvoke
  /// Invocation result.
  | InvokeResult(result<string, string>)
  /// Set filter text.
  | SetBojFilter(string)
  /// Dismiss the error banner.
  | DismissBojError
  /// TypeLL ABI type-check result for cartridge invocation.
  | AbiTypeCheckResult(result<string, string>)
