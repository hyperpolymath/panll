// SPDX-License-Identifier: MPL-2.0

/// PanLL Network Topology Engine — pure computation and helpers for the
/// IDApTIK in-game network topology viewer.

open NetworkTopologyModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: networkTopologyCategory): string =>
  switch cat {
  | TopologyGraph => "Graph"
  | TopologyZones => "Zones"
  | TopologyDns => "DNS"
  | TopologyPacketFlow => "Packet Flow"
  }

/// Human-readable labels for network zones.
let zoneLabel = (zone: networkZone): string =>
  switch zone {
  | ZonePublic => "Public"
  | ZoneDmz => "DMZ"
  | ZoneInternal => "Internal"
  | ZoneRestricted => "Restricted"
  | ZoneAirGapped => "Air-Gapped"
  }

/// Tailwind colour class for each zone.
let zoneColour = (zone: networkZone): string =>
  switch zone {
  | ZonePublic => "text-red-400"
  | ZoneDmz => "text-amber-400"
  | ZoneInternal => "text-emerald-400"
  | ZoneRestricted => "text-blue-400"
  | ZoneAirGapped => "text-purple-400"
  }

/// Background colour class for each zone.
let zoneBgColour = (zone: networkZone): string =>
  switch zone {
  | ZonePublic => "bg-red-900/30"
  | ZoneDmz => "bg-amber-900/30"
  | ZoneInternal => "bg-emerald-900/30"
  | ZoneRestricted => "bg-blue-900/30"
  | ZoneAirGapped => "bg-purple-900/30"
  }

/// Human-readable protocol label.
let protocolLabel = (proto: connectionProtocol): string =>
  switch proto {
  | ProtoSSH => "SSH"
  | ProtoHTTPS => "HTTPS"
  | ProtoFTP => "FTP"
  | ProtoDNS => "DNS"
  | ProtoCustom(name) => name
  }

/// Count devices per zone.
let devicesByZone = (devices: array<networkDevice>, zone: networkZone): array<networkDevice> =>
  devices->Array.filter(d => d.zone === zone)

/// Find connections involving a device.
let connectionsForDevice = (connections: array<networkConnection>, deviceId: string): array<
  networkConnection,
> => connections->Array.filter(c => c.sourceId === deviceId || c.targetId === deviceId)

/// Default state for the Network Topology panel.
let defaultState: networkTopologyState = {
  activeCategory: TopologyGraph,
  devices: [],
  connections: [],
  dnsEntries: [],
  packetFlow: [],
  selectedDeviceId: None,
  highlightedPath: [],
  showLabels: true,
  showSecurityLevels: true,
  animatePackets: false,
  zoomLevel: 1.0,
  loading: false,
  error: None,
}
