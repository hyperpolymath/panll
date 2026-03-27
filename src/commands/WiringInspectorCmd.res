// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Wiring Inspector Command Wrappers — Backend bindings for PCC invocation.
///
/// Two commands:
///   - `runVerification`: invoke PCC against all panel contracts.
///   - `runSingleVerification`: invoke PCC against a single panel contract.
///
/// Both return JSON strings that the frontend parses with
/// WiringInspectorEngine.parseVerificationJson.

let invoke = RuntimeBridge.invoke

/// Run PCC verification against all panel contracts.
/// Returns JSON string with all panel verification results.
let runVerification = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("wiring_inspector_verify", Dict.make())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to run PCC verification")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run PCC verification against a single panel contract.
/// Returns JSON string with one panel verification result.
let runSingleVerification = (panelId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("wiring_inspector_verify_panel", {"panelId": panelId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to verify panel: ${panelId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
