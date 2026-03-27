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
  ProtoMCP,
  ProtoLSP,
  ProtoDAP,
  ProtoBSP,
  ProtoNeSy,
  ProtoAgentic,
  ProtoFleet,
  ProtoGRPC,
  ProtoREST,
  ProtoGraphQL,
]

/// Layer readiness as a fraction string (e.g. "3/4").
let layerProgress = (layers: layerStatus): string => {
  let count =
    if layers.abiReady {
      1
    } else {
      0
    } +
    if layers.ffiReady {
      1
    } else {
      0
    } +
    if layers.adapterReady {
      1
    } else {
      0
    } + if layers.sharedLibReady {
      1
    } else {
      0
    }
  `${Int.toString(count)}/4`
}

// ============================================================================
// JSON Parsing Helpers
// ============================================================================

/// Parse a grade string into a cartridgeGrade variant.
let parseGrade = (s: string): cartridgeGrade => {
  switch String.toLowerCase(s) {
  | "a" | "gradea" | "production" => GradeA
  | "b" | "gradeb" | "rc" => GradeB
  | "c" | "gradec" | "beta" => GradeC
  | _ => GradeD
  }
}

/// Parse a protocol string into a protocolColumn variant.
let parseProtocol = (s: string): option<protocolColumn> => {
  switch String.toLowerCase(s) {
  | "mcp" => Some(ProtoMCP)
  | "lsp" => Some(ProtoLSP)
  | "dap" => Some(ProtoDAP)
  | "bsp" => Some(ProtoBSP)
  | "nesy" => Some(ProtoNeSy)
  | "agentic" => Some(ProtoAgentic)
  | "fleet" => Some(ProtoFleet)
  | "grpc" => Some(ProtoGRPC)
  | "rest" => Some(ProtoREST)
  | "graphql" => Some(ProtoGraphQL)
  | _ => None
  }
}

/// Parse a peer state string into a peerState variant.
let parsePeerState = (s: string): peerState => {
  switch String.toLowerCase(s) {
  | "exchanged" => PeerExchanged
  | "verified" => PeerVerified
  | "rejected" => PeerRejected
  | "stale" => PeerStale
  | _ => PeerPending
  }
}

/// Helper: extract a string from a JSON object dict.
let getStringFromObj = (obj: Dict.t<JSON.t>, key: string): string =>
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | String(s) => s
    | _ => ""
    }
  | None => ""
  }

/// Helper: extract an int from a JSON object dict.
let getIntFromObj = (obj: Dict.t<JSON.t>, key: string): int =>
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | Number(n) => Float.toInt(n)
    | _ => 0
    }
  | None => 0
  }

/// Helper: extract a float from a JSON object dict.
let getFloatFromObj = (obj: Dict.t<JSON.t>, key: string): float =>
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | Number(n) => n
    | _ => 0.0
    }
  | None => 0.0
  }

/// Helper: extract a bool from a JSON object dict.
let getBoolFromObj = (obj: Dict.t<JSON.t>, key: string): bool =>
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | Bool(b) => b
    | _ => false
    }
  | None => false
  }

/// Parse a single cartridge JSON object into a bojCartridge record.
let parseCartridgeObj = (obj: Dict.t<JSON.t>): bojCartridge => {
  // Parse protocols array.
  let protocols = switch Dict.get(obj, "protocols") {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | Array(arr) =>
      arr->Array.filterMap(item =>
        switch JSON.Classify.classify(item) {
        | String(s) => parseProtocol(s)
        | _ => None
        }
      )
    | _ => []
    }
  | None => []
  }
  // Parse layers object.
  let layers = switch Dict.get(obj, "layers") {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | Object(layerObj) => {
        abiReady: getBoolFromObj(layerObj, "abiReady"),
        ffiReady: getBoolFromObj(layerObj, "ffiReady"),
        adapterReady: getBoolFromObj(layerObj, "adapterReady"),
        sharedLibReady: getBoolFromObj(layerObj, "sharedLibReady"),
      }
    | _ => {abiReady: false, ffiReady: false, adapterReady: false, sharedLibReady: false}
    }
  | None => {abiReady: false, ffiReady: false, adapterReady: false, sharedLibReady: false}
  }
  {
    name: getStringFromObj(obj, "name"),
    displayName: getStringFromObj(obj, "displayName"),
    description: getStringFromObj(obj, "description"),
    grade: parseGrade(getStringFromObj(obj, "grade")),
    loaded: getBoolFromObj(obj, "loaded"),
    protocols,
    layers,
    soHash: getStringFromObj(obj, "soHash"),
    restPort: getIntFromObj(obj, "restPort"),
    grpcPort: getIntFromObj(obj, "grpcPort"),
    graphqlPort: getIntFromObj(obj, "graphqlPort"),
  }
}

/// Tea_Json decoder for a single cartridge, bridging the existing parseCartridgeObj parser.
let cartridgeDecoder: Tea_Json.decoder<bojCartridge> = json => {
  switch json {
  | Object(dict) => Ok(parseCartridgeObj(dict))
  | _ => Error(Tea_Json.Failure("Expected an object for cartridge", json))
  }
}

/// Tea_Json decoder for a cartridges array.
let cartridgesDecoder: Tea_Json.decoder<array<bojCartridge>> = Decoders.lenientArray(
  cartridgeDecoder,
)

/// Parse a JSON string containing an array of cartridge objects.
let parseCartridges = (json: string): result<array<bojCartridge>, string> =>
  Decoders.decode(cartridgesDecoder, json)

/// Tea_Json decoder for a single peer, bridging the existing value-level helpers.
let peerDecoder: Tea_Json.decoder<umojaPeer> = json => {
  switch json {
  | Object(peerObj) =>
    Ok({
      nodeId: getStringFromObj(peerObj, "nodeId"),
      address: getStringFromObj(peerObj, "endpoint"),
      state: parsePeerState(getStringFromObj(peerObj, "state")),
      gossipRound: getIntFromObj(peerObj, "currentRound"),
      catalogueDigest: getStringFromObj(peerObj, "catalogueDigest"),
      lastSeen: getFloatFromObj(peerObj, "loadFactor"),
    })
  | _ => Error(Tea_Json.Failure("Expected an object for peer", json))
  }
}

/// Tea_Json decoder for Umoja federation status.
let umojaStatusDecoder: Tea_Json.decoder<umojaStatus> = {
  open Decoders
  open Tea_Json
  map4((active, localNodeId, peers, currentRound): umojaStatus => {
    active,
    localNodeId,
    peers,
    currentRound,
  }, boolField(
    "active",
  ), stringField(
    "localNodeId",
  ), fieldWithDefault("peers", lenientArray(peerDecoder), []), intField("currentRound"))
}

/// Parse a JSON string containing Umoja federation status.
let parseUmojaStatus = (json: string): result<umojaStatus, string> =>
  Decoders.decode(umojaStatusDecoder, json)

/// Tea_Json decoder for topology diagram data.
/// Extracts the "diagram" field as a plain string.
let topologyDecoder: Tea_Json.decoder<string> = Decoders.stringField("diagram")

/// Parse a JSON string containing topology diagram data.
/// Extracts the "diagram" field as a plain string.
let parseTopology = (json: string): result<string, string> => Decoders.decode(topologyDecoder, json)

/// Default BoJ panel state.
let defaultState: bojState = {
  serverUrl: ServiceEndpoints.bojServer,
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
  lastTypeCheck: None,
  latencyLog: [],
  umojaAddPeerInput: "",
}
