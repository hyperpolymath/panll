// SPDX-License-Identifier: PMPL-1.0-or-later

/// Storage module for persisting PanLL state between sessions.
///
/// Uses localStorage for now (Tauri storage API can be added later).
/// Handles serialization/deserialization of Model types to/from JSON.

open Model

// Storage key for localStorage
let storageKey = "panll_state_v1"

// Type for serializable state (subset of model that should persist)
type persistedState = {
  // User work (Priority 1)
  constraints: array<symbolicConstraint>,
  editorContent: string,
  neuralTokens: array<neuralToken>,
  worldContent: string,

  // Event chain data (Priority 1 - imported analysis results)
  eventChain: array<eventChainEvent>,
  eventChainSummary: option<eventChainSummary>,
  eventChainTimeline: option<eventChainTimeline>,

  // User preferences (Priority 2)
  viewMode: viewMode,
  paneLVisible: bool,
  paneNVisible: bool,
  paneWVisible: bool,
  humidity: humidityLevel,

  // Session state (Priority 3)
  vexometerIndex: float,
  orbitalStability: float,
}

// Convert OODA phase to string
let oodaPhaseToString = (phase: oodaPhase): string => {
  switch phase {
  | Observe => "Observe"
  | Orient => "Orient"
  | Decide => "Decide"
  | Act => "Act"
  }
}

// Convert string to OODA phase
let stringToOodaPhase = (str: string): oodaPhase => {
  switch str {
  | "Orient" => Orient
  | "Decide" => Decide
  | "Act" => Act
  | _ => Observe // Default
  }
}

// Convert viewMode to string
let viewModeToString = (mode: viewMode): string => {
  switch mode {
  | Standard => "Standard"
  | LightMode => "LightMode"
  | Ambient => "Ambient"
  | Zen => "Zen"
  | DarkStart => "DarkStart"
  }
}

// Convert string to viewMode
let stringToViewMode = (str: string): viewMode => {
  switch str {
  | "LightMode" => LightMode
  | "Ambient" => Ambient
  | "Zen" => Zen
  | "DarkStart" => DarkStart
  | _ => Standard // Default
  }
}

// Convert humidity level to string
let humidityToString = (humidity: humidityLevel): string => {
  switch humidity {
  | High => "High"
  | Medium => "Medium"
  | Low => "Low"
  }
}

// Convert string to humidity level
let stringToHumidity = (str: string): humidityLevel => {
  switch str {
  | "High" => High
  | "Low" => Low
  | _ => Medium // Default
  }
}

// Extract persisted state from model
let extractPersistedState = (model: model): persistedState => {
  constraints: model.paneL.constraints,
  editorContent: model.paneL.editorContent,
  neuralTokens: model.paneN.tokens,
  worldContent: model.paneW.content,
  eventChain: model.paneW.eventChain,
  eventChainSummary: model.paneW.eventChainSummary,
  eventChainTimeline: model.paneW.eventChainTimeline,
  viewMode: model.viewMode,
  paneLVisible: model.paneLVisible,
  paneNVisible: model.paneNVisible,
  paneWVisible: model.paneWVisible,
  humidity: model.humidity,
  vexometerIndex: model.vexometer.index,
  orbitalStability: model.orbital.stability,
}

