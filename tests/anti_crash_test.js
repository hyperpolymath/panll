// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * AntiCrash validation tests
 */

import { assertEquals } from "jsr:@std/assert";
import { processToken } from "../src/core/AntiCrash.res.js";

Deno.test("AntiCrash - high confidence clean token passes", () => {
  const token = {
    content: "const user = { name: 'Alice', age: 30 };",
    confidence: 0.95,
    sourcePaneId: "pane-n",
    inferredType: "code"
  };
  const constraints = [];
  const antiCrash = { enabled: true, halted: false };

  const result = processToken(token, constraints, antiCrash);
  assertEquals(result.TAG, "Approved");
});

Deno.test("AntiCrash - token with eval() is rejected by security", () => {
  const token = {
    content: "const result = eval('malicious code');",
    confidence: 0.9,
    sourcePaneId: "pane-n",
    inferredType: "code"
  };
  const constraints = [];
  const antiCrash = { enabled: true, halted: false };

  const result = processToken(token, constraints, antiCrash);
  assertEquals(result.TAG, "Blocked");
});

Deno.test("AntiCrash - low confidence token requires review", () => {
  const token = {
    content: "some content",
    confidence: 0.5,
    sourcePaneId: "pane-n",
    inferredType: "uncertain"
  };
  const constraints = [];
  const antiCrash = { enabled: true, halted: false };

  const result = processToken(token, constraints, antiCrash);
  assertEquals(result.TAG, "RequiresReview");
});

Deno.test("AntiCrash - token with undefined is rejected", () => {
  const token = {
    content: "const x = undefined;",
    confidence: 0.9,
    sourcePaneId: "pane-n",
    inferredType: "code"
  };
  const constraints = [
    { id: "c1", expression: "type Valid", active: true, pinned: false }
  ];
  const antiCrash = { enabled: true, halted: false };

  const result = processToken(token, constraints, antiCrash);
  assertEquals(result.TAG, "Blocked");
});

Deno.test("AntiCrash - disabled antiCrash passes everything", () => {
  const token = {
    content: "eval('dangerous');",
    confidence: 0.3,
    sourcePaneId: "pane-n",
    inferredType: "code"
  };
  const constraints = [];
  const antiCrash = { enabled: false, halted: false };

  const result = processToken(token, constraints, antiCrash);
  assertEquals(result.TAG, "Approved");
});

Deno.test("AntiCrash - halted state blocks everything", () => {
  const token = {
    content: "const safe = 42;",
    confidence: 0.99,
    sourcePaneId: "pane-n",
    inferredType: "code"
  };
  const constraints = [];
  const antiCrash = { enabled: true, halted: true };

  const result = processToken(token, constraints, antiCrash);
  assertEquals(result.TAG, "Blocked");
});
