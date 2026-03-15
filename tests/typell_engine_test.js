// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * TypeLLEngine Tests — view layers, features, tiers, narratives, parsing,
 * formatting, filtering, and default state.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  viewLayerLabel,
  viewLayerDescription,
  allViewLayers,
  viewLayerColour,
  featureLabel,
  featureCode,
  featureTier,
  coreFeatures,
  advancedFeatures,
  researchFeatures,
  allFeatures,
  tierLabel,
  tierColour,
  featureGlyph,
  categoryLabel,
  allCategories,
  generateNarrative,
  formatSignature,
  filterByTier,
  filterBySearch,
  parseCheckResult,
  parseRefinementResult,
  defaultState,
} from "../src/core/TypeLLEngine.res.js";

// ============================================================================
// viewLayerLabel
// ============================================================================

Deno.test("viewLayerLabel returns correct strings", () => {
  assertEquals(viewLayerLabel("Raw"), "Raw");
  assertEquals(viewLayerLabel("Folded"), "Folded");
  assertEquals(viewLayerLabel("Glyphed"), "Glyphed");
  assertEquals(viewLayerLabel("Wysiwyg"), "WYSIWYG");
});

// ============================================================================
// viewLayerDescription
// ============================================================================

Deno.test("viewLayerDescription returns descriptive text for each layer", () => {
  assertEquals(viewLayerDescription("Raw"), "Full type signatures, unmodified. Expert mode.");
  assertEquals(viewLayerDescription("Folded"), "Categorised and collapsible. Working developer mode.");
  assertEquals(viewLayerDescription("Glyphed"), "Symbol-annotated types. Learning mode.");
  assertEquals(viewLayerDescription("Wysiwyg"), "Interactive type construction. Exploration mode.");
});

// ============================================================================
// allViewLayers
// ============================================================================

Deno.test("allViewLayers has 4 entries in abstraction order", () => {
  assertEquals(allViewLayers.length, 4);
  assertEquals(allViewLayers[0], "Raw");
  assertEquals(allViewLayers[1], "Folded");
  assertEquals(allViewLayers[2], "Glyphed");
  assertEquals(allViewLayers[3], "Wysiwyg");
});

// ============================================================================
// viewLayerColour
// ============================================================================

Deno.test("viewLayerColour returns Tailwind classes for each layer", () => {
  assertEquals(viewLayerColour("Raw"), "text-gray-300 bg-gray-800/50");
  assertEquals(viewLayerColour("Folded"), "text-sky-400 bg-sky-900/30");
  assertEquals(viewLayerColour("Glyphed"), "text-violet-400 bg-violet-900/30");
  assertEquals(viewLayerColour("Wysiwyg"), "text-amber-400 bg-amber-900/30");
});

// ============================================================================
// featureLabel
// ============================================================================

Deno.test("featureLabel returns human-readable labels for all features", () => {
  assertEquals(featureLabel("DependentTypes"), "Dependent Types");
  assertEquals(featureLabel("LinearTypes"), "Linear Types");
  assertEquals(featureLabel("SessionTypes"), "Session Types");
  assertEquals(featureLabel("ProofCarryingCode"), "Proof-Carrying Code");
  assertEquals(featureLabel("QuantitativeTypeTheory"), "Quantitative Type Theory");
  assertEquals(featureLabel("EffectSystems"), "Effect Systems");
  assertEquals(featureLabel("ModalTypes"), "Modal Types");
  assertEquals(featureLabel("AffineTypes"), "Affine Types");
  assertEquals(featureLabel("HomotopyTypeTheory"), "Homotopy Type Theory");
  assertEquals(featureLabel("EqualitySaturation"), "Equality Saturation");
  assertEquals(featureLabel("CategoryTheoreticTypes"), "Category-Theoretic Types");
});

// ============================================================================
// featureCode
// ============================================================================

Deno.test("featureCode returns short codes for all features", () => {
  assertEquals(featureCode("DependentTypes"), "dep");
  assertEquals(featureCode("LinearTypes"), "lin");
  assertEquals(featureCode("SessionTypes"), "sess");
  assertEquals(featureCode("ProofCarryingCode"), "pcc");
  assertEquals(featureCode("QuantitativeTypeTheory"), "qtt");
  assertEquals(featureCode("EffectSystems"), "eff");
  assertEquals(featureCode("ModalTypes"), "mod");
  assertEquals(featureCode("AffineTypes"), "aff");
  assertEquals(featureCode("HomotopyTypeTheory"), "hott");
  assertEquals(featureCode("EqualitySaturation"), "eqsat");
  assertEquals(featureCode("CategoryTheoreticTypes"), "cat");
});

