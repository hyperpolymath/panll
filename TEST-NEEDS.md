# TEST-NEEDS.md — panll

> Generated 2026-03-29 by punishing audit.

## Current State

| Category     | Count | Notes |
|-------------|-------|-------|
| Unit tests   | ~20   | JS engine tests: tentacles, network_topology, level_architect, cloudguard, security, ums, automation_router, accessibility, seam, focus_dimming, help, tiling, anti_crash, contractiles, orbital_sync, menu_bar |
| Integration  | ~6    | TEA framework: tea_app_test, tea_cmd_test, tea_sub_test, tea_render_test |
| E2E          | 0     | None |
| Benchmarks   | 0     | Files named "Workbench" are components, NOT benchmarks |

**Source modules:** ~686 ReScript .res files (not counting compiled .res.js). Massive TEA architecture with engines, models, views, components, core modules. Also: 116 Rust files, 15 Elixir, 5 Zig FFI, Idris2 ABI.

## What's Missing

### P2P (Property-Based) Tests
- [ ] TEA Model: property tests for state transition invariants
- [ ] Panel layout: property tests for tiling constraints (no overlapping, no gaps)
- [ ] Network topology: graph property tests (connectivity, acyclicity where required)
- [ ] Security engine: policy evaluation property tests

### E2E Tests
- [ ] Full panel lifecycle: create -> layout -> interact -> resize -> close
- [ ] Multi-panel: open multiple panels, tile, switch focus, close
- [ ] Accessibility: keyboard navigation through all panel types
- [ ] Theme/variant: each visual theme renders correctly
- [ ] Gossamer integration: panel communication round-trips

### Aspect Tests
- **Security:** 1 security_engine_test exists but for 686 modules — ZERO tests for panel isolation, IPC sanitization, plugin sandboxing
- **Performance:** ZERO benchmarks. No render frame budget tests, no panel creation overhead measurement, no memory leak detection for long-running sessions
- **Concurrency:** No tests for concurrent panel operations, WebSocket message ordering, subscription race conditions
- **Error handling:** 1 anti_crash_test exists. No tests for panel crash recovery, malformed IPC messages, subscription failure handling

### Build & Execution
- [ ] ReScript build (686 modules!)
- [ ] JS test runner for tests/
- [ ] Rust cargo test
- [ ] Elixir mix test

### Benchmarks Needed
- [ ] Panel creation/destruction time
- [ ] TEA update cycle latency
- [ ] Render time per panel type
- [ ] IPC message throughput
- [ ] Memory usage per panel count
- [ ] Layout algorithm time vs panel count

### Self-Tests
- [ ] Panel manifest validation
- [ ] TEA framework self-test (model/view/update cycle)
- [ ] Component registry consistency
- [ ] Accessibility compliance check (WCAG)

### CRITICAL GAPS

| Area | Modules | Tests | Coverage |
|------|---------|-------|----------|
| Components (.res) | ~200+ | 0 direct | **0%** |
| Core engines | ~50+ | ~16 | **~32%** |
| Models | ~100+ | 0 direct | **0%** |
| Views | ~100+ | 0 direct | **0%** |
| TEA framework | ~20 | 4 | **20%** |
| Rust crates | 116 files | 0 | **0%** |

## Priority

**CRITICAL.** 686 ReScript modules with ~26 test files is 3.8% coverage. The TEA engine tests are a good start but the component, model, and view layers are completely untested. 116 Rust files with ZERO tests. ZERO benchmarks for a UI framework where performance is user-visible. The "DebuggingWorkbench" and "ExploratoryWorkbench" files in bench results are components, not benchmarks — do not be fooled.

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
