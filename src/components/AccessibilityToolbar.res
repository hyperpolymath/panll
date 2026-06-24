// SPDX-License-Identifier: MPL-2.0

/// PanLL AccessibilityToolbar — floating accessibility widget (FAB style).
///
/// Renders as a fixed-position circular button in the bottom-right corner.
/// Clicking it opens a floating panel with categorised accessibility controls:
///   - Theme: Dark / Light / System
///   - Colour Palette: Standard / Deuteranopia / Protanopia / High Contrast
///   - Animation: On / Reduced / Off
///   - Font Size: S / M / L / XL
///   - Focus Indicators: Default / High Contrast / Thick / Dotted
///
/// Inspired by the "All in One Accessibility" WordPress widget pattern:
/// a non-intrusive floating button that expands to a comprehensive panel.
///
/// All dispatch goes through `AccessibilityCtrl(accessibilityMsg)`.
/// The widget reads from `accessibilityState` and uses `AccessibilityEngine`
/// for labels. Position is fixed so it floats above all content.

open Model
open Msg
open Tea.Html

// ===========================================================================
// Shared radio button helper
// ===========================================================================

/// Render a single option button within a control group.
/// Active buttons get a highlighted ring + brighter text.
let renderOption = (label: string, tooltip: string, isActive: bool, onClick: msg): Tea_Vdom.t<
  msg,
> => {
  button(
    list{
      Attrs.class_(
        `px-3 py-1.5 text-xs rounded-md transition-all ${isActive
            ? "bg-indigo-600 text-white ring-2 ring-indigo-400"
            : "bg-gray-800 text-gray-400 hover:bg-gray-700 hover:text-gray-200"}`,
      ),
      Attrs.role("radio"),
      Attrs.ariaSelected(isActive),
      Attrs.title(tooltip),
      Events.onClick(onClick),
    },
    list{text(label)},
  )
}

// ===========================================================================
// Section header helper
// ===========================================================================

/// Render a section heading inside the accessibility panel.
let renderSectionHeader = (title: string): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2 mt-3 first:mt-0",
      ),
    },
    list{text(title)},
  )
}

// ===========================================================================
// Control group renderers
// ===========================================================================

/// Theme mode: Dark / Light / System.
let renderThemeSection = (active: themeMode): Tea_Vdom.t<msg> => {
  let modes: array<(themeMode, string, string)> = [
    (ThemeDark, "Dark", "Dark background with light text"),
    (ThemeLight, "Light", "Light background with dark text"),
    (ThemeSystem, "System", "Follow your OS colour scheme"),
  ]
  div(
    list{Attrs.role("radiogroup"), Attrs.ariaLabel("Theme mode")},
    list{
      renderSectionHeader("Theme"),
      div(
        list{Attrs.class_("flex flex-wrap gap-1.5")},
        modes
        ->Array.map(((mode, label, tooltip)) =>
          renderOption(label, tooltip, mode === active, AccessibilityCtrl(SetThemeMode(mode)))
        )
        ->List.fromArray,
      ),
    },
  )
}

/// Colour palette: Standard / Deuteranopia / Protanopia / High Contrast.
let renderPaletteSection = (active: accessibilityPalette): Tea_Vdom.t<msg> => {
  let palettes: array<(accessibilityPalette, string, string)> = [
    (StandardPalette, "Standard", "Default colour palette"),
    (DeuteranopiaPalette, "Deutan.", "Red-green colour blindness safe"),
    (ProtanopiaPalette, "Protan.", "Protanopia-safe palette"),
    (HighContrastPalette, "Hi-Con", "Maximum contrast for low vision"),
  ]
  div(
    list{Attrs.role("radiogroup"), Attrs.ariaLabel("Colour palette")},
    list{
      renderSectionHeader("Colour Vision"),
      div(
        list{Attrs.class_("flex flex-wrap gap-1.5")},
        palettes
        ->Array.map(((palette, label, tooltip)) =>
          renderOption(
            label,
            tooltip,
            palette === active,
            AccessibilityCtrl(SetAccessibilityPalette(palette)),
          )
        )
        ->List.fromArray,
      ),
    },
  )
}

/// Animation preference: On / Reduced / Off.
let renderAnimationSection = (active: animationPreference): Tea_Vdom.t<msg> => {
  let prefs: array<(animationPreference, string, string)> = [
    (AnimationsOn, "On", "All animations enabled"),
    (AnimationsReduced, "Reduced", "Slower, fewer animations"),
    (AnimationsOff, "Off", "No animations or transitions"),
  ]
  div(
    list{Attrs.role("radiogroup"), Attrs.ariaLabel("Animation preference")},
    list{
      renderSectionHeader("Motion"),
      div(
        list{Attrs.class_("flex flex-wrap gap-1.5")},
        prefs
        ->Array.map(((pref, label, tooltip)) =>
          renderOption(label, tooltip, pref === active, AccessibilityCtrl(SetAnimations(pref)))
        )
        ->List.fromArray,
      ),
    },
  )
}

