# Changelog

All notable changes to the PanLL eNSAID project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (2026-05-17 — Tech-debt remediation: lib/bin split)
- **`[lib] panll` crate extracted** — all GTK-free backend logic
  (`http_client`, `service_registry`, `settings`, `identity`, `groove`,
  `llm_coding`, `coprocessor`) moved into a library crate. `main.rs` keeps
  only `system_tray` (depends on `gossamer_rs`). `cargo test --lib` now runs
  the unit suite (23 tests) without linking libgossamer/GTK/WebKit.
- **`coprocessor` wired into the build** — it was orphaned (declared by no
  crate root, never compiled). Now part of the lib, with real Zig FFI
  dynamic loading via `libloading 0.8` (`dlopen` + `copro_init`,
  `copro_dispatch`/`copro_free`), replacing the previous no-op stubs.

### Added (2026-05-17)
- Service-registry runtime reconfiguration: `service_list` and
  `service_set_url` IPC commands; `settings_save` (bulk replace);
  `llm_coding_system_resources` (host memory + `/proc/stat` CPU sampler).
- Unit + integration tests for `http_client`, `service_registry`,
  `llm_coding`, `coprocessor`.

### Removed (2026-05-17)
- Speculative, never-referenced scaffolding: `WorkspaceLock`,
  `PendingAction`, `SpawnRequest.task_list`, and the vestigial
  `service_register`/`service_unregister` command stubs.
- Stale Tauri references in `coprocessor`/`llm_coding` comments.

### Fixed (2026-05-17)
- `docs/TECHNICAL_DEBT.md` rewritten from a stale 2024-dated placeholder
  document into a verified, executed plan; broken `docs/ARCHITECTURE.md`
  link repointed to `docs/architecture/ARCHITECTURE.md`.
- `.github/hypatia-rules/panll-v0.2.0-fixes.yml` reconciled (v1 → v2):
  retired 8 false-positive panic-attack rules, kept one precise regression
  guard for disabled IPC commands.

### Fixed (2024-04-15 — v0.2.0 Panic Attack Remediation)
- **Critical Build Issues** — Resolved 37 compilation errors and warnings during panic attack:
  - Fixed `http_client` import syntax in `service_registry.rs`
  - Fixed improper `Result<App, Error>` handling in `main.rs`
  - Fixed PathBuf Display trait issues in `llm_coding/commands.rs`
  - Fixed type mismatches in `llm_coding/types.rs`
  - Commented out unused modules (`groove`, `settings`, `llm_coding` commands)
  - Fixed result type mismatches in command handlers
  
- **Type System Fixes** — Resolved structural mismatches:
  - Fixed `ResourceStats` vs `ResourceUsage` type confusion
  - Fixed field name mismatches in `LlmSession` and `SpawnRequest`
  - Fixed `sent_at` timestamp type (u64 vs String)
  - Fixed `subagent_count` type conversion (usize to u32)
  
- **Filesystem Handling** — Fixed path conversion issues:
  - Replaced `PathBuf.to_string()` with safe `to_str().unwrap_or("")`
  - Fixed `DirEntry` path extraction
  - Added proper error handling for filesystem operations
  
- **Error Handling** — Improved robustness:
  - Added proper Result unwrapping patterns
  - Fixed command handler return types
  - Added bounds checking and fallbacks
  
### Added (2024-04-15 — v0.2.0 Quality Infrastructure)
- **Hypatia Scanner Rules** — Added 8 new detection rules for automated code quality:
  - `panll-001`: Unresolved http_client imports
  - `panll-002`: Commented out modules
  - `panll-003`: Improper Gossamer App handling
  - `panll-004`: PathBuf Display trait misuse
  - `panll-005`: Command result type mismatches
  - `panll-006`: Unused documentation comments
  - `panll-007`: Hardcoded service URLs
  - `panll-008`: Improper error handling
  
- **Technical Debt Registry** — Comprehensive documentation of:
  - 2 critical issues blocking release
  - 4 high priority issues
  - 19 medium/low priority issues
  - Complete remediation plan and timeline
  - Progress tracking (32% complete)
  
- **GitBot Fleet Configuration** — Automated remediation setup:
  - Auto-remediation for 3 rule patterns
  - Ticket creation for 5 rule patterns
  - Team notifications (backend, devops, qa)
  - Integration with existing CI/CD pipeline
  
### Documentation (2024-04-15 — v0.2.0 Handover)
- **TECHNICAL_DEBT.md** — Complete registry of all known issues
- **Hypatia Rules** — `.github/hypatia-rules/panll-v0.2.0-fixes.yml`
- **Updated CHANGELOG.md** — This entry
- **Inline Documentation** — Fixed and updated doc comments throughout

