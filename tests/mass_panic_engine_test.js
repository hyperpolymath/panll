// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * PanicAttackerMode Tests — tone class and label formatting for
 * panic-attacker mode presentation helpers.
 *
 * Note: This module does not have a defaultState; it exports only
 * toneClass and label helper functions.
 */

import { assertEquals } from "jsr:@std/assert";
import {
  toneClass,
  label,
} from "../src/core/PanicAttackerMode.res.js";

// -- toneClass --

Deno.test("toneClass returns correct class for 'full'", () => {
  assertEquals(toneClass("full"), "text-emerald-400");
});

Deno.test("toneClass returns correct class for 'fallback'", () => {
  assertEquals(toneClass("fallback"), "text-amber-400");
});

Deno.test("toneClass returns correct class for 'unavailable'", () => {
  assertEquals(toneClass("unavailable"), "text-red-400");
});

Deno.test("toneClass returns default class for unknown mode", () => {
  assertEquals(toneClass("anything"), "text-gray-500");
});

// -- label --

Deno.test("label returns correct text for 'full'", () => {
  assertEquals(label("full"), "panic-attacker mode: full panll export");
});

Deno.test("label returns correct text for 'fallback'", () => {
  assertEquals(label("fallback"), "panic-attacker mode: fallback conversion");
});

Deno.test("label returns correct text for 'unavailable'", () => {
  assertEquals(label("unavailable"), "panic-attacker mode: unavailable");
});

Deno.test("label returns unknown text for unrecognised mode", () => {
  assertEquals(label("xyz"), "panic-attacker mode: unknown (probe pending)");
});
