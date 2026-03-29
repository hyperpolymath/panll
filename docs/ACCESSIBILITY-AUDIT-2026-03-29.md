<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- Accessibility Audit — 2026-03-29 -->

# PanLL Accessibility Audit

**Date:** 2026-03-29
**Auditor:** Claude (automated scan) — manual testing with NVDA/Orca still needed
**Scope:** All 123 component files in src/components/, supporting engines, tests

## Summary

| Metric | Count | Rating |
|--------|-------|--------|
| Components with ariaLabel | 91/123 | Good (74%) |
| Components with role attributes | 90/123 | Good (73%) |
| Components with keyboard handlers | 1/123 | Critical gap |
| Components with tabIndex | 2/123 | Critical gap |
| aria-live regions | 7 total | Poor |
| sr-only screen reader text | 1 (skip-links only) | Poor |
| ariaDescribedBy / ariaLabelledBy | 8 total | Poor |
| Colour palettes defined | 4 | Complete |
| Font size presets | 4 (14-20px) | Complete |
| Focus style options | 4 | Complete |
| Accessibility engine tests | 30+ | Complete |

## Architecture (Excellent)

PanLL has dedicated accessibility infrastructure:
- `AccessibilityEngine.res` — theme, palette, animation, font, focus
- `AccessibilityModel.res` — type-safe state
- `AccessibilityToolbar.res` — floating FAB widget
- `FocusDimmingEngine.res` — focus indicator styling
- `KeyboardUtil.res` — keyboard utilities
- `accessibility-baseline.k9.ncl` — K9 validator contract

## Critical Gaps

### 1. Keyboard Navigation (Priority 1)

Only 1 of 123 components (MyLang.res) has keyboard event handlers.
All interactive panels need:
- Enter/Space to activate buttons
- Arrow keys for lists/tabs
- Escape to close overlays

**Remediation:** Add a `KeyboardNav.res` utility module with standard handlers
that components can compose. Target: all 108 panels keyboard-navigable.

### 2. Tab Order (Priority 1)

Only 2 components use tabIndex. Custom interactive elements are invisible
to keyboard users.

**Remediation:** Add `Attrs.tabIndex(0)` to all custom interactive elements.
Add `Attrs.tabIndex(-1)` to programmatically focusable containers.

### 3. Live Regions (Priority 2)

Only 7 aria-live regions across 108+ panels. Status changes, form validation,
and dynamic content updates are silent to screen readers.

**Remediation:** Add `aria-live="polite"` to status bars, notification areas,
and VQL result displays. Add `aria-live="assertive"` to error messages.

### 4. Screen Reader Text (Priority 2)

Only 1 sr-only instance (skip-links). Icon-only buttons, data visualizations,
and status indicators lack text alternatives.

**Remediation:** Add sr-only labels to icon buttons and decorative elements
that carry meaning.

### 5. Complex Relationships (Priority 3)

Only 8 ariaDescribedBy/ariaLabelledBy instances. Form fields, error messages,
and complex controls need semantic linking.

## What's Already Working

- 4 colour palettes (Standard, Deuteranopia, Protanopia, High Contrast)
- Scalable font sizes (14-20px presets, rem-based)
- Reduced motion detection and respect
- Focus indicator options (Default, High Contrast, Thick, Dotted)
- OS theme preference detection (System mode)
- Floating accessibility toolbar (non-intrusive FAB)
- 30+ engine-level tests for preference persistence

## DD-008 Compliance

| Level | Criteria | Status |
|-------|----------|--------|
| Baseline | ariaLabel + role per component | 90/123 (73%) |
| Full | Baseline + keyboard + tabIndex | ~3/123 (~2%) |
| Target | Full + aria-live + sr-only | 0% |

## Next Steps

1. Create `KeyboardNav.res` utility with composable keyboard handlers
2. Add tabIndex to all custom interactive elements
3. Add aria-live regions to status-changing areas
4. Add sr-only labels to icon-only buttons
5. Manual testing with NVDA/Orca (requires Jonathan)
6. Update K9 validator to enforce full compliance
