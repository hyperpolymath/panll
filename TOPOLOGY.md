<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-03-09 (honest audit) -->

# PanLL eNSAID — Project Topology

## System Architecture

```
                          ┌─────────────────────────────────────────────┐
                          │              HUMAN OPERATOR                 │
                          │        (Binary Star Co-orbit)               │
                          └───────────────────┬─────────────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
    ┌───────────────────────┐ ┌───────────────────────┐ ┌──────────────────────┐
    │  Panel-L (Symbolic)   │ │  Panel-N (Neural)     │ │ Panel-W (World)      │
    │  Constraints, rules,  │ │  AI reasoning, ECHIDNA│ │ Results, dashboards, │
    │  formal specs         │ │  confidence, proofs   │ │ live data, VeriSimDB │
    └───────────┬───────────┘ └───────────┬───────────┘ └──────────┬───────────┘
                └─────────────────────────┼────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │        TypeLL VERIFICATION KERNEL (cross-cutting)            │
          │  Cross-panel type intelligence │ 7/41 panels wired           │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │             COGNITIVE GOVERNANCE (always present)             │
          │  Vexometer │ Anti-Crash Gate │ Orbital Drift │ Info Humidity  │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │               AMBIENT INFRASTRUCTURE                         │
          │  Provenance Map │ Watcher │ Feedback-O-Tron │ Panel Switcher │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │          7-TENTACLES AGENTIC ORCHESTRATION                    │
          │  Multi-agent coordination │ Panel dispatch │ Task routing    │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │           BoJ PRIMARY GATEWAY (bojRouting toggle)             │
          │  lsp-mcp │ database-mcp │ dap-mcp │ bsp-mcp │ 17 cartridges │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │          A2ML / K9 INTEGRATION LAYER                         │
          │  Manifest parsing │ Kennel schema │ Yard contracts │ Hunt   │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │        COPROCESSOR ENGINE (Phase 1 + 2 + 3)                  │
          │  Control plane │ Zig FFI data plane │ Smart routing          │
          │  Local (CPU<80%) │ Remote (neural) │ BoJ fallback            │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
    ┌─────────────────────────────────────┼─────────────────────────────────────┐
    │                        PANEL OVERLAY SYSTEM (41 entries)                  │
    │  ┌──────┐ ┌─────────┐ ┌──────┐ ┌─────┐ ┌──────┐ ┌───────┐ ┌──────────┐  │
    │  │ VAB  │ │CloudGrd │ │ Farm │ │Plaza│ │Hypatia│ │Fleet  │ │Reposystem│  │
    │  └──────┘ └─────────┘ └──────┘ └─────┘ └──────┘ └───────┘ └──────────┘  │
    │  ┌──────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐ ┌───────────┐ │
    │  │Aerie │ │Interfaces│ │Playground│ │  Minter  │ │Provis│ │ My-Lang   │ │
    │  └──────┘ └──────────┘ └──────────┘ └──────────┘ └──────┘ └───────────┘ │
    │  ┌──────────────┐ ┌──────┐ ┌────────────────────────────────────────┐    │
    │  │Proto-Squisher│ │ BoJ  │ │ 11x IDApTIK eNSAID panels            │    │
    │  └──────────────┘ └──────┘ └────────────────────────────────────────┘    │
    │  ┌──────────────┐ ┌──────────────┐ ┌───────────┐ ┌───────────┐          │
    │  │Clade Browser │ │ Tentacles    │ │ TypeLL    │ │Automation │          │
    │  └──────────────┘ └──────────────┘ └───────────┘ └───────────┘          │
    │  41 clades defined │ 55 component views │ 47 core engines               │
    └─────────────────────────────────────┼─────────────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │                    PROVISIONER                                │
          │  Portfolios │ Configurator │ Isolation Tiers │ Custom Build  │
          │  Native <--> Standard Pod <--> Hardened Pod (Stapeln)        │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │              CUSTOM TEA RUNTIME (permanent)                   │
          │  18 modules │ VDOM diffing │ ARIA │ message queue │ animation │
          │  Tea_App │ Tea_Html │ Tea_Cmd │ Tea_Sub │ Tea_Render │ ...    │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
                    ┌─────────────────────┼──────────────────────┐
                    ▼                     ▼                      ▼
    ┌───────────────────────┐ ┌───────────────────┐ ┌───────────────────────┐
    │  TAURI BACKEND (Rust) │ │ BEAM (Elixir)     │ │ EXTERNAL SERVICES     │
    │  34 backend modules   │ │ - Hypatia API     │ │ - Cloudflare API      │
    │  - Farm, Fleet, Aerie │ │ - VeriSimDB       │ │ - gitbot-fleet Axum   │
    │  - Minter, Watcher    │ │ - QuandleDB       │ │ - Aerie V-lang API    │
    │  - Anti-Crash Gate    │ │ - LithoGlyph      │ │ - NQC proxy (:4000)   │
    │  - Provenance (blame) │ │ - State Orch.     │ │ - panic-attack        │
    │  - BoJ cartridges     │ │                   │ │ - BoJ-Server (:8080)  │
    │  - 11x IDApTIK cmds   │ │                   │ │                       │
    └───────────────────────┘ └───────────────────┘ └───────────────────────┘
```

