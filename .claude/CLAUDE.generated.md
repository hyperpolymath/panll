<!-- K9 Coordination Protocol — Generated for Claude Code -->
<!-- Source: coordination.k9 | Generated: 2026-04-03 -->
<!-- Re-generate: deno run --allow-read --allow-write generate.js coordination.k9 -->

# PanLL — AI Coordination Rules

> **Auto-generated from `coordination.k9`** — do not edit directly.
> Re-generate with: `deno run --allow-read --allow-write generate.js coordination.k9`
> Source of truth: `coordination.k9` in repository root.

## Project

Neurosymbolic IDE built on the Binary Star model — human (symbolic, Panel-L) and machine (neural, Panel-N) orbiting a shared world state (Panel-W). 106 panels, custom TEA runtime, Gossamer desktop backend.

**Languages:** ReScript, Rust, Elixir, JavaScript
**License:** PMPL-1.0-or-later
**Build system:** just
**Runtime:** deno

## Build Commands

| Command | Description |
|---------|-------------|
| `just build` | Full build (ReScript + CSS + bundle) |
| `just res` | ReScript compile only |
| `just bundle` | esbuild bundle |
| `just css` | Build CSS |
| `just dev` | Start dev server on port 8000 |
| `just test` | Run test suite (979 tests, 41 suites) |
| `just coverage` | Run tests with coverage |
| `just lint` | Lint ReScript source |
| `just doctor` | Run project health checks |

## INVARIANTS — Do Not Violate

These rules are non-negotiable. Violating them will break the project
or contradict deliberate architectural decisions.

### [CRITICAL] custom-tea-runtime

**Rule:** The custom TEA runtime in src/tea/ (18 modules) must NEVER be replaced with rescript-tea or any other library

**Why:** rescript-tea was deliberately evaluated and rejected. The custom TEA runtime handles PanLL-specific needs: Anti-Crash circuit breaking, Vexometer cognitive load adaptation, OrbitalSync multi-panel state coherence, and panel lifecycle management. It is not legacy — it is the architecture.

### [CRITICAL] no-typescript

**Rule:** Do not introduce TypeScript files — ReScript is the frontend language

**Why:** ReScript provides better type safety with less overhead. This is a deliberate, ecosystem-wide decision.

### [CRITICAL] no-tauri

**Rule:** Do not introduce Tauri references or dependencies — Gossamer is the desktop backend

**Why:** PanLL was migrated FROM Tauri 2.0 TO Gossamer. This migration is complete and intentional.

### [CRITICAL] tea-pattern-only

**Rule:** All state management uses TEA (Model -> Msg -> Update -> View) — no MVC, Redux, hooks, or other patterns

**Why:** TEA is foundational to PanLL's architecture. Model.res holds all state, Msg.res defines all messages, Update.res is the state transition kernel.

### [CRITICAL] all-state-in-model

**Rule:** ALL application state lives in Model.model — no global mutable state, no module-level state, no window.* state

**Why:** TEA requires single state tree. Anti-Crash and OrbitalSync depend on this invariant for correctness.

### [CRITICAL] no-npm-bun

**Rule:** No npm, Bun, pnpm, or yarn — Deno is the orchestrator

**Why:** npm is used ONLY for the ReScript compiler (which requires it). All other tooling uses Deno. Do not add npm dependencies.

### [CRITICAL] anticrash-validates-all

**Rule:** Anti-Crash circuit breaker validates ALL neural tokens before symbolic execution — never bypass this

**Why:** Safety-critical: prevents untrusted neural output from corrupting symbolic state. The validation path exists for a reason.

### [HIGH] panels-not-panes

**Rule:** UI elements are called 'panels', NEVER 'panes', 'tabs', or 'windows'

**Why:** PanLL naming convention — 'panels' is the correct term everywhere in code, docs, and communication

### [CRITICAL] no-bulk-panel-deletion

**Rule:** Do not delete more than 2 panel files in a single operation without explicit user approval

**Why:** 106 panels have complex interdependencies. Bulk deletion can cascade and break OrbitalSync.

### [HIGH] gossamer-bridge-pattern

**Rule:** Gossamer commands in src/commands/ are invoke wrappers only — do not put business logic there

**Why:** Business logic belongs in Update.res. Commands are thin bridges to the Gossamer backend.

### [CRITICAL] binary-star-model

**Rule:** The Binary Star architecture (Panel-L symbolic + Panel-N neural + Panel-W world) is deliberate — do not flatten into a single panel type

**Why:** The three panel types serve fundamentally different roles. This is the core design of PanLL.

### [CRITICAL] rescript-core-team

**Rule:** The project owner is on the ReScript core team — do not suggest migrating away from ReScript

**Why:** ReScript is not a temporary choice. The owner contributes to ReScript itself.

## Protected Files and Directories

Do NOT delete, reorganise, or replace these without explicit user approval:

