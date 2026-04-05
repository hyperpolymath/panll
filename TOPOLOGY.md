<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Root-level architecture and module structure map -->
<!-- Last updated: 2026-04-03 -->

# PanLL — Topology

## Overview

PanLL (pronounced "parallel") is a panel-based development environment built on
The Elm Architecture (TEA) in ReScript. It serves as a cognitive-relief layer
(eNSAID) — a Human-Things Interface (HTI) that reduces friction, context-switching,
and cognitive overhead during development work.

The frontend is 686 ReScript source files organised into a strict TEA decomposition:
Model, Msg, Update, View, Commands, and Subscriptions. The backend is a Gossamer
shell (Zig + WebKitGTK) with 107 Rust modules handling IPC, filesystem, and
external service integration. 108 panels are defined across 118 clade definitions.

## Module Structure

```
src/
├── App.res                    Entry point — mounts TEA application
├── Model.res                  State composition root (includes domain modules)
├── Msg.res                    TEA message variants (top-level sum type)
├── Update.res                 State transition kernel
├── View.res                   Main view renderer — dispatches to panel components
├── Storage.res                localStorage persistence layer
├── SubscriptionsFixed.res     Keyboard + polling subscriptions
│
├── tea/                [18]   Custom TEA runtime (permanent, zero npm deps)
│   ├── Tea_App.res            Application lifecycle (mount/update/render)
│   ├── Tea_Html.res           Element constructors (no JSX)
│   ├── Tea_Render.res         Virtual DOM diff/patch engine
│   ├── Tea_Cmd.res            Command (side-effect) abstraction
│   ├── Tea_Sub.res            Subscription management
│   ├── Tea_Vdom.res           VDOM node types, ARIA attributes
│   ├── Tea_Debug.res          Debug utilities
│   ├── Tea_Json.res           JSON encoding/decoding
│   ├── Tea_Http.res           HTTP request commands
│   ├── Tea_Keyboard.res       Keyboard event handling
│   ├── Tea_Mouse.res          Mouse event handling
│   ├── Tea_Animationframe.res RequestAnimationFrame subscriptions
│   └── ...                    (18 modules total)
│
├── model/             [117]   Domain model types (one or more per panel)
│   ├── AccessibilityModel.res
│   ├── AerieModel.res
│   ├── AiModel.res
│   ├── CloudGuardModel.res    (CloudGuard panel state)
│   └── ...
│
├── msg/               [117]   Message types per panel domain
│   ├── A2mlMsg.res
│   ├── AerieMsg.res
│   ├── CloudGuardMsg.res
│   └── ...
│
├── update/             [74]   Update functions (state transitions per domain)
│   ├── UpdateAccessibility.res
│   ├── UpdateAerie.res
│   ├── UpdateBoj.res
│   └── ...
│
├── core/              [139]   Engine logic — computation, validation, integration
│   ├── A2mlEngine.res         A2ML manifest parsing engine
│   ├── AntiCrash.res          Neural token circuit breaker
│   ├── ConnectionManager.res  Service connection lifecycle
│   ├── Contractiles.res       Contract enforcement
│   ├── DebugLogger.res        Structured logging
│   ├── Decoders.res           JSON decoders
│   ├── DOMPurify.res          DOM sanitisation
│   ├── EventChain.res         Event propagation engine
│   ├── RuntimeBridge.res      Gossamer IPC bridge
│   ├── SmartRouter.res        Panel routing logic
│   ├── TilingEngine.res       Panel layout management
│   ├── TrustedTypes.res       Trusted Types policy
│   ├── UndoEngine.res         Undo/redo state management
│   ├── WindowBridge.res       Window API bridge
│   └── ...                    (139 modules total)
│
├── components/        [123]   Panel view components (Tea_Html renderers)
│   ├── AccessibilityToolbar.res
│   ├── Aerie.res
│   ├── Boj.res
│   ├── CloudGuard.res
│   ├── CladeBrowser.res
│   └── ...
│
├── commands/           [69]   Gossamer bridge command bindings (invoke wrappers)
│   ├── A2mlCmd.res
│   ├── AerieCmd.res
│   └── ...
│
├── modules/            [19]   Module registry, clade loader, TypeLL service
│   ├── PanelRegistry.res      Panel registration and lookup
│   ├── CladeLoader.res        Clade definition loading
│   ├── DatabaseModule.res     VeriSimDB integration module
│   ├── DatabaseRegistry.res   Database connection registry
│   ├── CloudGuardModule.res   CloudGuard domain module
│   ├── FarmModule.res         Farm domain module
│   └── ...
│
├── subscriptions/       [2]   TEA subscriptions
│   ├── KeyboardFixed.res      Keyboard shortcut handling
│   └── GossamerEvents.res     Gossamer backend event stream
│
├── panels/                    Panel-specific subdirectories
│   └── system-update/         System update panel assets
│
├── abi/                       ABI definitions
│   ├── cartridge-schema.json  BoJ cartridge ABI schema
│   └── README.md
│
├── generated/                 Auto-generated code
│   └── CartridgeAbi.res       Generated cartridge bindings
│
└── styles/
    └── input.css              Tailwind CSS input
```

