// SPDX-License-Identifier: PMPL-1.0-or-later

/// Storage module for persisting PanLL state between sessions.
///
/// Uses localStorage for now (Tauri storage API can be added later).
/// Handles serialization/deserialization of Model types to/from JSON.

open Model

// Storage key for localStorage
let storageKey = "panll_state_v1"

module LocalStorage = {
  @scope("localStorage")
  @val
  external setItem: (string, string) => unit = "setItem"

  @scope("localStorage")
  @val
  external getItem: string => Js.Nullable.t<string> = "getItem"

  @scope("localStorage")
  @val
  external removeItem: string => unit = "removeItem"
}

// Type for serializable state (subset of model that should persist)
type persistedState = {
  version: int,
  // User work (Priority 1)
  constraints: array<symbolicConstraint>,
  editorContent: string,
  neuralTokens: array<neuralToken>,
  worldContent: string,
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
  version: 2,
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

// Serialize persisted state to JSON string
let serialize = (state: persistedState): string => {
  // Use raw JavaScript to stringify
  %raw(`
    JSON.stringify({
      version: state.version,
      constraints: state.constraints.map(c => ({
        id: c.id,
        expression: c.expression,
        active: c.active,
        pinned: c.pinned
      })),
      editorContent: state.editorContent,
      neuralTokens: state.neuralTokens.map(t => ({
        content: t.content,
        timestamp: t.timestamp,
        confidence: t.confidence,
        validated: t.validated
      })),
      worldContent: state.worldContent,
      eventChain: state.eventChain.map(e => ({
        id: e.id,
        axis: e.axis,
        startMs: e.startMs,
        durationMs: e.durationMs,
        intensity: e.intensity,
        status: e.status,
        peakMemory: e.peakMemory,
        notes: e.notes
      })),
      eventChainSummary: state.eventChainSummary == null ? null : state.eventChainSummary,
      eventChainTimeline: state.eventChainTimeline == null ? null : state.eventChainTimeline,
      viewMode: viewModeToString(state.viewMode),
      paneLVisible: state.paneLVisible,
      paneNVisible: state.paneNVisible,
      paneWVisible: state.paneWVisible,
      humidity: humidityToString(state.humidity),
      vexometerIndex: state.vexometerIndex,
      orbitalStability: state.orbitalStability
    })
  `)
}

// Save model to localStorage
let save = (model: model): unit => {
  try {
    let state = extractPersistedState(model)

    // Save to localStorage
    LocalStorage.setItem(storageKey, serialize(state))

    Console.log("State saved to localStorage")
  } catch {
  | exn => Console.error2("Failed to save state:", exn)
  }
}

// Load persisted state from localStorage and merge with initial model
let load = (): option<model> => {
  try {
    // Load from localStorage
    let json = LocalStorage.getItem(storageKey)->Js.Nullable.toOption

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

        let getOptionString = (obj, field) => {
          switch getField(obj, field) {
          | Some(value) => value->JSON.Decode.string
          | None => None
          }
        }

        let getOptionFloat = (obj, field) => {
          switch getField(obj, field) {
          | Some(value) => value->JSON.Decode.float
          | None => None
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

        let _version = getFloat(parsed, "version", 1.0)

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

        let eventChainSummary = switch getField(parsed, "eventChainSummary") {
        | Some(value) =>
          switch value->JSON.Decode.object {
          | Some(_) =>
            Some({
              program: getString(value, "program", ""),
              weakPoints: Int.fromFloat(getFloat(value, "weakPoints", 0.0)),
              criticalWeakPoints: Int.fromFloat(getFloat(value, "criticalWeakPoints", 0.0)),
              totalCrashes: Int.fromFloat(getFloat(value, "totalCrashes", 0.0)),
              robustnessScore: getFloat(value, "robustnessScore", 0.0),
            })
          | None => None
          }
        | None => None
        }

        let eventChain = switch getArray(parsed, "eventChain") {
        | Some(arr) =>
          arr->Array.map(item => {
            {
              id: getString(item, "id", ""),
              axis: getString(item, "axis", "unknown"),
              startMs: getOptionFloat(item, "startMs"),
              durationMs: getFloat(item, "durationMs", 0.0),
              intensity: getString(item, "intensity", "unknown"),
              status: getString(item, "status", "unknown"),
              peakMemory: getOptionFloat(item, "peakMemory"),
              notes: getOptionString(item, "notes"),
            }
          })
        | None => []
        }

        let eventChainTimeline = switch getField(parsed, "eventChainTimeline") {
        | Some(value) =>
          switch value->JSON.Decode.object {
          | Some(_) =>
            Some({
              durationMs: getFloat(value, "durationMs", 0.0),
              events: Int.fromFloat(getFloat(value, "events", 0.0)),
            })
          | None => None
          }
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

// Clear persisted state
let clear = (): unit => {
  try {
    LocalStorage.removeItem(storageKey)
    Console.log("State cleared from localStorage")
  } catch {
  | exn => Console.error2("Failed to clear state:", exn)
  }
}
