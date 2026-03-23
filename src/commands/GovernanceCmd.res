// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Governance Commands — backend invoke wrappers for nesy-MCP governance
/// queries. These call into the Rust backend at src-gossamer/src/governance/commands.rs
/// which routes governance decisions through the BoJ nesy-mcp cartridge for
/// real-time neural validation.
///
/// Used by the GovernanceEngine's `evaluateWithCmd` path when the engine cannot
/// make a confident pure decision and needs async neural consultation.

let invoke = RuntimeBridge.invoke

/// Query nesy-mcp for a confidence assessment on a borderline governance
/// decision. Returns JSON with confidence score, recommended action, and
/// reasoning from the neural subsystem.
let queryNesyConfidence = (
  query: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("governance_nesy_query", {"query": query})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Nesy confidence query failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Ask nesy-mcp to validate a governance adjustment before it is applied.
/// Used primarily for HaltInference decisions — the neural subsystem can
/// approve or reject the halt with reasoning.
let validateAdjustment = (
  adj: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("governance_nesy_validate", {"adjustment": adj})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Nesy adjustment validation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Probe nesy-mcp for overall stability metrics from the neural subsystem.
/// Returns JSON with neural coherence, drift magnitude, and recommendation.
/// Emitted automatically when any governance query is generated.
let probeStability = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("governance_nesy_probe", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Nesy stability probe failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
