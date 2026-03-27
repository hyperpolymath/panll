// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateTentacles.res — 7Tentacles (agent orchestration) sub-updater extracted from Update.res

open Model
open Msg

let updateTentacles = (model: model, msg: tentaclesMsg): (model, Tea_Cmd.t<msg>) => {
  let st = model.tentacles
  switch msg {
  | SetTentaclesCategory(cat) => ({...model, tentacles: {...st, activeCategory: cat}}, Tea_Cmd.none)
  | SelectAgent(id) => ({...model, tentacles: {...st, selectedAgent: id}}, Tea_Cmd.none)
  | SetGlobalStage(stage) => {
      let updatedAgents = st.agents->Array.map(a => {...a, stage})
      ({...model, tentacles: {...st, globalStage: stage, agents: updatedAgents}}, Tea_Cmd.none)
    }
  | ToggleOrchestraCompact => ({...model, tentacles: {...st, orchestraCompact: !st.orchestraCompact}}, Tea_Cmd.none)
  | BroadcastFromAgent(_source, payload) => (
      {...model, tentacles: {...st, pendingBroadcasts: Array.concat(st.pendingBroadcasts, [payload])}},
      Tea_Cmd.none,
    )
  | DeliverBroadcasts => ({...model, tentacles: {...st, pendingBroadcasts: []}}, Tea_Cmd.none)
  | StartAgentTask(id, task) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a =>
        TentaclesEngine.startTask(a, task)
      )
      ({...model, tentacles: {...st, agents}}, TypeLLService.checkCodeTypes(task, "tentacles", result => Tentacles(TypeCheckResult(result))))
    }
  | AgentPhaseAdvanced(id, _phase) => {
      // S1: Use OODA progression engine — advance through Observe→Orient→Decide→Act.
      // When the cycle completes (Act→Observe), the agent task finishes automatically.
      let updatedAgents = TentaclesEngine.updateAgent(st.agents, id, a => {
        let (advanced, _completed) = TentaclesEngine.advancePhase(a)
        advanced
      })
      ({...model, tentacles: {...st, agents: updatedAgents}}, Tea_Cmd.none)
    }
  | AgentConstraintAdded(id, newConstraint) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        constraints: Array.concat(a.constraints, [newConstraint]),
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentReasoningAdded(id, entry) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        reasoning: Array.concat(a.reasoning, [entry]),
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentResultAdded(id, result) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        results: Array.concat(a.results, [result]),
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentTaskCompleted(id) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        busy: false,
        currentTask: None,
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentError(id, err) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a =>
        TentaclesEngine.failTask(a, err)
      )
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | ClearAgentError(id) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {...a, lastError: None})
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | CheckFfiBridge => (model, TentaclesCmd.checkFfiBridge(result =>
      switch result {
      | Ok(_) => Tentacles(FfiBridgeResult(true, None))
      | Error(err) => Tentacles(FfiBridgeResult(false, Some(err)))
      }
    ))
  | FfiBridgeResult(connected, error) => (
      {...model, tentacles: {...st, ffiConnected: connected, ffiError: error, ffiLastCheck: 0.0}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "tentacles", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