// Build a plain JS object from persisted state for JSON serialization
let toJsonObject = (state: persistedState): JSON.t => {
  let constraints = state.constraints->Array.map(c => {
    let d = Dict.make()
    d->Dict.set("id", JSON.Encode.string(c.id))
    d->Dict.set("expression", JSON.Encode.string(c.expression))
    d->Dict.set("active", JSON.Encode.bool(c.active))
    d->Dict.set("pinned", JSON.Encode.bool(c.pinned))
    JSON.Encode.object(d)
  })
  let sourceToString = (s: tokenSource): string => switch s {
  | NeuralInference => "neural"
  | EchidnaProver => "echidna"
  | TypeLLKernel => "typell"
  | VeriSimInference => "verisim"
  | AntiCrashGate => "anticrash"
  | OperatorInput => "operator"
  | OrbitalSync => "orbital"
  }
  let categoryToString = (c: tokenCategory): string => switch c {
  | Observation => "observation"
  | Hypothesis => "hypothesis"
  | Deduction => "deduction"
  | Abduction => "abduction"
  | ProofStep => "proof"
  | Violation => "violation"
  | Correction => "correction"
  | Synthesis => "synthesis"
  }
  let phaseToString = (p: oodaPhase): string => switch p {
  | Observe => "observe"
  | Orient => "orient"
  | Decide => "decide"
  | Act => "act"
  }
  let tokens = state.neuralTokens->Array.map(t => {
    let d = Dict.make()
    d->Dict.set("id", JSON.Encode.string(t.id))
    d->Dict.set("content", JSON.Encode.string(t.content))
    d->Dict.set("timestamp", JSON.Encode.float(t.timestamp))
    d->Dict.set("confidence", JSON.Encode.float(t.confidence))
    d->Dict.set("validated", JSON.Encode.bool(t.validated))
    d->Dict.set("source", JSON.Encode.string(sourceToString(t.source)))
    d->Dict.set("category", JSON.Encode.string(categoryToString(t.category)))
    d->Dict.set("emittedDuring", JSON.Encode.string(phaseToString(t.emittedDuring)))
    d->Dict.set("causedBy", JSON.Encode.array(t.causedBy->Array.map(JSON.Encode.string)))
    switch t.proofHash {
    | Some(h) => d->Dict.set("proofHash", JSON.Encode.string(h))
    | None => ()
    }
    JSON.Encode.object(d)
  })
  let eventChainEvents = state.eventChain->Array.map(e => {
    let d = Dict.make()
    d->Dict.set("id", JSON.Encode.string(e.id))
    d->Dict.set("axis", JSON.Encode.string(e.axis))
    switch e.startMs {
    | Some(ms) => d->Dict.set("startMs", JSON.Encode.float(ms))
    | None => ()
    }
    d->Dict.set("durationMs", JSON.Encode.float(e.durationMs))
    d->Dict.set("intensity", JSON.Encode.string(e.intensity))
    d->Dict.set("status", JSON.Encode.string(e.status))
    switch e.peakMemory {
    | Some(mem) => d->Dict.set("peakMemory", JSON.Encode.float(mem))
    | None => ()
    }
    switch e.notes {
    | Some(n) => d->Dict.set("notes", JSON.Encode.string(n))
    | None => ()
    }
    JSON.Encode.object(d)
  })
  let root = Dict.make()
  root->Dict.set("constraints", JSON.Encode.array(constraints))
  root->Dict.set("editorContent", JSON.Encode.string(state.editorContent))
  root->Dict.set("neuralTokens", JSON.Encode.array(tokens))
  root->Dict.set("worldContent", JSON.Encode.string(state.worldContent))
  root->Dict.set("eventChain", JSON.Encode.array(eventChainEvents))
  switch state.eventChainSummary {
  | Some(summary) => {
      let d = Dict.make()
      d->Dict.set("program", JSON.Encode.string(summary.program))
      d->Dict.set("weakPoints", JSON.Encode.int(summary.weakPoints))
      d->Dict.set("criticalWeakPoints", JSON.Encode.int(summary.criticalWeakPoints))
      d->Dict.set("totalCrashes", JSON.Encode.int(summary.totalCrashes))
      d->Dict.set("robustnessScore", JSON.Encode.float(summary.robustnessScore))
      root->Dict.set("eventChainSummary", JSON.Encode.object(d))
    }
  | None => ()
  }
  switch state.eventChainTimeline {
  | Some(timeline) => {
      let d = Dict.make()
      d->Dict.set("durationMs", JSON.Encode.float(timeline.durationMs))
      d->Dict.set("events", JSON.Encode.int(timeline.events))
      root->Dict.set("eventChainTimeline", JSON.Encode.object(d))
    }
  | None => ()
  }
  root->Dict.set("viewMode", JSON.Encode.string(viewModeToString(state.viewMode)))
  root->Dict.set("paneLVisible", JSON.Encode.bool(state.paneLVisible))
  root->Dict.set("paneNVisible", JSON.Encode.bool(state.paneNVisible))
  root->Dict.set("paneWVisible", JSON.Encode.bool(state.paneWVisible))
  root->Dict.set("humidity", JSON.Encode.string(humidityToString(state.humidity)))
  root->Dict.set("vexometerIndex", JSON.Encode.float(state.vexometerIndex))
  root->Dict.set("orbitalStability", JSON.Encode.float(state.orbitalStability))
  JSON.Encode.object(root)
}

