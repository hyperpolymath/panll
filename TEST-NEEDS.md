# TEST-NEEDS.md — panll

> Generated 2026-03-29 by punishing audit. Updated 2026-04-04 by CRG C blitz.

## Current State

| Category     | Count | Notes |
|-------------|-------|-------|
| Unit tests   | ~120  | JS engine tests + Rust type tests |
| Integration  | ~6    | TEA framework: tea_app_test, tea_cmd_test, tea_sub_test, tea_render_test |
| E2E          | 47    | e2e_panel_lifecycle_test.js (comprehensive lifecycle + TypeLL + cross-panel) |
| Benchmarks   | 35+   | engine_bench_test, tea_update_cycle_bench_test, safedom_bench_test, panic_attack_bench_test + benches/panll_bench.js |
| P2P          | 23    | tests/p2p/tea_properties_test.mjs — TEA invariants, layout no-overlap, IPC roundtrip |
| Aspect       | 36    | tests/aspect/security_test.mjs — IPC sanitation, plugin sandboxing, redaction, XSS |
| Contract     | 30    | tests/contract/panel_contracts_test.mjs — C1-C9 governance contracts |
| Reflexive    | 22    | tests/reflexive/manifest_test.mjs — manifest consistency, export verification |
| Rust smoke   | 267   | All Rust tests pass (267 total). New smoke tests in: security, capture, farm, minter, plaza, watcher, workspace, ai, cloudguard, voicetag, hypatia |

**Source modules:** ~686 ReScript .res files. 116 Rust files (all previously-untested crates now have smoke tests).

## What Was Added (2026-04-04 CRG C Blitz)

### Benchmarks
- [x] `benches/panll_bench.js` — standalone bench file (4 groups × 8 benches):
  - TEA update cycle latency (NoOp baseline, AddConstraint, AntiCrash, 100-msg load)
  - Panel creation/destruction time (Model.init, ResetAllPanels, registry lookups, TogglePanel)
  - IPC message throughput (PanelBus, JSON round-trips, AntiCrash pipeline)
  - Layout algorithm time vs panel count (1, 4, 9, 16, 36, 108 panels)
- [x] `deno task bench` added to deno.json

### P2P Property-Based Tests
- [x] `tests/p2p/tea_properties_test.mjs` — 8 properties × 100 random trials each:
  - update(msg, model) always produces valid model shape
  - TilingEngine.tile produces non-overlapping panels with positive dimensions
  - IPC JSON round-trip structural equality
  - AntiCrash halted flag monotonicity
  - Vexometer index non-decreasing
  - Contractiles.evaluateAll never throws (totality)
  - PanelRegistry findPanel/allPanels inverse consistency
  - TypeLL serviceActive always boolean

### Aspect Tests
- [x] `tests/aspect/security_test.mjs` — 36 tests:
  - Panel IPC sanitization (malformed TAGs, null payloads, empty objects)
  - Plugin sandboxing (CloudGuard cannot modify paneL, Farm cannot modify cloudguard, etc.)
  - Anti-Crash circuit breaker (processToken, checkSecurityConstraints)
  - Redaction engine (Anthropic, OpenAI, GitHub tokens; idempotency; safe content preservation)
  - XSS/injection resistance (script tags, javascript: URIs, onerror, onload, 1MB rejection)
  - Governance range invariants (vexometer [0,1], orbital [0,1])

### Contract Tests
- [x] `tests/contract/panel_contracts_test.mjs` — 30 tests across 9 contracts:
  - C1: Orbital Stability Contract (threshold 0.7)
  - C2: Vexation Ceiling Contract
  - C3: Anti-Crash Quorum Contract (violations ≤ 10)
  - C5: TypeLL Service Contract (queriesServed increments on Ok)
  - C6: Panel Bus Contract (registry, topics, subscribers)
  - C7: Model Initialisation Contract (11 default contractiles)
  - C8: Governance Engine Contract
  - C9: Contractiles Elasticity Adaptation Contract

### Reflexive Tests
- [x] `tests/reflexive/manifest_test.mjs` — 22 tests:
  - AI manifest claims vs PanelRegistry reality
  - Panel count, ID uniqueness, clade coverage
  - All core engine module exports verified (11 engines)
  - TEA module export verification
  - Model default values match documentation

