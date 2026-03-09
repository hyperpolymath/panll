// SPDX-License-Identifier: PMPL-1.0-or-later
// Tests for SeamEngine — compliance seam detection and exception register.

import { assertEquals, assert } from "jsr:@std/assert";

import {
  severityLabel,
  categoryLabel,
  severityColour,
  knownPanllSeams,
  buildRegister,
  auditRegister,
  isOverdue,
  generateA2mlRegister,
  summariseRegister,
  defaultRegister,
  checkDriftRisk,
} from "../src/core/SeamEngine.res.js";

Deno.test("SeamEngine — severityLabel maps all variants", () => {
  assertEquals(severityLabel("Critical"), "CRITICAL");
  assertEquals(severityLabel("High"), "HIGH");
  assertEquals(severityLabel("Medium"), "MEDIUM");
  assertEquals(severityLabel("Low"), "LOW");
  assertEquals(severityLabel("Info"), "INFO");
});

Deno.test("SeamEngine — categoryLabel maps all variants", () => {
  assertEquals(categoryLabel("LanguagePolicy"), "Language Policy");
  assertEquals(categoryLabel("LicensePolicy"), "License Policy");
  assertEquals(categoryLabel("AbiFfiPolicy"), "ABI/FFI Policy");
  assertEquals(categoryLabel("SecurityPolicy"), "Security Policy");
  assertEquals(categoryLabel("ToolingPolicy"), "Tooling Policy");
  assertEquals(categoryLabel("DocsPolicy"), "Documentation Policy");
  assertEquals(categoryLabel("ContainerPolicy"), "Container Policy");
  assertEquals(categoryLabel("IntegrationBoundary"), "Integration Boundary");
});

Deno.test("SeamEngine — severityColour returns CSS hex", () => {
  const colour = severityColour("Critical");
  assert(colour.startsWith("#"), "Should be a hex colour");
  assertEquals(colour, "#dc2626");
});

Deno.test("SeamEngine — knownPanllSeams is non-empty", () => {
  const seams = knownPanllSeams;
  assert(seams.length > 0, "Should have known seams");
  assert(seams.length >= 6, "Should have at least 6 known seams");
});

Deno.test("SeamEngine — all known seams are acknowledged", () => {
  const seams = knownPanllSeams;
  for (const seam of seams) {
    assert(seam.acknowledged, `Seam ${seam.id} should be acknowledged`);
  }
});

Deno.test("SeamEngine — no known seams have drift detected", () => {
  const seams = knownPanllSeams;
  for (const seam of seams) {
    assert(!seam.driftDetected, `Seam ${seam.id} should not have drift`);
  }
});

Deno.test("SeamEngine — buildRegister creates register with known seams", () => {
  const register = buildRegister("2026-03-09");
  assertEquals(register.lastAuditDate, "2026-03-09");
  assert(register.complianceSeamsCheckEnabled);
  assert(register.exceptionRegisterRequired);
  assert(register.seams.length >= 6);
});

Deno.test("SeamEngine — auditRegister with clean state", () => {
  const register = buildRegister("2026-03-09");
  const audit = auditRegister(register, "2026-03-09");
  assertEquals(audit.driftCount, 0);
  assertEquals(audit.unacknowledgedCount, 0);
  assertEquals(audit.totalSeams, register.seams.length);
  assert(audit.summary.includes("no drift detected"), `Summary should report clean: ${audit.summary}`);
});

Deno.test("SeamEngine — auditRegister detects overdue seams", () => {
  const register = buildRegister("2026-03-09");
  // Check with a future date past all review dates
  const audit = auditRegister(register, "2027-01-01");
  assert(audit.overdueCount > 0, "Should detect overdue seams with future date");
});

Deno.test("SeamEngine — isOverdue works correctly", () => {
  const seam = knownPanllSeams[0];
  assert(!isOverdue(seam, "2026-03-09"), "Should not be overdue on audit date");
  assert(isOverdue(seam, "2027-01-01"), "Should be overdue well past review date");
});

Deno.test("SeamEngine — generateA2mlRegister produces valid A2ML", () => {
  const register = buildRegister("2026-03-09");
  const a2ml = generateA2mlRegister(register);
  assert(a2ml.includes("SPDX-License-Identifier: PMPL-1.0-or-later"));
  assert(a2ml.includes("compliance-seams-check = true"));
  assert(a2ml.includes("[seam.SEAM-001]"));
  assert(a2ml.includes("acknowledged = true"));
});

Deno.test("SeamEngine — summariseRegister produces summary string", () => {
  const register = buildRegister("2026-03-09");
  const summary = summariseRegister(register, "2026-03-09");
  assert(summary.includes("Seam Register:"));
  assert(summary.includes("Drift:"));
  assert(summary.includes("Unacknowledged:"));
});

Deno.test("SeamEngine — defaultRegister is empty", () => {
  const reg = defaultRegister;
  assertEquals(reg.seams.length, 0);
  assertEquals(reg.lastAuditDate, "");
});

Deno.test("SeamEngine — each seam has required fields", () => {
  for (const seam of knownPanllSeams) {
    assert(seam.id.startsWith("SEAM-"), `ID should start with SEAM-: ${seam.id}`);
    assert(seam.title.length > 0, "Title should be non-empty");
    assert(seam.rationale.length > 0, "Rationale should be non-empty");
    assert(seam.scope.length > 0, "Scope should be non-empty");
    assert(seam.identifiedDate.length > 0, "Identified date should be non-empty");
    assert(seam.reviewDate.length > 0, "Review date should be non-empty");
  }
});

Deno.test("SeamEngine — SEAM-001 is npm/ReScript seam", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-001");
  assert(seam !== undefined);
  assert(seam.title.includes("npm"));
  assert(seam.category === "ToolingPolicy");
  assert(seam.severity === "Medium");
});

Deno.test("SeamEngine — checkDriftRisk returns false for clean indicators", () => {
  const seam = knownPanllSeams[0];
  const result = checkDriftRisk(seam, ["src/core/foo.res", "tests/bar.js"]);
  assert(!result, "Should not detect drift for clean indicators");
});
