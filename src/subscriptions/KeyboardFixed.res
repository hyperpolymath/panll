// SPDX-License-Identifier: MPL-2.0

/// Keyboard Subscriptions for Custom TEA
///
/// Provides keyboard event subscriptions using our custom TEA's registration API.

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
  Tea_Sub.registration("keyboard-keydown", dispatch => {
    let handler = evt => {
      let keyEvt = {
        key: evt["key"],
        ctrlKey: evt["ctrlKey"],
        shiftKey: evt["shiftKey"],
        altKey: evt["altKey"],
        metaKey: evt["metaKey"],
      }
      dispatch(tagger(keyEvt))
    }
    addEventListener("keydown", handler)
    // Return cleanup function
    () => removeEventListener("keydown", handler)
  })
}

/// Subscribe to keyup events
let onKeyUp = (tagger: keyEvent => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("keyboard-keyup", dispatch => {
    let handler = evt => {
      let keyEvt = {
        key: evt["key"],
        ctrlKey: evt["ctrlKey"],
        shiftKey: evt["shiftKey"],
        altKey: evt["altKey"],
        metaKey: evt["metaKey"],
      }
      dispatch(tagger(keyEvt))
    }
    addEventListener("keyup", handler)
    () => removeEventListener("keyup", handler)
  })
}
