// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Coordination command wrappers — invoke bridge for the
/// coordination view panel.
///
/// All commands invoke BoJ cartridge endpoints for multi-agent topology
/// and strategy management. Uses `Tea_Cmd.call` for async operations.

let invoke = RuntimeBridge.invoke

/// Fetch the current agent coordination topology.
/// Returns JSON with nodes, edges, and active strategy.
let topology = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_coord_topology", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch coordination topology")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Set the coordination strategy for the agent system.
/// Returns JSON confirming the strategy change.
let setStrategy = (strategyId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_coord_set_strategy", {"strategy_id": strategyId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to set coordination strategy")))
      Promise.resolve()
    })
    ->ignore
  })
}
