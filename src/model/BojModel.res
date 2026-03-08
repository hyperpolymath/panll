// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL BoJ Model — types for the Bundle of Joy cartridge server panel.
///
/// BoJ is the unified cartridge runtime that absorbs all protocol domains
/// (MCP, LSP, DAP, BSP, etc.) through a 3-layer architecture:
///   Idris2 ABI (dependent types) → Zig FFI (C-compatible) → V-lang adapter (REST+gRPC+GraphQL)
///
/// 17 cartridges, each with a shared library (.so), hot-reloadable, SHA-256 verified.
/// Umoja federation provides distributed node discovery via gossip protocol.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Cartridge Types
// ============================================================================

/// Cartridge Readiness Grade (CRG) — maturity level of a cartridge.
///   D = Alpha (skeleton + basic tests)
///   C = Beta (integration tests, CI wired)
///   B = Release Candidate (benchmarks, docs, bindings)
///   A = Production (formally verified ABI, full test coverage)
type cartridgeGrade =
  | GradeD
  | GradeC
  | GradeB
  | GradeA

/// The 3-layer build status for a cartridge.
type layerStatus = {
  /// Idris2 ABI definition exists and compiles.
  abiReady: bool,
  /// Zig FFI implementation exists and tests pass.
  ffiReady: bool,
  /// V-lang triple adapter (REST+gRPC+GraphQL) exists.
  adapterReady: bool,
  /// Shared library (.so) built and SHA-256 verified.
  sharedLibReady: bool,
}

/// Protocol columns that a cartridge may support.
/// The capability matrix is cartridges (rows) × protocols (columns).
type protocolColumn =
  | ProtoMCP
  | ProtoLSP
  | ProtoDAP
  | ProtoBSP
  | ProtoNeSy
  | ProtoAgentic
  | ProtoFleet
  | ProtoGRPC
  | ProtoREST
  | ProtoGraphQL

/// A single cartridge in the BoJ runtime.
type bojCartridge = {
  /// Cartridge name (e.g. "database-mcp", "proof-mcp").
  name: string,
  /// Human-readable display name.
  displayName: string,
  /// One-line description.
  description: string,
  /// Readiness grade.
  grade: cartridgeGrade,
  /// Whether currently loaded in the runtime.
  loaded: bool,
  /// Protocol columns this cartridge supports.
  protocols: array<protocolColumn>,
  /// 3-layer build status.
  layers: layerStatus,
  /// SHA-256 hash of the .so file (for integrity verification).
  soHash: string,
  /// Port for the V-lang REST adapter (0 if not running).
  restPort: int,
  /// Port for the V-lang gRPC adapter (0 if not running).
  grpcPort: int,
  /// Port for the V-lang GraphQL adapter (0 if not running).
  graphqlPort: int,
}

// ============================================================================
// Umoja Federation Types
// ============================================================================

/// Peer node state in the Umoja gossip protocol.
type peerState =
  | PeerPending
  | PeerExchanged
  | PeerVerified
  | PeerRejected
  | PeerStale

/// A peer node in the Umoja federation network.
type umojaPeer = {
  /// Node identifier.
  nodeId: string,
  /// Node address (IP:port).
  address: string,
  /// Current handshake state.
  state: peerState,
  /// Round number in the gossip protocol.
  gossipRound: int,
  /// SHA-256 digest of the peer's cartridge catalogue.
  catalogueDigest: string,
  /// Last seen timestamp.
  lastSeen: float,
}

/// Umoja federation status.
type umojaStatus = {
  /// Whether the federation layer is active.
  active: bool,
  /// This node's ID.
  localNodeId: string,
  /// Known peers.
  peers: array<umojaPeer>,
  /// Current gossip round.
  currentRound: int,
}

// ============================================================================
// Invocation Types
// ============================================================================

/// An argument pair for a cartridge tool invocation.
type invokeArg = {
  key: string,
  value: string,
}

/// A latency measurement for a BoJ cartridge invocation.
type bojLatencyEntry = {
  cartridge: string,
  tool: string,
  durationMs: float,
  timestamp: float,
}

/// Result of a cartridge tool invocation.
type invokeResult = {
  /// Whether the invocation succeeded.
  success: bool,
  /// Response payload (JSON string).
  payload: string,
  /// Execution time in milliseconds.
  durationMs: int,
}

// ============================================================================
// Panel State
// ============================================================================

/// Category tabs for the BoJ panel.
type bojCategory =
  /// Overview dashboard — health, cartridge count, federation status.
  | Dashboard
  /// Cartridge matrix — 17 rows × protocol columns, load/unload controls.
  | Cartridges
  /// Topology view — architecture diagram and dependency graph.
  | Topology
  /// Umoja federation — peer nodes, gossip rounds, attestation.
  | Federation
  /// Invoke — select a cartridge, pick a tool, pass args, execute.
  | Invoke

/// Root state for the BoJ panel.
type bojState = {
  /// BoJ server URL (default: http://localhost:7700/api/v1).
  serverUrl: string,
  /// Whether the BoJ server is reachable.
  connected: bool,
  /// Last health check timestamp.
  lastHealthCheck: float,
  /// All known cartridges.
  cartridges: array<bojCartridge>,
  /// Selected cartridge name (for detail view / invocation).
  selectedCartridge: option<string>,
  /// Umoja federation status.
  umoja: umojaStatus,
  /// Active category tab.
  activeCategory: bojCategory,
  /// Invoke form state.
  invokeCartridge: string,
  invokeTool: string,
  invokeArgs: array<invokeArg>,
  /// Last invocation result.
  invokeResult: option<invokeResult>,
  /// Loading state.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Filter text for cartridge list.
  filterText: string,
  /// TypeLL ABI type-check result JSON for the last invocation (cross-panel intelligence).
  lastTypeCheck: option<string>,
  /// Recent invocation latency log (last 100 entries).
  latencyLog: array<bojLatencyEntry>,
}
