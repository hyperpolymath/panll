// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! PanLL Gossamer backend — testable logic library.
//!
//! This crate holds the backend logic that does **not** depend on the
//! Gossamer webview shell (`gossamer-rs`) or the GTK/WebKit native stack.
//! Keeping it as a library means `cargo test --lib` builds and runs the unit
//! suite without linking `libgossamer` or `libgtk-3` / `libwebkit2gtk`.
//!
//! The `panll-gossamer` binary (`main.rs`) depends on this library for all
//! business logic and adds only the IPC/webview wiring and the
//! GTK-coupled `system_tray` module.

/// Shared HTTP client for backend service connections.
pub mod http_client;

/// Service Registry — centralized lifecycle management for backend services.
pub mod service_registry;

/// Settings — user configuration persistence and management.
pub mod settings;

/// Identity — named identity snapshots and team replication.
pub mod identity;

/// Groove — Gossamer groove discovery endpoint (port 8000).
pub mod groove;

/// LLM Coding — multi-session Claude/LLM coordinator.
pub mod llm_coding;

/// Coprocessor — external compute control plane + Zig FFI data plane.
///
/// Previously orphaned (declared by no crate root, so never compiled). Its
/// command handlers are registered through [`ipc`].
pub mod coprocessor;

/// IPC command table — adapts the panel-backend handlers to Gossamer's IPC
/// handler shape. `main.rs` registers every entry with `command_async`.
pub mod ipc;

// ---------------------------------------------------------------------------
// Formerly orphaned modules — panel backends, live service connections
// (`*_live`), and shared helpers (`compat`, `error`).
//
// These modules were declared by no crate root, so they were never compiled,
// linted, or tested. They are GTK/WebKit-free and now build as part of the
// library; each module's own `//!` docs describe it. Their command handlers
// are NOT yet registered in the binary's IPC table (`register_commands` in
// `main.rs`) — that is follow-up work (`docs/TECHNICAL_DEBT.adoc`, F1).
// ---------------------------------------------------------------------------

pub mod a2ml;
pub mod aerie;
pub mod ai;
pub mod boj;
pub mod boj_live;
pub mod capture;
pub mod clade_scanner;
pub mod cloudguard;
pub mod compat;
pub mod dlc_workshop;
pub mod echidna_live;
pub mod error;
pub mod farm;
pub mod feedback;
pub mod fleet;
pub mod game_preview;
pub mod governance;
pub mod hypatia;
pub mod k9;
pub mod level_architect;
pub mod minter;
pub mod multiplayer_monitor;
pub mod network_topology;
pub mod observability;
pub mod overlay;
pub mod plaza;
pub mod provenance;
pub mod release_manager;
pub mod repoloader;
pub mod script_gist;
pub mod security;
pub mod system_update;
pub mod typell;
pub mod umoja;
pub mod ums;
pub mod ums_cartridge;
pub mod valence_shell;
pub mod verisim_live;
pub mod vm_inspector;
pub mod voicetag;
pub mod watcher;
pub mod wiring_inspector;
pub mod workspace;

/// Cross-module integration tests. These exercise the public command-backed
/// functions end-to-end. They live in the lib (not `tests/`) so they run via
/// `cargo test --lib` without cargo also force-building the GTK-linked
/// binary. No disk/home-dir side effects (the settings disk path is excluded
/// deliberately).
#[cfg(test)]
mod integration_tests {
    use crate::{coprocessor, llm_coding, service_registry};

    #[test]
    fn service_registry_lifecycle() {
        let reg = service_registry::get_registry().expect("get_registry");
        let obj = reg.as_object().expect("object");
        assert_eq!(obj.len(), 5);
        for k in ["verisim", "echidna", "burble", "boj", "typell"] {
            assert!(obj.contains_key(k), "missing {k}");
        }
        let updated = service_registry::update_service_url("boj", "http://boj.test:7700/")
            .expect("update_service_url");
        assert_eq!(updated["url"], "http://boj.test:7700");
        assert!(service_registry::check_service("nope").is_err());
        assert!(service_registry::update_service_url("nope", "http://x").is_err());
    }

    #[test]
    fn llm_coding_system_resources_reports_real_host() {
        let json = llm_coding::commands::llm_coding_system_resources().expect("system_resources");
        let v: serde_json::Value = serde_json::from_str(&json).expect("parse");
        assert!(
            v["memory_total_mb"].as_u64().unwrap_or(0) > 0,
            "memory_total_mb should be positive, got {json}"
        );
        let cpu = v["cpu_percent"].as_f64().unwrap_or(-1.0);
        assert!(
            (0.0..=100.0).contains(&cpu),
            "cpu_percent out of range: {cpu}"
        );
    }

    #[test]
    fn coprocessor_backend_parsing_round_trips() {
        use coprocessor::CoproBackend::*;
        // Canonical parse names (note: `label()` is intentionally NOT the
        // inverse of `from_str` — e.g. Io's label is "I/O").
        let cases = [
            ("maths", Maths),
            ("vector", Vector),
            ("tensor", Tensor),
            ("physics", Physics),
            ("crypto", Crypto),
            ("neural", Neural),
            ("quantum", Quantum),
            ("audio", Audio),
            ("graphics", Graphics),
            ("io", Io),
        ];
        for (name, expected) in cases {
            assert_eq!(
                coprocessor::CoproBackend::from_str(name),
                Some(expected),
                "round-trip failed for {name}"
            );
        }
        // Short aliases also resolve.
        assert_eq!(coprocessor::CoproBackend::from_str("gfx"), Some(Graphics));
        assert_eq!(coprocessor::CoproBackend::from_str("not-a-backend"), None);
    }

    #[tokio::test]
    async fn coprocessor_load_ffi_rejects_missing_library() {
        let err = coprocessor::commands::coprocessor_load_ffi(
            "/definitely/not/a/real/libpanll_copro.so".to_string(),
        )
        .await
        .expect_err("loading a missing library must fail");
        assert!(
            err.contains("not found") || err.contains("Failed to load"),
            "got: {err}"
        );
    }

    #[tokio::test]
    async fn coprocessor_ffi_status_is_well_formed() {
        let json = coprocessor::commands::coprocessor_ffi_status()
            .await
            .expect("ffi_status");
        let v: serde_json::Value = serde_json::from_str(&json).expect("parse");
        assert_eq!(v["ffi_loaded"], false);
        assert!(v["cpu_cores"].as_u64().unwrap_or(0) >= 1);
    }
}
