// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Network Topology Commands — backend invoke wrappers for reading
/// the in-game network topology from the running IDApTIK instance.

let invoke = RuntimeBridge.invoke

/// Read the current network topology from the running game.
let readTopology = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("read_network_topology", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read network topology")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read DNS resolution table from the game.
let readDnsTable = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("read_dns_table", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read DNS table")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export the topology as SVG.
let exportSvg = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("export_topology_svg", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export SVG")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read packet flow events from the game.
let readPacketFlow = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("read_packet_flow", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read packet flow")))
      Promise.resolve()
    })
    ->ignore
  })
}
