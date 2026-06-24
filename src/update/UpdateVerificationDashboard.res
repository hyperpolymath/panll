// SPDX-License-Identifier: MPL-2.0

/// VerificationDashboard — proof/test/benchmark status sub-updater.

open Model
open Msg

let updateVerificationDashboard = (model: model, subMsg: verificationDashboardMsg): (model, Tea_Cmd.t<msg>) => {
  switch subMsg {
  | SetVdCategory(cat) => (
      {...model, verificationDashboard: {...model.verificationDashboard, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SelectVdLanguage(name) => (
      {...model, verificationDashboard: {...model.verificationDashboard, selectedLanguage: name}},
      Tea_Cmd.none,
    )
  | SetVdFilter(txt) => (
      {...model, verificationDashboard: {...model.verificationDashboard, filterText: txt}},
      Tea_Cmd.none,
    )
  | SetVdSort(sortBy) => (
      {...model, verificationDashboard: {...model.verificationDashboard, sortBy}},
      Tea_Cmd.none,
    )
  | ToggleDebtOnly => (
      {
        ...model,
        verificationDashboard: {
          ...model.verificationDashboard,
          showDebtOnly: !model.verificationDashboard.showDebtOnly,
        },
      },
      Tea_Cmd.none,
    )
  | DismissVdError => (
      {...model, verificationDashboard: {...model.verificationDashboard, error: None}},
      Tea_Cmd.none,
    )
  }
}
