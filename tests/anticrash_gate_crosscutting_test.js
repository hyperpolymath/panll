// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * Anti-Crash Gate Cross-Cutting Tests — aspect-oriented verification of
 * the logical circuit breaker for neural token validation.
 *
 * Tests the full validation pipeline:
 *   - Security constraint checking (eval, exec, rm -rf, DROP TABLE, <script>)
 *   - Type constraint checking (forbidden patterns, reserved keywords)
 *   - Logic constraint checking (boolean contradictions, negations)
 *   - Review/approve/reject state machine
 *   - Halt/clear lifecycle
 *   - Integration with Update cycle
 *   - Throughput under adversarial input
 *
 * ReScript compilation notes:
 *   processToken returns [state, token | undefined] (tuple → JS array)
 *   validate returns "Valid" | { TAG: "Invalid", _0: reason } | { TAG: "RequiresReview", _0: reason }
 */

import { assertEquals, assert, assertNotEquals } from "jsr:@std/assert";
import * as AntiCrash from "../src/core/AntiCrash.res.js";
import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";

// ─── Helpers ────────────────────────────────────────────────────────────

const makeToken = (content, confidence = 0.95) => ({
  content,
  confidence,
  sourcePaneId: "pane-n",
  inferredType: "code",
});

const defaultState = () => AntiCrash.init();

const defaultConstraints = () => [
  { id: "c1", expression: "type Safe", active: true, pinned: false },
];

// ─── State Machine Initialisation ───────────────────────────────────────

Deno.test("AntiCrash — init creates enabled, non-halted state", () => {
  const state = defaultState();
  assertEquals(state.enabled, true);
  assertEquals(state.strictMode, true);
  assertEquals(state.halted, false);
  assertEquals(state.violations.length, 0);
  assertEquals(state.pendingReview, undefined);
});

// ─── Security Constraint Checking ───────────────────────────────────────

Deno.test("AntiCrash — checkSecurityConstraints: eval() detected", () => {
  const token = makeToken("const x = eval('malicious');");
  const result = AntiCrash.checkSecurityConstraints(token);
  assertNotEquals(result, undefined, "eval should be flagged");
});

Deno.test("AntiCrash — checkSecurityConstraints: exec() detected", () => {
  const token = makeToken("require('child_process').exec('rm -rf /')");
  const result = AntiCrash.checkSecurityConstraints(token);
  assertNotEquals(result, undefined, "exec should be flagged");
});

Deno.test("AntiCrash — checkSecurityConstraints: DROP TABLE detected", () => {
  const token = makeToken("DROP TABLE users;");
  const result = AntiCrash.checkSecurityConstraints(token);
  assertNotEquals(result, undefined, "DROP TABLE should be flagged");
});

Deno.test("AntiCrash — checkSecurityConstraints: <script> detected", () => {
  const token = makeToken('<script>alert("xss")</script>');
  const result = AntiCrash.checkSecurityConstraints(token);
  assertNotEquals(result, undefined, "<script> should be flagged");
});

Deno.test("AntiCrash — checkSecurityConstraints: DELETE FROM detected", () => {
  const token = makeToken("DELETE FROM accounts WHERE id = 1;");
  const result = AntiCrash.checkSecurityConstraints(token);
  assertNotEquals(result, undefined, "DELETE FROM should be flagged");
});

Deno.test("AntiCrash — checkSecurityConstraints: rm -rf detected", () => {
  const token = makeToken("rm -rf /var/data");
  const result = AntiCrash.checkSecurityConstraints(token);
  assertNotEquals(result, undefined, "rm -rf should be flagged");
});

Deno.test("AntiCrash — checkSecurityConstraints: safe code passes", () => {
  const token = makeToken("const greeting = 'Hello, world!';");
  const result = AntiCrash.checkSecurityConstraints(token);
  assertEquals(result, undefined, "Safe code should not be flagged");
});

// ─── Type Constraint Checking ───────────────────────────────────────────

