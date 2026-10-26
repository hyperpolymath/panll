// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! IPC command table for the panel-backend modules.
//!
//! Each entry adapts one backend function to the Gossamer IPC handler shape,
//! `Fn(serde_json::Value) -> Result<serde_json::Value, String>`. The table is
//! GTK-free, so `cargo test --lib` checks every entry; `main.rs` registers it
//! with `App::command_async`, which runs each call on a worker thread instead
//! of the GTK main thread.
//!
//! Conventions shared by every entry:
//! - Arguments are read by parameter name: the snake_case key first, then its
//!   camelCase form. Tauri renamed camelCase keys to snake_case for us; the
//!   Gossamer bridge does not, and the old frontend sent both.
//! - A missing argument reads as JSON `null`. `Option` parameters get `None`;
//!   a required one fails with "missing argument `x`" before the handler runs.
//! - Responses use the envelope the rest of `main.rs` uses:
//!   `{"ok": true, "result": …}` or `{"ok": false, "error": "…"}`. A result
//!   string that is valid JSON is embedded as JSON, anything else as a string.
//! - `async fn` handlers run to completion on one shared Tokio runtime, so
//!   tasks they spawn (e.g. via `compat::spawn_async`) keep running after the
//!   call returns.

use serde::de::DeserializeOwned;
use serde_json::{json, Value};
use std::future::Future;
use std::sync::OnceLock;

/// A Gossamer IPC handler.
pub type Handler = Box<dyn Fn(Value) -> Result<Value, String> + Send + 'static>;

/// One IPC command.
pub struct Command {
    /// Command name, as the frontend passes it to `invoke`.
    pub name: &'static str,
    /// Arguments the handler cannot run without: every parameter that is not
    /// an `Option` and is not supplied by the backend itself.
    pub required: &'static [&'static str],
    /// The handler. It always returns `Ok`; failures are in the envelope.
    pub handler: Handler,
}

/// Every panel-backend command, grouped by module.
pub fn commands() -> Vec<Command> {
    let mut table = Table(Vec::new());
    coprocessor(&mut table);
    a2ml(&mut table);
    aerie(&mut table);
    ai(&mut table);
    boj(&mut table);
    boj_live(&mut table);
    capture(&mut table);
    clade_scanner(&mut table);
    cloudguard(&mut table);
    dlc_workshop(&mut table);
    echidna_live(&mut table);
    farm(&mut table);
    feedback(&mut table);
    fleet(&mut table);
    game_preview(&mut table);
    governance(&mut table);
    hypatia(&mut table);
    k9(&mut table);
    level_architect(&mut table);
    minter(&mut table);
    network_topology(&mut table);
    observability(&mut table);
    overlay(&mut table);
    plaza(&mut table);
    provenance(&mut table);
    release_manager(&mut table);
    repoloader(&mut table);
    script_gist(&mut table);
    security(&mut table);
    system_update(&mut table);
    typell(&mut table);
    umoja(&mut table);
    ums(&mut table);
    ums_cartridge(&mut table);
    valence_shell(&mut table);
    verisim_live(&mut table);
    vm_inspector(&mut table);
    voicetag(&mut table);
    watcher(&mut table);
    wiring_inspector(&mut table);
    workspace(&mut table);
    workspace_sysinfo(&mut table);
    table.0
}

// ---------------------------------------------------------------------------
// Argument and response helpers
// ---------------------------------------------------------------------------

/// Read argument `name` from `payload`, trying `name` and then its camelCase
/// form. A missing key reads as `null`, so `Option<T>` yields `None`.
pub fn arg<T: DeserializeOwned>(payload: &Value, name: &str) -> Result<T, String> {
    let value = lookup(payload, name).cloned().unwrap_or(Value::Null);
    let missing = value.is_null();
    serde_json::from_value(value).map_err(|e| {
        if missing {
            format!("missing argument `{name}`")
        } else {
            format!("invalid argument `{name}`: {e}")
        }
    })
}

/// Read a struct argument: the value under `name` (or its camelCase form) if
/// present, otherwise the whole payload. The old frontend sent both shapes.
pub fn struct_arg<T: DeserializeOwned>(payload: &Value, name: &str) -> Result<T, String> {
    let value = lookup(payload, name).unwrap_or(payload).clone();
    serde_json::from_value(value).map_err(|e| format!("invalid argument `{name}`: {e}"))
}

/// Wrap a handler result in the IPC response envelope.
pub fn respond(result: Result<String, String>) -> Value {
    match result {
        Ok(text) => {
            let result = serde_json::from_str::<Value>(&text).unwrap_or(Value::String(text));
            json!({ "ok": true, "result": result })
        }
        Err(error) => json!({ "ok": false, "error": error }),
    }
}

/// Run an `async fn` handler to completion on the shared IPC runtime.
///
/// Must not be called from inside a Tokio runtime. Gossamer's worker threads
/// are plain threads, so `command_async` handlers can call it.
pub fn block_on<F>(future: F) -> Result<String, String>
where
    F: Future<Output = Result<String, String>>,
{
    static RUNTIME: OnceLock<Result<tokio::runtime::Runtime, String>> = OnceLock::new();
    let runtime = RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .map_err(|e| format!("cannot start the IPC Tokio runtime: {e}"))
    });
    match runtime {
        Ok(runtime) => runtime.block_on(future),
        Err(e) => Err(e.clone()),
    }
}

fn lookup<'a>(payload: &'a Value, name: &str) -> Option<&'a Value> {
    payload
        .get(name)
        .or_else(|| payload.get(snake_to_camel(name).as_str()))
}

fn snake_to_camel(name: &str) -> String {
    let mut out = String::with_capacity(name.len());
    let mut upper = false;
    for c in name.chars() {
        if c == '_' {
            upper = true;
        } else if upper {
            out.extend(c.to_uppercase());
            upper = false;
        } else {
            out.push(c);
        }
    }
    out
}

struct Table(Vec<Command>);

