// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL eNSAID - Tauri Backend
//!
//! This module provides the native backend for the PanLL environment,
//! managing system-level operations and the Anti-Crash validation layer.

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};
use serde_json::{json, Value};
use tauri::Manager;

const DEFAULT_PANIC_ATTACK_BIN: &str = "/var/mnt/eclipse/repos/panic-attacker/target/debug/panic-attack";
const DEFAULT_PANIC_ATTACK_REPORTS_DIR: &str = "/var/mnt/eclipse/repos/panic-attacker/reports";

fn panic_attack_binaries() -> Vec<PathBuf> {
    let mut bins = Vec::new();

    if let Ok(custom_bin) = env::var("PANIC_ATTACK_BIN") {
        bins.push(PathBuf::from(custom_bin));
    }

    bins.push(PathBuf::from(DEFAULT_PANIC_ATTACK_BIN));
    bins.push(PathBuf::from(
        "/var/mnt/eclipse/repos/panic-attacker/target/release/panic-attack",
    ));
    bins.push(PathBuf::from("panic-attack"));

    bins
}

fn panic_attack_reports_dir() -> PathBuf {
    env::var("PANIC_ATTACK_REPORTS_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from(DEFAULT_PANIC_ATTACK_REPORTS_DIR))
}

fn latest_panic_attack_report(reports_dir: &Path) -> Result<PathBuf, String> {
    let entries = fs::read_dir(reports_dir).map_err(|err| {
        format!(
            "Failed to read panic-attacker reports dir {}: {}",
            reports_dir.display(),
            err
        )
    })?;

    let mut candidates: Vec<(SystemTime, PathBuf)> = entries
        .filter_map(|entry| {
            let entry = entry.ok()?;
            let path = entry.path();
            let is_json = path.extension().is_some_and(|ext| ext == "json");
            let file_name = path.file_name()?.to_string_lossy();
            let is_attack_report = file_name.starts_with("panic-attack-");
            if !is_json || !is_attack_report {
                return None;
            }
            let modified = entry
                .metadata()
                .ok()
                .and_then(|meta| meta.modified().ok())
                .unwrap_or(UNIX_EPOCH);
            Some((modified, path))
        })
        .collect();

    candidates.sort_by(|a, b| b.0.cmp(&a.0));
    candidates
        .into_iter()
        .next()
        .map(|(_, path)| path)
        .ok_or_else(|| {
            format!(
                "No panic-attacker report JSON files found in {}",
                reports_dir.display()
            )
        })
}

fn help_lists_command(help_text: &str, command: &str) -> bool {
    help_text.lines().any(|line| {
        let trimmed = line.trim_start();
        trimmed.starts_with(command)
            && trimmed
                .chars()
                .nth(command.len())
                .is_some_and(|ch| ch.is_whitespace())
    })
}

fn panic_attacker_capability_json() -> String {
    let reports_dir = panic_attack_reports_dir().display().to_string();
    let mut failures = Vec::new();

    for bin in panic_attack_binaries() {
        match Command::new(&bin).arg("--help").output() {
            Ok(process) if process.status.success() => {
                let stdout = String::from_utf8_lossy(&process.stdout).to_string();
                let supports_panll = help_lists_command(&stdout, "panll");
                let supports_ambush = help_lists_command(&stdout, "ambush");
                let mode = if supports_panll { "full" } else { "fallback" };
                let detail = if supports_panll {
                    "panic-attack panll export is available"
                } else {
                    "panic-attack panll export is unavailable; PanLL will use fallback conversion"
                };

                let payload = json!({
                    "mode": mode,
                    "supports_panll": supports_panll,
                    "supports_ambush": supports_ambush,
                    "binary": bin.display().to_string(),
                    "reports_dir": reports_dir,
                    "detail": detail
                });

                return serde_json::to_string(&payload).unwrap_or_else(|_| {
                    "{\"mode\":\"unavailable\",\"detail\":\"Failed to serialize panic-attacker capability\"}".to_string()
                });
            }
            Ok(process) => {
                let stderr = String::from_utf8_lossy(&process.stderr).trim().to_string();
                failures.push(format!(
                    "{} -> exit {} ({})",
                    bin.display(),
                    process.status,
                    stderr
                ));
            }
            Err(err) => failures.push(format!("{} -> {}", bin.display(), err)),
        }
    }

    let payload = json!({
        "mode": "unavailable",
        "supports_panll": false,
        "supports_ambush": false,
        "binary": Value::Null,
        "reports_dir": reports_dir,
        "detail": format!("No runnable panic-attack binary found. Tried: {}", failures.join(" | "))
    });
    serde_json::to_string(&payload).unwrap_or_else(|_| {
        "{\"mode\":\"unavailable\",\"detail\":\"No runnable panic-attack binary found\"}".to_string()
    })
}

fn temp_panll_export_path() -> PathBuf {
    let millis = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0);
    env::temp_dir().join(format!(
        "panll-event-chain-{}-{}.json",
        std::process::id(),
        millis
    ))
}

