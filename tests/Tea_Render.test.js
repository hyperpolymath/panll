// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * Tea_Render Tests - DOM rendering basics (simplified)
 *
 * Tests:
 * - State creation
 * - Cleanup function
 * - Basic mounting (when fully implemented)
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { createState, cleanup } from '../src/tea/Tea_Render.res.js';

describe('Tea_Render - DOM Rendering System (Basics)', () => {
  let dispatch;

  beforeEach(() => {
    dispatch = vi.fn();
  });

  afterEach(() => {
    dispatch = null;
  });

  describe('State Management', () => {
    it('creates render state', () => {
      const state = createState(dispatch);

      expect(state).toBeDefined();
      expect(state.listeners).toEqual([]);
      expect(state.dispatch).toBe(dispatch);
    });

    it('cleanup removes all listeners', () => {
      const state = createState(dispatch);

      // Manually add a mock listener
      const mockListener = {
        element: { removeEventListener: vi.fn() },
        eventName: 'click',
        handler: () => {}
      };
      state.listeners.push(mockListener);

      cleanup(state);

      expect(state.listeners.length).toBe(0);
    });
  });

  // Note: Full DOM rendering tests require complete Tea_Vdom implementation
  // These will be added when the rendering pipeline is fully implemented
});
