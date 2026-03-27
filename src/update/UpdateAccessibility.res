// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// Update handler for accessibility preferences.
/// Manages colour palette, animation, font size, and focus indicator changes.
let updateAccessibility = (model: model, msg: accessibilityMsg): (model, Tea_Cmd.t<msg>) => {
  let a = model.accessibility
  // Helper: update state and persist to localStorage in one step.
  let withSave = (newA: accessibilityState) => {
    ({...model, accessibility: newA}, AccessibilityEngine.saveCmd(newA))
  }
  switch msg {
  | SetAccessibilityPalette(palette) => {
      let newA = {...a, palette}
      // Also update provenance palette for backward compatibility
      (
        {...model, accessibility: newA, provenance: {...model.provenance, palette}},
        AccessibilityEngine.saveCmd(newA),
      )
    }
  | SetThemeMode(theme) => {
      let resolvedTheme = switch theme {
      | ThemeSystem => AccessibilityEngine.detectOsColorScheme()
      | other => other
      }
      withSave({...a, theme, resolvedTheme})
    }
  | OsColorSchemeChanged(osTheme) =>
    // Only update resolvedTheme if user is in System mode.
    if a.theme === ThemeSystem {
      ({...model, accessibility: {...a, resolvedTheme: osTheme}}, Tea_Cmd.none)
    } else {
      (model, Tea_Cmd.none)
    }
  | SetAnimations(pref) => withSave({...a, animations: pref})
  | SetFontSize(size) => {
      let newA = {...a, fontSize: size}
      (
        {...model, accessibility: newA},
        Tea_Cmd.batch(list{
          AccessibilityEngine.saveCmd(newA),
          AccessibilityEngine.applyFontSizeCmd(size),
        }),
      )
    }
  | SetFocusStyle(style) => withSave({...a, focusStyle: style})
  | ToggleAccessibilityToolbar => // Don't persist toolbar expanded state — it's transient.
    ({...model, accessibility: {...a, toolbarExpanded: !a.toolbarExpanded}}, Tea_Cmd.none)
  }
}
