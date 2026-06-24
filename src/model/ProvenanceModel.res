// SPDX-License-Identifier: MPL-2.0

/// PanLL ProvenanceModel — Code trust surface types.
///
/// The Provenance Map is CORE INFRASTRUCTURE, always visible as an ambient
/// layer over every panel. It uses Qubes-style semantic colours to show
/// who wrote each piece of code and how trustworthy it is.
///
/// Colour semantics are FIXED — they cannot be reconfigured:
///   Green  = formally verified (proof-checked, no believe_me)
///   Blue   = human-reviewed (human author or human commit after AI)
///   Amber  = AI-assisted (co-authored, no subsequent human review)
///   Red    = unreviewed AI (pure AI, no human in chain)
///   Grey   = unknown/ancient (pre-git or no attribution)
///
/// Accessibility palettes swap hues but NEVER meanings. Shape, position,
/// and label provide redundant channels beyond colour alone.

/// The trust level of a piece of code, derived from git blame + Co-Authored-By
/// parsing. This enum has FIXED semantic meaning — do not reorder or rename.
type trustLevel =
  /// Formally verified: proof-checked by ECHIDNA or equivalent, zero believe_me,
  /// zero sorry, zero Admitted. The highest trust. Colour: green.
  | Verified
  /// Human-reviewed: written by a human, or AI-generated code that has been
  /// subsequently committed by a human (review chain intact). Colour: blue.
  | HumanReviewed
  /// AI-assisted: co-authored (human + AI), but no subsequent human-only commit
  /// has reviewed the AI portions. Trust is partial. Colour: amber.
  | AiAssisted
  /// Unreviewed AI: purely AI-generated with no human in the commit chain.
  /// Triggers hostile UX (pulsing border, vexometer spike). Colour: red.
  | UnreviewedAi
  /// Unknown provenance: pre-git history, missing attribution, or ancient code
  /// where the commit chain is lost. Not alarming but not trusted. Colour: grey.
  | Unknown

/// A single line or region of code with its provenance attribution.
type provenanceRegion = {
  /// Starting line number (1-indexed, inclusive).
  startLine: int,
  /// Ending line number (1-indexed, inclusive).
  endLine: int,
  /// The trust level derived from blame analysis.
  trustLevel: trustLevel,
  /// The author name from git blame.
  author: string,
  /// The author email from git blame.
  authorEmail: string,
  /// Whether a Co-Authored-By trailer was present on the commit.
  coAuthored: bool,
  /// The co-author name, if any.
  coAuthor: option<string>,
  /// The commit SHA for this region.
  commitSha: string,
  /// Commit timestamp (Unix seconds).
  commitTimestamp: float,
  /// Whether the region has been explicitly acknowledged (dismissed hostile UX).
  acknowledged: bool,
}

/// Summary statistics for a file's provenance.
type provenanceSummary = {
  /// Total lines analysed.
  totalLines: int,
  /// Lines at each trust level.
  verifiedLines: int,
  humanReviewedLines: int,
  aiAssistedLines: int,
  unreviewedAiLines: int,
  unknownLines: int,
  /// Number of distinct authors.
  authorCount: int,
  /// Number of distinct co-authors (AI tools).
  coAuthorCount: int,
  /// Whether any region triggers hostile UX (unreviewed AI present).
  hasViolations: bool,
  /// Count of believe_me / sorry / Admitted found in verified regions
  /// (should be zero — if nonzero, the Verified trust level is wrong).
  unsoundMarkers: int,
}

/// A file's complete provenance analysis.
type fileProvenance = {
  /// The file path (relative to repo root).
  filePath: string,
  /// Per-region provenance data.
  regions: array<provenanceRegion>,
  /// Aggregate statistics.
  summary: provenanceSummary,
  /// When this analysis was last computed (Unix timestamp).
  analysedAt: float,
}

/// Accessibility palette — swaps hues but preserves semantic positions.
/// Each palette provides colours for the five trust levels in order:
/// [verified, humanReviewed, aiAssisted, unreviewedAi, unknown].
type accessibilityPalette =
  /// Default palette: green, blue, amber, red, grey.
  | StandardPalette
  /// Deuteranopia-safe: teal, blue, yellow, magenta, grey.
  | DeuteranopiaPalette
  /// Protanopia-safe: cyan, blue, orange, magenta, grey.
  | ProtanopiaPalette
  /// High-contrast: white-on-green, white-on-blue, black-on-yellow, white-on-red, grey.
  | HighContrastPalette

