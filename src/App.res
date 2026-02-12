// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Application Entry Point
///
/// Initializes the TEA application with the Binary Star co-orbit model.

/// Initialize the application
/// Attempts to restore persisted state then probes panic-attacker capability so the UI
/// knows whether ambush/panll exports are available.
let init = (): (Model.model, Tea_Cmd.t<Msg.msg>) => {
  // Try to load persisted state
  let model = switch Storage.load() {
  | Some(loadedModel) => loadedModel
  | None => Model.init() // Use default if no saved state
  }

  (model, Tea_Cmd.none)
}

/// Main TEA program
/// Bootstraps the standard TEA pipeline (init/update/view/subscriptions).
let main = Tea_App.standardProgram(
  ~init,
  ~update=Update.update,
  ~view=View.view,
  ~subscriptions=SubscriptionsFixed.all,
  (),
)
