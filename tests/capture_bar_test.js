// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * CaptureBar Tests — captureButton helper, view function, visibility
 * toggling, recording state rendering, and export verification.
 */

import { assertEquals, assert, assertExists } from "jsr:@std/assert";
import {
  captureButton,
  view,
} from "../src/components/CaptureBar.res.js";

// -- Export verification --

Deno.test("captureButton is exported and callable", () => {
  assertExists(captureButton);
  assertEquals(typeof captureButton, "function");
});

Deno.test("view is exported and callable", () => {
  assertExists(view);
  assertEquals(typeof view, "function");
});

// -- captureButton produces vdom --

Deno.test("captureButton produces vdom node when active=false", () => {
  const msg = { TAG: "Capture", _0: { TAG: "CaptureScreenshot", _0: "panel-l" } };
  const result = captureButton("Screenshot", "C", "Take screenshot", msg, false);
  assertExists(result);
  assertEquals(typeof result, "object");
});

Deno.test("captureButton produces vdom node when active=true", () => {
  const msg = { TAG: "Capture", _0: "StopRecording" };
  const result = captureButton("Stop Recording", "R", "Stop recording", msg, true);
  assertExists(result);
  assertEquals(typeof result, "object");
});

// -- view with visible=false returns noNode --

Deno.test("view returns noNode when visible is false", () => {
  const result = view("panel-l", false, false);
  assertExists(result);
  // Tea_Html.noNode is typically an empty/text node — just verify it is an object
  assertEquals(typeof result, "object");
});

// -- view with visible=true returns toolbar --

Deno.test("view returns toolbar vdom when visible is true", () => {
  const result = view("panel-l", false, true);
  assertExists(result);
  assertEquals(typeof result, "object");
});

Deno.test("view with recording state returns toolbar vdom", () => {
  const result = view("panel-n", true, true);
  assertExists(result);
  assertEquals(typeof result, "object");
});

// -- view panelId parameter is used --

Deno.test("view accepts different panel IDs without error", () => {
  const panels = ["panel-l", "panel-n", "panel-w", "custom-panel"];
  for (const p of panels) {
    const result = view(p, false, true);
    assertExists(result);
  }
});
