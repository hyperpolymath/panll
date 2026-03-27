# PanLL as eNSAID for IDApTIK Development

**Date**: 2026-03-08
**Author**: Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
**Status**: Design (MuSCoCA-classified)

## Overview

This document designs PanLL as an **eNSAID** (Environment for NeSy-Agentic
Integrated Development) tailored for IDApTIK game development — a collaborative
parent-child workbench where Jonathan and his son can build, test, debug,
visualise, and evolve the IDApixiTIK game together.

The key insight: IDApTIK is a **reversible-computation stealth puzzle game**
with a VM, multiplayer sync server, coprocessor system, device network topology,
and formal verification layer. PanLL's three-panel neurosymbolic model maps
directly onto this:

| PanLL Panel | IDApTIK Mapping |
|-------------|-----------------|
| **Panel-L** (Symbolic) | VM instruction constraints, level rules, device defence flags, protocol specs |
| **Panel-N** (Neural) | ECHIDNA proof advisor for VM correctness, AI-assisted level design, NeSy reasoning |
| **Panel-W** (World) | Game preview, network topology view, device dashboard, telemetry |

---

## The IDApTIK Panel Suite

### New Panels (8 IDApTIK-specific)

These panels form the **IDApTIK Development Kit (IDK)** — a PanLL panel bundle
that transforms the eNSAID into a game development environment.

---

### Panel 1: Valence Shell (MUST)

**ID**: `PanelValenceShell`
**Kind**: terminal
**Icon**: `terminal-square`
**Priority**: MUST — first thing to build

Embedded Valence shell running inside a PanLL panel. This is the primary
interface for running Claude Code, build commands, git operations, and
interactive development.

**Features**:
- Full Valence shell (formally verified reversible filesystem ops)
- PTY allocation via Tauri shell plugin (`@tauri-apps/plugin-shell`)
- Claude Code integration — run `claude` CLI directly in the panel
- Session recording — capture terminal sessions as `.cast` files (asciinema format)
- Screenshot terminal state to Capture panel
- Share terminal sessions via export (JSON, cast, HTML replay)
- Split view: multiple terminal instances side by side
- Command palette with IDApTIK-aware completions (`deno task dev`, `deno task res:build`, etc.)
- Reversible command history with Valence's MAA audit trail
- Alkahest transmuter integration for format conversions

**Panel-L integration**: Display active filesystem constraints (watched paths, undo checkpoints)
**Panel-N integration**: AI command suggestions based on current context
**Panel-W integration**: Terminal output feeds watcher events

**Collaborative**: Both parent and child see the same terminal (shared session mode).
Child can type commands, parent can review before execution (approval gate).

**Backend**: Tauri shell plugin for PTY, Valence shell binary for reversible ops.

---

### Panel 2: Game Preview (MUST)

**ID**: `PanelGamePreview`
**Kind**: viewer
**Icon**: `gamepad-2`

Live game preview embedded in PanLL via iframe or Tauri webview.

**Features**:
- Embedded Vite dev server output (port 8080)
- Hot-reload — changes in ReScript files reflect immediately
- Pause/resume game loop for inspection
- Frame-by-frame stepping (connect to GameLoop.res tick)
- FPS counter, render stats overlay
- Device interaction log (which devices the player touched)
- Screenshot current game frame → Capture panel
- Record gameplay clips (WebM via MediaRecorder API)
- Overlay toggle: show collision boxes, network topology, guard patrol paths
- Zoom and pan for level inspection

**Panel-L integration**: Display active level constraints (LevelConfig.res flags)
**Panel-N integration**: AI commentary on gameplay patterns, difficulty estimation
**Panel-W integration**: Feeds game events to world canvas

**Collaborative**: Parent and child each see the preview; multiplayer mode shows
both players simultaneously (asymmetric co-op view).

---

### Panel 3: VM Inspector (MUST)

**ID**: `PanelVmInspector`
**Kind**: viewer
**Icon**: `cpu`

Visual debugger for the reversible VM — the core computation engine.