## Source File Inventory

```
DIRECTORY              FILES   DESCRIPTION
─────────────────────  ─────   ─────────────────────────────
src/model/               49   Domain model types (1 per panel + shared)
src/components/          55   Panel view components (Tea_Html)
src/core/                47   Engine logic (computation, validation)
src/commands/            49   Tauri bridge command bindings
src/tea/                 18   Custom TEA runtime (permanent, no npm deps)
src/modules/             14   Module registry, TypeLLService, helpers
src/subscriptions/        2   Keyboard + polling subscriptions
src/bindings/             1   FFI bindings
src/*.res                 7   Top-level: Model, Msg, Update, View, App, Storage
src-tauri/src/          103   Rust backend (34 modules)
tests/                   69   Deno test files
panel-clades/clades/     41   Clade definitions (a2ml)
─────────────────────  ─────
TOTAL SOURCE            361   258 ReScript + 103 Rust
TOTAL TEST FILES         69   JS test suites (Deno.test)
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES                       CRG
──────────────────────────────────  ──────────────────  ─────────────────────────── ───
CORE PANELS (3)
  Panel-L (Symbolic Mass)           ██████████ 100%    Constraints, editor, proofs   D
  Panel-N (Neural Stream + ECHIDNA) ██████████ 100%    Inference, confidence, OODA   D
  Panel-W (World/Barycentre)        ██████████ 100%    Results, VeriSimDB, security  D

PANEL OVERLAYS (14 general + 11 IDApTIK + 3 meta)
  VAB (Verified Assembly Building)  ██████████ 100%    111 components, KSP aesthetic D
  CloudGuard                        ██████████ 100%    Phases 1-6, DNS, SSL, audit  D
  Git-Private-Farm                  ██████████ 100%    Repo inventory, health       D
  Palimpsest Plaza                  ██████████ 100%    Licensing, compliance        D
  Reposystem                        ██████████ 100%    RSR scores, template check   D
  Aerie                             ██████████ 100%    Network, speed, BGP          D
  Interfaces                        ██████████ 100%    ABI/FFI inventory            D
  Playgrounds                       ██████████ 100%    Sandbox, NQC, tutorials      D
  Hypatia                           ██████████ 100%    5 neural nets, 298 repos     D
  Gitbot-Fleet                      ██████████ 100%    6 bots, safety triangle      D
  Panel Minter                      ██████████ 100%    Accessible panel templates   D
  Protocol-Squisher                 ██████████ 100%    13 formats, 4 transports     D
  My-Lang                           ██████████ 100%    4 dialects, LSP backend      D
  BoJ Panel                         ██████████ 100%    17 cartridges, gateway       D
  IDApTIK eNSAID (x11)             ██████████ 100%    11 game-engine panels        D
  Automation Router                 ██████████ 100%    Rule engine, BoJ routing     D
  Clade Browser                     ██████████ 100%    41 clades, inheritance       D
  7-Tentacles                       ██████████ 100%    Agentic orchestration        D

CROSS-CUTTING SERVICES
  TypeLL Verification Kernel        █░░░░░░░░░  20%    7/41 panels wired (17%)      D
  A2ML/K9 Integration Layer         ████████░░  80%    Manifest, Kennel, Yard, Hunt D
  Coprocessor Engine (Phase 1-3)    ████████░░  80%    Control + data + smart route D
  Panel Bus pub/sub                 ████████░░  80%    10 topics, ring buffer       D
  SeamEngine compliance             ███████░░░  70%    6 known seams, drift detect  D

INFRASTRUCTURE
  Panel Switcher                    ██████████ 100%    Unified navigation bar       D
  Provisioner                       ██████████ 100%    Portfolios, config, tiers    D
  Code Provenance Map               ██████████ 100%    Trust surface, 4 palettes    D
  Filesystem Watcher                ██████████ 100%    Rust notify + ReScript cmds  D
  StatusBar                         ██████████ 100%    System info, build status    D

COGNITIVE GOVERNANCE
  Vexometer                         ██████████ 100%    Friction monitoring           D
  Anti-Crash Gate                   ██████████ 100%    Neural token gating           D
  Orbital Drift Aura                ██████████ 100%    Ambient stability indicator   D
  Feedback-O-Tron                   ██████████ 100%    BoJ context + persistence     D
  Information Humidity              ██████████ 100%    High/Medium/Low adaptation    D
  Dark Start                        ██████████ 100%    Architecture manifold entry   D

CUSTOM TEA RUNTIME (18 modules, permanent)
  Tea_App (mount/update/render)     ██████████ 100%    Application lifecycle         D
  Tea_Html (element constructors)   ██████████ 100%    No JSX — all Tea_Html         D
  Tea_Render (VDOM diffing)         ██████████ 100%    Virtual DOM diff/patch        D
  Tea_Cmd / Tea_Sub                 ██████████ 100%    Commands and subscriptions    D
  Tea_Vdom (ARIA, attributes)       ██████████ 100%    Accessibility attributes      D

BACKEND CONNECTIONS (Rust — 34 modules in src-tauri/)
  Farm (local JSON)                 ██████████ 100%    3 Rust cmds, manifest parser  D
  Fleet (Axum API)                  ██████████ 100%    3 Rust cmds, reqwest :8080    D
  Hypatia (Elixir API)              ██████████ 100%    3 Rust cmds, reqwest Elixir   D
  Aerie (V-lang API)                ██████████ 100%    2 Rust cmds, latency + speed  D
  Provenance (git blame)            ██████████ 100%    2 Rust cmds, blame + unsound  D
  BoJ-Server (Axum API)             ██████████ 100%    Gateway: 17 cartridges routed D
  Watcher (event hookup)            ██████████ 100%    5 Rust cmds + event emission  D
  Minter (Rust codegen)             ██████████ 100%    Backend exists                D
  Feedback (persistence)            ██████████ 100%    1 Rust cmd, ~/.panll/feedback  D
  IDApTIK backends (x11)           ██████████ 100%    Per-panel Rust commands       D

TESTING (69 test files)
  Core TEA tests                    ██████████ 100%    tea_app, tea_cmd, tea_sub     D
  Engine tests (47 engines)         ████████░░  80%    Most engines have test files  D
  Integration tests                 ██████░░░░  60%    update_test, integration      D
  Benchmark tests                   ██████░░░░  60%    safedom_bench, panic_bench    D
  End-to-end (Tauri app)            ░░░░░░░░░░   0%    Not yet implemented           X

──────────────────────────────────────────────────────────────────────────────────────
FRONTEND:         258 ReScript files │ 18 TEA + 49 model + 55 view + 47 engine + 49 cmd
BACKEND:          103 Rust files     │ 34 backend modules
TOTAL:            361 source files   │ 41 panel entries │ 41 clades │ 55 components
TESTS:             69 test files     │ 0 end-to-end     │ CRG D (Alpha) across the board
──────────────────────────────────────────────────────────────────────────────────────

OVERALL PROGRESS
  Frontend (panels compile & render) █████████░  90%    All 41 panels render, views D
  TypeLL cross-panel coverage        █░░░░░░░░░  20%    7/41 panels = 17%           D
  Backend connections (Rust cmds)    ████████░░  80%    34 modules, stubs remain    D
  Testing                           ███████░░░  70%    69 files, no E2E            D
  Documentation                     ██████░░░░  60%    TOPOLOGY, manifests, clades D
  CRG Grade Promotion (D->C)        ░░░░░░░░░░   0%    Not started                 X
──────────────────────────────────────────────────────────────────────────────────────
  HONEST OVERALL                    ███████░░░  70%    Alpha quality, compiles clean
──────────────────────────────────────────────────────────────────────────────────────
```

