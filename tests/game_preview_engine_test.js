// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * GamePreviewEngine Tests — category labels, overlay labels, overlay
 * toggling, execution labels, and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  categoryLabel,
  overlayLabel,
  allOverlays,
  isOverlayActive,
  toggleOverlay,
  executionLabel,
  defaultState,
} from "../src/core/GamePreviewEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("PreviewLive"), "Live Preview");
  assertEquals(categoryLabel("PreviewDeviceLog"), "Device Log");
  assertEquals(categoryLabel("PreviewClips"), "Clips");
  assertEquals(categoryLabel("PreviewPerformance"), "Performance");
});

// -- overlayLabel --

Deno.test("overlayLabel returns correct strings for all overlays", () => {
  assertEquals(overlayLabel("OverlayCollision"), "Collision Boxes");
  assertEquals(overlayLabel("OverlayNetworkTopology"), "Network Topology");
  assertEquals(overlayLabel("OverlayGuardPatrols"), "Guard Patrols");
  assertEquals(overlayLabel("OverlayDeviceZones"), "Device Zones");
  assertEquals(overlayLabel("OverlaySpawnPoints"), "Spawn Points");
  assertEquals(overlayLabel("OverlayRenderStats"), "Render Stats");
});

// -- allOverlays --

Deno.test("allOverlays has 6 entries", () => {
  assertEquals(allOverlays.length, 6);
});

Deno.test("allOverlays contains every overlay variant", () => {
  const expected = [
    "OverlayCollision",
    "OverlayNetworkTopology",
    "OverlayGuardPatrols",
    "OverlayDeviceZones",
    "OverlaySpawnPoints",
    "OverlayRenderStats",
  ];
  assertEquals(allOverlays, expected);
});

Deno.test("allOverlays entries all have valid labels", () => {
  for (const overlay of allOverlays) {
    const label = overlayLabel(overlay);
    assert(typeof label === "string" && label.length > 0, `Missing label for ${overlay}`);
  }
});

// -- isOverlayActive --

Deno.test("isOverlayActive returns true when overlay is present", () => {
  assertEquals(isOverlayActive(["OverlayCollision", "OverlayDeviceZones"], "OverlayCollision"), true);
});

Deno.test("isOverlayActive returns false when overlay is absent", () => {
  assertEquals(isOverlayActive(["OverlayCollision"], "OverlayDeviceZones"), false);
});

Deno.test("isOverlayActive returns false for empty array", () => {
  assertEquals(isOverlayActive([], "OverlayCollision"), false);
});

// -- toggleOverlay --

Deno.test("toggleOverlay adds overlay when not present", () => {
  const result = toggleOverlay([], "OverlayCollision");
  assertEquals(result.length, 1);
  assertEquals(result[0], "OverlayCollision");
});

Deno.test("toggleOverlay removes overlay when already present", () => {
  const result = toggleOverlay(["OverlayCollision", "OverlayDeviceZones"], "OverlayCollision");
  assertEquals(result.length, 1);
  assertEquals(result[0], "OverlayDeviceZones");
});

Deno.test("toggleOverlay appends to existing overlays", () => {
  const result = toggleOverlay(["OverlayCollision"], "OverlayRenderStats");
  assertEquals(result.length, 2);
  assertEquals(result[0], "OverlayCollision");
  assertEquals(result[1], "OverlayRenderStats");
});

Deno.test("toggleOverlay double-toggle restores original", () => {
  const original = ["OverlayCollision"];
  const toggled = toggleOverlay(original, "OverlayDeviceZones");
  const restored = toggleOverlay(toggled, "OverlayDeviceZones");
  assertEquals(restored.length, 1);
  assertEquals(restored[0], "OverlayCollision");
});

// -- executionLabel --

Deno.test("executionLabel returns correct strings", () => {
  assertEquals(executionLabel("GameRunning"), "Running");
  assertEquals(executionLabel("GamePaused"), "Paused");
  assertEquals(executionLabel("GameStepping"), "Stepping");
});

// -- defaultState --

Deno.test("defaultState devServerConnected is false", () => {
  assertEquals(defaultState.devServerConnected, false);
});

Deno.test("defaultState devServerUrl is localhost:8080", () => {
  assertEquals(defaultState.devServerUrl, "http://localhost:8080");
});

Deno.test("defaultState execution is GameRunning", () => {
  assertEquals(defaultState.execution, "GameRunning");
});

Deno.test("defaultState activeCategory is PreviewLive", () => {
  assertEquals(defaultState.activeCategory, "PreviewLive");
});

Deno.test("defaultState has empty activeOverlays", () => {
  assertEquals(defaultState.activeOverlays.length, 0);
});

Deno.test("defaultState gameRecording is GameRecordingIdle", () => {
  assertEquals(defaultState.gameRecording, "GameRecordingIdle");
});

Deno.test("defaultState has empty clips", () => {
  assertEquals(defaultState.clips.length, 0);
});

Deno.test("defaultState has empty deviceLog", () => {
  assertEquals(defaultState.deviceLog.length, 0);
});

Deno.test("defaultState stats is undefined (None)", () => {
  assertEquals(defaultState.stats, undefined);
});

Deno.test("defaultState zoomLevel is 1.0", () => {
  assertEquals(defaultState.zoomLevel, 1.0);
});

Deno.test("defaultState multiplayerView is false", () => {
  assertEquals(defaultState.multiplayerView, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});
