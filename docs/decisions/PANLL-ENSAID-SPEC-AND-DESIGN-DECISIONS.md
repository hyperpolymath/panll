# PanLL eNSAID Specification & Design Decisions
**Compiled: 2026-03-14**
**Source: panll/docs/DESIGN-DECISIONS.md + panll/docs/DESIGN-2026-03-08-idaptik-ensaid.md**

---

# PART 1: eNSAID DESIGN DECISIONS (DD-001 to DD-018)

<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

**Last updated: 2026-03-02**
**Living document — updated as decisions are made or revised**

## DD-001: eNSAID Is a Specification, PanLL Is an Implementation

**Date:** 2026-02-27
**Status:** Accepted
**Context:** Need to separate the idea from the tool so others can build competing implementations.

**Decision:** eNSAID (Environment for NeSy-Agentic Integrated Development) is a specification. PanLL is the reference implementation. The spec lives in its own repo with its own governance. PanLL claims `IMPLEMENTS eNSAID` and that claim is verifiable.

**Consequences:**
- Contributors contribute to the eNSAID ecosystem, not just PanLL
- Every panel written works with any compliant eNSAID environment
- Pattern: HTTP → Apache/Nginx/Caddy. SQL → Postgres/MySQL. LSP → every language server.
- If someone builds a better eNSAID, the idea survives

**The V for Vendetta Principle:** You can kill PanLL. You cannot kill the idea. Ideas are bulletproof.

---

## DD-002: Binary Star Architecture (Human-Machine Co-Orbit)

**Date:** 2026-01-15
**Status:** Accepted
**Context:** Traditional IDEs treat AI as subordinate tool. Need genuine co-working.

**Decision:** Model Human and Machine as Binary Star system — two gravitationally bound entities orbiting a shared Barycentre (the task). Three panels: Panel-L (Symbolic/Human constraints), Panel-N (Neural/Machine reasoning), Panel-W (World/Barycentre results). Neither Human nor Machine is primary.

**Consequences:**
- Operator sees Machine reasoning in real-time (Panel-N)
- Machine constrained by symbolic rules visible to both (Panel-L)
- Shared output space validates mutual understanding (Panel-W)
- Higher cognitive load initially, offset by Vexometer monitoring

---

## DD-003: The Elm Architecture (TEA) for State Management

**Date:** 2026-01-20
**Status:** Accepted
**Context:** Complex UI with 14 panels, cognitive governance, orbital tracking needs deterministic state.

**Decision:** Model-Update-View with Commands and Subscriptions. Single immutable model record. All state changes flow through typed messages. Custom TEA implementation extended for PanLL's needs.

**Technical detail:** The main `model` type composes all domain slices via `include` re-exports. Each panel has its own Model/Engine/Cmd/Component files following a proven 8-file pattern.

---

## DD-004: Panel Module Pattern (8 Files Per Panel)

**Date:** 2026-03-01
**Status:** Accepted
**Context:** Need a repeatable, consistent pattern for adding panels.

**Decision:** Every panel follows exactly 8 files:

| Layer | ReScript | Rust (if backend needed) |
|-------|----------|--------------------------|
| Types | `src/model/XModel.res` | `src-tauri/src/x/types.rs` |
| Engine | `src/core/XEngine.res` | — |
| Commands | `src/commands/XCmd.res` | `src-tauri/src/x/commands.rs` |
| Component | `src/components/X.res` | `src-tauri/src/x/mod.rs` |

Plus wiring into 5 global files: Msg.res, Model.res, Update.res, View.res, main.rs

**Consequences:**
- Panel Minter can generate this structure automatically
- Every panel is structurally identical — contributors know where everything is
- Engine files are pure functions (no side effects) — fully testable
- Cmd files handle Tauri IPC — all effects isolated

---

## DD-005: Three-Tier Panel Isolation (Native / Standard Pod / Hardened Pod)

