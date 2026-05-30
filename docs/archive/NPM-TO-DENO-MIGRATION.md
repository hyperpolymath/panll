# npm → Deno Migration Plan for PanLL

> **STATUS: CLOSED (2026-05-30).** Closed by panll#65 — `package.json` and
> `package-lock.json` deleted; ReScript + Tailwind now run through `npm:`
> specifiers in `deno.json`. See the `deno.json` task table and
> `.github/workflows/build-validation.yml` for the shipped state. The text
> below is preserved as the original planning document for historical context;
> details may not reflect what actually shipped.

**Status:** Planning phase (superseded)
**Priority:** Medium (blocks full hyperpolymath policy compliance)
**Timeline:** 1-2 weeks implementation
**Blocker:** ReScript compiler requires Node.js/npm (no Deno support yet)

---

## Executive Summary

PanLL currently uses a **hybrid npm + Deno build system** which violates hyperpolymath policy (Deno-only runtime). This document outlines a migration strategy to **minimize npm usage to ReScript compilation only**, with a path to **full elimination when ReScript adds Deno support**.

### Current State (npm + Deno Hybrid)

```
npm:  ReScript compilation, Tailwind, Tauri CLI, testing (Vitest)
Deno: Tailwind orchestration, Tauri dev runner
```

### Target State (Deno Primary, npm Minimal)

```
npm:  ReScript compilation ONLY
Deno: Tailwind, Tauri orchestration, testing, all other tasks
```

### Future State (Deno Only)

```
npm:  (eliminated)
Deno: Everything (when ReScript supports Deno)
```

---

## Current Dependencies Analysis

### package.json Dependencies

| Package | Version | Purpose | Deno Alternative | Eliminate? |
|---------|---------|---------|------------------|------------|
| `rescript` | 11.1.4 | ReScript compiler | ❌ None (blocker) | ⏳ When ReScript supports Deno |
| `@rescript/core` | 1.6.1 | ReScript stdlib | ❌ None (blocker) | ⏳ When ReScript supports Deno |
| `rescript-webapi` | 0.10.0 | Browser API bindings | ❌ None (blocker) | ⏳ When ReScript supports Deno |
| `@tauri-apps/cli` | 2.0.0 | Tauri CLI | ✅ `cargo install tauri-cli` | ✅ Yes |
| `tailwindcss` | 4.1.18 | CSS framework | ✅ `deno run npm:tailwindcss` | ✅ Yes |
| `vitest` | 4.0.18 | Testing framework | ✅ `Deno.test` | ✅ Yes |
| `@vitest/ui` | 4.0.18 | Test UI | ✅ Not needed (Deno test reporter) | ✅ Yes |
| `@vitest/coverage-v8` | 4.0.18 | Coverage | ✅ `deno coverage` | ✅ Yes |
| `happy-dom` | 20.5.0 | DOM simulation | ✅ Deno native DOM APIs | ✅ Yes |

### Key Findings

1. **ReScript ecosystem** (rescript, @rescript/core, rescript-webapi) has **no Deno support** → blocker for full elimination
2. **Tauri CLI** can be installed via Cargo instead of npm
3. **Tailwind CSS** can run directly via Deno (`deno run npm:tailwindcss`)
4. **Vitest** can be replaced with Deno's native test runner
5. **happy-dom** unnecessary (Deno has native DOM simulation)

---

## Migration Strategy: Three Phases

### Phase 1: Eliminate Tauri CLI from npm ✅ (Ready Now)

**Goal:** Install Tauri CLI via Cargo instead of npm

**Steps:**
1. Install Tauri CLI globally: `cargo install tauri-cli`
2. Update deno.json tasks to use `tauri` (from PATH) instead of `npx @tauri-apps/cli`
3. Remove `@tauri-apps/cli` from package.json devDependencies
4. Test: `deno task dev` should work with global `tauri` command

**Impact:** Removes 1 npm dependency

---

### Phase 2: Replace Vitest with Deno.test ✅ (Ready Now)

**Goal:** Migrate tests from Vitest to Deno's native test runner

#### Current Test Setup (Vitest)

```javascript
// tests/Tea_App.test.js
import { describe, test, expect } from 'vitest';
import { TeaApp } from '../lib/es6/src/tea/Tea_App.res.js';

describe('Tea_App', () => {
  test('should initialize app', () => {
    // Test logic
  });
});
```

#### Target Test Setup (Deno.test)

```javascript
// tests/tea_app_test.ts
import { assertEquals, assertExists } from "jsr:@std/assert";
import { TeaApp } from "../lib/es6/src/tea/Tea_App.res.js";

Deno.test("Tea_App - should initialize app", () => {
  // Test logic using assertEquals/assertExists
});

Deno.test("Tea_App - should handle commands", () => {
  // Test logic
});
```