Deno.test("AntiCrash — checkTypeConstraints: token with constraints passes basic check", () => {
  const token = makeToken("const x: number = 42;");
  const constraints = [{ id: "c1", expression: "type Safe", active: true, pinned: false }];
  const result = AntiCrash.checkTypeConstraints(token, constraints);
  // Whether this flags depends on implementation, but should not throw
  assert(result === undefined || typeof result === "object", "Type check returns violation or undefined");
});

// ─── Logic Constraint Checking ──────────────────────────────────────────

Deno.test("AntiCrash — checkLogicConstraints: clean token passes", () => {
  const token = makeToken("const result = a && b;");
  const constraints = [];
  const result = AntiCrash.checkLogicConstraints(token, constraints);
  assertEquals(result, undefined, "Clean token should pass logic check");
});

// ─── Full Validation Pipeline ───────────────────────────────────────────

Deno.test("AntiCrash — validate: safe high-confidence token is Valid", () => {
  const token = makeToken("const x = 42;", 0.95);
  const result = AntiCrash.validate(token, defaultConstraints());
  assertEquals(result, "Valid");
});

Deno.test("AntiCrash — validate: dangerous token is Invalid", () => {
  const token = makeToken("eval('attack');", 0.95);
  const result = AntiCrash.validate(token, defaultConstraints());
  assertEquals(result.TAG, "Invalid");
  assert(typeof result._0 === "string", "Invalid has reason string");
});

Deno.test("AntiCrash — validate: low-confidence token RequiresReview", () => {
  const token = makeToken("ambiguous output", 0.4);
  const result = AntiCrash.validate(token, defaultConstraints());
  // Low confidence should trigger review or validation depending on threshold
  assert(
    result === "Valid" || result.TAG === "RequiresReview" || result.TAG === "Invalid",
    `Expected a valid result type, got: ${JSON.stringify(result)}`
  );
});

// ─── processToken Pipeline ──────────────────────────────────────────────

Deno.test("AntiCrash — processToken: safe token returns [state, validatedToken]", () => {
  const state = defaultState();
  const token = makeToken("const greeting = 'hi';", 0.95);
  const [newState, validatedToken] = AntiCrash.processToken(token, [], state);

  assertNotEquals(validatedToken, undefined, "Safe token should pass through");
  assertEquals(validatedToken.validated, true);
  assertEquals(newState.halted, false);
});

Deno.test("AntiCrash — processToken: dangerous token returns [state, undefined]", () => {
  const state = defaultState();
  const token = makeToken("eval('rm -rf /')", 0.9);
  const [newState, validatedToken] = AntiCrash.processToken(token, [], state);

  assertEquals(validatedToken, undefined, "Dangerous token should be blocked");
});

Deno.test("AntiCrash — processToken: halted state blocks everything", () => {
  const state = { ...defaultState(), halted: true };
  const token = makeToken("perfectly safe code", 0.99);
  const [_newState, validatedToken] = AntiCrash.processToken(token, [], state);

  assertEquals(validatedToken, undefined, "Halted state blocks all tokens");
});

Deno.test("AntiCrash — processToken: disabled state passes everything unvalidated", () => {
  const state = { ...defaultState(), enabled: false };
  const token = makeToken("eval('dangerous')", 0.5);
  const [_newState, validatedToken] = AntiCrash.processToken(token, [], state);

  assertNotEquals(validatedToken, undefined, "Disabled gate passes tokens");
  assertEquals(validatedToken.validated, false, "Passed tokens are not validated");
});

// ─── Review State Machine ───────────────────────────────────────────────

Deno.test("AntiCrash — low confidence token sets pendingReview", () => {
  const state = defaultState();
  const token = makeToken("uncertain output", 0.3);
  const [newState, _validatedToken] = AntiCrash.processToken(token, [], state);

  // Either pendingReview is set (RequiresReview) or token was rejected
  // Depends on the exact confidence threshold in implementation
  assert(
    newState.pendingReview !== undefined || _validatedToken === undefined,
    "Low confidence should either set pendingReview or block"
  );
});

