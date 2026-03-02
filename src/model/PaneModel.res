// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Pane State Types — Pane-L (Symbolic), Pane-N (Neural), Pane-W (World).
///
/// These types define the three core panes of the Binary Star co-orbit model.
/// Pane-L holds formal constraints and the symbolic editor. Pane-N holds the
/// neural inference stream with its token log, monologue, and agency monitor.
/// Pane-W holds the world/task barycentre including security tools, event chain
/// analysis, and the panic-attacker integration.
///
/// This module has NO dependencies on other PanLL modules — it is the leaf
/// of the type dependency graph.
///
/// ON VARIANT TYPES: Each OODA phase below (`Observe | Orient | Decide | Act`)
/// is a ReScript variant — a tagged union the compiler understands structurally.
/// In TypeScript you'd write `type OodaPhase = "observe" | "orient" | ...` which
/// looks similar, but the compiler can't enforce exhaustive matching (you need a
/// manual `default: throw` or `satisfies never` trick that's easy to forget, and
/// which won't catch new additions at compile time across files). ReScript's
/// `switch` on variants is exhaustive by default — miss a case, get a compile
/// error. At 14 panels with dozens of variant types each, this single property
/// has prevented more bugs than any linter rule could.

/// Constraint types for the Symbolic Mass (Pane-L)
type symbolicConstraint = {
  id: string,
  expression: string,
  active: bool,
  pinned: bool, // Sticky Constraints feature
}

/// Neural token with metadata
type neuralToken = {
  content: string,
  timestamp: float,
  confidence: float,
  validated: bool, // Has passed Anti-Crash validation
}

/// OODA loop phase for Thing-Agency Monitor
type oodaPhase =
  | Observe
  | Orient
  | Decide
  | Act

/// Autonomy indicator for HTI
type agencyState = {
  phase: oodaPhase,
  autonomyLevel: float, // 0.0 = fully instructed, 1.0 = fully autonomous
  lastOperatorInput: float, // timestamp
}

/// Pane-L: Symbolic Mass (Noumena)
type paneLState = {
  constraints: array<symbolicConstraint>,
  activeConstraintId: option<string>,
  editorContent: string,
}

/// Pane-N: Neural Stream (Phenomena)
type paneNState = {
  tokens: array<neuralToken>,
  inferenceActive: bool,
  monologue: string,
  agency: agencyState,
}

/// Pane-W: World/Task Barycentre
/// Events are created from panic-attack/panll exports and feed the Time/Space
/// study view; each event carries axis/duration/intensity metadata.
type eventChainEvent = {
  id: string,
  axis: string,
  startMs: option<float>,
  durationMs: float,
  intensity: string,
  status: string,
  peakMemory: option<float>,
  notes: option<string>,
}

type eventChainSummary = {
  program: string,
  weakPoints: int,
  criticalWeakPoints: int,
  totalCrashes: int,
  robustnessScore: float,
}

type eventChainTimeline = {
  durationMs: float,
  events: int,
}

/// The Pane-W state tracks the world view (content/topology), the imported
/// panic-attacker event-chain, and the security dialog fields that run ambush
/// tooling. Keeping these annotations clarifies how the UI state mirrors the
/// backend command lifecycle.
type paneWState = {
  content: string,
  topologyView: bool, // Binary Star diagram mode
  lastValidatedOutput: string,
  eventChain: array<eventChainEvent>,
  eventChainSummary: option<eventChainSummary>,
  eventChainTimeline: option<eventChainTimeline>,
  eventChainInput: string,
  eventChainError: option<string>,
  panicAttackerMode: string, // unknown | full | fallback | unavailable
  panicAttackerBinary: option<string>,
  panicAttackerStatusDetail: option<string>,
  securityTarget: string,
  securityTimeline: string,
  securityAxes: string,
  securityIntensity: string,
  securityDuration: string,
  securityStatus: option<string>,
  securityError: option<string>,
  securityMenuExpanded: bool,
  securityDialogOpen: bool,
  securityDialogTool: option<string>,
  securityViewActive: bool,
}