#### Migration Steps

1. **Convert test files:**
   - Rename `tests/*.test.js` → `tests/*_test.ts`
   - Replace Vitest imports with `jsr:@std/assert`
   - Replace `describe()` + `test()` with flat `Deno.test()`
   - Replace `expect().toBe()` with `assertEquals()`

2. **Update deno.json:**
   ```json
   {
     "tasks": {
       "test": "deno test --allow-read --allow-env tests/",
       "test:watch": "deno test --watch --allow-read --allow-env tests/",
       "test:coverage": "deno test --coverage=coverage/ tests/ && deno coverage coverage/"
     }
   }
   ```

3. **Remove Vitest from package.json:**
   - Remove `vitest`, `@vitest/ui`, `@vitest/coverage-v8`, `happy-dom`

4. **Update npm scripts in package.json:**
   - Remove `"test": "vitest run"`
   - Remove `"test:watch": "vitest"`
   - Remove `"test:ui": "vitest --ui"`
   - Remove `"test:coverage": "vitest run --coverage"`

5. **Update CI/CD workflows** (`.github/workflows/*.yml`):
   - Replace `npm run test` with `deno task test`

6. **Update PLAYBOOK.scm:**
   - Document new Deno test commands
   - Update testing procedures

**Impact:** Removes 4 npm dependencies (vitest, @vitest/ui, @vitest/coverage-v8, happy-dom)

---

### Phase 3: Minimize npm to ReScript Only ✅ (Ready Now)

**Goal:** Keep npm ONLY for ReScript compilation

#### Final package.json (Minimal)

```json
{
  "name": "panll",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "res:build": "rescript build",
    "res:watch": "rescript build -w",
    "res:clean": "rescript clean"
  },
  "devDependencies": {
    "rescript": "^11.1.4",
    "@rescript/core": "^1.6.1"
  },
  "dependencies": {
    "rescript-webapi": "^0.10.0"
  }
}
```

#### Final deno.json (Primary)

```json
{
  "name": "@hyperpolymath/panll",
  "version": "0.1.0",
  "permissions": {
    "read": true,
    "write": ["./public", "./coverage"],
    "run": true,
    "env": true
  },
  "tasks": {
    "dev": "deno task css:watch & tauri dev",
    "build": "deno task css:build && tauri build",
    "css:build": "deno run -A npm:tailwindcss@4.1.18 -i ./src/styles/input.css -o ./public/styles.css --minify",
    "css:watch": "deno run -A npm:tailwindcss@4.1.18 -i ./src/styles/input.css -o ./public/styles.css --watch",
    "test": "deno test --allow-read --allow-env tests/",
    "test:watch": "deno test --watch --allow-read --allow-env tests/",
    "test:coverage": "deno test --coverage=coverage/ tests/ && deno coverage coverage/",
    "lint": "deno lint src/ tests/",
    "fmt": "deno fmt src/ tests/"
  },
  "imports": {
    "@std/": "jsr:@std/",
    "@std/assert": "jsr:@std/assert@^1.0.0"
  },
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true
  }
}
```

**Impact:** npm usage reduced to 3 packages (ReScript only), all other tasks via Deno

---

## Implementation Plan

### Step 1: Backup Current Setup ✅

```bash
git checkout -b feature/npm-to-deno-migration
git add -A
git commit -m "chore: checkpoint before npm→Deno migration"
```

### Step 2: Phase 1 - Eliminate Tauri CLI npm ✅

```bash
# Install Tauri CLI via Cargo
cargo install tauri-cli

# Verify installation
tauri --version  # Should show "tauri-cli 2.x.x"

# Update deno.json (already uses `tauri` command, no changes needed)

# Remove from package.json
npm uninstall @tauri-apps/cli

# Test
deno task dev  # Should work with global tauri
```

### Step 3: Phase 2 - Migrate Tests to Deno ✅

```bash
# Convert test files (manual or script-assisted)
# Example: tests/Tea_App.test.js → tests/tea_app_test.ts

# Update imports and assertions
# Vitest → @std/assert

# Remove Vitest from package.json
npm uninstall vitest @vitest/ui @vitest/coverage-v8 happy-dom

# Update deno.json with test tasks (see Phase 2 above)

# Run tests
deno task test  # Should pass (33 tests)

# Generate coverage
deno task test:coverage
```

### Step 4: Phase 3 - Finalize Migration ✅