// Serialize persisted state to JSON string
let serialize = (state: persistedState): string => {
  JSON.stringify(toJsonObject(state))
}

// Raw localStorage helpers that receive values as arguments
let setItem: (string, string) => unit = %raw(`function(key, value) { localStorage.setItem(key, value) }`)

// Save model to localStorage
let save = (model: model): unit => {
  try {
    let state = extractPersistedState(model)
    let json = serialize(state)
    setItem(storageKey, json)
  } catch {
  | exn => Console.error2("Failed to save state:", exn)
  }
}

// ── Token source/category/phase string parsers (used by decoders) ────

/// Parse a token source string into a tokenSource variant.
let parseSource = (s: string): tokenSource => switch s {
| "echidna" => EchidnaProver
| "typell" => TypeLLKernel
| "verisim" => VeriSimInference
| "anticrash" => AntiCrashGate
| "operator" => OperatorInput
| "orbital" => OrbitalSync
| _ => NeuralInference
}

/// Parse a token category string into a tokenCategory variant.
let parseCategory = (s: string): tokenCategory => switch s {
| "hypothesis" => Hypothesis
| "deduction" => Deduction
| "abduction" => Abduction
| "proof" => ProofStep
| "violation" => Violation
| "correction" => Correction
| "synthesis" => Synthesis
| _ => Observation
}

/// Parse an OODA phase string into an oodaPhase variant.
let parsePhase = (s: string): oodaPhase => switch s {
| "orient" => Orient
| "decide" => Decide
| "act" => Act
| _ => Observe
}

// ── Tea_Json decoders for persisted state ────────────────────────────

/// Tea_Json decoder for a symbolic constraint.
let constraintDecoder: Tea_Json.decoder<symbolicConstraint> = {
  open Decoders
  open Tea_Json
  map4(
    (id, expression, active, pinned) => ({
      id,
      expression,
      active,
      pinned,
    }: symbolicConstraint),
    stringField("id"),
    stringField("expression"),
    fieldWithDefault("active", bool, true),
    boolField("pinned"),
  )
}

/// Tea_Json decoder for a neural token.
let neuralTokenDecoder: Tea_Json.decoder<neuralToken> = {
  open Decoders
  open Tea_Json
  map10(
    (id, content, timestamp, confidence, validated, sourceStr, categoryStr, phaseStr, causedBy, proofHash) => ({
      id,
      content,
      timestamp,
      confidence,
      validated,
      source: parseSource(sourceStr),
      category: parseCategory(categoryStr),
      emittedDuring: parsePhase(phaseStr),
      causedBy,
      proofHash,
    }: neuralToken),
    stringField("id"),
    stringField("content"),
    floatField("timestamp"),
    floatField("confidence"),
    boolField("validated"),
    fieldWithDefault("source", string, "neural"),
    fieldWithDefault("category", string, "observation"),
    fieldWithDefault("emittedDuring", string, "observe"),
    stringArrayField("causedBy"),
    optionalFieldDecoder("proofHash", string),
  )
}

/// Tea_Json decoder for a persisted event chain event (camelCase field names).
let eventChainEventDecoder: Tea_Json.decoder<eventChainEvent> = {
  open Decoders
  open Tea_Json
  map8(
    (id, axis, startMs, durationMs, intensity, status, peakMemory, notes) => ({
      id,
      axis,
      startMs,
      durationMs,
      intensity,
      status,
      peakMemory,
      notes,
    }: eventChainEvent),
    stringField("id"),
    stringField("axis"),
    optionalFieldDecoder("startMs", float),
    floatField("durationMs"),
    stringField("intensity"),
    stringField("status"),
    optionalFieldDecoder("peakMemory", float),
    optionalFieldDecoder("notes", string),
  )
}

/// Tea_Json decoder for a persisted event chain summary (camelCase field names).
let summaryDecoder: Tea_Json.decoder<eventChainSummary> = {
  open Decoders
  open Tea_Json
  map5(
    (program, weakPoints, criticalWeakPoints, totalCrashes, robustnessScore) => ({
      program,
      weakPoints,
      criticalWeakPoints,
      totalCrashes,
      robustnessScore,
    }: eventChainSummary),
    stringField("program"),
    intField("weakPoints"),
    intField("criticalWeakPoints"),
    intField("totalCrashes"),
    floatField("robustnessScore"),
  )
}

