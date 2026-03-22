// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Umoja Commands — backend invoke wrappers for Umoja peer management.
///
/// These call into the Rust backend at src-tauri/src/umoja/commands.rs
/// for federation peer lifecycle operations: add, disconnect, gossip,
/// catalogue sync, and metrics retrieval.

let invoke = RuntimeBridge.invoke

/// Add a new peer to the Umoja federation by address.
let addPeer = (
  address: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("umoja_add_peer", {"address": address})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to add peer: ${address}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Disconnect a peer from the Umoja federation by node ID.
let disconnectPeer = (
  nodeId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("umoja_disconnect_peer", {"nodeId": nodeId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to disconnect peer: ${nodeId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Trigger a manual gossip round across the Umoja federation.
let triggerGossipRound = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("umoja_trigger_gossip", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to trigger gossip round")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Request a catalogue sync with a specific peer by node ID.
let syncCatalogue = (
  nodeId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("umoja_sync_catalogue", {"nodeId": nodeId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to sync catalogue with peer: ${nodeId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Retrieve metrics for a specific peer by node ID.
let getPeerMetrics = (
  nodeId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("umoja_peer_metrics", {"nodeId": nodeId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to get metrics for peer: ${nodeId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
