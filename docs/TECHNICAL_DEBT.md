# PanLL Technical Debt Registry — 30-Day Plan

> **Reset note (2026-05-17):** The previous version of this file described a
> "v0.2.0 Panic Attack Remediation" dated 2024-04-15 with placeholder
> metadata and fabricated progress counters. Its two P0 blockers and all
> three "commented out" modules were already resolved by commit
> `6ae4336 fix(gossamer): resolve P0/P1 type mismatches, wire http_client,
> enable settings`. This document has been rewritten against the **verified
> state of the tree** and recast as a dated 30-day plan.

## Verified Baseline (2026-05-17)

`cargo check` **passes** (8 dead-code warnings, 0 errors). The Gossamer
backend builds. Status of the historic items:

| Historic item | Verified state |
|---|---|
| `http_client` module | ✅ Implemented (`src-gossamer/src/http_client.rs`, wired at `main.rs:48`). No unit tests yet. |
| Command result type mismatches | ✅ Resolved — `result_to_json`/`result_str_to_json` return `Result<Value, String>`; build green. |
| `groove` / `settings` / `llm_coding` modules | ✅ All present and wired (`groove.rs`, `settings.rs`, `llm_coding/{mod,commands,types}.rs`). |
| Unused doc comment `main.rs:38` | ✅ Obsolete reference — line 38 is now `mod settings;`. |

### Remaining Debt (the real backlog)

| ID | Item | Location | Severity | Status |
|----|------|----------|----------|--------|
| D1 | Service registry mutability: register/unregister/list commands commented out | `src-gossamer/src/main.rs` | High | ✅ Resolved — fixed env-set design; `service_list` + `service_set_url` wired; vestigial register/unregister stubs removed |
| D2 | 8 dead-code warnings | `service_registry.rs`, `settings.rs`, `llm_coding/` | Medium | ✅ Resolved — `get_registry`/`update_service_url`/`settings_save`/`read_system_memory`+`SystemResources` wired; `WorkspaceLock`/`PendingAction`/`SpawnRequest.task_list` removed; clippy `-D warnings` clean |
| D3 | No unit tests for `http_client.rs` or `service_registry.rs` | `src-gossamer/src/` | High | ✅ Resolved — required a **lib/bin split** (see below); 23 tests now run via `cargo test --lib` with no GTK link |
| D4 | 6 TODOs: dynamic plugin loading stubbed pending `libloading`/`once_cell` deps | `src-gossamer/src/coprocessor/{mod,commands}.rs` | Medium | ✅ Resolved — `libloading 0.8` added (`once_cell` was already a dep); real `dlopen`+`copro_init` and real `copro_dispatch`/`copro_free` symbol calls. **Caveat:** `coprocessor` was orphaned (declared by no crate root → never compiled); now wired into the lib so the fix is real and tested |
| D5 | Stale doc: wrong date, placeholder maintainer, broken `docs/ARCHITECTURE.md` link, fabricated stats | this file | Low | ✅ Resolved — rewritten 2026-05-17; real arch doc is `docs/architecture/ARCHITECTURE.md` |

---

## Execution Log

The 30-day plan was executed in a single accelerated session on **2026-05-17**
(CAP order preserved: corrective → adaptive → perfective).

### Week 1 — Corrective ✅ (commit `7c7203d`)
- **D5** doc rewritten; arch link repointed to `docs/architecture/ARCHITECTURE.md`.
- **D1** registry resolved as a fixed env-driven set: `service_list`
  (`get_registry`) + `service_set_url` (`update_service_url`) wired; vestigial
  `service_register`/`service_unregister` stubs removed.
- **D2** `settings_save` + `llm_coding_system_resources` wired (with a real
  `/proc/stat` CPU sampler); `WorkspaceLock`, `PendingAction`,
  `SpawnRequest.task_list` removed. Two pre-existing clippy lints fixed.
- Gate: `cargo clippy --all-targets -- -D warnings` clean.

### Week 2 — Adaptive (FFI) ✅ (commit `8812d7f`)
- **D4** `libloading 0.8` added; `FfiState` owns the loaded `Library`;
  `coprocessor_load_ffi` does a real `dlopen` + `copro_init`;
  `coprocessor_ffi_dispatch` resolves and calls `copro_dispatch`/`copro_free`.
- De-Tauri'd coprocessor comments; removed stale TODOs.

