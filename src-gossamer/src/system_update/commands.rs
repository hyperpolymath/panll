// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! System Update command handlers.
//!
//! Each function matches a command name in SystemUpdateModule.res Commands module.
//! Returns `Result<String, String>` — JSON on success, error message on failure.
//!
//! Commands:
//!   - `system_update_list_components` — list all updatable components
//!   - `system_update_check_all` — scan all components for updates
//!   - `system_update_check_component` — check a single component
//!   - `system_update_apply_component` — apply update to a single component
//!   - `system_update_apply_all` — apply all available updates
//!   - `system_update_asdf_status` — get asdf plugin details
//!   - `system_update_logs` — get update log history
//!   - `system_update_last_summary` — get last update run summary

use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

use serde::Serialize;
use serde_json::json;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize)]
struct Component {
    id: String,
    name: String,
    category: String,
    current_version: String,
    latest_version: Option<String>,
    status: String,
    last_checked: Option<String>,
    managed_by: String,
}

#[derive(Debug, Clone, Serialize)]
struct UpdateSummary {
    total_components: usize,
    up_to_date: usize,
    updates_available: usize,
    updating: usize,
    failed: usize,
    last_full_update: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
struct AsdfPlugin {
    plugin: String,
    installed: String,
    latest: String,
}

#[derive(Debug, Clone, Serialize)]
struct LogEntry {
    timestamp: String,
    summary: String,
}

// ---------------------------------------------------------------------------
// Shell helpers
// ---------------------------------------------------------------------------

/// Run a command and return stdout, or an error string.
fn run_cmd(program: &str, args: &[&str]) -> Result<String, String> {
    Command::new(program)
        .args(args)
        .output()
        .map_err(|e| format!("{} not found or failed to execute: {}", program, e))
        .and_then(|output| {
            if output.status.success() {
                Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
                Err(format!("{} failed: {}", program, stderr))
            }
        })
}

/// Run a command silently, returning stdout or empty string on failure.
fn run_cmd_quiet(program: &str, args: &[&str]) -> String {
    run_cmd(program, args).unwrap_or_default()
}

/// Get ISO 8601 timestamp.
fn now_iso() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    // Simple UTC timestamp without chrono dependency
    format!("{}Z", secs)
}

// ---------------------------------------------------------------------------
// Component discovery
// ---------------------------------------------------------------------------

/// Discover rpm-ostree status.
fn discover_rpm_ostree() -> Component {
    let version = run_cmd_quiet("rpm-ostree", &["--version"]);
    let current = if version.is_empty() {
        "unknown".to_string()
    } else {
        version.lines().next().unwrap_or("unknown").to_string()
    };

    // Check for pending updates
    let status_output = run_cmd_quiet("rpm-ostree", &["status", "--json"]);
    let has_update = status_output.contains("pending");

    Component {
        id: "rpm-ostree".to_string(),
        name: "Fedora Atomic Base OS".to_string(),
        category: "BaseOS".to_string(),
        current_version: current,
        latest_version: None,
        status: if has_update {
            "UpdateAvailable".to_string()
        } else {
            "UpToDate".to_string()
        },
        last_checked: Some(now_iso()),
        managed_by: "rpm-ostree".to_string(),
    }
}