fn as_u64(value: &Value) -> Option<u64> {
    value
        .as_u64()
        .or_else(|| value.as_i64().and_then(|n| u64::try_from(n).ok()))
}

fn duration_to_millis(value: &Value) -> Option<u64> {
    if let Some(ms) = as_u64(value) {
        return Some(ms);
    }

    let secs = value.get("secs").and_then(as_u64)?;
    let nanos = value.get("nanos").and_then(as_u64).unwrap_or(0);
    Some(secs.saturating_mul(1000).saturating_add(nanos / 1_000_000))
}

fn fallback_panll_export_from_assault(report_path: &Path) -> Result<String, String> {
    let raw = fs::read_to_string(report_path).map_err(|err| {
        format!(
            "Failed to read panic-attacker report {}: {}",
            report_path.display(),
            err
        )
    })?;

    let parsed: Value = serde_json::from_str(&raw).map_err(|err| {
        format!(
            "Failed to parse panic-attacker report {} as JSON: {}",
            report_path.display(),
            err
        )
    })?;

    let program = parsed
        .get("assail_report")
        .and_then(|v| v.get("program_path"))
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    let weak_points = parsed
        .get("assail_report")
        .and_then(|v| v.get("weak_points"))
        .and_then(Value::as_array)
        .map(|arr| arr.len())
        .unwrap_or(0);

    let critical_weak_points = parsed
        .get("assail_report")
        .and_then(|v| v.get("weak_points"))
        .and_then(Value::as_array)
        .map(|arr| {
            arr.iter()
                .filter(|wp| {
                    wp.get("severity")
                        .and_then(Value::as_str)
                        .map(|sev| sev.eq_ignore_ascii_case("critical"))
                        .unwrap_or(false)
                })
                .count()
        })
        .unwrap_or(0);

    let total_crashes = parsed
        .get("total_crashes")
        .and_then(as_u64)
        .unwrap_or(0);

    let robustness_score = parsed
        .get("overall_assessment")
        .and_then(|v| v.get("robustness_score"))
        .and_then(Value::as_f64)
        .unwrap_or(0.0);

    let mut event_chain = Vec::new();
    let mut timeline_meta = Value::Null;

    if let Some(timeline) = parsed.get("timeline") {
        if let Some(events) = timeline.get("events").and_then(Value::as_array) {
            let duration_ms = timeline
                .get("duration")
                .and_then(duration_to_millis)
                .unwrap_or(0);
            timeline_meta = json!({
                "duration_ms": duration_ms,
                "events": events.len()
            });

            for event in events {
                let id = event
                    .get("id")
                    .and_then(Value::as_str)
                    .unwrap_or("timeline-event")
                    .to_string();
                let axis = event
                    .get("axis")
                    .and_then(Value::as_str)
                    .unwrap_or("unknown")
                    .to_lowercase();
                let start_ms = event.get("start_offset").and_then(duration_to_millis);
                let duration_ms = event
                    .get("duration")
                    .and_then(duration_to_millis)
                    .unwrap_or(0);
                let intensity = event
                    .get("intensity")
                    .and_then(Value::as_str)
                    .unwrap_or("unknown")
                    .to_string();
                let status = if event.get("ran").and_then(Value::as_bool).unwrap_or(false) {
                    "ran".to_string()
                } else {
                    "skipped".to_string()
                };
                let peak_memory = event.get("peak_memory").and_then(as_u64);

                event_chain.push(json!({
                    "id": id,
                    "axis": axis,
                    "start_ms": start_ms,
                    "duration_ms": duration_ms,
                    "intensity": intensity,
                    "status": status,
                    "peak_memory": peak_memory,
                    "notes": Value::Null
                }));
            }
        }
    }

    if event_chain.is_empty() {
        if let Some(results) = parsed.get("attack_results").and_then(Value::as_array) {
            for (index, result) in results.iter().enumerate() {
                let axis = result
                    .get("axis")
                    .and_then(Value::as_str)
                    .unwrap_or("unknown")
                    .to_lowercase();
                let skipped = result
                    .get("skipped")
                    .and_then(Value::as_bool)
                    .unwrap_or(false);
                let success = result
                    .get("success")
                    .and_then(Value::as_bool)
                    .unwrap_or(false);
                let status = if skipped {
                    "skipped"
                } else if success {
                    "passed"
                } else {
                    "failed"
                };
                let duration_ms = result
                    .get("duration")
                    .and_then(duration_to_millis)
                    .unwrap_or(0);
                let peak_memory = result.get("peak_memory").and_then(as_u64);
                let notes = result.get("skip_reason").cloned().unwrap_or(Value::Null);

                event_chain.push(json!({
                    "id": format!("attack-{}-{}", axis, index + 1),
                    "axis": axis,
                    "start_ms": Value::Null,
                    "duration_ms": duration_ms,
                    "intensity": "unknown",
                    "status": status,
                    "peak_memory": peak_memory,
                    "notes": notes
                }));
            }
        }
    }

    let generated_at = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    let export = json!({
        "format": "panll.event-chain.v0",
        "generated_at": format!("unix:{}", generated_at),
        "source": {
            "tool": "panic-attack",
            "report_path": report_path.display().to_string()
        },
        "summary": {
            "program": program,
            "weak_points": weak_points,
            "critical_weak_points": critical_weak_points,
            "total_crashes": total_crashes,
            "robustness_score": robustness_score
        },
        "timeline": timeline_meta,
        "event_chain": event_chain,
        "constraints": []
    });

    serde_json::to_string_pretty(&export)
        .map_err(|err| format!("Failed to serialize fallback PanLL export: {}", err))
}