impl Table {
    fn add<F>(&mut self, name: &'static str, required: &'static [&'static str], f: F)
    where
        F: Fn(&Value) -> Result<String, String> + Send + 'static,
    {
        self.0.push(Command {
            name,
            required,
            handler: Box::new(move |payload| Ok(respond(f(&payload)))),
        });
    }
}

// ---------------------------------------------------------------------------
// Command groups
// ---------------------------------------------------------------------------

fn coprocessor(t: &mut Table) {
    use crate::coprocessor::commands as c;
    t.add("query_compute_engine", &["engine_id", "operation"], |p| {
        block_on(c::query_compute_engine(
            arg(p, "engine_id")?,
            arg(p, "operation")?,
        ))
    });
    t.add("discover_compute_devices", &[], |_| {
        block_on(c::discover_compute_devices())
    });
    // An empty `lib_path` means "use runtime discovery", which is how the
    // "Load Local FFI" action calls it (no path at all).
    t.add("coprocessor_load_ffi", &[], |p| {
        let lib_path: Option<String> = arg(p, "lib_path")?;
        block_on(c::coprocessor_load_ffi(lib_path.unwrap_or_default()))
    });
    t.add(
        "coprocessor_ffi_dispatch",
        &["backend", "operation", "payload"],
        |p| {
            block_on(c::coprocessor_ffi_dispatch(
                arg(p, "backend")?,
                arg(p, "operation")?,
                arg(p, "payload")?,
            ))
        },
    );
    t.add("coprocessor_ffi_status", &[], |_| {
        block_on(c::coprocessor_ffi_status())
    });
    t.add("coprocessor_dispatch_local", &["operation", "input"], |p| {
        block_on(c::coprocessor_dispatch_local(
            arg(p, "operation")?,
            arg(p, "input")?,
        ))
    });
    t.add("coprocessor_check_ffi", &[], |_| {
        block_on(c::coprocessor_check_ffi())
    });
    t.add("coprocessor_benchmark", &[], |_| {
        block_on(c::coprocessor_benchmark())
    });
    t.add("coprocessor_local_resources", &[], |_| {
        block_on(c::coprocessor_local_resources())
    });
    t.add(
        "coprocessor_smart_dispatch",
        &["operation", "payload"],
        |p| {
            block_on(c::coprocessor_smart_dispatch(
                arg(p, "operation")?,
                arg(p, "payload")?,
            ))
        },
    );
}

fn a2ml(t: &mut Table) {
    use crate::a2ml::commands as c;
    t.add("a2ml_load_manifest", &["path"], |p| {
        c::a2ml_load_manifest(arg(p, "path")?)
    });
    t.add("a2ml_validate", &["path"], |p| {
        c::a2ml_validate(arg(p, "path")?)
    });
    t.add("a2ml_list", &[], |_| c::a2ml_list());
}

fn aerie(t: &mut Table) {
    use crate::aerie::commands as c;
    t.add("aerie_get_latency", &[], |_| {
        block_on(c::aerie_get_latency())
    });
    t.add("aerie_speed_test", &[], |_| block_on(c::aerie_speed_test()));
}

fn ai(t: &mut Table) {
    use crate::ai::commands as c;
    t.add("ai_send_message", &["request"], |p| {
        block_on(c::ai_send_message(struct_arg(p, "request")?))
    });
    t.add("ai_check_provider", &["provider_id"], |p| {
        block_on(c::ai_check_provider(arg(p, "provider_id")?))
    });
    t.add("ai_set_model", &["provider_id", "model"], |p| {
        block_on(c::ai_set_model(arg(p, "provider_id")?, arg(p, "model")?))
    });
    t.add("ai_set_priority", &["provider_id", "priority"], |p| {
        block_on(c::ai_set_priority(
            arg(p, "provider_id")?,
            arg(p, "priority")?,
        ))
    });
    t.add("ai_toggle_provider", &["provider_id"], |p| {
        block_on(c::ai_toggle_provider(arg(p, "provider_id")?))
    });
    t.add("ai_clear_history", &[], |_| block_on(c::ai_clear_history()));
    t.add("ai_build_context", &["repo_path"], |p| {
        block_on(c::ai_build_context(arg(p, "repo_path")?))
    });
    t.add("ai_get_state", &[], |_| block_on(c::ai_get_state()));
    t.add("ai_send_message_streaming", &["request"], |p| {
        block_on(c::ai_send_message_streaming(
            crate::compat::AppHandle::new(),
            struct_arg(p, "request")?,
        ))
    });
}

fn boj(t: &mut Table) {
    use crate::boj::commands as c;
    t.add("boj_health", &[], |_| c::boj_health());
    t.add("boj_list_cartridges", &[], |_| c::boj_list_cartridges());
    t.add("boj_get_cartridge", &["name"], |p| {
        c::boj_get_cartridge(arg(p, "name")?)
    });
    t.add("boj_load_cartridge", &["name"], |p| {
        c::boj_load_cartridge(arg(p, "name")?)
    });
    t.add("boj_unload_cartridge", &["name"], |p| {
        c::boj_unload_cartridge(arg(p, "name")?)
    });
    t.add("boj_topology", &[], |_| c::boj_topology());
    t.add("boj_invoke", &["name", "tool"], |p| {
        c::boj_invoke(arg(p, "name")?, arg(p, "tool")?, arg(p, "args")?)
    });
    t.add("boj_umoja_status", &[], |_| c::boj_umoja_status());
}

fn boj_live(t: &mut Table) {
    use crate::boj_live as c;
    t.add("boj_live_health", &[], |_| block_on(c::boj_live_health()));
    t.add("boj_live_cartridges", &[], |_| {
        block_on(c::boj_live_cartridges())
    });
    t.add("boj_live_invoke", &["cartridge", "tool", "params"], |p| {
        block_on(c::boj_live_invoke(
            arg(p, "cartridge")?,
            arg(p, "tool")?,
            arg(p, "params")?,
        ))
    });
    t.add("boj_live_topology", &[], |_| {
        block_on(c::boj_live_topology())
    });
    t.add("boj_live_check", &[], |_| block_on(c::boj_live_check()));
}

fn capture(t: &mut Table) {
    use crate::capture::commands as c;
    t.add(
        "save_screenshot",
        &["capture_id", "panel_id", "base64_data", "format"],
        |p| {
            block_on(c::save_screenshot(
                arg(p, "capture_id")?,
                arg(p, "panel_id")?,
                arg(p, "base64_data")?,
                arg(p, "format")?,
            ))
        },
    );
    t.add("print_panel", &["panel_id"], |p| {
        block_on(c::print_panel(arg(p, "panel_id")?))
    });
    t.add("save_demo", &["demo_json"], |p| {
        block_on(c::save_demo(arg(p, "demo_json")?))
    });
    t.add("load_demos", &[], |_| block_on(c::load_demos()));
    t.add("delete_demo", &["demo_id"], |p| {
        block_on(c::delete_demo(arg(p, "demo_id")?))
    });
}

fn clade_scanner(t: &mut Table) {
    use crate::clade_scanner::commands as c;
    t.add("scan_clade_files", &[], |_| block_on(c::scan_clade_files()));
}

fn cloudguard(t: &mut Table) {
    use crate::cloudguard::commands as c;
    t.add("cloudguard_verify_token", &[], |_| {
        c::cloudguard_verify_token()
    });
    t.add("cloudguard_list_zones", &[], |_| c::cloudguard_list_zones());
    t.add("cloudguard_get_zone", &["zone_id"], |p| {
        c::cloudguard_get_zone(arg(p, "zone_id")?)
    });
    t.add("cloudguard_get_settings", &["zone_id"], |p| {
        c::cloudguard_get_settings(arg(p, "zone_id")?)
    });
    t.add(
        "cloudguard_update_setting",
        &["zone_id", "setting_id", "value"],
        |p| {
            c::cloudguard_update_setting(
                arg(p, "zone_id")?,
                arg(p, "setting_id")?,
                arg(p, "value")?,
            )
        },
    );
    t.add(
        "cloudguard_update_settings_batch",
        &["zone_id", "settings_json"],
        |p| c::cloudguard_update_settings_batch(arg(p, "zone_id")?, arg(p, "settings_json")?),
    );
    t.add("cloudguard_list_dns_records", &["zone_id"], |p| {
        c::cloudguard_list_dns_records(arg(p, "zone_id")?)
    });
    t.add("cloudguard_create_dns_record", &["payload"], |p| {
        c::cloudguard_create_dns_record(struct_arg(p, "payload")?)
    });
    t.add("cloudguard_update_dns_record", &["payload"], |p| {
        c::cloudguard_update_dns_record(struct_arg(p, "payload")?)
    });
    t.add(
        "cloudguard_delete_dns_record",
        &["zone_id", "record_id"],
        |p| c::cloudguard_delete_dns_record(arg(p, "zone_id")?, arg(p, "record_id")?),
    );
    t.add("cloudguard_get_dnssec", &["zone_id"], |p| {
        c::cloudguard_get_dnssec(arg(p, "zone_id")?)
    });
    t.add("cloudguard_enable_dnssec", &["zone_id"], |p| {
        c::cloudguard_enable_dnssec(arg(p, "zone_id")?)
    });
    t.add("cloudguard_harden_zone", &["zone_id"], |p| {
        c::cloudguard_harden_zone(arg(p, "zone_id")?)
    });
    t.add("cloudguard_download_config", &["zone_id"], |p| {
        c::cloudguard_download_config(arg(p, "zone_id")?)
    });
}

fn dlc_workshop(t: &mut Table) {
    use crate::dlc_workshop::commands as c;
    t.add("dlc_load_puzzles", &[], |_| block_on(c::dlc_load_puzzles()));
    t.add("dlc_save_puzzle", &["data"], |p| {
        block_on(c::dlc_save_puzzle(arg(p, "data")?))
    });
    t.add("dlc_run_test", &["puzzle_id"], |p| {
        block_on(c::dlc_run_test(arg(p, "puzzle_id")?))
    });
    t.add("dlc_run_all_tests", &[], |_| {
        block_on(c::dlc_run_all_tests())
    });
    t.add("dlc_browse_assets", &[], |_| {
        block_on(c::dlc_browse_assets())
    });
    t.add("dlc_package", &["data"], |p| {
        block_on(c::dlc_package(arg(p, "data")?))
    });
    t.add("dlc_import_puzzle", &["path"], |p| {
        block_on(c::dlc_import_puzzle(arg(p, "path")?))
    });
    t.add("dlc_export_puzzle", &["puzzle_id"], |p| {
        block_on(c::dlc_export_puzzle(arg(p, "puzzle_id")?))
    });
}

fn echidna_live(t: &mut Table) {
    use crate::echidna_live as c;
    t.add("echidna_live_health", &[], |_| {
        block_on(c::echidna_live_health())
    });
    t.add("echidna_live_recommend_tactics", &["obligation"], |p| {
        block_on(c::echidna_live_recommend_tactics(arg(p, "obligation")?))
    });
    t.add("echidna_live_submit_obligation", &["obligation"], |p| {
        block_on(c::echidna_live_submit_obligation(arg(p, "obligation")?))
    });
    t.add("echidna_live_get_result", &["obligation_id"], |p| {
        block_on(c::echidna_live_get_result(arg(p, "obligation_id")?))
    });
    t.add("echidna_live_stats", &[], |_| {
        block_on(c::echidna_live_stats())
    });
}

fn farm(t: &mut Table) {
    use crate::farm::commands as c;
    t.add("farm_list_repos", &[], |_| block_on(c::farm_list_repos()));
    t.add("farm_get_repo", &["name"], |p| {
        block_on(c::farm_get_repo(arg(p, "name")?))
    });
    t.add("farm_get_stats", &[], |_| block_on(c::farm_get_stats()));
}

fn feedback(t: &mut Table) {
    use crate::feedback::commands as c;
    t.add("feedback_save_report", &["report_json"], |p| {
        block_on(c::feedback_save_report(arg(p, "report_json")?))
    });
}

fn fleet(t: &mut Table) {
    use crate::fleet::commands as c;
    t.add("fleet_get_bots", &[], |_| block_on(c::fleet_get_bots()));
    t.add("fleet_get_findings", &[], |_| {
        block_on(c::fleet_get_findings())
    });
    t.add("fleet_dispatch", &["finding_id", "bot_id"], |p| {
        block_on(c::fleet_dispatch(arg(p, "finding_id")?, arg(p, "bot_id")?))
    });
}

fn game_preview(t: &mut Table) {
    use crate::game_preview::commands as c;
    t.add("game_preview_check_server", &["url"], |p| {
        block_on(c::game_preview_check_server(arg(p, "url")?))
    });
    t.add("game_preview_start_server", &["project_dir"], |p| {
        block_on(c::game_preview_start_server(
            arg(p, "project_dir")?,
            arg(p, "port")?,
        ))
    });
    t.add("game_preview_stop_server", &[], |_| {
        block_on(c::game_preview_stop_server())
    });
    t.add("game_preview_control", &["command"], |p| {
        block_on(c::game_preview_control(arg(p, "command")?))
    });
    t.add("game_preview_record_start", &["name"], |p| {
        block_on(c::game_preview_record_start(arg(p, "name")?))
    });
    t.add("game_preview_record_stop", &[], |_| {
        block_on(c::game_preview_record_stop())
    });
    t.add("game_preview_screenshot", &[], |_| {
        block_on(c::game_preview_screenshot())
    });
    t.add("game_preview_stats", &[], |_| {
        block_on(c::game_preview_stats())
    });
    t.add("game_preview_clips_list", &[], |_| {
        block_on(c::game_preview_clips_list())
    });
    t.add("game_preview_clip_delete", &["id"], |p| {
        block_on(c::game_preview_clip_delete(arg(p, "id")?))
    });
}

fn governance(t: &mut Table) {
    use crate::governance::commands as c;
    t.add("governance_nesy_query", &["query"], |p| {
        block_on(c::governance_nesy_query(arg(p, "query")?))
    });
    t.add("governance_nesy_validate", &["adjustment"], |p| {
        block_on(c::governance_nesy_validate(arg(p, "adjustment")?))
    });
    t.add("governance_nesy_probe", &[], |_| {
        block_on(c::governance_nesy_probe())
    });
}

fn hypatia(t: &mut Table) {
    use crate::hypatia::commands as c;
    t.add("hypatia_get_networks", &[], |_| {
        block_on(c::hypatia_get_networks())
    });
    t.add("hypatia_get_scans", &[], |_| {
        block_on(c::hypatia_get_scans())
    });
    t.add("hypatia_scan_repo", &["repo_name"], |p| {
        block_on(c::hypatia_scan_repo(arg(p, "repo_name")?))
    });
}

fn k9(t: &mut Table) {
    use crate::k9::commands as c;
    t.add("k9_load_contractile", &["path"], |p| {
        c::k9_load_contractile(arg(p, "path")?)
    });
    t.add("k9_validate", &["path"], |p| {
        c::k9_validate(arg(p, "path")?)
    });
    t.add("k9_apply_layout", &["name"], |p| {
        c::k9_apply_layout(arg(p, "name")?)
    });
}

fn level_architect(t: &mut Table) {
    use crate::level_architect::commands as c;
    t.add("load_level", &["path"], |p| {
        block_on(c::load_level(arg(p, "path")?))
    });
    t.add("save_level", &["path", "data"], |p| {
        block_on(c::save_level(arg(p, "path")?, arg(p, "data")?))
    });
    t.add("export_level_config", &["data"], |p| {
        block_on(c::export_level_config(arg(p, "data")?))
    });
    t.add("browse_level_assets", &[], |_| {
        block_on(c::browse_level_assets())
    });
    t.add("validate_level", &["data"], |p| {
        block_on(c::validate_level(arg(p, "data")?))
    });
}

fn minter(t: &mut Table) {
    use crate::minter::commands as c;
    t.add("minter_validate_name", &["name"], |p| {
        block_on(c::minter_validate_name(arg(p, "name")?))
    });
    t.add("minter_mint_panel", &["request"], |p| {
        block_on(c::minter_mint_panel(struct_arg(p, "request")?))
    });
}

fn network_topology(t: &mut Table) {
    use crate::network_topology::commands as c;
    t.add("read_network_topology", &[], |_| {
        block_on(c::read_network_topology())
    });
    t.add("read_dns_table", &[], |_| block_on(c::read_dns_table()));
    t.add("read_packet_flow", &[], |_| block_on(c::read_packet_flow()));
    t.add("export_topology_svg", &[], |_| {
        block_on(c::export_topology_svg())
    });
}

fn observability(t: &mut Table) {
    use crate::observability::commands as c;
    t.add("observe_export_sarif", &["report_id"], |p| {
        block_on(c::observe_export_sarif(arg(p, "report_id")?))
    });
    t.add("observe_export_traces", &["batch"], |p| {
        block_on(c::observe_export_traces(arg(p, "batch")?))
    });
    t.add("observe_summary", &[], |_| block_on(c::observe_summary()));
}

fn overlay(t: &mut Table) {
    use crate::overlay::commands as c;
    t.add("overlay_status", &[], |_| c::overlay_status());
    t.add("overlay_health", &[], |_| c::overlay_health());
    t.add("overlay_tor_connect", &[], |p| {
        c::overlay_tor_connect(
            arg(p, "control_host")?,
            arg(p, "control_port")?,
            arg(p, "socks_port")?,
            arg(p, "auth_method")?,
            arg(p, "auth_data")?,
        )
    });
    t.add("overlay_tor_disconnect", &[], |_| {
        c::overlay_tor_disconnect()
    });
    t.add("overlay_tor_status", &[], |_| c::overlay_tor_status());
    t.add(
        "overlay_tor_create_hidden_service",
        &["port", "target_port"],
        |p| c::overlay_tor_create_hidden_service(arg(p, "port")?, arg(p, "target_port")?),
    );
    t.add(
        "overlay_tor_destroy_hidden_service",
        &["onion_address"],
        |p| c::overlay_tor_destroy_hidden_service(arg(p, "onion_address")?),
    );
    t.add("overlay_tor_list_circuits", &[], |_| {
        c::overlay_tor_list_circuits()
    });
    t.add("overlay_tor_get_circuit", &["circuit_id"], |p| {
        c::overlay_tor_get_circuit(arg(p, "circuit_id")?)
    });
    t.add("overlay_tor_resolve", &["hostname"], |p| {
        c::overlay_tor_resolve(arg(p, "hostname")?)
    });
    t.add("overlay_ipfs_connect", &[], |p| {
        c::overlay_ipfs_connect(
            arg(p, "api_host")?,
            arg(p, "api_port")?,
            arg(p, "gateway_port")?,
            arg(p, "repo_path")?,
        )
    });
    t.add("overlay_ipfs_disconnect", &[], |_| {
        c::overlay_ipfs_disconnect()
    });
    t.add("overlay_ipfs_status", &[], |_| c::overlay_ipfs_status());
    t.add("overlay_ipfs_add", &["data"], |p| {
        c::overlay_ipfs_add(arg(p, "data")?, arg(p, "content_type")?)
    });
    t.add("overlay_ipfs_cat", &["cid"], |p| {
        c::overlay_ipfs_cat(arg(p, "cid")?)
    });
    t.add("overlay_ipfs_pin", &["cid"], |p| {
        c::overlay_ipfs_pin(arg(p, "cid")?)
    });
    t.add("overlay_ipfs_unpin", &["cid"], |p| {
        c::overlay_ipfs_unpin(arg(p, "cid")?)
    });
    t.add("overlay_ipfs_dag_get", &["cid"], |p| {
        c::overlay_ipfs_dag_get(arg(p, "cid")?)
    });
    t.add("overlay_eth_connect", &[], |p| {
        c::overlay_eth_connect(arg(p, "rpc_url")?, arg(p, "network")?, arg(p, "chain_id")?)
    });
    t.add("overlay_eth_disconnect", &[], |_| {
        c::overlay_eth_disconnect()
    });
    t.add("overlay_eth_status", &[], |_| c::overlay_eth_status());
    t.add("overlay_eth_timestamp_proof", &["proof_hash"], |p| {
        c::overlay_eth_timestamp_proof(arg(p, "proof_hash")?)
    });
    t.add("overlay_eth_verify_timestamp", &["tx_hash"], |p| {
        c::overlay_eth_verify_timestamp(arg(p, "tx_hash")?)
    });
}

fn plaza(t: &mut Table) {
    use crate::plaza::commands as c;
    t.add("plaza_scan_repo", &["repo_name"], |p| {
        block_on(c::plaza_scan_repo(arg(p, "repo_name")?))
    });
    t.add("plaza_adoption_stats", &[], |_| {
        block_on(c::plaza_adoption_stats())
    });
    t.add("plaza_check_compatibility", &["license"], |p| {
        block_on(c::plaza_check_compatibility(arg(p, "license")?))
    });
}

fn provenance(t: &mut Table) {
    use crate::provenance::commands as c;
    t.add(
        "provenance_analyse_file",
        &["repo_path", "file_path"],
        |p| {
            block_on(c::provenance_analyse_file(
                arg(p, "repo_path")?,
                arg(p, "file_path")?,
            ))
        },
    );
    t.add("provenance_scan_unsound", &["file_path"], |p| {
        block_on(c::provenance_scan_unsound(arg(p, "file_path")?))
    });
}

fn release_manager(t: &mut Table) {
    use crate::release_manager::commands as c;
    t.add("release_generate_changelog", &["from_version"], |p| {
        block_on(c::release_generate_changelog(arg(p, "from_version")?))
    });
    t.add("release_build_artifacts", &["version", "platforms"], |p| {
        block_on(c::release_build_artifacts(
            arg(p, "version")?,
            arg(p, "platforms")?,
        ))
    });
    t.add("release_publish", &["version", "channel"], |p| {
        block_on(c::release_publish(arg(p, "version")?, arg(p, "channel")?))
    });
    t.add("release_read_history", &[], |_| {
        block_on(c::release_read_history())
    });
    t.add("release_bump_version", &["bump_type"], |p| {
        block_on(c::release_bump_version(arg(p, "bump_type")?))
    });
}

fn repoloader(t: &mut Table) {
    use crate::repoloader::commands as c;
    t.add("repoloader_scan", &["repo_path"], |p| {
        block_on(c::repoloader_scan(arg(p, "repo_path")?))
    });
    t.add(
        "repoloader_save_panels",
        &["repo_path", "panels_json"],
        |p| {
            block_on(c::repoloader_save_panels(
                arg(p, "repo_path")?,
                arg(p, "panels_json")?,
            ))
        },
    );
    t.add("repoloader_list_recent", &[], |_| {
        block_on(c::repoloader_list_recent())
    });
    t.add("repoloader_search_farm", &["query"], |p| {
        block_on(c::repoloader_search_farm(arg(p, "query")?))
    });
}

fn script_gist(t: &mut Table) {
    use crate::script_gist::commands as c;
    t.add("script_gist_save", &["gist_json"], |p| {
        block_on(c::script_gist_save(arg(p, "gist_json")?))
    });
    t.add("script_gist_execute", &["gist_json"], |p| {
        block_on(c::script_gist_execute(arg(p, "gist_json")?))
    });
    t.add("script_gist_restore_snapshot", &["snapshot_json"], |p| {
        block_on(c::script_gist_restore_snapshot(arg(p, "snapshot_json")?))
    });
    t.add("script_gist_list", &[], |_| block_on(c::script_gist_list()));
}

fn security(t: &mut Table) {
    use crate::security::commands as c;
    t.add("redact_text", &["text", "panel_id", "patterns_json"], |p| {
        block_on(c::redact_text(
            arg(p, "text")?,
            arg(p, "panel_id")?,
            arg(p, "patterns_json")?,
        ))
    });
    t.add("vault_store", &["key", "value"], |p| {
        block_on(c::vault_store(arg(p, "key")?, arg(p, "value")?))
    });
    t.add("vault_retrieve", &["key"], |p| {
        block_on(c::vault_retrieve(arg(p, "key")?))
    });
    t.add("vault_list", &[], |_| block_on(c::vault_list()));
    t.add("load_trustfile", &["repo_path"], |p| {
        block_on(c::load_trustfile(arg(p, "repo_path")?))
    });
}

fn system_update(t: &mut Table) {
    use crate::system_update::commands as c;
    t.add("system_update_list_components", &[], |_| {
        c::system_update_list_components()
    });
    t.add("system_update_check_all", &[], |_| {
        c::system_update_check_all()
    });
    t.add("system_update_check_component", &["component_id"], |p| {
        c::system_update_check_component(arg(p, "component_id")?)
    });
    t.add("system_update_apply_component", &["component_id"], |p| {
        c::system_update_apply_component(arg(p, "component_id")?)
    });
    t.add("system_update_apply_all", &[], |_| {
        c::system_update_apply_all()
    });
    t.add("system_update_asdf_status", &[], |_| {
        c::system_update_asdf_status()
    });
    t.add("system_update_logs", &[], |_| c::system_update_logs());
    t.add("system_update_last_summary", &[], |_| {
        c::system_update_last_summary()
    });
}

fn typell(t: &mut Table) {
    use crate::typell::commands as c;
    t.add("typell_health", &[], |_| c::typell_health());
    t.add("typell_check", &["expression"], |p| {
        c::typell_check(arg(p, "expression")?, arg(p, "context")?)
    });
    t.add("typell_infer", &["expression"], |p| {
        c::typell_infer(arg(p, "expression")?)
    });
    t.add("typell_refine", &["spec"], |p| {
        c::typell_refine(arg(p, "spec")?, arg(p, "constraints")?)
    });
    t.add("typell_compute", &["term"], |p| {
        c::typell_compute(arg(p, "term")?)
    });
    t.add("typell_list_signatures", &[], |_| {
        c::typell_list_signatures()
    });
    t.add("typell_universes", &[], |_| c::typell_universes());
}

fn umoja(t: &mut Table) {
    use crate::umoja::commands as c;
    t.add("umoja_add_peer", &["address"], |p| {
        block_on(c::umoja_add_peer(arg(p, "address")?))
    });
    t.add("umoja_disconnect_peer", &["node_id"], |p| {
        block_on(c::umoja_disconnect_peer(arg(p, "node_id")?))
    });
    t.add("umoja_trigger_gossip", &[], |_| {
        block_on(c::umoja_trigger_gossip())
    });
    t.add("umoja_sync_catalogue", &["node_id"], |p| {
        block_on(c::umoja_sync_catalogue(arg(p, "node_id")?))
    });
    t.add("umoja_peer_metrics", &["node_id"], |p| {
        block_on(c::umoja_peer_metrics(arg(p, "node_id")?))
    });
}

fn ums(t: &mut Table) {
    use crate::ums::commands as c;
    t.add("ums_load_projects", &[], |_| {
        block_on(c::ums_load_projects())
    });
    t.add("ums_create_project", &["name", "description"], |p| {
        block_on(c::ums_create_project(
            arg(p, "name")?,
            arg(p, "description")?,
        ))
    });
    t.add("ums_open_project", &["project_id"], |p| {
        block_on(c::ums_open_project(arg(p, "project_id")?))
    });
    t.add("ums_delete_project", &["project_id"], |p| {
        block_on(c::ums_delete_project(arg(p, "project_id")?))
    });
    t.add("ums_validate_level", &["level_id"], |p| {
        block_on(c::ums_validate_level(arg(p, "level_id")?))
    });
    t.add("ums_load_templates", &[], |_| {
        block_on(c::ums_load_templates())
    });
    t.add(
        "ums_instantiate_template",
        &["template_id", "project_name"],
        |p| {
            block_on(c::ums_instantiate_template(
                arg(p, "template_id")?,
                arg(p, "project_name")?,
            ))
        },
    );
    t.add("ums_load_assets", &["project_id"], |p| {
        block_on(c::ums_load_assets(arg(p, "project_id")?))
    });
    t.add("ums_import_asset", &["project_id", "file_path"], |p| {
        block_on(c::ums_import_asset(
            arg(p, "project_id")?,
            arg(p, "file_path")?,
        ))
    });
    t.add("ums_publish_mod", &["project_id", "platform"], |p| {
        block_on(c::ums_publish_mod(
            arg(p, "project_id")?,
            arg(p, "platform")?,
        ))
    });
    t.add("ums_load_api_reference", &[], |_| {
        block_on(c::ums_load_api_reference())
    });
}

fn ums_cartridge(t: &mut Table) {
    use crate::ums_cartridge::commands as c;
    t.add("ums_cartridge_validate", &["level"], |p| {
        block_on(c::ums_cartridge_validate(arg(p, "level")?))
    });
    t.add("ums_cartridge_load_level", &["name"], |p| {
        block_on(c::ums_cartridge_load_level(arg(p, "name")?))
    });
    t.add("ums_cartridge_save_level", &["level"], |p| {
        block_on(c::ums_cartridge_save_level(arg(p, "level")?))
    });
    t.add("ums_cartridge_list_levels", &[], |_| {
        block_on(c::ums_cartridge_list_levels())
    });
    t.add("ums_cartridge_export_config", &["level"], |p| {
        block_on(c::ums_cartridge_export_config(arg(p, "level")?))
    });
}

fn valence_shell(t: &mut Table) {
    use crate::valence_shell::commands as c;
    t.add("valence_shell_check", &[], |_| {
        block_on(c::valence_shell_check())
    });
    t.add("valence_shell_spawn", &["shell", "cwd"], |p| {
        block_on(c::valence_shell_spawn(arg(p, "shell")?, arg(p, "cwd")?))
    });
    t.add("valence_shell_input", &["input"], |p| {
        block_on(c::valence_shell_input(
            arg(p, "session_id")?,
            arg(p, "input")?,
        ))
    });
    t.add("valence_shell_record_start", &["name"], |p| {
        block_on(c::valence_shell_record_start(arg(p, "name")?))
    });
    t.add("valence_shell_record_stop", &[], |_| {
        block_on(c::valence_shell_record_stop())
    });
    t.add("valence_shell_recordings_list", &[], |_| {
        block_on(c::valence_shell_recordings_list())
    });
    t.add("valence_shell_recording_delete", &["id"], |p| {
        block_on(c::valence_shell_recording_delete(arg(p, "id")?))
    });
    t.add("valence_shell_checkpoint_create", &["label"], |p| {
        block_on(c::valence_shell_checkpoint_create(arg(p, "label")?))
    });
    t.add("valence_shell_checkpoint_restore", &["id"], |p| {
        block_on(c::valence_shell_checkpoint_restore(
            arg(p, "id")?,
            arg(p, "session_id")?,
        ))
    });
    t.add("valence_shell_checkpoints_list", &[], |_| {
        block_on(c::valence_shell_checkpoints_list())
    });
    t.add("valence_shell_screenshot", &[], |p| {
        block_on(c::valence_shell_screenshot(
            arg(p, "session_id")?,
            arg(p, "lines")?,
        ))
    });
    t.add("valence_shell_recording_export", &["id", "format"], |p| {
        block_on(c::valence_shell_recording_export(
            arg(p, "id")?,
            arg(p, "format")?,
        ))
    });
}

fn verisim_live(t: &mut Table) {
    use crate::verisim_live as c;
    t.add("verisim_live_health", &[], |_| {
        block_on(c::verisim_live_health())
    });
    t.add("verisim_live_list_octads", &[], |_| {
        block_on(c::verisim_live_list_octads())
    });
    t.add("verisim_live_query", &["query"], |p| {
        block_on(c::verisim_live_query(arg(p, "query")?))
    });
    t.add("verisim_live_get_octad", &["id"], |p| {
        block_on(c::verisim_live_get_octad(arg(p, "id")?))
    });
}

fn vm_inspector(t: &mut Table) {
    use crate::vm_inspector::commands as c;
    t.add("vm_inspector_read_state", &[], |_| {
        block_on(c::vm_inspector_read_state())
    });
    t.add("vm_inspector_step_forward", &[], |_| {
        block_on(c::vm_inspector_step_forward())
    });
    t.add("vm_inspector_step_backward", &[], |_| {
        block_on(c::vm_inspector_step_backward())
    });
    t.add("vm_inspector_run", &[], |_| block_on(c::vm_inspector_run()));
    t.add("vm_inspector_load_program", &["assembly"], |p| {
        block_on(c::vm_inspector_load_program(arg(p, "assembly")?))
    });
    t.add("vm_inspector_export_snapshot", &[], |_| {
        block_on(c::vm_inspector_export_snapshot())
    });
    t.add("vm_inspector_read_file", &["path"], |p| {
        block_on(c::vm_inspector_read_file(arg(p, "path")?))
    });
}

fn voicetag(t: &mut Table) {
    use crate::voicetag::commands as c;
    t.add("voicetag_load", &["path"], |p| {
        block_on(c::voicetag_load(arg(p, "path")?))
    });
    t.add("voicetag_save", &["path", "content"], |p| {
        block_on(c::voicetag_save(arg(p, "path")?, arg(p, "content")?))
    });
    t.add("voicetag_delete", &["path"], |p| {
        block_on(c::voicetag_delete(arg(p, "path")?))
    });
    t.add("voicetag_scan", &["path"], |p| {
        block_on(c::voicetag_scan(arg(p, "path")?))
    });
}

fn watcher(t: &mut Table) {
    use crate::watcher::commands as c;
    t.add("watcher_start", &["paths"], |p| {
        block_on(c::watcher_start(
            crate::compat::AppHandle::new(),
            arg(p, "paths")?,
        ))
    });
    t.add("watcher_stop", &[], |_| block_on(c::watcher_stop()));
    t.add("watcher_add_path", &["path"], |p| {
        block_on(c::watcher_add_path(arg(p, "path")?))
    });
    t.add("watcher_remove_path", &["path"], |p| {
        block_on(c::watcher_remove_path(arg(p, "path")?))
    });
    t.add("watcher_status", &[], |_| block_on(c::watcher_status()));
}

fn wiring_inspector(t: &mut Table) {
    use crate::wiring_inspector::commands as c;
    t.add("wiring_inspector_verify", &[], |_| {
        block_on(c::wiring_inspector_verify())
    });
    t.add("wiring_inspector_verify_panel", &["panel_id"], |p| {
        block_on(c::wiring_inspector_verify_panel(arg(p, "panel_id")?))
    });
}

fn workspace(t: &mut Table) {
    use crate::workspace::commands as c;
    t.add("save_arrangement", &["arrangement"], |p| {
        block_on(c::save_arrangement(struct_arg(p, "arrangement")?))
    });
    t.add("load_arrangements", &[], |_| {
        block_on(c::load_arrangements())
    });
    t.add("delete_arrangement", &["arrangement_id"], |p| {
        block_on(c::delete_arrangement(arg(p, "arrangement_id")?))
    });
    t.add("save_session", &["session"], |p| {
        block_on(c::save_session(struct_arg(p, "session")?))
    });
    t.add("load_sessions", &[], |_| block_on(c::load_sessions()));
    t.add("delete_session", &["session_id"], |p| {
        block_on(c::delete_session(arg(p, "session_id")?))
    });
}

fn workspace_sysinfo(t: &mut Table) {
    use crate::workspace::sysinfo as c;
    t.add("get_system_info", &[], |_| block_on(c::get_system_info()));
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    fn call(name: &str, payload: Value) -> Value {
        let commands = commands();
        let cmd = commands
            .iter()
            .find(|c| c.name == name)
            .unwrap_or_else(|| panic!("no command {name}"));
        (cmd.handler)(payload).expect("handlers always return Ok")
    }

    #[test]
    fn arg_reads_snake_then_camel() {
        let p =
            json!({ "panel_id": "a", "repoPath": "b", "both_set": "snake", "bothSet": "camel" });
        assert_eq!(arg::<String>(&p, "panel_id").unwrap(), "a");
        assert_eq!(arg::<String>(&p, "repo_path").unwrap(), "b");
        assert_eq!(arg::<String>(&p, "both_set").unwrap(), "snake");
    }

    #[test]
    fn arg_missing_required_and_optional() {
        let p = json!({});
        assert_eq!(
            arg::<String>(&p, "lib_path").unwrap_err(),
            "missing argument `lib_path`"
        );
        assert_eq!(arg::<Option<u16>>(&p, "port").unwrap(), None);
        assert_eq!(
            arg::<Option<u16>>(&json!({ "port": 8080 }), "port").unwrap(),
            Some(8080)
        );
        let err = arg::<u16>(&json!({ "port": "x" }), "port").unwrap_err();
        assert!(err.starts_with("invalid argument `port`"), "{err}");
    }

    #[test]
    fn struct_arg_accepts_nested_or_flattened() {
        #[derive(serde::Deserialize, Debug, PartialEq)]
        struct Req {
            content: String,
        }
        let nested = json!({ "request": { "content": "hi" } });
        let flat = json!({ "content": "hi" });
        assert_eq!(struct_arg::<Req>(&nested, "request").unwrap().content, "hi");
        assert_eq!(struct_arg::<Req>(&flat, "request").unwrap().content, "hi");
        assert!(struct_arg::<Req>(&json!({}), "request")
            .unwrap_err()
            .contains("missing"));
    }

    #[test]
    fn respond_envelope() {
        assert_eq!(
            respond(Ok(r#"{"a":1}"#.into())),
            json!({ "ok": true, "result": { "a": 1 } })
        );
        assert_eq!(
            respond(Ok("plain text".into())),
            json!({ "ok": true, "result": "plain text" })
        );
        assert_eq!(
            respond(Err("boom".into())),
            json!({ "ok": false, "error": "boom" })
        );
    }

    #[test]
    fn snake_to_camel_cases() {
        assert_eq!(snake_to_camel("provider_id"), "providerId");
        assert_eq!(snake_to_camel("base64_data"), "base64Data");
        assert_eq!(snake_to_camel("path"), "path");
    }

    #[test]
    fn command_names_are_unique_and_disjoint_from_main_rs() {
        let mut seen = HashSet::new();
        for cmd in commands() {
            assert!(seen.insert(cmd.name), "duplicate command {}", cmd.name);
        }
        // Commands main.rs registers itself must not be registered twice.
        let main_rs = include_str!("main.rs");
        for chunk in main_rs.split("app.command(\"").skip(1) {
            let name = chunk.split('"').next().unwrap_or_default();
            assert!(
                !seen.contains(name),
                "{name} is registered in main.rs and the table"
            );
        }
    }

    /// Dispatch is total: every public command handler in the backend
    /// modules is reachable over IPC, from this table or from `main.rs`.
    #[test]
    fn every_backend_command_is_registered() {
        // Public helpers that are not commands.
        const NOT_COMMANDS: &[&str] = &["validate_level_data"];
        let main_rs = include_str!("main.rs");
        let registered: HashSet<&str> = commands().iter().map(|c| c.name).collect();
        let src = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("src-gossamer/src");
        let mut files = vec![src.join("workspace/sysinfo.rs")];
        for entry in std::fs::read_dir(&src).expect("read src-gossamer/src") {
            let path = entry.expect("dir entry").path();
            let name = path.file_name().unwrap_or_default().to_string_lossy();
            if path.join("commands.rs").is_file() {
                files.push(path.join("commands.rs"));
            } else if name.ends_with("_live.rs") {
                files.push(path);
            }
        }
        let mut missing = Vec::new();
        for file in files {
            let text = std::fs::read_to_string(&file).expect("read command file");
            // Only the code before the unit tests.
            let text = text.split("#[cfg(test)]").next().unwrap_or_default();
            for line in text.lines() {
                let Some(rest) = line
                    .strip_prefix("pub async fn ")
                    .or_else(|| line.strip_prefix("pub fn "))
                else {
                    continue;
                };
                let name = rest.split(['(', '<']).next().unwrap_or_default();
                // Skips code templates inside string literals (e.g. `{snake}_health`).
                let is_ident = name.chars().all(|c| c.is_ascii_alphanumeric() || c == '_');
                if !is_ident || NOT_COMMANDS.contains(&name) || registered.contains(name) {
                    continue;
                }
                if !main_rs.contains(&format!("app.command(\"{name}\"")) {
                    missing.push(format!("{} ({})", name, file.display()));
                }
            }
        }
        assert!(missing.is_empty(), "not registered: {missing:#?}");
    }

    /// Every command with a required argument must reject an empty payload
    /// before its handler body runs (so this test has no side effects).
    #[test]
    fn required_arguments_are_enforced() {
        for cmd in commands() {
            if cmd.required.is_empty() {
                continue;
            }
            let response = (cmd.handler)(json!({})).expect("handlers always return Ok");
            assert_eq!(
                response["ok"], false,
                "{} accepted an empty payload",
                cmd.name
            );
            let error = response["error"].as_str().unwrap_or_default();
            assert!(
                error.contains("missing"),
                "{}: unexpected error {error}",
                cmd.name
            );
        }
    }

    #[test]
    fn coprocessor_commands_run_through_the_table() {
        let status = call("coprocessor_ffi_status", json!({}));
        assert_eq!(status["ok"], true, "{status}");
        assert_eq!(status["result"]["ffi_loaded"], false);

        let load = call(
            "coprocessor_load_ffi",
            json!({ "libPath": "/no/such/libpanll_copro.so" }),
        );
        assert_eq!(load["ok"], false, "{load}");

        // `lib_path` is optional: omitting it selects runtime discovery
        // rather than failing as a missing argument.
        let commands = commands();
        let load_ffi = commands
            .iter()
            .find(|c| c.name == "coprocessor_load_ffi")
            .expect("coprocessor_load_ffi is registered");
        assert!(load_ffi.required.is_empty());

        let missing = call("query_compute_engine", json!({ "operation": "x" }));
        assert_eq!(missing["error"], "missing argument `engine_id`");
    }
}