// ============================================================================
// featureTier
// ============================================================================

Deno.test("featureTier maps core features to TierCore", () => {
  assertEquals(featureTier("DependentTypes"), "TierCore");
  assertEquals(featureTier("LinearTypes"), "TierCore");
  assertEquals(featureTier("SessionTypes"), "TierCore");
  assertEquals(featureTier("ProofCarryingCode"), "TierCore");
});

Deno.test("featureTier maps advanced features to TierAdvanced", () => {
  assertEquals(featureTier("QuantitativeTypeTheory"), "TierAdvanced");
  assertEquals(featureTier("EffectSystems"), "TierAdvanced");
  assertEquals(featureTier("ModalTypes"), "TierAdvanced");
  assertEquals(featureTier("AffineTypes"), "TierAdvanced");
});

Deno.test("featureTier maps research features to TierResearch", () => {
  assertEquals(featureTier("HomotopyTypeTheory"), "TierResearch");
  assertEquals(featureTier("EqualitySaturation"), "TierResearch");
  assertEquals(featureTier("CategoryTheoreticTypes"), "TierResearch");
});

// ============================================================================
// Feature arrays
// ============================================================================

Deno.test("coreFeatures has 4 entries", () => {
  assertEquals(coreFeatures.length, 4);
});

Deno.test("advancedFeatures has 4 entries", () => {
  assertEquals(advancedFeatures.length, 4);
});

Deno.test("researchFeatures has 3 entries", () => {
  assertEquals(researchFeatures.length, 3);
});

Deno.test("allFeatures has 11 entries (4 + 4 + 3)", () => {
  assertEquals(allFeatures.length, 11);
});

Deno.test("allFeatures contains every core, advanced, and research feature", () => {
  for (const f of coreFeatures) {
    assert(allFeatures.includes(f), `Missing core feature: ${f}`);
  }
  for (const f of advancedFeatures) {
    assert(allFeatures.includes(f), `Missing advanced feature: ${f}`);
  }
  for (const f of researchFeatures) {
    assert(allFeatures.includes(f), `Missing research feature: ${f}`);
  }
});

// ============================================================================
// tierLabel
// ============================================================================

Deno.test("tierLabel returns correct strings", () => {
  assertEquals(tierLabel("TierCore"), "Core");
  assertEquals(tierLabel("TierAdvanced"), "Advanced");
  assertEquals(tierLabel("TierResearch"), "Research");
});

// ============================================================================
// tierColour
// ============================================================================

Deno.test("tierColour returns Tailwind classes for each tier", () => {
  assertEquals(tierColour("TierCore"), "text-emerald-400 bg-emerald-900/30");
  assertEquals(tierColour("TierAdvanced"), "text-blue-400 bg-blue-900/30");
  assertEquals(tierColour("TierResearch"), "text-purple-400 bg-purple-900/30");
});

// ============================================================================
// featureGlyph
// ============================================================================

Deno.test("featureGlyph returns glyph with symbol, label, and meaning", () => {
  const g = featureGlyph("DependentTypes");
  assertEquals(g.symbol, "Pi");
  assertEquals(g.label, "Dependent");
  assert(g.meaning.length > 0, "meaning should be non-empty");
});

Deno.test("featureGlyph returns distinct symbols for each feature", () => {
  const symbols = allFeatures.map((f) => featureGlyph(f).symbol);
  const unique = new Set(symbols);
  assertEquals(unique.size, symbols.length);
});

Deno.test("featureGlyph covers specific symbols", () => {
  assertEquals(featureGlyph("LinearTypes").symbol, "1");
  assertEquals(featureGlyph("SessionTypes").symbol, "!");
  assertEquals(featureGlyph("ProofCarryingCode").symbol, "QED");
  assertEquals(featureGlyph("EffectSystems").symbol, "IO");
  assertEquals(featureGlyph("ModalTypes").symbol, "BOX");
  assertEquals(featureGlyph("AffineTypes").symbol, "?1");
  assertEquals(featureGlyph("HomotopyTypeTheory").symbol, "~");
  assertEquals(featureGlyph("EqualitySaturation").symbol, "=");
  assertEquals(featureGlyph("CategoryTheoreticTypes").symbol, "->");
});

// ============================================================================
// categoryLabel
// ============================================================================

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("TlChecker"), "Checker");
  assertEquals(categoryLabel("TlExplorer"), "Explorer");
  assertEquals(categoryLabel("TlRefinement"), "Refinement");
  assertEquals(categoryLabel("TlGuide"), "Guide");
});

