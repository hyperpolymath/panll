// SPDX-License-Identifier: MPL-2.0

/**
 * Tea_Render Tests - DOM rendering basics (simplified)
 *
 * Tests:
 * - State creation
 * - Cleanup function
 * - Basic mounting (when fully implemented)
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import { createState, cleanup } from "../src/tea/Tea_Render.res.js";

// Simple mock function
function createMock() {
  const calls = [];
  const fn = (...args) => {
    calls.push(args);
  };
  fn.calls = calls;
  fn.callCount = () => calls.length;
  return fn;
}

Deno.test("Tea_Render - creates render state", () => {
  const dispatch = createMock();
  const state = createState(dispatch);

  assertExists(state);
  assertEquals(state.listeners, []);
  assertEquals(state.dispatch, dispatch);
});

Deno.test("Tea_Render - cleanup removes all listeners", () => {
  const dispatch = createMock();
  const state = createState(dispatch);

  // Manually add a mock listener
  const mockListener = {
    element: {
      removeEventListener: createMock()
    },
    eventName: 'click',
    handler: () => {}
  };
  state.listeners.push(mockListener);

  cleanup(state);

  assertEquals(state.listeners.length, 0);
});

// Note: Full DOM rendering tests require complete Tea_Vdom implementation
// These will be added when the rendering pipeline is fully implemented