/// Discover Flatpak apps with updates.
fn discover_flatpak() -> Vec<Component> {
    let output = run_cmd_quiet("flatpak", &["list", "--app", "--columns=application,version"]);
    let update_output = run_cmd_quiet("flatpak", &["remote-ls", "--updates", "--columns=application,version"]);

    let updates: Vec<&str> = update_output.lines().collect();

    output
        .lines()
        .filter(|l| !l.is_empty() && l.contains('\t'))
        .map(|line| {
            let parts: Vec<&str> = line.split('\t').collect();
            let app_id = parts.first().unwrap_or(&"unknown").trim();
            let version = parts.get(1).unwrap_or(&"").trim();

            let has_update = updates.iter().any(|u| u.contains(app_id));
            let latest = if has_update {
                updates
                    .iter()
                    .find(|u| u.contains(app_id))
                    .and_then(|u| u.split('\t').nth(1))
                    .map(|v| v.trim().to_string())
            } else {
                None
            };

            Component {
                id: format!("flatpak-{}", app_id),
                name: app_id.to_string(),
                category: "Desktop".to_string(),
                current_version: version.to_string(),
                latest_version: latest.clone(),
                status: if has_update {
                    format!("UpdateAvailable({})", latest.unwrap_or_default())
                } else {
                    "UpToDate".to_string()
                },
                last_checked: Some(now_iso()),
                managed_by: "flatpak".to_string(),
            }
        })
        .collect()
}

/// Discover asdf plugins and their versions.
fn discover_asdf() -> Vec<Component> {
    let output = run_cmd_quiet("opsm", &["plugin", "list"]);

    output
        .lines()
        .filter(|l| !l.is_empty())
        .map(|plugin| {
            let plugin = plugin.trim();
            let current = run_cmd_quiet("opsm", &["current", plugin]);
            let current_ver = current
                .split_whitespace()
                .nth(1)
                .unwrap_or("none")
                .to_string();

            let latest = run_cmd_quiet("opsm", &["latest", plugin]);
            let latest_ver = latest.trim().to_string();

            let has_update =
                !latest_ver.is_empty() && !current_ver.is_empty() && latest_ver != current_ver;

            Component {
                id: format!("asdf-{}", plugin),
                name: format!("{} (asdf)", plugin),
                category: "Toolchain".to_string(),
                current_version: current_ver.clone(),
                latest_version: if latest_ver.is_empty() {
                    None
                } else {
                    Some(latest_ver.clone())
                },
                status: if has_update {
                    format!("UpdateAvailable({})", latest_ver)
                } else if current_ver == "none" {
                    "Unknown".to_string()
                } else {
                    "UpToDate".to_string()
                },
                last_checked: Some(now_iso()),
                managed_by: "asdf".to_string(),
            }
        })
        .collect()
}

/// Discover cargo-installed binaries.
fn discover_cargo() -> Vec<Component> {
    let output = run_cmd_quiet("cargo", &["install", "--list"]);

    output
        .lines()
        .filter(|l| !l.starts_with(' ') && l.contains(' '))
        .map(|line| {
            let parts: Vec<&str> = line.splitn(2, ' ').collect();
            let name = parts[0].trim();
            let version = parts
                .get(1)
                .unwrap_or(&"")
                .trim()
                .trim_start_matches('v')
                .trim_end_matches(':');

            Component {
                id: format!("cargo-{}", name),
                name: format!("{} (cargo)", name),
                category: "PackageManager".to_string(),
                current_version: version.to_string(),
                latest_version: None, // Would need crates.io API to check
                status: "UpToDate".to_string(), // Conservative — no remote check
                last_checked: Some(now_iso()),
                managed_by: "cargo".to_string(),
            }
        })
        .collect()
}

/// Discover Deno version.
fn discover_deno() -> Component {
    let current = run_cmd_quiet("deno", &["--version"]);
    let ver = current
        .lines()
        .next()
        .unwrap_or("")
        .replace("deno ", "")
        .trim()
        .to_string();

    Component {
        id: "deno".to_string(),
        name: "Deno Runtime".to_string(),
        category: "Runtime".to_string(),
        current_version: ver,
        latest_version: None,
        status: "UpToDate".to_string(),
        last_checked: Some(now_iso()),
        managed_by: "deno".to_string(),
    }
}

