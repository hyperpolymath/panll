// SPDX-License-Identifier: MPL-2.0
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
  assert(seams.length >= 13, "Should have at least 13 known seams (6 original + 7 UMS)");
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
  const register = buildRegister("2026-03-14");
  assertEquals(register.lastAuditDate, "2026-03-14");
  assert(register.complianceSeamsCheckEnabled);
  assert(register.exceptionRegisterRequired);
  assert(register.seams.length >= 13);
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
  assert(a2ml.includes("SPDX-License-Identifier: MPL-2.0"));
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

// ============================================================================
// UMS compliance seam tests (SEAM-007 through SEAM-013)
// ============================================================================

Deno.test("SeamEngine — UMS seams exist in register (SEAM-007 to SEAM-013)", () => {
  const umsSeamIds = [
    "SEAM-007", "SEAM-008", "SEAM-009", "SEAM-010",
    "SEAM-011", "SEAM-012", "SEAM-013",
  ];
  for (const id of umsSeamIds) {
    const found = knownPanllSeams.find(s => s.id === id);
    assert(found !== undefined, `${id} should exist in knownPanllSeams`);
  }
});

Deno.test("SeamEngine — SEAM-007 UMS Rust backend commands", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-007");
  assert(seam !== undefined);
  assertEquals(seam.category, "IntegrationBoundary");
  assertEquals(seam.severity, "High");
  assert(seam.title.includes("UMS"), "Title should reference UMS");
  assert(seam.title.includes("Rust backend"), "Title should reference Rust backend");
  assert(seam.policyExpectation.includes("ums_"), "Policy should reference ums_* commands");
  assert(seam.acknowledged, "Should be acknowledged");
  assert(!seam.driftDetected, "Should not have drift");
});

Deno.test("SeamEngine — SEAM-008 UMS clade definition", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-008");
  assert(seam !== undefined);
  assertEquals(seam.category, "IntegrationBoundary");
  assertEquals(seam.severity, "High");
  assert(seam.title.includes("clade"), "Title should reference clade");
  assert(seam.policyExpectation.includes("ums"), "Policy should reference ums clade");
  assert(seam.acknowledged, "Should be acknowledged");
});

Deno.test("SeamEngine — SEAM-009 UMS TypeLL ABI checks", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-009");
  assert(seam !== undefined);
  assertEquals(seam.category, "AbiFfiPolicy");
  assertEquals(seam.severity, "Medium");
  assert(seam.title.includes("TypeLL"), "Title should reference TypeLL");
  assert(seam.title.includes("ABI"), "Title should reference ABI");
  assert(seam.rationale.includes("deviceKind"), "Rationale should mention shared UMS types");
  assert(seam.acknowledged, "Should be acknowledged");
});

Deno.test("SeamEngine — SEAM-010 UMS BoJ routing capability", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-010");
  assert(seam !== undefined);
  assertEquals(seam.category, "IntegrationBoundary");
  assertEquals(seam.severity, "Medium");
  assert(seam.title.includes("BoJ"), "Title should reference BoJ");
  assert(seam.policyExpectation.includes("routing"), "Policy should reference routing");
  assert(seam.acknowledged, "Should be acknowledged");
});

Deno.test("SeamEngine — SEAM-011 UMS cartridge Idris2 proofs", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-011");
  assert(seam !== undefined);
  assertEquals(seam.category, "AbiFfiPolicy");
  assertEquals(seam.severity, "High");
  assert(seam.title.includes("5 Idris2 proofs"), "Title should reference 5 Idris2 proofs");
  assert(
    seam.policyExpectation.includes("memory safety"),
    "Policy should enumerate proof obligations"
  );
  assert(seam.acknowledged, "Should be acknowledged");
});

Deno.test("SeamEngine — SEAM-012 Level Architect shares UMS types", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-012");
  assert(seam !== undefined);
  assertEquals(seam.category, "IntegrationBoundary");
  assertEquals(seam.severity, "Medium");
  assert(seam.title.includes("Level Architect"), "Title should reference Level Architect");
  assert(seam.title.includes("deviceKind"), "Title should reference shared types");
  assert(seam.title.includes("guardRank"), "Title should reference guardRank");
  assert(seam.acknowledged, "Should be acknowledged");
});

Deno.test("SeamEngine — SEAM-013 PanelBus UMS event subscribers", () => {
  const seam = knownPanllSeams.find(s => s.id === "SEAM-013");
  assert(seam !== undefined);
  assertEquals(seam.category, "IntegrationBoundary");
  assertEquals(seam.severity, "Medium");
  assert(seam.title.includes("PanelBus"), "Title should reference PanelBus");
  assert(seam.title.includes("UMS event"), "Title should reference UMS events");
  assert(
    seam.rationale.includes("device registered"),
    "Rationale should describe UMS event examples"
  );
  assert(seam.acknowledged, "Should be acknowledged");
});

Deno.test("SeamEngine — all UMS seams have 2026-03-14 identified date", () => {
  const umsSeams = knownPanllSeams.filter(s => {
    const num = parseInt(s.id.replace("SEAM-", ""), 10);
    return num >= 7 && num <= 13;
  });
  assertEquals(umsSeams.length, 7, "Should have exactly 7 UMS seams");
  for (const seam of umsSeams) {
    assertEquals(
      seam.identifiedDate,
      "2026-03-14",
      `${seam.id} should have identifiedDate 2026-03-14`
    );
  }
});

Deno.test("SeamEngine — UMS seams cover all required categories", () => {
  const umsSeams = knownPanllSeams.filter(s => {
    const num = parseInt(s.id.replace("SEAM-", ""), 10);
    return num >= 7 && num <= 13;
  });
  const categories = umsSeams.map(s => s.category);
  assert(
    categories.includes("IntegrationBoundary"),
    "UMS seams should include IntegrationBoundary"
  );
  assert(categories.includes("AbiFfiPolicy"), "UMS seams should include AbiFfiPolicy");
});

Deno.test("SeamEngine — audit register includes UMS seams in totals", () => {
  const register = buildRegister("2026-03-14");
  const audit = auditRegister(register, "2026-03-14");
  assert(audit.totalSeams >= 13, "Audit should count all seams including UMS");
  assertEquals(audit.driftCount, 0, "No UMS seams should have drift");
  assertEquals(audit.unacknowledgedCount, 0, "All UMS seams should be acknowledged");
});
