<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-03-08 -->

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
          │  Cross-panel type intelligence │ 7 panels wired │ inference  │
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
          │  lsp-mcp │ database-mcp │ dap-mcp │ bsp-mcp │ 14 cartridges │
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
    │  │Proto-Squisher│ │ BoJ  │ │ 11× IDApTIK eNSAID panels            │    │
    │  └──────────────┘ └──────┘ └────────────────────────────────────────┘    │
    │  ┌──────────────┐                                                        │
    │  │Clade Browser │  39 clades defined │ inheritance engine                │
    │  └──────────────┘                                                        │
    └─────────────────────────────────────┼─────────────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │                    PROVISIONER                                │
          │  Portfolios │ Configurator │ Isolation Tiers │ Custom Build  │
          │  Native ◄──► Standard Pod ◄──► Hardened Pod (Stapeln)        │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
                    ┌─────────────────────┼──────────────────────┐
                    ▼                     ▼                      ▼
    ┌───────────────────────┐ ┌───────────────────┐ ┌───────────────────────┐
    │  TAURI BACKEND (Rust) │ │ BEAM (Elixir)     │ │ EXTERNAL SERVICES     │
    │  - Watcher (notify)   │ │ - Hypatia API     │ │ - Cloudflare API      │
    │  - Farm (local JSON)  │ │ - VeriSimDB       │ │ - gitbot-fleet Axum   │
    │  - Minter (codegen)   │ │ - QuandleDB       │ │ - Aerie V-lang API    │
    │  - Anti-Crash Gate    │ │ - LithoGlyph      │ │ - NQC proxy (:4000)   │
    │  - Provenance (blame) │ │ - State Orch.     │ │ - panic-attack        │
    │  - BoJ cartridges     │ │                   │ │ - BoJ-Server (:8080)  │
    └───────────────────────┘ └───────────────────┘ └───────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES                       CRG
──────────────────────────────────  ──────────────────  ─────────────────────────── ───
CORE PANELS (3)
  Panel-L (Symbolic Mass)           ██████████ 100%    Constraints, editor, proofs   D
  Panel-N (Neural Stream + ECHIDNA) ██████████ 100%    Inference, confidence, OODA   D
  Panel-W (World/Barycentre)        ██████████ 100%    Results, VeriSimDB, security  D

PANEL OVERLAYS (14 + 11 IDApTIK)
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
  Protocol-Squisher                 ██████████ 100%    Protocol compression/merge    D
  My-Lang                           ██████████ 100%    Language playground panel     D
  BoJ Panel                         ██████████ 100%    Cartridge mgmt, 14 carts     D
  IDApTIK eNSAID (×11)             ██████████ 100%    11 game-engine panels        D

CROSS-CUTTING SERVICES (2)
  TypeLL Verification Kernel        ██████████ 100%    Cross-panel type intel, 7 wired D
  7-Tentacles Orchestration         ██████████ 100%    Agentic multi-panel dispatch  D

INFRASTRUCTURE (5)
  Panel Switcher                    ██████████ 100%    Unified navigation bar       D
  Provisioner                       ██████████ 100%    Portfolios, config, tiers    D
  Code Provenance Map               ██████████ 100%    Trust surface, 4 palettes    D
  Filesystem Watcher                ██████████ 100%    Rust notify + ReScript cmds  D
  Clade Browser                     ██████████ 100%    39 clades, inheritance engine D

COGNITIVE GOVERNANCE (6)
  Vexometer                         ██████████ 100%    Friction monitoring           D
  Anti-Crash Gate                   ██████████ 100%    Neural token gating           D
  Orbital Drift Aura                ██████████ 100%    Ambient stability indicator   D
  Feedback-O-Tron                   █████████░  90%    BoJ context snapshot added    D
  Information Humidity              ██████████ 100%    High/Medium/Low adaptation    D
  Dark Start                        ██████████ 100%    Architecture manifold entry   D

BACKEND CONNECTIONS
  Farm (local JSON)                 ░░░░░░░░░░   0%    Needs ~/.git-private-farm/    X
  Fleet (Axum API)                  ░░░░░░░░░░   0%    Needs reqwest to :8080        X
  Hypatia (Elixir API)              ░░░░░░░░░░   0%    Needs reqwest to Elixir       X
  Aerie (V-lang API)                ░░░░░░░░░░   0%    Needs reqwest to :4000        X
  Provenance (git blame)            ░░░░░░░░░░   0%    Needs blame parsing           X
  BoJ-Server (Axum API)             ██████░░░░  60%    Gateway: 4 panels routed      D
  Watcher (event hookup)            █████░░░░░  50%    Rust done, frontend TODO      D
  Minter (Rust codegen)             ██████████ 100%    Backend exists                D

──────────────────────────────────────────────────────────────────────────────────────
FRONTEND:         230 ReScript files │ 26,000+ lines │ 0 errors │ CRG D (Alpha)
BACKEND:           63 Rust files     │  5,300+ lines │ 0 errors │ CRG D (Alpha)
TOTAL:            293 source files   │ 31,300+ lines │ 41 panel entries │ 39 clades
TESTS:            979 Deno + 28 Rust │ 0 warnings    │ 41 test suites
──────────────────────────────────────────────────────────────────────────────────────

OVERALL PROGRESS
  Frontend                          █████████░  98%    41 panels, 39 clades          D
  Backend Connections                █████░░░░░  50%    BoJ gateway + coprocessor     D
  Testing                           ████████░░  85%    979+28 tests, 41 suites       D
  Documentation                     ██████░░░░  60%    TOPOLOGY, manifests, clades   D
──────────────────────────────────────────────────────────────────────────────────────
```

## Cross-Panel Communication Map

```
Farm ──────► Reposystem (repo inventory → compliance targets)
  │
  └────────► Hypatia (repo list → scanning targets)
                 │
                 └──► Fleet (scan findings → dispatch queue)
                        │
                        └──► Panel-N (confidence → reasoning display)

TypeLL ────► 7 PANELS (cross-panel type verification + inference)
  │
  └────────► Panel-L (type constraints → formal spec validation)

BoJ ───────► Panel-W (cartridge status → dashboard display)
  │
  ├────────► Provisioner (cartridge isolation → tier selection)
  │
  ├────────► Editor Bridge (LSP via lsp-mcp when bojRouting=true)
  │
  ├────────► VeriSimDB (VQL queries via database-mcp when bojRouting=true)
  │
  ├────────► VM Inspector (DAP debug via dap-mcp when bojRouting=true)
  │
  └────────► Build Dashboard (BSP builds via bsp-mcp when bojRouting=true)

7-Tentacles ► ALL PANELS (agentic dispatch → task routing)

Watcher ───► ALL PANELS (filesystem events → targeted refresh)

Clade Browser ► ALL PANELS (clade inheritance → panel classification)

Feedback-O-Tron ──► Vexometer (sentiment → friction index)
                        │
                        └──► Humidity (friction → UI density)

Provenance ──► Anti-Crash (trust levels → validation thresholds)

Provisioner ──► ALL PANELS (isolation tier → startup mode)
```

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