// ============================================================================
// allCategories
// ============================================================================

Deno.test("allCategories has 5 entries", () => {
  assertEquals(allCategories.length, 5);
  assertEquals(allCategories[0], "TlChecker");
  assertEquals(allCategories[1], "TlExplorer");
  assertEquals(allCategories[2], "TlRefinement");
  assertEquals(allCategories[3], "TlDiscipline");
  assertEquals(allCategories[4], "TlGuide");
});

// ============================================================================
// generateNarrative
// ============================================================================

Deno.test("generateNarrative for valid result with no features", () => {
  const result = {
    valid: true,
    typeSignature: "Int -> Int",
    explanation: "A simple function",
    proofObligations: [],
    effects: [],
    linearityIssues: [],
    sessionNotes: [],
    activeFeatures: [],
    maxTier: "TierCore",
  };
  const narrative = generateNarrative(result);
  assert(narrative.celebrate.includes("type-checks cleanly"));
  assertEquals(narrative.minimize, "");
  assert(narrative.showBetter.includes("Core type features"));
  assert(narrative.safety.includes("Fully verified"));
});

Deno.test("generateNarrative for valid result with active features", () => {
  const result = {
    valid: true,
    typeSignature: "(n : Nat) -> Vec n Int",
    explanation: "A dependent vector",
    proofObligations: [],
    effects: [],
    linearityIssues: [],
    sessionNotes: [],
    activeFeatures: ["DependentTypes"],
    maxTier: "TierCore",
  };
  const narrative = generateNarrative(result);
  assert(narrative.celebrate.includes("Dependent Types"));
  assert(narrative.celebrate.includes("serious type-level engineering"));
});

Deno.test("generateNarrative for invalid result", () => {
  const result = {
    valid: false,
    typeSignature: "",
    explanation: "Type error",
    proofObligations: [],
    effects: [],
    linearityIssues: [],
    sessionNotes: [],
    activeFeatures: [],
    maxTier: "TierCore",
  };
  const narrative = generateNarrative(result);
  assert(narrative.celebrate.includes("engaging with the type system"));
  assert(narrative.minimize.includes("bug caught before runtime"));
  assert(narrative.safety.includes("Fix the type errors"));
});

Deno.test("generateNarrative for valid result with linearity issues", () => {
  const result = {
    valid: true,
    typeSignature: "1 Int -> ()",
    explanation: "Linear consumption",
    proofObligations: [],
    effects: [],
    linearityIssues: ["x used twice"],
    sessionNotes: [],
    activeFeatures: ["LinearTypes"],
    maxTier: "TierCore",
  };
  const narrative = generateNarrative(result);
  assert(narrative.minimize.includes("linearity notes"));
});

Deno.test("generateNarrative for valid result with proof obligations", () => {
  const result = {
    valid: true,
    typeSignature: "Nat -> Nat",
    explanation: "Needs proof",
    proofObligations: ["n > 0", "n < 100"],
    effects: [],
    linearityIssues: [],
    sessionNotes: [],
    activeFeatures: [],
    maxTier: "TierCore",
  };
  const narrative = generateNarrative(result);
  assert(narrative.minimize.includes("2 proof obligations"));
  assert(narrative.safety.includes("Verified with 2 proof obligations"));
});

Deno.test("generateNarrative for result with effects", () => {
  const result = {
    valid: true,
    typeSignature: "IO ()",
    explanation: "Effectful computation",
    proofObligations: [],
    effects: ["Read", "Write"],
    linearityIssues: [],
    sessionNotes: [],
    activeFeatures: ["EffectSystems"],
    maxTier: "TierAdvanced",
  };
  const narrative = generateNarrative(result);
  assert(narrative.showBetter.includes("2 effects tracked explicitly"));
});

Deno.test("generateNarrative for result with advanced tier and no effects", () => {
  const result = {
    valid: true,
    typeSignature: "Box a -> a",
    explanation: "Modal unboxing",
    proofObligations: [],
    effects: [],
    linearityIssues: [],
    sessionNotes: [],
    activeFeatures: [],
    maxTier: "TierAdvanced",
  };
  const narrative = generateNarrative(result);
  assert(narrative.showBetter.includes("Advanced type features"));
});

Deno.test("generateNarrative for result with research tier and no effects", () => {
  const result = {
    valid: true,
    typeSignature: "Path A a b",
    explanation: "HoTT path type",
    proofObligations: [],
    effects: [],
    linearityIssues: [],
    sessionNotes: [],
    activeFeatures: [],
    maxTier: "TierResearch",
  };
  const narrative = generateNarrative(result);
  assert(narrative.showBetter.includes("Type-level computation"));
});

