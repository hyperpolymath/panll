# Changelog

All notable changes to the PanLL eNSAID project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
  - VeriSimDB: VQL type checking on query submit
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
