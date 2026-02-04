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

import { describe, it, expect, vi, afterEach } from 'vitest';
import { none, registration, batch, enable, getKeys, map } from '../src/tea/Tea_Sub.res.js';

// Helper to convert JS array to ReScript list
function toList(arr) {
  if (arr.length === 0) return 0;
  let result = 0;
  for (let i = arr.length - 1; i >= 0; i--) {
    result = { hd: arr[i], tl: result };
  }
  return result;
}

describe('Tea_Sub - Subscription System', () => {
  let cleanupFunctions = [];

  afterEach(() => {
    // Clean up all subscriptions after each test
    cleanupFunctions.forEach(cleanup => cleanup());
    cleanupFunctions = [];
  });

  describe('Subscription Creation', () => {
    it('creates a None subscription', () => {
      const sub = none;
      expect(sub).toBeDefined();
      expect(sub).toBe("None"); // None is a string constant
    });

    it('creates a Registration subscription', () => {
      const enabler = vi.fn(() => () => {});
      const sub = registration('test-key', enabler);

      expect(sub).toBeDefined();
      expect(sub.TAG).toBe("Registration"); // String TAG
      expect(sub._0).toBe('test-key');
      expect(typeof sub._1).toBe('function');
    });

    it('creates a Batch subscription', () => {
      const sub1 = registration('key1', () => () => {});
      const sub2 = registration('key2', () => () => {});

      const sub = batch(toList([sub1, sub2])); // ReScript list format

      expect(sub).toBeDefined();
      if (sub.TAG === "Batch") { // String TAG
        expect(sub._0.length).toBe(2);
      }
    });
  });

  describe('Subscription Enabling', () => {
    it('enables None subscription (no-op)', () => {
      const dispatch = vi.fn();
      const cleanup = enable(none, dispatch);

      expect(typeof cleanup).toBe('function');
      cleanup(); // Should not throw
      expect(dispatch).not.toHaveBeenCalled();
    });

    it('enables Registration subscription', () => {
      const dispatch = vi.fn();
      const enabler = vi.fn((dispatchFn) => {
        dispatchFn({ type: 'SubMsg' });
        return () => {}; // cleanup
      });

      const sub = registration('test', enabler);
      const cleanup = enable(sub, dispatch);

      expect(enabler).toHaveBeenCalledWith(dispatch);
      expect(dispatch).toHaveBeenCalledWith({ type: 'SubMsg' });
      expect(typeof cleanup).toBe('function');

      cleanupFunctions.push(cleanup);
    });

    it('enables Batch subscription', () => {
      const dispatch = vi.fn();
      const enabler1 = vi.fn(() => () => {});
      const enabler2 = vi.fn(() => () => {});

      const sub = batch(toList([
        registration('key1', enabler1),
        registration('key2', enabler2)
      ]));

      const cleanup = enable(sub, dispatch);

      expect(enabler1).toHaveBeenCalled();
      expect(enabler2).toHaveBeenCalled();
      expect(typeof cleanup).toBe('function');

      cleanupFunctions.push(cleanup);
    });
  });

  describe('Subscription Cleanup', () => {
    it('executes cleanup function', () => {
      const dispatch = vi.fn();
      const cleanupFn = vi.fn();
      const enabler = vi.fn(() => cleanupFn);

      const sub = registration('cleanup-test', enabler);
      const cleanup = enable(sub, dispatch);

      cleanup();

      expect(cleanupFn).toHaveBeenCalled();
    });

    it('executes all cleanup functions in batch', () => {
      const dispatch = vi.fn();
      const cleanup1 = vi.fn();
      const cleanup2 = vi.fn();
      const cleanup3 = vi.fn();

      const sub = batch(toList([
        registration('key1', () => cleanup1),
        registration('key2', () => cleanup2),
        registration('key3', () => cleanup3)
      ]));

      const cleanup = enable(sub, dispatch);
      cleanup();

      expect(cleanup1).toHaveBeenCalled();
      expect(cleanup2).toHaveBeenCalled();
      expect(cleanup3).toHaveBeenCalled();
    });

    it('prevents memory leaks with timers', () => {
      return new Promise((resolve) => {
        const dispatch = vi.fn();
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
        setTimeout(() => {
          expect(timerFired).toBe(false);
          expect(dispatch).not.toHaveBeenCalled();
          resolve();
        }, 100);
      });
    });
  });

  describe('Key Extraction', () => {
    it('extracts empty array from None', () => {
      const keys = getKeys(none);
      expect(keys).toEqual([]);
    });

    it('extracts key from Registration', () => {
      const sub = registration('my-key', () => () => {});
      const keys = getKeys(sub);

      expect(keys).toEqual(['my-key']);
    });

    it('extracts keys from Batch', () => {
      const sub = batch(toList([
        registration('key-a', () => () => {}),
        registration('key-b', () => () => {}),
        registration('key-c', () => () => {})
      ]));

      const keys = getKeys(sub);

      expect(keys).toContain('key-a');
      expect(keys).toContain('key-b');
      expect(keys).toContain('key-c');
      expect(keys.length).toBe(3);
    });

    it('filters out None subscriptions in batch', () => {
      const sub = batch(toList([
        registration('key1', () => () => {}),
        none,
        registration('key2', () => () => {})
      ]));

      const keys = getKeys(sub);

      expect(keys).toEqual(expect.arrayContaining(['key1', 'key2']));
      expect(keys.length).toBe(2);
    });
  });

  describe('Subscription Mapping', () => {
    it('maps message type in Registration', () => {
      const dispatch = vi.fn();
      const sub = registration('map-test', (dispatchFn) => {
        dispatchFn({ value: 10 });
        return () => {};
      });

      const mappedSub = map(sub, (msg) => ({ transformed: msg.value * 2 }));
      const cleanup = enable(mappedSub, dispatch);

      expect(dispatch).toHaveBeenCalledWith({ transformed: 20 });

      cleanupFunctions.push(cleanup);
    });
  });

  describe('Edge Cases', () => {
    it('handles empty batch', () => {
      const dispatch = vi.fn();
      const sub = batch(toList([])); // Empty list

      const cleanup = enable(sub, dispatch);
      cleanup();

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('handles single-element batch (optimizes)', () => {
      const dispatch = vi.fn();
      const sub = batch(toList([
        registration('single', (d) => { d({ msg: 'test' }); return () => {}; })
      ]));

      const cleanup = enable(sub, dispatch);

      expect(dispatch).toHaveBeenCalledWith({ msg: 'test' });

      cleanupFunctions.push(cleanup);
    });
  });
});