/// State of the Provenance Map subsystem.
type provenanceState = {
  /// Whether provenance analysis is enabled (always on by default).
  enabled: bool,
  /// The currently active file's provenance (if any file is focused).
  activeFile: option<fileProvenance>,
  /// Cache of recently analysed files (keyed by path).
  cache: array<fileProvenance>,
  /// The active accessibility palette.
  palette: accessibilityPalette,
  /// Whether the hostile UX is active (pulsing borders on unreviewed AI).
  hostileUxActive: bool,
  /// Whether the user has globally suppressed hostile UX (smoke alarm battery pulled).
  hostileUxSuppressed: bool,
  /// Loading state for git blame analysis.
  loading: bool,
  /// Error from the last analysis attempt.
  error: option<string>,
}

/// Node in the provenance DAG — represents a single artefact in the supply chain.
type dagNodeKind =
  /// Source code file with trust analysis.
  | SourceNode
  /// Build artefact (compiled output, bundle, .so).
  | BuildNode
  /// External dependency (crate, npm package, opam package).
  | DependencyNode
  /// Proof artefact (ECHIDNA discharge, Coq proof term).
  | ProofNode
  /// Signing/attestation event (SLSA, Sigstore, in-toto).
  | AttestationNode

/// A single node in the provenance DAG.
type dagNode = {
  /// Unique node identifier (content-addressable hash preferred).
  id: string,
  /// Human-readable label for the node.
  label: string,
  /// The kind of artefact this node represents.
  kind: dagNodeKind,
  /// Trust level inherited from provenance analysis.
  trustLevel: trustLevel,
  /// SHA-256 or BLAKE3 content hash.
  contentHash: string,
  /// Timestamp of artefact creation (Unix ms).
  createdAt: float,
  /// Whether this node has been formally verified.
  verified: bool,
}

/// An edge in the provenance DAG — a dependency or derivation relationship.
type dagEdge = {
  /// Source node ID (the dependency).
  fromId: string,
  /// Target node ID (the dependent).
  toId: string,
  /// Relationship label (e.g. "compiles-to", "depends-on", "proves", "signs").
  relation: string,
  /// Whether this edge has been verified (e.g. hash chain intact).
  verified: bool,
}

/// The complete provenance DAG for a project or workspace.
type provenanceDag = {
  /// All nodes in the graph.
  nodes: array<dagNode>,
  /// All edges in the graph.
  edges: array<dagEdge>,
  /// The root node IDs (entry points with no incoming edges).
  roots: array<string>,
  /// The leaf node IDs (final artefacts with no outgoing edges).
  leaves: array<string>,
  /// When this DAG was last computed.
  computedAt: float,
}

// ===========================================================================
// Code MRI Layer 1 — Blake3 Provenance Chain Types
// ===========================================================================

/// A single entry in the provenance hash chain.
///
/// Each entry links to its parent via `parentHash`, forming a tamper-evident
/// chain. The `hash` field is computed deterministically from (content, author,
/// timestamp, parentHash), so any modification to any field invalidates the
/// chain from that point onward.
///
/// The `attribution` field tracks the origin of the code region:
///   - "human"      — written entirely by a human
///   - "ai:claude"  — generated by Claude
///   - "ai:copilot" — generated by GitHub Copilot
///   - "mixed"      — human + AI co-authored
///   - "imported"   — brought in from an external source
type provenanceChainEntry = {
  /// The computed hash of this entry (hex-encoded, deterministic).
  hash: string,
  /// Hash of the previous entry in the chain ("0" for genesis).
  parentHash: string,
  /// The code content this entry covers.
  content: string,
  /// The author who committed this region.
  author: string,
  /// ISO 8601 timestamp of the commit.
  timestamp: string,
  /// Origin classification: "human", "ai:claude", "ai:copilot", "mixed", "imported".
  attribution: string,
}
