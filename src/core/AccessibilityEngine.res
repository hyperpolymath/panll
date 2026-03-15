// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL AccessibilityEngine — Pure computation + side-effectful persistence
/// for accessibility preferences.
///
/// Pure functions map accessibility state (theme, palette, animations, font
/// size, focus style) to CSS classes applied at the root element level.
///
/// Side-effectful functions handle:
///   - localStorage persistence (save/load all preferences)
///   - OS preference detection (prefers-color-scheme, prefers-reduced-motion)
///   - prefers-color-scheme change subscription for System theme mode
///
/// DESIGN NOTE: Each preference dimension maps to exactly one CSS class on the
/// root element. Theme mode adds either "theme-light" or nothing (dark is default).
/// The "theme-light" class inverts background/text colours via CSS custom properties.

// ============================================================================
// LocalStorage key
// ============================================================================

/// The single localStorage key under which all accessibility preferences are
/// stored as a JSON object. Using one key keeps reads/writes atomic.
let storageKey = "panll-accessibility"

// ============================================================================
// Theme helpers (pure)
// ============================================================================

/// Human-readable label for a theme mode.
let themeLabel = (mode: AccessibilityModel.themeMode): string => {
  switch mode {
  | ThemeDark => "Dark"
  | ThemeLight => "Light"
  | ThemeSystem => "System"
  }
}

/// CSS class for the resolved theme. Dark returns "" (default), Light returns
/// "theme-light" which triggers CSS custom property overrides.
let themeClass = (state: AccessibilityModel.accessibilityState): string => {
  let effective = switch state.theme {
  | ThemeSystem => state.resolvedTheme
  | other => other
  }
  switch effective {
  | ThemeLight => "theme-light"
  | _ => ""
  }
}

// ============================================================================
// Font size helpers (pure)
// ============================================================================

/// Map a font size preset to a pixel value for the root <html> element.
/// Since Tailwind uses rem units, changing the root font-size scales
/// everything proportionally.
let fontSizePx = (preset: AccessibilityModel.fontSizePreset): int => {
  switch preset {
  | FontSmall => 14
  | FontMedium => 16
  | FontLarge => 18
  | FontExtraLarge => 20
  }
}

/// Raw JS function to set font size on <html> element.
let setRootFontSize: string => unit = %raw(`
  function(px) {
    try { document.documentElement.style.fontSize = px + "px"; } catch(e) {}
  }
`)

/// Apply the font size to <html> element via direct DOM manipulation.
/// This scales all rem-based Tailwind sizes proportionally.
let applyFontSize = (preset: AccessibilityModel.fontSizePreset): unit => {
  setRootFontSize(Int.toString(fontSizePx(preset)))
}

/// TEA command that applies font size to the DOM.
let applyFontSizeCmd = (preset: AccessibilityModel.fontSizePreset): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(_callbacks => {
    applyFontSize(preset)
  })
}

/// Map a font size preset to its CSS class name (kept for rootClasses but
/// no longer the primary mechanism — applyFontSize handles actual scaling).
let fontSizeClass = (_preset: AccessibilityModel.fontSizePreset): string => {
  // No longer used for root classes — font size is applied directly to <html>.
  ""
}

/// Human-readable label for a font size preset.
let fontSizeLabel = (preset: AccessibilityModel.fontSizePreset): string => {
  switch preset {
  | FontSmall => "Small (14px)"
  | FontMedium => "Medium (16px)"
  | FontLarge => "Large (18px)"
  | FontExtraLarge => "Extra Large (20px)"
  }
}

// ============================================================================
// Animation helpers (pure)
// ============================================================================

/// Map an animation preference to its corresponding CSS class name.
let animationClass = (pref: AccessibilityModel.animationPreference): string => {
  switch pref {
  | AnimationsOn => ""
  | AnimationsReduced => "animations-reduced"
  | AnimationsOff => "animations-off"
  }
}

