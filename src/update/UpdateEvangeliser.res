// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

let updateEvangeliser = (model: model, msg: evangeliserMsg): (model, Tea_Cmd.t<msg>) => {
  let ev = model.evangeliser
  switch msg {
  | SetJsInput(code) => ({...model, evangeliser: {...ev, jsInput: code}}, Tea_Cmd.none)
  | RunScan => {
      // Run the scan synchronously (pure computation, no side effects)
      let analysis = EvangeliserEngine.scanCode(ev.jsInput, ev.patterns, ev.constraints)
      (
        {
          ...model,
          evangeliser: {
            ...ev,
            analysis: Some(analysis),
            scanning: false,
            scanError: None,
            activeTab: TabResults,
          },
        },
        Tea_Cmd.none,
      )
    }
  | ScanComplete(result) =>
    switch result {
    | Ok(analysis) => (
        {
          ...model,
          evangeliser: {...ev, analysis: Some(analysis), scanning: false, scanError: None},
        },
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, evangeliser: {...ev, scanning: false, scanError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | SetTab(tab) => ({...model, evangeliser: {...ev, activeTab: tab}}, Tea_Cmd.none)
  | SetViewLayer(vl) => ({...model, evangeliser: {...ev, viewLayer: vl}}, Tea_Cmd.none)
  | SetMinConfidence(conf) => (
      {...model, evangeliser: {...ev, constraints: {...ev.constraints, minConfidence: conf}}},
      Tea_Cmd.none,
    )
  | SetDifficultyFilter(diff) => (
      {...model, evangeliser: {...ev, constraints: {...ev.constraints, difficultyFilter: diff}}},
      Tea_Cmd.none,
    )
  | ToggleCategory(cat) => {
      let cats = ev.constraints.enabledCategories
      let newCats = if cats->Array.includes(cat) {
        cats->Array.filter(c => c !== cat)
      } else {
        Array.concat(cats, [cat])
      }
      (
        {
          ...model,
          evangeliser: {...ev, constraints: {...ev.constraints, enabledCategories: newCats}},
        },
        Tea_Cmd.none,
      )
    }
  | SelectMatch(idx) => ({...model, evangeliser: {...ev, selectedMatchIndex: idx}}, Tea_Cmd.none)
  | SetFilterText(text) => ({...model, evangeliser: {...ev, filterText: text}}, Tea_Cmd.none)
  | DismissError => ({...model, evangeliser: {...ev, error: None, scanError: None}}, Tea_Cmd.none)
  }
}