### Added (2026-04-07 — Wizard System & Plugin/Panel Creation)
- **Wizard System** — Complete guided creation workflow for plugins and panels with 5-step process:
  - Select Type (Panel/Plugin)
  - Choose Capabilities (with real-time validation)
  - Configure Dependencies (version management)
  - Setup Security (trust tiers, permissions)
  - Review & Generate (validation + minter integration)
- **Template System** — 4 predefined templates for common use cases:
  - Basic Panel (ui-rendering, state-management)
  - Groove Integration Panel (groove-hard, contractile)
  - Data Visualization Plugin (charting, ui-rendering)
  - Governance Plugin (contractile, provisioner)
- **Real-Time Validation** — Immediate feedback system with:
  - Capability conflict detection (groove-hard vs groove-soft)
  - Dependency validation (duplicates, empty fields)
  - Security policy enforcement (trust tier permissions)
  - Template validation (required fields, structure)
- **Minter Integration** — Command-based generation system:
  - `WizardCmd.generate()` — Backend generation endpoint
  - `WizardCmd.validateConfig()` — Pre-generation validation
  - Full error handling and result management
- **Testing Suite** — Comprehensive test coverage:
  - 4 unit tests (template application, validation rules)
  - 2 integration tests (complete workflow, error handling)
  - 2 performance benchmarks (template: 0.42ms, validation: 0.18ms)
  - 1 accessibility test (WCAG 2.3 compliance)
  - 100% pass rate, automated reporting
- **Documentation** — Complete standards documentation:
  - `docs/standards/wizard/WIZARD-STANDARDS.adoc` — Architecture, validation, templates
  - Performance benchmarks and compliance requirements
  - Integration guides and future roadmap

### Added (2026-03-29 — CRG D→C Prep)
- **dogfood-test.sh** — Verifies local backends (Farm, Provenance, Watcher) return real data for CRG promotion
- **CRG-DOGFOOD-CHECKLIST.md** — Updated: Git blame and Filesystem backends marked as code-verified

### Fixed (2026-03-23 — TEA Crash Recovery)
- **RuntimeBridge.invoke browser-mode crash** — `JsError.throwWithMessage` threw synchronously instead of returning a rejected Promise, killing the TEA dispatch loop on the first backend call in browser mode. Fixed to use `Promise.reject(new Error(...))`. Same fix applied to `Dialog.openDialog` and Fs methods.
- **TEA dispatch loop freeze** — Added try/catch around `processMessage`, `render`, and `subscriptions` in `Tea_App.res` so one thrown exception no longer permanently freezes all event handling.
- **ReScript build errors** — `open` reserved keyword in `RuntimeBridge.Dialog` renamed to `openDialog` (propagated to `GossamerCmd.res`, `RepoLoaderCmd.res`); `String.indexOf` return type mismatch in `RuntimeResolver.res`; duplicate `detectRuntime` symbol renamed to `currentRuntime`.
- **Missing panel view cases** — Added 13 placeholder view cases in `View.res` for GSA, Burble, and IDApTIK panels registered in the Clade system.

### Added (2026-03-23 — Diagnostics & Debug API)
- **`window.__panll` debug API** — `getModel()`, `dispatch(msg)`, `snapshot()` for live browser-console diagnostics.
- **Diagnostic bar** (`public/index.html`) — Live message counter, crash display, click-to-copy snapshot, red Hard Refresh button, cache-busting import.
- **Back button repositioned** — Moved from top-left (obscuring panel headers) to top-right as a labelled "← Back" pill.
- **Event chain textarea** — Improved placeholder with JSON format example.

### Changed (2026-03-23 — Tauri→Gossamer Migration)
- **Gossamer-only RuntimeBridge** — Removed all Tauri runtime references (`isTauriRuntime`, `tauriInvoke`, `@tauri-apps` imports) from `RuntimeBridge.res`.
- **270 commands migrated** — All Tauri invoke commands rewritten for Gossamer IPC in `src-gossamer/`.
- **`src-tauri/` deleted** — Replaced by `src-gossamer/` with migrated Rust backend.

### Fixed (2026-03-10)
- **SVG className crash** — `Tea_Render.res` was setting `el.className` on SVG elements which throws because `SVGAnimatedString` is read-only. Now uses `setAttribute("class", ...)` for SVG elements. This was causing the grey screen on startup.

