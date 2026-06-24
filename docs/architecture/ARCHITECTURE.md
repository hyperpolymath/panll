<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- ARCHITECTURE.md — High-level PanLL architecture -->
<!-- Last updated: 2026-03-09 -->

# PanLL Architecture

PanLL (pronounced "parallel") is a Human-Things Interface (HTI) built with
ReScript + Tauri 2.0. This document describes the major architectural patterns.

## Three-Panel Layout

The UI is split into three persistent panels:

| Panel | Role | Content |
|-------|------|---------|
| **Panel-L** (Symbolic Mass) | Constraints, formal specs, proofs | Type rules, ECHIDNA verification, Anti-Crash gate |
| **Panel-N** (Neural Stream) | AI reasoning, OODA loop | Inference manifold, confidence display, agent monologue |
| **Panel-W** (World/Barycentre) | Results, dashboards, live data | VeriSimDB results, security findings, task outputs |

Overlay panels (41 total) appear one at a time on top of the core three.
The Panel Switcher navigation bar controls which overlay is active. At most
one overlay is visible; setting `activePanel` to `None` shows only the core
panels.

## TEA (The Elm Architecture)

PanLL uses a custom TEA implementation in `src/tea/`. This is **not**
rescript-tea@0.16.0 — the upstream package is incompatible with the panel
architecture, so PanLL maintains its own fork.

### TEA Modules

| Module | Path | Purpose |
|--------|------|---------|
| `Tea_App` | `src/tea/Tea_App.res` | Application lifecycle — init, update, view, subscriptions |
| `Tea_Cmd` | `src/tea/Tea_Cmd.res` | Side-effect commands — `Tea_Cmd.call(callbacks => ...)` |
| `Tea_Sub` | `src/tea/Tea_Sub.res` | Subscriptions — timers, event listeners |
| `Tea_Html` | `src/tea/Tea_Html.res` | Virtual DOM element constructors |
| `Tea_Vdom` | `src/tea/Tea_Vdom.res` | Virtual DOM diffing and patching |
| `Tea_Render` | `src/tea/Tea_Render.res` | DOM rendering pipeline |
| `Tea_Time` | `src/tea/Tea_Time.res` | Time-based subscriptions |
| `Tea_Animationframe` | `src/tea/Tea_Animationframe.res` | requestAnimationFrame subscriptions |
| `Tea` | `src/tea/Tea.res` | Re-export module |

### The Cycle

```
                    ┌──────────┐
                    │  Model   │  (immutable state record)
                    └────┬─────┘
                         │
              ┌──────────▼──────────┐
              │   View(model)       │  (model → Tea_Html virtual DOM)
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │   DOM Events        │  (user clicks, key presses)
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │   Msg dispatched    │  (variant type — exhaustive match)
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │   Update(model,msg) │  (returns (model, Cmd))
              └──────────┬──────────┘
                         │
                    ┌────▼─────┐
                    │  Model'  │  (new state → re-render)
                    └──────────┘
```

Key conventions:
- Commands use `Tea_Cmd.call(callbacks => ...)`, never `Tea_Cmd.promise`
- List conversion: `->List.fromArray` not `->Array.toList`
- Style attributes: `Attrs.style("property", "value")` (two string args)
- No JSX — all panels use `Tea_Html` element constructors
- `Events.onCheck` does not exist — use `Events.onClick`

## Engine Pattern

Every panel follows a consistent four-file pattern:

```
src/
├── model/XxxModel.res       # Types — state records, msg variants
├── core/XxxEngine.res        # Pure computation — no side effects
├── commands/XxxCmd.res        # Tauri invoke calls — side effects
└── components/Xxx.res         # View — Tea_Html rendering
```

| Layer | Responsibility | Testable? |
|-------|---------------|-----------|
| **Model** (`XxxModel.res`) | Type definitions — state, messages, sub-models | N/A (types only) |
| **Engine** (`XxxEngine.res`) | Pure functions — state transitions, filtering, formatting | Yes (Deno tests) |
| **Cmd** (`XxxCmd.res`) | Side effects — `Tauri.invoke`, `Tea_Cmd.call` | No (requires Tauri runtime) |
| **View** (`Xxx.res`) | `Tea_Html` rendering — maps model to virtual DOM | Integration tests |

There are 47 engine files in `src/core/`. Tests import the compiled `.res.js`
output from engines and exercise pure functions without needing a browser or
Tauri runtime.

## Clade System

Every panel belongs to a **clade** — a taxonomy entry defined in an A2ML file
under `panel-clades/clades/`. Clades provide:

- **Trait inheritance**: panels inherit capabilities from parent clades
- **Kind filtering**: the Clade Browser can filter panels by kind
- **Capability queries**: `PanelRegistry.panelHasTrait(id, clades, getter)`

There are 41 clade definitions. The `CladeBrowserEngine` resolves trait
inheritance chains. The Rust `clade_scanner` module reads `.a2ml` files from
disk and returns them to the frontend.

