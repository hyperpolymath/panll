// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Application Entry Point
///
/// Initializes the TEA application with the Binary Star co-orbit model.

/// Initialize the application
let init = (): (Model.model, Tea_Cmd.t<Msg.msg>) => {
  (Model.init(), Tea_Cmd.none)
}

/// Main TEA program
let main = Tea_App.standardProgram(
  ~init,
  ~update=Update.update,
  ~view=View.view,
  ~subscriptions=SubscriptionsFixed.all,
  (),
)