/// Discover firmware updates via fwupd.
fn discover_fwupd() -> Vec<Component> {
    let output = run_cmd_quiet("fwupdmgr", &["get-devices", "--json"]);
    if output.is_empty() {
        return vec![];
    }

    // Parse JSON output for devices with updates
    let updates = run_cmd_quiet("fwupdmgr", &["get-updates", "--json"]);
    let has_updates = !updates.is_empty() && updates.contains("\"Name\"");

    vec![Component {
        id: "fwupd".to_string(),
        name: "System Firmware".to_string(),
        category: "Firmware".to_string(),
        current_version: "installed".to_string(),
        latest_version: None,
        status: if has_updates {
            "UpdateAvailable".to_string()
        } else {
            "UpToDate".to_string()
        },
        last_checked: Some(now_iso()),
        managed_by: "fwupd".to_string(),
    }]
}

/// Collect all components from all managers.
fn discover_all_components() -> Vec<Component> {
    let mut components = Vec::new();

    components.push(discover_rpm_ostree());
    components.extend(discover_flatpak());
    components.extend(discover_asdf());
    components.extend(discover_cargo());
    components.push(discover_deno());
    components.extend(discover_fwupd());

    components
}

/// Build summary from component list.
fn summarise(components: &[Component]) -> UpdateSummary {
    let mut up_to_date = 0;
    let mut updates_available = 0;
    let mut updating = 0;
    let mut failed = 0;

    for c in components {
        match c.status.as_str() {
            "UpToDate" => up_to_date += 1,
            s if s.starts_with("UpdateAvailable") => updates_available += 1,
            "Updating" => updating += 1,
            s if s.starts_with("Failed") => failed += 1,
            _ => {}
        }
    }

    UpdateSummary {
        total_components: components.len(),
        up_to_date,
        updates_available,
        updating,
        failed,
        last_full_update: Some(now_iso()),
    }
}

// ---------------------------------------------------------------------------
// Command handlers (8 total)
// ---------------------------------------------------------------------------

/// 1. List all updatable components with current/latest versions.
pub fn system_update_list_components() -> Result<String, String> {
    let components = discover_all_components();
    serde_json::to_string(&components).map_err(|e| format!("JSON error: {}", e))
}

/// 2. Check all components for available updates. Returns summary.
pub fn system_update_check_all() -> Result<String, String> {
    let components = discover_all_components();
    let summary = summarise(&components);
    serde_json::to_string(&json!({
        "summary": summary,
        "components": components,
    }))
    .map_err(|e| format!("JSON error: {}", e))
}

/// 3. Check a single component for updates by ID.
pub fn system_update_check_component(component_id: String) -> Result<String, String> {
    let components = discover_all_components();
    let component = components
        .into_iter()
        .find(|c| c.id == component_id)
        .ok_or_else(|| format!("Component not found: {}", component_id))?;
    serde_json::to_string(&component).map_err(|e| format!("JSON error: {}", e))
}

/// 4. Apply update to a single component by ID.
pub fn system_update_apply_component(component_id: String) -> Result<String, String> {
    let (success, output) = if component_id == "rpm-ostree" {
        match run_cmd("rpm-ostree", &["upgrade"]) {
            Ok(o) => (true, o),
            Err(e) => (false, e),
        }
    } else if component_id.starts_with("flatpak-") {
        let app_id = component_id.trim_start_matches("flatpak-");
        match run_cmd("flatpak", &["update", "-y", app_id]) {
            Ok(o) => (true, o),
            Err(e) => (false, e),
        }
    } else if component_id.starts_with("asdf-") {
        let plugin = component_id.trim_start_matches("asdf-");
        let latest = run_cmd("opsm", &["latest", plugin])
            .unwrap_or_else(|_| "latest".to_string());
        match run_cmd("opsm", &["install", plugin, latest.trim()]) {
            Ok(o) => (true, o),
            Err(e) => (false, e),
        }
    } else if component_id.starts_with("cargo-") {
        let crate_name = component_id.trim_start_matches("cargo-");
        match run_cmd("cargo", &["install", crate_name]) {
            Ok(o) => (true, o),
            Err(e) => (false, e),
        }
    } else if component_id == "deno" {
        match run_cmd("deno", &["upgrade"]) {
            Ok(o) => (true, o),
            Err(e) => (false, e),
        }
    } else if component_id == "fwupd" {
        match run_cmd("fwupdmgr", &["update", "-y"]) {
            Ok(o) => (true, o),
            Err(e) => (false, e),
        }
    } else {
        return Err(format!("Unknown component: {}", component_id));
    };

    Ok(json!({ "success": success, "output": output }).to_string())
}