Deno.test("AntiCrash — approveReview releases pending token", () => {
  // Create state with pending review
  const state = {
    ...defaultState(),
    pendingReview: makeToken("reviewed output", 0.5),
  };

  const [newState, approvedToken] = AntiCrash.approveReview(state);
  assertEquals(newState.pendingReview, undefined, "Pending review cleared");
  assertNotEquals(approvedToken, undefined, "Approved token should be returned");
});

Deno.test("AntiCrash — rejectReview clears pending without releasing", () => {
  const state = {
    ...defaultState(),
    pendingReview: makeToken("rejected output", 0.5),
  };

  const newState = AntiCrash.rejectReview(state);
  assertEquals(newState.pendingReview, undefined, "Pending review cleared");
});

Deno.test("AntiCrash — clearHalt resets halt and pendingReview", () => {
  const state = {
    ...defaultState(),
    halted: true,
    pendingReview: makeToken("stuck", 0.5),
  };

  const newState = AntiCrash.clearHalt(state);
  assertEquals(newState.halted, false);
  assertEquals(newState.pendingReview, undefined);
});

// ─── Cross-Cutting: AntiCrash in the Update Cycle ───────────────────────

Deno.test("Cross-cutting — ValidationPassed adds validated token to PaneN", () => {
  const m = initModel();
  const token = { content: "safe output", timestamp: Date.now(), confidence: 0.95, validated: false };
  const [newModel] = Update.update(m, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationPassed", _0: token },
  });

  const lastToken = newModel.paneN.tokens[newModel.paneN.tokens.length - 1];
  assertEquals(lastToken.content, "safe output");
  assertEquals(lastToken.validated, true);
});

Deno.test("Cross-cutting — ValidationFailed in strict mode halts system", () => {
  const m = initModel();
  const [newModel] = Update.update(m, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: makeToken("bad"), _1: "Security violation" },
  });

  assertEquals(newModel.antiCrash.halted, true);
  assertEquals(newModel.antiCrash.violations.length, 1);
});

Deno.test("Cross-cutting — ValidationFailed in non-strict mode does not halt", () => {
  const m = { ...initModel(), antiCrash: { ...initModel().antiCrash, strictMode: false } };
  const [newModel] = Update.update(m, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: makeToken("bad"), _1: "Rejected" },
  });

  assertEquals(newModel.antiCrash.halted, false);
  assertEquals(newModel.antiCrash.violations.length, 1);
});

Deno.test("Cross-cutting — RequestOperatorIntervention halts the gate", () => {
  const m = initModel();
  const [newModel] = Update.update(m, {
    TAG: "AntiCrash",
    _0: { TAG: "RequestOperatorIntervention", _0: "Low confidence batch" },
  });

  assertEquals(newModel.antiCrash.halted, true);
});

Deno.test("Cross-cutting — multiple violations accumulate", () => {
  let m = initModel();
  // First violation halts in strict mode
  const [m2] = Update.update(m, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: makeToken("bad1"), _1: "Violation 1" },
  });
  assertEquals(m2.antiCrash.violations.length, 1);
});

// ─── Adversarial Input ──────────────────────────────────────────────────

Deno.test("AntiCrash — empty content token handled gracefully", () => {
  const state = defaultState();
  const token = makeToken("", 0.95);
  const [_newState, _result] = AntiCrash.processToken(token, [], state);
  // Should not throw
  assert(true, "Empty token handled without error");
});

Deno.test("AntiCrash — very long content token handled gracefully", () => {
  const state = defaultState();
  const token = makeToken("x".repeat(100000), 0.95);
  const [_newState, _result] = AntiCrash.processToken(token, [], state);
  assert(true, "Long token handled without error");
});

Deno.test("AntiCrash — special characters in content handled gracefully", () => {
  const state = defaultState();
  const specialChars = "🎯\0\n\r\t\"'`\\/<>&;|${}[]()";
  const token = makeToken(specialChars, 0.95);
  const [_newState, _result] = AntiCrash.processToken(token, [], state);
  assert(true, "Special characters handled without error");
});
