# PanLL Workspace Management Layer — Progress Tracker

## Status: Sessions E-H Complete (Skeleton), BOTH COMPILERS PASS CLEAN

**Date**: 2026-03-02 (compiler verification passed)
**Scope**: DD-022 through DD-027

## What Was Built

### New Files Created (37 files)

#### ReScript Models (5 files)
| File | Lines | Status |
|------|-------|--------|
| `src/model/WorkspaceModel.res` | ~230 | COMPLETE — all types defined |
| `src/model/KeybindingsModel.res` | ~65 | COMPLETE — all types defined |
| `src/model/CaptureModel.res` | ~130 | COMPLETE — all types defined |
| `src/model/StatusBarModel.res` | ~75 | COMPLETE — all types defined |
| `src/model/SecurityModel.res` | ~140 | COMPLETE — all types defined |

#### ReScript Engines (5 files)
| File | Lines | Status |
|------|-------|--------|
| `src/core/WorkspaceEngine.res` | ~280 | COMPLETE — all pure functions |
| `src/core/KeybindingsEngine.res` | ~165 | COMPLETE — defaults, lookup, conflict detection |
| `src/core/UndoEngine.res` | ~120 | COMPLETE — ring buffer, significance filter |
| `src/core/CaptureEngine.res` | ~170 | COMPLETE — all pure functions |
| `src/core/StatusBarEngine.res` | ~170 | COMPLETE — widget registry, formatters |
| `src/core/SecurityEngine.res` | ~200 | COMPLETE — patterns, redaction, 2FA checks |

#### ReScript Commands (3 files)
| File | Lines | Status |
|------|-------|--------|
| `src/commands/WorkspaceCmd.res` | ~80 | COMPLETE — Tauri wrappers |
| `src/commands/CaptureCmd.res` | ~70 | COMPLETE — Tauri wrappers |
| `src/commands/SecurityCmd.res` | ~70 | COMPLETE — Tauri wrappers |

#### ReScript Components (5 files)
| File | Lines | Status |
|------|-------|--------|
| `src/components/Workspace.res` | ~230 | COMPLETE — full panel with tooltip placeholders |
| `src/components/Capture.res` | ~200 | COMPLETE — gallery, recordings, demos, clones |
| `src/components/Security.res` | ~230 | COMPLETE — patterns, vault, 2FA, Trustfile |
| `src/components/StatusBar.res` | ~130 | COMPLETE — configurable bottom bar |
| `src/components/CaptureBar.res` | ~80 | COMPLETE — side-oriented vertical strip |

#### Rust Backend (9 files)
| File | Lines | Status |
|------|-------|--------|
| `src-tauri/src/workspace/mod.rs` | ~15 | COMPLETE |
| `src-tauri/src/workspace/types.rs` | ~110 | COMPLETE — serde types |
| `src-tauri/src/workspace/commands.rs` | ~120 | COMPLETE — arrangement/session I/O |
| `src-tauri/src/workspace/sysinfo.rs` | ~130 | COMPLETE — procfs CPU/memory/disk |
| `src-tauri/src/capture/mod.rs` | ~15 | COMPLETE |
| `src-tauri/src/capture/types.rs` | ~60 | COMPLETE — serde types |
| `src-tauri/src/capture/commands.rs` | ~170 | COMPLETE — screenshot/demo I/O |
| `src-tauri/src/security/mod.rs` | ~10 | COMPLETE |
| `src-tauri/src/security/types.rs` | ~80 | COMPLETE — serde types |
| `src-tauri/src/security/commands.rs` | ~200 | COMPLETE — redaction, vault, Trustfile |

### Modified Files (10 files)
| File | Change |
|------|--------|
| `src/model/PanelSwitcherModel.res` | Added PanelWorkspace, PanelCapture, PanelSecurity |
| `src/modules/PanelRegistry.res` | Added 3 panel entries with metadata |
| `src/Model.res` | Added 6 includes + 7 state fields + init values |
| `src/Msg.res` | Added workspaceMsg, captureMsg, securityMsg, keybindingsMsg + Undo/Redo |
| `src/Update.res` | Added 4 sub-updaters + routing in main update |
| `src/View.res` | Added 3 panel overlays + CaptureBar on panes + StatusBar |
| `src/SubscriptionsFixed.res` | Refactored to use KeybindingsEngine lookup |
| `src-tauri/src/main.rs` | Added 3 modules + 17 command registrations |
| `src-tauri/Cargo.toml` | Added regex, libc crates |

## What Still Needs Work (TODO for Next Sessions)

### High Priority (Makes Things Work)
- [x] ReScript compiler check (`npx rescript-legacy`) — PASSES CLEAN (0 errors)
- [x] Rust compiler check (`cargo check`) — PASSES CLEAN (warnings only, all pre-existing)
- [ ] Wire actual undo/redo snapshots (currently NoOp)
- [ ] Wire actual html2canvas screenshot capture in JS
- [ ] Parse JSON results in Workspace/Capture/Security sub-updaters (marked TODO)