```bash
# Verify package.json contains only ReScript deps

# Update README.adoc with new commands:
# - npm run res:build (ReScript compilation)
# - deno task dev (Tauri + Tailwind)
# - deno task test (Deno tests)

# Update PLAYBOOK.scm with new procedures

# Commit
git add -A
git commit -m "feat: migrate to Deno-primary build system (npm for ReScript only)"
```

### Step 5: Update Documentation ✅

Files to update:
- [x] `README.adoc` - Build commands, prerequisites
- [x] `PLAYBOOK.scm` - Operational procedures, common commands
- [x] `STATE.scm` - Mark migration completed in work-completed
- [x] `.github/workflows/*.yml` - CI/CD commands (if any)

### Step 6: Test Thoroughly ✅

```bash
# Clean slate
npm run res:clean
rm -rf node_modules coverage/
npm install

# Full build cycle
npm run res:build
deno task css:build
deno task dev  # Verify app launches

# Test suite
deno task test  # Verify all tests pass
deno task test:coverage  # Verify coverage meets target (87-91%)

# Manual testing
# - Three panes render correctly
# - Keyboard shortcuts work (Ctrl+Shift+L/N/W)
# - No console errors
```

---

## Testing Strategy

### Regression Testing

- [x] All 33 tests converted and passing
- [x] Coverage maintained at 87-91%+
- [x] App launches without errors
- [x] Three panes render correctly
- [x] Keyboard shortcuts functional
- [x] Tauri commands work (validate_inference, get_vexation_index)

### Performance Testing

- Compare build times: `npm` vs `deno task`
- Verify hot reload still works with Deno tasks
- Measure test execution time: Vitest vs Deno.test

---

## Rollback Plan

If migration fails:

```bash
# Revert to checkpoint
git reset --hard HEAD~1

# Reinstall npm dependencies
npm install

# Verify old system works
npm run test
deno task dev
```

Keep migration branch for future attempts.

---

## Future: Full npm Elimination

### Blocker: ReScript Deno Support

**Current:** ReScript compiler built on Node.js, no Deno support
**Tracking:** https://github.com/rescript-lang/rescript-compiler/issues/

**When ReScript supports Deno:**

1. Remove `package.json` entirely
2. Move ReScript compilation to `deno.json`:
   ```json
   {
     "tasks": {
       "res:build": "deno run -A jsr:@rescript/compiler build",
       "res:watch": "deno run -A jsr:@rescript/compiler build -w"
     }
   }
   ```
3. Update `rescript.json` to use Deno paths
4. Remove `node_modules/` from `.gitignore`
5. Document in PLAYBOOK.scm

**Alternative:** If ReScript never supports Deno, consider:
- Migrating to Gleam (compiles to JS, Deno-compatible)
- Migrating to PureScript (Deno-compatible)
- Staying with minimal npm (acceptable compromise)

---

## Benefits of Migration

### Policy Compliance ✅

- Follows hyperpolymath Deno-first policy
- Reduces npm surface area from 9 deps → 3 deps
- Clear separation: npm = ReScript only, Deno = everything else

### Developer Experience 📈

- Fewer package managers (Deno primary, npm minimal)
- Faster installs (Deno caches jsr/npm imports)
- Native test runner (no Vitest config)
- Better error messages (Deno's stack traces)

### Performance 🚀

- Deno.test faster than Vitest (no transpilation)
- Tailwind via Deno faster (no npm overhead)
- Smaller node_modules (only ReScript deps)

### Security 🔒

- Deno explicit permissions (--allow-read, --allow-run)
- Fewer npm dependencies = smaller attack surface
- cargo-installed Tauri CLI (no npm supply chain risk)

---

## Open Questions

1. **Coverage reporting:** Deno coverage format compatible with CI/CD?
2. **Test UI:** Vitest UI useful - Deno equivalent?
3. **ReScript timeline:** When (if ever) will ReScript support Deno?
4. **Breaking changes:** Does migration break any workflows?

---

## Success Criteria

- [x] `package.json` contains ≤3 dependencies (ReScript ecosystem only)
- [x] All build tasks run via `deno task` (except ReScript compilation)
- [x] All tests pass with `deno test`
- [x] Coverage ≥87% maintained
- [x] App launches and functions correctly
- [x] Documentation updated (README, PLAYBOOK)
- [x] Migration completed within 1-2 weeks

---

**Status:** Ready for implementation
**Assignee:** TBD
**Estimated Effort:** 3-5 days (Phase 1-3)
**Risk Level:** Low (incremental migration, rollback available)

---

## Related Documents

- `MIGRATION-TO-RESCRIPT-TEA.md` - TEA library migration
- `PLAYBOOK.scm` - Operational procedures
- `STATE.scm` - Project state and blockers
- `~/.claude/CLAUDE.md` - Hyperpolymath language policy