// ============================================================================
// formatSignature
// ============================================================================

Deno.test("formatSignature Raw returns signature unchanged", () => {
  assertEquals(formatSignature("Int -> Int", "Raw", []), "Int -> Int");
  assertEquals(
    formatSignature("Vec n a", "Raw", ["DependentTypes"]),
    "Vec n a",
  );
});

Deno.test("formatSignature Folded prepends tier prefix", () => {
  assertEquals(
    formatSignature("Int -> Int", "Folded", ["DependentTypes"]),
    "[Core] Int -> Int",
  );
  assertEquals(
    formatSignature("IO ()", "Folded", ["EffectSystems"]),
    "[Advanced] IO ()",
  );
  assertEquals(
    formatSignature("Path A a b", "Folded", ["HomotopyTypeTheory"]),
    "[Research] Path A a b",
  );
});

Deno.test("formatSignature Folded with no features defaults to Core", () => {
  assertEquals(
    formatSignature("Int", "Folded", []),
    "[Core] Int",
  );
});

Deno.test("formatSignature Folded picks highest tier when mixed", () => {
  assertEquals(
    formatSignature("sig", "Folded", ["DependentTypes", "HomotopyTypeTheory"]),
    "[Research] sig",
  );
  assertEquals(
    formatSignature("sig", "Folded", ["DependentTypes", "EffectSystems"]),
    "[Advanced] sig",
  );
});

Deno.test("formatSignature Glyphed prepends glyph symbols", () => {
  const result = formatSignature("Vec n a", "Glyphed", ["DependentTypes"]);
  assertEquals(result, "Pi | Vec n a");
});

Deno.test("formatSignature Glyphed with multiple features joins symbols", () => {
  const result = formatSignature("sig", "Glyphed", ["DependentTypes", "LinearTypes"]);
  assertEquals(result, "Pi 1 | sig");
});

Deno.test("formatSignature Glyphed with no features returns signature as-is", () => {
  assertEquals(formatSignature("Int", "Glyphed", []), "Int");
});

Deno.test("formatSignature Wysiwyg returns signature unchanged", () => {
  assertEquals(
    formatSignature("Int -> Int", "Wysiwyg", ["DependentTypes"]),
    "Int -> Int",
  );
});

// ============================================================================
// filterByTier
// ============================================================================

Deno.test("filterByTier with undefined returns all signatures", () => {
  const sigs = [
    { name: "f", signature: "Int", module_: "M", tier: "TierCore" },
    { name: "g", signature: "IO ()", module_: "M", tier: "TierAdvanced" },
  ];
  const result = filterByTier(sigs, undefined);
  assertEquals(result.length, 2);
});

Deno.test("filterByTier with TierCore returns only core entries", () => {
  const sigs = [
    { name: "f", signature: "Int", module_: "M", tier: "TierCore" },
    { name: "g", signature: "IO ()", module_: "M", tier: "TierAdvanced" },
    { name: "h", signature: "Path", module_: "M", tier: "TierResearch" },
  ];
  const result = filterByTier(sigs, "TierCore");
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "f");
});

Deno.test("filterByTier with TierAdvanced returns only advanced entries", () => {
  const sigs = [
    { name: "f", signature: "Int", module_: "M", tier: "TierCore" },
    { name: "g", signature: "IO ()", module_: "M", tier: "TierAdvanced" },
  ];
  const result = filterByTier(sigs, "TierAdvanced");
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "g");
});

// ============================================================================
// filterBySearch
// ============================================================================

Deno.test("filterBySearch with empty query returns all", () => {
  const sigs = [
    { name: "foo", signature: "Int", module_: "M", tier: "TierCore" },
    { name: "bar", signature: "String", module_: "N", tier: "TierCore" },
  ];
  assertEquals(filterBySearch(sigs, "").length, 2);
});

Deno.test("filterBySearch matches name case-insensitive", () => {
  const sigs = [
    { name: "myFunc", signature: "Int", module_: "M", tier: "TierCore" },
    { name: "other", signature: "Bool", module_: "N", tier: "TierCore" },
  ];
  const result = filterBySearch(sigs, "MYFUNC");
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "myFunc");
});

Deno.test("filterBySearch matches signature text", () => {
  const sigs = [
    { name: "f", signature: "Int -> Bool", module_: "M", tier: "TierCore" },
    { name: "g", signature: "String", module_: "N", tier: "TierCore" },
  ];
  const result = filterBySearch(sigs, "Bool");
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "f");
});

