// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

// ===========================================================================
// Game Dev Panel Sub-Updaters — Game-Specific Panels
// ===========================================================================

/// Handles all Generator Mode messages — parametric procedural world builder.
let updateGeneratorMode = (model: model, msg: generatorModeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.generatorMode
  switch msg {
  | SetGenCategory(cat) => ({...model, generatorMode: {...state, activeTab: cat}}, Tea_Cmd.none)
  | GenStarted => ({...model, generatorMode: {...state, generating: true, error: None}}, Tea_Cmd.none)
  | GenCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, generatorMode: {...state, generating: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, generatorMode: {...state, generating: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissGenError => ({...model, generatorMode: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Architect Mode messages — PixiJS fine-grained level editor.
/// Tab switching and error dismissal only (no running state field).
let updateArchitectMode = (model: model, msg: architectModeMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.architectMode
  switch msg {
  | SetArchModeCategory(cat) => ({...model, architectMode: {...state, activeTab: cat}}, Tea_Cmd.none)
  | ArchModeStarted => (model, Tea_Cmd.none)
  | ArchModeCompleted(_) => (model, Tea_Cmd.none)
  | DismissArchModeError => ({...model, architectMode: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Guard AI Tuner messages — guard patrol, alert threshold tuning.
let updateGuardAiTuner = (model: model, msg: guardAiTunerMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.guardAiTuner
  switch msg {
  | SetGatCategory(cat) => ({...model, guardAiTuner: {...state, activeTab: cat}}, Tea_Cmd.none)
  | GatStarted => ({...model, guardAiTuner: {...state, editing: true, error: None}}, Tea_Cmd.none)
  | GatCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, guardAiTuner: {...state, editing: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, guardAiTuner: {...state, editing: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissGatError => ({...model, guardAiTuner: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Device Network Designer messages — wire devices, security levels.
let updateDeviceNetworkDesigner = (model: model, msg: deviceNetworkDesignerMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.deviceNetworkDesigner
  switch msg {
  | SetDndCategory(cat) => ({...model, deviceNetworkDesigner: {...state, activeTab: cat}}, Tea_Cmd.none)
  | DndStarted => ({...model, deviceNetworkDesigner: {...state, wiringMode: true, error: None}}, Tea_Cmd.none)
  | DndCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, deviceNetworkDesigner: {...state, wiringMode: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, deviceNetworkDesigner: {...state, wiringMode: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissDndError => ({...model, deviceNetworkDesigner: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Asset Manager messages — PixiJS sprites, sounds, templates.
let updateAssetManager = (model: model, msg: assetManagerMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.assetManager
  switch msg {
  | SetAmCategory(cat) => ({...model, assetManager: {...state, activeTab: cat}}, Tea_Cmd.none)
  | AmStarted => ({...model, assetManager: {...state, importing: true, error: None}}, Tea_Cmd.none)
  | AmCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, assetManager: {...state, importing: false}}, Tea_Cmd.none)
    | Error(err) => ({...model, assetManager: {...state, importing: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DismissAmError => ({...model, assetManager: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Playtest Recorder messages — record + replay sessions.
/// Tab switching and error dismissal only (playback state managed externally).
let updatePlaytestRecorder = (model: model, msg: playtestRecorderMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.playtestRecorder
  switch msg {
  | SetPrCategory(cat) => ({...model, playtestRecorder: {...state, activeTab: cat}}, Tea_Cmd.none)
  | PrStarted => (model, Tea_Cmd.none)
  | PrCompleted(_) => (model, Tea_Cmd.none)
  | DismissPrError => ({...model, playtestRecorder: {...state, error: None}}, Tea_Cmd.none)
  }
}
