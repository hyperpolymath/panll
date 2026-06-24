// SPDX-License-Identifier: MPL-2.0

/**
 * AmbientOpsEngine tests — hospital-model sysadmin helpers.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as AO from "../src/core/AmbientOpsEngine.res.js";

Deno.test("defaultState has TabDashboard", () => {
  assertEquals(AO.defaultState.activeTab, "TabDashboard");
});

Deno.test("defaultState has empty findings", () => {
  assertEquals(AO.defaultState.findings.length, 0);
});

Deno.test("defaultState scanning is false", () => {
  assertEquals(AO.defaultState.scanning, false);
});

Deno.test("allTabs has 5 entries", () => {
  assertEquals(AO.allTabs.length, 5);
});

Deno.test("tabLabel covers all tabs", () => {
  for (const tab of AO.allTabs) {
    assert(AO.tabLabel(tab).length > 0);
  }
});

Deno.test("departmentLabel covers Clinician", () => {
  assertEquals(AO.departmentLabel("Clinician"), "Clinician");
});

Deno.test("departmentLabel covers NetworkAmbulance", () => {
  assert(AO.departmentLabel("NetworkAmbulance").includes("Network"));
});

Deno.test("severityLabel covers all levels", () => {
  assertEquals(AO.severityLabel("Info"), "Info");
  assertEquals(AO.severityLabel("Warning"), "Warning");
  assertEquals(AO.severityLabel("Error"), "Error");
  assertEquals(AO.severityLabel("Critical"), "Critical");
});

Deno.test("countBySeverity returns 0 for empty", () => {
  assertEquals(AO.countBySeverity([], "Info"), 0);
});

Deno.test("countBySeverity counts correctly", () => {
  const findings = [
    { id: "1", severity: "Info", department: "Clinician", message: "a", timestamp: "now", resolved: false },
    { id: "2", severity: "Error", department: "Clinician", message: "b", timestamp: "now", resolved: false },
    { id: "3", severity: "Info", department: "Clinician", message: "c", timestamp: "now", resolved: false },
  ];
  assertEquals(AO.countBySeverity(findings, "Info"), 2);
  assertEquals(AO.countBySeverity(findings, "Error"), 1);
});

Deno.test("countByDepartment counts correctly", () => {
  const findings = [
    { id: "1", severity: "Info", department: "Clinician", message: "a", timestamp: "now", resolved: false },
    { id: "2", severity: "Info", department: "NetworkAmbulance", message: "b", timestamp: "now", resolved: false },
  ];
  assertEquals(AO.countByDepartment(findings, "Clinician"), 1);
});

Deno.test("findingsForDepartment filters correctly", () => {
  const findings = [
    { id: "1", severity: "Info", department: "Clinician", message: "a", timestamp: "now", resolved: false },
    { id: "2", severity: "Info", department: "NetworkAmbulance", message: "b", timestamp: "now", resolved: false },
  ];
  assertEquals(AO.findingsForDepartment(findings, "Clinician").length, 1);
});
