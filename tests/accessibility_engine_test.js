// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * AccessibilityEngine Tests — theme labels, font sizes, animation classes,
 * focus styles, root classes, serialisation round-trips, and default state.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  themeLabel,
  themeClass,
  fontSizePx,
  fontSizeLabel,
  fontSizeClass,
  animationClass,
  animationLabel,
  focusStyleClass,
  focusStyleLabel,
  rootClasses,
  themeToString,
  themeFromString,
  paletteToString,
  paletteFromString,
  animationToString,
  animationFromString,
  fontSizeToString,
  fontSizeFromString,
  focusStyleToString,
  focusStyleFromString,
  storageKey,
  defaultState,
} from "../src/core/AccessibilityEngine.res.js";

// -- storageKey --

Deno.test("storageKey is panll-accessibility", () => {
  assertEquals(storageKey, "panll-accessibility");
});

// -- themeLabel --

Deno.test("themeLabel returns correct strings for all themes", () => {
  assertEquals(themeLabel("ThemeDark"), "Dark");
  assertEquals(themeLabel("ThemeLight"), "Light");
  assertEquals(themeLabel("ThemeSystem"), "System");
});

// -- themeClass --

Deno.test("themeClass returns theme-light for ThemeLight", () => {
  const state = { theme: "ThemeLight", resolvedTheme: "ThemeLight" };
  assertEquals(themeClass(state), "theme-light");
});

Deno.test("themeClass returns empty string for ThemeDark", () => {
  const state = { theme: "ThemeDark", resolvedTheme: "ThemeDark" };
  assertEquals(themeClass(state), "");
});

Deno.test("themeClass uses resolvedTheme when ThemeSystem", () => {
  const stateLight = { theme: "ThemeSystem", resolvedTheme: "ThemeLight" };
  assertEquals(themeClass(stateLight), "theme-light");

  const stateDark = { theme: "ThemeSystem", resolvedTheme: "ThemeDark" };
  assertEquals(themeClass(stateDark), "");
});

// -- fontSizePx --

Deno.test("fontSizePx returns correct pixel values", () => {
  assertEquals(fontSizePx("FontSmall"), 14);
  assertEquals(fontSizePx("FontMedium"), 16);
  assertEquals(fontSizePx("FontLarge"), 18);
  assertEquals(fontSizePx("FontExtraLarge"), 20);
});

// -- fontSizeLabel --

Deno.test("fontSizeLabel returns descriptive labels", () => {
  assertEquals(fontSizeLabel("FontSmall"), "Small (14px)");
  assertEquals(fontSizeLabel("FontMedium"), "Medium (16px)");
  assertEquals(fontSizeLabel("FontLarge"), "Large (18px)");
  assertEquals(fontSizeLabel("FontExtraLarge"), "Extra Large (20px)");
});

// -- fontSizeClass --

Deno.test("fontSizeClass always returns empty string", () => {
  assertEquals(fontSizeClass("FontSmall"), "");
  assertEquals(fontSizeClass("FontMedium"), "");
  assertEquals(fontSizeClass("FontLarge"), "");
  assertEquals(fontSizeClass("FontExtraLarge"), "");
});

// -- animationClass --

Deno.test("animationClass returns correct CSS classes", () => {
  assertEquals(animationClass("AnimationsOn"), "");
  assertEquals(animationClass("AnimationsReduced"), "animations-reduced");
  assertEquals(animationClass("AnimationsOff"), "animations-off");
});

// -- animationLabel --

Deno.test("animationLabel returns correct descriptive labels", () => {
  assertEquals(animationLabel("AnimationsOn"), "Animations On");
  assertEquals(animationLabel("AnimationsReduced"), "Animations Reduced");
  assertEquals(animationLabel("AnimationsOff"), "Animations Off");
});

// -- focusStyleClass --

Deno.test("focusStyleClass returns correct CSS classes", () => {
  assertEquals(focusStyleClass("FocusDefault"), "");
  assertEquals(focusStyleClass("FocusHighContrast"), "focus-high-contrast");
  assertEquals(focusStyleClass("FocusThick"), "focus-thick");
  assertEquals(focusStyleClass("FocusDotted"), "focus-dotted");
});

// -- focusStyleLabel --

Deno.test("focusStyleLabel returns correct descriptive labels", () => {
  assertEquals(focusStyleLabel("FocusDefault"), "Default (2px indigo)");
  assertEquals(focusStyleLabel("FocusHighContrast"), "High Contrast (3px black)");
  assertEquals(focusStyleLabel("FocusThick"), "Thick (4px indigo)");
  assertEquals(focusStyleLabel("FocusDotted"), "Dotted (3px dotted)");
});

// -- rootClasses --

Deno.test("rootClasses combines theme, animation, and focus classes", () => {
  const state = {
    theme: "ThemeLight",
    resolvedTheme: "ThemeLight",
    animations: "AnimationsReduced",
    focusStyle: "FocusHighContrast",
  };
  const result = rootClasses(state);
  assert(result.includes("theme-light"), "should include theme-light");
  assert(result.includes("animations-reduced"), "should include animations-reduced");
  assert(result.includes("focus-high-contrast"), "should include focus-high-contrast");
});

