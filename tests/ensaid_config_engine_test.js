// SPDX-License-Identifier: MPL-2.0

/**
 * EnsaidConfigEngine Tests — enum-to-string conversions
 */

import { assertEquals } from "jsr:@std/assert";
import {
  isolationToString,
  workspaceModeToString,
  protectionToString,
  executionModeToString,
} from "../src/core/EnsaidConfigEngine.res.js";

// -- isolationToString --

Deno.test("isolationToString - Native", () => {
  assertEquals(isolationToString("Native"), "native");
});

Deno.test("isolationToString - StandardPod", () => {
  assertEquals(isolationToString("StandardPod"), "container");
});

Deno.test("isolationToString - HardenedPod", () => {
  assertEquals(isolationToString("HardenedPod"), "vm");
});

// -- workspaceModeToString --

Deno.test("workspaceModeToString - RhodiumMode", () => {
  assertEquals(workspaceModeToString("RhodiumMode"), "rhodium");
});

Deno.test("workspaceModeToString - EverythingMode", () => {
  assertEquals(workspaceModeToString("EverythingMode"), "everything");
});

Deno.test("workspaceModeToString - CodeMode", () => {
  assertEquals(workspaceModeToString("CodeMode"), "code");
});

Deno.test("workspaceModeToString - BespokeMode", () => {
  assertEquals(workspaceModeToString("BespokeMode"), "bespoke");
});

// -- protectionToString --

Deno.test("protectionToString - Open", () => {
  assertEquals(protectionToString("Open"), "open");
});

Deno.test("protectionToString - ReadOnly", () => {
  assertEquals(protectionToString("ReadOnly"), "readonly");
});

Deno.test("protectionToString - Sandboxed", () => {
  assertEquals(protectionToString("Sandboxed"), "sandboxed");
});

Deno.test("protectionToString - LanguageLocked", () => {
  assertEquals(
    protectionToString({ TAG: "LanguageLocked", _0: "rescript" }),
    "language-locked",
  );
});

Deno.test("protectionToString - TranspilationGuarded", () => {
  assertEquals(
    protectionToString("TranspilationGuarded"),
    "transpilation-guarded",
  );
});

Deno.test("protectionToString - ProductionGated", () => {
  assertEquals(protectionToString("ProductionGated"), "production-gated");
});

// -- executionModeToString --

Deno.test("executionModeToString - Live", () => {
  assertEquals(executionModeToString("Live"), "live");
});

Deno.test("executionModeToString - DryRun", () => {
  assertEquals(executionModeToString("DryRun"), "dry-run");
});

Deno.test("executionModeToString - Simulation", () => {
  assertEquals(executionModeToString("Simulation"), "simulation");
});

Deno.test("executionModeToString - Emulation", () => {
  assertEquals(executionModeToString("Emulation"), "emulation");
});