**Date:** 2026-03-02
**Status:** Accepted

| Tier | Runtime | Security | Performance | Use Case |
|------|---------|----------|-------------|----------|
| **Native** | In-process (Tauri webview) | Full trust, hash-verified | Fastest | Core 14 panels |
| **Standard Pod** | Alpine + Podman container | Process isolation, network limited | Moderate overhead | Community panels, trusted |
| **Hardened Pod** | Stapeln + Chainguard image | Full Stapeln security stack, minimal attack surface | Higher overhead | Untrusted/experimental panels |

---

## DD-006: Qubes-Style Code Provenance Map

**Date:** 2026-03-02
**Status:** Accepted

Always-visible ambient trust surface (not a toggle). Parses git blame + Co-Authored-By headers.

| Level | Colour | Meaning |
|-------|--------|---------|
| Verified | Green | Formally verified, proof-checked, no believe_me |
| Human-Reviewed | Blue | Human author or human commit after AI |
| AI-Assisted | Amber | Co-authored, no subsequent human review |
| Unreviewed AI | Red | Pure AI, no human in chain |
| Unknown | Grey | Pre-git or no attribution |

**Hostile UX:** Unreviewed AI code gets pulsing red borders and increased visual friction. Users CAN suppress this, but the suppression action is itself visible ("pulled the smoke alarm battery").

---

## DD-007: Cognitive Governance Stack

**Date:** 2026-01-25
**Status:** Accepted

Four interconnected governance systems:

1. **Anti-Crash Gate** — Circuit breaker between Panel-N output and Panel-W workspace. Every neural token validated against Panel-L constraints before reaching shared space.
2. **Vexometer** — Friction monitor tracking cancellations, corrections, dwell time. Index 0.0–1.0 triggers anti-inflammatory UI adjustments.
3. **Information Humidity** — UI density adapts to stress. High humidity (relaxed) = more detail. Low humidity (stressed) = essential info only.
4. **Orbital Drift Aura** — Ambient visual (background colour shift) indicating system stability.

These feed each other: Feedback-O-Tron → Vexometer → Humidity → UI adaptation.

---

## DD-008: Accessibility as Core, Not Afterthought

**Date:** 2026-02-27
**Status:** Accepted

Accessibility is in the CORE infrastructure:
- Panel Minter produces accessible panels by default (harder to make inaccessible than accessible)
- Every colour system ships with 4 accessibility palettes
- Every keyboard interaction works without a mouse
- Screen reader semantics (ARIA) in every component template
- Renamed broader concept to "information/cognitive ergonomics"

---

## DD-009: Trust & Blame Separation

**Date:** 2026-02-27
**Status:** Accepted

Two-tier trust model:

1. **PanLL Core is hash-locked** — TEA framework, Tea_Vdom, Tea_Html, panel switcher, HAR are content-hashed. If core hashes don't match: `CORE_HASH_MISMATCH`, instantly detectable.
2. **Panels are author-signed** — Each panel manifest: `author: <name>, signed: <key>`. PanLL doesn't approve third-party panels, just hosts them. Blame is cryptographically attributable.

---

## DD-010: Panel Taxonomy (Cladistic Classification)

**Date:** 2026-03-02
**Status:** Accepted

Linnaean/cladistic hierarchy with EMPTY BRANCHES visible:

| Level | Example |
|-------|---------|
| Kingdom | Development, Operations, Governance, Analysis |
| Phylum | Security, Languages, Databases, Infrastructure |
| Class | Static Analysis, Runtime Monitoring, Formal Verification |
| Order | Vulnerability Scanning, Compliance, Dependency Audit |
| Family | Web Security, Network Security, Supply Chain |
| Genus | Cloudflare Management, WordPress Hardening |
| Species | CloudGuard, Wharf |

Empty nodes are specification slots, not stubs. Contributors see gaps and naturally fill them.

---

## DD-011: Notepad++ Community as First Target

