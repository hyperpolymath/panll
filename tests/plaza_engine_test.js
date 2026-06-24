// SPDX-License-Identifier: MPL-2.0

/**
 * PlazaEngine Tests — compliance level labels/colours/backgrounds, category
 * labels, signature status labels, common licenses, adoption stats parsing,
 * and percentage computations.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  complianceLevelLabel,
  complianceLevelColour,
  complianceLevelBg,
  categoryLabel,
  allCategories,
  signatureStatusLabel,
  commonLicenses,
  parseAdoptionStats,
  adoptionPercentage,
  licensedPercentage,
} from "../src/core/PlazaEngine.res.js";

// -- complianceLevelLabel --

Deno.test("complianceLevelLabel returns correct strings", () => {
  assertEquals(complianceLevelLabel("FullCompliance"), "Full Compliance");
  assertEquals(complianceLevelLabel("PartialCompliance"), "Partial");
  assertEquals(complianceLevelLabel("NonCompliant"), "Non-Compliant");
  assertEquals(complianceLevelLabel("Unknown"), "Not Scanned");
});

// -- complianceLevelColour --

Deno.test("complianceLevelColour returns correct Tailwind classes", () => {
  assertEquals(complianceLevelColour("FullCompliance"), "text-emerald-400");
  assertEquals(complianceLevelColour("PartialCompliance"), "text-amber-400");
  assertEquals(complianceLevelColour("NonCompliant"), "text-red-400");
  assertEquals(complianceLevelColour("Unknown"), "text-gray-500");
});

// -- complianceLevelBg --

Deno.test("complianceLevelBg returns correct background classes", () => {
  assertEquals(complianceLevelBg("FullCompliance"), "bg-emerald-900/50 border-emerald-700");
  assertEquals(complianceLevelBg("PartialCompliance"), "bg-amber-900/50 border-amber-700");
  assertEquals(complianceLevelBg("NonCompliant"), "bg-red-900/50 border-red-700");
  assertEquals(complianceLevelBg("Unknown"), "bg-gray-800/50 border-gray-700");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings for all categories", () => {
  assertEquals(categoryLabel("Dashboard"), "Dashboard");
  assertEquals(categoryLabel("Compliance"), "Compliance");
  assertEquals(categoryLabel("Provenance"), "Provenance");
  assertEquals(categoryLabel("Compatibility"), "Compatibility");
  assertEquals(categoryLabel("EthicalUse"), "Ethical Use");
  assertEquals(categoryLabel("Governance"), "Governance");
  assertEquals(categoryLabel("Adopt"), "Adopt PMPL");
});

// -- allCategories --

Deno.test("allCategories has 7 entries", () => {
  assertEquals(allCategories.length, 7);
});

Deno.test("allCategories contains every category in order", () => {
  assertEquals(allCategories, [
    "Dashboard",
    "Compliance",
    "Provenance",
    "Compatibility",
    "EthicalUse",
    "Governance",
    "Adopt",
  ]);
});

Deno.test("allCategories entries all have valid labels", () => {
  for (const cat of allCategories) {
    const label = categoryLabel(cat);
    assert(typeof label === "string" && label.length > 0, `Missing label for ${cat}`);
  }
});

// -- signatureStatusLabel --

Deno.test("signatureStatusLabel returns Valid for SignatureValid", () => {
  assertEquals(signatureStatusLabel("SignatureValid"), "Valid");
});

Deno.test("signatureStatusLabel returns None for NoSignature", () => {
  assertEquals(signatureStatusLabel("NoSignature"), "None");
});

Deno.test("signatureStatusLabel returns upgrade message for ClassicalOnly", () => {
  assertEquals(signatureStatusLabel("ClassicalOnly"), "Classical (upgrade recommended)");
});

Deno.test("signatureStatusLabel returns reason for SignatureInvalid", () => {
  const result = signatureStatusLabel({ TAG: "SignatureInvalid", _0: "expired cert" });
  assertEquals(result, "Invalid: expired cert");
});

// -- commonLicenses --

Deno.test("commonLicenses has 13 entries", () => {
  assertEquals(commonLicenses.length, 13);
});

Deno.test("commonLicenses includes MIT, MPL-2.0, and AGPL-3.0", () => {
  assert(commonLicenses.includes("MIT"));
  assert(commonLicenses.includes("MPL-2.0"));
  assert(commonLicenses.includes("AGPL-3.0"));
});

// -- parseAdoptionStats --

Deno.test("parseAdoptionStats parses valid JSON", () => {
  const json = JSON.stringify({
    total_repos: 100,
    pmpl_repos: 60,
    mpl_fallback_repos: 20,
    unlicensed_repos: 10,
    quantum_signed_repos: 5,
    by_license: { "PMPL-1.0": 60, "MPL-2.0": 20 },
  });
  const result = parseAdoptionStats(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.totalRepos, 100);
  assertEquals(result._0.pmplRepos, 60);
  assertEquals(result._0.mplFallbackRepos, 20);
  assertEquals(result._0.unlicensedRepos, 10);
  assertEquals(result._0.quantumSignedRepos, 5);
  assertEquals(result._0.byLicense.length, 2);
});

Deno.test("parseAdoptionStats returns Ok with defaults for non-object JSON", () => {
  const result = parseAdoptionStats('"hello"');
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.totalRepos, 0);
});

Deno.test("parseAdoptionStats returns error for invalid JSON", () => {
  const result = parseAdoptionStats("not json at all");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

Deno.test("parseAdoptionStats defaults missing fields to 0", () => {
  const json = JSON.stringify({});
  const result = parseAdoptionStats(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.totalRepos, 0);
  assertEquals(result._0.pmplRepos, 0);
  assertEquals(result._0.unlicensedRepos, 0);
});

Deno.test("parseAdoptionStats handles missing by_license", () => {
  const json = JSON.stringify({ total_repos: 10 });
  const result = parseAdoptionStats(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.byLicense.length, 0);
});

// -- adoptionPercentage --

Deno.test("adoptionPercentage returns 0 when totalRepos is 0", () => {
  assertEquals(adoptionPercentage({ totalRepos: 0, pmplRepos: 0 }), 0.0);
});

Deno.test("adoptionPercentage computes correct percentage", () => {
  const pct = adoptionPercentage({ totalRepos: 200, pmplRepos: 50 });
  assertEquals(pct, 25.0);
});

Deno.test("adoptionPercentage returns 100 when all repos are PMPL", () => {
  const pct = adoptionPercentage({ totalRepos: 100, pmplRepos: 100 });
  assertEquals(pct, 100.0);
});

// -- licensedPercentage --

Deno.test("licensedPercentage returns 0 when totalRepos is 0", () => {
  assertEquals(licensedPercentage({ totalRepos: 0, unlicensedRepos: 0 }), 0.0);
});

Deno.test("licensedPercentage computes correct percentage", () => {
  const pct = licensedPercentage({ totalRepos: 100, unlicensedRepos: 10 });
  assertEquals(pct, 90.0);
});

Deno.test("licensedPercentage returns 100 when no repos are unlicensed", () => {
  const pct = licensedPercentage({ totalRepos: 50, unlicensedRepos: 0 });
  assertEquals(pct, 100.0);
});
