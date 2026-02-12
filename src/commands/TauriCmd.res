// SPDX-License-Identifier: PMPL-1.0-or-later

/// Tauri Command Integration for TEA
///
/// Provides TEA commands for invoking Tauri backend functions.

// External binding to Tauri's invoke function
@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

module Dialog = {
  @module("@tauri-apps/api/dialog")
  external openDialog: Js.Json.t => promise<Js.Nullable.t<Js.Json.t>> = "open"
}

module Fs = {
  @module("@tauri-apps/api/fs")
  external readTextFile: string => promise<string> = "readTextFile"
}

let decodeDialogPath = (value: Js.Json.t): option<string> => {
  switch Js.Json.decodeString(value) {
  | Some(path) => Some(path)
  | None =>
    switch Js.Json.decodeArray(value) {
    | Some(arr) =>
      switch Array.get(arr, 0) {
      | Some(item) => Js.Json.decodeString(item)
      | None => None
      }
    | None => None
    }
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
    let options: Js.Json.t =
      %raw(`({
        multiple: false,
        filters: [
          { name: "PanLL Timeline (JSON/YAML)", extensions: ["json", "yaml", "yml"] }
        ]
      })`)
    Dialog.openDialog(options)
    ->Promise.then(result => {
      switch Js.Nullable.toOption(result) {
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
    let options: Js.Json.t =
      %raw(`({
        multiple: false,
        filters: [{ name: "PanLL Event Chain", extensions: ["json"] }]
      })`)
    Dialog.openDialog(options)
    ->Promise.then(result => {
      switch Js.Nullable.toOption(result) {
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
    let options: Js.Json.t =
      %raw(`({
        multiple: false,
        filters: [{ name: "panic-attacker Assault Report", extensions: ["json"] }]
      })`)
    Dialog.openDialog(options)
    ->Promise.then(result => {
      switch Js.Nullable.toOption(result) {
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

let optionToJson = (value: option<string>): Js.Json.t =>
  switch value {
  | Some(v) => Js.Json.string(v)
  | None => Js.Json.null
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
    let payload = Js.Dict.fromArray([
      ("program", Js.Json.string(program)),
      ("timeline", optionToJson(timeline)),
      ("axes", optionToJson(axes)),
      ("intensity", Js.Json.string(intensity)),
      ("duration_secs", Js.Json.number(float_of_int(durationSecs))),
    ])

    invoke("run_panic_attack_ambush", Js.Json.object_(payload))
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

/// Batch multiple Tauri commands together
let batch = (commands: list<Tea_Cmd.t<'msg>>): Tea_Cmd.t<'msg> => {
  Tea_Cmd.batch(commands)
}

/// No-op command
let none: Tea_Cmd.t<'msg> = Tea_Cmd.none