fn run_panic_attack_panll(report_path: &Path) -> Result<String, String> {
    if !report_path.exists() {
        return Err(format!(
            "panic-attacker report does not exist: {}",
            report_path.display()
        ));
    }

    let mut failures = Vec::new();
    for bin in panic_attack_binaries() {
        let output_path = temp_panll_export_path();
        let run = Command::new(&bin)
            .arg("--quiet")
            .arg("panll")
            .arg(report_path)
            .arg("--output")
            .arg(&output_path)
            .output();

        match run {
            Ok(process) if process.status.success() => {
                let json = fs::read_to_string(&output_path).map_err(|err| {
                    format!(
                        "panic-attack succeeded but export file could not be read ({}): {}",
                        output_path.display(),
                        err
                    )
                })?;
                let _ = fs::remove_file(&output_path);
                return Ok(json);
            }
            Ok(process) => {
                let stderr = String::from_utf8_lossy(&process.stderr).trim().to_string();
                let stdout = String::from_utf8_lossy(&process.stdout).trim().to_string();
                failures.push(format!(
                    "{} -> exit {} (stderr: {}; stdout: {})",
                    bin.display(),
                    process.status,
                    stderr,
                    stdout
                ));
            }
            Err(err) => {
                failures.push(format!("{} -> {}", bin.display(), err));
            }
        }
    }

    if let Ok(export) = fallback_panll_export_from_assault(report_path) {
        return Ok(export);
    }

    Err(format!(
        "Unable to run panic-attack export for {}. Tried binaries: {}",
        report_path.display(),
        failures.join(" | ")
    ))
}

