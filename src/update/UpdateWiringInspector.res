// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

/// Compute derived audit fields (distribution and bottlenecks) from results.
let computeAuditDerived = (
  state: wiringInspectorState,
  results: array<panelVerification>,
): wiringInspectorState => {
  ...state,
  results,
  distribution: WiringInspectorEngine.computeDistribution(results),
  bottlenecks: WiringInspectorEngine.extractBottlenecks(results),
}

/// Sub-updater for Wiring Inspector — PCC verification lifecycle, audit tabs, and UI state.
let updateWiringInspector = (model: model, msg: wiringInspectorMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.wiringInspector
  switch msg {
  | RunVerification =>
    let newState = {...state, loading: true, error: None}
    let cmd = WiringInspectorCmd.runVerification(result => WiringInspector(
      VerificationResult(result),
    ))
    ({...model, wiringInspector: newState}, cmd)

  | VerificationResult(Ok(json)) =>
    let results = WiringInspectorEngine.parseVerificationJson(json)
    let now = Date.make()->Date.toISOString
    let newState = computeAuditDerived(
      {
        ...state,
        loading: false,
        lastRunAt: Some(now),
        error: None,
      },
      results,
    )
    ({...model, wiringInspector: newState}, Tea_Cmd.none)

  | VerificationResult(Error(e)) =>
    UpdateHelpers.logDegradedService("WiringInspector", e)
    let newState = {...state, loading: false, error: Some(e)}
    ({...model, wiringInspector: newState}, Tea_Cmd.none)

  | RunSingleVerification(panelId) =>
    let newState = {...state, loading: true, error: None}
    let cmd = WiringInspectorCmd.runSingleVerification(panelId, result => WiringInspector(
      SingleVerificationResult(result),
    ))
    ({...model, wiringInspector: newState}, cmd)

  | SingleVerificationResult(Ok(json)) =>
    let results = WiringInspectorEngine.parseVerificationJson(json)
    let now = Date.make()->Date.toISOString
    let newState = computeAuditDerived(
      {
        ...state,
        loading: false,
        lastRunAt: Some(now),
        error: None,
      },
      results,
    )
    ({...model, wiringInspector: newState}, Tea_Cmd.none)

  | SingleVerificationResult(Error(e)) =>
    UpdateHelpers.logDegradedService("WiringInspector", e)
    let newState = {...state, loading: false, error: Some(e)}
    ({...model, wiringInspector: newState}, Tea_Cmd.none)

  | SelectPanel(p) => ({...model, wiringInspector: {...state, selectedPanel: p}}, Tea_Cmd.none)

  | SetFilterStatus(s) => ({...model, wiringInspector: {...state, filterStatus: s}}, Tea_Cmd.none)

  | SetAuditTab(tab) => ({...model, wiringInspector: {...state, activeTab: tab}}, Tea_Cmd.none)

  | SetSortBy(field) => ({...model, wiringInspector: {...state, sortBy: field}}, Tea_Cmd.none)

  | ToggleStateSection(panelState) =>
    // Toggle panel selection to act as expand/collapse for state sections.
    // Uses the state label as a pseudo-panel ID for section tracking.
    let sectionId = WiringInspectorEngine.stateLabel(panelState)
    let newSelected = if state.selectedPanel == Some(sectionId) {
      None
    } else {
      Some(sectionId)
    }
    ({...model, wiringInspector: {...state, selectedPanel: newSelected}}, Tea_Cmd.none)
  }
}