## BoJ Gateway

The Bundle of Joy (BoJ) server is PanLL's primary service gateway. When
`bojRouting` is enabled, panels route through BoJ cartridges instead of
direct HTTP calls:

| Protocol | Cartridge | Panels Using |
|----------|-----------|-------------|
| LSP (Language Server Protocol) | `lsp-mcp` | Editor Bridge |
| DAP (Debug Adapter Protocol) | `dap-mcp` | VM Inspector |
| BSP (Build Server Protocol) | `bsp-mcp` | Build Dashboard |
| Database queries | `database-mcp` | Databases, Panel-W |

BoJ exposes 17 cartridges total. The `boj/` Rust module proxies requests to
the BoJ server at `BOJ_URL` (default `http://localhost:7700/api/v1`). The
Umoja federation protocol enables peer-to-peer cartridge sharing between BoJ
instances.

## A2ML / K9 Integration Layer

**A2ML** (AI Markup Language) is the manifest format for AI agents. PanLL
reads `0-AI-MANIFEST.a2ml` files to understand repository structure and
configure panels automatically.

**K9** (Kennel) manages contractile configurations — validation rules and
layout constraints stored in `.a2ml` files. The K9 engine:
- Loads contractiles from `Trustfile.a2ml`
- Validates panel configurations against Yard contracts
- Applies layout constraints (isolation tiers, panel grouping)

The `a2ml/` and `k9/` Rust modules handle file I/O; the `A2mlEngine` and
`K9Engine` ReScript modules handle pure logic.

## Coprocessor Engine (Phase 1-3)

The coprocessor system offloads compute-intensive tasks:

| Phase | Layer | Purpose |
|-------|-------|---------|
| **Phase 1** | Control plane | CPU monitoring, task queuing, device discovery |
| **Phase 2** | Data plane (Zig FFI) | Direct FFI calls to compute engines (Axiom.jl, etc.) |
| **Phase 3** | Smart routing | Automatic dispatch: local (CPU<80%) / remote (neural) / BoJ (fallback) |

The `coprocessor/` Rust module exposes 8 commands for device discovery,
benchmarking, FFI loading, and smart dispatch. When local FFI is unavailable,
tasks fall back to BoJ cartridge invocation.

## Cognitive Governance

Six ambient systems monitor operator cognitive state:

| System | Purpose | Mechanism |
|--------|---------|-----------|
| **Vexometer** | Friction monitoring | Tracks cancellations + corrections, decays over 120s |
| **Anti-Crash Gate** | Circuit breaker | Validates neural output before it reaches Panel-W |
| **Orbital Drift Aura** | Stability indicator | Ambient visual cue for system health |
| **Feedback-O-Tron** | Performance reporting | Community-driven constraint suggestions |
| **Information Humidity** | UI density adaptation | High/Medium/Low modes adjust information density |
| **Dark Start** | Entry point | Architecture manifold bootstrapping |

These are not standalone panels — they operate as always-present subsystems
that influence the entire UI surface.

## Backend Architecture

```
┌─────────────────────────┐
│  ReScript Frontend      │  245 .res files, compiled to JS
│  (TEA cycle)            │
└────────┬────────────────┘
         │ Tauri invoke()
┌────────▼────────────────┐
│  Rust Backend (Tauri)   │  77 .rs files, 246 commands
│  src-tauri/src/         │  26 modules + main.rs
└────────┬────────────────┘
         │ HTTP / WebSocket / CLI
┌────────▼────────────────┐
│  External Services      │
│  - BoJ Server (:7700)   │
│  - TypeLL Server (:7800)│
│  - ECHIDNA (V-lang)     │
│  - Phoenix (:4000)      │
│  - Cloudflare API       │
│  - panic-attack CLI     │
│  - protocol-squisher CLI│
│  - my-lang CLI          │
└─────────────────────────┘
```

## Directory Structure

```
panll/
├── src/                      # ReScript frontend
│   ├── tea/                  # Custom TEA implementation (8 modules)
│   ├── model/                # Type definitions (XxxModel.res)
│   ├── core/                 # Pure engines (XxxEngine.res) — 47 files
│   ├── commands/             # Tauri invoke wrappers (XxxCmd.res)
│   ├── components/           # View functions (Xxx.res)
│   └── modules/              # Cross-cutting modules (PanelRegistry, etc.)
├── src-tauri/src/            # Rust backend
│   ├── main.rs               # Entry point, invoke_handler registration
│   └── <module>/commands.rs  # Per-module Tauri commands
├── tests/                    # Deno test files (45 files)
├── panel-clades/clades/      # A2ML clade definitions (41 clades)
├── public/                   # Static assets, index.html
├── docs/                     # Documentation
├── beam/panll_beam/          # Optional Elixir/BEAM middleware
└── deno.json                 # Task runner and import map
```
