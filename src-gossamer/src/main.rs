// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

// PanLL Connected Workbench v0.2.0
// ===========================================================================
//
// Backend service built on gossamer-rs (webview shell replacing Tauri).
// Provides:
//   • Identity snapshots (VeriSimDB + filesystem)
//   • System tray integration
//   • Burble/Gossamer service toggling
//   • Team state replication
//   • Service registry
//   • Settings persistence
//   • LLM coordination
//   • Groove discovery
//   • VeriSimDB integration
//
// Entry point: main() → gossamer::run() → webview shell.

use gossamer_rs::App;
use serde_json::json;
use std::env;

// -----------------------------------------------------------------------
// Module imports
// -----------------------------------------------------------------------

// Backend logic lives in the `panll` library crate (GTK-free, unit-tested).
use panll::{groove, identity, llm_coding, service_registry, settings};

/// System Tray — system tray integration and service toggling (v0.2.0).
/// Stays in the binary: it depends on `gossamer_rs` (GTK/WebKit).
mod system_tray;

// Constants and helpers (moved from old Tauri main.rs)
// ===========================================================================

const DEFAULT_VERISIMDB_URL: &str = "http://localhost:8080/api/v1";

fn verisim_url() -> String {
    env::var("VERISIMDB_URL").unwrap_or_else(|_| DEFAULT_VERISIMDB_URL.to_string())
}

fn verisim_orch_url() -> String {
    env::var("VERISIMDB_ORCH_URL").unwrap_or_else(|_| "http://localhost:4080".to_string())
}

// -----------------------------------------------------------------------
// Helper functions
// -----------------------------------------------------------------------

fn get_str(payload: &serde_json::Value, key: &str) -> Result<String, String> {
    payload
        .get(key)
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .ok_or_else(|| format!("Missing or invalid key: {}", key))
}

fn result_to_json<T: serde::Serialize>(result: Result<T, String>) -> Result<serde_json::Value, String> {
    match result {
        Ok(val) => Ok(json!({"ok": true, "result": val})),
        Err(err) => Ok(json!({"ok": false, "error": err})),
    }
}

// Wrap a Result whose Ok variant is itself a JSON-encoded string,
// so the response is `{"ok": true, "result": <object>}` instead of a
// string-wrapped string the client would have to parse twice.
fn result_str_to_json(result: Result<String, String>) -> Result<serde_json::Value, String> {
    match result {
        Ok(s) => result_to_json(Ok(
            serde_json::from_str::<serde_json::Value>(&s).unwrap_or(serde_json::Value::Null),
        )),
        Err(e) => result_to_json::<serde_json::Value>(Err(e)),
    }
}

fn blocking_get(url: &str, timeout_secs: u64) -> Result<String, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;
    let resp = client.get(url).send().map_err(|e| format!("GET failed: {}", e))?;
    if resp.status().is_success() {
        resp.text().map_err(|e| format!("Read failed: {}", e))
    } else {
        Err(format!("HTTP {} - {}", resp.status(), resp.text().unwrap_or_default()))
    }
}

fn blocking_post(url: &str, body: &serde_json::Value, timeout_secs: u64) -> Result<String, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;
    let resp = client.post(url).json(body).send().map_err(|e| format!("POST failed: {}", e))?;
    if resp.status().is_success() {
        resp.text().map_err(|e| format!("Read failed: {}", e))
    } else {
        Err(format!("HTTP {} - {}", resp.status(), resp.text().unwrap_or_default()))
    }
}

fn blocking_post_empty(url: &str, timeout_secs: u64) -> Result<String, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;
    let resp = client.post(url).send().map_err(|e| format!("POST failed: {}", e))?;
    if resp.status().is_success() {
        resp.text().map_err(|e| format!("Read failed: {}", e))
    } else {
        Err(format!("HTTP {} - {}", resp.status(), resp.text().unwrap_or_default()))
    }
}

// -----------------------------------------------------------------------
// Main entry point
// -----------------------------------------------------------------------

fn main() {
    // Spawn the groove discovery server (HTTP on 127.0.0.1:8000) on its own
    // thread before the webview starts. This lets peers in the mesh
    // (Burble, Vext, Hypatia, VeriSimDB) probe `/.well-known/groove` and
    // discover PanLL's panel-ui capability for the entire app lifetime.
    // `spawn()` also starts the mesh-monitor thread internally.
    groove::spawn();

    // Initialize Gossamer app
    let app = App::new("PanLL", 1280, 800);

    // Register all commands
    if let Ok(mut app_ok) = app {
        register_commands(&mut app_ok);
        let _ = system_tray::init(&app_ok);
        app_ok.run();
        system_tray::cleanup();
    }
}

