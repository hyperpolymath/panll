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
  | Ambient => "Ambient"
  | Zen => "Zen"
  | DarkStart => "DarkStart"
  }
}

// Convert string to viewMode
let stringToViewMode = (str: string): viewMode => {
  switch str {
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
  let tokens = state.neuralTokens->Array.map(t => {
    let d = Dict.make()
    d->Dict.set("content", JSON.Encode.string(t.content))
    d->Dict.set("timestamp", JSON.Encode.float(t.timestamp))
    d->Dict.set("confidence", JSON.Encode.float(t.confidence))
    d->Dict.set("validated", JSON.Encode.bool(t.validated))
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
    Console.log("State saved to localStorage")
  } catch {
  | exn => Console.error2("Failed to save state:", exn)
  }
}

// Load persisted state from localStorage and merge with initial model
let load = (): option<model> => {
  try {
    // Load from localStorage
    let getItem: string => option<string> = %raw(`function(key) { var v = localStorage.getItem(key); return v === null ? undefined : v }`)
    let json: option<string> = getItem(storageKey)

    switch json {
    | None => None
    | Some(jsonStr) => {
        // Parse JSON
        let parsed = JSON.parseExn(jsonStr)

        // Extract fields safely
        let getField = (obj, field) => {
          switch obj->JSON.Decode.object {
          | Some(dict) => dict->Dict.get(field)
          | None => None
          }
        }

        let getString = (obj, field, default) => {
          switch getField(obj, field) {
          | Some(value) =>
            switch value->JSON.Decode.string {
            | Some(str) => str
            | None => default
            }
          | None => default
          }
        }

        let getBool = (obj, field, default) => {
          switch getField(obj, field) {
          | Some(value) =>
            switch value->JSON.Decode.bool {
            | Some(b) => b
            | None => default
            }
          | None => default
          }
        }

        let getFloat = (obj, field, default) => {
          switch getField(obj, field) {
          | Some(value) =>
            switch value->JSON.Decode.float {
            | Some(f) => f
            | None => default
            }
          | None => default
          }
        }

        let getArray = (obj, field) => {
          switch getField(obj, field) {
          | Some(value) =>
            switch value->JSON.Decode.array {
            | Some(arr) => Some(arr)
            | None => None
            }
          | None => None
          }
        }

        // Parse constraints
        let constraints = switch getArray(parsed, "constraints") {
        | Some(arr) =>
          arr->Array.map(item => {
            {
              id: getString(item, "id", ""),
              expression: getString(item, "expression", ""),
              active: getBool(item, "active", true),
              pinned: getBool(item, "pinned", false),
            }
          })
        | None => []
        }

        // Parse neural tokens
        let neuralTokens = switch getArray(parsed, "neuralTokens") {
        | Some(arr) =>
          arr->Array.map(item => {
            {
              content: getString(item, "content", ""),
              timestamp: getFloat(item, "timestamp", 0.0),
              confidence: getFloat(item, "confidence", 0.0),
              validated: getBool(item, "validated", false),
            }
          })
        | None => []
        }

        // Parse event chain events
        let eventChain = switch getArray(parsed, "eventChain") {
        | Some(arr) =>
          arr->Array.map(item => {
            {
              id: getString(item, "id", ""),
              axis: getString(item, "axis", ""),
              startMs: switch getField(item, "startMs") {
              | Some(v) => v->JSON.Decode.float
              | None => None
              },
              durationMs: getFloat(item, "durationMs", 0.0),
              intensity: getString(item, "intensity", ""),
              status: getString(item, "status", ""),
              peakMemory: switch getField(item, "peakMemory") {
              | Some(v) => v->JSON.Decode.float
              | None => None
              },
              notes: switch getField(item, "notes") {
              | Some(v) => v->JSON.Decode.string
              | None => None
              },
            }
          })
        | None => []
        }

        // Parse event chain summary
        let getInt = (obj, field, default) => {
          switch getField(obj, field) {
          | Some(value) =>
            switch value->JSON.Decode.float {
            | Some(f) => Float.toInt(f)
            | None => default
            }
          | None => default
          }
        }

        let eventChainSummary = switch getField(parsed, "eventChainSummary") {
        | Some(summaryObj) =>
          Some({
            program: getString(summaryObj, "program", ""),
            weakPoints: getInt(summaryObj, "weakPoints", 0),
            criticalWeakPoints: getInt(summaryObj, "criticalWeakPoints", 0),
            totalCrashes: getInt(summaryObj, "totalCrashes", 0),
            robustnessScore: getFloat(summaryObj, "robustnessScore", 0.0),
          })
        | None => None
        }

        // Parse event chain timeline
        let eventChainTimeline = switch getField(parsed, "eventChainTimeline") {
        | Some(timelineObj) =>
          Some({
            durationMs: getFloat(timelineObj, "durationMs", 0.0),
            events: getInt(timelineObj, "events", 0),
          })
        | None => None
        }

        // Create model with loaded state
        let baseModel = init()
        let loadedModel: model = {
          ...baseModel,
          paneL: {
            ...baseModel.paneL,
            constraints: constraints,
            editorContent: getString(parsed, "editorContent", ""),
          },
          paneN: {
            ...baseModel.paneN,
            tokens: neuralTokens,
          },
          paneW: {
            ...baseModel.paneW,
            content: getString(parsed, "worldContent", ""),
            eventChain: eventChain,
            eventChainSummary: eventChainSummary,
            eventChainTimeline: eventChainTimeline,
          },
          viewMode: stringToViewMode(getString(parsed, "viewMode", "DarkStart")),
          paneLVisible: getBool(parsed, "paneLVisible", true),
          paneNVisible: getBool(parsed, "paneNVisible", true),
          paneWVisible: getBool(parsed, "paneWVisible", true),
          humidity: stringToHumidity(getString(parsed, "humidity", "Medium")),
          vexometer: {
            ...baseModel.vexometer,
            index: getFloat(parsed, "vexometerIndex", 0.0),
          },
          orbital: {
            ...baseModel.orbital,
            stability: getFloat(parsed, "orbitalStability", 1.0),
          },
        }

        Console.log("State loaded from localStorage")
        Some(loadedModel)
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
    Console.log("State cleared from localStorage")
  } catch {
  | exn => Console.error2("Failed to clear state:", exn)
  }
}
