// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Subscriptions - External event handling
///
/// This module defines all subscriptions (external events) that the
/// PanLL environment listens to, following the TEA pattern.

open Model
open Msg

/// Main subscriptions function
/// Called by TEA runtime to set up event listeners
let subscriptions = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    // Keyboard shortcuts for pane toggling
    Keyboard.onKeyDown(evt => {
      // Check for Ctrl+Shift+L/N/B shortcuts
      if evt.ctrlKey && evt.shiftKey {
        switch evt.key {
        | "L" => View(TogglePaneL)
        | "N" => View(TogglePaneN)
        | "B" | "W" => View(TogglePaneW) // Both B and W work
        | _ => NoOp
        }
      } else {
        NoOp
      }
    }),

    // Update vexation index periodically (every 2 seconds)
    // Only when the vexometer is active and inference is running
    if model.paneN.inferenceActive {
      Tea_Time.every(2000.0, _time => {
        // Request vexation index update from backend
        Vexometer(RequestVexationIndex)
      })
    } else {
      Tea_Sub.none
    },

    // Animation frame for smooth orbital drift aura
    if model.viewMode !== Ambient {
      Tea_Animationframe.onAnimationFrame(_time => {
        // Update orbital state for smooth animations
        NoOp // Placeholder for future orbital animation updates
      })
    } else {
      Tea_Sub.none
    },
  })
}

/// Subscription for when inference is active
/// This enables more frequent updates during active neural inference
let inferenceSubscriptions = (model: model): Tea_Sub.t<msg> => {
  if model.paneN.inferenceActive {
    Tea_Sub.batch(list{
      // More frequent vexation updates during inference
      Tea_Time.every(500.0, _time => Vexometer(RequestVexationIndex)),

      // Monitor for operator input
      Keyboard.onKeyDown(_evt => {
        // Any keyboard input resets the "last operator input" timer
        PaneN(UpdateAgency({
          phase: model.paneN.agency.phase,
          autonomyLevel: model.paneN.agency.autonomyLevel,
          lastOperatorInput: Date.now(),
        }))
      }),
    })
  } else {
    Tea_Sub.none
  }
}

/// Combined subscriptions
/// Use this as the main subscriptions function in App.res
let all = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{subscriptions(model), inferenceSubscriptions(model)})
}
