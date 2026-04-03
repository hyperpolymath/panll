// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Clade Browser Model — types for exploring and customising panel clades.
///
/// A clade is a taxonomic group that defines shared traits, capabilities,
/// and inheritance for panels. The Clade Browser lets users explore all 36+
/// clades, see which panels belong to each, inspect traits, and filter
/// by kind (ai, bridge, builder, database, directive, loader, meta,
/// network, scanner, terminal, viewer).

/// The 11 clade kinds defined in the PanLL taxonomy.
type cladeKind =
  | KindAi
  | KindBridge
  | KindBuilder
  | KindDatabase
  | KindDirective
  | KindLoader
  | KindMeta
  | KindNetwork
  | KindScanner
  | KindTerminal
  | KindViewer
  | KindAll

// ═══════════════════════════════════════════════════════════════════════
// Tier 1.1: Protocol adapters — which wire protocols a clade speaks.
// ═══════════════════════════════════════════════════════════════════════

/// Wire protocol that a clade can expose or consume.
type cladeProtocol =
  /// Language Server Protocol — code intelligence, diagnostics, completion.
  | ProtoLSP
  /// Debug Adapter Protocol — breakpoints, stepping, variable inspection.
  | ProtoDAP
  /// Build Server Protocol — compile, test, run, dependency resolution.
  | ProtoBSP
  /// Model Context Protocol — AI tool integration (resources, tools, prompts).
  | ProtoMCP
  /// REST over HTTP — traditional request/response API.
  | ProtoREST
  /// gRPC — binary protocol with Protobuf, bidirectional streaming.
  | ProtoGRPC
  /// GraphQL — query language with subscriptions.
  | ProtoGraphQL
  /// WebSocket — full-duplex persistent connection.
  | ProtoWebSocket
  /// Server-Sent Events — unidirectional server-to-client streaming.
  | ProtoSSE
  /// Gossamer IPC — inter-process communication via Gossamer invoke/listen.
  | ProtoGossamerIPC
  /// Unix Domain Socket — local process-to-process communication.
  | ProtoUnixSocket
  /// D-Bus — Linux desktop IPC (notifications, file pickers, portals).
  | ProtoDBus
  /// Stdio — JSON-RPC over stdin/stdout (LSP/DAP/MCP transport).
  | ProtoStdio

// ═══════════════════════════════════════════════════════════════════════
// Tier 1.2: Typed capability declarations — what a clade can actually do.
// ═══════════════════════════════════════════════════════════════════════

/// Specific capability that a clade provides beyond boolean traits.
type cladeCapability =
  /// Can read/write to the local filesystem.
  | CapFilesystem
  /// Can make outbound network requests.
  | CapNetwork
  /// Can access the system clipboard.
  | CapClipboard
  /// Can spawn child processes.
  | CapProcessSpawn
  /// Can access the system shell (PTY).
  | CapShell
  /// Can run in a container/sandbox.
  | CapContainerised
  /// Can accept real-time streaming data.
  | CapStreaming
  /// Can produce formal proofs or proof obligations.
  | CapProofProduction
  /// Can consume formal proofs for verification.
  | CapProofConsumption
  /// Can perform type checking or type inference.
  | CapTypeChecking
  /// Can scan for security issues.
  | CapSecurityScan
  /// Can manage secrets or credentials.
  | CapSecretManagement
  /// Can render rich visualisations (graphs, charts, heatmaps).
  | CapVisualisation
  /// Can record or replay user sessions.
  | CapSessionRecording

// ═══════════════════════════════════════════════════════════════════════
// Tier 1.3: Dependency graph — requires/provides relationships.
// ═══════════════════════════════════════════════════════════════════════

/// A dependency declaration: what a clade requires or provides.
type cladeDependency = {
  /// The clade ID this dependency refers to.
  cladeId: string,
  /// Whether this is a hard requirement or a soft enhancement.
  required: bool,
  /// Human-readable reason for the dependency.
  reason: string,
}

// ═══════════════════════════════════════════════════════════════════════
// Tier 1.4: Error boundary — per-clade fault isolation level.
// ═══════════════════════════════════════════════════════════════════════

/// Fault isolation level for a clade's panels.
type cladeIsolation =
  /// No isolation — crash in this panel may affect others.
  | IsolationNone
  /// Soft isolation — errors are caught and displayed inline.
  | IsolationSoft
  /// Process isolation — runs in a separate process (Extension Host model).
  | IsolationProcess
  /// Container isolation — runs in a Podman/MicroVM container.
  | IsolationContainer

