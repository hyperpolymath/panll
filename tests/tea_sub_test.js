// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * Tea_Sub Tests - Subscription lifecycle and cleanup
 *
 * Tests:
 * - Subscription creation (none, registration, batch)
 * - Subscription enabling (activation)
 * - Cleanup function execution
 * - Key extraction for diffing
 * - Memory leak prevention
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import { none, registration, batch, enable, getKeys, map } from "../src/tea/Tea_Sub.res.js";

// Helper to convert JS array to ReScript list
function toList(arr) {
  if (arr.length === 0) return 0;
  let result = 0;
  for (let i = arr.length - 1; i >= 0; i--) {
    result = { hd: arr[i], tl: result };
  }
  return result;
}

// Simple mock function
function createMock() {
  const calls = [];
  const fn = (...args) => {
    calls.push(args);
  };
  fn.calls = calls;
  fn.callCount = () => calls.length;
  fn.calledWith = (expected) => calls.some(args =>
    JSON.stringify(args[0]) === JSON.stringify(expected)
  );
  return fn;
}

Deno.test("Tea_Sub - creates a None subscription", () => {
  const sub = none;
  assertExists(sub);
  assertEquals(sub, "None");
});

Deno.test("Tea_Sub - creates a Registration subscription", () => {
  const enabler = () => () => {};
  const sub = registration('test-key', enabler);

  assertExists(sub);
  assertEquals(sub.TAG, "Registration");
  assertEquals(sub._0, 'test-key');
  assertEquals(typeof sub._1, 'function');
});

Deno.test("Tea_Sub - creates a Batch subscription", () => {
  const sub1 = registration('key1', () => () => {});
  const sub2 = registration('key2', () => () => {});

  const sub = batch(toList([sub1, sub2]));

  assertExists(sub);
  if (sub.TAG === "Batch") {
    assertEquals(sub._0.length, 2);
  }
});

Deno.test("Tea_Sub - enables None subscription (no-op)", () => {
  const dispatch = createMock();
  const cleanup = enable(none, dispatch);

  assertEquals(typeof cleanup, 'function');
  cleanup();
  assertEquals(dispatch.callCount(), 0);
});

Deno.test("Tea_Sub - enables Registration subscription", () => {
  const dispatch = createMock();
  const enabler = (dispatchFn) => {
    dispatchFn({ type: 'SubMsg' });
    return () => {};
  };

  const sub = registration('test', enabler);
  const cleanup = enable(sub, dispatch);

  assertEquals(dispatch.callCount(), 1);
  assertEquals(dispatch.calledWith({ type: 'SubMsg' }), true);
  assertEquals(typeof cleanup, 'function');

  cleanup();
});

Deno.test("Tea_Sub - enables Batch subscription", () => {
  const dispatch = createMock();
  let enabler1Called = false;
  let enabler2Called = false;

  const enabler1 = () => { enabler1Called = true; return () => {}; };
  const enabler2 = () => { enabler2Called = true; return () => {}; };

  const sub = batch(toList([
    registration('key1', enabler1),
    registration('key2', enabler2)
  ]));

  const cleanup = enable(sub, dispatch);

  assertEquals(enabler1Called, true);
  assertEquals(enabler2Called, true);
  assertEquals(typeof cleanup, 'function');

  cleanup();
});

Deno.test("Tea_Sub - executes cleanup function", () => {
  const dispatch = createMock();
  let cleanupCalled = false;
  const cleanupFn = () => { cleanupCalled = true; };
  const enabler = () => cleanupFn;

  const sub = registration('cleanup-test', enabler);
  const cleanup = enable(sub, dispatch);

  cleanup();

  assertEquals(cleanupCalled, true);
});

Deno.test("Tea_Sub - executes all cleanup functions in batch", () => {
  const dispatch = createMock();
  let cleanup1Called = false;
  let cleanup2Called = false;
  let cleanup3Called = false;

  const cleanup1 = () => { cleanup1Called = true; };
  const cleanup2 = () => { cleanup2Called = true; };
  const cleanup3 = () => { cleanup3Called = true; };

  const sub = batch(toList([
    registration('key1', () => cleanup1),
    registration('key2', () => cleanup2),
    registration('key3', () => cleanup3)
  ]));

  const cleanup = enable(sub, dispatch);
  cleanup();

  assertEquals(cleanup1Called, true);
  assertEquals(cleanup2Called, true);
  assertEquals(cleanup3Called, true);
});

Deno.test("Tea_Sub - prevents memory leaks with timers", async () => {
  const dispatch = createMock();
  let timerFired = false;

  const timerSub = registration('timer', (dispatchFn) => {
    const timerId = setTimeout(() => {
      timerFired = true;
      dispatchFn({ type: 'TimerFired' });
    }, 50);

    return () => clearTimeout(timerId);
  });

  const cleanup = enable(timerSub, dispatch);

  // Clean up immediately (before timer fires)
  cleanup();

  // Wait to ensure timer doesn't fire
  await new Promise(resolve => setTimeout(resolve, 100));

  assertEquals(timerFired, false);
  assertEquals(dispatch.callCount(), 0);
});

Deno.test("Tea_Sub - extracts empty array from None", () => {
  const keys = getKeys(none);
  assertEquals(keys, []);
});

Deno.test("Tea_Sub - extracts key from Registration", () => {
  const sub = registration('my-key', () => () => {});
  const keys = getKeys(sub);

  assertEquals(keys, ['my-key']);
});

Deno.test("Tea_Sub - extracts keys from Batch", () => {
  const sub = batch(toList([
    registration('key-a', () => () => {}),
    registration('key-b', () => () => {}),
    registration('key-c', () => () => {})
  ]));

  const keys = getKeys(sub);

  assertEquals(keys.includes('key-a'), true);
  assertEquals(keys.includes('key-b'), true);
  assertEquals(keys.includes('key-c'), true);
  assertEquals(keys.length, 3);
});

Deno.test("Tea_Sub - filters out None subscriptions in batch", () => {
  const sub = batch(toList([
    registration('key1', () => () => {}),
    none,
    registration('key2', () => () => {})
  ]));

  const keys = getKeys(sub);

  assertEquals(keys.includes('key1'), true);
  assertEquals(keys.includes('key2'), true);
  assertEquals(keys.length, 2);
});

Deno.test("Tea_Sub - maps message type in Registration", () => {
  const dispatch = createMock();
  const sub = registration('map-test', (dispatchFn) => {
    dispatchFn({ value: 10 });
    return () => {};
  });

  const mappedSub = map(sub, (msg) => ({ transformed: msg.value * 2 }));
  const cleanup = enable(mappedSub, dispatch);

  assertEquals(dispatch.calledWith({ transformed: 20 }), true);

  cleanup();
});

Deno.test("Tea_Sub - handles empty batch", () => {
  const dispatch = createMock();
  const sub = batch(toList([]));

  const cleanup = enable(sub, dispatch);
  cleanup();

  assertEquals(dispatch.callCount(), 0);
});

Deno.test("Tea_Sub - handles single-element batch", () => {
  const dispatch = createMock();
  const sub = batch(toList([
    registration('single', (d) => { d({ msg: 'test' }); return () => {}; })
  ]));

  const cleanup = enable(sub, dispatch);

  assertEquals(dispatch.calledWith({ msg: 'test' }), true);

  cleanup();
});
