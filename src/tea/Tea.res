// SPDX-License-Identifier: AGPL-3.0-or-later

/// TEA - The Elm Architecture for ReScript
///
/// A minimal, self-contained implementation of The Elm Architecture
/// pattern for PanLL eNSAID.
///
/// This implementation provides:
/// - Model-Update-View cycle
/// - Commands for side effects
/// - Subscriptions for external events
/// - Virtual DOM with efficient rendering

/// Re-export all TEA modules
module Cmd = Tea_Cmd
module Sub = Tea_Sub
module Html = Tea_Html
module Vdom = Tea_Vdom
module App = Tea_App
module Render = Tea_Render

/// Convenience re-exports for the App module
let standardProgram = Tea_App.standardProgram
let simpleProgram = Tea_App.simpleProgram