/// Tea_Json decoder for a persisted event chain timeline (camelCase field names).
let timelineDecoder: Tea_Json.decoder<eventChainTimeline> = {
  open Decoders
  open Tea_Json
  map2(
    (durationMs, events) => ({
      durationMs,
      events,
    }: eventChainTimeline),
    floatField("durationMs"),
    intField("events"),
  )
}

/// Tea_Json decoder for the full persisted state.
let persistedStateDecoder: Tea_Json.decoder<persistedState> = {
  open Decoders
  open Tea_Json
  map13(
    (constraints, editorContent, neuralTokens, worldContent,
     eventChain, eventChainSummary, eventChainTimeline,
     viewModeStr, paneLVisible, paneNVisible, paneWVisible,
     humidityStr, vexAndOrbital) => {
      let (vexometerIndex, orbitalStability) = vexAndOrbital
      ({
        constraints,
        editorContent,
        neuralTokens,
        worldContent,
        eventChain,
        eventChainSummary,
        eventChainTimeline,
        viewMode: stringToViewMode(viewModeStr),
        paneLVisible,
        paneNVisible,
        paneWVisible,
        humidity: stringToHumidity(humidityStr),
        vexometerIndex,
        orbitalStability,
      }: persistedState)
    },
    fieldWithDefault("constraints", lenientArray(constraintDecoder), []),
    stringField("editorContent"),
    fieldWithDefault("neuralTokens", lenientArray(neuralTokenDecoder), []),
    stringField("worldContent"),
    fieldWithDefault("eventChain", lenientArray(eventChainEventDecoder), []),
    optionalFieldDecoder("eventChainSummary", summaryDecoder),
    optionalFieldDecoder("eventChainTimeline", timelineDecoder),
    fieldWithDefault("viewMode", string, "DarkStart"),
    fieldWithDefault("paneLVisible", bool, true),
    fieldWithDefault("paneNVisible", bool, true),
    fieldWithDefault("paneWVisible", bool, true),
    fieldWithDefault("humidity", string, "Medium"),
    // Pack the last two floats into a tuple to fit map13
    map2(
      (vex, orb) => (vex, orb),
      floatField("vexometerIndex"),
      fieldWithDefault("orbitalStability", float, 1.0),
    ),
  )
}

/// Reconstruct a model from persisted state.
let modelFromPersisted = (state: persistedState): model => {
  let baseModel = init()
  {
    ...baseModel,
    paneL: {
      ...baseModel.paneL,
      constraints: state.constraints,
      editorContent: state.editorContent,
    },
    paneN: {
      ...baseModel.paneN,
      tokens: state.neuralTokens,
      nextTokenId: Array.length(state.neuralTokens),
      activeCausalChain: switch state.neuralTokens->Array.at(-1) {
      | Some(last) => [last.id]
      | None => []
      },
    },
    paneW: {
      ...baseModel.paneW,
      content: state.worldContent,
      eventChain: state.eventChain,
      eventChainSummary: state.eventChainSummary,
      eventChainTimeline: state.eventChainTimeline,
    },
    viewMode: state.viewMode,
    paneLVisible: state.paneLVisible,
    paneNVisible: state.paneNVisible,
    paneWVisible: state.paneWVisible,
    humidity: state.humidity,
    vexometer: {
      ...baseModel.vexometer,
      index: state.vexometerIndex,
    },
    orbital: {
      ...baseModel.orbital,
      stability: state.orbitalStability,
    },
  }
}

// Load persisted state from localStorage and merge with initial model
let load = (): option<model> => {
  try {
    let getItem: string => option<string> = %raw(`function(key) { var v = localStorage.getItem(key); return v === null ? undefined : v }`)
    let json: option<string> = getItem(storageKey)

    switch json {
    | None => None
    | Some(jsonStr) =>
      switch Decoders.decodeOption(persistedStateDecoder, jsonStr) {
      | Some(state) => Some(modelFromPersisted(state))
      | None => None
      }
    }
  } catch {
  | exn => {
      Console.error2("Failed to load state:", exn)
      None
    }
  }
}

// Raw localStorage remove helper
let removeItem: string => unit = %raw(`function(key) { localStorage.removeItem(key) }`)

// Clear persisted state
let clear = (): unit => {
  try {
    removeItem(storageKey)
  } catch {
  | exn => Console.error2("Failed to clear state:", exn)
  }
}
