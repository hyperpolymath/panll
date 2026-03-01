// SPDX-License-Identifier: PMPL-1.0-or-later

/// Tauri Command Integration for TEA
///
/// Provides TEA commands for invoking Tauri backend functions.

// External binding to Tauri's invoke function
@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

module Dialog = {
  @module("@tauri-apps/plugin-dialog")
  external openDialog: JSON.t => promise<Nullable.t<JSON.t>> = "open"
}

module Fs = {
  @module("@tauri-apps/plugin-fs")
  external readTextFile: string => promise<string> = "readTextFile"
}

let decodeDialogPath = (value: JSON.t): option<string> => {
  switch JSON.Classify.classify(value) {
  | String(path) => Some(path)
  | Array(arr) =>
    switch Array.get(arr, 0) {
    | Some(item) =>
      switch JSON.Classify.classify(item) {
      | String(s) => Some(s)
      | _ => None
      }
    | None => None
    }
  | _ => None
  }
}

/// Validate a neural inference token against symbolic constraints
let validateInference = (
  token: string,
  constraints: array<string>,
  tagger: result<bool, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("validate_inference", {"token": token, "constraints": constraints})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Validation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Open a timeline specification file for Security Ambush runs
let openSecurityTimelineFile = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let options: JSON.t =
      %raw(`({
        multiple: false,
        filters: [
          { name: "PanLL Timeline (JSON/YAML)", extensions: ["json", "yaml", "yml"] }
        ]
      })`)
    Dialog.openDialog(options)
    ->Promise.then(result => {
      switch Nullable.toOption(result) {
      | None => {
          callbacks.enqueue(tagger(Error("No timeline selected")))
          Promise.resolve()
        }
      | Some(value) =>
        switch decodeDialogPath(value) {
        | Some(path) => {
            callbacks.enqueue(tagger(Ok(path)))
            Promise.resolve()
          }
        | None => {
            callbacks.enqueue(tagger(Error("Unsupported dialog response")))
            Promise.resolve()
          }
        }
      }
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Timeline selection failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get the current vexation index from the backend
let getVexationIndex = (tagger: float => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("get_vexation_index", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(result))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      // Default to 0.0 on error
      callbacks.enqueue(tagger(0.0))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Submit feedback to the Feedback-O-Tron
let submitFeedback = (
  paneLState: string,
  paneNState: string,
  paneWState: string,
  reportType: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "submit_feedback",
      {
        "pane_l_state": paneLState,
        "pane_n_state": paneNState,
        "pane_w_state": paneWState,
        "report_type": reportType,
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Feedback submission failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Open and read a PanLL event-chain JSON file
let openEventChainFile = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let options: JSON.t =
      %raw(`({
        multiple: false,
        filters: [{ name: "PanLL Event Chain", extensions: ["json"] }]
      })`)
    Dialog.openDialog(options)
    ->Promise.then(result => {
      switch Nullable.toOption(result) {
      | None => {
          callbacks.enqueue(tagger(Error("No file selected")))
          Promise.resolve()
        }
      | Some(value) =>
        switch decodeDialogPath(value) {
        | Some(path) =>
          Fs.readTextFile(path)
          ->Promise.then(contents => {
            callbacks.enqueue(tagger(Ok(contents)))
            Promise.resolve()
          })
          ->Promise.catch(_err => {
            callbacks.enqueue(tagger(Error("Failed to read file")))
            Promise.resolve()
          })
        | None => {
            callbacks.enqueue(tagger(Error("Unsupported dialog response")))
            Promise.resolve()
          }
        }
      }
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("File selection failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Open a panic-attacker assault report JSON file and return the chosen path.
let openPanicAttackerReportFile = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let options: JSON.t =
      %raw(`({
        multiple: false,
        filters: [{ name: "panic-attacker Assault Report", extensions: ["json"] }]
      })`)
    Dialog.openDialog(options)
    ->Promise.then(result => {
      switch Nullable.toOption(result) {
      | None => {
          callbacks.enqueue(tagger(Error("No panic-attacker report selected")))
          Promise.resolve()
        }
      | Some(value) =>
        switch decodeDialogPath(value) {
        | Some(path) => {
            callbacks.enqueue(tagger(Ok(path)))
            Promise.resolve()
          }
        | None => {
            callbacks.enqueue(tagger(Error("Unsupported dialog response")))
            Promise.resolve()
          }
        }
      }
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("panic-attacker report selection failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Convert a panic-attacker assault report into PanLL event-chain JSON.
/// Tells the backend to convert a selected panic-attacker report into PanLL JSON.
let importPanicAttackerReport = (
  reportPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("import_panic_attacker_report", {"report_path": reportPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("panic-attacker import failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

let optionToJson = (value: option<string>): JSON.t =>
  switch value {
  | Some(v) => JSON.Encode.string(v)
  | None => JSON.Encode.null
  }

/// Invokes the backend `run_panic_attack_ambush` command and funnels the JSON
/// output back into the security update path so Pane-W can display the event chain.
let runPanicAttackAmbush = (
  program: string,
  timeline: option<string>,
  axes: option<string>,
  intensity: string,
  durationSecs: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let payload = Dict.fromArray([
      ("program", JSON.Encode.string(program)),
      ("timeline", optionToJson(timeline)),
      ("axes", optionToJson(axes)),
      ("intensity", JSON.Encode.string(intensity)),
      ("duration_secs", JSON.Encode.int(durationSecs)),
    ])

    invoke("run_panic_attack_ambush", JSON.Encode.object(payload))
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("panic-attacker ambush failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Import the latest panic-attacker report from its reports directory.
/// Pulls the latest panic-attacker report (from the configured reports dir) and imports it.
let importLatestPanicAttackerReport = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("import_latest_panic_attacker_report", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("No latest panic-attacker report could be imported")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Probe panic-attacker capabilities and report whether full PanLL export is available.
let getPanicAttackerCapability = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("get_panic_attacker_capability", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("panic-attacker capability probe failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Record a vexation event in the backend (cancellation, correction, etc.)
let recordVexationEvent = (
  eventType: string,
  tagger: result<unit, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("record_vexation_event", {"event_type": eventType})
    ->Promise.then(_result => {
      callbacks.enqueue(tagger(Ok()))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to record vexation event")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ===========================================================================
// VeriSimDB Database Backend Commands
// ===========================================================================

/// Check VeriSimDB server health status.
/// Invokes the `verisimdb_health` Tauri command which hits GET /health.
let checkVeriSimDBHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_health", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("VeriSimDB health check failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Execute a VQL query against VeriSimDB.
/// Invokes the `verisimdb_query` Tauri command which POSTs to /vql/execute.
let queryVeriSimDB = (query: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_query", {"query": query})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("VQL query execution failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List hexad (octad) entities from VeriSimDB with pagination.
/// Invokes `verisimdb_list_hexads` which hits GET /hexads?limit=N&offset=M.
let listHexads = (
  limit: int,
  offset: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_list_hexads", {"limit": limit, "offset": offset})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list hexad entities")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get drift detection status for a specific entity.
/// Invokes `verisimdb_get_drift` which hits GET /drift/entity/{id}.
let getDrift = (entityId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_get_drift", {"entity_id": entityId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Drift status retrieval failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Trigger normalisation (self-repair) for a drifted entity.
/// Invokes `verisimdb_normalise` which POSTs to /normalizer/trigger/{id}.
let triggerNormalise = (
  entityId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_normalise", {"entity_id": entityId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Normalisation failed for " ++ entityId)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load full entity detail (all modality data) for a specific hexad.
/// Invokes `verisimdb_get_entity` which hits GET /hexads/{id}.
let getEntityDetail = (
  entityId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_get_entity", {"entity_id": entityId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Entity detail retrieval failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch product telemetry from VeriSimDB.
/// Invokes `verisimdb_telemetry` which hits GET /telemetry.
/// Returns aggregate-only metrics — no query content, entity data, or PII.
let getTelemetry = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_telemetry", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Telemetry fetch failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch orchestration status (consensus, federation, telemetry) from VeriSimDB.
/// Invokes `verisimdb_orch_status` which hits GET /status on the Elixir layer.
let getOrchStatus = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_orch_status", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Orchestration status fetch failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ===========================================================================
// ECHIDNA Theorem Prover Backend Commands
// ===========================================================================

/// Check ECHIDNA prover health status.
/// Invokes the `echidna_health` Tauri command which hits GET /health.
let checkEchidnaHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("echidna_health", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA health check failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List available provers from the ECHIDNA catalog.
/// Invokes `echidna_list_provers` which hits GET /provers.
let listEchidnaProvers = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("echidna_list_provers", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA prover listing failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Submit proof content to ECHIDNA with an optional prover selection.
/// Invokes `echidna_prove` which POSTs to /prove.
let echidnaProve = (
  content: string,
  prover: option<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let payload = Dict.fromArray([
      ("content", JSON.Encode.string(content)),
      ("prover", optionToJson(prover)),
    ])
    invoke("echidna_prove", JSON.Encode.object(payload))
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA proof submission failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Submit content for verification to ECHIDNA.
/// Invokes `echidna_verify` which POSTs to /verify.
let echidnaVerify = (
  content: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("echidna_verify", {"content": content})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA verification failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Search the ECHIDNA theorem library by query string.
/// Invokes `echidna_search_theorems` which hits GET /search?q=...
let echidnaSearchTheorems = (
  query: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("echidna_search_theorems", {"query": query})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA theorem search failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ===========================================================================
// ECHIDNA Interactive Session Commands
// ===========================================================================

/// Create a new proof session on ECHIDNA with a goal and prover.
/// Invokes `echidna_create_session` which POSTs to /proofs.
let createEchidnaSession = (
  goal: string,
  prover: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("echidna_create_session", {"goal": goal, "prover": prover})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA session creation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Retrieve the current state of a proof session.
/// Invokes `echidna_get_session` which hits GET /proofs/{id}.
let getEchidnaSession = (
  sessionId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("echidna_get_session", {"session_id": sessionId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA get session failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Apply a tactic to an active proof session.
/// Invokes `echidna_apply_tactic` which POSTs to /proofs/{id}/tactics.
let applyEchidnaTactic = (
  sessionId: string,
  name: string,
  args: array<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let payload = Dict.fromArray([
      ("session_id", JSON.Encode.string(sessionId)),
      ("name", JSON.Encode.string(name)),
      ("args", JSON.Encode.array(Array.map(args, JSON.Encode.string))),
    ])
    invoke("echidna_apply_tactic", JSON.Encode.object(payload))
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA apply tactic failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Request ML-powered tactic suggestions for the current proof state.
/// Invokes `echidna_suggest_tactics` which hits GET /proofs/{id}/tactics/suggest?limit=N.
let suggestEchidnaTactics = (
  sessionId: string,
  limit: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("echidna_suggest_tactics", {"session_id": sessionId, "limit": limit})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA tactic suggestions failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Batch multiple Tauri commands together
let batch = (commands: list<Tea_Cmd.t<'msg>>): Tea_Cmd.t<'msg> => {
  Tea_Cmd.batch(commands)
}

/// No-op command
let none: Tea_Cmd.t<'msg> = Tea_Cmd.none
