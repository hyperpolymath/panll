<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-03-02 -->

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
          │             COGNITIVE GOVERNANCE (always present)             │
          │  Vexometer │ Anti-Crash Gate │ Orbital Drift │ Info Humidity  │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │               AMBIENT INFRASTRUCTURE                         │
          │  Provenance Map │ Watcher │ Feedback-O-Tron │ Panel Switcher │
          └───────────────────────────────┼───────────────────────────────┘
                                          │
    ┌─────────────────────────────────────┼─────────────────────────────────────┐
    │                        PANEL OVERLAY SYSTEM                               │
    │  ┌──────┐ ┌─────────┐ ┌──────┐ ┌─────┐ ┌──────┐ ┌───────┐ ┌──────────┐  │
    │  │ VAB  │ │CloudGrd │ │ Farm │ │Plaza│ │Hypatia│ │Fleet  │ │Reposystem│  │
    │  └──────┘ └─────────┘ └──────┘ └─────┘ └──────┘ └───────┘ └──────────┘  │
    │  ┌──────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐ ┌───────────┐ │
    │  │Aerie │ │Interfaces│ │Playground│ │  Minter  │ │Provis│ │ Future... │ │
    │  └──────┘ └──────────┘ └──────────┘ └──────────┘ └──────┘ └───────────┘ │
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

PANEL OVERLAYS (11)
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

INFRASTRUCTURE (4)
  Panel Switcher                    ██████████ 100%    Unified navigation bar       D
  Provisioner                       ██████████ 100%    Portfolios, config, tiers    D
  Code Provenance Map               ██████████ 100%    Trust surface, 4 palettes    D
  Filesystem Watcher                ██████████ 100%    Rust notify + ReScript cmds  D

COGNITIVE GOVERNANCE (6)
  Vexometer                         ██████████ 100%    Friction monitoring           D
  Anti-Crash Gate                   ██████████ 100%    Neural token gating           D
  Orbital Drift Aura                ██████████ 100%    Ambient stability indicator   D
  Feedback-O-Tron                   ████████░░  80%    Submission done, mining TODO  D
  Information Humidity              ██████████ 100%    High/Medium/Low adaptation    D
  Dark Start                        ██████████ 100%    Architecture manifold entry   D

BACKEND CONNECTIONS
  Farm (local JSON)                 ░░░░░░░░░░   0%    Needs ~/.git-private-farm/    X
  Fleet (Axum API)                  ░░░░░░░░░░   0%    Needs reqwest to :8080        X
  Hypatia (Elixir API)              ░░░░░░░░░░   0%    Needs reqwest to Elixir       X
  Aerie (V-lang API)                ░░░░░░░░░░   0%    Needs reqwest to :4000        X
  Provenance (git blame)            ░░░░░░░░░░   0%    Needs blame parsing           X
  Watcher (event hookup)            █████░░░░░  50%    Rust done, frontend TODO      D
  Minter (Rust codegen)             ██████████ 100%    Backend exists                D

──────────────────────────────────────────────────────────────────────────────────────
FRONTEND:         107 ReScript files │ 26,798 lines │ 0 errors │ CRG D (Alpha)
BACKEND:           20 Rust files     │  5,342 lines │ 0 errors │ CRG D (Alpha)
TOTAL:            127 source files   │ 32,140 lines │ 14 panels + 4 infra layers
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

Watcher ───► ALL PANELS (filesystem events → targeted refresh)

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
