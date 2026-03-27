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

  // Register OS colour scheme change listener for System theme mode.
  let colorSchemeCmd = AccessibilityEngine.listenColorSchemeChange(prefersLight => {
    let osTheme: AccessibilityModel.themeMode = if prefersLight {
      ThemeLight
    } else {
      ThemeDark
    }
    Msg.AccessibilityCtrl(OsColorSchemeChanged(osTheme))
  })

  // Apply saved font size on startup (sets <html> font-size for rem scaling).
  let fontSizeCmd = AccessibilityEngine.applyFontSizeCmd(model.accessibility.fontSize)

  // Probe Burble groove endpoint at startup for capability discovery.
  // Non-blocking — if Burble is not running, the error is silently recorded.
  let grooveCmd = BurbleCmd.checkGroove(result =>
    switch result {
    | Ok(_json) => Msg.Burble(BurbleModel.ConnectionChanged(BurbleModel.Connected))
    | Error(err) => Msg.Burble(BurbleModel.ErrorOccurred(err))
    }
  )

  (model, Tea_Cmd.batch(list{colorSchemeCmd, fontSizeCmd, grooveCmd}))
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
