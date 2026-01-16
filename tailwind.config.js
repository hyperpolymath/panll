// SPDX-License-Identifier: AGPL-3.0-or-later

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./src/**/*.res",
    "./src/**/*.res.js",
    "./public/**/*.html",
  ],
  theme: {
    extend: {
      colors: {
        // PanLL colour palette - "Memory Foam" aesthetic
        // Indigo: Symbolic/Logic (Pane-L)
        // Emerald: Neural/Inference (Pane-N)
        // Gray: Neutral/Shared (Pane-W)
        panll: {
          symbolic: {
            50: '#eef2ff',
            100: '#e0e7ff',
            200: '#c7d2fe',
            300: '#a5b4fc',
            400: '#818cf8',
            500: '#6366f1',
            600: '#4f46e5',
            700: '#4338ca',
            800: '#3730a3',
            900: '#312e81',
            950: '#1e1b4b',
          },
          neural: {
            50: '#ecfdf5',
            100: '#d1fae5',
            200: '#a7f3d0',
            300: '#6ee7b7',
            400: '#34d399',
            500: '#10b981',
            600: '#059669',
            700: '#047857',
            800: '#065f46',
            900: '#064e3b',
            950: '#022c22',
          },
        },
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      animation: {
        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'drift-aura': 'driftAura 8s ease-in-out infinite',
      },
      keyframes: {
        driftAura: {
          '0%, 100%': { opacity: '0.2' },
          '50%': { opacity: '0.3' },
        },
      },
    },
  },
  plugins: [],
}