**Date:** 2026-03-02
**Status:** Accepted

Target the Notepad++ community first. Metaphor: PanLL doesn't replace Notepad++ — it wraps around it. "The bionic Notepad++ user in a mech suit."

---

## DD-012: Feedback-O-Tron as Opinion Mining System

**Date:** 2026-03-02
**Status:** Proposed

Three-tier system:
1. **Panel Pulse** — Opinion mining extracts structured sentiment from feedback
2. **Prioritisation engine** — Maps sentiment to panel development priority
3. **Reusable infrastructure** — Same system usable by any product, not just PanLL

---

## DD-013: Triaxial Development Framework (TSDM)

**Date:** 2026-03-02
**Status:** Accepted

**Axis 1 — Scope:** must (5), intend (3), like (1)
**Axis 2 — Maintenance:** corrective (5), adaptive (3), perfective (1)
**Axis 3 — Audit:** systems (5), compliance (3), effects (1)

Combined score: must+corrective+systems = 15 (do immediately), like+perfective+effects = 3 (backlog).

---

## DD-014: FOSS-First Funding Strategy

**Date:** 2026-03-02
**Status:** Accepted

Everything is MPL-2.0. Funding buys acceleration, not access. "Is it really worth trying to compete with a crazy academic, or just give him the money?"

---

## DD-015: ReScript Technical Patterns

**Date:** 2026-03-02
**Status:** Accepted (standing reference)

Key patterns:
- `Tea_Cmd.call(callbacks => { ... callbacks.enqueue(tagger(result)) ... })` for Tauri commands
- `@module("@tauri-apps/api/core") external invoke` for Tauri bindings
- `input(attrs, list{})` — Tea_Html input takes 2 args, not 1
- `Attrs.style("width", "50%")` — two args (key, value), not single string
- No emoji literals in ReScript
- `exception` and `constraint` are reserved — use `domainExc` and `rule`

---

## DD-016: Code MRI — Mutual Recognition & Integrity

**Date:** 2026-03-02
**Status:** Accepted

Four-layer system:

**Layer 0 — VoiceTag (Input):** Interactive annotation on code regions. Voice-activated (Web Speech API) but also keyboard/mouse. Tags numbered per file.

**Layer 1 — Blake3 Provenance Chain:** Every code region gets a Blake3 hash covering content + author + timestamp + parent hash. Strip attribution? Hash mismatch — instantly detectable. Turnitin model flipped: collaborative attribution, not adversarial plagiarism detection.

**Layer 2 — VeriSimDB Development Timeline:** Development-as-time-series database. Scrub a timeline slider to see the project state at any point — like the end credits of a worldbuilder documentary.

**Layer 3 — Pattern Diagnostics & Gamification:** Derive development patterns from timeline data. Victory conditions: all TODOs resolved, zero panic-attack findings, Vexometer below threshold.

**Layer 4 — Attribution-to-Licensing Link:** Blake3 provenance chains auto-generate license attribution sections.

---

## DD-017: Care-On / Eco-Mode Tags and Adaptive Constraint Sensitivity

**Date:** 2026-03-02
**Status:** Accepted

Tag modes:
- `care-on` — Extra scrutiny. Raises panic-attack sensitivity.
- `eco-mode` — Flags excessive allocation, energy-intensive loops.
- `burden` — "I know this is a problem but the fix requires a serious rewrite."

Integrates with triaxial framework: eco-mode bumps to max priority, burden lowers audit axis.

---

## DD-018: Dogfood Mode — Self-Hosting Policy Engine

**Date:** 2026-03-02
**Status:** Accepted

Dogfood management with CRG-grade-driven policy:
- Grade D+ (Alpha): **Suggest**
- Grade E (Minimal): **Warn**
- Grade X/F (Untested/Harmful): **Ban**
- **Insist**: configurable per tool (no override)

---

---

# PART 2: PanLL as eNSAID for IDApTIK Development