// ═══════════════════════════════════════════════════════════════════════
// Tier 4: Security & Supply Chain — signing, SBOM, capability sandbox.
// ═══════════════════════════════════════════════════════════════════════

/// Signing status for a clade (Sigstore / SLSA).
type cladeSigningStatus =
  /// Not signed — no provenance verification.
  | SigningNone
  /// Signed but not verified in this session.
  | SigningPending
  /// Signed and verified (includes keyless Sigstore or PGP).
  | SigningVerified(string) // signer identity
  /// Verification failed.
  | SigningFailed(string) // reason

/// SBOM (Software Bill of Materials) summary for a clade.
type cladeSbom = {
  /// SBOM format (CycloneDX or SPDX).
  format: string,
  /// Number of direct dependencies.
  directDeps: int,
  /// Number of transitive dependencies.
  transitiveDeps: int,
  /// Known vulnerabilities count.
  knownVulns: int,
  /// License compliance status.
  licenseCompliant: bool,
}

/// Capability sandbox policy — what a clade is allowed to do at runtime.
type cladeSandboxPolicy = {
  /// Maximum allowed capabilities (subset of cladeCapability).
  allowedCapabilities: array<cladeCapability>,
  /// Whether network access is rate-limited.
  networkRateLimit: option<int>,
  /// Whether filesystem access is restricted to specific paths.
  fsAllowedPaths: array<string>,
  /// Whether process spawning requires user approval.
  processApprovalRequired: bool,
}

/// Traits that a clade can confer on its panels.
type cladeTraits = {
  hasPersistence: bool,
  hasBackend: bool,
  hasWorkItems: bool,
  hasRealTime: bool,
  isAmbient: bool,
}

/// A single clade entry in the browser.
type cladeEntry = {
  id: string,
  name: string,
  kind: string,
  version: string,
  summary: string,
  longDescription: string,
  traits: cladeTraits,
  panelIds: array<string>,
  consumedBy: array<string>,
  supersedes: array<string>,
  /// Parent clade ID for trait inheritance (e.g. "bridge" for BoJ).
  parentCladeId: option<string>,
  /// Sibling clades in the taxonomy.
  siblingClades: array<string>,
  /// Tier 1.1: Wire protocols this clade exposes.
  protocols: array<cladeProtocol>,
  /// Tier 1.2: Typed capabilities this clade provides.
  capabilities: array<cladeCapability>,
  /// Tier 1.3: Clades this one requires to function.
  requires: array<cladeDependency>,
  /// Tier 1.3: Clades this one enhances (soft dependency from the other side).
  enhances: array<string>,
  /// Tier 1.4: Fault isolation level.
  isolation: cladeIsolation,
  /// Tier 4: Signing status.
  signing: cladeSigningStatus,
  /// Tier 4: SBOM summary (if available).
  sbom: option<cladeSbom>,
  /// Tier 4: Sandbox policy.
  sandbox: option<cladeSandboxPolicy>,
}

/// Category tabs for the clade browser.
type cladeBrowserCategory =
  | CategoryOverview
  | CategoryByKind
  | CategoryTraits
  | CategoryPanelMap

/// Permission level for cross-clade references.
type cladePermission =
  /// Unrestricted — any clade can reference this one.
  | PermitAll
  /// Restricted to specific clade IDs.
  | PermitOnly(array<string>)
  /// Denied — no cross-clade references allowed.
  | PermitNone

/// A clade permission rule: which clades can cross-reference a target clade.
type cladePermissionRule = {
  /// The clade that is being referenced (target).
  targetCladeId: string,
  /// Who is allowed to reference it.
  permission: cladePermission,
}

/// Root state for the clade browser.
type cladeBrowserState = {
  category: cladeBrowserCategory,
  clades: array<cladeEntry>,
  selectedClade: option<string>,
  kindFilter: cladeKind,
  searchQuery: string,
  loading: bool,
  error: option<string>,
  /// Cross-clade permission rules (which clades may reference which).
  permissionRules: array<cladePermissionRule>,
}

/// Default initial state.
let defaultState: cladeBrowserState = {
  category: CategoryOverview,
  clades: [],
  selectedClade: None,
  kindFilter: KindAll,
  searchQuery: "",
  loading: false,
  error: None,
  permissionRules: [],
}
