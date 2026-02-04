// SPDX-License-Identifier: PMPL-1.0-or-later

/// Tauri Command Integration for Custom TEA
///
/// Provides TEA commands for invoking Tauri backend functions using our custom TEA's call API.

// External binding to Tauri's invoke function
@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

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
