// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Multiplayer Monitor Commands — backend invoke wrappers for
/// connecting to the IDApTIK Phoenix sync server and reading
/// multiplayer state.

let invoke = RuntimeBridge.invoke

/// Connect to the Phoenix WebSocket sync server.
let connectToServer = (url: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("multiplayer_connect", {"url": url})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to connect to sync server")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Disconnect from the sync server.
let disconnectFromServer = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("multiplayer_disconnect", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to disconnect")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read the current multiplayer state (players, channels, locks).
let readMultiplayerState = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("multiplayer_read_state", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read multiplayer state")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read state diffs between local and remote.
let readStateDiffs = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("multiplayer_read_diffs", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read state diffs")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read ETS cache entries for inspection.
let readEtsCache = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("multiplayer_read_ets", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read ETS cache")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Trigger a reconnection test.
let reconnectionTest = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("multiplayer_reconnection_test", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Reconnection test failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
