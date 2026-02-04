// SPDX-License-Identifier: PMPL-1.0-or-later

/// Keyboard Subscriptions for TEA
///
/// Provides keyboard event subscriptions since rescript-tea doesn't include them by default.

type keyEvent = {
  key: string,
  ctrlKey: bool,
  shiftKey: bool,
  altKey: bool,
  metaKey: bool,
}

// External bindings for window event listeners
@val @scope("window")
external addEventListener: (string, {..} => unit) => unit = "addEventListener"

@val @scope("window")
external removeEventListener: (string, {..} => unit) => unit = "removeEventListener"

/// Subscribe to keydown events
let onKeyDown = (tagger: keyEvent => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("keyboard-keydown", enabler => {
    let handler = evt => {
      let keyEvt = {
        key: evt["key"],
        ctrlKey: evt["ctrlKey"],
        shiftKey: evt["shiftKey"],
        altKey: evt["altKey"],
        metaKey: evt["metaKey"],
      }
      enabler(tagger(keyEvt))
    }
    addEventListener("keydown", handler)
    // Return cleanup function
    () => removeEventListener("keydown", handler)
  })
}

/// Subscribe to keyup events
let onKeyUp = (tagger: keyEvent => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("keyboard-keyup", enabler => {
    let handler = evt => {
      let keyEvt = {
        key: evt["key"],
        ctrlKey: evt["ctrlKey"],
        shiftKey: evt["shiftKey"],
        altKey: evt["altKey"],
        metaKey: evt["metaKey"],
      }
      enabler(tagger(keyEvt))
    }
    addEventListener("keyup", handler)
    () => removeEventListener("keyup", handler)
  })
}

/// Subscribe to keypress events
let onKeyPress = (tagger: keyEvent => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("keyboard-keypress", enabler => {
    let handler = evt => {
      let keyEvt = {
        key: evt["key"],
        ctrlKey: evt["ctrlKey"],
        shiftKey: evt["shiftKey"],
        altKey: evt["altKey"],
        metaKey: evt["metaKey"],
      }
      enabler(tagger(keyEvt))
    }
    addEventListener("keypress", handler)
    () => removeEventListener("keypress", handler)
  })
}
