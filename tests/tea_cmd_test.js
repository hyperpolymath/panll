// SPDX-License-Identifier: MPL-2.0

/**
 * Tea_Cmd Tests - Command execution and lifecycle
 *
 * Tests:
 * - Command creation (none, msg, batch, call)
 * - Command execution (sync and async)
 * - Command mapping (message type transformation)
 * - Batch command execution
 * - Async command with callbacks
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import { none, msg, batch, call, execute, map } from "../src/tea/Tea_Cmd.res.js";

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

Deno.test("Tea_Cmd - creates a None command", () => {
  const cmd = none;
  assertExists(cmd);
  assertEquals(cmd, "None");
});

Deno.test("Tea_Cmd - creates a Msg command", () => {
  const message = { type: 'TestMsg', value: 42 };
  const cmd = msg(message);

  assertExists(cmd);
  assertEquals(cmd.TAG, "Msg");
  assertEquals(cmd._0, message);
});

Deno.test("Tea_Cmd - creates a Batch command from multiple commands", () => {
  const msg1 = msg({ type: 'Msg1' });
  const msg2 = msg({ type: 'Msg2' });
  const cmd = batch(toList([msg1, msg2]));

  assertExists(cmd);
  if (cmd.TAG === "Batch") {
    assertEquals(cmd._0.length > 0, true);
  }
});

Deno.test("Tea_Cmd - creates a Call command with callback", () => {
  const callback = (callbacks) => {
    callbacks.enqueue({ type: 'AsyncResult' });
  };
  const cmd = call(callback);

  assertExists(cmd);
  assertEquals(cmd.TAG, "Call");
  assertEquals(typeof cmd._0, 'function');
});

Deno.test("Tea_Cmd - executes None command (no-op)", () => {
  const dispatch = createMock();
  execute(none, dispatch);

  assertEquals(dispatch.callCount(), 0);
});

Deno.test("Tea_Cmd - executes Msg command", () => {
  const message = { type: 'TestMsg', value: 42 };
  const dispatch = createMock();

  execute(msg(message), dispatch);

  assertEquals(dispatch.callCount(), 1);
  assertEquals(dispatch.calledWith(message), true);
});

Deno.test("Tea_Cmd - executes Batch command", () => {
  const msg1 = { type: 'Msg1' };
  const msg2 = { type: 'Msg2' };
  const msg3 = { type: 'Msg3' };
  const dispatch = createMock();

  const cmd = batch(toList([
    msg(msg1),
    msg(msg2),
    msg(msg3)
  ]));

  execute(cmd, dispatch);

  assertEquals(dispatch.callCount(), 3);
  assertEquals(dispatch.calledWith(msg1), true);
  assertEquals(dispatch.calledWith(msg2), true);
  assertEquals(dispatch.calledWith(msg3), true);
});

Deno.test("Tea_Cmd - executes Call command with async callback", async () => {
  const dispatch = createMock();

  const asyncCmd = call((callbacks) => {
    setTimeout(() => {
      callbacks.enqueue({ type: 'AsyncResult', value: 123 });
    }, 10);
  });

  execute(asyncCmd, dispatch);

  // Wait for async callback
  await new Promise(resolve => setTimeout(resolve, 50));

  assertEquals(dispatch.callCount(), 1);
  assertEquals(dispatch.calledWith({ type: 'AsyncResult', value: 123 }), true);
});

Deno.test("Tea_Cmd - maps message type in Msg command", () => {
  const originalMsg = { value: 42 };
  const cmd = msg(originalMsg);

  const mappedCmd = map(cmd, (m) => ({ transformed: m.value * 2 }));
  const dispatch = createMock();

  execute(mappedCmd, dispatch);

  assertEquals(dispatch.calledWith({ transformed: 84 }), true);
});

Deno.test("Tea_Cmd - maps message type in Batch command", () => {
  const cmd = batch(toList([
    msg({ value: 1 }),
    msg({ value: 2 })
  ]));

  const mappedCmd = map(cmd, (m) => ({ doubled: m.value * 2 }));
  const dispatch = createMock();

  execute(mappedCmd, dispatch);

  assertEquals(dispatch.callCount(), 2);
  assertEquals(dispatch.calledWith({ doubled: 2 }), true);
  assertEquals(dispatch.calledWith({ doubled: 4 }), true);
});

Deno.test("Tea_Cmd - handles empty batch command", () => {
  const dispatch = createMock();
  const cmd = batch(toList([]));

  execute(cmd, dispatch);

  assertEquals(dispatch.callCount(), 0);
});

Deno.test("Tea_Cmd - handles single-element batch", () => {
  const dispatch = createMock();
  const cmd = batch(toList([msg({ type: 'Single' })]));

  execute(cmd, dispatch);

  assertEquals(dispatch.callCount(), 1);
  assertEquals(dispatch.calledWith({ type: 'Single' }), true);
});

Deno.test("Tea_Cmd - handles nested Call commands", async () => {
  const dispatch = createMock();
  let callCount = 0;

  const nestedCmd = call((callbacks) => {
    callCount++;
    callbacks.enqueue({ level: 1 });

    setTimeout(() => {
      callCount++;
      callbacks.enqueue({ level: 2 });
    }, 10);
  });

  execute(nestedCmd, dispatch);

  // Wait for nested async
  await new Promise(resolve => setTimeout(resolve, 50));

  assertEquals(callCount, 2);
  assertEquals(dispatch.callCount(), 2);
});
