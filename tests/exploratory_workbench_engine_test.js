// SPDX-License-Identifier: MPL-2.0

/**
 * ExploratoryWorkbenchEngine Tests — default state, tab labels, severity labels
 * and colours, anomaly counting, and total anomalies.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  severityLabel,
  severityColor,
  anomalyCountBySeverity,
  totalAnomalies,
} from "../src/core/ExploratoryWorkbenchEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.sessions.length, 0);
  assertEquals(defaultState.anomalies.length, 0);
  assertEquals(defaultState.recording, false);
  assertEquals(defaultState.anomalyDetectionEnabled, true);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabSession"), "Session");
  assertEquals(tabLabel("TabAnomalies"), "Anomalies");
  assertEquals(tabLabel("TabNotes"), "Notes");
  assertEquals(tabLabel("TabHistory"), "History");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- severityLabel --

Deno.test("severityLabel returns correct labels", () => {
  assertEquals(severityLabel("AnomalyLow"), "Low");
  assertEquals(severityLabel("AnomalyMedium"), "Medium");
  assertEquals(severityLabel("AnomalyHigh"), "High");
  assertEquals(severityLabel("AnomalyCritical"), "Critical");
});

// -- severityColor --

Deno.test("severityColor returns correct Tailwind classes", () => {
  assertEquals(severityColor("AnomalyLow"), "text-blue-400");
  assertEquals(severityColor("AnomalyCritical"), "text-red-400");
});

// -- anomalyCountBySeverity with empty array --

Deno.test("anomalyCountBySeverity returns 0 for empty array", () => {
  assertEquals(anomalyCountBySeverity([], "AnomalyHigh"), 0);
});

// -- totalAnomalies with empty array --

Deno.test("totalAnomalies returns 0 for empty sessions", () => {
  assertEquals(totalAnomalies([]), 0);
});
