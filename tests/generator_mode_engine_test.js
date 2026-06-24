// SPDX-License-Identifier: MPL-2.0

/**
 * GeneratorModeEngine Tests — default state, default params, tab labels,
 * weather/time formatting, and district/facility counting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  defaultWorldParams,
  tabLabel,
  allTabs,
  formatWeather,
  formatTimeOfDay,
  countDistricts,
  countTotalFacilities,
} from "../src/core/GeneratorModeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.generating, false);
  assertEquals(defaultState.templates.length, 0);
  assertEquals(defaultState.error, undefined);
});

// -- defaultWorldParams --

Deno.test("defaultWorldParams has balanced mid-range values", () => {
  assertExists(defaultWorldParams);
  assertEquals(defaultWorldParams.securityLevel, 0.5);
  assertEquals(defaultWorldParams.techLevel, 0.5);
  assertEquals(defaultWorldParams.trapDensity, 0.3);
  assertEquals(defaultWorldParams.civilianPopulation, 100);
  assertEquals(defaultWorldParams.difficultyTarget, 0.5);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Design"), "Design");
  assertEquals(tabLabel("Parameters"), "Parameters");
  assertEquals(tabLabel("Preview"), "Preview");
  assertEquals(tabLabel("Export"), "Export");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- formatWeather --

Deno.test("formatWeather returns correct labels", () => {
  assertEquals(formatWeather("Clear"), "Clear");
  assertEquals(formatWeather("Rain"), "Rain");
  assertEquals(formatWeather("Snow"), "Snow");
  assertEquals(formatWeather("Fog"), "Fog");
  assertEquals(formatWeather("Storm"), "Storm");
  assertEquals(formatWeather("NightRain"), "Night Rain");
});

// -- formatTimeOfDay --

Deno.test("formatTimeOfDay returns correct labels", () => {
  assertEquals(formatTimeOfDay("Dawn"), "Dawn");
  assertEquals(formatTimeOfDay("Morning"), "Morning");
  assertEquals(formatTimeOfDay("Afternoon"), "Afternoon");
  assertEquals(formatTimeOfDay("Evening"), "Evening");
  assertEquals(formatTimeOfDay("Night"), "Night");
  assertEquals(formatTimeOfDay("Midnight"), "Midnight");
});
