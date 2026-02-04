// SPDX-License-Identifier: PMPL-1.0-or-later

import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'happy-dom',
    include: ['tests/**/*.test.{js,mjs,ts}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.res.js'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.spec.js',
        'src/**/*.test.js',
      ],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70,
      },
    },
  },
});