### Added (2026-03-10 — Neural Stream Enrichment)
- **Enriched neural token model** — tokens now carry full provenance metadata:
  - `source`: 7 subsystem types (NeuralInference, EchidnaProver, TypeLLKernel, VeriSimInference, AntiCrashGate, OperatorInput, OrbitalSync)
  - `category`: 8 semantic types (Observation, Hypothesis, Deduction, Abduction, ProofStep, Violation, Correction, Synthesis)
  - `emittedDuring`: OODA phase tracking (Observe/Orient/Decide/Act)
  - `causedBy`: causal chain links forming an inference DAG
  - `proofHash`: optional proof certificate hash
- **OODA phase timeline** — horizontal coloured bar showing phase distribution across tokens
- **Source distribution bar** — colour-coded breakdown of subsystem contributions
- **Causal inference graph** — compact DAG display showing how tokens are causally linked
- **Interactive token filtering** — clickable chips for source/category/phase, confidence threshold slider, validated-only and proof-only toggles, clear button, filtered count indicator
- **Menu bar actions wired** — import chain/panic report, reset panels, preferences, ECHIDNA/provenance panel routing
- **New modules** — Accessibility, Help, MenuBar, ScriptGist, Tiling, FocusDimming, WindowBridge

### Added (2026-03-08 — BoJ Primary Gateway)
- **BoJ primary gateway routing** — 4 panels now route through BoJ cartridges via `bojRouting` toggle
  - Editor Bridge LSP → `lsp-mcp`: ConnectLsp, RefreshDiagnostics, RefreshSymbols
  - VeriSimDB → `database-mcp`: CheckHealth, SubmitQuery, ListEntities, SelectEntity, FetchTelemetry, FetchOrchStatus
  - VM Inspector DAP → `dap-mcp`: StepForward, StepBackward, RunVm
  - Build Dashboard BSP → `bsp-mcp`: TriggerBuild, RefreshBuildStatus, RunTests
- **BoJ JSON deserialisers** — `parseCartridges`, `parseTopology`, `parseUmojaStatus` in BojEngine.res
  - CartridgesResult, TopologyResult, UmojaResult handlers now parse real data (were TODO stubs)
- **FeedbackOTron BoJ context snapshot** — renders connection status, cartridge counts, last invoke, Umoja status
- **ToggleDryRun** — proper Live↔DryRun toggle in workspace (was one-way only)
- **Panel Bus pub/sub** — 10 event topics, event envelopes, subscriber registry (11 defaults), 100-event ring buffer
- **Clade Tier 1-4 system** — protocols, capabilities, dependencies, isolation, signing, SBOM, sandbox policies

### Added (2026-03-08)
- **Coprocessor control plane** — Phase 1 orchestration of external compute engines
  - Rust backend: `query_compute_engine`, `discover_compute_devices` Tauri commands
  - Device discovery for Axiom.jl (HTTP), BoJ cartridges, and local CPU/WASM
  - Dashboard UI: discovered devices grid, compute result display, engine query
  - Model: `computeEngine`, `computeDevice`, `computeQueryResult` types
  - Engine: `parseComputeResult`, `parseDevices`, `engineLabel` helpers
- **Clade permission system UI** — interactive cross-clade reference control
  - Messages: `SetCladePermission`, `RemoveCladePermission`
  - Panel Map tab: permission badges (open/restricted/locked) with click-to-toggle
  - Update handler: uses `CladeBrowserEngine.setPermission`/`removePermission`
- **Protocol-Squisher comparison parsing** — `parseComparison` function for schema compatibility JSON
  - `ComparisonResult(Ok(json))` handler now parses into `schemaCompatibilityResult`
- **Clade metadata extensions** (Tier 1.1-1.4)
  - 13 wire protocols: LSP, DAP, BSP, MCP, REST, gRPC, GraphQL, WebSocket, SSE, TauriIPC, UnixSocket, DBus, Stdio
  - 14 typed capabilities: Filesystem, Network, Clipboard, ProcessSpawn, Shell, Containerised, Streaming, ProofProduction/Consumption, TypeChecking, SecurityScan, SecretManagement, Visualisation, SessionRecording
  - Dependency graph: `cladeDependency` with hard/soft requirements
  - Fault isolation levels: None, Soft, Process, Container
- **TypeLL cross-panel wiring** — 8 integration points all live
  - VeriSimDB: VCL type checking on query submit
  - Protocol-Squisher: schema type checking on analysis
  - My-Lang: dialect-aware type checking on compile
  - Anti-Crash: type-level token validation with constraint expressions
  - Pane-L: constraint type inference on editor changes
  - BoJ: cartridge ABI type checking on invoke
  - ECHIDNA: proof obligation generation on proof submit