/// Human-readable label for an animation preference.
let animationLabel = (pref: AccessibilityModel.animationPreference): string => {
  switch pref {
  | AnimationsOn => "Animations On"
  | AnimationsReduced => "Animations Reduced"
  | AnimationsOff => "Animations Off"
  }
}

// ============================================================================
// Focus style helpers (pure)
// ============================================================================

/// Map a focus indicator style to its corresponding CSS class name.
let focusStyleClass = (style: AccessibilityModel.focusIndicatorStyle): string => {
  switch style {
  | FocusDefault => ""
  | FocusHighContrast => "focus-high-contrast"
  | FocusThick => "focus-thick"
  | FocusDotted => "focus-dotted"
  }
}

/// Human-readable label for a focus indicator style.
let focusStyleLabel = (style: AccessibilityModel.focusIndicatorStyle): string => {
  switch style {
  | FocusDefault => "Default (2px indigo)"
  | FocusHighContrast => "High Contrast (3px black)"
  | FocusThick => "Thick (4px indigo)"
  | FocusDotted => "Dotted (3px dotted)"
  }
}

// ============================================================================
// Root classes (pure)
// ============================================================================

/// Combine all accessibility CSS classes into a single space-separated string
/// for the root element.
///
/// Called on every render to produce the class attribute for the app root.
/// Filters out empty strings so there are no double-spaces in the output.
///
/// Example output: "theme-light text-lg animations-reduced focus-high-contrast"
/// Example output (all defaults): "text-base"
let rootClasses = (state: AccessibilityModel.accessibilityState): string => {
  let classes = [
    themeClass(state),
    fontSizeClass(state.fontSize),
    animationClass(state.animations),
    focusStyleClass(state.focusStyle),
  ]
  classes
  ->Array.filter(c => c !== "")
  ->Array.join(" ")
}

// ============================================================================
// OS preference detection (side-effectful)
// ============================================================================

/// Detect the OS colour scheme preference via matchMedia.
/// Returns ThemeDark or ThemeLight.
let detectOsColorScheme = (): AccessibilityModel.themeMode => {
  try {
    let _mql = %raw(`window.matchMedia("(prefers-color-scheme: light)")`)
    let matches: bool = %raw(`_mql.matches`)
    if matches { AccessibilityModel.ThemeLight } else { ThemeDark }
  } catch {
  | _ => ThemeDark
  }
}

/// Detect the OS reduced-motion preference.
/// Returns true if the OS prefers reduced motion.
let detectOsReducedMotion = (): bool => {
  try {
    let _mql = %raw(`window.matchMedia("(prefers-reduced-motion: reduce)")`)
    let matches: bool = %raw(`_mql.matches`)
    matches
  } catch {
  | _ => false
  }
}

// ============================================================================
// localStorage persistence (side-effectful)
// ============================================================================

/// Serialise a theme mode to a JSON-safe string.
let themeToString = (mode: AccessibilityModel.themeMode): string => {
  switch mode {
  | ThemeDark => "dark"
  | ThemeLight => "light"
  | ThemeSystem => "system"
  }
}

/// Parse a theme mode from a string. Returns None for unknown values.
let themeFromString = (s: string): option<AccessibilityModel.themeMode> => {
  switch s {
  | "dark" => Some(ThemeDark)
  | "light" => Some(ThemeLight)
  | "system" => Some(ThemeSystem)
  | _ => None
  }
}

/// Serialise a palette to a string.
let paletteToString = (p: ProvenanceModel.accessibilityPalette): string => {
  switch p {
  | StandardPalette => "standard"
  | DeuteranopiaPalette => "deuteranopia"
  | ProtanopiaPalette => "protanopia"
  | HighContrastPalette => "high-contrast"
  }
}

/// Parse a palette from a string.
let paletteFromString = (s: string): option<ProvenanceModel.accessibilityPalette> => {
  switch s {
  | "standard" => Some(StandardPalette)
  | "deuteranopia" => Some(DeuteranopiaPalette)
  | "protanopia" => Some(ProtanopiaPalette)
  | "high-contrast" => Some(HighContrastPalette)
  | _ => None
  }
}

