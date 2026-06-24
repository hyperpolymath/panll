// SPDX-License-Identifier: MPL-2.0

/// PanLL Network Topology Model — types for the IDApTIK in-game
/// network topology viewer. Displays force-directed graph of devices,
/// zones, security levels, packet flow, and DNS resolution.

/// Security zone classification for network devices.
type networkZone =
  | ZonePublic
  | ZoneDmz
  | ZoneInternal
  | ZoneRestricted
  | ZoneAirGapped

/// Connection protocol between devices.
type connectionProtocol =
  | ProtoSSH
  | ProtoHTTPS
  | ProtoFTP
  | ProtoDNS
  | ProtoCustom(string)

/// A network device in the game topology.
type networkDevice = {
  id: string,
  name: string,
  deviceType: string,
  zone: networkZone,
  securityLevel: int,
  x: float,
  y: float,
  defenceFlags: array<string>,
  compromised: bool,
  active: bool,
}

/// A connection (edge) between two devices.
type networkConnection = {
  sourceId: string,
  targetId: string,
  protocol: connectionProtocol,
  encrypted: bool,
  packetCount: int,
  latencyMs: float,
  active: bool,
}

/// A DNS resolution entry.
type dnsEntry = {
  hostname: string,
  resolvedIp: string,
  recordType: string,
  ttl: int,
}

/// Packet flow event for animation.
type packetFlowEvent = {
  connectionId: string,
  timestamp: float,
  size: int,
  blocked: bool,
}

/// Category tabs for the Network Topology panel.
type networkTopologyCategory =
  | TopologyGraph
  | TopologyZones
  | TopologyDns
  | TopologyPacketFlow

/// Root state for the Network Topology panel.
type networkTopologyState = {
  activeCategory: networkTopologyCategory,
  devices: array<networkDevice>,
  connections: array<networkConnection>,
  dnsEntries: array<dnsEntry>,
  packetFlow: array<packetFlowEvent>,
  selectedDeviceId: option<string>,
  highlightedPath: array<string>,
  showLabels: bool,
  showSecurityLevels: bool,
  animatePackets: bool,
  zoomLevel: float,
  loading: bool,
  error: option<string>,
}
