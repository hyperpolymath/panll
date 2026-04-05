// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playgrounds Commands — Backend wrappers for code execution.
///
/// Connects to the NQC proxy at :4000 for VCL/KQL/GQL queries.

let invoke = RuntimeBridge.invoke

/// Execute a query through the NQC proxy.
let executeQuery = (
  language: string,
  code: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("playgrounds_execute", {"language": language, "code": code})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Execution failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
