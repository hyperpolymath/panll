// SPDX-License-Identifier: PMPL-1.0-or-later

/// Network Topology messages -- topology reading, device selection,
/// packet flow animation, DNS browsing, and display toggles for the
/// IDApTIK in-game network topology viewer.

open Model

type networkTopologyMsg =
  /// Switch the active category tab.
  | SetTopologyCategory(networkTopologyCategory)
  /// Read the network topology from the running game.
  | RefreshTopology
  /// Topology data received.
  | TopologyReceived(result<string, string>)
  /// Select a device by ID.
  | SelectDevice(string)
  /// Deselect the current device.
  | DeselectDevice
  /// Read DNS resolution table.
  | RefreshDns
  /// DNS data received.
  | DnsReceived(result<string, string>)
  /// Toggle packet flow animation.
  | TogglePacketAnimation
  /// Packet flow data received.
  | PacketFlowReceived(result<string, string>)
  /// Toggle device name labels.
  | ToggleLabels
  /// Toggle security level indicators.
  | ToggleSecurityLevels
  /// Export topology as SVG.
  | ExportTopologySvg
  /// SVG exported (or failed).
  | TopologySvgExported(result<string, string>)
  /// Dismiss the error banner.
  | DismissTopoError
  /// TypeLL cross-panel type check result for topology types.
  | TypeCheckResult(result<string, string>)