**Date**: 2026-03-08
**Author**: Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
**Status**: Design (MuSCoCA-classified)

## Overview

This document designs PanLL as an **eNSAID** (Environment for NeSy-Agentic Integrated Development) tailored for IDApTIK game development — a collaborative parent-child workbench where Jonathan and his son can build, test, debug, visualise, and evolve the IDApixiTIK game together.

The key insight: IDApTIK is a **reversible-computation stealth puzzle game** with a VM, multiplayer sync server, coprocessor system, device network topology, and formal verification layer. PanLL's three-panel neurosymbolic model maps directly onto this:

| PanLL Panel | IDApTIK Mapping |
|-------------|-----------------|
| **Panel-L** (Symbolic) | VM instruction constraints, level rules, device defence flags, protocol specs |
| **Panel-N** (Neural) | ECHIDNA proof advisor for VM correctness, AI-assisted level design, NeSy reasoning |
| **Panel-W** (World) | Game preview, network topology view, device dashboard, telemetry |

---

## The IDApTIK Panel Suite (11 panels)

### Panel 1: Valence Shell (MUST)
Embedded Valence shell running inside a PanLL panel. Full reversible filesystem ops, PTY allocation via Tauri shell plugin, Claude Code integration, session recording (asciinema format), shared session mode with approval gate.

### Panel 2: Game Preview (MUST)
Live game preview via iframe/Tauri webview. Hot-reload, pause/resume, frame-by-frame stepping, FPS counter, collision box overlay, gameplay recording (WebM).

### Panel 3: VM Inspector (MUST)
Visual debugger for the reversible VM. Stack visualisation, memory grid, step forward/backward (reversible!), execution timeline scrubber, breakpoints, subroutine call graph, multi-VM view for multiplayer.

### Panel 4: Network Topology (SHOULD)
Force-directed graph of in-game network. Colour-coded zones, live packet flow animation, defence flag badges, drag-to-rearrange for level design.

### Panel 5: Level Architect (SHOULD)
Visual level design tool. Drag-and-drop device placement, guard patrol path editor, defence flag toggles, level validation via VM simulation, undo/redo with Valence checkpoints.

### Panel 6: Coprocessor Dashboard (SHOULD)
Monitor 3 coprocessor backends (Compute, Security, I/O). Real-time call log, health status, performance metrics, backend toggle.

### Panel 7: Multiplayer Monitor (COULD)
WebSocket/Phoenix channel inspector. Lamport clock visualisation, device lock status, latency graph, sync server process tree.

### Panel 8: DLC Workshop (COULD)
Puzzle editor and test runner. VM instruction composer, difficulty classification, asset bundling, puzzle chain editor.

### Panel 9-11: Editor Bridge, Build Dashboard, Release Manager
Close-the-loop panels for LSP integration, CI/CD monitoring, and release packaging.

---

## Core eNSAID Features for IDApTIK

### TypeLL (Type-Level Intelligence)
- Validate LevelConfig.res against expected schema
- Ensure all DeviceType variants handled
- Constraint propagation (guard count > 5 → alert threshold ≥ Medium)
- Temporal types: VM instruction sequences must be reversible (provable)

### ECHIDNA (Theorem Prover)
| Proof Obligation | What It Checks |
|------------------|----------------|
| VM reversibility | `undo(do(instruction, state)) == state` for all 23 instructions |
| Level solvability | At least one path from spawn to objective |
| Device reachability | All networked devices can reach gateway |
| Defence consistency | `tamperProof` and `decoy` are mutually exclusive |
| Save/load roundtrip | `deserialize(serialize(gameState)) == gameState` |
| Coprocessor safety | Input ranges produce valid outputs (no NaN, no overflow) |

