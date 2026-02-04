// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * Tea_App Tests - Application runtime basics (simplified)
 *
 * Tests:
 * - Program creation
 * - Basic program structure
 */

import { describe, it, expect } from 'vitest';
import { simpleProgram, standardProgram } from '../src/tea/Tea_App.res.js';

describe('Tea_App - Application Runtime (Basics)', () => {
  describe('Program Creation', () => {
    it('exports simpleProgram function', () => {
      expect(typeof simpleProgram).toBe('function');
    });

    it('exports standardProgram function', () => {
      expect(typeof standardProgram).toBe('function');
    });
  });

  // Note: Full application lifecycle tests require:
  // 1. Complete Tea_Render implementation
  // 2. DOM mounting infrastructure
  // 3. Event loop setup
  // These will be added when the full TEA runtime is implemented
});
