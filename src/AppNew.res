// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Application Entry Point (Official rescript-tea version)
///
/// Initializes the TEA application using official rescript-tea package.

/// Initialize the application with the starting model and commands
let init = (): (Model.model, Tea_Cmd.t<Msg.msg>) => {
  let initialModel = Model.init()

  // Initial commands to run on startup
  let initialCommands = Tea_Cmd.batch(list{
    // Get initial vexation index from backend
    TauriCmd.getVexationIndex(index => Msg.Vexometer(UpdateVexationIndex(index))),

    // Log startup
    Tea_Cmd.none,
  })

  (initialModel, initialCommands)
}

/// Main TEA program configuration
let main = Tea_App.standardProgram(
  ~init,
  ~update=Update.update,
  ~view=View.view,
  ~subscriptions=Subscriptions.all,
  (),
)

/// Start the application
/// This function is called from the generated JavaScript
@val external startApp: Tea_App.programInterface<'msg, 'model> => unit = "Tea.App.start"

// Uncomment when ready to run:
// let () = startApp(main)