/// Validates a neural inference token against symbolic constraints.
///
/// This is the core of the Anti-Crash Library - no token passes to the
/// Barycentre without symbolic validation.
#[tauri::command]
fn validate_inference(token: &str, constraints: Vec<String>) -> Result<bool, String> {
    // TODO: Implement Echidna-based validation
    // For now, basic constraint checking
    for constraint in &constraints {
        if token.contains(constraint.as_str()) {
            return Err(format!("Constraint violation detected: {}", constraint));
        }
    }
    Ok(true)
}

/// Returns the current Vexation Index based on operator stress indicators.
#[tauri::command]
fn get_vexation_index() -> f64 {
    // TODO: Implement actual stress indicator tracking
    0.0
}

/// Submits feedback to the Feedback-O-Tron collective.
#[tauri::command]
fn submit_feedback(
    _pane_l_state: String,
    _pane_n_state: String,
    _pane_w_state: String,
    report_type: String,
) -> Result<String, String> {
    // TODO: Implement feedback submission to community pool
    Ok(format!("Feedback submitted: {}", report_type))
}

#[tauri::command]
fn import_panic_attacker_report(report_path: String) -> Result<String, String> {
    run_panic_attack_panll(Path::new(&report_path))
}

#[tauri::command]
fn import_latest_panic_attacker_report() -> Result<String, String> {
    let reports_dir = panic_attack_reports_dir();
    let latest_report = latest_panic_attack_report(&reports_dir)?;
    run_panic_attack_panll(&latest_report)
}