### Rust Smoke Tests
New `#[cfg(test)]` blocks added to crates that had zero tests:
- `security/types.rs` — 5 tests (RedactionPattern, DetectedSecret, TrustfilePolicy, VaultKey)
- `capture/types.rs` — 4 tests (CaptureFormat, CaptureEntry, DemoPackage, DemoStep)
- `farm/types.rs` — 3 tests (FarmRepoEntry, FarmInventory, ManifestRepo)
- `minter/types.rs` — 5 tests (BackendKind, MintResult, WiringDetail, BotFinding, Capability)
- `plaza/types.rs` — 4 tests (ComplianceLevel, ComplianceAudit, AdoptionStats, RepoScanResult)
- `watcher/types.rs` — 4 tests (WatchEventKind, WatchEvent, WatcherStatus)
- `workspace/types.rs` — 6 tests (PanelPosition, Arrangement, WorkspaceMode, SessionProtection, SystemInfo, PanelGroup)
- `ai/types.rs` — 6 tests (ProviderId, AiProvidersFile.defaults, AiMessage, ProviderStatus, StreamChunk, ToolDefinition)
- `cloudguard/types.rs` — 3 tests (CfApiResponse success/failure parse, CfApiError)
- `voicetag/commands.rs` — 3 tests (empty MRI JSON validity, suffix stripping, filename detection)
- `hypatia/commands.rs` — 2 tests merged (URL default, URL override) into existing test module

**Bug fixes (pre-existing):**
- `valence_shell/commands.rs`: Fixed `valence_shell_checkpoint_restore` called with 1 arg instead of 2 (in existing tests)
- `valence_shell/commands.rs`: Fixed `map_or_else` type annotation (`Ok::<_, Infallible>`)

**Total Rust tests after blitz: 267 (all passing)**

## What's Still Missing

### P2P (Property-Based) Tests
- [ ] Network topology: graph property tests (connectivity, acyclicity where required)
- [ ] Security engine: policy evaluation property tests

### E2E Tests
- [ ] Accessibility: keyboard navigation through all panel types
- [ ] Theme/variant: each visual theme renders correctly
- [ ] Gossamer integration: panel communication round-trips (requires gossamer binary)

### Aspect Tests
- **Concurrency:** No tests for concurrent panel operations, WebSocket message ordering, subscription race conditions

### Build & Execution
- [ ] ReScript build (686 modules — very slow, CI only)
- [ ] Elixir mix test (beam/ layer)

### Benchmarks (remaining)
- [ ] Render time per panel type (requires compiled ReScript output + DOM)
- [ ] Memory usage per panel count (long-running session simulation)

### Self-Tests
- [ ] TEA framework self-test (model/view/update cycle with real DOM render)
- [ ] Accessibility compliance check (WCAG — requires headless browser)

### CRITICAL GAPS (remaining after blitz)

| Area | Modules | Tests | Coverage |
|------|---------|-------|----------|
| Components (.res) | ~200+ | 0 direct | **0%** (requires ReScript build) |
| Models (.res) | ~100+ | 0 direct | **0%** (requires ReScript build) |
| Views (.res) | ~100+ | 0 direct | **0%** (requires ReScript build) |
| TEA framework | ~20 | 4 | **20%** |
| Rust crates | 116 files | 267 tests | **smoke coverage** |

## CRG Grade Assessment

**Before blitz:** D (3.8% coverage, 0 benchmarks, no taxonomy structure)
**After blitz:** C+ (Taxonomy structure complete, all taxonomy categories populated, Rust smoke tests, 267 Rust tests passing)

**CRG C requirements met:**
- [x] Unit tests present (120+ JS + 267 Rust)
- [x] Smoke tests (all Rust crates have at least smoke coverage)
- [x] Build verification (cargo test: 267/267 pass)
- [x] P2P property tests (tea_properties_test.mjs)
- [x] E2E tests (e2e_panel_lifecycle_test.js — 47 tests)
- [x] Reflexive tests (manifest_test.mjs)
- [x] Contract tests (panel_contracts_test.mjs)
- [x] Aspect tests (security_test.mjs)
- [x] Benchmarks baselined (benches/panll_bench.js + existing bench_test.js files)

**Next grade (B):** Requires 686 ReScript modules to build + coverage measurement + 6 minimum A-tier targets.

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
