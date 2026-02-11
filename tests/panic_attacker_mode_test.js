// SPDX-License-Identifier: PMPL-1.0-or-later

import { assertEquals } from "jsr:@std/assert";
import { label, toneClass } from "../src/core/PanicAttackerMode.res.js";

Deno.test("PanicAttackerMode.toneClass - maps all supported modes", () => {
  assertEquals(toneClass("full"), "text-emerald-400");
  assertEquals(toneClass("fallback"), "text-amber-400");
  assertEquals(toneClass("unavailable"), "text-red-400");
  assertEquals(toneClass("unknown"), "text-gray-500");
});

Deno.test("PanicAttackerMode.label - maps all supported modes", () => {
  assertEquals(label("full"), "panic-attacker mode: full panll export");
  assertEquals(label("fallback"), "panic-attacker mode: fallback conversion");
  assertEquals(label("unavailable"), "panic-attacker mode: unavailable");
  assertEquals(label("unknown"), "panic-attacker mode: unknown (probe pending)");
});

