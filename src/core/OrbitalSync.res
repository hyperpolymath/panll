// SPDX-License-Identifier: MPL-2.0

/// OrbitalSync Module - Pane Synchronisation
///
/// Implements the "Semantic Synchronisation" between Pane-L, Pane-N,
/// and Pane-W. Ensures the Binary Star co-orbit maintains gravitational
/// coherence across all three panes.

// Use Model types to avoid circular dependencies
type syncEvent = Model.syncEvent
type syncState = Model.syncState

/// FNV-1a change-detection hash — consistent with ProvenanceEngine pattern.
/// Replaces the broken length+first+last approach that collided on any two
/// strings differing only in middle characters (e.g. "abc" ≡ "axc").
let simpleHash = (content: string): string => {
  if String.length(content) === 0 {
    "empty"
  } else {
    %raw(`
      (function(s) {
        var h = 0x811c9dc5;
        for (var i = 0; i < s.length; i++) {
          h = ((h ^ s.charCodeAt(i)) * 0x01000193) >>> 0;
        }
        return h.toString(16);
      })(content)
    `)
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

/// S3: Token-overlap divergence between symbolic and neural content.
/// Splits both panes' content into word tokens and computes Jaccard
/// distance: 1 - |intersection| / |union|. Falls back to length
/// ratio when token sets are empty.
let calculateDivergence = (paneL: Model.paneLState, paneN: Model.paneNState): float => {
  let symbolicContent = paneL.editorContent
  let neuralContent = paneN.monologue

  let symbolicLen = String.length(symbolicContent)
  let neuralLen = String.length(neuralContent)

  if symbolicLen === 0 && neuralLen === 0 {
    0.0
  } else if symbolicLen === 0 || neuralLen === 0 {
    1.0
  } else {
    // Tokenise: split on whitespace and punctuation boundaries.
    let tokenise = (s: string): array<string> => {
      String.split(s, " ")
      ->Array.flatMap(w => String.split(w, "\n"))
      ->Array.map(String.trim)
      ->Array.filter(t => String.length(t) > 0)
    }

    let symTokens = tokenise(symbolicContent)
    let neuTokens = tokenise(neuralContent)

    let symLen = Array.length(symTokens)
    let neuLen = Array.length(neuTokens)

    if symLen === 0 && neuLen === 0 {
      0.0
    } else {
      // Count intersection: tokens present in both sets.
      let intersection = Array.filter(symTokens, t => Array.includes(neuTokens, t))->Array.length

      // Jaccard distance = 1 - |intersection| / |union|
      // |union| = |A| + |B| - |intersection|
      let union = symLen + neuLen - intersection
      if union === 0 {
        0.0
      } else {
        let jaccard = Int.toFloat(intersection) /. Int.toFloat(union)
        Math.min(1.0, 1.0 -. jaccard)
      }
    }
  }
}

/// Calculate orbital stability based on divergence and sync latency
let calculateStability = (divergence: float, latency: float): float => {
  // Stability decreases with divergence and latency
  let divergencePenalty = divergence *. 0.6
  let latencyPenalty = Math.min(0.4, latency /. 1000.0) // Normalize latency to 0-0.4

  Math.max(0.0, 1.0 -. divergencePenalty -. latencyPenalty)
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
  let newEvents =
    [symbolicChange, neuralChange, worldChange]
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

  // Symbolic mass: derived from constraint editor content density PLUS active
  // constraint count.  Each active constraint adds mass equivalent to ~20 tokens,
  // reflecting the formal weight constraints carry in the symbolic–neural loop.
  // Normalise effective token count to 0.0–1.0 (cap at 500 tokens for max mass).
  let symTokenCount =
    String.split(model.paneL.editorContent, " ")
    ->Array.filter(t => String.length(String.trim(t)) > 0)
    ->Array.length
  let activeConstraintCount =
    model.paneL.constraints
    ->Array.filter(c => c.active)
    ->Array.length
  let effectiveTokens = symTokenCount + activeConstraintCount * 20
  let symbolicMass = Math.min(1.0, Int.toFloat(effectiveTokens) /. 500.0)

  // Neural stream: derived from monologue density.
  // Normalise to 0.0–1.0 (cap at 500 tokens).
  let neuTokenCount =
    String.split(model.paneN.monologue, " ")
    ->Array.filter(t => String.length(String.trim(t)) > 0)
    ->Array.length
  let neuralStream = Math.min(1.0, Int.toFloat(neuTokenCount) /. 500.0)

  // Barycentre position: centre of mass between symbolic and neural.
  // -1.0 = all symbolic, 0.0 = balanced, +1.0 = all neural.
  let totalMass = symbolicMass +. neuralStream
  let barycentrePosition = if totalMass < 0.001 {
    0.0
  } else {
    (neuralStream -. symbolicMass) /. totalMass
  }

  // Sync health: composite of latency freshness and event throughput.
  let latencyHealth = Math.max(0.0, 1.0 -. state.syncLatency /. 2000.0)
  let eventFreshness = if Array.length(newEvents) > 0 {
    0.9
  } else {
    1.0
  }
  let syncHealth = latencyHealth *. eventFreshness

  let orbital: Model.orbitalState = {
    stability,
    divergenceLevel: divergence,
    driftAuraColour: auraColour,
    symbolicMass,
    neuralStream,
    barycentrePosition,
    syncHealth,
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
