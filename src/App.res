// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Application Entry Point
///
/// Initializes the TEA application with the Binary Star co-orbit model.

/// Initialize the application
let init = (): (Model.model, Tea_Cmd.t<Msg.msg>) => {
  // Try to load persisted state
  let model = switch Storage.load() {
  | Some(loadedModel) => loadedModel
  | None => Model.init() // Use default if no saved state
  }

  let capabilityProbe =
    TauriCmd.getPanicAttackerCapability(result => Msg.PaneW(Msg.PanicAttackerCapabilityLoaded(result)))

  (model, capabilityProbe)
}

/// Main TEA program
let main = Tea_App.standardProgram(
  ~init,
  ~update=Update.update,
  ~view=View.view,
  ~subscriptions=SubscriptionsFixed.all,
  (),
)
