// SPDX-License-Identifier: MPL-2.0

/**
 * StapelnEngine tests — container assembly pipeline helpers.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as S from "../src/core/StapelnEngine.res.js";

Deno.test("defaultState has secure defaults", () => {
  assertEquals(S.defaultState.connected, false);
  assertEquals(S.defaultState.constraints.requireHealthcheck, true);
  assertEquals(S.defaultState.constraints.requireNonRoot, true);
});

Deno.test("defaultConstraints blocks docker.io", () => {
  const dockerRule = S.defaultConstraints.registryConstraints.find(r => r.registry === "docker.io");
  assert(dockerRule !== undefined);
  assertEquals(dockerRule.allowed, false);
});

Deno.test("defaultConstraints allows chainguard", () => {
  const cgRule = S.defaultConstraints.registryConstraints.find(r => r.registry.includes("chainguard"));
  assert(cgRule !== undefined);
  assertEquals(cgRule.allowed, true);
});

Deno.test("defaultConstraints denies ubuntu:latest", () => {
  assert(S.defaultConstraints.deniedImages.includes("ubuntu:latest"));
});

Deno.test("slsaLabel covers all levels", () => {
  for (const level of S.allSlsaLevels) {
    assert(S.slsaLabel(level).length > 0);
  }
});

Deno.test("signaturePolicyLabel returns non-empty", () => {
  assert(S.signaturePolicyLabel("CerroTorre").length > 0);
  assert(S.signaturePolicyLabel("Cosign").length > 0);
});

Deno.test("sbomFormatLabel covers formats", () => {
  assert(S.sbomFormatLabel("Spdx").includes("SPDX"));
  assert(S.sbomFormatLabel("CycloneDx").includes("CycloneDX"));
});

Deno.test("artifactFormatLabel covers all formats", () => {
  for (const fmt of S.allFormats) {
    assert(S.artifactFormatLabel(fmt).length > 0);
  }
});

Deno.test("healthLabel covers all states", () => {
  assert(S.healthLabel("PipelineHealthy") === "Healthy");
  assert(S.healthLabel("PipelineFailing") === "Failing");
});

Deno.test("healthColour returns tailwind classes", () => {
  assert(S.healthColour("PipelineHealthy").includes("emerald"));
  assert(S.healthColour("PipelineFailing").includes("red"));
});

Deno.test("findingLevelColour returns colour for error", () => {
  assert(S.findingLevelColour("error").includes("red"));
  assert(S.findingLevelColour("warning").includes("amber"));
});

Deno.test("countFindings counts by level", () => {
  const findings = [
    { level: "error", message: "a", rule: "r1" },
    { level: "warning", message: "b", rule: "r2" },
    { level: "error", message: "c", rule: "r3" },
  ];
  assertEquals(S.countFindings(findings, "error"), 2);
  assertEquals(S.countFindings(findings, "warning"), 1);
});

Deno.test("allFormats has 4 entries", () => {
  assertEquals(S.allFormats.length, 4);
});

Deno.test("allSlsaLevels has 5 entries", () => {
  assertEquals(S.allSlsaLevels.length, 5);
});
