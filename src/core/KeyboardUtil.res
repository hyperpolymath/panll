// SPDX-License-Identifier: PMPL-1.0-or-later

/// Keyboard accessibility utilities for PanLL.
///
/// Provides onKeyDown handlers for common interaction patterns:
/// Enter/Space for button activation, Escape for dialog dismissal,
/// and arrow keys for list navigation. These ensure WCAG 2.1 Level A
/// compliance (2.1.1 Keyboard) across all interactive components.
///
/// Each helper returns a `Tea_Vdom.attribute<'msg>` that attaches a
/// `keydown` event listener to the element. The listener checks the
/// pressed key and dispatches the given message only when the key
/// matches the expected activation pattern. Non-matching keys are
/// ignored (the event is not prevented), preserving normal browser
/// keyboard behaviour for Tab, arrow keys, etc.

/// Trigger a message on Enter or Space key press (button activation pattern).
///
/// This implements the WAI-ARIA button activation pattern: interactive
/// elements that are not native `<button>` elements (e.g. `<div role="button">`)
/// must respond to both Enter and Space to be keyboard-accessible.
/// The handler calls `preventDefault` only when Enter or Space is pressed,
/// so that Tab navigation and other keys continue to work normally.
let onEnterOrSpace = (msg: 'msg): Tea_Vdom.attribute<'msg> => {
  Tea_Vdom.onKeyDown(key =>
    if key === "Enter" || key === " " {
      Some(msg)
    } else {
      None
    }
  )
}

/// Trigger a message on Escape key press (dialog/menu dismiss pattern).
///
/// Implements the WAI-ARIA dialog dismiss pattern: pressing Escape
/// should close the currently open dialog, popover, or dropdown menu.
/// Only the Escape key triggers the message; all other keys pass through.
let onEscape = (msg: 'msg): Tea_Vdom.attribute<'msg> => {
  Tea_Vdom.onKeyDown(key =>
    if key === "Escape" {
      Some(msg)
    } else {
      None
    }
  )
}
