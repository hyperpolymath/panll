# SPDX-License-Identifier: CC-BY-SA-4.0
# PanLL — Project-Specific Claude Instructions

## Build Commands

> **Stale:** #108 removed `deno.json`, so the `deno task` commands in this file
> and the Deno steps in `.github/workflows/build-validation.yml` no longer run.
> There is no JS manifest in the repo yet; a Bun `package.json` + `bun.lock` is
> the replacement (see Critical Rules).

```bash
# Compile ReScript modules
npx rescript build

# Bundle JS output
deno run -A scripts/bundle.ts

# Build Tailwind CSS
deno task css:build

# Full production build (Gossamer + bundle + CSS)
deno task build
```

## Development

```bash
# Dev server (Gossamer + bundle + static server on http://localhost:8000/public/)
deno task dev

# ReScript watch mode
npx rescript build -w

# Tailwind watch mode
deno task css:watch
```

## Testing

```bash
# Run all tests
deno task test

# Watch mode
deno task test:watch

# Coverage
deno task test:coverage
```

## Architecture

- **TEA (The Elm Architecture)** in ReScript — Model/Msg/Update/View/Subscriptions
- **Gossamer** (Zig + WebKitGTK) backend — migrated from Tauri 2.0
- **Elixir/BEAM** optional middleware (`beam/panll_beam`)
- **106 panels** across four panes: Panel-A (Ambient), Panel-L (Logic, role: Symbolic), Panel-N (Neural), Panel-W (World). Panel-L + Panel-N orbit Panel-W in the Binary Star core; Panel-A surrounds as ambient substrate.

## Key Files

| File | Purpose |
|------|---------|
| `src/View.res` | Main view renderer — dispatches to panel components |
| `src/Update.res` | State transition kernel (~7500 lines) |
| `src/Model.res` | State composition root (includes domain modules) |
| `src/Msg.res` | TEA message variants |
| `src/App.res` | Application entry point |
| `src/Storage.res` | localStorage persistence layer |
| `src/tea/` | Custom TEA runtime (18 modules — permanent, not rescript-tea) |
| `src/model/` | Domain type modules (PaneModel, EchidnaModel, VeriSimModel, GovernanceModel, etc.) |
| `src/core/` | Engines (AntiCrash, OrbitalSync, Contractiles, TypeLLEngine, VabEngine, etc.) |
| `src/commands/` | Gossamer bridge commands (invoke wrappers) |
| `src/components/` | Panel view components |
| `src/modules/` | Module registry + TypeLLService (cross-panel type intelligence) |
| `src-gossamer/` | Rust backend (migrated from src-tauri/) |

## Critical Rules

- **NEVER use Tauri** — project migrated to Gossamer. All backend refs use `src-gossamer/`
- **NEVER use TypeScript** — AffineScript only (ReScript is also banned; RS/TS/JS → AffineScript → typed-wasm)
- **JS runtime: Bun** (estate primary, owner 2026-10-14), then pnpm, then npm. Deno is retired estate-wide (2026-09-22): add no new Deno tooling. npm is still how the ReScript compiler is fetched until AffineScript replaces it.
- **Panels, not panes** — PanLL uses "panels" terminology
- **TEA pattern only** — no MVC, no Redux, no hooks. Model -> Msg -> Update -> View
- **All state in Model.model** — no global mutable state
- **Anti-Crash validates ALL neural tokens** — no inference bypasses the circuit breaker

## ReScript Conventions

- Use `list{}` for vdom children: `Tea_Html.div(list{}, list{...})`
- Use `Events.onClick` / `Events.onInput` for event handlers
- Pattern match exhaustively on all variant types
- Domain model types go in `src/model/` — `Model.res` only composes via `include`
- Command wrappers go in `src/commands/` using `Tea_Cmd.call` pattern

## Ports and Services

| Service | Port | Purpose |
|---------|------|---------|
| Dev server | 8000 | Static file server for Gossamer webview |
| ECHIDNA | 9000 | Theorem prover dispatch (mock: `deno task mock:echidna`) |
| VeriSimDB | 8080 | 8-modality versioned database |
| BoJ server | 7700 | Cartridge server and protocol gateway |
| TypeLL | 7800 | Type verification kernel |

## License

- **Code** (all original source files): `MPL-2.0`
- **Documentation** (prose `.adoc` / `.md`): `CC-BY-SA-4.0`
- Licence texts live in `LICENSES/`; GitHub detects the repo as MPL-2.0 from the root `LICENSE`.
- Quantum-Safe Provenance specification: `EXHIBIT-B-QUANTUM-SAFE.txt` (additive supplement, MPL-2.0).

(Estate policy: sole-owner repos are MPL-2.0; the prior `PMPL-1.0-or-later`
declaration is superseded. NOTE for agents: the **Palimpsest Plaza** panel
(`panel-clades/clades/plaza/`, `src/**/Plaza*`, `src-gossamer/src/plaza/`)
references PMPL as a *feature subject* — a PMPL-adoption/compliance hub. Those
PMPL strings are intentional product content, NOT this repo's licence; do not
sweep them.)

## Asking the owner

Put every question that needs the owner's decision through the selector
(the AskUserQuestion tool), not as prose at the end of a report. Batch up to
four per call, offer concrete options with the recommended one first, and say
what each option would cause.
