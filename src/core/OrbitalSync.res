// SPDX-License-Identifier: PMPL-1.0-or-later

/// OrbitalSync Module - Pane Synchronisation
///
/// Implements the "Semantic Synchronisation" between Pane-L, Pane-N,
/// and Pane-W. Ensures the Binary Star co-orbit maintains gravitational
/// coherence across all three panes.

// Use Model types to avoid circular dependencies
type syncEvent = Model.syncEvent
type syncState = Model.syncState

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
let detectSymbolicChanges = (paneL: Model.paneLState, state: syncState): option<syncEvent> => {
  let currentHash = simpleHash(paneL.editorContent)
  if currentHash !== state.lastSymbolicHash {
    Some(Model.SymbolicUpdate(paneL.editorContent))
  } else {
    None
  }
}

/// Detect changes in Pane-N
let detectNeuralChanges = (paneN: Model.paneNState, state: syncState): option<syncEvent> => {
  let currentHash = simpleHash(paneN.monologue)
  if currentHash !== state.lastNeuralHash {
    Some(Model.NeuralUpdate(paneN.monologue))
  } else {
    None
  }
}

/// Detect changes in Pane-W
let detectWorldChanges = (paneW: Model.paneWState, state: syncState): option<syncEvent> => {
  let currentHash = simpleHash(paneW.content)
  if currentHash !== state.lastWorldHash {
    Some(Model.WorldUpdate(paneW.content))
  } else {
    None
  }
}

/// Calculate divergence between symbolic and neural content
let calculateDivergence = (paneL: Model.paneLState, paneN: Model.paneNState): float => {
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
    Js.Math.min_float(1.0, diff /. maxLen)
  }
}

/// Calculate orbital stability based on divergence and sync latency
let calculateStability = (divergence: float, latency: float): float => {
  // Stability decreases with divergence and latency
  let divergencePenalty = divergence *. 0.6
  let latencyPenalty = Js.Math.min_float(0.4, latency /. 1000.0) // Normalize latency to 0-0.4

  Js.Math.max_float(0.0, 1.0 -. divergencePenalty -. latencyPenalty)
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
let sync = (model: Model.model, state: syncState): (syncState, Model.orbitalState) => {
  // Detect all changes
  let symbolicChange = detectSymbolicChanges(model.paneL, state)
  let neuralChange = detectNeuralChanges(model.paneN, state)
  let worldChange = detectWorldChanges(model.paneW, state)

  // Collect pending events
  let newEvents = [symbolicChange, neuralChange, worldChange]
    ->Array.filter(Option.isSome)
    ->Array.map(opt => Option.getExn(opt))

  // Update hashes
  let newState: Model.syncState = {
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

  let orbital: Model.orbitalState = {
    stability,
    divergenceLevel: divergence,
    driftAuraColour: auraColour,
  }

  (newState, orbital)
}

/// Create a cross-pane link (Circuit Lines feature)
let createCrossLink = (sourcePane: string, targetPane: string, content: string): syncEvent => {
  Model.CrossPaneLink(sourcePane ++ ":" ++ content, targetPane)
}

/// Get Information Humidity level based on model state
let getHumidityLevel = (model: Model.model): Model.humidityLevel => {
  let vexation = model.vexometer.index
  let stability = model.orbital.stability

  // High stress = Low humidity (shed visual noise)
  // Low stress = High humidity (reveal more detail)
  if vexation > 0.7 || stability < 0.4 {
    Model.Low
  } else if vexation > 0.4 || stability < 0.7 {
    Model.Medium
  } else {
    Model.High
  }
}
