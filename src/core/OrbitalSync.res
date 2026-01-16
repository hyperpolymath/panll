// SPDX-License-Identifier: AGPL-3.0-or-later

/// OrbitalSync Module - Pane Synchronisation
///
/// Implements the "Semantic Synchronisation" between Pane-L, Pane-N,
/// and Pane-W. Ensures the Binary Star co-orbit maintains gravitational
/// coherence across all three panes.

open Model

/// Synchronisation event types
type syncEvent =
  | SymbolicUpdate(string)   // Change in Pane-L
  | NeuralUpdate(string)     // Change in Pane-N
  | WorldUpdate(string)      // Change in Pane-W
  | CrossPaneLink(string, string) // Link between panes

/// Synchronisation state
type syncState = {
  lastSymbolicHash: string,
  lastNeuralHash: string,
  lastWorldHash: string,
  pendingSync: array<syncEvent>,
  syncLatency: float, // milliseconds
}

/// Initial sync state
let init = (): syncState => {
  lastSymbolicHash: "",
  lastNeuralHash: "",
  lastWorldHash: "",
  pendingSync: [],
  syncLatency: 0.0,
}

/// Simple hash function for change detection
let simpleHash = (content: string): string => {
  // Simple hash based on content length and first/last chars
  // In production, use a proper hash function
  let len = String.length(content)
  if len === 0 {
    "empty"
  } else {
    let first = String.charAt(content, 0)
    let last = String.charAt(content, len - 1)
    `${Int.toString(len)}-${first}-${last}`
  }
}

/// Detect changes in Pane-L
let detectSymbolicChanges = (paneL: paneLState, state: syncState): option<syncEvent> => {
  let currentHash = simpleHash(paneL.editorContent)
  if currentHash !== state.lastSymbolicHash {
    Some(SymbolicUpdate(paneL.editorContent))
  } else {
    None
  }
}

/// Detect changes in Pane-N
let detectNeuralChanges = (paneN: paneNState, state: syncState): option<syncEvent> => {
  let currentHash = simpleHash(paneN.monologue)
  if currentHash !== state.lastNeuralHash {
    Some(NeuralUpdate(paneN.monologue))
  } else {
    None
  }
}

/// Detect changes in Pane-W
let detectWorldChanges = (paneW: paneWState, state: syncState): option<syncEvent> => {
  let currentHash = simpleHash(paneW.content)
  if currentHash !== state.lastWorldHash {
    Some(WorldUpdate(paneW.content))
  } else {
    None
  }
}

/// Calculate divergence between symbolic and neural content
let calculateDivergence = (paneL: paneLState, paneN: paneNState): float => {
  // Simple divergence calculation based on content similarity
  // In production, use semantic similarity measures
  let symbolicLen = String.length(paneL.editorContent)
  let neuralLen = String.length(paneN.monologue)

  if symbolicLen === 0 && neuralLen === 0 {
    0.0
  } else if symbolicLen === 0 || neuralLen === 0 {
    1.0
  } else {
    // Calculate difference ratio
    let diff = Int.toFloat(abs(symbolicLen - neuralLen))
    let maxLen = Int.toFloat(max(symbolicLen, neuralLen))
    Float.Math.min(1.0, diff /. maxLen)
  }
}

/// Calculate orbital stability based on divergence and sync latency
let calculateStability = (divergence: float, latency: float): float => {
  // Stability decreases with divergence and latency
  let divergencePenalty = divergence *. 0.6
  let latencyPenalty = Float.Math.min(0.4, latency /. 1000.0) // Normalize latency to 0-0.4

  Float.Math.max(0.0, 1.0 -. divergencePenalty -. latencyPenalty)
}

/// Determine drift aura colour based on stability
let getDriftAuraColour = (stability: float): string => {
  if stability >= 0.7 {
    "indigo" // Stable co-orbit
  } else {
    "amber" // Orbital decay detected
  }
}

/// Process synchronisation for the model
let sync = (model: model, state: syncState): (syncState, orbitalState) => {
  // Detect all changes
  let symbolicChange = detectSymbolicChanges(model.paneL, state)
  let neuralChange = detectNeuralChanges(model.paneN, state)
  let worldChange = detectWorldChanges(model.paneW, state)

  // Collect pending events
  let newEvents = [symbolicChange, neuralChange, worldChange]
    ->Array.filter(Option.isSome)
    ->Array.map(opt => Option.getExn(opt))

  // Update hashes
  let newState = {
    lastSymbolicHash: simpleHash(model.paneL.editorContent),
    lastNeuralHash: simpleHash(model.paneN.monologue),
    lastWorldHash: simpleHash(model.paneW.content),
    pendingSync: newEvents,
    syncLatency: state.syncLatency, // Would be measured in real implementation
  }

  // Calculate orbital metrics
  let divergence = calculateDivergence(model.paneL, model.paneN)
  let stability = calculateStability(divergence, state.syncLatency)
  let auraColour = getDriftAuraColour(stability)

  let orbital = {
    stability,
    divergenceLevel: divergence,
    driftAuraColour: auraColour,
  }

  (newState, orbital)
}

/// Create a cross-pane link (Circuit Lines feature)
let createCrossLink = (sourcePane: string, targetPane: string, content: string): syncEvent => {
  CrossPaneLink(sourcePane ++ ":" ++ content, targetPane)
}

/// Get Information Humidity level based on model state
let getHumidityLevel = (model: model): humidityLevel => {
  let vexation = model.vexometer.index
  let stability = model.orbital.stability

  // High stress = Low humidity (shed visual noise)
  // Low stress = High humidity (reveal more detail)
  if vexation > 0.7 || stability < 0.4 {
    Low
  } else if vexation > 0.4 || stability < 0.7 {
    Medium
  } else {
    High
  }
}