### Backend (Gossamer — Rust)

```
src-gossamer/
├── src/               [107]   Rust backend modules
│   ├── main.rs                Gossamer application entry point
│   ├── farm/                  Repository inventory commands
│   ├── boj/                   BoJ cartridge routing (17 cartridges)
│   ├── cloudguard/            Cloudflare API integration (14 commands)
│   ├── overlay/               Aerie network commands (21 commands)
│   ├── plaza/                 License compliance commands
│   ├── minter/                Panel codegen backend
│   ├── coprocessor/           Coprocessor control plane
│   ├── valence_shell/         Terminal session management (12 commands)
│   ├── game_preview/          IDApTIK live preview (8 commands)
│   ├── vm_inspector/          Reversible VM debugger (7 commands)
│   ├── level_architect/       Level design backend (5 commands)
│   ├── dlc_workshop/          DLC/puzzle pack tools (8 commands)
│   ├── multiplayer_monitor/   Phoenix sync backend (6 commands)
│   ├── network_topology/      Network graph backend (4 commands)
│   ├── release_manager/       Release pipeline (5 commands)
│   └── ...
└── lib/                       Shared Rust library code
```

### Clade Definitions

```
panel-clades/
└── clades/            [118]   A2ML clade definitions
    ├── core-*.a2ml            Core panel clades
    ├── overlay-*.a2ml         Overlay panel clades
    ├── gamedev-*.a2ml         Game development panel clades (28)
    └── meta-*.a2ml            Cross-cutting service clades
```

### Tests

```
tests/                 [137]   Deno test files
├── tea_*.test.ts              TEA runtime tests
├── engine_*.test.ts           Engine unit tests (47 engines)
├── e2e_*.test.ts              End-to-end panel lifecycle tests (40)
├── integration_*.test.ts      Cross-panel integration tests
└── bench_*.test.ts            Performance benchmarks
```

## Architectural Decisions

### TEA Framework (permanent)

PanLL uses a custom TEA (The Elm Architecture) runtime in `src/tea/` — 18 modules
with zero npm dependencies. All UI follows the cycle:

```
Model -> Msg -> Update -> View -> (Cmd | Sub) -> ...
```

All state lives in `Model.model`. No global mutable state. No hooks, no Redux,
no MVC. The custom runtime includes VDOM diffing (`Tea_Render`), ARIA support
(`Tea_Vdom`), and animation frame subscriptions.

### Gossamer Integration

PanLL migrated from Tauri 2.0 to Gossamer (Zig + WebKitGTK). The Rust backend
in `src-gossamer/` provides IPC commands invoked from ReScript via
`src/core/RuntimeBridge.res`. The `GossamerEvents` subscription streams backend
events to the TEA message loop.

### VeriSimDB Backing

Panel state, feedback history, and diagnostic data persist to VeriSimDB (port 8080)
via the `DatabaseModule` and `DatabaseBridgeEngine`. Queries use VCL-total through
the BoJ database-mcp cartridge when `bojRouting` is enabled.

### Panel Organisation

108 panels are organised into categories:

