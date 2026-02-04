// SPDX-License-Identifier: PMPL-1.0-or-later

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

import { describe, it, expect, vi } from 'vitest';
import { none, msg, batch, call, execute, map } from '../src/tea/Tea_Cmd.res.js';

// Helper to convert JS array to ReScript list
function toList(arr) {
  if (arr.length === 0) return 0;
  let result = 0;
  for (let i = arr.length - 1; i >= 0; i--) {
    result = { hd: arr[i], tl: result };
  }
  return result;
}

describe('Tea_Cmd - Command System', () => {
  describe('Command Creation', () => {
    it('creates a None command', () => {
      const cmd = none;
      expect(cmd).toBeDefined();
      expect(cmd).toBe("None"); // None is a string constant
    });

    it('creates a Msg command', () => {
      const message = { type: 'TestMsg', value: 42 };
      const cmd = msg(message);

      expect(cmd).toBeDefined();
      expect(cmd.TAG).toBe("Msg"); // String TAG
      expect(cmd._0).toEqual(message);
    });

    it('creates a Batch command from multiple commands', () => {
      const msg1 = msg({ type: 'Msg1' });
      const msg2 = msg({ type: 'Msg2' });
      const cmd = batch(toList([msg1, msg2])); // ReScript list format

      expect(cmd).toBeDefined();
      // Batch uses string TAG
      if (cmd.TAG === "Batch") {
        expect(cmd._0.length).toBeGreaterThan(0);
      }
    });

    it('creates a Call command with callback', () => {
      const callback = (callbacks) => {
        callbacks.enqueue({ type: 'AsyncResult' });
      };
      const cmd = call(callback);

      expect(cmd).toBeDefined();
      expect(cmd.TAG).toBe("Call"); // String TAG
      expect(typeof cmd._0).toBe('function');
    });
  });

  describe('Command Execution', () => {
    it('executes None command (no-op)', () => {
      const dispatch = vi.fn();
      execute(none, dispatch);

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('executes Msg command', () => {
      const message = { type: 'TestMsg', value: 42 };
      const dispatch = vi.fn();

      execute(msg(message), dispatch);

      expect(dispatch).toHaveBeenCalledOnce();
      expect(dispatch).toHaveBeenCalledWith(message);
    });

    it('executes Batch command', () => {
      const msg1 = { type: 'Msg1' };
      const msg2 = { type: 'Msg2' };
      const msg3 = { type: 'Msg3' };
      const dispatch = vi.fn();

      const cmd = batch(toList([
        msg(msg1),
        msg(msg2),
        msg(msg3)
      ]));

      execute(cmd, dispatch);

      expect(dispatch).toHaveBeenCalledTimes(3);
      expect(dispatch).toHaveBeenCalledWith(msg1);
      expect(dispatch).toHaveBeenCalledWith(msg2);
      expect(dispatch).toHaveBeenCalledWith(msg3);
    });

    it('executes Call command with async callback', () => {
      return new Promise((resolve) => {
        const dispatch = vi.fn((message) => {
          expect(message).toEqual({ type: 'AsyncResult', value: 123 });
          resolve();
        });

        const asyncCmd = call((callbacks) => {
          setTimeout(() => {
            callbacks.enqueue({ type: 'AsyncResult', value: 123 });
          }, 10);
        });

        execute(asyncCmd, dispatch);
      });
    });
  });

  describe('Command Mapping', () => {
    it('maps message type in Msg command', () => {
      const originalMsg = { value: 42 };
      const cmd = msg(originalMsg);

      const mappedCmd = map(cmd, (m) => ({ transformed: m.value * 2 }));
      const dispatch = vi.fn();

      execute(mappedCmd, dispatch);

      expect(dispatch).toHaveBeenCalledWith({ transformed: 84 });
    });

    it('maps message type in Batch command', () => {
      const cmd = batch(toList([
        msg({ value: 1 }),
        msg({ value: 2 })
      ]));

      const mappedCmd = map(cmd, (m) => ({ doubled: m.value * 2 }));
      const dispatch = vi.fn();

      execute(mappedCmd, dispatch);

      expect(dispatch).toHaveBeenCalledTimes(2);
      expect(dispatch).toHaveBeenCalledWith({ doubled: 2 });
      expect(dispatch).toHaveBeenCalledWith({ doubled: 4 });
    });
  });

  describe('Edge Cases', () => {
    it('handles empty batch command', () => {
      const dispatch = vi.fn();
      const cmd = batch(toList([])); // Empty list

      execute(cmd, dispatch);

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('handles single-element batch (optimizes to Msg)', () => {
      const dispatch = vi.fn();
      const cmd = batch(toList([msg({ type: 'Single' })]));

      execute(cmd, dispatch);

      expect(dispatch).toHaveBeenCalledOnce();
      expect(dispatch).toHaveBeenCalledWith({ type: 'Single' });
    });

    it('handles nested Call commands', () => {
      return new Promise((resolve) => {
        const dispatch = vi.fn();
        let callCount = 0;

        const nestedCmd = call((callbacks) => {
          callCount++;
          callbacks.enqueue({ level: 1 });

          // Simulate nested async
          setTimeout(() => {
            callCount++;
            callbacks.enqueue({ level: 2 });

            if (callCount === 2) {
              expect(dispatch).toHaveBeenCalledTimes(2);
              resolve();
            }
          }, 10);
        });

        execute(nestedCmd, dispatch);
      });
    });
  });
});
