// SPDX-License-Identifier: PMPL-1.0-or-later

/// Gossamer Command Integration for TEA
///
/// Gossamer command integration for TEA. Provides TEA commands for invoking
/// backend functions through the RuntimeBridge, which dispatches to Gossamer
/// or rejects with a descriptive error in browser-only mode.
///
/// All panel command modules should use RuntimeBridge.invoke directly.
/// This module provides higher-level TEA command wrappers for the core
/// PanLL operations (dialogs, filesystem, service health, VeriSimDB,
/// ECHIDNA, panic-attacker, vexation tracking).

let invoke = RuntimeBridge.invoke
let isGossamerRuntime = RuntimeBridge.isGossamerRuntime

// ===========================================================================
// Direct HTTP helpers for browser-only mode
// ===========================================================================

/// ECHIDNA base URL for direct browser fetch.
let echidnaUrl = "http://localhost:9000/api/v1"

/// GET helper for ECHIDNA direct fetch (bypasses desktop runtime).
let echidnaGet: string => promise<string> = %raw(`
  function(path) {
    return fetch("http://localhost:9000/api/v1" + path)
      .then(function(r) {
        if (!r.ok) throw new Error("ECHIDNA returned " + r.status);
        return r.text();
      });
  }
`)

/// POST helper for ECHIDNA direct fetch (bypasses desktop runtime).
let echidnaPost: (string, string) => promise<string> = %raw(`
  function(path, body) {
    return fetch("http://localhost:9000/api/v1" + path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body
    }).then(function(r) {
      if (!r.ok) throw new Error("ECHIDNA returned " + r.status);
      return r.text();
    });
  }
`)

module Dialog = {
  /// Open a file picker dialog through the RuntimeBridge.
  let openDialog = (opts: JSON.t): promise<Nullable.t<JSON.t>> => {
    RuntimeBridge.Dialog.openDialog(opts)
  }
}

module Fs = {
  /// Read a text file through the RuntimeBridge.
  let readTextFile = (path: string): promise<string> => {
    RuntimeBridge.Fs.readTextFile(path)
  }
}

let decodeDialogPath = RuntimeBridge.decodeDialogPath

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
    let options: JSON.t = %raw(`({
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
    let options: JSON.t = %raw(`({
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
          ->Promise.then(
            contents => {
              callbacks.enqueue(tagger(Ok(contents)))
              Promise.resolve()
            },
          )
          ->Promise.catch(
            _err => {
              callbacks.enqueue(tagger(Error("Failed to read file")))
              Promise.resolve()
            },
          )
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
    let options: JSON.t = %raw(`({
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

/// Invokes the backend `run_panic_attack_ambush` command.
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

/// Probe panic-attacker capabilities.
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

/// Record a vexation event in the backend.
let recordVexationEvent = (eventType: string, tagger: result<unit, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
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

/// List octad entities from VeriSimDB with pagination.
let listOctads = (limit: int, offset: int, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("verisimdb_list_octads", {"limit": limit, "offset": offset})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list octad entities")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get drift detection status for a specific entity.
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

/// Trigger normalisation for a drifted entity.
let triggerNormalise = (entityId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
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

/// Load full entity detail for a specific octad.
let getEntityDetail = (entityId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
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

/// Fetch orchestration status from VeriSimDB.
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
/// In browser mode, calls ECHIDNA directly via fetch.
let checkEchidnaHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      invoke("echidna_health", ())
    } else {
      echidnaGet("/health")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(
        tagger(Error("ECHIDNA health check failed — server not running on localhost:9000")),
      )
      Promise.resolve()
    })
    ->ignore
  })
}

/// List available provers from the ECHIDNA catalog.
let listEchidnaProvers = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      invoke("echidna_list_provers", ())
    } else {
      echidnaGet("/provers")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(
        tagger(Error("ECHIDNA prover listing failed — server not running on localhost:9000")),
      )
      Promise.resolve()
    })
    ->ignore
  })
}

/// Submit proof content to ECHIDNA.
let echidnaProve = (
  content: string,
  prover: option<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      let payload = Dict.fromArray([
        ("content", JSON.Encode.string(content)),
        ("prover", optionToJson(prover)),
      ])
      invoke("echidna_prove", JSON.Encode.object(payload))
    } else {
      let proverJson = switch prover {
      | Some(pv) => JSON.stringifyAny(pv)->Option.getOr("null")
      | None => "null"
      }
      echidnaPost(
        "/prove",
        `{"content":${JSON.stringifyAny(content)->Option.getOr("\"\"")}, "prover":${proverJson}}`,
      )
    }
    p
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
let echidnaVerify = (content: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      invoke("echidna_verify", {"content": content})
    } else {
      echidnaPost("/verify", `{"content":${JSON.stringifyAny(content)->Option.getOr("\"\"")}}`)
    }
    p
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

/// Search the ECHIDNA theorem library.
let echidnaSearchTheorems = (query: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    let encoded = query->String.replaceAll(" ", "%20")
    let p = if isGossamerRuntime() {
      invoke("echidna_search_theorems", {"query": query})
    } else {
      echidnaGet(`/search?q=${encoded}`)
    }
    p
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

/// Create a new proof session.
let createEchidnaSession = (
  goal: string,
  prover: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      invoke("echidna_create_session", {"goal": goal, "prover": prover})
    } else {
      echidnaPost(
        "/proofs",
        `{"goal":${JSON.stringifyAny(goal)->Option.getOr("\"\"")}, "prover":${JSON.stringifyAny(
            prover,
          )->Option.getOr("\"\"")}}`,
      )
    }
    p
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
let getEchidnaSession = (sessionId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      invoke("echidna_get_session", {"session_id": sessionId})
    } else {
      echidnaGet(`/proofs/${sessionId}`)
    }
    p
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
let applyEchidnaTactic = (
  sessionId: string,
  name: string,
  args: array<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      let payload = Dict.fromArray([
        ("session_id", JSON.Encode.string(sessionId)),
        ("name", JSON.Encode.string(name)),
        ("args", JSON.Encode.array(Array.map(args, JSON.Encode.string))),
      ])
      invoke("echidna_apply_tactic", JSON.Encode.object(payload))
    } else {
      let argsJson = JSON.stringifyAny(args)->Option.getOr("[]")
      echidnaPost(
        `/proofs/${sessionId}/tactics`,
        `{"name":${JSON.stringifyAny(name)->Option.getOr("\"\"")}, "args":${argsJson}}`,
      )
    }
    p
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

/// Request ML-powered tactic suggestions.
let suggestEchidnaTactics = (
  sessionId: string,
  limit: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if isGossamerRuntime() {
      invoke("echidna_suggest_tactics", {"session_id": sessionId, "limit": limit})
    } else {
      echidnaGet(`/proofs/${sessionId}/tactics/suggest?limit=${Int.toString(limit)}`)
    }
    p
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

/// Batch multiple commands together
let batch = (commands: list<Tea_Cmd.t<'msg>>): Tea_Cmd.t<'msg> => {
  Tea_Cmd.batch(commands)
}

/// No-op command
let none: Tea_Cmd.t<'msg> = Tea_Cmd.none
