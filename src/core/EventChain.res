// SPDX-License-Identifier: PMPL-1.0-or-later

/// Event-chain parsing helpers for PanLL.
///
/// Parses panic-attack PanLL export JSON into lightweight model state.

open Model

type payload = {
  summary: option<eventChainSummary>,
  events: array<eventChainEvent>,
}

let parse = (raw: string): result<payload, string> => {
  try {
    let parsed = JSON.parseExn(raw)

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
      | Some(value) => value->JSON.Decode.array
      | None => None
      }
    }

    let summary = switch getField(parsed, "summary") {
    | Some(value) =>
      switch value->JSON.Decode.object {
      | Some(_) =>
        Some({
          program: getString(value, "program", ""),
          weakPoints: Int.fromFloat(getFloat(value, "weak_points", 0.0)),
          criticalWeakPoints: Int.fromFloat(
            getFloat(value, "critical_weak_points", 0.0),
          ),
          totalCrashes: Int.fromFloat(getFloat(value, "total_crashes", 0.0)),
          robustnessScore: getFloat(value, "robustness_score", 0.0),
        })
      | None => None
      }
    | None => None
    }

    let events = switch getArray(parsed, "event_chain") {
    | Some(arr) =>
      arr->Array.map(item => {
        {
          id: getString(item, "id", ""),
          axis: getString(item, "axis", "unknown"),
          startMs: getOptionFloat(item, "start_ms"),
          durationMs: getFloat(item, "duration_ms", 0.0),
          intensity: getString(item, "intensity", "unknown"),
          status: getString(item, "status", "unknown"),
          peakMemory: getOptionFloat(item, "peak_memory"),
          notes: getOptionString(item, "notes"),
        }
      })
    | None => []
    }

    Ok({summary, events})
  } catch {
  | _ => Error("Invalid event-chain JSON")
  }
}
