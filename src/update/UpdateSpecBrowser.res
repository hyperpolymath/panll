// SPDX-License-Identifier: PMPL-1.0-or-later

/// SpecBrowser — language specification browsing sub-updater.

open Model
open Msg

let updateSpecBrowser = (model: model, subMsg: specBrowserMsg): (model, Tea_Cmd.t<msg>) => {
  switch subMsg {
  | SetSpecCategory(cat) => (
      {...model, specBrowser: {...model.specBrowser, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SelectSpecLanguage(name) => (
      {...model, specBrowser: {...model.specBrowser, selectedLanguage: name}},
      Tea_Cmd.none,
    )
  | SetComparisonSide(side, name) =>
    switch side {
    | LeftSide => (
        {...model, specBrowser: {...model.specBrowser, comparisonLeft: Some(name)}},
        Tea_Cmd.none,
      )
    | RightSide => (
        {...model, specBrowser: {...model.specBrowser, comparisonRight: Some(name)}},
        Tea_Cmd.none,
      )
    }
  | SetSpecFilter(txt) => (
      {...model, specBrowser: {...model.specBrowser, filterText: txt}},
      Tea_Cmd.none,
    )
  | ToggleIncompleteOnly => (
      {
        ...model,
        specBrowser: {
          ...model.specBrowser,
          showIncompleteOnly: !model.specBrowser.showIncompleteOnly,
        },
      },
      Tea_Cmd.none,
    )
  | DismissSpecError => (
      {...model, specBrowser: {...model.specBrowser, error: None}},
      Tea_Cmd.none,
    )
  }
}