/// 5. Apply all available updates in sequence.
pub fn system_update_apply_all() -> Result<String, String> {
    let components = discover_all_components();
    let mut results = Vec::new();
    let mut success_count = 0;
    let mut fail_count = 0;

    for c in &components {
        if c.status.starts_with("UpdateAvailable") {
            match system_update_apply_component(c.id.clone()) {
                Ok(result) => {
                    success_count += 1;
                    results.push(json!({ "id": c.id, "result": result }));
                }
                Err(e) => {
                    fail_count += 1;
                    results.push(json!({ "id": c.id, "error": e }));
                }
            }
        }
    }

    let summary = summarise(&discover_all_components());

    Ok(json!({
        "success": fail_count == 0,
        "applied": success_count,
        "failed": fail_count,
        "results": results,
        "summary": summary,
    })
    .to_string())
}

/// 6. Get detailed asdf plugin status.
pub fn system_update_asdf_status() -> Result<String, String> {
    let output = run_cmd("asdf", &["plugin", "list"])?;
    let plugins: Vec<AsdfPlugin> = output
        .lines()
        .filter(|l| !l.is_empty())
        .map(|plugin| {
            let plugin = plugin.trim();
            let current = run_cmd_quiet("opsm", &["current", plugin]);
            let installed = current
                .split_whitespace()
                .nth(1)
                .unwrap_or("none")
                .to_string();
            let latest = run_cmd_quiet("opsm", &["latest", plugin]);

            AsdfPlugin {
                plugin: plugin.to_string(),
                installed,
                latest: latest.trim().to_string(),
            }
        })
        .collect();

    serde_json::to_string(&plugins).map_err(|e| format!("JSON error: {}", e))
}

/// 7. Get update log history.
pub fn system_update_logs() -> Result<String, String> {
    // Read from rpm-ostree journal and flatpak history
    let rpm_log = run_cmd_quiet("rpm-ostree", &["db", "diff"]);
    let flatpak_log = run_cmd_quiet("flatpak", &["history", "--columns=time,change,application"]);

    let mut entries = Vec::new();

    for line in rpm_log.lines().take(20) {
        if !line.is_empty() {
            entries.push(LogEntry {
                timestamp: now_iso(),
                summary: format!("[rpm-ostree] {}", line.trim()),
            });
        }
    }

    for line in flatpak_log.lines().take(20) {
        if !line.is_empty() {
            entries.push(LogEntry {
                timestamp: now_iso(),
                summary: format!("[flatpak] {}", line.trim()),
            });
        }
    }

    serde_json::to_string(&entries).map_err(|e| format!("JSON error: {}", e))
}

/// 8. Get last update run summary.
pub fn system_update_last_summary() -> Result<String, String> {
    let rpm_status = run_cmd_quiet("rpm-ostree", &["status"]);
    let first_deployment = rpm_status
        .lines()
        .take(10)
        .collect::<Vec<&str>>()
        .join("\n");

    let flatpak_count = run_cmd_quiet("flatpak", &["list", "--app"])
        .lines()
        .count();

    let asdf_count = run_cmd_quiet("opsm", &["plugin", "list"])
        .lines()
        .filter(|l| !l.is_empty())
        .count();

    let summary = format!(
        "System Update Summary\n\
         =====================\n\
         rpm-ostree: {}\n\
         Flatpak apps: {}\n\
         asdf plugins: {}\n\
         Last checked: {}",
        first_deployment.lines().next().unwrap_or("unknown"),
        flatpak_count,
        asdf_count,
        now_iso()
    );

    Ok(json!({ "summary": summary }).to_string())
}
