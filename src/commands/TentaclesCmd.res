// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Tentacles Commands — backend invoke wrappers for the ECHIDNA FFI bridge.
///
/// These call into the Rust backend which proxies to the ECHIDNA V-lang REST
/// adapters. Used for "without" mode — agents operating through the FFI/ABI
/// layer rather than embedded TEA state.

let invoke = RuntimeBridge.invoke

/// Check ECHIDNA FFI bridge health.
let checkFfiBridge = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("tentacles_ffi_health", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA FFI bridge unreachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Send a task to a specific agent via the FFI bridge.
let sendAgentTask = (
  agentId: string,
  task: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("tentacles_agent_task", {"agent": agentId, "task": task})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to dispatch agent task")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Poll for events from the ECHIDNA FFI event stream.
let pollEvents = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("tentacles_poll_events", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to poll FFI events")))
      Promise.resolve()
    })
    ->ignore
  })
}
