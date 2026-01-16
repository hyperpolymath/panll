// SPDX-License-Identifier: AGPL-3.0-or-later

/// PanLL Model - The unified state of the eNSAID environment.
///
/// This module defines the "Gravitational Centre" of the Binary Star system,
/// managing the synchronised state across all three panes.

/// Constraint types for the Symbolic Mass (Pane-L)
type constraint = {
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
  constraints: array<constraint>,
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
type paneWState = {
  content: string,
  topologyView: bool, // Binary Star diagram mode
  lastValidatedOutput: string,
}

/// Vexometer state
type vexometerState = {
  index: float, // 0.0 - 1.0
  recentCancellations: int,
  recentCorrections: int,
  antiInflammatoryActive: bool,
  inertiaDetected: bool,
}

/// Orbital stability metrics
type orbitalState = {
  stability: float, // sigma value
  divergenceLevel: float,
  driftAuraColour: string, // "indigo" or "amber"
}

/// Information Humidity level
type humidityLevel =
  | High // Low stress - show more detail
  | Medium
  | Low // High stress - shed visual noise

/// View mode for the environment
type viewMode =
  | Standard
  | Ambient // Memory Foam grid only
  | Zen // No sidebars/status
  | DarkStart // Architecture Manifold on idle

/// The complete Model
type model = {
  // Core panes
  paneL: paneLState,
  paneN: paneNState,
  paneW: paneWState,

  // Cognitive governance
  vexometer: vexometerState,
  orbital: orbitalState,
  humidity: humidityLevel,

  // View state
  viewMode: viewMode,
  paneLVisible: bool,
  paneNVisible: bool,
  paneWVisible: bool,
  protocolAnalysisVisible: bool,

  // Feedback-O-Tron
  feedbackPending: option<string>,
}

/// Initial model state - "Dark Start" mode
let init = (): model => {
  paneL: {
    constraints: [],
    activeConstraintId: None,
    editorContent: "",
  },
  paneN: {
    tokens: [],
    inferenceActive: false,
    monologue: "",
    agency: {
      phase: Observe,
      autonomyLevel: 0.0,
      lastOperatorInput: 0.0,
    },
  },
  paneW: {
    content: "",
    topologyView: true, // Start with Binary Star diagram
    lastValidatedOutput: "",
  },
  vexometer: {
    index: 0.0,
    recentCancellations: 0,
    recentCorrections: 0,
    antiInflammatoryActive: false,
    inertiaDetected: false,
  },
  orbital: {
    stability: 1.0,
    divergenceLevel: 0.0,
    driftAuraColour: "indigo",
  },
  humidity: Medium,
  viewMode: DarkStart,
  paneLVisible: true,
  paneNVisible: true,
  paneWVisible: true,
  protocolAnalysisVisible: false,
  feedbackPending: None,
}