| Path | Reason |
|------|--------|
| `src/tea/` | Custom TEA runtime — 18 modules. NEVER replace with rescript-tea. |
| `src/Model.res` | Single state tree — all application state lives here |
| `src/Msg.res` | Message type definitions — the TEA message catalogue |
| `src/Update.res` | State transition kernel — ~7500 lines, the heart of PanLL |
| `src/View.res` | Root view renderer |
| `src/App.res` | Application entry point |
| `src/core/` | Core engines — AntiCrash, OrbitalSync, Contractiles, TypeLLEngine, VabEngine |
| `src/components/` | 106 panel views — do not bulk-delete |
| `src/commands/` | Gossamer bridge commands — thin wrappers only |
| `src/modules/` | Module registry + TypeLLService — cross-panel type intelligence |
| `src-gossamer/` | Rust backend (WebKitGTK) — Gossamer desktop integration |
| `beam/` | Elixir/BEAM API layer |
| `tests/` | 979 tests, 41 suites — never delete tests |
| `.machine_readable/` | Canonical location for A2ML state files — MUST stay here |
| `coordination.k9` | This file — source of truth for AI coordination |

## Architecture Decisions (Deliberate)

These choices may look unusual but are intentional:

### gossamer-not-tauri

**Decision:** Gossamer (Zig + WebKitGTK) is the desktop backend — migration from Tauri 2.0 is complete

**Why:** Gossamer is the hyperpolymath desktop runtime. Tauri was used previously but replaced.

**Rejected alternatives:** Tauri 2.0, Electron, native GTK

### custom-tea-not-rescript-tea

**Decision:** Custom TEA runtime (src/tea/, 18 modules) instead of the rescript-tea library

**Why:** PanLL needs Anti-Crash integration, OrbitalSync, Vexometer hooks, and panel lifecycle — none available in rescript-tea

**Rejected alternatives:** rescript-tea, Redux, MobX, React hooks pattern

### deno-npm-hybrid

**Decision:** Deno orchestrates everything, but npm is used solely for the ReScript compiler

**Why:** ReScript compiler requires npm — this is the ONLY permitted npm usage. Do not extend npm's role.

### binary-star

**Decision:** Three panel types: Panel-L (symbolic/human), Panel-N (neural/machine), Panel-W (world/shared)

**Why:** Neurosymbolic architecture requires clear separation of human reasoning, machine inference, and shared world state

### vexometer-cognitive-load

**Decision:** Vexometer monitors operator stress and adapts UI detail density

**Why:** HTI (Human-Tool Interaction) principle — the IDE adapts to the human, not vice versa

### anticrash-circuit-breaker

**Decision:** Anti-Crash validates all neural tokens before they enter the symbolic pipeline

**Why:** Safety boundary between neural and symbolic systems — prevents hallucinated code from corrupting state

## Do NOT Create

These files, patterns, or systems must NOT be introduced:

- ****/*.ts** — TypeScript is banned — use ReScript
- **Dockerfile** — Use Containerfile (Podman, not Docker)
- ****/*.py** — Python is banned — use ReScript, Rust, or Elixir
- **A replacement TEA runtime or state management library** — src/tea/ is the TEA runtime — it is custom, deliberate, and must not be replaced
- **REST API endpoints parallel to existing Groove protocol endpoints** — Groove is the inter-service communication protocol — do not create REST alternatives
- **A new panel type beyond Panel-L, Panel-N, Panel-W** — Binary Star model has exactly three types — adding more would break OrbitalSync
- **Direct Tauri imports or tauri.conf.json** — Tauri migration to Gossamer is complete — do not reintroduce

## Terminology

Use the correct terms for this project:

- Say **"panels"**, NOT "panes", "tabs", "windows"
  - PanLL UI elements are always called panels — this is enforced everywhere
- Say **"Binary Star"**, NOT "dual-pane", "split-view", "two-panel"
  - The architectural model is Binary Star (Panel-L + Panel-N orbiting Panel-W)
- Say **"Anti-Crash"**, NOT "validator", "sanitizer", "filter"
  - The neural token validation system is called Anti-Crash
- Say **"Vexometer"**, NOT "stress meter", "load indicator", "fatigue tracker"
  - The cognitive load monitoring system is called Vexometer
- Say **"OrbitalSync"**, NOT "state sync", "panel sync", "sync engine"
  - The multi-panel state coherence system is called OrbitalSync

## Port Assignments

| Service | Port |
|---------|------|
| dev-server | 8000 |
| echidna | 9000 |
| verisim | 8080 |
| boj-server | 7700 |
| typell | 7800 |

## Ecosystem Context

**Depends on:**
- **gossamer** — Desktop backend runtime (Zig + WebKitGTK)
- **verisim** — Persistent storage layer
- **typell** — Type intelligence engine — cross-panel type checking
- **boj-server** — MCP server — all external tool integration

**Consumed by:**
- **idaptik** — Uses PanLL as level editor for game content

**Related projects:**
- **echidna** — Proof engine — formal verification integration
- **hypatia** — Neurosymbolic CI/CD scanning
- **panic-attack** — Security scanning tool
- **gitbot-fleet** — Bot orchestration (rhodibot, echidnabot, etc.)
- **proven** — Formally verified alternatives library