### Medium Priority (Functional Gaps)
- [ ] Arrangements: gather actual panel positions and save
- [ ] Sessions: create with current context, fork from active
- [ ] Checkpoints: snapshot and restore
- [ ] System info: parse JSON response and update statusBar.systemInfo
- [ ] Trustfile: parse JSON and apply policy via SecurityEngine.applyTrustfile
- [ ] Vault: parse key list JSON and update vaultKeys
- [ ] TOTP: implement verification via Rust backend
- [ ] Panel cloning: snapshot actual panel state
- [ ] Multi-panel capture: composite image from selected panels
- [ ] Demo recording: capture state snapshots at each step

### User's Additional Ideas (Captured, Not Yet Implemented)
1. **Workspace Modes** — Rhodium/Everything/Code/Bespoke (types DONE, switching DONE, panel filtering TODO)
2. **Poly Integration** — polystack tool registry (types DONE, tool invocation TODO)
3. **Session Protection** — all 6 levels (types DONE, enforcement TODO)
4. **Dry Run/Simulation/Emulation** — modes (types DONE, behaviour TODO)
5. **Forked Instances** — versioner-produced forks (types DONE, versioner integration TODO)
6. **Panel Clades** — taxonomic inheritance (Kingdom→Species) for panel customisation (NOT STARTED)
7. **ABI/API/FFI Designers** — constrained to Idris/V/Zig in Interfaces panel (NOT STARTED)
8. **Controlled Permissions** — per-member visibility and edit permissions (NOT STARTED)
9. **Code Provenance Tracking** — BLAKE3 + uni IDs for group project attribution (NOT STARTED)
10. **Cognitive Ergonomics** — focus mode, dimming non-relevant panels, event-driven alerting (NOT STARTED)
11. **Encysting Protection (Anti-Tunnel-Vision HUD)** — peripheral vision system for developers. When you're deep in one area, a HUD overlay monitors the rest of the codebase for: (a) error storms sprawling from your changes, (b) strain indicators in distant modules responding to your code, (c) panic-attack hashing analysis detecting "panic-stricken" code in areas you're not looking at. Prevents the developer getting locked in and missing cascading failures. Leverages panic-attack's fast BLAKE3-based source scanning to quickly fingerprint stressed code regions. The HUD could pulse/glow/flash at the edges of dimmed panels rather than interrupting flow — a "something's wrong over THERE" ambient signal. Integrates with Vexometer (operator strain) + OrbitalSync (pane divergence) + panic-attack (source code hashing). Think of it like a submarine's sonar display — you're focused on navigation but the sonar quietly shows threats on the periphery. (NOT STARTED)
12. **Clone-and-Modify from Clades** — take a panel design from one context (e.g., Adobe's design panel clade), clone the code, modify the interface, switch between instances on replicated code without changing the original — like forking a UI at any taxonomy level (NOT STARTED)
13. **AI Traversal Mode Control (Depth-First / Breadth-First)** — explicit instruction modes for how AI agents approach code generation within PanLL sessions. **Depth-first mode**: AI picks one directory/module, completes it fully to its deepest level, verifies it compiles/works, then moves to the next. Not the most efficient path but every piece is validated before proceeding — prevents building on wrong assumptions. **Breadth-first mode**: AI outlines the full scope first — creates file names, type signatures, empty functions, stubs across ALL directories — so the human sees the complete map before a single line of real implementation. Cheap to discard if the architecture is wrong. This prevents the catastrophic failure mode where an AI generates thousands of lines across dozens of files built on a wrong assumption, and the human only discovers it after the fact. Could be enforced via the session protection system or as a Trustfile directive (`(ai-traversal-mode "depth-first")`). The Workspace panel could show which mode is active and visualise the traversal path. (NOT STARTED — but should inform how Claude/AI panel dispatches work)

14. **Programmatic Operations Scripter** — a panel/mode where you design scripts that perform bulk programmatic operations (e.g., "apply this change to 500 repos"). The system calculates the upfront token/compute cost to create the script vs. the per-run savings for future executions. Pulls from catalogues of pre-made programmatic scripts in any target language the user wants. Knows when an operation is better as a one-shot vs. a reusable script. (NOT STARTED)
15. **Model Mode Switcher / Token Cost Guide** — talks to incoming LLMs about their model modes and capabilities. Creates switching scripts based on token cost analysis — knows when to delegate to a cheap model (Haiku for simple tasks) vs. escalate to an expensive one (Opus for complex reasoning). Auto-discovers new models' capabilities and creates optimal routing strategies. Builds model profiles dynamically rather than hardcoding provider knowledge. (NOT STARTED)
16. **Warmup Script Maker** — designs efficient LLM briefing packages for specific projects, roles, or tasks. Instead of LLMs cold-starting and reading everything from scratch every time, warmup scripts pull from repo history, user preferences, memory, project memories, 6SCM files, and contractiles to create role-specific briefings (e.g., "you are the security engineer for this crypto project — use security-warmup script"). Output is dual-format: human-readable for handovers between team members, and A2ML machine-readable for tight specification. Dramatically saves tokens on LLM context setup. Think of it as a pre-flight checklist / briefing packet rather than "please read everything about everything every time". (NOT STARTED)

## Architecture Notes

- All new code follows the existing TEA pattern: Model → Engine → Msg → Update → View
- No dependencies between new models (all leaf modules)
- New engines are pure functions
- Tauri commands follow the existing pattern: async fn → Result<String, String>
- Status bar uses the same model-driven approach as the rest of the UI
- Security redaction has both frontend (quick regex) and backend (full regex) paths
