// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

// ===========================================================================
// Game Dev Panel Sub-Updaters — Bridge Panels
// ===========================================================================

/// Handles all Typing Bridge messages — TypeLL type constraints for game state.
let updateTypingBridge = (model: model, msg: typingBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.typingBridge
  switch msg {
  | SetTbTab(tab) => ({...model, typingBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | TbStarted => ({...model, typingBridge: {...state, running: true, error: None}}, Tea_Cmd.none)
  | TbCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, typingBridge: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, typingBridge: {...state, running: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissTbError => ({...model, typingBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Neurosymbolic Bridge messages — guard AI behaviour reasoning via ECHIDNA.
let updateNeurosymBridge = (model: model, msg: neurosymBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.neurosymBridge
  switch msg {
  | SetNbTab(tab) => ({...model, neurosymBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | NbStarted => ({...model, neurosymBridge: {...state, simulating: true, error: None}}, Tea_Cmd.none)
  | NbCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, neurosymBridge: {...state, simulating: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, neurosymBridge: {...state, simulating: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissNbError => ({...model, neurosymBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Agentic Bridge messages — automated playtesting agents with OODA loop.
let updateAgenticBridge = (model: model, msg: agenticBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.agenticBridge
  switch msg {
  | SetAbTab(tab) => ({...model, agenticBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | AbStarted => ({...model, agenticBridge: {...state, running: true, error: None}}, Tea_Cmd.none)
  | AbCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, agenticBridge: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, agenticBridge: {...state, running: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissAbError => ({...model, agenticBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Automation Bridge messages — CI/CD pipeline orchestration.
let updateAutomationBridge = (model: model, msg: automationBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.automationBridge
  switch msg {
  | SetAutoBTab(tab) => ({...model, automationBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | AutoBStarted => ({...model, automationBridge: {...state, running: true, error: None}}, Tea_Cmd.none)
  | AutoBCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, automationBridge: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, automationBridge: {...state, running: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissAutoBError => ({...model, automationBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Database Bridge messages — VeriSimDB game state persistence.
let updateDatabaseBridge = (model: model, msg: databaseBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.databaseBridge
  switch msg {
  | SetDbBTab(tab) => ({...model, databaseBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | DbBStarted => ({...model, databaseBridge: {...state, connected: true, error: None}}, Tea_Cmd.none)
  | DbBCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, databaseBridge: {...state, connected: true}}, Tea_Cmd.none)
    | Error(err) => ({...model, databaseBridge: {...state, connected: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissDbBError => ({...model, databaseBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Protocol Bridge messages — multiplayer sync protocol analysis.
let updateProtocolBridge = (model: model, msg: protocolBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.protocolBridge
  switch msg {
  | SetPbTab(tab) => ({...model, protocolBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | PbStarted => ({...model, protocolBridge: {...state, connected: true, error: None}}, Tea_Cmd.none)
  | PbCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, protocolBridge: {...state, connected: true}}, Tea_Cmd.none)
    | Error(err) => ({...model, protocolBridge: {...state, connected: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissPbError => ({...model, protocolBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Proofs Bridge messages — proven repo formal verification.
let updateProofsBridge = (model: model, msg: proofsBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.proofsBridge
  switch msg {
  | SetPrBTab(tab) => ({...model, proofsBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | PrBStarted => ({...model, proofsBridge: {...state, verifying: true, error: None}}, Tea_Cmd.none)
  | PrBCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, proofsBridge: {...state, verifying: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, proofsBridge: {...state, verifying: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissPrBError => ({...model, proofsBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Scripting Bridge messages — VM instruction scripting REPL.
let updateScriptingBridge = (model: model, msg: scriptingBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.scriptingBridge
  switch msg {
  | SetScBTab(tab) => ({...model, scriptingBridge: {...state, activeTab: tab}}, Tea_Cmd.none)
  | ScBStarted => ({...model, scriptingBridge: {...state, executing: true, error: None}}, Tea_Cmd.none)
  | ScBCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, scriptingBridge: {...state, executing: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, scriptingBridge: {...state, executing: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissScBError => ({...model, scriptingBridge: {...state, error: None}}, Tea_Cmd.none)
  }
}