/// Serialise an animation preference to a string.
let animationToString = (a: AccessibilityModel.animationPreference): string => {
  switch a {
  | AnimationsOn => "on"
  | AnimationsReduced => "reduced"
  | AnimationsOff => "off"
  }
}

/// Parse an animation preference from a string.
let animationFromString = (s: string): option<AccessibilityModel.animationPreference> => {
  switch s {
  | "on" => Some(AnimationsOn)
  | "reduced" => Some(AnimationsReduced)
  | "off" => Some(AnimationsOff)
  | _ => None
  }
}

/// Serialise a font size preset to a string.
let fontSizeToString = (f: AccessibilityModel.fontSizePreset): string => {
  switch f {
  | FontSmall => "small"
  | FontMedium => "medium"
  | FontLarge => "large"
  | FontExtraLarge => "extra-large"
  }
}

/// Parse a font size preset from a string.
let fontSizeFromString = (s: string): option<AccessibilityModel.fontSizePreset> => {
  switch s {
  | "small" => Some(FontSmall)
  | "medium" => Some(FontMedium)
  | "large" => Some(FontLarge)
  | "extra-large" => Some(FontExtraLarge)
  | _ => None
  }
}

/// Serialise a focus style to a string.
let focusStyleToString = (f: AccessibilityModel.focusIndicatorStyle): string => {
  switch f {
  | FocusDefault => "default"
  | FocusHighContrast => "high-contrast"
  | FocusThick => "thick"
  | FocusDotted => "dotted"
  }
}

/// Parse a focus style from a string.
let focusStyleFromString = (s: string): option<AccessibilityModel.focusIndicatorStyle> => {
  switch s {
  | "default" => Some(FocusDefault)
  | "high-contrast" => Some(FocusHighContrast)
  | "thick" => Some(FocusThick)
  | "dotted" => Some(FocusDotted)
  | _ => None
  }
}

/// Save the current accessibility state to localStorage as JSON.
/// Silently fails if localStorage is unavailable (e.g. private browsing).
let saveToLocalStorage = (state: AccessibilityModel.accessibilityState): unit => {
  try {
    let json = Dict.make()
    Dict.set(json, "theme", JSON.Encode.string(themeToString(state.theme)))
    Dict.set(json, "palette", JSON.Encode.string(paletteToString(state.palette)))
    Dict.set(json, "animations", JSON.Encode.string(animationToString(state.animations)))
    Dict.set(json, "fontSize", JSON.Encode.string(fontSizeToString(state.fontSize)))
    Dict.set(json, "focusStyle", JSON.Encode.string(focusStyleToString(state.focusStyle)))
    let _jsonStr = JSON.stringify(JSON.Encode.object(json))
    %raw(`localStorage.setItem(storageKey, _jsonStr)`)
  } catch {
  | _ => ()
  }
}

/// Helper to extract a string from a parsed JSON object dict.
let getJsonString = (obj: Dict.t<JSON.t>, key: string): option<string> => {
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | String(s) => Some(s)
    | _ => None
    }
  | None => None
  }
}