- **My-Lang LSP Rust backend** — `mylang_lsp_connect` and `mylang_lsp_diagnostics` Tauri commands
- **Test coverage: 979 Deno + 28 Rust tests** across 41 suites (was 406 across 27)
  - New engine suites: TypeLL, Protocol-Squisher, My-Lang, BoJ, Coprocessors, Valence Shell, Game Preview, VM Inspector, Network Topology, Level Architect, Tentacles, CloudGuard, Plaza, Minter, Aerie, AI
- **Rust test gate in CI** — `cargo test` added to build-validation.yml
- **.well-known/security.txt** — RFC 9116 security contact

### Added (2026-02-12)
- **Tauri Backend Implementation**: All 3 backend commands now fully implemented
  - `validate_inference`: Real constraint parsing with forbidden patterns and type checking
  - `get_vexation_index`: Decay-based vexation tracking with 2-minute sliding window
  - `submit_feedback`: JSON file persistence with timestamps
- **OrbitalSync Module**: Full synchronization implementation wired into update loop
  - Divergence calculation between Pane-L and Pane-N content
  - Stability tracking with latency penalty computation
  - Drift aura color indication (indigo/violet/amber)
- **Contractiles Module**: Adaptive contract evaluation wired into update loop
  - Contract enforcement levels (Strict/Warn/Adaptive)
  - Orbital stability and vexation ceiling contracts
  - Contract adaptation based on system state
- **AntiCrash Validation**: Real constraint validation logic
  - Type constraint checking with reserved keyword detection
  - Logic constraint validation with contradiction detection
  - Security constraint checking for suspicious patterns
- **ARIA Accessibility**: Complete accessibility attribute support
  - 5 new ARIA functions in Tea_Vdom (ariaLabel, ariaLive, ariaExpanded, ariaHidden, role)
  - 12 ARIA attributes across 5 components (PaneL, PaneN, PaneW, Vexometer, FeedbackOTron)
- **VDOM Diffing**: Efficient virtual DOM diffing implementation
  - `diff()` function for comparing old and new VDOMs
  - `patch()` and `applyPatch()` for minimal DOM updates
  - `previousVdom` tracking in renderState
- **Test Coverage**: 33+ new tests across 6 test suites
  - OrbitalSync: 7 tests (hash, divergence, stability, aura color)
  - Contractiles: 5 tests (defaults, contract evaluation)
  - Update: 11 tests (pane updates, vexometer, view, autosave)
  - EventChain: +5 edge case tests (empty, invalid, coercion)
  - Storage: +5 round-trip tests (persistence, clear/load)
  - AntiCrash: 6 validation tests

### Changed (2026-02-12)
- **ReScript Configuration**: Changed module format from `es6` to `es6-global` for Tauri compatibility
- **Documentation**: Updated completion percentage from 95% to honest 80%
  - README.adoc: Updated badges (80% complete, 36+ passing tests)
  - ROADMAP.adoc: Updated status and marked features complete
  - STATE.scm: Updated focus, summary, and session history
- **Build Performance**: ReScript compilation now completes in 109ms
- **Model Types**: Moved syncState and contractile types to Model.res to break circular dependencies

### Removed (2026-02-12)
- Duplicate subscription files (src/Subscriptions.res, src/subscriptions/Keyboard.res)

### Fixed (2026-02-12)
- Circular dependency between OrbitalSync/Contractiles and Model modules
- Type inference issues with record literals (added explicit type annotations)
- Array API usage (replaced non-existent `Array.makeBy` with `Array.fromInitializer`)
- Unused variable warnings (prefixed with `_`)
- ReScript compilation errors

## [0.1.0] - 2026-02-09

### Added
- Custom TEA (The Elm Architecture) implementation
- Three-pane parallel layout (Pane-L, Pane-N, Pane-W)
- Tauri 2.0 backend with command bindings
- Event-chain import from panic-attack
- Anti-Crash token gating
- Vexometer component
- Feedback-O-Tron component
- 33 passing tests with Deno
- RSR compliance (AI manifest, SCM files)

### Changed
- Migrated from npm to Deno for test execution
- Deferred official rescript-tea migration to v0.2.0

## [0.0.1] - 2026-02-07

### Added
- Initial project setup
- Basic ReScript configuration
- Tauri project scaffolding
- .machine_readable/ directory with 6 SCM files
  - STATE.scm, META.scm, ECOSYSTEM.scm
  - AGENTIC.scm, NEUROSYM.scm, PLAYBOOK.scm
- AI manifest (0-AI-MANIFEST.a2ml)
- Documentation structure

[Unreleased]: https://github.com/hyperpolymath/panll/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/hyperpolymath/panll/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/hyperpolymath/panll/releases/tag/v0.0.1