**Features**:
- Stack visualisation (push/pop animated)
- Memory cells displayed as grid with highlighting on read/write
- Instruction pointer with assembly listing
- Step forward / step backward (reversible!)
- Breakpoints on instructions, memory addresses, stack depth
- Execution timeline scrubber — drag to any point in execution history
- Subroutine call graph (SubroutineRegistry visualisation)
- Port I/O monitoring (SEND/RECV buffers)
- Multi-VM view for multiplayer (each player's VM side by side)
- Instruction statistics: most-executed, cycle count, tier usage
- Export VM state snapshot (JSON)

**Panel-L integration**: Display proof obligations for VM instruction correctness
**Panel-N integration**: ECHIDNA verifies instruction reversibility proofs
**Panel-W integration**: VM state feeds telemetry dashboard

**Collaborative**: Child can step through VM execution while parent explains
the instruction semantics. "What happens if we SWAP here?"

---

### Panel 4: Network Topology (SHOULD)

**ID**: `PanelNetworkTopology`
**Kind**: viewer
**Icon**: `network`

Visual map of the in-game network — devices, connections, zones, security levels.

**Features**:
- Force-directed graph layout of network devices
- Colour-coded zones: LAN (green), VLAN (blue), External (red)
- Device icons matching in-game types (laptop, router, camera, firewall, PBX)
- Security level indicators (Open/Weak/Medium/Strong)
- Live packet flow animation (traceroute visualisation)
- Click device → open device GUI in Game Preview panel
- Defence flag badges on devices (tamperProof, decoy, canary, killSwitch, etc.)
- DNS resolution tree (Atlas 8.8.8.8, Nexus 1.1.1.1)
- SSH connection paths highlighted
- Drag-to-rearrange topology for level design
- Export topology as SVG/PNG

**Panel-L integration**: Constraint editor for network rules (zone access, firewall rules)
**Panel-N integration**: Suggest network topology improvements, detect unreachable devices
**Panel-W integration**: Overlay on world canvas for spatial context

---

### Panel 5: Level Architect (SHOULD)

**ID**: `PanelLevelArchitect`
**Kind**: builder
**Icon**: `map`

Visual level design tool — the PanLL version of IDApTIK-UMS.

**Features**:
- Drag-and-drop device placement on level grid
- Guard patrol path editor (waypoint-based)
- Spawn point configuration
- Defence flag toggles per device (11 flags from LevelConfig.res)
- Alert threshold sliders
- Asset browser (from AssetPack manifest)
- Level validation: run VM simulation to check solvability
- Companion placement (Moletaire start position, food items)
- Level export to LevelConfig.res format
- Level import from existing configs
- Undo/redo with Valence checkpoint integration
- Side-by-side: edit left, preview right

**Panel-L integration**: Formal constraints on level design (min exits, device connectivity)
**Panel-N integration**: AI difficulty estimation, auto-balance suggestions
**Panel-W integration**: Level metrics dashboard (estimated completion time, paths)

**Collaborative**: Parent designs level structure, child places devices and tests.

---

### Panel 6: Coprocessor Dashboard (SHOULD)

**ID**: `PanelCoprocessors`
**Kind**: viewer
**Icon**: `chip`

Monitor and inspect the 3 coprocessor backends (Compute, Security, I/O).

**Features**:
- Real-time coprocessor call log
- Backend health status (Maths, Vector, Tensor, Physics, Crypto, Neural, Quantum, Audio, Graphics, I/O)
- Call frequency heatmap
- Performance metrics per backend
- Input/output inspection for individual calls
- CoprocessorManager dispatch log
- Backend toggle (enable/disable for testing)

**Panel-L integration**: Coprocessor contracts (expected input ranges, output guarantees)
**Panel-N integration**: Anomaly detection on coprocessor usage patterns
**Panel-W integration**: Performance metrics feed world canvas

---

### Panel 7: Multiplayer Monitor (COULD)

**ID**: `PanelMultiplayer`
**Kind**: viewer
**Icon**: `users`

Monitor the Elixir/Phoenix sync server and multiplayer state.

**Features**:
- WebSocket connection status
- Phoenix channel subscriptions
- Player state diff (Hacker vs Observer roles)
- VMMessageBus traffic monitor
- Lamport clock visualisation (causal ordering)
- Device lock status (who's editing which device)
- Latency graph (client ↔ server round-trip)
- Sync server process tree (Horde distributed supervisor)
- ETS cache inspection
- Reconnection test trigger

**Panel-L integration**: Protocol constraints from proven-servers gameserver spec
**Panel-N integration**: Predict desync risk from Lamport clock drift
**Panel-W integration**: Multiplayer health feeds world canvas

---

### Panel 8: DLC Workshop (COULD)

**ID**: `PanelDlcWorkshop`
**Kind**: builder
**Icon**: `puzzle`

Create, test, and package DLC puzzle packs.

**Features**:
- Puzzle editor with VM instruction composer
- Test runner for puzzle solutions (42-test suite integration)
- Difficulty classification
- Asset bundling for DLC distribution
- Import/export puzzle packs
- Puzzle chain editor (sequence of related puzzles)

**Panel-L integration**: Puzzle solvability proofs (ECHIDNA checks reversibility)
**Panel-N integration**: AI-generated puzzle suggestions based on difficulty curve
**Panel-W integration**: Puzzle analytics (completion rates, hint usage)

---

## Core eNSAID Features for IDApTIK

### TyPELL (Type-Level Intelligence)

TyPELL operates through Panel-L's constraint layer:

| Feature | IDApTIK Application |
|---------|---------------------|
| **Type checking** | Validate LevelConfig.res against expected schema |
| **Exhaustiveness** | Ensure all DeviceType variants handled in DeviceFactory |
| **Constraint propagation** | If guard count > 5, alert threshold must be ≥ Medium |
| **Temporal types** | VM instruction sequences must be reversible (provable) |

### ECHIDNA (Theorem Prover Integration)

Panel-N's ECHIDNA advisor applied to game development:

| Proof Obligation | What It Checks |
|------------------|----------------|
| VM reversibility | `undo(do(instruction, state)) == state` for all 23 instructions |
| Level solvability | At least one path from spawn to objective exists |
| Device reachability | All networked devices can reach gateway |
| Defence consistency | `tamperProof` and `decoy` are mutually exclusive |
| Save/load roundtrip | `deserialize(serialize(gameState)) == gameState` |
| Coprocessor safety | Input ranges produce valid outputs (no NaN, no overflow) |

Trust Level applied: game builds only with Level 3+ proofs (multiple solver agreement).

### NeSy (Neurosymbolic Reasoning)

The binary star model applied to IDApTIK:

- **Symbolic star** (Panel-L): VM instruction rules, network topology constraints, level design rules
- **Neural star** (Panel-N): AI-assisted level generation, difficulty estimation, playtest analysis
- **Barycentre** (Panel-W): Where symbolic proofs meet neural suggestions — the game preview with overlays

### Agentic Features

BoJ cartridge integration for autonomous development workflows:

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

## External Portfolio Integration

### panic-attack (Existing Panel)

Already wired. For IDApTIK: scan game code for unsafe patterns, command
injection in network simulation, ReScript-specific weak points.

### Mass Panic (Existing Panel)

Already wired. For IDApTIK: batch scan all monorepo subdirectories
(src/, vm/, shared/, dlc/, sync-server/).

### VAB (Existing Panel)

Already wired. For IDApTIK: compose the game's server stack from
proven-servers components (gameserver, websocket, dns, firewall protocols).

### Databases (Existing Panel)

Already wired. For IDApTIK: VeriSimDB for game telemetry persistence,
drift detection on game state, entity browser for level objects.

### Capture (Existing Panel)

Already wired. Critical for collaborative use — screenshot game state,
record development sessions, compare before/after level changes.

### AI Panel (Existing)

Already wired. For IDApTIK: Claude integration for code assistance,
level design suggestions, debugging help. This is the AI conversation
panel complementing the Valence Shell's Claude CLI.

---

## Collaborative Features (Parent-Child)

### Shared Session Mode

- Both users see the same PanLL instance (same Tauri window or screen-shared)
- Valence Shell has "approval gate": child types command, parent approves
- Game Preview shows both players in multiplayer mode
- VM Inspector supports "explain mode": step-by-step with annotations

### Recording and Sharing

- **Session recording**: Valence Shell records terminal sessions (asciinema .cast)
- **Gameplay recording**: Game Preview records WebM clips
- **Screenshot**: Any panel → Capture panel → PNG export
- **Comparison views**: Capture panel's diff mode shows before/after changes
- **Share**: Export session bundles (terminal + gameplay + screenshots) as ZIP

### Visualisation

- **VM execution timeline**: Scrubber showing instruction flow with undo/redo
- **Network topology graph**: Force-directed device map with live traffic
- **Coprocessor heatmap**: Which backends are hot during gameplay
- **Level difficulty map**: Colour overlay showing hard/easy areas
- **Orbital drift aura**: Ambient visual showing symbolic/neural co-orbit health

---

## Watcher Integration

The existing watcher infrastructure feeds IDApTIK-specific events:

| Watch Path | Panel Reaction |
|------------|----------------|
| `src/**/*.res` | Game Preview hot-reloads, panic-attack re-scans |
| `vm/lib/ocaml/**/*.res` | VM Inspector reloads instruction set, ECHIDNA re-verifies |
| `shared/src/**/*.res` | Coprocessor Dashboard refreshes backend status |
| `dlc/**/*.res` | DLC Workshop re-runs puzzle tests |
| `sync-server/**/*.ex` | Multiplayer Monitor checks sync server health |
| `raw-assets/**/*` | Game Preview triggers AssetPack rebuild |
| `src/app/screens/LevelConfig.res` | Level Architect reloads level definitions |

---

## MuSCoCA Classification

### MUST (Minimum Viable eNSAID)

1. **Valence Shell panel** — embedded terminal with Claude Code, session recording, reversible ops
2. **Game Preview panel** — live iframe of Vite dev server with hot-reload
3. **VM Inspector panel** — visual debugger with step forward/backward
4. **Watcher integration** — file change events feed all IDApTIK panels
5. **Panel registration** — 8 new panel IDs in PanelSwitcherModel.res + PanelRegistry.res
6. **Model/Msg/Update wiring** — TEA integration for all MUST panels

### SHOULD (Full Development Experience)

7. **Network Topology panel** — force-directed graph of in-game network
8. **Level Architect panel** — visual level editor (PanLL version of UMS)
9. **Coprocessor Dashboard** — monitor compute/security/IO backends
10. **Shared session mode** — approval gate for child commands
11. **ECHIDNA proofs for VM** — reversibility verification in Panel-N
12. **BoJ cartridge integration** — database-mcp, git-mcp for dev workflows
13. **Gameplay recording** — WebM capture in Game Preview

### COULD (Enhanced Experience)

14. **Multiplayer Monitor** — Phoenix channel inspector
15. **DLC Workshop** — puzzle editor and test runner
16. **Level difficulty estimator** — AI-powered analysis in Panel-N
17. **Coprocessor anomaly detection** — NeSy reasoning on usage patterns
18. **VM execution timeline** — full scrubber with undo/redo visualisation
19. **Asset browser** — visual asset picker integrated with Level Architect
20. **Export session bundles** — ZIP of terminal + gameplay + screenshots

### Corrective (Fix Existing Issues)

21. **Watcher debounce tuning** — 500ms default may be too slow for game dev hot-reload
22. **Panel-N OODA cycle** — ensure agency phase tracking works with game-specific proofs
23. **Capture panel format** — add WebM and asciinema .cast alongside existing PNG
24. **Anti-Crash for game events** — validate game state transitions through circuit breaker

### Adaptive (Respond to Change)

25. **ReScript 13 migration panel** — when staging migration lands, track it in PanLL
26. **Multi-VM networking** — when VM Tier 5 lands, add cross-VM visualisation
27. **VeriSimDB temporal mode** — when per-level toggle ships, integrate with Level Architect
28. **Tauri 2 mobile** — adapt panels for tablet use (child on iPad, parent on desktop)

### Perfective (Polish and Optimise)

29. **Panel transitions** — smooth animations between IDApTIK panels
30. **Keyboard shortcuts** — game-dev-specific bindings (F5=run, F9=breakpoint, F10=step)
31. **Dark Start IDApTIK theme** — binary star animation with game characters
32. **Accessibility** — screen reader support for VM Inspector, colour-blind mode for topology
33. **Performance** — lazy-load IDApTIK panels only when IDApTIK repo is loaded
34. **Panel presets** — "IDApTIK Dev" workspace preset with recommended panel arrangement

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

## Implementation Order

### Phase 1: Shell First (Week 1-2)

1. Add `PanelValenceShell` to PanelSwitcherModel.res
2. Create ValenceShellModel.res, ValenceShellMsg.res
3. Wire PTY via `@tauri-apps/plugin-shell`
4. Basic terminal emulator (xterm.js via Tauri webview)
5. Claude Code launch command
6. Session recording (asciinema format)

### Phase 2: Game Preview (Week 2-3)

1. Add `PanelGamePreview` to registry
2. Embed Vite dev server output in iframe/webview
3. Hot-reload integration with watcher
4. FPS overlay and render stats
5. Screenshot to Capture panel

### Phase 3: VM Inspector (Week 3-4)

1. Add `PanelVmInspector` to registry
2. Connect to VM state via Tauri command bridge
3. Stack and memory visualisation
4. Step forward/backward controls
5. Execution timeline scrubber

### Phase 4: Network + Level Tools (Week 5-6)

1. Network Topology panel (force-directed graph)
2. Level Architect panel (device placement)
3. Connect both to LevelConfig.res

### Phase 5: Collaborative Features (Week 7-8)

1. Shared session mode
2. Approval gate for Valence Shell
3. Recording and sharing infrastructure
4. Workspace preset for "IDApTIK Dev Mode"

---

## Technical Notes

### Panel Registration Pattern

Each new panel requires:
1. `PanelSwitcherModel.res` — add variant to `panelId`
2. `PanelRegistry.res` — add `panelMeta` entry
3. `src/model/XxxModel.res` — domain types
4. `src/components/Xxx.res` — view function
5. `Model.res` — `include XxxModel`
6. `Msg.res` — add message type + variants
7. `Update.res` — add pattern match cases
8. `View.res` — add to `renderActivePanel` dispatch

### Terminal Emulator Options

- **xterm.js** — industry standard, WebGL renderer, accessible
- Loaded via Tauri webview, communicates with Valence shell binary via PTY
- Alternative: raw ANSI rendering in Tea_Html (simpler but less capable)

### Game Preview Embedding

- Tauri supports multiple webviews — one for PanLL, one for game preview
- Communication via Tauri event bus (not postMessage)
- Game preview webview loads `http://localhost:8080` (Vite dev server)

### VM State Bridge

- VM runs in game's Vite webview
- Expose VM state via global `window.__IDAPTIK_VM_STATE__`
- PanLL reads via Tauri inter-webview messaging
- Or: VM state serialised to file, watcher picks it up (simpler, decoupled)

---

## Simulation, Emulation, and Beyond

### Simulation Mode

Run the game logic without rendering — useful for:
- Automated playtesting (agent-mcp runs through levels)
- Performance profiling (how fast can the VM execute 10k instructions?)
- Puzzle solvability checking (brute-force all SWAP/ADD sequences)

### Emulation Mode

Run the VM in a sandboxed PanLL panel without the full game:
- Test individual instructions
- Compose subroutines
- Verify reversibility interactively
- Educational: "Here's how XOR works" with animated visualisation

### Preview Mode

Live game preview with overlays — the standard development view.

### Watch Mode

Passive monitoring — watcher feeds events, panels update, no interaction required.
Good for "leave it running while we code" workflows.

---

## Summary

PanLL becomes the **mission control for IDApTIK development** by adding 8
game-specific panels to the existing 22-panel suite. The Valence Shell is the
foundation — it gives parent and child a shared, recorded, reversible terminal
with Claude Code integration. The Game Preview, VM Inspector, and Network
Topology panels provide the visual development experience. ECHIDNA proves VM
correctness, BoJ cartridges automate workflows, and panic-attack keeps the
codebase secure.

The MuSCoCA classification ensures we build the most valuable panels first
(Shell, Preview, VM Inspector) while planning for collaborative features,
multiplayer monitoring, and DLC creation tools.
