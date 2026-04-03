; SPDX-License-Identifier: PMPL-1.0-or-later
; PanLL project state — .machine_readable/STATE.scm
; Last updated: 2026-03-23

(state
  (metadata
    (version "0.2.0-dev")
    (last-updated "2026-03-23")
    (author "Jonathan D.A. Jewell"))

  (project-context
    (name "PanLL")
    (description "Parallel Neurosymbolic Layout Language — multi-panel workspace for eNSAID")
    (runtime "Gossamer (migrated from Tauri 2.0)")
    (frontend "ReScript v12 with custom TEA framework")
    (backend "Rust via Gossamer IPC"))

  (current-position
    (summary "TEA runtime crash recovery + Gossamer migration complete")
    (completion-percentage 85)
    (focus "stability — TEA dispatch loop hardening and browser-mode RuntimeBridge fixes")
    (recent-changes
      ("RuntimeBridge.invoke fixed: JsError.throwWithMessage replaced with Promise.reject(new Error()) for browser mode")
      ("TEA dispatch loop: try/catch around processMessage, render, subscriptions prevents permanent freeze")
      ("window.__panll debug API: getModel, dispatch, snapshot for live diagnostics")
      ("Diagnostic bar: live message counter, crash display, click-to-copy snapshot, hard refresh")
      ("13 placeholder view cases added for GSA, Burble, IDApTIK panels")
      ("Back button repositioned from top-left to top-right pill")
      ("All Tauri references removed from RuntimeBridge — Gossamer-only")
      ("src-tauri/ deleted, src-gossamer/ created with migrated Rust backend")
      ("270 commands migrated from Tauri invoke to Gossamer IPC")
      ("ReScript build errors fixed: open keyword, String.indexOf, duplicate symbols")))

  (route-to-mvp
    (milestone "v0.2.0 — Gossamer-native release"
      (tasks
        ("Gossamer IPC wiring for all 270 commands" done)
        ("TEA crash recovery" done)
        ("RuntimeBridge browser-mode Promise fix" done)
        ("Diagnostic bar and debug API" done)
        ("Panel view stubs for GSA/Burble/IDApTIK" done)
        ("End-to-end Gossamer build verification" pending)
        ("Subscription cleanup on panel unmount" pending)
        ("Panel Bus event persistence" pending))))

  (blockers-and-issues
    (blocker "Gossamer build tooling not yet integrated into CI"
      (severity medium)
      (workaround "Manual cargo build in src-gossamer/"))
    (issue "13 panel views are placeholder stubs"
      (severity low)
      (plan "Flesh out as GSA/Burble/IDApTIK mature")))

  (critical-next-actions
    ("Wire Gossamer IPC end-to-end test")
    ("Update CI to build src-gossamer/ instead of src-tauri/")
    ("Implement real GSA panel views")
    ("Add subscription cleanup lifecycle hooks"))

  (session-history
    (session "2026-03-23"
      (focus "TEA crash recovery + Gossamer migration cleanup")
      (changes
        "Fixed RuntimeBridge.invoke Promise rejection for browser mode"
        "Added try/catch crash recovery to TEA dispatch loop"
        "Added window.__panll debug API and diagnostic bar"
        "Completed Tauri→Gossamer migration (270 commands)"
        "Fixed ReScript build errors (open keyword, indexOf, duplicate symbols)"
        "Added 13 placeholder panel views for GSA/Burble/IDApTIK"
        "Moved back button to top-right pill"))
    (session "2026-04-03"
      (focus "XSS security fix")
      (changes
        "panelName sanitized with DOMPurify in detached.html to prevent XSS"))
    (session "2026-04-04"
      (focus "CRG C test blitz — Testing & Benchmarking Taxonomy v1.0")
      (changes
        "Created benches/panll_bench.js (4 groups: TEA cycle, panel lifecycle, IPC throughput, layout scaling)"
        "Added deno task bench to deno.json"
        "Created tests/p2p/tea_properties_test.mjs (8 properties x 100 trials)"
        "Created tests/aspect/security_test.mjs (36 tests: IPC sanitization, sandboxing, redaction, XSS)"
        "Created tests/contract/panel_contracts_test.mjs (30 tests: C1-C9 governance contracts)"
        "Created tests/reflexive/manifest_test.mjs (22 tests: manifest consistency, module exports)"
        "Added Rust smoke tests to 11 untested crates: security, capture, farm, minter, plaza, watcher, workspace, ai, cloudguard, voicetag, hypatia"
        "Fixed pre-existing Rust bugs: valence_shell checkpoint_restore arity + type annotation"
        "Total Rust tests: 267/267 passing"
        "CRG grade: D → C+ (all taxonomy categories populated)"))))