### Week 3 — Adaptive (tests) + architectural fix ✅ (commit `bd62aef`)
- **Lib/bin split**: new `[lib] panll` (GTK-free) holds `http_client`,
  `service_registry`, `settings`, `identity`, `groove`, `llm_coding`,
  `coprocessor`. `main.rs` keeps only `system_tray` (needs `gossamer_rs`).
- **D3** 23 tests run via `cargo test --lib` **without** linking
  libgossamer/GTK. The orphaned `coprocessor` was wired into the lib (11
  latent clippy lints cleared once it actually compiled).

### Week 4 — Perfective ✅ (this commit)
- Cross-module integration tests folded into the lib test surface.
- `.github/hypatia-rules/panll-v0.2.0-fixes.yml` reconciled v1 → v2: retired
  all 8 false-positive panic-attack rules; one precise regression guard
  (`panll-cmd-disabled`) kept; clippy `-D warnings` documented as the gate.
- `CHANGELOG.md` updated.
- Final gate: `cargo test --lib` 23/23; `cargo clippy --all-targets -- -D warnings` clean.

## Environment Caveat (honest)

`cargo test --lib` and all `cargo clippy`/`cargo check` pass in this WSL box.
**Linking the `panll-gossamer` binary still fails here** — `libgossamer`,
`libgtk-3`, `libwebkit2gtk-4.1` are not installed. This is a pre-existing
environment gap, unrelated to these changes, and the entire reason the
lib/bin split was necessary: it moves all testable logic out from behind the
GTK link wall. The binary builds in a GTK-equipped environment / CI.

## Follow-up Debt Discovered (not in original scope)

| ID | Item | Severity |
|----|------|----------|
| F1 | **38 unwired PanLL panel backends** under `src-gossamer/src/` (aerie=net diagnostics, hypatia=neurosym scanner, ai=multi-provider AI, farm, provenance, k9, governance, …; ~19,181 LOC). NOT dead code — real panel backends orphaned by the same defect as `coprocessor` (declared by no crate root → never compiled → IPC commands never registered). **Decision (2026-05-17): integrate, not delete.** Also carry stale Tauri refs. Tracked as the F1 integration workstream. | High (lost functionality) |
| F2 | `coprocessor`'s async command handlers are implemented + tested but **not registered** in the binary's IPC table (`main.rs`). Wire them — this is the **pilot** for F1 (establishes the async→sync `app.command` bridge), done first. | Medium |
| F3 | Binary cannot be built/linked locally without GTK/WebKit + a built `libgossamer`. Document the dev-env setup or provide a container. | Medium |

### F1 integration workstream (multi-session)

1. **Pilot (F2):** finish `coprocessor` IPC registration → builds the
   reusable async→sync `block_on` bridge for `app.command`.
2. **Census:** declare all 38 modules; `cargo check` each; record which
   compile clean vs. bit-rotted (never compiled — expect API drift).
3. **Bulk wire** in dependency/risk order using the proven pattern;
   de-Tauri as we go; cross-check command names against the ReScript
   frontend `invoke()` contract so we wire what the UI actually calls.

---

## Progress Tracking (live — update on every change)

```
Original debt items:         5  (D1–D5)
Resolved:                     5  (all — 2026-05-17)
Follow-up debt opened:        3  (F1–F3, see above)
Build status:                 cargo check / clippy green; bin link needs GTK env
Clippy -D warnings:           clean (0, all targets)
Lib tests:                    23 passing (cargo test --lib, GTK-free)
```

## Success Criteria

- [x] D1–D5 all resolved or explicitly closed with rationale.
- [x] `cargo clippy --all-targets -- -D warnings` clean.
- [x] `http_client` and `service_registry` have unit tests in `cargo test`.
- [x] No commented-out command handlers in `main.rs`.
- [x] Hypatia rules reflect actual current debt (no rules for resolved items).
- [ ] F1–F3 follow-up debt triaged (next cycle).

## Related

- `docs/architecture/ARCHITECTURE.md` — architecture reference
- `.github/hypatia-rules/panll-v0.2.0-fixes.yml` — reconciled v2 (regression guard only)
- `CONTRIBUTING.md`
- `CHANGELOG.md`

---

**Last Updated:** 2026-05-17
**Plan window:** 2026-05-17 → 2026-06-15
**Maintainer:** Jonathan Jewell (hyperpolymath)
