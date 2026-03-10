// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Accessibility Model — types for the accessibility toolbar and preferences.
///
/// Centralises all accessibility-related state that was previously scattered
/// across Provenance (palette) and CSS-only media queries (reduced motion,
/// high contrast). Provides explicit user-controlled toggles that complement
/// (and can override) OS-level preferences.
///
/// Controls:
///   - Colour palette: Standard, Deuteranopia, Protanopia, High Contrast
///   - Animation: On, Reduced, Off (overrides prefers-reduced-motion)
///   - Font size: Small, Medium, Large, Extra Large
///   - Focus indicators: Default, High Contrast, Thick, Dotted
///
/// The toolbar renders in the top bar area, consolidating accessibility
/// controls into a single discoverable location.
///
/// Dependency: imports ProvenanceModel for accessibilityPalette type only.

/// Theme mode controlling light/dark appearance.
/// System follows the OS prefers-color-scheme media query.
type themeMode =
  /// Dark background with light text (PanLL default).
  | ThemeDark
  /// Light background with dark text.
  | ThemeLight
  /// Follow the operating system's prefers-color-scheme setting.
  | ThemeSystem

/// Font size presets that apply globally via CSS class on the root element.
/// Each preset maps to a CSS custom property or Tailwind text size modifier.
type fontSizePreset =
  /// 14px base — compact display for experienced users or small screens.
  | FontSmall
  /// 16px base — default comfortable reading size.
  | FontMedium
  /// 18px base — larger text for accessibility or preference.
  | FontLarge
  /// 20px base — maximum size for users with low vision.
  | FontExtraLarge

/// Animation preference that complements the OS-level prefers-reduced-motion.
/// Users can explicitly override OS settings per-application.
type animationPreference =
  /// All animations and transitions run normally.
  | AnimationsOn
  /// Animations play but at reduced speed/frequency. Pulse effects are
  /// slowed, transitions shortened. Maps to the same behaviour as
  /// prefers-reduced-motion: reduce but user-controlled.
  | AnimationsReduced
  /// All animations and transitions are completely disabled.
  /// Overrides even AnimationsOn if the user explicitly wants stillness.
  | AnimationsOff

/// Focus indicator style options for keyboard navigation visibility.
/// Complements the existing :focus-visible CSS rules with user choice.
type focusIndicatorStyle =
  /// Default 2px indigo outline (standard PanLL style).
  | FocusDefault
  /// 3px black outline for maximum visibility against any background.
  | FocusHighContrast
  /// 4px indigo outline — same colour as default but thicker.
  | FocusThick
  /// 3px dotted outline — alternative visual style that some users
  /// find easier to distinguish from borders.
  | FocusDotted

/// Root state for accessibility preferences.
/// All fields are persisted to localStorage for cross-session continuity.
type accessibilityState = {
  /// Active colour palette applied globally to all trust indicators,
  /// status dots, and colour-coded UI elements.
  palette: ProvenanceModel.accessibilityPalette,
  /// Light/dark/system theme mode.
  theme: themeMode,
  /// Animation preference — overrides OS setting when explicitly set.
  animations: animationPreference,
  /// Font size preset applied via CSS class on the root element.
  fontSize: fontSizePreset,
  /// Focus indicator style for keyboard navigation visibility.
  focusStyle: focusIndicatorStyle,
  /// Whether the accessibility toolbar is expanded (showing all controls)
  /// or collapsed (showing just the accessibility icon).
  toolbarExpanded: bool,
  /// Resolved theme (Dark or Light) after evaluating System mode against
  /// the OS preference. Updated by the subscription that watches
  /// prefers-color-scheme changes.
  resolvedTheme: themeMode,
}
