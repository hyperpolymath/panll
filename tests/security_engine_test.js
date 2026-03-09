// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * SecurityEngine Tests — patterns, redaction, 2FA, operations, default state
 */

import { assertEquals } from "jsr:@std/assert";
import {
  builtInPatterns,
  addPattern,
  removePattern,
  togglePattern,
  redactText,
  requires2FA,
  is2FAValid,
  isOperationAllowed,
  defaultState,
} from "../src/core/SecurityEngine.res.js";

// -- builtInPatterns --

Deno.test("builtInPatterns has 10 entries", () => {
  assertEquals(builtInPatterns.length, 10);
});

Deno.test("builtInPatterns first is anthropic-key", () => {
  assertEquals(builtInPatterns[0].id, "anthropic-key");
  assertEquals(builtInPatterns[0].enabled, true);
  assertEquals(builtInPatterns[0].builtIn, true);
});

// -- addPattern --

Deno.test("addPattern adds a custom pattern", () => {
  const custom = { id: "test", label: "Test", pattern: "abc", enabled: true, builtIn: false };
  const result = addPattern(defaultState, custom);
  assertEquals(result.patterns.length, defaultState.patterns.length + 1);
  assertEquals(result.patterns[result.patterns.length - 1].id, "test");
});

// -- removePattern --

Deno.test("removePattern does not remove built-in patterns", () => {
  const result = removePattern(defaultState, "anthropic-key");
  assertEquals(result.patterns.length, defaultState.patterns.length);
});

Deno.test("removePattern removes custom patterns", () => {
  const custom = { id: "custom1", label: "Custom", pattern: "x", enabled: true, builtIn: false };
  const withCustom = addPattern(defaultState, custom);
  const result = removePattern(withCustom, "custom1");
  assertEquals(result.patterns.length, defaultState.patterns.length);
});

// -- togglePattern --

Deno.test("togglePattern flips enabled flag", () => {
  const result = togglePattern(defaultState, "anthropic-key");
  const toggled = result.patterns.find(p => p.id === "anthropic-key");
  assertEquals(toggled.enabled, false);
});

// -- redactText --

Deno.test("redactText replaces sk-ant tokens", () => {
  const text = "key is sk-ant-abcdefghijklmnopqrstu";
  const result = redactText(text, builtInPatterns);
  assertEquals(result.includes("sk-ant-"), false);
});

Deno.test("redactText returns plain text unchanged", () => {
  const text = "hello world no secrets here";
  const result = redactText(text, builtInPatterns);
  assertEquals(result, "hello world no secrets here");
});

// -- requires2FA --

Deno.test("requires2FA returns false when no trustfile", () => {
  assertEquals(requires2FA(defaultState, "deploy"), false);
});

Deno.test("requires2FA returns true when trustfile has matching requirement", () => {
  const state = {
    ...defaultState,
    trustfile: {
      twoFactorRequirements: [{ operation: "deploy", required: true }],
      customPatterns: [],
      redactionMode: "RedactAlways",
    },
  };
  assertEquals(requires2FA(state, "deploy"), true);
});

// -- is2FAValid --

Deno.test("is2FAValid returns false when not configured", () => {
  assertEquals(is2FAValid(defaultState, Date.now()), false);
});

Deno.test("is2FAValid returns true when not expired", () => {
  const state = { ...defaultState, twoFactorStatus: { _0: Date.now() + 60000 } };
  assertEquals(is2FAValid(state, Date.now()), true);
});

// -- isOperationAllowed --

Deno.test("isOperationAllowed returns true when no 2FA needed", () => {
  assertEquals(isOperationAllowed(defaultState, "anything", Date.now()), true);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.patterns.length, 10);
  assertEquals(defaultState.detectedSecrets.length, 0);
  assertEquals(defaultState.redactionMode, "RedactOnShare");
  assertEquals(defaultState.vaultStatus, "VaultLocked");
  assertEquals(defaultState.shoulderSafe, false);
  assertEquals(defaultState.activeCategory, "SecurityOverview");
  assertEquals(defaultState.totpInput, "");
  assertEquals(defaultState.trustfile, undefined);
  assertEquals(defaultState.error, undefined);
});
