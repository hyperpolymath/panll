// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Reposystem Commands — Backend wrappers for RSR compliance scanning.
///
/// The reposystem backend scans local repo directories for required files.

let invoke = RuntimeBridge.invoke

/// Scan all repos for RSR compliance.
let scanAll = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("reposystem_scan_all", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("RSR scan failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
