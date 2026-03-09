// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ProvenanceEngine Tests — trust levels, summaries, colours, hostile UX
 */

import { assertEquals } from "jsr:@std/assert";
import {
  deriveTrustLevel,
  computeSummary,
  trustLabel,
  trustShortLabel,
  trustShape,
  trustColours,
  isHostile,
  hostileClasses,
  trustPercentage,
  defaultState,
} from "../src/core/ProvenanceEngine.res.js";

// -- deriveTrustLevel --

Deno.test("deriveTrustLevel human author returns HumanReviewed", () => {
  assertEquals(deriveTrustLevel("Jonathan", false, undefined, false), "HumanReviewed");
});

Deno.test("deriveTrustLevel bot author returns UnreviewedAi", () => {
  assertEquals(deriveTrustLevel("dependabot", false, undefined, false), "UnreviewedAi");
});

Deno.test("deriveTrustLevel AI co-authored returns AiAssisted", () => {
  assertEquals(deriveTrustLevel("Jonathan", true, "Claude <noreply@anthropic.com>", false), "AiAssisted");
});

Deno.test("deriveTrustLevel AI co-authored with subsequent human commit returns HumanReviewed", () => {
  assertEquals(deriveTrustLevel("Jonathan", true, "Claude <noreply@anthropic.com>", true), "HumanReviewed");
});

Deno.test("deriveTrustLevel empty author returns Unknown", () => {
  assertEquals(deriveTrustLevel("", false, undefined, false), "Unknown");
});

// -- trustLabel / trustShortLabel --

Deno.test("trustLabel returns correct strings", () => {
  assertEquals(trustLabel("Verified"), "Formally Verified");
  assertEquals(trustLabel("HumanReviewed"), "Human Reviewed");
  assertEquals(trustLabel("AiAssisted"), "AI Assisted");
  assertEquals(trustLabel("UnreviewedAi"), "Unreviewed AI");
  assertEquals(trustLabel("Unknown"), "Unknown Provenance");
});

Deno.test("trustShortLabel returns short forms", () => {
  assertEquals(trustShortLabel("Verified"), "Verified");
  assertEquals(trustShortLabel("HumanReviewed"), "Human");
  assertEquals(trustShortLabel("AiAssisted"), "AI+Human");
  assertEquals(trustShortLabel("UnreviewedAi"), "AI Only");
});

// -- trustShape --

Deno.test("trustShape returns correct icons", () => {
  assertEquals(trustShape("Verified"), "shield-check");
  assertEquals(trustShape("UnreviewedAi"), "alert-triangle");
});

// -- trustColours --

Deno.test("trustColours returns standard palette for Verified", () => {
  const [bg, text, border] = trustColours("Verified", "StandardPalette");
  assertEquals(bg, "bg-green-900/30");
  assertEquals(text, "text-green-400");
  assertEquals(border, "border-green-600");
});

Deno.test("trustColours returns high contrast for UnreviewedAi", () => {
  const [bg, text, border] = trustColours("UnreviewedAi", "HighContrastPalette");
  assertEquals(bg, "bg-red-800");
  assertEquals(text, "text-white");
});

// -- isHostile / hostileClasses --

Deno.test("isHostile returns true for UnreviewedAi", () => {
  assertEquals(isHostile("UnreviewedAi"), true);
  assertEquals(isHostile("HumanReviewed"), false);
});

Deno.test("hostileClasses returns animation classes for hostile unsuppressed", () => {
  const classes = hostileClasses("UnreviewedAi", false);
  assertEquals(classes.includes("animate-pulse"), true);
});

Deno.test("hostileClasses returns empty for suppressed", () => {
  assertEquals(hostileClasses("UnreviewedAi", true), "");
});

// -- computeSummary / trustPercentage --

Deno.test("computeSummary counts correctly", () => {
  const regions = [
    { startLine: 1, endLine: 10, trustLevel: "HumanReviewed", author: "A", coAuthor: undefined },
    { startLine: 11, endLine: 15, trustLevel: "UnreviewedAi", author: "bot", coAuthor: undefined },
  ];
  const summary = computeSummary(regions);
  assertEquals(summary.totalLines, 15);
  assertEquals(summary.humanReviewedLines, 10);
  assertEquals(summary.unreviewedAiLines, 5);
  assertEquals(summary.hasViolations, true);
});

Deno.test("trustPercentage returns 0 for empty", () => {
  assertEquals(trustPercentage({ totalLines: 0, verifiedLines: 0, humanReviewedLines: 0 }), 0.0);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.enabled, true);
  assertEquals(defaultState.activeFile, undefined);
  assertEquals(defaultState.cache.length, 0);
  assertEquals(defaultState.palette, "StandardPalette");
  assertEquals(defaultState.hostileUxActive, false);
  assertEquals(defaultState.hostileUxSuppressed, false);
});