## Cross-Panel Communication Map

```
Farm ──────> Reposystem (repo inventory -> compliance targets)
  |
  └────────> Hypatia (repo list -> scanning targets)
                 |
                 └──> Fleet (scan findings -> dispatch queue)
                        |
                        └──> Panel-N (confidence -> reasoning display)

TypeLL ────> 7 PANELS (cross-panel type verification + inference)
  |           VeriSimDB, Protocol-Squisher, My-Lang, Anti-Crash,
  |           Pane-L, BoJ, ECHIDNA
  |
  └────────> Panel-L (type constraints -> formal spec validation)

BoJ ───────> Panel-W (cartridge status -> dashboard display)
  |
  ├────────> Provisioner (cartridge isolation -> tier selection)
  |
  ├────────> Editor Bridge (LSP via lsp-mcp when bojRouting=true)
  |
  ├────────> VeriSimDB (VQL queries via database-mcp when bojRouting=true)
  |
  ├────────> VM Inspector (DAP debug via dap-mcp when bojRouting=true)
  |
  └────────> Build Dashboard (BSP builds via bsp-mcp when bojRouting=true)

7-Tentacles > ALL PANELS (agentic dispatch -> task routing)

Watcher ───> ALL PANELS (filesystem events -> targeted refresh)

Clade Browser > ALL PANELS (clade inheritance -> panel classification)

Feedback-O-Tron ──> Vexometer (sentiment -> friction index)
                        |
                        └──> Humidity (friction -> UI density)

Provenance ──> Anti-Crash (trust levels -> validation thresholds)

Coprocessor ──> Panel-N (smart routing -> local/remote/BoJ dispatch)
  |
  └────────> BoJ (fallback routing when local FFI unavailable)

A2ML/K9 ────> Clade Browser (Hunt permission -> clade isolation check)
  |
  ├────────> BoJ (CartridgesResult -> auto Yard contract generation)
  |
  └────────> Feedback-O-Tron (test coverage policy -> quality reporting)

Provisioner ──> ALL PANELS (isolation tier -> startup mode)
```

