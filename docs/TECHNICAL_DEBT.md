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
| D3 | No unit tests for `http_client.rs` or `service_registry.rs` | `src-gossamer/src/` | High | ⏳ Pending (Week 3) |
| D4 | 6 TODOs: dynamic plugin loading stubbed pending `libloading`/`once_cell` deps | `src-gossamer/src/coprocessor/{mod,commands}.rs` | Medium | ⏳ Pending (Week 2) |
| D5 | Stale doc: wrong date, placeholder maintainer, broken `docs/ARCHITECTURE.md` link, fabricated stats | this file | Low | ✅ Resolved — rewritten 2026-05-17; real arch doc is `docs/architecture/ARCHITECTURE.md` |

---

## 30-Day Plan

Order follows CAP discipline: **corrective → adaptive → perfective**. Finish
each week's bucket before starting the next.

### Week 1 (2026-05-17 → 2026-05-23) — Corrective: stop the bleeding

- [ ] **D5** Fix broken `ARCHITECTURE.md` link (create stub or repoint to existing doc); remove placeholder metadata. *(~30 min)*
- [ ] **D1** Decide registry mutability: either re-enable `service_register/unregister/list` commands **or** delete the dead backing fns and document registry as read-only by design. *(~3 h)*
- [ ] **D2** Resolve the 8 dead-code warnings consistent with the D1 decision (wire up or remove; no blanket `#[allow(dead_code)]`). *(~3 h)*
- [ ] Gate: `cargo check` and `cargo clippy --all-targets -- -D warnings` clean.

### Week 2 (2026-05-24 → 2026-05-30) — Adaptive: close functional gaps

- [ ] **D4** Add `libloading` + `once_cell` (or `std::sync::LazyLock`) to `Cargo.toml`; replace the 6 coprocessor stubs with real dynamic-symbol calls. *(~6 h)*
- [ ] Verify coprocessor load path end-to-end with one real plugin. *(~2 h)*
- [ ] Gate: build green; coprocessor smoke test passes.

### Week 3 (2026-05-31 → 2026-06-06) — Adaptive: test coverage

- [ ] **D3** Unit tests for `http_client.rs` (get/post, error paths, timeout). *(~4 h)*
- [ ] **D3** Unit tests for `service_registry.rs` (health check, all-services, plus mutation if re-enabled in W1). *(~4 h)*
- [ ] Wire both into `cargo test`; ensure CI runs them.
- [ ] Gate: `cargo test` green; coverage reported.

### Week 4 (2026-06-07 → 2026-06-15) — Perfective: hardening & prevention

- [ ] Integration test exercising `main.rs` command dispatch across http_client + service_registry + settings.
- [ ] Reconcile `.github/hypatia-rules/panll-v0.2.0-fixes.yml` with the now-resolved items (retire dead rules, keep regression guards for D1/D4).
- [ ] Update `CHANGELOG.md` `[Unreleased]` with this remediation.
- [ ] Final gate: `cargo build --release`, `cargo test`, `cargo clippy --all-targets --all-features -- -D warnings` all clean.

---

## Progress Tracking (live — update on every change)

```
Remaining debt items:        5  (D1–D5)
Resolved:                     3  (D1, D2, D5 — 2026-05-17)
Build status:                 green (cargo check, 0 errors)
Clippy -D warnings:           clean (0)
Unit tests (http/registry):   0  (D3, Week 3)
```

## Success Criteria

- [ ] D1–D5 all resolved or explicitly closed with rationale.
- [ ] `cargo clippy --all-targets --all-features -- -D warnings` clean.
- [ ] `http_client` and `service_registry` have unit tests in `cargo test`.
- [ ] No commented-out command handlers in `main.rs`.
- [ ] Hypatia rules reflect actual current debt (no rules for resolved items).

## Related

- `docs/architecture/ARCHITECTURE.md` — architecture reference
- `.github/hypatia-rules/panll-v0.2.0-fixes.yml` — detection rules (needs reconciliation, W4)
- `CONTRIBUTING.md`
- `CHANGELOG.md`

---

**Last Updated:** 2026-05-17
**Plan window:** 2026-05-17 → 2026-06-15
**Maintainer:** Jonathan Jewell (hyperpolymath)
