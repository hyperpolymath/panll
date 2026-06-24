// SPDX-License-Identifier: MPL-2.0

/**
 * Tea_App Tests - Application runtime basics (simplified)
 *
 * Tests:
 * - Program creation
 * - Basic program structure
 */

import { assertEquals } from "jsr:@std/assert";
import { simpleProgram, standardProgram } from "../src/tea/Tea_App.res.js";

Deno.test("Tea_App - simpleProgram function exists", () => {
  assertEquals(typeof simpleProgram, "function");
});

Deno.test("Tea_App - standardProgram function exists", () => {
  assertEquals(typeof standardProgram, "function");
});

// Note: Full application lifecycle tests require:
// 1. Complete Tea_Render implementation
// 2. DOM mounting infrastructure
// 3. Event loop setup
// These will be added when the full TEA runtime is implemented
