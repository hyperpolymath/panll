// SPDX-License-Identifier: MPL-2.0

/**
 * CaptureEngine Tests — recording, captures, demos, comparison, clones
 */

import { assertEquals } from "jsr:@std/assert";
import {
  addCapture,
  removeCapture,
  startRecording,
  stopRecording,
  toggleCaptureSelection,
  clearSelection,
  startDemo,
  stopDemo,
  nextDemoStep,
  prevDemoStep,
  defaultState,
} from "../src/core/CaptureEngine.res.js";

// -- addCapture / removeCapture --

Deno.test("addCapture adds an entry", () => {
  const entry = { id: "c1", panelId: "Farm", timestamp: 1000 };
  const result = addCapture(defaultState, entry);
  assertEquals(result.captures.length, 1);
  assertEquals(result.captures[0].id, "c1");
});

Deno.test("removeCapture removes by id", () => {
  const entry = { id: "c1", panelId: "Farm", timestamp: 1000 };
  const withCapture = addCapture(defaultState, entry);
  const result = removeCapture(withCapture, "c1");
  assertEquals(result.captures.length, 0);
});

// -- startRecording / stopRecording --

Deno.test("startRecording sets recording state", () => {
  const result = startRecording(defaultState, "Farm", 5000);
  assertEquals(result.recording.TAG, "Recording");
  assertEquals(result.recording._0, "Farm");
  assertEquals(result.recording._1, 5000);
});

Deno.test("stopRecording clears recording state", () => {
  const recording = startRecording(defaultState, "Farm", 5000);
  const result = stopRecording(recording);
  assertEquals(result.recording, "NotRecording");
});

// -- toggleCaptureSelection / clearSelection --

Deno.test("toggleCaptureSelection adds panel id", () => {
  const result = toggleCaptureSelection(defaultState, "Farm");
  assertEquals(result.selectedForCapture.length, 1);
  assertEquals(result.selectedForCapture[0], "Farm");
});

Deno.test("toggleCaptureSelection removes if already selected", () => {
  const selected = toggleCaptureSelection(defaultState, "Farm");
  const result = toggleCaptureSelection(selected, "Farm");
  assertEquals(result.selectedForCapture.length, 0);
});

Deno.test("clearSelection empties selection", () => {
  const selected = toggleCaptureSelection(defaultState, "Farm");
  const result = clearSelection(selected);
  assertEquals(result.selectedForCapture.length, 0);
});

// -- startDemo / stopDemo / nextDemoStep / prevDemoStep --

Deno.test("startDemo sets activeDemo", () => {
  const result = startDemo(defaultState, "demo-1");
  assertEquals(result.activeDemo, "demo-1");
  assertEquals(result.activeDemoStep, 0);
});

Deno.test("stopDemo clears activeDemo", () => {
  const started = startDemo(defaultState, "demo-1");
  const result = stopDemo(started);
  assertEquals(result.activeDemo, undefined);
  assertEquals(result.activeDemoStep, 0);
});

Deno.test("nextDemoStep does nothing without active demo", () => {
  const result = nextDemoStep(defaultState);
  assertEquals(result.activeDemoStep, 0);
});

Deno.test("prevDemoStep does not go below 0", () => {
  const result = prevDemoStep(defaultState);
  assertEquals(result.activeDemoStep, 0);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.captures.length, 0);
  assertEquals(defaultState.recording, "NotRecording");
  assertEquals(defaultState.selectedForCapture.length, 0);
  assertEquals(defaultState.demos.length, 0);
  assertEquals(defaultState.activeDemo, undefined);
  assertEquals(defaultState.activeDemoStep, 0);
  assertEquals(defaultState.comparison, "NoComparison");
  assertEquals(defaultState.clones.length, 0);
  assertEquals(defaultState.activeCategory, "CaptureGallery");
  assertEquals(defaultState.captureBarVisible, true);
  assertEquals(defaultState.fullEnvironmentCapture, false);
});
