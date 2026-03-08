// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL BoJ Engine — pure helpers for the Bundle of Joy cartridge server panel.
///
/// All functions are pure (no side effects). State transformations, display
/// helpers, filtering, and default values live here.

open BojModel

/// Label for a category tab.
let categoryLabel = (cat: bojCategory): string => {
  switch cat {
  | Dashboard => "Dashboard"
  | Cartridges => "Cartridges"
  | Topology => "Topology"
  | Federation => "Federation"
  | Invoke => "Invoke"
  }
}

/// Display string for a cartridge grade.
let gradeLabel = (grade: cartridgeGrade): string => {
  switch grade {
  | GradeD => "D (Alpha)"
  | GradeC => "C (Beta)"
  | GradeB => "B (RC)"
  | GradeA => "A (Production)"
  }
}

/// Colour class for a cartridge grade badge.
let gradeColour = (grade: cartridgeGrade): string => {
  switch grade {
  | GradeD => "bg-yellow-900/50 text-yellow-300 border-yellow-700"
  | GradeC => "bg-blue-900/50 text-blue-300 border-blue-700"
  | GradeB => "bg-emerald-900/50 text-emerald-300 border-emerald-700"
  | GradeA => "bg-green-900/50 text-green-300 border-green-700"
  }
}

/// Display string for a protocol column.
let protocolLabel = (proto: protocolColumn): string => {
  switch proto {
  | ProtoMCP => "MCP"
  | ProtoLSP => "LSP"
  | ProtoDAP => "DAP"
  | ProtoBSP => "BSP"
  | ProtoNeSy => "NeSy"
  | ProtoAgentic => "Agentic"
  | ProtoFleet => "Fleet"
  | ProtoGRPC => "gRPC"
  | ProtoREST => "REST"
  | ProtoGraphQL => "GraphQL"
  }
}

/// Short label for protocol column (matrix header).
let protocolShort = (proto: protocolColumn): string => {
  switch proto {
  | ProtoMCP => "MCP"
  | ProtoLSP => "LSP"
  | ProtoDAP => "DAP"
  | ProtoBSP => "BSP"
  | ProtoNeSy => "NeSy"
  | ProtoAgentic => "Agent"
  | ProtoFleet => "Fleet"
  | ProtoGRPC => "gRPC"
  | ProtoREST => "REST"
  | ProtoGraphQL => "GQL"
  }
}

/// Display string for a peer state.
let peerStateLabel = (state: peerState): string => {
  switch state {
  | PeerPending => "Pending"
  | PeerExchanged => "Exchanged"
  | PeerVerified => "Verified"
  | PeerRejected => "Rejected"
  | PeerStale => "Stale"
  }
}

/// Colour class for a peer state badge.
let peerStateColour = (state: peerState): string => {
  switch state {
  | PeerPending => "text-yellow-400"
  | PeerExchanged => "text-blue-400"
  | PeerVerified => "text-green-400"
  | PeerRejected => "text-red-400"
  | PeerStale => "text-gray-500"
  }
}

/// Count loaded cartridges.
let loadedCount = (cartridges: array<bojCartridge>): int => {
  cartridges->Array.filter(c => c.loaded)->Array.length
}

/// Count cartridges by grade.
let countByGrade = (cartridges: array<bojCartridge>, grade: cartridgeGrade): int => {
  cartridges->Array.filter(c => c.grade === grade)->Array.length
}

/// Filter cartridges by text (name or description).
let filterCartridges = (cartridges: array<bojCartridge>, text: string): array<bojCartridge> => {
  if text === "" {
    cartridges
  } else {
    let lower = String.toLowerCase(text)
    cartridges->Array.filter(c =>
      String.toLowerCase(c.name)->String.includes(lower) ||
      String.toLowerCase(c.displayName)->String.includes(lower) ||
      String.toLowerCase(c.description)->String.includes(lower)
    )
  }
}

/// Check whether a cartridge supports a given protocol.
let hasProtocol = (cartridge: bojCartridge, proto: protocolColumn): bool => {
  cartridge.protocols->Array.some(p => p === proto)
}

/// All protocol columns in display order.
let allProtocols: array<protocolColumn> = [
  ProtoMCP, ProtoLSP, ProtoDAP, ProtoBSP, ProtoNeSy,
  ProtoAgentic, ProtoFleet, ProtoGRPC, ProtoREST, ProtoGraphQL,
]

/// Layer readiness as a fraction string (e.g. "3/4").
let layerProgress = (layers: layerStatus): string => {
  let count = (if layers.abiReady { 1 } else { 0 })
    + (if layers.ffiReady { 1 } else { 0 })
    + (if layers.adapterReady { 1 } else { 0 })
    + (if layers.sharedLibReady { 1 } else { 0 })
  `${Int.toString(count)}/4`
}

/// Default BoJ panel state.
let defaultState: bojState = {
  serverUrl: "http://localhost:7700/api/v1",
  connected: false,
  lastHealthCheck: 0.0,
  cartridges: [],
  selectedCartridge: None,
  umoja: {
    active: false,
    localNodeId: "",
    peers: [],
    currentRound: 0,
  },
  activeCategory: Dashboard,
  invokeCartridge: "",
  invokeTool: "",
  invokeArgs: [],
  invokeResult: None,
  loading: false,
  error: None,
  filterText: "",
}
