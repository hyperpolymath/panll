// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * DeviceNetworkDesignerEngine Tests — default state, tab labels, device/connection
 * counting, and validation summary formatting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countDevicesByType,
  countConnections,
  validationSummary,
} from "../src/core/DeviceNetworkDesignerEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.devices.length, 0);
  assertEquals(defaultState.connections.length, 0);
  assertEquals(defaultState.wiringMode, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Designer"), "Designer");
  assertEquals(tabLabel("Devices"), "Devices");
  assertEquals(tabLabel("Wiring"), "Wiring");
  assertEquals(tabLabel("Validation"), "Validation");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- countDevicesByType with empty array --

Deno.test("countDevicesByType returns 0 for empty array", () => {
  assertEquals(countDevicesByType([], "sensor"), 0);
});

// -- countConnections with empty array --

Deno.test("countConnections returns 0 for empty array", () => {
  assertEquals(countConnections([]), 0);
});

// -- validationSummary with None --

Deno.test("validationSummary returns 'No validation run' for undefined", () => {
  assertEquals(validationSummary(undefined), "No validation run");
});
