// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

// ════════════════════════════════════════════════════════════════════════
// Floor Raise campaign panel sub-updaters
// ════════════════════════════════════════════════════════════════════════

/// Floor Raise campaign dashboard — tab switching, scan, campaign dispatch.
let updateFloorRaise = (model: model, msg: floorRaiseMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.floorRaise
  switch msg {
  | SetTab(tab) => ({...model, floorRaise: {...state, activeTab: tab}}, Tea_Cmd.none)
  | ScanAdoption => ({...model, floorRaise: {...state, scanning: true, error: None}}, Tea_Cmd.none)
  | AdoptionScanned(Ok(_json)) => (
      {...model, floorRaise: {...state, scanning: false}},
      Tea_Cmd.none,
    )
  | AdoptionScanned(Error(err)) => (
      {...model, floorRaise: {...state, scanning: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunCampaign(_tool) => (model, Tea_Cmd.none)
  | CampaignResult(Ok(_json)) => (model, Tea_Cmd.none)
  | CampaignResult(Error(err)) => (
      {...model, floorRaise: {...state, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, floorRaise: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Proven Adoption scanner — tab switching, scan, repo selection.
let updateProvenAdoption = (model: model, msg: provenAdoptionMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.provenAdoption
  switch msg {
  | SetTab(tab) => ({...model, provenAdoption: {...state, activeTab: tab}}, Tea_Cmd.none)
  | ScanRepos => ({...model, provenAdoption: {...state, scanning: true, error: None}}, Tea_Cmd.none)
  | ReposScanned(Ok(_json)) => (
      {...model, provenAdoption: {...state, scanning: false}},
      Tea_Cmd.none,
    )
  | ReposScanned(Error(err)) => (
      {...model, provenAdoption: {...state, scanning: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectRepo(name) => (
      {...model, provenAdoption: {...state, selectedRepo: Some(name)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, provenAdoption: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Contractile Completeness scanner — tab switching, scan, repo selection.
let updateContractileCompleteness = (model: model, msg: contractileCompletenessMsg): (
  model,
  Tea_Cmd.t<msg>,
) => {
  let state = model.contractileCompleteness
  switch msg {
  | SetTab(tab) => ({...model, contractileCompleteness: {...state, activeTab: tab}}, Tea_Cmd.none)
  | ScanRepos => (
      {...model, contractileCompleteness: {...state, scanning: true, error: None}},
      Tea_Cmd.none,
    )
  | ReposScanned(Ok(_json)) => (
      {...model, contractileCompleteness: {...state, scanning: false}},
      Tea_Cmd.none,
    )
  | ReposScanned(Error(err)) => (
      {...model, contractileCompleteness: {...state, scanning: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectRepo(name) => (
      {...model, contractileCompleteness: {...state, selectedRepo: Some(name)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, contractileCompleteness: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Manifest Coverage scanner — tab switching, scan, repo selection.
let updateManifestCoverage = (model: model, msg: manifestCoverageMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.manifestCoverage
  switch msg {
  | SetTab(tab) => ({...model, manifestCoverage: {...state, activeTab: tab}}, Tea_Cmd.none)
  | ScanRepos => (
      {...model, manifestCoverage: {...state, scanning: true, error: None}},
      Tea_Cmd.none,
    )
  | ReposScanned(Ok(_json)) => (
      {...model, manifestCoverage: {...state, scanning: false}},
      Tea_Cmd.none,
    )
  | ReposScanned(Error(err)) => (
      {...model, manifestCoverage: {...state, scanning: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectRepo(name) => (
      {...model, manifestCoverage: {...state, selectedRepo: Some(name)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, manifestCoverage: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// VeriSimDB Feeds viewer — tab switching, health check, feed selection.
let updateVerisimdbFeeds = (model: model, msg: verisimdbFeedsMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.verisimdbFeeds
  switch msg {
  | SetTab(tab) => ({...model, verisimdbFeeds: {...state, activeTab: tab}}, Tea_Cmd.none)
  | CheckFeeds => (
      {...model, verisimdbFeeds: {...state, checking: true, error: None}},
      Tea_Cmd.none,
    )
  | FeedsChecked(Ok(_json)) => (
      {...model, verisimdbFeeds: {...state, checking: false}},
      Tea_Cmd.none,
    )
  | FeedsChecked(Error(err)) => (
      {...model, verisimdbFeeds: {...state, checking: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectFeed(feedId) => (
      {...model, verisimdbFeeds: {...state, selectedFeed: Some(feedId)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, verisimdbFeeds: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Feedback Routing viewer — tab switching, refresh, report selection.
let updateFeedbackRouting = (model: model, msg: feedbackRoutingMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.feedbackRouting
  switch msg {
  | SetTab(tab) => ({...model, feedbackRouting: {...state, activeTab: tab}}, Tea_Cmd.none)
  | RefreshReports => (
      {...model, feedbackRouting: {...state, refreshing: true, error: None}},
      Tea_Cmd.none,
    )
  | ReportsRefreshed(Ok(_json)) => (
      {...model, feedbackRouting: {...state, refreshing: false}},
      Tea_Cmd.none,
    )
  | ReportsRefreshed(Error(err)) => (
      {...model, feedbackRouting: {...state, refreshing: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectReport(reportId) => (
      {...model, feedbackRouting: {...state, selectedReport: Some(reportId)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, feedbackRouting: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// 007 Toolchain update handler.
let updateOo7Toolchain = (model: model, msg: oo7Msg): (model, Tea_Cmd.t<msg>) => {
  let state = model.oo7toolchain
  switch msg {
  | SetCategory(cat) => ({...model, oo7toolchain: {...state, activeCategory: cat}}, Tea_Cmd.none)
  | ConnectDaemon => (
      {...model, oo7toolchain: {...state, loading: true, error: None}},
      Tea_Cmd.none,
    )
  | DisconnectDaemon => ({...model, oo7toolchain: {...state, isConnected: false}}, Tea_Cmd.none)
  | SetPermissions(p) => ({...model, oo7toolchain: {...state, permissions: p}}, Tea_Cmd.none)
  | RunStage(_stage) => ({...model, oo7toolchain: {...state, loading: true}}, Tea_Cmd.none)
  | StageResult(stage, result) =>
    switch result {
    | Ok(out) =>
      let newOutputs = state.stageOutputs->Array.filter(((s, _)) => s !== stage)
      let newOutputs = Array.concat(newOutputs, [(stage, out)])
      ({...model, oo7toolchain: {...state, loading: false, stageOutputs: newOutputs}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, oo7toolchain: {...state, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | UpdateSource(code) => ({...model, oo7toolchain: {...state, sourceCode: code}}, Tea_Cmd.none)
  | LoadToolchain => ({...model, oo7toolchain: {...state, loaded: true}}, Tea_Cmd.none)
  | ClearError => ({...model, oo7toolchain: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Vexometer Friction viewer — tab switching, measurement, tool selection.
let updateVexometerFriction = (model: model, msg: vexometerFrictionMsg): (
  model,
  Tea_Cmd.t<msg>,
) => {
  let state = model.vexometerFriction
  switch msg {
  | SetTab(tab) => ({...model, vexometerFriction: {...state, activeTab: tab}}, Tea_Cmd.none)
  | MeasureAll => (
      {...model, vexometerFriction: {...state, measuring: true, error: None}},
      Tea_Cmd.none,
    )
  | MeasureResult(Ok(_json)) => (
      {...model, vexometerFriction: {...state, measuring: false}},
      Tea_Cmd.none,
    )
  | MeasureResult(Error(err)) => (
      {...model, vexometerFriction: {...state, measuring: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectTool(name) => (
      {...model, vexometerFriction: {...state, selectedTool: Some(name)}},
      Tea_Cmd.none,
    )
  | ClearError => ({...model, vexometerFriction: {...state, error: None}}, Tea_Cmd.none)
  }
}
