// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Subscriptions - External event handling (Custom TEA version)
///
/// This module defines all subscriptions (external events) that the
/// PanLL environment listens to, following the TEA pattern.

open Model
open Msg

/// Main subscriptions function
let subscriptions = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    // Keyboard shortcuts for pane toggling
    KeyboardFixed.onKeyDown(evt => {
      // Check for Ctrl+Shift+L/N/B shortcuts
      if evt.ctrlKey && evt.shiftKey {
        switch evt.key {
        | "L" => View(TogglePaneL)
        | "N" => View(TogglePaneN)
        | "B" | "W" => View(TogglePaneW)
        | "V" => Vab(ToggleVab) // Toggle VAB panel
        | _ => NoOp
        }
      } else {
        NoOp
      }
    }),

    // Update vexation index periodically (every 2 seconds)
    // Only when vexometer is active
    if model.paneN.inferenceActive {
      Tea_Time.every(2000.0, _time => {
        Vexometer(RequestVexationIndex)
      })
    } else {
      Tea_Sub.none
    },
  })
}

/// Subscription for when inference is active
let inferenceSubscriptions = (model: model): Tea_Sub.t<msg> => {
  if model.paneN.inferenceActive {
    Tea_Sub.batch(list{
      // More frequent updates during inference
      Tea_Time.every(500.0, _time => Vexometer(RequestVexationIndex)),
    })
  } else {
    Tea_Sub.none
  }
}

/// Combined subscriptions
let all = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{subscriptions(model), inferenceSubscriptions(model)})
}