/// Tea_Json decoder for accessibility preferences from localStorage.
/// Parses string fields and maps them to variant types via existing parsers.
let accessibilityDecoder: Tea_Json.decoder<AccessibilityModel.accessibilityState> = json => {
  open Decoders
  open Tea_Json
  let inner = map5(
    (themeStr, paletteStr, animStr, fontStr, focusStr) =>
      (themeStr, paletteStr, animStr, fontStr, focusStr),
    optionalFieldDecoder("theme", string),
    optionalFieldDecoder("palette", string),
    optionalFieldDecoder("animations", string),
    optionalFieldDecoder("fontSize", string),
    optionalFieldDecoder("focusStyle", string),
  )
  switch inner(json) {
  | Ok((themeStr, paletteStr, animStr, fontStr, focusStr)) => {
      let theme = switch themeStr {
      | Some(s) => themeFromString(s)
      | None => None
      }
      let palette = switch paletteStr {
      | Some(s) => paletteFromString(s)
      | None => None
      }
      let animations = switch animStr {
      | Some(s) => animationFromString(s)
      | None => None
      }
      let fontSize = switch fontStr {
      | Some(s) => fontSizeFromString(s)
      | None => None
      }
      let focusStyle = switch focusStr {
      | Some(s) => focusStyleFromString(s)
      | None => None
      }
      let osScheme = detectOsColorScheme()
      let resolvedTheme = switch theme {
      | Some(ThemeSystem) => osScheme
      | Some(t) => t
      | None => ThemeDark
      }
      Ok({
        palette: switch palette {
        | Some(p) => p
        | None => StandardPalette
        },
        theme: switch theme {
        | Some(t) => t
        | None => ThemeDark
        },
        animations: switch animations {
        | Some(a) => a
        | None => AnimationsOn
        },
        fontSize: switch fontSize {
        | Some(f) => f
        | None => FontMedium
        },
        focusStyle: switch focusStyle {
        | Some(f) => f
        | None => FocusDefault
        },
        toolbarExpanded: false,
        resolvedTheme,
      }: AccessibilityModel.accessibilityState)
    }
  | Error(e) => Error(e)
  }
}

/// Load accessibility preferences from localStorage.
/// Returns None if nothing is stored or parsing fails.
let loadFromLocalStorage = (): option<AccessibilityModel.accessibilityState> => {
  try {
    let raw: Nullable.t<string> = %raw(`localStorage.getItem(storageKey)`)
    switch Nullable.toOption(raw) {
    | None => None
    | Some(jsonStr) => Decoders.decodeOption(accessibilityDecoder, jsonStr)
    }
  } catch {
  | _ => None
  }
}

// ============================================================================
// Default state (reads OS prefs + localStorage)
// ============================================================================

/// Build the initial accessibility state by layering:
///   1. Hardcoded defaults
///   2. OS preferences (reduced-motion, colour-scheme)
///   3. localStorage overrides (user's previous choices)
///
/// This is called once at startup.
let defaultState: AccessibilityModel.accessibilityState = {
  let osScheme = detectOsColorScheme()
  let osReduced = detectOsReducedMotion()
  let base: AccessibilityModel.accessibilityState = {
    palette: StandardPalette,
    theme: ThemeDark,
    animations: osReduced ? AnimationsReduced : AnimationsOn,
    fontSize: FontMedium,
    focusStyle: FocusDefault,
    toolbarExpanded: false,
    resolvedTheme: osScheme,
  }
  switch loadFromLocalStorage() {
  | Some(saved) => saved
  | None => base
  }
}

// ============================================================================
// TEA command for saving (wraps side effect in a Cmd)
// ============================================================================

/// Create a TEA command that persists the current accessibility state to
/// localStorage. Fire-and-forget — no result message needed.
let saveCmd = (state: AccessibilityModel.accessibilityState): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call((_callbacks) => {
    saveToLocalStorage(state)
  })
}

// ============================================================================
// TEA command for listening to OS colour scheme changes
// ============================================================================

/// Create a TEA command that registers a matchMedia listener for
/// prefers-color-scheme changes. When the OS scheme changes and the user
/// is in System theme mode, dispatches a message to update resolvedTheme.
///
/// The tagger receives a bool: true = OS prefers light, false = OS prefers dark.
let listenColorSchemeChange = (
  _tagger: bool => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(_callbacks => {
    try {
      let _: unit = %raw(`
        window.matchMedia("(prefers-color-scheme: light)").addEventListener("change", (e) => {
          callbacks.enqueue(tagger(e.matches))
        })
      `)
    } catch {
    | _ => ()
    }
  })
}