## Key Dependencies

```
BUILD TOOLS
  ReScript compiler        via npm (ADR accepted — npm kept for this only)
  Tailwind CSS             via npm (same ADR)
  Deno                     runtime, testing, task runner
  Tauri 2.0                desktop shell (Rust backend)

RUNTIME DEPENDENCIES
  Custom TEA (src/tea/)    18 modules, zero npm deps, VDOM diffing
  @tauri-apps/api          Tauri IPC bridge
  @tauri-apps/plugin-*     dialog, fs plugins

EXTERNAL SERVICES
  ECHIDNA                  port 9000 — theorem prover dispatch
  VeriSimDB                port 8080 — 8-modality versioned database
  BoJ-Server               port 8080 — cartridge server
  gitbot-fleet             Axum API — bot orchestration
  Aerie                    V-lang API — network analysis
  Hypatia                  Elixir API — neurosymbolic CI/CD
```

## Honesty Notes

- All 41 panels compile and render with 0 errors, 0 warnings
- TypeLL cross-panel intelligence is wired to only 7 of 41 panels (17%)
- CRG grade D (Alpha) across every component — none have reached C (Beta)
- No end-to-end testing exists (Tauri desktop app integration)
- Previous TOPOLOGY.md claimed 100% across all four summary categories
- Source file count was previously inflated by counting compiled .res.js alongside .res
- Test "count" of 1346 was individual assertions, not test files (69 files on disk)
- 34 Rust backend modules exist, but depth of implementation varies

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar, percentage, and CRG grade
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **After backend connection**: Move from Backend Connections 0% to actual %
5. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
CRG grades: X (untested), F (harmful), E (minimal), D (alpha), C (beta), B (RC), A (stable).
