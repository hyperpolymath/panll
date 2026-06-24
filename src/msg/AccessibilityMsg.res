// SPDX-License-Identifier: MPL-2.0

/// Accessibility toolbar messages -- palette, animation, font size, focus indicators.

open Model

type accessibilityMsg =
  /// Switch the active colour palette (Standard, Deuteranopia, Protanopia, High Contrast).
  | SetAccessibilityPalette(accessibilityPalette)
  /// Set the theme mode (Dark, Light, System).
  | SetThemeMode(themeMode)
  /// OS colour scheme changed (dispatched by matchMedia listener when in System mode).
  | OsColorSchemeChanged(themeMode)
  /// Set the animation preference (On, Reduced, Off).
  | SetAnimations(animationPreference)
  /// Set the font size preset.
  | SetFontSize(fontSizePreset)
  /// Set the focus indicator style.
  | SetFocusStyle(focusIndicatorStyle)
  /// Toggle the accessibility toolbar expanded/collapsed state.
  | ToggleAccessibilityToolbar
