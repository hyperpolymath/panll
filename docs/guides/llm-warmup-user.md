# PanLL LLM Warmup (User Context)

## What This Is

PanLL (eNSAID) is a three-panel neurosymbolic AI development environment.
License: MPL-2.0. Author: Jonathan D.A. Jewell.

## Architecture (30-second version)

- **ReScript** frontend using **TEA** (The Elm Architecture): Model -> Msg -> Update -> View
- **Gossamer** backend (Rust + WebKitGTK) — NOT Tauri
- **106 panels** across three panes: Panel-L (Symbolic), Panel-N (Neural), Panel-W (World)
- Optional **Elixir/BEAM** middleware in `beam/`
- **Zig FFI** layer in `ffi/zig/`

## Three Panels

| Panel | Name | Purpose |
|-------|------|---------|
| L | Symbolic Mass | Formal constraints, proof editor |
| N | Neural Stream | Inference tokens, ECHIDNA advisor |
| W | World Barycentre | Task canvas, VeriSimDB, security |

## Cognitive Governance

- **Anti-Crash**: Circuit breaker validating all neural tokens
- **Vexometer**: Operator friction tracking (0.0 calm to 1.0 frustrated)
- **Orbital Sync**: Cross-panel synchronisation
- **Contractiles**: Elastic state contracts

## Key Commands

```bash
just dev          # Full dev environment (Gossamer + watchers)
just serve        # Browser-only dev
just test         # 979 tests, 41 suites
just build        # Production build
just mock         # Mock ECHIDNA prover (port 9000)
just doctor       # Check toolchain
```

## Ports

| Port | Service |
|------|---------|
| 8000 | Dev server |
| 9000 | ECHIDNA theorem prover |
| 8080 | VeriSimDB (external) |
| 7700 | BoJ server (external) |

## Prerequisites

Deno >= 2.0, ReScript >= 12.0, Rust/Cargo >= 1.80, Zig >= 0.13, just >= 1.25.
Optional: Elixir >= 1.16 (for beam/ middleware).

## Key Files

| File | Role |
|------|------|
| src/Model.res | State composition root |
| src/Msg.res | TEA message variants |
| src/Update.res | State transition kernel (~7500 lines) |
| src/View.res | Root view renderer |
| src/tea/ | Custom TEA runtime (18 modules) |
| src/core/ | Engines: AntiCrash, OrbitalSync, TypeLLEngine |
| src-gossamer/ | Rust backend |

## Rules

- No TypeScript. ReScript only.
- No npm/bun. Deno only (ReScript + Tailwind run via `npm:` specifiers in `deno.json`).
- Panels, not panes.
- TEA pattern only. All state in Model.model.
- Anti-Crash validates ALL neural tokens.

## Related Projects

ECHIDNA (prover), VeriSimDB (database), panic-attack (security),
BoJ server (protocol gateway), TypeLL (type verification).