### Agentic Features (BoJ Cartridges)
| Cartridge | IDApTIK Use |
|-----------|-------------|
| `database-mcp` | Save/load game state to VeriSimDB |
| `git-mcp` | Version control from within PanLL |
| `container-mcp` | Build and deploy game containers |
| `observe-mcp` | Game telemetry and performance monitoring |
| `nesy-mcp` | Neurosymbolic reasoning for level design |
| `agent-mcp` | Automated playtest workflows |
| `proof-mcp` | ECHIDNA proof submission from BoJ |

---

## Collaborative Features (Parent-Child)

### Shared Session Mode
- Both users see the same PanLL instance
- Valence Shell has "approval gate": child types command, parent approves
- Game Preview shows both players in multiplayer mode
- VM Inspector supports "explain mode": step-by-step with annotations

### Recording and Sharing
- Terminal sessions (asciinema .cast)
- Gameplay clips (WebM)
- Screenshots (any panel → Capture → PNG)
- Session bundles (ZIP export)

---

## Recommended Panel Arrangement: IDApTIK Dev Mode

```
┌─────────────────────────────────────────────────────────────┐
│ Panel Bar (vertical, left)                                   │
│ ┌──────────┬──────────────────────┬───────────────────────┐ │
│ │ Panel-L  │      Panel-N         │      Panel-W          │ │
│ │ Level    │      ECHIDNA         │      Game Preview     │ │
│ │ Rules    │      VM Proofs       │      (live iframe)    │ │
│ │          │                      │                       │ │
│ │ Device   │      AI Commentary   │      ┌─────────────┐ │ │
│ │ Flags    │                      │      │ Network     │ │ │
│ │          │      Trust Level:    │      │ Topology    │ │ │
│ │ Network  │      ████ L3         │      │ Overlay     │ │ │
│ │ Constr.  │                      │      └─────────────┘ │ │
│ ├──────────┴──────────────────────┴───────────────────────┤ │
│ │ Valence Shell (bottom dock)                             │ │
│ │ $ deno task dev                                         │ │
│ │ $ claude "help me add a new device type"                │ │
│ │ [Recording ●] [Share] [Screenshot] [Approval Gate: ON]  │ │
│ └─────────────────────────────────────────────────────────┘ │
│ Status Bar: IDApTIK v0.1.0 | ReScript 12.1.0 | 0 errors   │
└─────────────────────────────────────────────────────────────┘
```

---

## MuSCoCA Classification Summary

### MUST (6 items)
Valence Shell, Game Preview, VM Inspector, Watcher integration, Panel registration, TEA wiring

### SHOULD (7 items)
Network Topology, Level Architect, Coprocessor Dashboard, Shared session mode, ECHIDNA proofs, BoJ cartridges, Gameplay recording

### COULD (7 items)
Multiplayer Monitor, DLC Workshop, Level difficulty estimator, Coprocessor anomaly detection, VM execution timeline, Asset browser, Session bundle export

### Corrective (4 items)
Watcher debounce tuning, Panel-N OODA cycle, Capture format expansion, Anti-Crash for game events

### Adaptive (4 items)
ReScript 13 migration, Multi-VM networking, VeriSimDB temporal mode, Tauri 2 mobile

### Perfective (6 items)
Panel transitions, Keyboard shortcuts, Dark Start theme, Accessibility, Performance, Panel presets

---

## Implementation Phases

### Phase 1: Shell First (Week 1-2)
Valence Shell panel + PTY + Claude Code + session recording

### Phase 2: Game Preview (Week 2-3)
Embedded Vite dev server + hot-reload + FPS overlay

### Phase 3: VM Inspector (Week 3-4)
VM state bridge + stack/memory visualisation + step forward/backward

### Phase 4: Network + Level Tools (Week 5-6)
Network Topology + Level Architect + LevelConfig.res integration

### Phase 5: Collaborative Features (Week 7-8)
Shared session mode + approval gate + recording + workspace preset

---

*Source files: `panll/docs/DESIGN-DECISIONS.md` and `panll/docs/DESIGN-2026-03-08-idaptik-ensaid.md`*