/// Font size: S / M / L / XL.
let renderFontSizeSection = (active: fontSizePreset): Tea_Vdom.t<msg> => {
  let sizes: array<(fontSizePreset, string)> = [
    (FontSmall, "S"),
    (FontMedium, "M"),
    (FontLarge, "L"),
    (FontExtraLarge, "XL"),
  ]
  div(
    list{Attrs.role("radiogroup"), Attrs.ariaLabel("Font size")},
    list{
      renderSectionHeader("Text Size"),
      div(
        list{Attrs.class_("flex flex-wrap gap-1.5")},
        sizes
        ->Array.map(((preset, shortLabel)) =>
          renderOption(
            shortLabel,
            AccessibilityEngine.fontSizeLabel(preset),
            preset === active,
            AccessibilityCtrl(SetFontSize(preset)),
          )
        )
        ->List.fromArray,
      ),
    },
  )
}

/// Focus indicator style: Default / High Contrast / Thick / Dotted.
let renderFocusSection = (active: focusIndicatorStyle): Tea_Vdom.t<msg> => {
  let styles: array<(focusIndicatorStyle, string)> = [
    (FocusDefault, "Default"),
    (FocusHighContrast, "Hi-Con"),
    (FocusThick, "Thick"),
    (FocusDotted, "Dotted"),
  ]
  div(
    list{Attrs.role("radiogroup"), Attrs.ariaLabel("Focus indicator style")},
    list{
      renderSectionHeader("Focus Ring"),
      div(
        list{Attrs.class_("flex flex-wrap gap-1.5")},
        styles
        ->Array.map(((style, shortLabel)) =>
          renderOption(
            shortLabel,
            AccessibilityEngine.focusStyleLabel(style),
            style === active,
            AccessibilityCtrl(SetFocusStyle(style)),
          )
        )
        ->List.fromArray,
      ),
    },
  )
}

// ===========================================================================
// Main view: FAB + floating panel
// ===========================================================================

/// The floating accessibility panel that appears when the FAB is clicked.
let renderPanel = (state: accessibilityState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "fixed bottom-20 right-4 w-72 max-h-[80vh] overflow-y-auto bg-gray-900 border border-gray-700 rounded-xl shadow-2xl shadow-black/50 z-[9999] p-4",
      ),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Accessibility settings"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          div(
            list{Attrs.class_("text-sm font-semibold text-gray-200")},
            list{text("Accessibility")},
          ),
          button(
            list{
              Attrs.class_("text-gray-500 hover:text-gray-300 transition-colors p-1"),
              Attrs.title("Close accessibility panel"),
              Attrs.ariaLabel("Close accessibility panel"),
              Events.onClick(AccessibilityCtrl(ToggleAccessibilityToolbar)),
              KeyboardNav.onActivate(AccessibilityCtrl(ToggleAccessibilityToolbar)),
            },
            list{text("X")},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-600 mb-3")},
        list{text("Adjust display and interaction preferences")},
      ),
      // Divider
      div(list{Attrs.class_("border-t border-gray-800 mb-1")}, list{}),
      // Control sections
      renderThemeSection(state.theme),
      renderPaletteSection(state.palette),
      renderAnimationSection(state.animations),
      renderFontSizeSection(state.fontSize),
      renderFocusSection(state.focusStyle),
      // Reset link
      div(
        list{Attrs.class_("mt-4 pt-3 border-t border-gray-800 text-center")},
        list{
          button(
            list{
              Attrs.class_("text-xs text-gray-600 hover:text-gray-400 transition-colors"),
              Attrs.title("Reset all accessibility settings to defaults"),
              Events.onClick(AccessibilityCtrl(SetThemeMode(ThemeDark))),
            },
            list{text("Reset to defaults")},
          ),
        },
      ),
    },
  )
}

/// Main view entry point for the floating accessibility widget.
///
/// Renders a fixed-position FAB (Floating Action Button) in the bottom-right
/// corner. When `toolbarExpanded` is true, the floating panel appears above
/// the FAB with all accessibility controls.
///
/// @param state The current accessibility state from the model
let view = (state: accessibilityState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("fixed bottom-4 right-4 z-[9999] flex flex-col items-end gap-2")},
    list{
      // Floating panel (when expanded)
      if state.toolbarExpanded {
        renderPanel(state)
      } else {
        noNode
      },
      // FAB button (always visible)
      button(
        list{
          Attrs.class_(
            "w-12 h-12 rounded-full bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-900/50 flex items-center justify-center transition-all hover:scale-110 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2 focus:ring-offset-gray-950",
          ),
          Attrs.title(
            state.toolbarExpanded ? "Close accessibility settings" : "Open accessibility settings",
          ),
          Attrs.ariaLabel(
            state.toolbarExpanded ? "Close accessibility settings" : "Open accessibility settings",
          ),
          Events.onClick(AccessibilityCtrl(ToggleAccessibilityToolbar)),
          KeyboardNav.onActivate(AccessibilityCtrl(ToggleAccessibilityToolbar)),
        },
        list{
          // Accessibility icon (universal access symbol approximation using text)
          span(list{Attrs.class_("text-lg font-bold")}, list{text("A")}),
        },
      ),
    },
  )
}
