// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Aerie Commands — Backend wrappers for network diagnostics.
///
/// Backend is V-lang API gateway at :4000 (GraphQL + REST).

let invoke = RuntimeBridge.invoke

/// Fetch latest latency measurements.
let fetchLatency = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("aerie_get_latency", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Latency fetch failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run a speed test.
let runSpeedTest = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("aerie_speed_test", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Speed test failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
