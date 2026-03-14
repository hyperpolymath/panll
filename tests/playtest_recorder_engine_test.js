// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * PlaytestRecorderEngine Tests — default state, tab labels, duration formatting,
 * annotation counting, and playback progress computation.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  formatDuration,
  countAnnotations,
  playbackProgressPercent,
} from "../src/core/PlaytestRecorderEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.sessions.length, 0);
  assertEquals(defaultState.annotations.length, 0);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Record"), "Record");
  assertEquals(tabLabel("Replay"), "Replay");
  assertEquals(tabLabel("Annotations"), "Annotations");
  assertEquals(tabLabel("Sessions"), "Sessions");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- formatDuration --

Deno.test("formatDuration formats minutes and seconds", () => {
  assertEquals(formatDuration(90000), "1m 30s");
});

Deno.test("formatDuration formats zero duration", () => {
  assertEquals(formatDuration(0), "0m 0s");
});

// -- countAnnotations with empty array --

Deno.test("countAnnotations returns 0 for empty array", () => {
  assertEquals(countAnnotations([]), 0);
});

// -- playbackProgressPercent with stopped playback --

Deno.test("playbackProgressPercent returns 0 for stopped playback", () => {
  assertEquals(playbackProgressPercent("Stopped", undefined), 0.0);
});
