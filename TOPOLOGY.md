<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# PanLL eNSAID — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              HUMAN OPERATOR             │
                        │        (Binary Star Co-orbit)           │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           PANLL INTERFACE (HTI)         │
                        │  ┌───────────┐  ┌───────────┐  ┌───────┐│
                        │  │ Pane-L    │  │ Pane-N    │  │ Pane-W││
                        │  │ (Symbolic)│  │ (Neural)  │  │(World)││
                        │  └─────┬─────┘  └─────┬─────┘  └───┬───┘│
                        └────────│──────────────│────────────│────┘
                                 │              │            │
                                 ▼              ▼            ▼
                        ┌─────────────────────────────────────────┐
                        │           UI LAYER (RESCRIPT TEA)       │
                        │    (Model-Update-View, Vexometer)       │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ TAURI BACKEND (RUST)  │  │ BEAM MIDDLEWARE (ELIXIR)       │
                        │ - OS Commands         │  │ - HTTP / GraphQL / gRPC        │
                        │ - File I/O            │  │ - Container Runtime            │
                        │ - Anti-Crash Gate     │  │ - State Orchestration          │
                        └──────────┬────────────┘  └──────────┬─────────────────────┘
                                   │                          │
                                   └────────────┬─────────────┘
                                                ▼
                        ┌─────────────────────────────────────────┐
                        │          EXTERNAL TOOLING               │
                        │  ┌───────────┐  ┌───────────┐  ┌───────┐│
                        │  │ panic-    │  │ feedback- │  │ ESN / ││
                        │  │ attack    │  │ o-tron    │  │ LSM   ││
                        │  └───────────┘  └───────────┘  └───────┘│
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Deno Task Runner   .machine_readable/  │
                        │  Tailwind v4        0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
USER INTERFACE (HTI)
  Three-Pane Layout (L/N/W)         ██████████ 100%    Barycentre interaction verified
  Vexometer (Friction Monitor)      ██████████ 100%    Real-time polling active
  ReScript TEA Implementation       ██████████ 100%    Model-Update-View stable
  Keyboard Shortcuts                ██████████ 100%    Ctrl+Shift L/N/B/W active

CORE SYSTEMS
  Anti-Crash Gate                   ██████████ 100%    Neural token gating verified
  Tauri 2.0 Backend                 ██████████ 100%    All 8 commands functional
  BEAM API Modes                    ██████████ 100%    HTTP/GraphQL/gRPC selectable
  panic-attack integration          ██████████ 100%    Event-chain import stable

REPO INFRASTRUCTURE
  Deno Tooling (npm -> Deno)        ██████████ 100%    Build/Test orchestration verified
  .machine_readable/                ██████████ 100%    STATE tracking active
  Test Suite (109 passing)          ██████████ 100%    High JS/Rust coverage

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████████░  ~92%   v0.1.0-alpha Production Ready
```

## Key Dependencies

```
Human Operator ──► Vexometer ──► ReScript TEA ──► Result (Pane-W)
     │               ▲               │               ▲
     ▼               │               ▼               │
Neural Stream ──► SLM/LLM ────► Anti-Crash Gate ──► Result
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