| Category | Count | Description |
|----------|-------|-------------|
| Core panels | 3 | Panel-L (Symbolic), Panel-N (Neural), Panel-W (World) — always visible |
| General overlays | 14 | CloudGuard, VAB, Farm, Fleet, Hypatia, Reposystem, Aerie, Interfaces, Playgrounds, Plaza, Minter, Protocol-Squisher, My-Lang, BoJ |
| IDApTIK panels | 11 | Valence Shell, Game Preview, VM Inspector, Network Topology, Level Architect, Coprocessors, Multiplayer Monitor, DLC Workshop, Editor Bridge, Build Dashboard, Release Manager |
| Meta panels | 3 | Automation Router, Clade Browser, 7-Tentacles |
| Game dev panels | 28 | Clade definitions only (A2ML); ReScript implementation pending |
| Cross-cutting | 49 | TypeLL verification, A2ML/K9 integration, cognitive governance, provisioner |

The three core panels form a permanent tiled layout. Overlay panels appear one
at a time on top of them, activated via the panel switcher bar.

### TypeLL Verification Kernel

TypeLL provides cross-panel type intelligence. All 48 implemented panels are wired
to the verification kernel via `TypeCheckResult` messages. The `panelTypeChecks`
dictionary in the model tracks per-panel verification status.

### Cognitive Governance

Six always-present systems monitor operator state:

- **Vexometer** — friction index monitoring
- **Anti-Crash Gate** — neural token circuit breaker (all inference gated)
- **Orbital Drift Aura** — ambient stability indicator
- **Feedback-O-Tron** — BoJ-backed context persistence
- **Information Humidity** — UI density adaptation (High/Medium/Low)
- **Dark Start** — architecture manifold entry

### Coprocessor Engine

Three-phase coprocessor routing: local CPU (when load < 80%), remote neural,
and BoJ fallback. The control plane (`src/core/CoprocessorsEngine.res`) manages
dispatch; the Zig FFI data plane handles computation.

## Build and Test

```bash
# Compile ReScript modules
deno task res:build

# Full production build (Gossamer + bundle + CSS)
deno task build

# Development server (Gossamer + bundle + static on :8000)
deno task dev

# Run all tests
deno task test

# Test with coverage
deno task test:coverage

# ReScript watch mode
deno task res:watch
```

## Integration Points

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Gossamer shell | — | IPC | Desktop webview host (Zig + WebKitGTK) |
| ECHIDNA | 9000 | HTTP | Theorem prover dispatch |
| VeriSimDB | 8080 | HTTP/VCL-total | 8-modality versioned database |
| BoJ-Server | 7700 | HTTP | Cartridge server (17 cartridges) and protocol gateway |
| TypeLL | 7800 | HTTP | Cross-panel type verification kernel |
| Hypatia | — | HTTP (Elixir) | Neurosymbolic CI/CD intelligence |
| gitbot-fleet | — | HTTP (Axum) | Bot orchestration (rhodibot, echidnabot, etc.) |
| Aerie | — | HTTP (V-lang) | Network analysis API |
| NQC proxy | 4000 | HTTP | Code execution sandbox |
| Groove | — | IPC/HTTP | Universal service discovery and capability negotiation |

## File Counts (as of 2026-04-03)

| Directory | .res files | .rs files | Description |
|-----------|-----------|-----------|-------------|
| `src/tea/` | 18 | — | Custom TEA runtime |
| `src/model/` | 117 | — | Domain model types |
| `src/msg/` | 117 | — | Message types |
| `src/update/` | 74 | — | Update functions |
| `src/core/` | 139 | — | Engine logic |
| `src/components/` | 123 | — | View components |
| `src/commands/` | 69 | — | Gossamer IPC commands |
| `src/modules/` | 19 | — | Registries and services |
| `src/subscriptions/` | 2 | — | TEA subscriptions |
| `src/*.res` | 7 | — | Top-level TEA wiring |
| `src-gossamer/` | — | 107 | Rust backend |
| **Total source** | **685** | **107** | **792 files** |
| `tests/` | — | — | 137 test files |
| `panel-clades/clades/` | — | — | 118 A2ML clade definitions |

## See Also

- `docs/architecture/TOPOLOGY.md` — detailed completion dashboard and cross-panel communication map
- `docs/architecture/PANEL-INVENTORY.md` — full catalog of all 108 panels
- `docs/architecture/ARCHITECTURE.md` — architectural narrative
- `docs/decisions/DESIGN-DECISIONS.md` — ADR log
- `docs/ENSAID.adoc` — eNSAID philosophy and design rationale
