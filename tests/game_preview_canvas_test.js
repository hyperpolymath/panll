// SPDX-License-Identifier: MPL-2.0

/**
 * GamePreviewEngine Canvas Tests — pixiBootstrapScript, iframeSrcDoc,
 * renderStatsLabel, defaultRenderStats, overlay helpers, execution labels.
 */

import { assertEquals, assert, assertExists } from "jsr:@std/assert";
import {
  pixiBootstrapScript,
  iframeSrcDoc,
  renderStatsLabel,
  defaultRenderStats,
  categoryLabel,
  overlayLabel,
  allOverlays,
  isOverlayActive,
  toggleOverlay,
  executionLabel,
  defaultState,
} from "../src/core/GamePreviewEngine.res.js";

// -- pixiBootstrapScript --

Deno.test("pixiBootstrapScript contains PIXI.Application", () => {
  const script = pixiBootstrapScript("http://localhost:8080");
  assert(script.includes("PIXI.Application"));
});

Deno.test("pixiBootstrapScript embeds dev server URL for WebSocket", () => {
  const url = "http://localhost:9999";
  const script = pixiBootstrapScript(url);
  assert(script.includes(url + "/ws"));
});

Deno.test("pixiBootstrapScript references game-root element", () => {
  const script = pixiBootstrapScript("http://localhost:8080");
  assert(script.includes("game-root"));
});

// -- iframeSrcDoc --

Deno.test("iframeSrcDoc returns valid HTML document", () => {
  const doc = iframeSrcDoc("http://localhost:8080");
  assert(doc.startsWith("<!DOCTYPE html>"));
  assert(doc.includes("<html>"));
  assert(doc.includes("</html>"));
});

Deno.test("iframeSrcDoc includes Pixi.js CDN script tag", () => {
  const doc = iframeSrcDoc("http://localhost:8080");
  assert(doc.includes("pixi.js"));
  assert(doc.includes("cdn.jsdelivr.net"));
});

Deno.test("iframeSrcDoc embeds bootstrap script", () => {
  const url = "http://localhost:3000";
  const doc = iframeSrcDoc(url);
  assert(doc.includes("PIXI.Application"));
  assert(doc.includes(url));
});

// -- renderStatsLabel --

Deno.test("renderStatsLabel formats stats into readable string", () => {
  const stats = { fps: 59.9, drawCalls: 12, spriteCount: 42, textureMemory: 1024 };
  const label = renderStatsLabel(stats);
  assert(label.includes("59.9"));
  assert(label.includes("FPS"));
  assert(label.includes("12"));
  assert(label.includes("draws"));
  assert(label.includes("42"));
  assert(label.includes("sprites"));
});

Deno.test("renderStatsLabel handles zero stats", () => {
  const stats = { fps: 0.0, drawCalls: 0, spriteCount: 0, textureMemory: 0 };
  const label = renderStatsLabel(stats);
  assert(label.includes("0.0"));
  assert(label.includes("FPS"));
});

// -- defaultRenderStats --

Deno.test("defaultRenderStats has expected default values", () => {
  assertEquals(defaultRenderStats.fps, 60.0);
  assertEquals(defaultRenderStats.drawCalls, 0);
  assertEquals(defaultRenderStats.textureMemory, 0);
  assertEquals(defaultRenderStats.spriteCount, 0);
});

Deno.test("defaultRenderStats can be passed to renderStatsLabel", () => {
  const label = renderStatsLabel(defaultRenderStats);
  assert(label.includes("60.0"));
  assert(label.includes("FPS"));
});

// -- Overlay helpers --

Deno.test("allOverlays contains 6 overlay types", () => {
  assertEquals(allOverlays.length, 6);
  assert(allOverlays.includes("OverlayCollision"));
  assert(allOverlays.includes("OverlayRenderStats"));
});

Deno.test("isOverlayActive returns true when overlay present", () => {
  assertEquals(isOverlayActive(["OverlayCollision"], "OverlayCollision"), true);
  assertEquals(isOverlayActive(["OverlayCollision"], "OverlayRenderStats"), false);
  assertEquals(isOverlayActive([], "OverlayCollision"), false);
});

Deno.test("toggleOverlay adds overlay when not present", () => {
  const result = toggleOverlay([], "OverlayCollision");
  assertEquals(result.length, 1);
  assert(result.includes("OverlayCollision"));
});

Deno.test("toggleOverlay removes overlay when present", () => {
  const result = toggleOverlay(["OverlayCollision", "OverlayRenderStats"], "OverlayCollision");
  assertEquals(result.length, 1);
  assert(!result.includes("OverlayCollision"));
  assert(result.includes("OverlayRenderStats"));
});

// -- Execution and category labels --

Deno.test("executionLabel maps all states", () => {
  assertEquals(executionLabel("GameRunning"), "Running");
  assertEquals(executionLabel("GamePaused"), "Paused");
  assertEquals(executionLabel("GameStepping"), "Stepping");
});

Deno.test("categoryLabel maps all preview categories", () => {
  assertEquals(categoryLabel("PreviewLive"), "Live Preview");
  assertEquals(categoryLabel("PreviewDeviceLog"), "Device Log");
  assertEquals(categoryLabel("PreviewClips"), "Clips");
  assertEquals(categoryLabel("PreviewPerformance"), "Performance");
});
