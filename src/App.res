// SPDX-License-Identifier: AGPL-3.0-or-later

/// PanLL Application Entry Point
///
/// Initialises the TEA application with the Binary Star co-orbit model.

open Tea.App

let main = standardProgram({
  init: () => (Model.init(), Tea.Cmd.none),
  update: Update.update,
  view: View.view,
  subscriptions: _ => Tea.Sub.none,
})
