# PANLL: Complete Project Status, Priority TODO Plan & Thread Decomposition
# Generated: 2026-02-11 (KEEP UPDATED EACH SESSION)
# Author: Codex (GPT-5) audit pass
# Purpose: Single source of truth for what is actually done vs what still needs work

---

## HOW TO USE THIS DOCUMENT

Read this document fully before starting new work on PanLL.  
It records:
- what is genuinely working now,
- what is claimed but not yet true,
- what is currently broken,
- and the next tasks in strict priority order.

Move completed tasks into the TO-DONE section at the bottom as work lands.

---

## TABLE OF CONTENTS

1. [Honest Status Assessment](#1-honest-status-assessment)
2. [What Is Actually Done](#2-what-is-actually-done)
3. [What Is Claimed But Not Done](#3-what-is-claimed-but-not-done)
4. [What Is Broken Right Now](#4-what-is-broken-right-now)
5. [Code Quality & Risk Notes](#5-code-quality--risk-notes)
6. [Complete Task List (Priority Ordered)](#6-complete-task-list-priority-ordered)
7. [Thread Decomposition](#7-thread-decomposition)
8. [TO-DONE (Completed Items)](#8-to-done-completed-items)
9. [Revision History](#9-revision-history)

---

## 1. HONEST STATUS ASSESSMENT

**Estimated completion: ~76% (not 95%)**

Reasoning:
- Core TEA modules exist and have unit tests.
- Tauri backend compiles.
- Core product loop is not release-ready yet, but frontend ReScript compile now passes.
- Backend command behavior is partly placeholder logic.
- Coverage is concentrated in TEA internals, not full application behavior.

### Reality Snapshot (2026-02-11)

| Component | Claimed | Actual | Notes |
|-----------|---------|--------|-------|
| Custom TEA runtime | Complete | ~80% | Modules exist, tests pass, but app lifecycle/rendering is still described as partial in tests |
| Frontend ReScript build | Implied healthy | **Working** | `npm run res:build` passes (warnings only) |
| Tauri backend commands | Working | ~45% | Commands are wired, but `main.rs` still has TODO placeholder implementations |
| Event-chain import | Working | ~92% | Parser/update flow is real + panic-attacker integration path now wired |
| State persistence | Roadmap says TODO | **Implemented** | `src/Storage.res` has load/save/clear via localStorage and is wired from app init/update |
| Keyboard shortcuts | Roadmap says TODO | **Implemented (core set)** | Ctrl+Shift+L/N/B/W handlers exist in subscriptions |
| Testing | 36 tests passing | True, improving | TEA tests + panic-attacker event-chain parser tests now pass |
| Coverage | 87-91% | Misleading headline | Current run: Branch 86.2%, Line 51.4% across only TEA files under test |

---

## 2. WHAT IS ACTUALLY DONE

Verified in code and/or command execution:

### Architecture & Core
- Custom TEA modules exist: `src/tea/Tea_Cmd.res`, `src/tea/Tea_Sub.res`, `src/tea/Tea_App.res`, `src/tea/Tea_Render.res`, `src/tea/Tea_Vdom.res`, `src/tea/Tea_Html.res`.
- Centralized model/message/update/view wiring exists: `src/Model.res`, `src/Msg.res`, `src/Update.res`, `src/View.res`, `src/App.res`.

### Product Features Implemented
- Event-chain parse/import path implemented in `src/core/EventChain.res` and `src/components/PaneW.res`.
- File import command path implemented in `src/commands/TauriCmd.res` and update handler (`PaneW(ImportEventChainFile)` in `src/Update.res`).
- panic-attacker integration added:
  - `Import latest panic-attacker` path (auto-detect latest report in panic-attacker reports dir).
  - `Load panic-attacker Report` path (select report file, convert, import).
  - Backend runs `panic-attack panll` when available and falls back to direct assault-report conversion when binary lacks that subcommand.
- Anti-crash flow and token gating wired (`src/core/AntiCrash.res`, `src/Update.res`).
- localStorage persistence implemented and auto-save wired (`src/Storage.res`, `src/App.res`, `src/Update.res`).
- Keyboard shortcut subscriptions implemented (`src/SubscriptionsFixed.res`).
- BEAM runtime scaffold implemented in `beam/panll_beam` with protocol-selectable API surface:
  - HTTP via Bandit/Plug (`/healthz`, `/v1/status`)
  - GraphQL via Absinthe (`/graphql`, `/graphiql`)
  - gRPC via `panll.v1.StatusService/GetStatus`
  - Runtime selection via `PANLL_BEAM_APIS` (`http`, `graphql`, `grpc`)
- Hypatia workflow parsing fixed to read scanner envelope (`.findings`) correctly for counts/severity in `.github/workflows/hypatia-scan.yml`, with explicit `FLEET_GITHUB_TOKEN` gate for cross-repo submission.
- Runtime stack scaffolding added under `runtime/`:
  - Chainguard-based `Containerfile` for BEAM release
  - `compose.toml` including `svalinn`, `vordr`, `selur`, `rokur`, and `panll`
  - scripts for build/pack/verify via Cerro Torre and selur-compose up/down

### Build/Test Health
- `deno task test`: **36 passed, 0 failed**.
- `deno task test:coverage`: Branch **86.2%**, Line **51.4%**, scoped to TEA files in current tests.
- `npm run res:clean && npm run res:build`: passes (warnings only).
- `cargo check` in `src-tauri`: passes (with minor unused-variable warnings).

---

## 3. WHAT IS CLAIMED BUT NOT DONE

### A) Build/Runtime Readiness Claims

| Claim | Reality |
|------|---------|
| `v0.1.0 ... 95% complete` (`README.adoc`, `ROADMAP.adoc`) | Frontend now compiles, but release readiness is still overstated due backend stubs + thin integration coverage |
| Tauri commands "working" | Wired but logic is placeholder in `src-tauri/src/main.rs` |
| Coverage badge-level confidence | Real app line coverage is low relative to whole codebase; only selected TEA modules are covered |

### B) Roadmap Drift (Needs Cleanup)

Roadmap currently marks these as TODO, but code shows they are already present:
- State persistence (`src/Storage.res`)
- Keyboard shortcuts (`src/SubscriptionsFixed.res`, plus docs in `README.adoc`)

### C) "Production Ready" Documentation Drift

- `docs/TEA_GUIDE.md` reports `Status: Production Ready`, but:
  - ReScript build passes, but production-quality integration coverage is still missing.
  - Test files explicitly note missing full lifecycle/render pipeline coverage (`tests/tea_app_test.js`, `tests/tea_render_test.js`).

---

## 4. WHAT IS BROKEN RIGHT NOW

### 4.1 Panic-Attacker Binary Version Drift

- In the original dev environment, the `panic-attack` binary (from the `panic-attacker` repo)
  currently exposes older commands only (no `ambush`/`panll` in `--help` output).
- PanLL integration now handles this by falling back to a local assault-report → event-chain converter in backend (`src-tauri/src/main.rs`), so import still works.

### 4.2 Panic-Attacker Source Build Break

- Building current panic-attacker source fails in `src/report/gui.rs` at `eframe::run_native(...)?` due `eframe::Error` conversion into `anyhow::Error` (`Send`/`Sync`) constraints.
- This blocks easy validation that newly added source commands are present in a fresh binary.

### 4.3 Source/Test Confidence Gap

- PanLL now has parser/adapter tests for panic-attacker report import, but full app-level UI automation is still missing.

### 4.4 Backend Stubs

- `src-tauri/src/main.rs:18`: TODO Echidna validation.
- `src-tauri/src/main.rs:31`: TODO real vexation index tracking.
- `src-tauri/src/main.rs:43`: TODO feedback persistence/transport.

---

## 5. CODE QUALITY & RISK NOTES

- Accessibility gap: no ARIA-related attrs found in `src/` (roadmap "accessibility improvements" still valid).
- `rescript.json` still uses deprecated `"module": "es6"` (warning on build).
- Rust devtools setup now avoids `unwrap()` panic on missing window handle.
- `src/core/AntiCrash.res` contains placeholder logic and TODO integration points for real symbolic checking.

---

## 6. COMPLETE TASK LIST (PRIORITY ORDERED)

### P0 - Must Fix Before Any "Release Ready" Claim

- [ ] Fix panic-attacker compile failure in `src/report/gui.rs` so current source can build and ship updated CLI commands.
- [ ] Validate fresh panic-attacker binary command surface (`ambush`, `panll`) and pin compatibility expectations in PanLL docs.

### P1 - Core Functionality Truthfulness

- [ ] Replace placeholder Tauri command logic with real implementations:
  - `validate_inference` should perform real validation semantics.
  - `get_vexation_index` should read actual signal(s), not constant `0.0`.
  - `submit_feedback` should persist/forward feedback.
- [ ] Add tests for command contracts and error paths (frontend `TauriCmd` + backend command behavior).
- [ ] Add integration tests for app-level flows (Pane interactions, event-chain import, auto-save/restore).

### P2 - Product Quality & Consistency

- [ ] Update `ROADMAP.adoc` to mark already-shipped items done (state persistence, keyboard shortcuts).
- [ ] Reconcile status messaging in `README.adoc` and `docs/TEA_GUIDE.md` with actual build state.
- [ ] Decide TEA strategy:
  - complete migration to official `rescript-tea`, or
  - remove/stop signaling migration if custom TEA remains canonical.
- [ ] Replace deprecated ReScript module config (`"es6"` -> `"esmodule"`).

### P3 - UX, A11y, Maintainability

- [ ] Accessibility pass: semantic labels/roles/keyboard focus behavior and ARIA where needed.
- [ ] Expand test coverage beyond TEA internals to component and end-to-end behavior.
- [ ] Add performance baselines for render/update and event import handling.

---

## 7. THREAD DECOMPOSITION

### Thread A: Build Integrity
- Keep CI compile gate green (`res:build`, `deno test`, `cargo check`).
- Track/resolve new build warnings before release.

### Thread B: Backend Correctness
- Implement real logic in Tauri commands.
- Expand backend tests and command-level error handling.

### Thread C: App-Level Testing
- Add integration tests for key user flows.
- Extend panic-attacker import coverage from parser/backend tests to UI-level interactions.

### Thread D: Docs & Truthfulness
- Align README/ROADMAP/TEA_GUIDE with real state.
- Keep this status file updated each session.

### Thread E: UX/A11y
- Accessibility audit and remediation.
- Theme/view-mode polish and consistency checks.

---

## 8. TO-DONE (COMPLETED ITEMS)

- [x] Custom TEA core modules implemented.
- [x] 36 Deno tests passing (TEA + panic-attacker parser tests).
- [x] Event-chain parsing and import flow wired.
- [x] ReScript compile blockers fixed (`TauriCmd` reserved keyword + `PaneW` array slice labels).
- [x] panic-attacker integration wired (latest + selected report import, backend conversion fallback, unit test).
- [x] panic-attacker import backend tests added (latest-file selection + command path).
- [x] CI build gate added (`.github/workflows/build-validation.yml`) for `res:build`, `deno task test`, and `cargo check`.
- [x] Full clean frontend rebuild validated (`npm run res:clean && npm run res:build`).
- [x] localStorage persistence implemented and connected.
- [x] Keyboard shortcut subscriptions implemented.
- [x] Tauri backend command plumbing and app boot wiring in place.
- [x] BEAM API options implemented (HTTP + GraphQL + gRPC) with runtime toggles and tests in `beam/panll_beam`.
- [x] Hypatia scan workflow fixed for current JSON envelope shape (`findings` array under metadata object).
- [x] Added runtime stack files for Chainguard + Cerro Torre + selur-compose orchestration.

---

## 9. REVISION HISTORY

- **2026-02-11:** Initial honest audit created from code + test + build checks.  
  Key correction: project is not currently 95% complete due active compile break and backend stubs.
- **2026-02-11 (update):** panic-attacker integration implemented; ReScript compile blockers fixed; backend fallback conversion + unit test added.
- **2026-02-11 (update 2):** Added panic-attacker import tests, CI build-validation workflow, validated clean ReScript rebuild, and confirmed panic-attacker source build break (`gui.rs`) still blocks fresh binary verification.
- **2026-02-11 (update 3):** Added BEAM API runtime (`panll_beam`) with selectable HTTP/GraphQL/gRPC frontdoors; added BEAM tests (`mix test` 5/5); fixed Hypatia workflow parsing to use `.findings` envelope.
- **2026-02-11 (update 4):** Added `runtime/` stack scaffolding for Chainguard image build, Cerro Torre pack/verify, and selur-compose topology with `svalinn`, `vordr`, `selur`, `rokur`, and PanLL.