Deno.test("filterBySearch matches module name", () => {
  const sigs = [
    { name: "f", signature: "Int", module_: "Prelude", tier: "TierCore" },
    { name: "g", signature: "Int", module_: "Network", tier: "TierCore" },
  ];
  const result = filterBySearch(sigs, "prelude");
  assertEquals(result.length, 1);
  assertEquals(result[0].module_, "Prelude");
});

Deno.test("filterBySearch returns empty when nothing matches", () => {
  const sigs = [
    { name: "f", signature: "Int", module_: "M", tier: "TierCore" },
  ];
  assertEquals(filterBySearch(sigs, "zzzzz").length, 0);
});

// ============================================================================
// parseCheckResult
// ============================================================================

Deno.test("parseCheckResult parses valid JSON object", () => {
  const json = JSON.stringify({
    valid: true,
    type_signature: "Nat -> Nat",
    explanation: "Natural number function",
    proof_obligations: ["n >= 0"],
    effects: ["Read"],
    linearity_issues: [],
    session_notes: ["protocol ok"],
  });
  const result = parseCheckResult(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.valid, true);
  assertEquals(result._0.typeSignature, "Nat -> Nat");
  assertEquals(result._0.explanation, "Natural number function");
  assertEquals(result._0.proofObligations.length, 1);
  assertEquals(result._0.proofObligations[0], "n >= 0");
  assertEquals(result._0.effects[0], "Read");
  assertEquals(result._0.linearityIssues.length, 0);
  assertEquals(result._0.sessionNotes[0], "protocol ok");
  assertEquals(result._0.activeFeatures.length, 0);
  assertEquals(result._0.maxTier, "TierCore");
});

Deno.test("parseCheckResult defaults missing fields", () => {
  const json = JSON.stringify({});
  const result = parseCheckResult(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.valid, false);
  assertEquals(result._0.typeSignature, "");
  assertEquals(result._0.explanation, "");
  assertEquals(result._0.proofObligations.length, 0);
  assertEquals(result._0.effects.length, 0);
});

Deno.test("parseCheckResult returns Ok with defaults for non-object JSON", () => {
  const result = parseCheckResult('"just a string"');
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.valid, false);
  assertEquals(result._0.typeSignature, "");
});

Deno.test("parseCheckResult returns Error for invalid JSON", () => {
  const result = parseCheckResult("not valid json at all");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

Deno.test("parseCheckResult returns Ok with defaults for JSON array", () => {
  const result = parseCheckResult("[1, 2, 3]");
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.valid, false);
});

// ============================================================================
// parseRefinementResult
// ============================================================================

Deno.test("parseRefinementResult parses valid JSON object", () => {
  const json = JSON.stringify({
    base_type: "Int",
    refined_type: "{ x : Int | x > 0 }",
    consistent: true,
  });
  const result = parseRefinementResult(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.baseType, "Int");
  assertEquals(result._0.refinedType, "{ x : Int | x > 0 }");
  assertEquals(result._0.consistent, true);
  assertEquals(result._0.constraints.length, 0);
});

Deno.test("parseRefinementResult defaults missing fields", () => {
  const json = JSON.stringify({});
  const result = parseRefinementResult(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.baseType, "");
  assertEquals(result._0.refinedType, "");
  assertEquals(result._0.consistent, false);
});

Deno.test("parseRefinementResult returns Ok with defaults for non-object JSON", () => {
  const result = parseRefinementResult("42");
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.consistent, false);
});

Deno.test("parseRefinementResult returns Error for invalid JSON", () => {
  const result = parseRefinementResult("{broken");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

// ============================================================================
// defaultState
// ============================================================================

Deno.test("defaultState has expected initial values", () => {
  assertEquals(defaultState.serverConnected, false);
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.error, undefined);
  assertEquals(defaultState.activeCategory, "TlChecker");
  assertEquals(defaultState.activeViewLayer, "Folded");
  assertEquals(defaultState.checkerInput, "");
  assertEquals(defaultState.checkerContext, "");
  assertEquals(defaultState.lastCheckResult, undefined);
  assertEquals(defaultState.lastNarrative, undefined);
  assertEquals(defaultState.signatures.length, 0);
  assertEquals(defaultState.universes.length, 0);
  assertEquals(defaultState.signatureFilter, "");
  assertEquals(defaultState.tierFilter, undefined);
  assertEquals(defaultState.refinementSpec, "");
  assertEquals(defaultState.refinementConstraints, "");
  assertEquals(defaultState.lastRefinement, undefined);
  assertEquals(defaultState.serviceActive, true);
  assertEquals(defaultState.queriesServed, 0);
});