fn register_commands(app: &mut gossamer_rs::App) {
    // -----------------------------------------------------------------------
    // LLM Coding commands
    // -----------------------------------------------------------------------

    app.command("llm_coding_init", |_payload| {
        result_str_to_json(llm_coding::commands::llm_coding_init())
    });

    app.command("llm_coding_spawn", |payload: serde_json::Value| {
        match serde_json::from_value::<llm_coding::types::SpawnRequest>(payload) {
            Ok(request) => result_str_to_json(llm_coding::commands::llm_coding_spawn(request)),
            Err(e) => result_to_json::<serde_json::Value>(Err(format!(
                "Invalid SpawnRequest payload: {}",
                e
            ))),
        }
    });

    app.command("llm_coding_freeze", |payload| {
        let session_id = get_str(&payload, "session_id").unwrap_or_default();
        result_str_to_json(llm_coding::commands::llm_coding_freeze(session_id))
    });

    app.command("llm_coding_thaw", |payload| {
        let session_id = get_str(&payload, "session_id").unwrap_or_default();
        result_str_to_json(llm_coding::commands::llm_coding_thaw(session_id))
    });

    app.command("llm_coding_terminate", |payload| {
        let session_id = get_str(&payload, "session_id").unwrap_or_default();
        result_str_to_json(llm_coding::commands::llm_coding_terminate(session_id))
    });

    app.command("llm_coding_list_sessions", |_payload| {
        result_str_to_json(llm_coding::commands::llm_coding_list_sessions())
    });

    app.command("llm_coding_session_status", |payload| {
        let session_id = get_str(&payload, "session_id").unwrap_or_default();
        result_str_to_json(llm_coding::commands::llm_coding_session_status(session_id))
    });

    app.command("llm_coding_append_message", |payload| {
        let session_id = get_str(&payload, "session_id").unwrap_or_default();
        let content = get_str(&payload, "content").unwrap_or_default();
        result_str_to_json(llm_coding::commands::llm_coding_append_message(
            session_id, content,
        ))
    });

    app.command("llm_coding_get_messages", |payload| {
        let session_id = get_str(&payload, "session_id").unwrap_or_default();
        result_str_to_json(llm_coding::commands::llm_coding_get_messages(session_id))
    });

    app.command("llm_coding_system_resources", |_payload| {
        result_str_to_json(llm_coding::commands::llm_coding_system_resources())
    });

    // -----------------------------------------------------------------------
    // Groove discovery — no commands.
    //
    // Groove is an external discovery surface: peers probe
    // `GET /.well-known/groove` on port 8000 to find PanLL's panel-ui
    // capability. The server is launched in `main()` via `groove::spawn()`,
    // which also starts the mesh monitor. There is nothing for the webview
    // to call locally.
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // Service Registry commands (Connected Workbench v0.2.0)
    // -----------------------------------------------------------------------

    // The registry is a fixed env-driven set (verisim, echidna, burble, boj,
    // typell) — there is no dynamic register/unregister. The Settings panel
    // reconfigures URLs at runtime via `service_set_url`.

    app.command("service_list", |_payload| {
        result_to_json(service_registry::get_registry())
    });

    app.command("service_set_url", |payload| {
        let key = get_str(&payload, "service_key").unwrap_or_default();
        let url = get_str(&payload, "url").unwrap_or_default();
        result_to_json(service_registry::update_service_url(&key, &url))
    });

    app.command("service_status_all", |_payload| {
        result_to_json(service_registry::check_all_services())
    });

    app.command("service_status", |payload| {
        let key = get_str(&payload, "service_key").unwrap_or_default();
        result_to_json(service_registry::check_service(&key))
    });

    // -----------------------------------------------------------------------
    // Settings commands (Connected Workbench v0.2.0)
    // -----------------------------------------------------------------------

    app.command("settings_get", |_payload| {
        result_to_json(settings::settings_get())
    });

    app.command("settings_set", |payload| {
        let key = get_str(&payload, "key").unwrap_or_default();
        let value = get_str(&payload, "value").unwrap_or_default();
        result_to_json(settings::settings_set(&key, &value))
    });

    app.command("settings_reset", |_payload| {
        result_to_json(settings::settings_reset())
    });

    app.command("settings_save", |payload| {
        let settings_json = get_str(&payload, "settings_json").unwrap_or_default();
        result_to_json(settings::settings_save(&settings_json))
    });

    // -----------------------------------------------------------------------
    // Identity commands (Connected Workbench v0.2.0)
    // -----------------------------------------------------------------------

    app.command("identity_save", |payload| {
        let name = get_str(&payload, "name").unwrap_or_default();
        let panll_state = get_str(&payload, "panll_state").unwrap_or_default();
        let settings = get_str(&payload, "settings").unwrap_or_default();
        let service_urls = get_str(&payload, "service_urls").unwrap_or_default();
        result_to_json(identity::identity_save(&name, &panll_state, &settings, &service_urls))
    });

    app.command("identity_load", |payload| {
        let id = get_str(&payload, "id").unwrap_or_default();
        result_to_json(identity::identity_load(&id))
    });

    app.command("identity_list", |_payload| {
        result_to_json(identity::identity_list())
    });

    app.command("identity_delete", |payload| {
        let id = get_str(&payload, "id").unwrap_or_default();
        result_to_json(identity::identity_delete(&id))
    });

    app.command("team_broadcast_state", |payload| {
        let snapshot_json = get_str(&payload, "snapshot_json").unwrap_or_default();
        result_to_json(identity::team_broadcast_state(&snapshot_json))
    });

    // -----------------------------------------------------------------------
    // System Tray commands (Connected Workbench v0.2.0)
    // -----------------------------------------------------------------------

    app.command("system_tray_toggle_burble", |_payload| {
        result_to_json(Ok(system_tray::toggle_burble()))
    });

    app.command("system_tray_toggle_gossamer", |_payload| {
        result_to_json(Ok(system_tray::toggle_gossamer()))
    });

    app.command("system_tray_get_burble_status", |_payload| {
        result_to_json(Ok(system_tray::get_burble_status()))
    });

    app.command("system_tray_get_gossamer_status", |_payload| {
        result_to_json(Ok(system_tray::get_gossamer_status()))
    });

    // -----------------------------------------------------------------------
    // VeriSimDB commands (Connected Workbench v0.2.0)
    // -----------------------------------------------------------------------

    app.command("verisim_health", |_payload| {
        result_str_to_json(blocking_get(&format!("{}/health", verisim_url()), 5))
    });

    app.command("verisim_vcl_execute", |payload| {
        let vcl = get_str(&payload, "vcl").unwrap_or_default();
        let url = format!("{}/vcl/execute", verisim_url());
        result_str_to_json(blocking_post(&url, &json!({"vcl": vcl}), 10))
    });

    app.command("verisim_octads_list", |payload: serde_json::Value| {
        let limit = payload.get("limit").and_then(|v| v.as_u64()).unwrap_or(100) as usize;
        let offset = payload.get("offset").and_then(|v| v.as_u64()).unwrap_or(0) as usize;
        result_str_to_json(blocking_get(
            &format!("{}/octads?limit={}&offset={}", verisim_url(), limit, offset),
            10,
        ))
    });

    app.command("verisim_drift_entity", |payload| {
        let entity_id = get_str(&payload, "entity_id").unwrap_or_default();
        result_str_to_json(blocking_get(
            &format!("{}/drift/entity/{}", verisim_url(), entity_id),
            10,
        ))
    });

    app.command("verisim_normalizer_trigger", |payload| {
        let entity_id = get_str(&payload, "entity_id").unwrap_or_default();
        result_str_to_json(blocking_post_empty(
            &format!("{}/normalizer/trigger/{}", verisim_url(), entity_id),
            30,
        ))
    });

    app.command("verisim_octads_get", |payload| {
        let entity_id = get_str(&payload, "entity_id").unwrap_or_default();
        result_str_to_json(blocking_get(
            &format!("{}/octads/{}", verisim_url(), entity_id),
            10,
        ))
    });

    app.command("verisim_orch_status", |_payload| {
        result_str_to_json(blocking_get(&format!("{}/status", verisim_orch_url()), 5))
    });

    // VeriSimDB state persistence (Connected Workbench v0.2.0)
    app.command("verisim_save_state", |payload| {
        let key = get_str(&payload, "key").unwrap_or_default();
        let state = get_str(&payload, "state").unwrap_or_default();
        let url = format!("{}/state/{}", verisim_url(), key);
        result_str_to_json(blocking_post(&url, &json!({"state": state}), 10))
    });

    app.command("verisim_load_state", |payload| {
        let key = get_str(&payload, "key").unwrap_or_default();
        let url = format!("{}/state/{}", verisim_url(), key);
        result_str_to_json(blocking_get(&url, 10))
    });
}