Deno.test("rootClasses returns empty string when all defaults", () => {
  const state = {
    theme: "ThemeDark",
    resolvedTheme: "ThemeDark",
    animations: "AnimationsOn",
    focusStyle: "FocusDefault",
  };
  assertEquals(rootClasses(state), "");
});

// -- themeToString / themeFromString round-trip --

Deno.test("themeToString returns correct strings", () => {
  assertEquals(themeToString("ThemeDark"), "dark");
  assertEquals(themeToString("ThemeLight"), "light");
  assertEquals(themeToString("ThemeSystem"), "system");
});

Deno.test("themeFromString parses known strings", () => {
  assertEquals(themeFromString("dark"), "ThemeDark");
  assertEquals(themeFromString("light"), "ThemeLight");
  assertEquals(themeFromString("system"), "ThemeSystem");
});

Deno.test("themeFromString returns undefined for unknown strings", () => {
  assertEquals(themeFromString("unknown"), undefined);
  assertEquals(themeFromString(""), undefined);
});

// -- paletteToString / paletteFromString round-trip --

Deno.test("paletteToString returns correct strings", () => {
  assertEquals(paletteToString("StandardPalette"), "standard");
  assertEquals(paletteToString("DeuteranopiaPalette"), "deuteranopia");
  assertEquals(paletteToString("ProtanopiaPalette"), "protanopia");
  assertEquals(paletteToString("HighContrastPalette"), "high-contrast");
});

Deno.test("paletteFromString parses known strings", () => {
  assertEquals(paletteFromString("standard"), "StandardPalette");
  assertEquals(paletteFromString("deuteranopia"), "DeuteranopiaPalette");
  assertEquals(paletteFromString("protanopia"), "ProtanopiaPalette");
  assertEquals(paletteFromString("high-contrast"), "HighContrastPalette");
});

Deno.test("paletteFromString returns undefined for unknown strings", () => {
  assertEquals(paletteFromString("unknown"), undefined);
  assertEquals(paletteFromString(""), undefined);
});

// -- animationToString / animationFromString round-trip --

Deno.test("animationToString returns correct strings", () => {
  assertEquals(animationToString("AnimationsOn"), "on");
  assertEquals(animationToString("AnimationsReduced"), "reduced");
  assertEquals(animationToString("AnimationsOff"), "off");
});

Deno.test("animationFromString parses known strings", () => {
  assertEquals(animationFromString("on"), "AnimationsOn");
  assertEquals(animationFromString("reduced"), "AnimationsReduced");
  assertEquals(animationFromString("off"), "AnimationsOff");
});

Deno.test("animationFromString returns undefined for unknown strings", () => {
  assertEquals(animationFromString("unknown"), undefined);
  assertEquals(animationFromString(""), undefined);
});

// -- fontSizeToString / fontSizeFromString round-trip --

Deno.test("fontSizeToString returns correct strings", () => {
  assertEquals(fontSizeToString("FontSmall"), "small");
  assertEquals(fontSizeToString("FontMedium"), "medium");
  assertEquals(fontSizeToString("FontLarge"), "large");
  assertEquals(fontSizeToString("FontExtraLarge"), "extra-large");
});

Deno.test("fontSizeFromString parses known strings", () => {
  assertEquals(fontSizeFromString("small"), "FontSmall");
  assertEquals(fontSizeFromString("medium"), "FontMedium");
  assertEquals(fontSizeFromString("large"), "FontLarge");
  assertEquals(fontSizeFromString("extra-large"), "FontExtraLarge");
});

Deno.test("fontSizeFromString returns undefined for unknown strings", () => {
  assertEquals(fontSizeFromString("unknown"), undefined);
  assertEquals(fontSizeFromString(""), undefined);
});

// -- focusStyleToString / focusStyleFromString round-trip --

Deno.test("focusStyleToString returns correct strings", () => {
  assertEquals(focusStyleToString("FocusDefault"), "default");
  assertEquals(focusStyleToString("FocusHighContrast"), "high-contrast");
  assertEquals(focusStyleToString("FocusThick"), "thick");
  assertEquals(focusStyleToString("FocusDotted"), "dotted");
});

Deno.test("focusStyleFromString parses known strings", () => {
  assertEquals(focusStyleFromString("default"), "FocusDefault");
  assertEquals(focusStyleFromString("high-contrast"), "FocusHighContrast");
  assertEquals(focusStyleFromString("thick"), "FocusThick");
  assertEquals(focusStyleFromString("dotted"), "FocusDotted");
});

Deno.test("focusStyleFromString returns undefined for unknown strings", () => {
  assertEquals(focusStyleFromString("unknown"), undefined);
  assertEquals(focusStyleFromString(""), undefined);
});

// -- defaultState --

Deno.test("defaultState has expected structure and types", () => {
  assert(typeof defaultState === "object", "defaultState should be an object");
  assert("palette" in defaultState, "should have palette field");
  assert("theme" in defaultState, "should have theme field");
  assert("animations" in defaultState, "should have animations field");
  assert("fontSize" in defaultState, "should have fontSize field");
  assert("focusStyle" in defaultState, "should have focusStyle field");
  assert("toolbarExpanded" in defaultState, "should have toolbarExpanded field");
  assert("resolvedTheme" in defaultState, "should have resolvedTheme field");
});

Deno.test("defaultState toolbarExpanded is false", () => {
  assertEquals(defaultState.toolbarExpanded, false);
});
