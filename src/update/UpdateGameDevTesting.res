// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

// ===========================================================================
// Game Dev Panel Sub-Updaters — Testing & QA Panels
// ===========================================================================

/// Handles all Unit Test Runner messages — test execution, coverage heatmap.
let updateUnitTestRunner = (model: model, msg: unitTestRunnerMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.unitTestRunner
  switch msg {
  | SetUtrTab(tab) => ({...model, unitTestRunner: {...state, activeTab: tab}}, Tea_Cmd.none)
  | UtrStarted => ({...model, unitTestRunner: {...state, running: true, error: None}}, Tea_Cmd.none)
  | UtrCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, unitTestRunner: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, unitTestRunner: {...state, running: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissUtrError => ({...model, unitTestRunner: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled unit test runner messages
  }
}

/// Handles all Functional Tester messages — end-to-end game workflow simulation.
let updateFunctionalTester = (model: model, msg: functionalTesterMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.functionalTester
  switch msg {
  | SetFtTab(tab) => ({...model, functionalTester: {...state, activeTab: tab}}, Tea_Cmd.none)
  | FtStarted => (
      {...model, functionalTester: {...state, running: true, error: None}},
      Tea_Cmd.none,
    )
  | FtCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, functionalTester: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, functionalTester: {...state, running: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissFtError => ({...model, functionalTester: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled functional tester messages
  }
}

/// Handles all Regression Guard messages — snapshot comparison, golden-file testing.
let updateRegressionGuard = (model: model, msg: regressionGuardMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.regressionGuard
  switch msg {
  | SetRgTab(tab) => ({...model, regressionGuard: {...state, activeTab: tab}}, Tea_Cmd.none)
  | RgStarted => ({...model, regressionGuard: {...state, running: true, error: None}}, Tea_Cmd.none)
  | RgCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, regressionGuard: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, regressionGuard: {...state, running: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissRgError => ({...model, regressionGuard: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled regression guard messages
  }
}

/// Handles all Performance Profiler messages — frame budget, GC pressure, flamegraphs.
let updatePerformanceProfiler = (model: model, msg: performanceProfilerMsg): (
  model,
  Tea_Cmd.t<msg>,
) => {
  let state = model.performanceProfiler
  switch msg {
  | SetPpTab(tab) => ({...model, performanceProfiler: {...state, activeTab: tab}}, Tea_Cmd.none)
  | PpStarted => (
      {...model, performanceProfiler: {...state, profiling: true, error: None}},
      Tea_Cmd.none,
    )
  | PpCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, performanceProfiler: {...state, profiling: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, performanceProfiler: {...state, profiling: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissPpError => ({...model, performanceProfiler: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled performance profiler messages
  }
}

/// Handles all Load Tester messages — Phoenix channel stress testing.
let updateLoadTester = (model: model, msg: loadTesterMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.loadTester
  switch msg {
  | SetLtTab(tab) => ({...model, loadTester: {...state, activeTab: tab}}, Tea_Cmd.none)
  | LtStarted => ({...model, loadTester: {...state, running: true, error: None}}, Tea_Cmd.none)
  | LtCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, loadTester: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, loadTester: {...state, running: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissLtError => ({...model, loadTester: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled load tester messages
  }
}

/// Handles all Soak Monitor messages — long-running session memory trend.
let updateSoakMonitor = (model: model, msg: soakMonitorMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.soakMonitor
  switch msg {
  | SetSmTab(tab) => ({...model, soakMonitor: {...state, activeTab: tab}}, Tea_Cmd.none)
  | SmStarted => ({...model, soakMonitor: {...state, monitoring: true, error: None}}, Tea_Cmd.none)
  | SmCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, soakMonitor: {...state, monitoring: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, soakMonitor: {...state, monitoring: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissSmError => ({...model, soakMonitor: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled soak monitor messages
  }
}

/// Handles all Compatibility Matrix messages — browser/device/resolution test matrix.
let updateCompatibilityMatrix = (model: model, msg: compatibilityMatrixMsg): (
  model,
  Tea_Cmd.t<msg>,
) => {
  let state = model.compatibilityMatrix
  switch msg {
  | SetCmTab(tab) => ({...model, compatibilityMatrix: {...state, activeTab: tab}}, Tea_Cmd.none)
  | CmStarted => (
      {...model, compatibilityMatrix: {...state, running: true, error: None}},
      Tea_Cmd.none,
    )
  | CmCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, compatibilityMatrix: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, compatibilityMatrix: {...state, running: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissCmError => ({...model, compatibilityMatrix: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled compatibility matrix messages
  }
}

/// Handles all Exploratory Workbench messages — freeform play session recording.
let updateExploratoryWorkbench = (model: model, msg: exploratoryWorkbenchMsg): (
  model,
  Tea_Cmd.t<msg>,
) => {
  let state = model.exploratoryWorkbench
  switch msg {
  | SetEwTab(tab) => ({...model, exploratoryWorkbench: {...state, activeTab: tab}}, Tea_Cmd.none)
  | EwStarted => (
      {...model, exploratoryWorkbench: {...state, recording: true, error: None}},
      Tea_Cmd.none,
    )
  | EwCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, exploratoryWorkbench: {...state, recording: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, exploratoryWorkbench: {...state, recording: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissEwError => ({...model, exploratoryWorkbench: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled exploratory workbench messages
  }
}

/// Handles all Beta Feedback Hub messages — feedback-o-tron integration, sentiment.
let updateBetaFeedbackHub = (model: model, msg: betaFeedbackHubMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.betaFeedbackHub
  switch msg {
  | SetBfhTab(tab) => ({...model, betaFeedbackHub: {...state, activeTab: tab}}, Tea_Cmd.none)
  | BfhStarted => (
      {...model, betaFeedbackHub: {...state, submitting: true, error: None}},
      Tea_Cmd.none,
    )
  | BfhCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, betaFeedbackHub: {...state, submitting: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, betaFeedbackHub: {...state, submitting: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissBfhError => ({...model, betaFeedbackHub: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled beta feedback hub messages
  }
}

/// Handles all Balance Analyser messages — game balance stats, Monte Carlo.
let updateBalanceAnalyser = (model: model, msg: balanceAnalyserMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.balanceAnalyser
  switch msg {
  | SetBaTab(tab) => ({...model, balanceAnalyser: {...state, activeTab: tab}}, Tea_Cmd.none)
  | BaStarted => ({...model, balanceAnalyser: {...state, running: true, error: None}}, Tea_Cmd.none)
  | BaCompleted(result) =>
    switch result {
    | Ok(_) => ({...model, balanceAnalyser: {...state, running: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, balanceAnalyser: {...state, running: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissBaError => ({...model, balanceAnalyser: {...state, error: None}}, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled balance analyser messages
  }
}