#[tauri::command]
fn get_panic_attacker_capability() -> Result<String, String> {
    Ok(panic_attacker_capability_json())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_assault_report_json() -> Value {
        json!({
            "assail_report": {
                "program_path": "/tmp/demo-target",
                "weak_points": [
                    {"severity": "Low"},
                    {"severity": "Critical"}
                ]
            },
            "attack_results": [
                {
                    "axis": "cpu",
                    "success": false,
                    "duration": {"secs": 1, "nanos": 250000000},
                    "peak_memory": 1024
                }
            ],
            "total_crashes": 1,
            "overall_assessment": {
                "robustness_score": 72.5
            }
        })
    }

    #[test]
    fn fallback_export_maps_attack_results_to_event_chain() {
        let report_path = env::temp_dir().join(format!(
            "panic-attacker-fallback-test-{}.json",
            std::process::id()
        ));
        fs::write(
            &report_path,
            serde_json::to_string(&sample_assault_report_json()).expect("serialize test report"),
        )
        .expect("write test report");

        let converted = fallback_panll_export_from_assault(&report_path).expect("convert report");
        let _ = fs::remove_file(&report_path);

        let parsed: Value = serde_json::from_str(&converted).expect("parse converted export");
        assert_eq!(parsed.get("format").and_then(Value::as_str), Some("panll.event-chain.v0"));
        assert_eq!(
            parsed
                .get("summary")
                .and_then(|s| s.get("critical_weak_points"))
                .and_then(Value::as_u64),
            Some(1)
        );

        let event_chain = parsed
            .get("event_chain")
            .and_then(Value::as_array)
            .expect("event_chain array");
        assert_eq!(event_chain.len(), 1);
        assert_eq!(
            event_chain[0].get("axis").and_then(Value::as_str),
            Some("cpu")
        );
        assert_eq!(
            event_chain[0].get("duration_ms").and_then(Value::as_u64),
            Some(1250)
        );
    }

    #[test]
    fn latest_report_prefers_most_recent_json() {
        let reports_dir = env::temp_dir().join(format!(
            "panic-attacker-reports-test-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|d| d.as_millis())
                .unwrap_or(0)
        ));
        fs::create_dir_all(&reports_dir).expect("create reports dir");

        let older = reports_dir.join("panic-attack-older.json");
        let newer = reports_dir.join("panic-attack-newer.json");
        let ignored = reports_dir.join("not-a-report.txt");

        fs::write(&older, "{}").expect("write older report");
        std::thread::sleep(std::time::Duration::from_millis(20));
        fs::write(&newer, "{}").expect("write newer report");
        fs::write(&ignored, "noop").expect("write ignored file");

        let selected = latest_panic_attack_report(&reports_dir).expect("select latest report");
        assert_eq!(selected, newer);

        let _ = fs::remove_file(&older);
        let _ = fs::remove_file(&newer);
        let _ = fs::remove_file(&ignored);
        let _ = fs::remove_dir_all(&reports_dir);
    }

    #[test]
    fn run_panic_attack_panll_returns_event_chain_json() {
        let report_path = env::temp_dir().join(format!(
            "panic-attacker-run-panll-test-{}.json",
            std::process::id()
        ));
        fs::write(
            &report_path,
            serde_json::to_string(&sample_assault_report_json()).expect("serialize test report"),
        )
        .expect("write test report");

        let converted = run_panic_attack_panll(&report_path).expect("convert via cli or fallback");
        let _ = fs::remove_file(&report_path);

        let parsed: Value = serde_json::from_str(&converted).expect("parse converted export");
        assert_eq!(parsed.get("format").and_then(Value::as_str), Some("panll.event-chain.v0"));
        assert!(
            parsed
                .get("event_chain")
                .and_then(Value::as_array)
                .map(|arr| !arr.is_empty())
                .unwrap_or(false),
            "expected non-empty event_chain in converted export"
        );
    }

    #[test]
    fn panic_attacker_panll_cli_fixture_round_trip() {
        let capability: Value = serde_json::from_str(&panic_attacker_capability_json())
            .expect("parse panic-attacker capability json");
        let mode = capability
            .get("mode")
            .and_then(Value::as_str)
            .unwrap_or("unavailable");

        if mode != "full" {
            eprintln!(
                "Skipping fixture round-trip test: panic-attacker capability mode is '{}'",
                mode
            );
            return;
        }

        let fixture = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("tests")
            .join("fixtures")
            .join("panic-attack-ambush-report.json");
        assert!(
            fixture.exists(),
            "missing fixture report for integration test: {}",
            fixture.display()
        );

        let converted = run_panic_attack_panll(&fixture).expect("convert fixture via panic-attack panll");
        let parsed: Value = serde_json::from_str(&converted).expect("parse converted panll export");

        assert_eq!(parsed.get("format").and_then(Value::as_str), Some("panll.event-chain.v0"));
        assert_eq!(
            parsed
                .get("timeline")
                .and_then(|timeline| timeline.get("events"))
                .and_then(Value::as_u64),
            Some(2),
            "expected timeline metadata from fixture export"
        );
        assert_eq!(
            parsed
                .get("event_chain")
                .and_then(Value::as_array)
                .map(|arr| arr.len())
                .unwrap_or(0),
            2,
            "expected two timeline events in exported event_chain"
        );

        let generated_at = parsed
            .get("generated_at")
            .and_then(Value::as_str)
            .unwrap_or("");
        assert!(
            !generated_at.starts_with("unix:"),
            "expected CLI panll export path, but fallback converter marker was found"
        );
    }

    #[test]
    fn help_lists_command_detects_command_rows() {
        let help = r#"
Usage: panic-attack [OPTIONS] <COMMAND>

Commands:
  assault   Full assault
  ambush    Ambush execution
  panll     Export assault report
"#;

        assert!(help_lists_command(help, "ambush"));
        assert!(help_lists_command(help, "panll"));
        assert!(!help_lists_command(help, "nonexistent"));
    }
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![
            validate_inference,
            get_vexation_index,
            submit_feedback,
            import_panic_attacker_report,
            import_latest_panic_attacker_report,
            get_panic_attacker_capability,
        ])
        .setup(|app| {
            #[cfg(debug_assertions)]
            {
                if let Some(window) = app.get_webview_window("main") {
                    window.open_devtools();
                }
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running PanLL");
}
