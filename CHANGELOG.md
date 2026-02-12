# Changelog

All notable changes to the PanLL eNSAID project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
