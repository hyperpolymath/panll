// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
//! PanLL eNSAID — Gossamer Backend
//!
//! This module provides the native backend for the PanLL environment,
//! managing system-level operations and the Anti-Crash validation layer.
//!
//! Replaces the former Tauri 2.0 backend (src-tauri/) with gossamer-rs.
//! All 103+ command handlers are registered via `app.command()` instead
//! of `#[tauri::command]` macros. The IPC JSON protocol is identical —
//! the ReScript frontend works unchanged via RuntimeBridge.

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::Mutex;
use std::time::{Instant, SystemTime, UNIX_EPOCH};

use once_cell::sync::Lazy;
use serde::Deserialize;
use serde_json::{json, Value};

/// Tauri compatibility shim — provides AppHandle and Emitter for modules
/// that previously depended on `tauri::AppHandle` for event emission.
pub mod compat;

/// Unified error types for the PanLL backend.
pub mod error;

/// CloudGuard — Cloudflare domain security management module.
mod cloudguard;

/// Farm — Git-Private-Farm repo inventory module.
mod farm;

/// VM Inspector — in-process virtual machine with stepping and reverse execution.
mod vm_inspector;

/// VoiceTag — Code MRI Layer 0 sidecar file I/O module.
mod voicetag;

/// Plaza — Palimpsest License adoption and compliance module.
mod plaza;

/// Minter — Panel creation wizard, generates accessible panel modules from templates.
mod minter;

/// Watcher — Filesystem observation infrastructure (notify/inotify/FSEvents).
mod watcher;

/// AI — Multi-provider AI neural interface (Anthropic, Google, Mistral, OpenAI, local).
mod ai;

/// Repo Loader — Repository scanning and panel configuration.
mod repoloader;

/// Workspace — Panel arrangements, groups, sessions, and system info (DD-024/025).
mod workspace;

/// Capture — Screenshots, recordings, and demo packages (DD-022).
mod capture;

/// Security — Redaction, vault, 2FA, and Trustfile enforcement (DD-026/027).
mod security;

/// Overlay — Tor, IPFS, Ethereum overlay network bridge (Aerie backend).
mod overlay;

/// BoJ — Barrel of Jelly cartridge runtime bridge (blocking).
mod boj;

/// BoJ Live — async BoJ-server connection via shared HTTP client (v0.2.0+).
mod boj_live;

/// VeriSimDB Live — async VeriSimDB connection for proof-carrying data operations.
mod verisimdb_live;

/// ECHIDNA Live — async ECHIDNA theorem prover connection.
mod echidna_live;

/// Shared async HTTP client for backend service connections.
mod http_client;

/// TypeLL — Type-Level Language server bridge.
mod typell;

/// Valence Shell — PTY session management, asciicast recordings, and checkpoints.
mod valence_shell;

/// Clade Scanner — reads `.a2ml` clade definition files from `panel-clades/clades/`.
mod clade_scanner;

/// Governance — nesy-MCP bridge for neural governance validation.
mod governance;

/// Coprocessor — Control plane for external compute engines (Axiom.jl, BoJ).
mod coprocessor;

/// Game Preview — IDApTIK game engine preview and recording.
mod game_preview;

/// Network Topology — IDApTIK in-game network topology viewer.
mod network_topology;

/// Level Architect — IDApTIK visual level design tool.
mod level_architect;

/// Multiplayer Monitor — IDApTIK Phoenix sync server monitoring.
mod multiplayer_monitor;

/// DLC Workshop — IDApTIK DLC puzzle pack creation and testing.
mod dlc_workshop;

/// Universal Modding Studio — unified IDApTIK content creation hub.
mod ums;

/// UMS Cartridge — BoJ cartridge backend for ums-mcp routing.
mod ums_cartridge;

/// Release Manager — IDApTIK versioning, changelog, and distribution.
mod release_manager;

/// Umoja — peer management for the federation gossip protocol.
mod umoja;

/// Observability — SARIF export and OpenTelemetry trace collection via observe-mcp.
mod observability;

/// A2ML — AI manifest parsing and validation engine.
mod a2ml;

/// K9 — contractile configuration validation and layout application.
mod k9;

/// Fleet — Gitbot-Fleet bot orchestration dashboard bridge.
mod fleet;

/// Hypatia — Neurosymbolic scanner bridge for CI/CD intelligence.
mod hypatia;

/// Aerie — Network diagnostics (latency probes, speed tests).
mod aerie;

/// Provenance — Git blame analysis and unsound marker detection.
mod provenance;

/// Feedback — Persistent feedback report storage under ~/.panll/feedback/.
mod feedback;

/// Script Gist — Persistent gist storage, execution dispatch, and diachronic snapshots.
mod script_gist;

/// Wiring Inspector — Panel Contract Compiler (PCC) bridge for constraint verification.
mod wiring_inspector;

/// LLM Coding — multi-session Claude/LLM coordinator.
mod llm_coding;

/// Groove — Gossamer groove discovery endpoint (port 8000).
mod groove;

// ===========================================================================
// Constants and helpers (moved from old Tauri main.rs)
// ===========================================================================

/// Fallback binary name for panic-attack.  Resolved at runtime via
/// `PANIC_ATTACK_BIN` env var, then `$PATH` lookup, then sibling directory.
const DEFAULT_PANIC_ATTACK_BIN_NAME: &str = "panic-attack";

/// Fallback reports directory — resolved via `PANIC_ATTACK_REPORTS_DIR` env
/// var, then a `reports/` sibling of the discovered binary.
const DEFAULT_PANIC_ATTACK_REPORTS_SUBDIR: &str = "reports";

/// Tracks operator vexation indicators for the Vexometer.
struct VexationTracker {
    cancellations: u32,
    corrections: u32,
    last_update: Instant,
}

impl VexationTracker {
    fn new() -> Self {
        Self {
            cancellations: 0,
            corrections: 0,
            last_update: Instant::now(),
        }
    }

    fn compute_index(&self) -> f64 {
        let elapsed_secs = self.last_update.elapsed().as_secs_f64();
        let decay_factor = (1.0 - elapsed_secs / 120.0).max(0.1);
        let raw_index =
            (self.cancellations as f64 * 0.15 + self.corrections as f64 * 0.08) * decay_factor;
        raw_index.min(1.0)
    }
}

static VEXATION_TRACKER: Lazy<Mutex<VexationTracker>> =
    Lazy::new(|| Mutex::new(VexationTracker::new()));

#[derive(Deserialize)]
struct AmbushOptions {
    program: String,
    timeline: Option<String>,
    axes: Option<String>,
    intensity: Option<String>,
    duration_secs: Option<u64>,
}

fn panic_attack_binaries() -> Vec<PathBuf> {
    let mut bins = Vec::new();

    // 1. Explicit env var override (highest priority).
    if let Ok(custom_bin) = env::var("PANIC_ATTACK_BIN") {
        bins.push(PathBuf::from(custom_bin));
    }

    // 2. PANIC_ATTACKER_DIR — look for debug and release builds inside it.
    if let Ok(dir) = env::var("PANIC_ATTACKER_DIR") {
        let base = PathBuf::from(&dir);
        bins.push(base.join("target/debug").join(DEFAULT_PANIC_ATTACK_BIN_NAME));
        bins.push(base.join("target/release").join(DEFAULT_PANIC_ATTACK_BIN_NAME));
    }

    // 3. Sibling directory (relative to this binary's location).
    if let Ok(exe) = env::current_exe() {
        if let Some(parent) = exe.parent().and_then(|p| p.parent()) {
            let sibling = parent.join("panic-attacker/target/release").join(DEFAULT_PANIC_ATTACK_BIN_NAME);
            bins.push(sibling);
        }
    }

    // 4. Bare name — relies on $PATH (lowest priority).
    bins.push(PathBuf::from(DEFAULT_PANIC_ATTACK_BIN_NAME));
    bins
}

fn panic_attack_reports_dir() -> PathBuf {
    // 1. Explicit env var.
    if let Ok(dir) = env::var("PANIC_ATTACK_REPORTS_DIR") {
        return PathBuf::from(dir);
    }
    // 2. Sibling of PANIC_ATTACKER_DIR.
    if let Ok(dir) = env::var("PANIC_ATTACKER_DIR") {
        return PathBuf::from(dir).join(DEFAULT_PANIC_ATTACK_REPORTS_SUBDIR);
    }
    // 3. Fallback: temp directory.
    env::temp_dir().join("panic-attack-reports")
}

fn ambush_report_path() -> PathBuf {
    let millis = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0);
    env::temp_dir().join(format!(
        "panic-attack-ambush-{}-{}.json",
        std::process::id(),
        millis
    ))
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
                    "{\"mode\":\"unavailable\",\"detail\":\"Failed to serialize\"}".to_string()
                });
            }
            Ok(process) => {
                let stderr = String::from_utf8_lossy(&process.stderr).trim().to_string();
                failures.push(format!("{} -> exit {} ({})", bin.display(), process.status, stderr));
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
        format!("Failed to read panic-attacker report {}: {}", report_path.display(), err)
    })?;

    let parsed: Value = serde_json::from_str(&raw).map_err(|err| {
        format!("Failed to parse panic-attacker report {} as JSON: {}", report_path.display(), err)
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

    let total_crashes = parsed.get("total_crashes").and_then(as_u64).unwrap_or(0);

    let robustness_score = parsed
        .get("overall_assessment")
        .and_then(|v| v.get("robustness_score"))
        .and_then(Value::as_f64)
        .unwrap_or(0.0);

    let mut event_chain = Vec::new();
    let mut timeline_meta = Value::Null;

    if let Some(timeline) = parsed.get("timeline") {
        if let Some(events) = timeline.get("events").and_then(Value::as_array) {
            let duration_ms = timeline.get("duration").and_then(duration_to_millis).unwrap_or(0);
            timeline_meta = json!({ "duration_ms": duration_ms, "events": events.len() });

            for event in events {
                let id = event.get("id").and_then(Value::as_str).unwrap_or("timeline-event").to_string();
                let axis = event.get("axis").and_then(Value::as_str).unwrap_or("unknown").to_lowercase();
                let start_ms = event.get("start_offset").and_then(duration_to_millis);
                let dur_ms = event.get("duration").and_then(duration_to_millis).unwrap_or(0);
                let intensity = event.get("intensity").and_then(Value::as_str).unwrap_or("unknown").to_string();
                let status = if event.get("ran").and_then(Value::as_bool).unwrap_or(false) {
                    "ran"
                } else {
                    "skipped"
                };
                let peak_memory = event.get("peak_memory").and_then(as_u64);

                event_chain.push(json!({
                    "id": id, "axis": axis, "start_ms": start_ms,
                    "duration_ms": dur_ms, "intensity": intensity,
                    "status": status, "peak_memory": peak_memory, "notes": Value::Null
                }));
            }
        }
    }

    if event_chain.is_empty() {
        if let Some(results) = parsed.get("attack_results").and_then(Value::as_array) {
            for (index, result) in results.iter().enumerate() {
                let axis = result.get("axis").and_then(Value::as_str).unwrap_or("unknown").to_lowercase();
                let skipped = result.get("skipped").and_then(Value::as_bool).unwrap_or(false);
                let success = result.get("success").and_then(Value::as_bool).unwrap_or(false);
                let status = if skipped { "skipped" } else if success { "passed" } else { "failed" };
                let dur_ms = result.get("duration").and_then(duration_to_millis).unwrap_or(0);
                let peak_memory = result.get("peak_memory").and_then(as_u64);
                let notes = result.get("skip_reason").cloned().unwrap_or(Value::Null);

                event_chain.push(json!({
                    "id": format!("attack-{}-{}", axis, index + 1),
                    "axis": axis, "start_ms": Value::Null, "duration_ms": dur_ms,
                    "intensity": "unknown", "status": status,
                    "peak_memory": peak_memory, "notes": notes
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
        return Err(format!("panic-attacker report does not exist: {}", report_path.display()));
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
                let json_str = fs::read_to_string(&output_path).map_err(|err| {
                    format!("panic-attack succeeded but export file could not be read ({}): {}", output_path.display(), err)
                })?;
                let _ = fs::remove_file(&output_path);
                return Ok(json_str);
            }
            Ok(process) => {
                let stderr = String::from_utf8_lossy(&process.stderr).trim().to_string();
                let stdout = String::from_utf8_lossy(&process.stdout).trim().to_string();
                failures.push(format!("{} -> exit {} (stderr: {}; stdout: {})", bin.display(), process.status, stderr, stdout));
            }
            Err(err) => {
                failures.push(format!("{} -> {}", bin.display(), err));
            }
        }
    }

    if let Ok(export) = fallback_panll_export_from_assault(report_path) {
        return Ok(export);
    }

    Err(format!("Unable to run panic-attack export for {}. Tried: {}", report_path.display(), failures.join(" | ")))
}

// ===========================================================================
// Inline command handlers (were in old main.rs, now plain functions)
// ===========================================================================

/// Generic health check — used by the panel switcher to probe any HTTP service.
fn health_check(endpoint: &str) -> Result<String, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))?;

    let resp = client.get(endpoint).send().map_err(|e| format!("Request failed: {e}"))?;

    if resp.status().is_success() {
        resp.text().map_err(|e| format!("Body read error: {e}"))
    } else {
        Err(format!("HTTP {}", resp.status()))
    }
}

/// Validates a neural inference token against symbolic constraints.
fn validate_inference(token: &str, constraints: Vec<String>) -> Result<bool, String> {
    for constraint in &constraints {
        let constraint = constraint.trim();

        if let Some(pattern_start) = constraint.find("!contains(\"") {
            if let Some(pattern_end) = constraint[pattern_start..].find("\")") {
                let pattern = &constraint[pattern_start + 11..pattern_start + pattern_end];
                if token.contains(pattern) {
                    return Err(format!("Forbidden pattern detected: {}", pattern));
                }
                continue;
            }
        }

        if constraint.starts_with("type ") {
            let parts: Vec<&str> = constraint.split_whitespace().collect();
            if parts.len() >= 2 {
                let type_name = parts[1];
                let reserved = ["undefined", "null", "NaN", "eval", "function", "var", "let", "const"];
                if reserved.contains(&type_name) {
                    return Err(format!("Type name uses reserved keyword: {}", type_name));
                }
            }
            continue;
        }

        if constraint.contains(" > ") || constraint.contains(" < ") ||
           constraint.contains(" >= ") || constraint.contains(" <= ") {
            let operators = [" >= ", " <= ", " > ", " < "];
            let mut validated = false;
            for op in &operators {
                if let Some(pos) = constraint.find(op) {
                    let lhs = constraint[..pos].trim();
                    let rhs = constraint[pos + op.len()..].trim();

                    if lhs.is_empty() || lhs.starts_with(|c: char| c.is_ascii_digit()) ||
                       !lhs.chars().all(|c| c.is_alphanumeric() || c == '_') {
                        return Err(format!(
                            "Invalid boundary constraint: '{}' is not a valid identifier in '{}'",
                            lhs, constraint
                        ));
                    }

                    if rhs.parse::<f64>().is_err() {
                        return Err(format!(
                            "Invalid boundary constraint: '{}' is not a valid number in '{}'",
                            rhs, constraint
                        ));
                    }

                    validated = true;
                    break;
                }
            }
            if !validated {
                return Err(format!("Malformed boundary constraint: {}", constraint));
            }
            continue;
        }

        if constraint.contains("==") || constraint.contains("!=") {
            if token.contains(&format!("!{}", constraint)) ||
               (constraint.contains("==") && token.contains(&constraint.replace("==", "!="))) {
                return Err(format!("Token contradicts constraint: {}", constraint));
            }
        }
    }

    Ok(true)
}

/// Records a vexation event (cancellation or correction).
fn record_vexation_event(event_type: &str) -> Result<(), String> {
    let mut tracker = VEXATION_TRACKER.lock().map_err(|e| format!("Lock error: {}", e))?;
    match event_type {
        "cancellation" => {
            tracker.cancellations += 1;
            tracker.last_update = Instant::now();
        }
        "correction" => {
            tracker.corrections += 1;
            tracker.last_update = Instant::now();
        }
        _ => return Err(format!("Unknown event type: {}", event_type)),
    }
    Ok(())
}

/// Returns the current Vexation Index.
fn get_vexation_index() -> f64 {
    VEXATION_TRACKER.lock().map(|t| t.compute_index()).unwrap_or(0.0)
}

/// Submits feedback to the Feedback-O-Tron collective (NDJSON append).
fn submit_feedback(
    pane_l_state: &str,
    pane_n_state: &str,
    pane_w_state: &str,
    report_type: &str,
) -> Result<String, String> {
    let feedback_dir = env::temp_dir().join("panll").join("feedback");
    fs::create_dir_all(&feedback_dir)
        .map_err(|e| format!("Failed to create feedback directory: {}", e))?;

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|e| format!("Time error: {}", e))?
        .as_secs();

    let id = format!("{}-{}", report_type, timestamp);
    let feedback_json = json!({
        "id": id,
        "report_type": report_type,
        "pane_l_state": pane_l_state,
        "pane_n_state": pane_n_state,
        "pane_w_state": pane_w_state,
        "timestamp": timestamp,
    });

    let mut line = serde_json::to_string(&feedback_json).map_err(|e| e.to_string())?;
    line.push('\n');

    let filepath = feedback_dir.join("feedback.ndjson");
    use std::io::Write;
    let mut file = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&filepath)
        .map_err(|e| format!("Failed to open feedback log: {}", e))?;
    file.write_all(line.as_bytes())
        .map_err(|e| format!("Failed to append feedback: {}", e))?;

    Ok(format!("Feedback appended: {}", filepath.display()))
}

fn import_panic_attacker_report(report_path: &str) -> Result<String, String> {
    run_panic_attack_panll(Path::new(report_path))
}

fn import_latest_panic_attacker_report() -> Result<String, String> {
    let reports_dir = panic_attack_reports_dir();
    let latest_report = latest_panic_attack_report(&reports_dir)?;
    run_panic_attack_panll(&latest_report)
}

fn get_panic_attacker_capability() -> Result<String, String> {
    Ok(panic_attacker_capability_json())
}

fn run_panic_attack_ambush(options: AmbushOptions) -> Result<String, String> {
    if options.program.trim().is_empty() {
        return Err("Program path is required".to_string());
    }

    let output_report = ambush_report_path();
    let mut failures = Vec::new();

    for bin in panic_attack_binaries() {
        let mut command = Command::new(&bin);
        command.arg("--quiet").arg("ambush").arg(&options.program).arg("--output").arg(&output_report);

        if let Some(timeline) = &options.timeline {
            if !timeline.trim().is_empty() {
                command.arg("--timeline").arg(timeline);
            }
        }
        if let Some(axes) = &options.axes {
            if !axes.trim().is_empty() {
                command.arg("--axes").arg(axes);
            }
        }
        if let Some(intensity) = &options.intensity {
            if !intensity.trim().is_empty() {
                command.arg("--intensity").arg(intensity);
            }
        }
        if let Some(duration) = options.duration_secs {
            command.arg("--duration").arg(duration.to_string());
        }

        match command.output() {
            Ok(process) if process.status.success() => {
                return run_panic_attack_panll(&output_report);
            }
            Ok(process) => {
                let stderr = String::from_utf8_lossy(&process.stderr).trim().to_string();
                let stdout = String::from_utf8_lossy(&process.stdout).trim().to_string();
                failures.push(format!("{} -> exit {} (stderr: {}; stdout: {})", bin.display(), process.status, stderr, stdout));
            }
            Err(err) => failures.push(format!("{} -> {}", bin.display(), err)),
        }
    }

    Err(format!("Failed to launch ambush. Tried: {}", failures.join(" | ")))
}

// ===========================================================================
// VeriSimDB inline commands
// ===========================================================================

// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_VERISIMDB_URL: &str = "http://localhost:8080/api/v1";

fn verisimdb_url() -> String {
    env::var("VERISIMDB_URL").unwrap_or_else(|_| DEFAULT_VERISIMDB_URL.to_string())
}

fn verisimdb_orch_url() -> String {
    env::var("VERISIMDB_ORCH_URL").unwrap_or_else(|_| "http://localhost:4080".to_string())
}

fn blocking_get(url: &str, timeout_secs: u64) -> Result<String, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;
    match client.get(url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() { Ok(body) } else { Err(format!("HTTP {} : {}", status, body)) }
        }
        Err(e) => Err(format!("Request to {} failed: {}", url, e)),
    }
}

fn blocking_post(url: &str, payload: &Value, timeout_secs: u64) -> Result<String, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;
    match client.post(url).json(payload).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() { Ok(body) } else { Err(format!("HTTP {} : {}", status, body)) }
        }
        Err(e) => Err(format!("Request to {} failed: {}", url, e)),
    }
}

fn blocking_post_empty(url: &str, timeout_secs: u64) -> Result<String, String> {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;
    match client.post(url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() { Ok(body) } else { Err(format!("HTTP {} : {}", status, body)) }
        }
        Err(e) => Err(format!("Request to {} failed: {}", url, e)),
    }
}

// ===========================================================================
// ECHIDNA inline commands
// ===========================================================================

// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_ECHIDNA_URL: &str = "http://localhost:9000/api/v1";

fn echidna_url() -> String {
    env::var("ECHIDNA_URL").unwrap_or_else(|_| DEFAULT_ECHIDNA_URL.to_string())
}

// ===========================================================================
// Protocol-Squisher CLI Bridge
// ===========================================================================

const DEFAULT_PROTOCOL_SQUISHER_BIN: &str = "protocol-squisher";

fn protocol_squisher_bin() -> String {
    env::var("PROTOCOL_SQUISHER_BIN").unwrap_or_else(|_| DEFAULT_PROTOCOL_SQUISHER_BIN.to_string())
}

// ===========================================================================
// My-Lang CLI Bridge
// ===========================================================================

const DEFAULT_MYLANG_BIN: &str = "my";

fn mylang_bin() -> String {
    env::var("MYLANG_BIN").unwrap_or_else(|_| DEFAULT_MYLANG_BIN.to_string())
}

// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_MYLANG_LSP_URL: &str = "http://localhost:7900";

fn mylang_lsp_url() -> String {
    env::var("MYLANG_LSP_URL").unwrap_or_else(|_| DEFAULT_MYLANG_LSP_URL.to_string())
}

// ===========================================================================
// Gossamer application entry point
// ===========================================================================

/// Helper: extract a string field from a JSON payload, with error message.
fn get_str<'a>(payload: &'a Value, field: &str) -> Result<&'a str, String> {
    payload.get(field)
        .and_then(Value::as_str)
        .ok_or_else(|| format!("missing or invalid field: {}", field))
}

/// Helper: extract an optional string field from a JSON payload.
fn get_opt_str(payload: &Value, field: &str) -> Option<String> {
    payload.get(field).and_then(Value::as_str).map(|s| s.to_string())
}

/// Helper: extract a u64 field from a JSON payload.
fn get_u64(payload: &Value, field: &str) -> Result<u64, String> {
    payload.get(field)
        .and_then(|v| v.as_u64().or_else(|| v.as_i64().and_then(|n| u64::try_from(n).ok())))
        .ok_or_else(|| format!("missing or invalid field: {}", field))
}

/// Helper: extract a usize field from a JSON payload.
fn get_usize(payload: &Value, field: &str) -> Result<usize, String> {
    get_u64(payload, field).map(|v| v as usize)
}

/// Wrap a Result<String, String> into a JSON Value for Gossamer response.
fn result_to_json(result: Result<String, String>) -> Result<Value, String> {
    result.map(|s| {
        // Try to parse the string as JSON — if it parses, return the value directly.
        // Otherwise wrap it as a string.
        serde_json::from_str::<Value>(&s).unwrap_or_else(|_| Value::String(s))
    })
}

/// Wrap a Result<bool, String> into a JSON Value.
fn bool_result_to_json(result: Result<bool, String>) -> Result<Value, String> {
    result.map(|b| Value::Bool(b))
}

/// Wrap a Result<(), String> into a JSON Value.
fn unit_result_to_json(result: Result<(), String>) -> Result<Value, String> {
    result.map(|_| json!({"ok": true}))
}

/// Wrap a plain f64 return.
fn f64_to_json(v: f64) -> Result<Value, String> {
    Ok(serde_json::Number::from_f64(v)
        .map(Value::Number)
        .unwrap_or(Value::Null))
}

#[tokio::main]
async fn main() -> Result<(), gossamer_rs::Error> {
    let mut app = gossamer_rs::App::new("PanLL eNSAID", 1440, 900)?;

    // -----------------------------------------------------------------------
    // Inline commands (from old main.rs)
    // -----------------------------------------------------------------------

    app.command("health_check", |payload| {
        let endpoint = get_str(&payload, "endpoint")?;
        result_to_json(health_check(endpoint))
    });

    app.command("validate_inference", |payload| {
        let token = get_str(&payload, "token")?.to_string();
        let constraints: Vec<String> = payload.get("constraints")
            .and_then(Value::as_array)
            .map(|arr| arr.iter().filter_map(Value::as_str).map(String::from).collect())
            .unwrap_or_default();
        bool_result_to_json(validate_inference(&token, constraints))
    });

    app.command("record_vexation_event", |payload| {
        let event_type = get_str(&payload, "event_type")?;
        unit_result_to_json(record_vexation_event(event_type))
    });

    app.command("get_vexation_index", |_payload| {
        f64_to_json(get_vexation_index())
    });

    app.command("submit_feedback", |payload| {
        let pls = get_str(&payload, "pane_l_state")?;
        let pns = get_str(&payload, "pane_n_state")?;
        let pws = get_str(&payload, "pane_w_state")?;
        let rt = get_str(&payload, "report_type")?;
        result_to_json(submit_feedback(pls, pns, pws, rt))
    });

    app.command("import_panic_attacker_report", |payload| {
        let report_path = get_str(&payload, "report_path")?;
        result_to_json(import_panic_attacker_report(report_path))
    });

    app.command("import_latest_panic_attacker_report", |_payload| {
        result_to_json(import_latest_panic_attacker_report())
    });

    app.command("get_panic_attacker_capability", |_payload| {
        result_to_json(get_panic_attacker_capability())
    });

    app.command("run_panic_attack_ambush", |payload| {
        let opts: AmbushOptions = serde_json::from_value(payload.clone())
            .map_err(|e| format!("Invalid ambush options: {e}"))?;
        result_to_json(run_panic_attack_ambush(opts))
    });

    // -----------------------------------------------------------------------
    // VeriSimDB commands
    // -----------------------------------------------------------------------

    app.command("verisimdb_health", |_payload| {
        result_to_json(blocking_get(&format!("{}/health", verisimdb_url()), 5))
    });

    app.command("verisimdb_query", |payload| {
        let query = get_str(&payload, "query")?.to_string();
        let url = format!("{}/vql/execute", verisimdb_url());
        result_to_json(blocking_post(&url, &json!({"query": query}), 30))
    });

    app.command("verisimdb_list_octads", |payload| {
        let limit = get_usize(&payload, "limit")?;
        let offset = get_usize(&payload, "offset")?;
        result_to_json(blocking_get(&format!("{}/octads?limit={}&offset={}", verisimdb_url(), limit, offset), 10))
    });

    app.command("verisimdb_get_drift", |payload| {
        let entity_id = get_str(&payload, "entity_id")?;
        result_to_json(blocking_get(&format!("{}/drift/entity/{}", verisimdb_url(), entity_id), 10))
    });

    app.command("verisimdb_normalise", |payload| {
        let entity_id = get_str(&payload, "entity_id")?;
        result_to_json(blocking_post_empty(&format!("{}/normalizer/trigger/{}", verisimdb_url(), entity_id), 30))
    });

    app.command("verisimdb_get_entity", |payload| {
        let entity_id = get_str(&payload, "entity_id")?;
        result_to_json(blocking_get(&format!("{}/octads/{}", verisimdb_url(), entity_id), 10))
    });

    app.command("verisimdb_telemetry", |_payload| {
        result_to_json(blocking_get(&format!("{}/telemetry", verisimdb_orch_url()), 10))
    });

    app.command("verisimdb_orch_status", |_payload| {
        result_to_json(blocking_get(&format!("{}/status", verisimdb_orch_url()), 5))
    });

    // -----------------------------------------------------------------------
    // ECHIDNA Theorem Prover commands
    // -----------------------------------------------------------------------

    app.command("echidna_health", |_payload| {
        result_to_json(blocking_get(&format!("{}/health", echidna_url()), 5))
    });

    app.command("echidna_list_provers", |_payload| {
        result_to_json(blocking_get(&format!("{}/provers", echidna_url()), 10))
    });

    app.command("echidna_prove", |payload| {
        let content = get_str(&payload, "content")?.to_string();
        let prover = get_opt_str(&payload, "prover");
        let mut p = json!({"content": content});
        if let Some(pv) = prover { p["prover"] = Value::String(pv); }
        result_to_json(blocking_post(&format!("{}/prove", echidna_url()), &p, 60))
    });

    app.command("echidna_verify", |payload| {
        let content = get_str(&payload, "content")?.to_string();
        result_to_json(blocking_post(&format!("{}/verify", echidna_url()), &json!({"content": content}), 60))
    });

    app.command("echidna_search_theorems", |payload| {
        let query = get_str(&payload, "query")?;
        let encoded: String = query.chars().map(|c| match c {
            'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '_' | '.' | '~' => c.to_string(),
            ' ' => "+".to_string(),
            _ => format!("%{:02X}", c as u32),
        }).collect();
        result_to_json(blocking_get(&format!("{}/search?q={}", echidna_url(), encoded), 10))
    });

    app.command("echidna_create_session", |payload| {
        let goal = get_str(&payload, "goal")?.to_string();
        let prover = get_str(&payload, "prover")?.to_string();
        result_to_json(blocking_post(&format!("{}/proofs", echidna_url()), &json!({"goal": goal, "prover": prover}), 30))
    });

    app.command("echidna_get_session", |payload| {
        let session_id = get_str(&payload, "session_id")?;
        result_to_json(blocking_get(&format!("{}/proofs/{}", echidna_url(), session_id), 10))
    });

    app.command("echidna_apply_tactic", |payload| {
        let session_id = get_str(&payload, "session_id")?;
        let name = get_str(&payload, "name")?.to_string();
        let args: Vec<String> = payload.get("args")
            .and_then(Value::as_array)
            .map(|arr| arr.iter().filter_map(Value::as_str).map(String::from).collect())
            .unwrap_or_default();
        result_to_json(blocking_post(
            &format!("{}/proofs/{}/tactics", echidna_url(), session_id),
            &json!({"name": name, "args": args}),
            30,
        ))
    });

    app.command("echidna_suggest_tactics", |payload| {
        let session_id = get_str(&payload, "session_id")?;
        let limit = get_usize(&payload, "limit")?;
        result_to_json(blocking_get(
            &format!("{}/proofs/{}/tactics/suggest?limit={}", echidna_url(), session_id, limit),
            15,
        ))
    });

    // -----------------------------------------------------------------------
    // CloudGuard commands — delegates to cloudguard::commands::*
    // -----------------------------------------------------------------------

    app.command("cloudguard_verify_token", |_payload| {
        result_to_json(cloudguard::commands::cloudguard_verify_token())
    });

    app.command("cloudguard_list_zones", |_payload| {
        result_to_json(cloudguard::commands::cloudguard_list_zones())
    });

    app.command("cloudguard_get_zone", |payload| {
        result_to_json(cloudguard::commands::cloudguard_get_zone(
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_get_settings", |payload| {
        result_to_json(cloudguard::commands::cloudguard_get_settings(
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_update_setting", |payload| {
        let value_str = serde_json::to_string(&payload.get("value").cloned().unwrap_or(Value::Null))
            .unwrap_or_else(|_| "null".to_string());
        result_to_json(cloudguard::commands::cloudguard_update_setting(
            get_str(&payload, "zone_id")?.to_string(),
            get_str(&payload, "setting_id")?.to_string(),
            value_str,
        ))
    });

    app.command("cloudguard_update_settings_batch", |payload| {
        let settings_str = serde_json::to_string(&payload.get("settings").cloned().unwrap_or(Value::Array(vec![])))
            .unwrap_or_else(|_| "[]".to_string());
        result_to_json(cloudguard::commands::cloudguard_update_settings_batch(
            get_str(&payload, "zone_id")?.to_string(),
            settings_str,
        ))
    });

    app.command("cloudguard_list_dns_records", |payload| {
        result_to_json(cloudguard::commands::cloudguard_list_dns_records(
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_create_dns_record", |payload| {
        let record: cloudguard::commands::CreateDnsRecordPayload = serde_json::from_value(
            payload.get("record").cloned().unwrap_or(Value::Null)
        ).map_err(|e| format!("Invalid record: {e}"))?;
        result_to_json(cloudguard::commands::cloudguard_create_dns_record(record))
    });

    app.command("cloudguard_update_dns_record", |payload| {
        let record: cloudguard::commands::UpdateDnsRecordPayload = serde_json::from_value(
            payload.get("record").cloned().unwrap_or(Value::Null)
        ).map_err(|e| format!("Invalid record: {e}"))?;
        result_to_json(cloudguard::commands::cloudguard_update_dns_record(record))
    });

    app.command("cloudguard_delete_dns_record", |payload| {
        result_to_json(cloudguard::commands::cloudguard_delete_dns_record(
            get_str(&payload, "zone_id")?.to_string(),
            get_str(&payload, "record_id")?.to_string(),
        ))
    });

    app.command("cloudguard_get_dnssec", |payload| {
        result_to_json(cloudguard::commands::cloudguard_get_dnssec(
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_enable_dnssec", |payload| {
        result_to_json(cloudguard::commands::cloudguard_enable_dnssec(
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_harden_zone", |payload| {
        result_to_json(cloudguard::commands::cloudguard_harden_zone(
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_download_config", |payload| {
        result_to_json(cloudguard::commands::cloudguard_download_config(
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    // -----------------------------------------------------------------------
    // Farm commands
    // -----------------------------------------------------------------------

    app.command("farm_list_repos", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(farm::commands::farm_list_repos()))
    });

    app.command("farm_get_repo", |payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(farm::commands::farm_get_repo(get_str(&payload, "name")?.to_string())))
    });

    app.command("farm_get_stats", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(farm::commands::farm_get_stats()))
    });

    // -----------------------------------------------------------------------
    // VM Inspector commands
    // -----------------------------------------------------------------------

    app.command("vm_inspector_read_state", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(vm_inspector::commands::vm_inspector_read_state()))
    });

    app.command("vm_inspector_step_forward", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(vm_inspector::commands::vm_inspector_step_forward()))
    });

    app.command("vm_inspector_step_backward", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(vm_inspector::commands::vm_inspector_step_backward()))
    });

    app.command("vm_inspector_run", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(vm_inspector::commands::vm_inspector_run()))
    });

    app.command("vm_inspector_load_program", |payload| {
        let program = get_str(&payload, "program")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(vm_inspector::commands::vm_inspector_load_program(program)))
    });

    app.command("vm_inspector_export_snapshot", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(vm_inspector::commands::vm_inspector_export_snapshot()))
    });

    app.command("vm_inspector_read_file", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(vm_inspector::commands::vm_inspector_read_file(path)))
    });

    // -----------------------------------------------------------------------
    // Plaza commands
    // -----------------------------------------------------------------------

    app.command("plaza_scan_repo", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(plaza::commands::plaza_scan_repo(path)))
    });

    app.command("plaza_adoption_stats", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(plaza::commands::plaza_adoption_stats()))
    });

    app.command("plaza_check_compatibility", |payload| {
        let license = get_str(&payload, "license")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(plaza::commands::plaza_check_compatibility(license)))
    });

    // -----------------------------------------------------------------------
    // Minter commands
    // -----------------------------------------------------------------------

    app.command("minter_validate_name", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(minter::commands::minter_validate_name(name)))
    });

    app.command("minter_mint_panel", |payload| {
        let panel_name = get_str(&payload, "panel_name")?.to_string();
        let short_name = get_str(&payload, "short_name")?.to_string();
        let description = get_str(&payload, "description")?.to_string();
        let icon = get_str(&payload, "icon")?.to_string();
        let backend_kind = get_str(&payload, "backend_kind")?.to_string();
        let accessibility = get_str(&payload, "accessibility")?.to_string();
        let capabilities = get_str(&payload, "capabilities")?.to_string();
        let endpoint = get_str(&payload, "endpoint")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(
            minter::commands::minter_mint_panel(panel_name, short_name, description, icon, backend_kind, accessibility, capabilities, endpoint)
        ))
    });

    // -----------------------------------------------------------------------
    // VoiceTag commands
    // -----------------------------------------------------------------------

    app.command("voicetag_load", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(voicetag::commands::voicetag_load(path)))
    });

    app.command("voicetag_save", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        let data = get_str(&payload, "data")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(voicetag::commands::voicetag_save(path, data)))
    });

    app.command("voicetag_delete", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(voicetag::commands::voicetag_delete(path)))
    });

    app.command("voicetag_scan", |payload| {
        let dir = get_str(&payload, "dir")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(voicetag::commands::voicetag_scan(dir)))
    });

    // -----------------------------------------------------------------------
    // Watcher commands
    // -----------------------------------------------------------------------

    app.command("watcher_start", |payload| {
        let paths: Vec<String> = payload.get("paths")
            .and_then(Value::as_array)
            .map(|arr| arr.iter().filter_map(Value::as_str).map(String::from).collect())
            .unwrap_or_else(|| {
                payload.get("path").and_then(Value::as_str)
                    .map(|p| vec![p.to_string()])
                    .unwrap_or_default()
            });
        let app_handle = compat::AppHandle::new();
        result_to_json(tokio::runtime::Handle::current().block_on(watcher::commands::watcher_start(app_handle, paths)))
    });

    app.command("watcher_stop", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(watcher::commands::watcher_stop()))
    });

    app.command("watcher_add_path", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(watcher::commands::watcher_add_path(path)))
    });

    app.command("watcher_remove_path", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(watcher::commands::watcher_remove_path(path)))
    });

    app.command("watcher_status", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(watcher::commands::watcher_status()))
    });

    // -----------------------------------------------------------------------
    // AI commands
    // -----------------------------------------------------------------------

    app.command("ai_send_message", |payload| {
        let request: crate::ai::types::SendMessageRequest = serde_json::from_value(payload)
            .map_err(|e| format!("Invalid send message request: {e}"))?;
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_send_message(request)))
    });

    app.command("ai_check_provider", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_check_provider(provider_id)))
    });

    app.command("ai_set_model", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        let model = get_str(&payload, "model")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_set_model(provider_id, model)))
    });

    app.command("ai_set_priority", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        let priority = get_u64(&payload, "priority")? as u32;
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_set_priority(provider_id, priority)))
    });

    app.command("ai_toggle_provider", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_toggle_provider(provider_id)))
    });

    app.command("ai_clear_history", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_clear_history()))
    });

    app.command("ai_build_context", |payload| {
        let repo_path = get_str(&payload, "repo_path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_build_context(repo_path)))
    });

    app.command("ai_get_state", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(ai::commands::ai_get_state()))
    });

    // Note: ai_send_message_streaming requires AppHandle for event emission.
    // The compat shim provides AppHandle but the function is async.
    // Registered as a sync command that spawns the async work internally.
    app.command("ai_send_message_streaming", |payload| {
        let request: crate::ai::types::StreamingRequest = serde_json::from_value(payload)
            .map_err(|e| format!("Invalid streaming request: {e}"))?;
        let app_handle = compat::AppHandle::new();
        // Spawn the streaming task on the Tokio runtime
        compat::spawn_async(async move {
            let _ = ai::commands::ai_send_message_streaming(app_handle, request).await;
        });
        Ok(json!({"status": "streaming_started"}))
    });

    // -----------------------------------------------------------------------
    // Repo Loader commands
    // -----------------------------------------------------------------------

    app.command("repoloader_scan", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(repoloader::commands::repoloader_scan(path)))
    });

    app.command("repoloader_save_panels", |payload| {
        let repo_path = get_str(&payload, "repo_path")?.to_string();
        let panels_json = get_str(&payload, "panels_json")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(repoloader::commands::repoloader_save_panels(repo_path, panels_json)))
    });

    app.command("repoloader_list_recent", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(repoloader::commands::repoloader_list_recent()))
    });

    app.command("repoloader_search_farm", |payload| {
        let query = get_str(&payload, "query")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(repoloader::commands::repoloader_search_farm(query)))
    });

    // -----------------------------------------------------------------------
    // Workspace commands
    // -----------------------------------------------------------------------

    app.command("save_arrangement", |payload| {
        let arrangement: workspace::types::Arrangement = serde_json::from_value(payload)
            .map_err(|e| format!("Invalid arrangement: {e}"))?;
        result_to_json(tokio::runtime::Handle::current().block_on(workspace::commands::save_arrangement(arrangement)))
    });

    app.command("load_arrangements", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(workspace::commands::load_arrangements()))
    });

    app.command("delete_arrangement", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(workspace::commands::delete_arrangement(name)))
    });

    app.command("save_session", |payload| {
        let session: workspace::types::Session = serde_json::from_value(payload)
            .map_err(|e| format!("Invalid session: {e}"))?;
        result_to_json(tokio::runtime::Handle::current().block_on(workspace::commands::save_session(session)))
    });

    app.command("load_sessions", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(workspace::commands::load_sessions()))
    });

    app.command("delete_session", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(workspace::commands::delete_session(name)))
    });

    app.command("get_system_info", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(workspace::sysinfo::get_system_info()))
    });

    // -----------------------------------------------------------------------
    // Capture commands
    // -----------------------------------------------------------------------

    app.command("save_screenshot", |payload| {
        let capture_id = get_str(&payload, "capture_id")?.to_string();
        let panel_id = get_str(&payload, "panel_id")?.to_string();
        let base64_data = get_str(&payload, "base64_data")?.to_string();
        let format = get_str(&payload, "format")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(
            capture::commands::save_screenshot(capture_id, panel_id, base64_data, format)
        ))
    });

    app.command("print_panel", |payload| {
        let panel_id = get_str(&payload, "panel_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(capture::commands::print_panel(panel_id)))
    });

    app.command("save_demo", |payload| {
        let demo_json = get_str(&payload, "demo_json")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(capture::commands::save_demo(demo_json)))
    });

    app.command("load_demos", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(capture::commands::load_demos()))
    });

    app.command("delete_demo", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(capture::commands::delete_demo(name)))
    });

    // -----------------------------------------------------------------------
    // Security commands
    // -----------------------------------------------------------------------

    app.command("redact_text", |payload| {
        let text = get_str(&payload, "text")?.to_string();
        let panel_id = get_str(&payload, "panel_id")?.to_string();
        let patterns_json = serde_json::to_string(&payload.get("patterns").cloned().unwrap_or(Value::Array(vec![])))
            .unwrap_or_else(|_| "[]".to_string());
        result_to_json(tokio::runtime::Handle::current().block_on(
            security::commands::redact_text(text, panel_id, patterns_json)
        ))
    });

    app.command("vault_store", |payload| {
        let key = get_str(&payload, "key")?.to_string();
        let value = get_str(&payload, "value")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(security::commands::vault_store(key, value)))
    });

    app.command("vault_retrieve", |payload| {
        let key = get_str(&payload, "key")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(security::commands::vault_retrieve(key)))
    });

    app.command("vault_list", |_payload| {
        result_to_json(tokio::runtime::Handle::current().block_on(security::commands::vault_list()))
    });

    app.command("load_trustfile", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(security::commands::load_trustfile(path)))
    });

    // -----------------------------------------------------------------------
    // Overlay commands (Tor, IPFS, Ethereum)
    // -----------------------------------------------------------------------

    app.command("overlay_status", |_p| { result_to_json(overlay::commands::overlay_status()) });
    app.command("overlay_health", |_p| { result_to_json(overlay::commands::overlay_health()) });
    app.command("overlay_tor_connect", |p| {
        let control_host = get_opt_str(&p, "control_host");
        let control_port = p.get("control_port").and_then(|v| v.as_u64()).map(|n| n as u16);
        let socks_port = p.get("socks_port").and_then(|v| v.as_u64()).map(|n| n as u16);
        let auth_method = p.get("auth_method").and_then(|v| v.as_u64()).map(|n| n as u8);
        let auth_data = get_opt_str(&p, "auth_data");
        result_to_json(overlay::commands::overlay_tor_connect(control_host, control_port, socks_port, auth_method, auth_data))
    });
    app.command("overlay_tor_disconnect", |_p| { result_to_json(overlay::commands::overlay_tor_disconnect()) });
    app.command("overlay_tor_status", |_p| { result_to_json(overlay::commands::overlay_tor_status()) });
    app.command("overlay_tor_create_hidden_service", |p| {
        let port = p.get("port").and_then(|v| v.as_u64()).unwrap_or(80) as u16;
        let target_port = p.get("target_port").and_then(|v| v.as_u64()).unwrap_or(8080) as u16;
        result_to_json(overlay::commands::overlay_tor_create_hidden_service(port, target_port))
    });
    app.command("overlay_tor_destroy_hidden_service", |p| {
        let id = get_str(&p, "service_id")?.to_string();
        result_to_json(overlay::commands::overlay_tor_destroy_hidden_service(id))
    });
    app.command("overlay_tor_list_circuits", |_p| { result_to_json(overlay::commands::overlay_tor_list_circuits()) });
    app.command("overlay_tor_get_circuit", |p| {
        let id = get_str(&p, "circuit_id")?.to_string();
        result_to_json(overlay::commands::overlay_tor_get_circuit(id))
    });
    app.command("overlay_tor_resolve", |p| {
        let hostname = get_str(&p, "hostname")?.to_string();
        result_to_json(overlay::commands::overlay_tor_resolve(hostname))
    });
    app.command("overlay_ipfs_connect", |p| {
        let api_host = get_opt_str(&p, "api_host");
        let api_port = p.get("api_port").and_then(|v| v.as_u64()).map(|n| n as u16);
        let gateway_port = p.get("gateway_port").and_then(|v| v.as_u64()).map(|n| n as u16);
        let repo_path = get_opt_str(&p, "repo_path");
        result_to_json(overlay::commands::overlay_ipfs_connect(api_host, api_port, gateway_port, repo_path))
    });
    app.command("overlay_ipfs_disconnect", |_p| { result_to_json(overlay::commands::overlay_ipfs_disconnect()) });
    app.command("overlay_ipfs_status", |_p| { result_to_json(overlay::commands::overlay_ipfs_status()) });
    app.command("overlay_ipfs_add", |p| {
        let content = get_str(&p, "content")?.to_string();
        let content_type = get_opt_str(&p, "content_type");
        result_to_json(overlay::commands::overlay_ipfs_add(content, content_type))
    });
    app.command("overlay_ipfs_cat", |p| {
        let cid = get_str(&p, "cid")?.to_string();
        result_to_json(overlay::commands::overlay_ipfs_cat(cid))
    });
    app.command("overlay_ipfs_pin", |p| {
        let cid = get_str(&p, "cid")?.to_string();
        result_to_json(overlay::commands::overlay_ipfs_pin(cid))
    });
    app.command("overlay_ipfs_unpin", |p| {
        let cid = get_str(&p, "cid")?.to_string();
        result_to_json(overlay::commands::overlay_ipfs_unpin(cid))
    });
    app.command("overlay_ipfs_dag_get", |p| {
        let cid = get_str(&p, "cid")?.to_string();
        result_to_json(overlay::commands::overlay_ipfs_dag_get(cid))
    });
    app.command("overlay_eth_connect", |p| {
        let rpc_url = get_opt_str(&p, "rpc_url");
        let network = get_opt_str(&p, "network");
        let chain_id = p.get("chain_id").and_then(|v| v.as_u64());
        result_to_json(overlay::commands::overlay_eth_connect(rpc_url, network, chain_id))
    });
    app.command("overlay_eth_disconnect", |_p| { result_to_json(overlay::commands::overlay_eth_disconnect()) });
    app.command("overlay_eth_status", |_p| { result_to_json(overlay::commands::overlay_eth_status()) });
    app.command("overlay_eth_timestamp_proof", |p| {
        let data = get_str(&p, "data")?.to_string();
        result_to_json(overlay::commands::overlay_eth_timestamp_proof(data))
    });
    app.command("overlay_eth_verify_timestamp", |p| {
        let proof = get_str(&p, "proof")?.to_string();
        result_to_json(overlay::commands::overlay_eth_verify_timestamp(proof))
    });

    // -----------------------------------------------------------------------
    // BoJ commands (blocking)
    // -----------------------------------------------------------------------

    app.command("boj_health", |_p| { result_to_json(boj::commands::boj_health()) });
    app.command("boj_list_cartridges", |_p| { result_to_json(boj::commands::boj_list_cartridges()) });
    app.command("boj_get_cartridge", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(boj::commands::boj_get_cartridge(id))
    });
    app.command("boj_load_cartridge", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(boj::commands::boj_load_cartridge(id))
    });
    app.command("boj_unload_cartridge", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(boj::commands::boj_unload_cartridge(id))
    });
    app.command("boj_topology", |_p| { result_to_json(boj::commands::boj_topology()) });
    app.command("boj_invoke", |p| {
        let name = get_str(&p, "name")?.to_string();
        let tool = get_str(&p, "tool")?.to_string();
        let args = get_opt_str(&p, "args");
        result_to_json(boj::commands::boj_invoke(name, tool, args))
    });
    app.command("boj_umoja_status", |_p| { result_to_json(boj::commands::boj_umoja_status()) });

    // -----------------------------------------------------------------------
    // BoJ Live commands (async — dispatched as blocking via tokio block_on)
    // -----------------------------------------------------------------------

    app.command("boj_live_health", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_health())) });
    app.command("boj_live_cartridges", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_cartridges())) });
    app.command("boj_live_invoke", |p| {
        let cartridge = get_str(&p, "cartridge")?.to_string();
        let tool = get_str(&p, "tool")?.to_string();
        let params = get_str(&p, "params")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_invoke(cartridge, tool, params)))
    });
    app.command("boj_live_topology", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_topology())) });
    app.command("boj_live_check", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_check())) });

    // -----------------------------------------------------------------------
    // VeriSimDB Live commands (async)
    // -----------------------------------------------------------------------

    app.command("verisimdb_live_health", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_health())) });
    app.command("verisimdb_live_list_octads", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_list_octads())) });
    app.command("verisimdb_live_query", |p| {
        let query = get_str(&p, "query")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_query(query)))
    });
    app.command("verisimdb_live_get_octad", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_get_octad(id)))
    });

    // -----------------------------------------------------------------------
    // ECHIDNA Live commands (async)
    // -----------------------------------------------------------------------

    app.command("echidna_live_health", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_health())) });
    app.command("echidna_live_recommend_tactics", |p| {
        let obligation = get_str(&p, "obligation")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_recommend_tactics(obligation)))
    });
    app.command("echidna_live_submit_obligation", |p| {
        let obligation = get_str(&p, "obligation")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_submit_obligation(obligation)))
    });
    app.command("echidna_live_get_result", |p| {
        let obligation_id = get_str(&p, "obligation_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_get_result(obligation_id)))
    });
    app.command("echidna_live_stats", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_stats())) });

    // -----------------------------------------------------------------------
    // TypeLL commands
    // -----------------------------------------------------------------------

    app.command("typell_health", |_p| { result_to_json(typell::commands::typell_health()) });
    app.command("typell_check", |p| {
        let expression = get_str(&p, "expression")?.to_string();
        let context = get_opt_str(&p, "context");
        result_to_json(typell::commands::typell_check(expression, context))
    });
    app.command("typell_infer", |p| {
        let expression = get_str(&p, "expression")?.to_string();
        result_to_json(typell::commands::typell_infer(expression))
    });
    app.command("typell_refine", |p| {
        let spec = get_str(&p, "spec")?.to_string();
        let constraints = get_opt_str(&p, "constraints");
        result_to_json(typell::commands::typell_refine(spec, constraints))
    });
    app.command("typell_compute", |p| {
        let term = get_str(&p, "term")?.to_string();
        result_to_json(typell::commands::typell_compute(term))
    });
    app.command("typell_list_signatures", |_p| { result_to_json(typell::commands::typell_list_signatures()) });
    app.command("typell_universes", |_p| { result_to_json(typell::commands::typell_universes()) });

    // -----------------------------------------------------------------------
    // Protocol-Squisher commands
    // -----------------------------------------------------------------------

    app.command("protocol_squisher_check", |_p| {
        let output = std::process::Command::new(protocol_squisher_bin())
            .arg("--version").output()
            .map_err(|e| format!("CLI not found: {}", e))?;
        if output.status.success() {
            let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
            Ok(json!({"available": true, "version": version}))
        } else {
            Err("protocol-squisher CLI not available".to_string())
        }
    });

    app.command("protocol_squisher_analyze", |p| {
        let file_path = get_str(&p, "file_path")?.to_string();
        let output = std::process::Command::new(protocol_squisher_bin())
            .args(["analyze", &file_path, "--format", "json"]).output()
            .map_err(|e| format!("Analysis failed: {}", e))?;
        if output.status.success() {
            result_to_json(Ok(String::from_utf8_lossy(&output.stdout).to_string()))
        } else {
            Err(format!("Analysis error: {}", String::from_utf8_lossy(&output.stderr)))
        }
    });

    app.command("protocol_squisher_compare", |p| {
        let left = get_str(&p, "left_path")?.to_string();
        let right = get_str(&p, "right_path")?.to_string();
        let output = std::process::Command::new(protocol_squisher_bin())
            .args(["compare", &left, &right, "--format", "json"]).output()
            .map_err(|e| format!("Comparison failed: {}", e))?;
        if output.status.success() {
            result_to_json(Ok(String::from_utf8_lossy(&output.stdout).to_string()))
        } else {
            Err(format!("Comparison error: {}", String::from_utf8_lossy(&output.stderr)))
        }
    });

    // -----------------------------------------------------------------------
    // My-Lang commands
    // -----------------------------------------------------------------------

    app.command("mylang_check", |_p| {
        let output = std::process::Command::new(mylang_bin())
            .arg("--version").output()
            .map_err(|e| format!("CLI not found: {}", e))?;
        if output.status.success() {
            let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
            Ok(json!({"available": true, "version": version}))
        } else {
            Err("my-lang CLI not available".to_string())
        }
    });

    app.command("mylang_compile", |p| {
        let source = get_str(&p, "source")?.to_string();
        let dialect = get_str(&p, "dialect")?.to_string();
        let ext = match dialect.to_lowercase().as_str() {
            "solo" => "solo", "duet" => "duet", "ensemble" => "ens", "me" => "me", _ => "solo",
        };
        let tmp_dir = env::temp_dir().join("panll-mylang");
        fs::create_dir_all(&tmp_dir).map_err(|e| format!("Failed to create temp dir: {}", e))?;
        let tmp_file = tmp_dir.join(format!("input.{}", ext));
        fs::write(&tmp_file, &source).map_err(|e| format!("Failed to write source: {}", e))?;
        let start = Instant::now();
        let output = std::process::Command::new(mylang_bin())
            .args(["compile", tmp_file.to_str().unwrap_or("input"), "--format", "json"]).output()
            .map_err(|e| format!("Compilation failed: {}", e))?;
        let elapsed_ms = start.elapsed().as_millis();
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        Ok(json!({
            "success": output.status.success(),
            "output": stdout, "diagnostics": stderr,
            "error_count": 0, "warning_count": 0, "compile_time_ms": elapsed_ms
        }))
    });

    app.command("mylang_repl", |p| {
        let input = get_str(&p, "input")?.to_string();
        let dialect = get_str(&p, "dialect")?.to_string();
        let output = std::process::Command::new(mylang_bin())
            .args(["repl", "--eval", &input, "--dialect", &dialect.to_lowercase()]).output()
            .map_err(|e| format!("REPL eval failed: {}", e))?;
        if output.status.success() {
            Ok(Value::String(String::from_utf8_lossy(&output.stdout).trim().to_string()))
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
            Err(if stderr.is_empty() { "Evaluation error".to_string() } else { stderr })
        }
    });

    app.command("mylang_lsp_connect", |_p| {
        result_to_json(blocking_get(&mylang_lsp_url(), 5).map(|_| {
            json!({"status": "connected", "url": mylang_lsp_url()}).to_string()
        }))
    });

    app.command("mylang_lsp_diagnostics", |p| {
        let file_path = get_str(&p, "file_path")?.to_string();
        let content = get_str(&p, "content")?.to_string();
        let url = format!("{}/diagnostics", mylang_lsp_url());
        let body = json!({
            "jsonrpc": "2.0", "method": "textDocument/didOpen",
            "params": { "textDocument": {
                "uri": format!("file://{}", file_path),
                "languageId": "mylang", "version": 1, "text": content
            }}
        });
        result_to_json(blocking_post(&url, &body, 30))
    });

    // -----------------------------------------------------------------------
    // Clade Scanner
    // -----------------------------------------------------------------------

    app.command("scan_clade_files", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(clade_scanner::commands::scan_clade_files()))
    });

    // -----------------------------------------------------------------------
    // Governance commands
    // -----------------------------------------------------------------------

    app.command("governance_nesy_query", |p| {
        let query = get_str(&p, "query")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(governance::commands::governance_nesy_query(query)))
    });
    app.command("governance_nesy_validate", |p| {
        let adjustment = get_str(&p, "adjustment")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(governance::commands::governance_nesy_validate(adjustment)))
    });
    app.command("governance_nesy_probe", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(governance::commands::governance_nesy_probe()))
    });

    // -----------------------------------------------------------------------
    // Coprocessor commands
    // -----------------------------------------------------------------------

    app.command("query_compute_engine", |p| {
        let engine_id = get_str(&p, "engine_id")?.to_string();
        let operation = get_str(&p, "operation")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::query_compute_engine(engine_id, operation)))
    });
    app.command("discover_compute_devices", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::discover_compute_devices()))
    });
    app.command("coprocessor_dispatch_local", |p| {
        let operation = get_str(&p, "operation")?.to_string();
        let input = get_str(&p, "input")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::coprocessor_dispatch_local(operation, input)))
    });
    app.command("coprocessor_check_ffi", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::coprocessor_check_ffi()))
    });
    app.command("coprocessor_benchmark", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::coprocessor_benchmark()))
    });
    app.command("coprocessor_load_ffi", |p| {
        let lib_path = get_str(&p, "lib_path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::coprocessor_load_ffi(lib_path)))
    });
    app.command("coprocessor_local_resources", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::coprocessor_local_resources()))
    });
    app.command("coprocessor_smart_dispatch", |p| {
        let operation = get_str(&p, "operation")?.to_string();
        let payload_str = get_str(&p, "payload")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(coprocessor::commands::coprocessor_smart_dispatch(operation, payload_str)))
    });

    // -----------------------------------------------------------------------
    // Game Preview commands
    // -----------------------------------------------------------------------

    app.command("game_preview_check_server", |p| {
        let url = get_str(&p, "url")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_check_server(url)))
    });
    app.command("game_preview_control", |p| {
        let command = get_str(&p, "command")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_control(command)))
    });
    app.command("game_preview_record_start", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_record_start(name)))
    });
    app.command("game_preview_record_stop", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_record_stop()))
    });
    app.command("game_preview_screenshot", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_screenshot()))
    });
    app.command("game_preview_stats", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_stats()))
    });
    app.command("game_preview_clips_list", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_clips_list()))
    });
    app.command("game_preview_clip_delete", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(game_preview::commands::game_preview_clip_delete(name)))
    });

    // -----------------------------------------------------------------------
    // Network Topology commands
    // -----------------------------------------------------------------------

    app.command("read_network_topology", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(network_topology::commands::read_network_topology()))
    });
    app.command("read_dns_table", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(network_topology::commands::read_dns_table()))
    });
    app.command("read_packet_flow", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(network_topology::commands::read_packet_flow()))
    });
    app.command("export_topology_svg", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(network_topology::commands::export_topology_svg()))
    });

    // -----------------------------------------------------------------------
    // Level Architect commands
    // -----------------------------------------------------------------------

    app.command("load_level", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(level_architect::commands::load_level(path)))
    });
    app.command("save_level", |p| {
        let path = get_str(&p, "path")?.to_string();
        let data = get_str(&p, "data")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(level_architect::commands::save_level(path, data)))
    });
    app.command("export_level_config", |p| {
        let data = get_str(&p, "data")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(level_architect::commands::export_level_config(data)))
    });
    app.command("browse_level_assets", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(level_architect::commands::browse_level_assets()))
    });
    app.command("validate_level", |p| {
        let data = get_str(&p, "data")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(level_architect::commands::validate_level(data)))
    });

    // -----------------------------------------------------------------------
    // Valence Shell commands
    // -----------------------------------------------------------------------

    app.command("valence_shell_check", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_check()))
    });
    app.command("valence_shell_spawn", |p| {
        let shell = get_str(&p, "shell")?.to_string();
        let cwd = get_str(&p, "cwd")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_spawn(shell, cwd)))
    });
    app.command("valence_shell_input", |p| {
        let session_id = get_opt_str(&p, "session_id");
        let input = get_str(&p, "input")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_input(session_id, input)))
    });
    app.command("valence_shell_record_start", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_record_start(name)))
    });
    app.command("valence_shell_record_stop", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_record_stop()))
    });
    app.command("valence_shell_recordings_list", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_recordings_list()))
    });
    app.command("valence_shell_recording_delete", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_recording_delete(name)))
    });
    app.command("valence_shell_checkpoint_create", |p| {
        let label = get_str(&p, "label")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_checkpoint_create(label)))
    });
    app.command("valence_shell_checkpoint_restore", |p| {
        let id = get_str(&p, "id")?.to_string();
        let session_id = get_opt_str(&p, "session_id");
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_checkpoint_restore(id, session_id)))
    });
    app.command("valence_shell_checkpoints_list", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_checkpoints_list()))
    });
    app.command("valence_shell_screenshot", |p| {
        let session_id = get_opt_str(&p, "session_id");
        let lines = p.get("lines").and_then(|v| v.as_u64()).map(|n| n as usize);
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_screenshot(session_id, lines)))
    });
    app.command("valence_shell_recording_export", |p| {
        let id = get_str(&p, "id")?.to_string();
        let format = get_str(&p, "format")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(valence_shell::commands::valence_shell_recording_export(id, format)))
    });

    // -----------------------------------------------------------------------
    // Multiplayer Monitor commands
    // -----------------------------------------------------------------------

    app.command("multiplayer_connect", |p| {
        let url = get_str(&p, "url")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(multiplayer_monitor::commands::multiplayer_connect(url)))
    });
    app.command("multiplayer_disconnect", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(multiplayer_monitor::commands::multiplayer_disconnect()))
    });
    app.command("multiplayer_read_state", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(multiplayer_monitor::commands::multiplayer_read_state()))
    });
    app.command("multiplayer_read_diffs", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(multiplayer_monitor::commands::multiplayer_read_diffs()))
    });
    app.command("multiplayer_read_ets", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(multiplayer_monitor::commands::multiplayer_read_ets()))
    });
    app.command("multiplayer_reconnection_test", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(multiplayer_monitor::commands::multiplayer_reconnection_test()))
    });

    // -----------------------------------------------------------------------
    // DLC Workshop commands
    // -----------------------------------------------------------------------

    app.command("dlc_load_puzzles", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_load_puzzles()))
    });
    app.command("dlc_save_puzzle", |p| {
        let data = get_str(&p, "data")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_save_puzzle(data)))
    });
    app.command("dlc_run_test", |p| {
        let puzzle_id = get_str(&p, "puzzle_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_run_test(puzzle_id)))
    });
    app.command("dlc_run_all_tests", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_run_all_tests()))
    });
    app.command("dlc_browse_assets", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_browse_assets()))
    });
    app.command("dlc_package", |p| {
        let data = get_str(&p, "data")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_package(data)))
    });
    app.command("dlc_import_puzzle", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_import_puzzle(path)))
    });
    app.command("dlc_export_puzzle", |p| {
        let puzzle_id = get_str(&p, "puzzle_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(dlc_workshop::commands::dlc_export_puzzle(puzzle_id)))
    });

    // -----------------------------------------------------------------------
    // UMS commands
    // -----------------------------------------------------------------------

    app.command("ums_load_projects", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_load_projects()))
    });
    app.command("ums_create_project", |p| {
        let name = get_str(&p, "name")?.to_string();
        let description = get_str(&p, "description")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_create_project(name, description)))
    });
    app.command("ums_open_project", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_open_project(id)))
    });
    app.command("ums_delete_project", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_delete_project(id)))
    });
    app.command("ums_validate_level", |p| {
        let level_id = get_str(&p, "level_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_validate_level(level_id)))
    });
    app.command("ums_load_templates", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_load_templates()))
    });
    app.command("ums_instantiate_template", |p| {
        let template_id = get_str(&p, "template_id")?.to_string();
        let project_name = get_str(&p, "project_name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_instantiate_template(template_id, project_name)))
    });
    app.command("ums_load_assets", |p| {
        let project_id = get_str(&p, "project_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_load_assets(project_id)))
    });
    app.command("ums_import_asset", |p| {
        let project_id = get_str(&p, "project_id")?.to_string();
        let file_path = get_str(&p, "file_path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_import_asset(project_id, file_path)))
    });
    app.command("ums_publish_mod", |p| {
        let project_id = get_str(&p, "project_id")?.to_string();
        let platform = get_str(&p, "platform")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_publish_mod(project_id, platform)))
    });
    app.command("ums_load_api_reference", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(ums::commands::ums_load_api_reference()))
    });

    // -----------------------------------------------------------------------
    // UMS Cartridge commands
    // -----------------------------------------------------------------------

    app.command("ums_cartridge_validate", |p| {
        let level = get_str(&p, "level")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums_cartridge::commands::ums_cartridge_validate(level)))
    });
    app.command("ums_cartridge_load_level", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums_cartridge::commands::ums_cartridge_load_level(name)))
    });
    app.command("ums_cartridge_save_level", |p| {
        let level = get_str(&p, "level")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums_cartridge::commands::ums_cartridge_save_level(level)))
    });
    app.command("ums_cartridge_list_levels", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(ums_cartridge::commands::ums_cartridge_list_levels()))
    });
    app.command("ums_cartridge_export_config", |p| {
        let level = get_str(&p, "level")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(ums_cartridge::commands::ums_cartridge_export_config(level)))
    });

    // -----------------------------------------------------------------------
    // Release Manager commands
    // -----------------------------------------------------------------------

    app.command("release_generate_changelog", |p| {
        let from_version = get_str(&p, "from_version")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(release_manager::commands::release_generate_changelog(from_version)))
    });
    app.command("release_build_artifacts", |p| {
        let version = get_str(&p, "version")?.to_string();
        let platforms = get_str(&p, "platforms")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(release_manager::commands::release_build_artifacts(version, platforms)))
    });
    app.command("release_publish", |p| {
        let version = get_str(&p, "version")?.to_string();
        let channel = get_str(&p, "channel")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(release_manager::commands::release_publish(version, channel)))
    });
    app.command("release_read_history", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(release_manager::commands::release_read_history()))
    });
    app.command("release_bump_version", |p| {
        let bump_type = get_str(&p, "bump_type")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(release_manager::commands::release_bump_version(bump_type)))
    });

    // -----------------------------------------------------------------------
    // Umoja commands
    // -----------------------------------------------------------------------

    app.command("umoja_add_peer", |p| {
        let address = get_str(&p, "address")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(umoja::commands::umoja_add_peer(address)))
    });
    app.command("umoja_disconnect_peer", |p| {
        let id = get_str(&p, "peer_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(umoja::commands::umoja_disconnect_peer(id)))
    });
    app.command("umoja_trigger_gossip", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(umoja::commands::umoja_trigger_gossip()))
    });
    app.command("umoja_sync_catalogue", |p| {
        let node_id = get_str(&p, "node_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(umoja::commands::umoja_sync_catalogue(node_id)))
    });
    app.command("umoja_peer_metrics", |p| {
        let node_id = get_str(&p, "node_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(umoja::commands::umoja_peer_metrics(node_id)))
    });

    // -----------------------------------------------------------------------
    // Observability commands
    // -----------------------------------------------------------------------

    app.command("observe_export_sarif", |p| {
        let report_id = get_str(&p, "report_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(observability::commands::observe_export_sarif(report_id)))
    });
    app.command("observe_export_traces", |p| {
        let batch = get_str(&p, "batch")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(observability::commands::observe_export_traces(batch)))
    });
    app.command("observe_summary", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(observability::commands::observe_summary()))
    });

    // -----------------------------------------------------------------------
    // A2ML commands
    // -----------------------------------------------------------------------

    app.command("a2ml_load_manifest", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(a2ml::commands::a2ml_load_manifest(path))
    });
    app.command("a2ml_validate", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(a2ml::commands::a2ml_validate(path))
    });
    app.command("a2ml_list", |_p| { result_to_json(a2ml::commands::a2ml_list()) });

    // -----------------------------------------------------------------------
    // K9 commands
    // -----------------------------------------------------------------------

    app.command("k9_load_contractile", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(k9::commands::k9_load_contractile(path))
    });
    app.command("k9_validate", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(k9::commands::k9_validate(path))
    });
    app.command("k9_apply_layout", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(k9::commands::k9_apply_layout(name))
    });

    // -----------------------------------------------------------------------
    // Fleet commands
    // -----------------------------------------------------------------------

    app.command("fleet_get_bots", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(fleet::commands::fleet_get_bots()))
    });
    app.command("fleet_get_findings", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(fleet::commands::fleet_get_findings()))
    });
    app.command("fleet_dispatch", |p| {
        let finding_id = get_str(&p, "finding_id")?.to_string();
        let bot_id = get_str(&p, "bot_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(fleet::commands::fleet_dispatch(finding_id, bot_id)))
    });

    // -----------------------------------------------------------------------
    // Hypatia commands
    // -----------------------------------------------------------------------

    app.command("hypatia_get_networks", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(hypatia::commands::hypatia_get_networks()))
    });
    app.command("hypatia_get_scans", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(hypatia::commands::hypatia_get_scans()))
    });
    app.command("hypatia_scan_repo", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(hypatia::commands::hypatia_scan_repo(path)))
    });

    // -----------------------------------------------------------------------
    // Aerie commands
    // -----------------------------------------------------------------------

    app.command("aerie_get_latency", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(aerie::commands::aerie_get_latency()))
    });
    app.command("aerie_speed_test", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(aerie::commands::aerie_speed_test()))
    });

    // -----------------------------------------------------------------------
    // Provenance commands
    // -----------------------------------------------------------------------

    app.command("provenance_analyse_file", |p| {
        let repo_path = get_str(&p, "repo_path")?.to_string();
        let file_path = get_str(&p, "file_path")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(provenance::commands::provenance_analyse_file(repo_path, file_path)))
    });
    app.command("provenance_scan_unsound", |p| {
        let dir = get_str(&p, "dir")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(provenance::commands::provenance_scan_unsound(dir)))
    });

    // -----------------------------------------------------------------------
    // Feedback commands
    // -----------------------------------------------------------------------

    app.command("feedback_save_report", |p| {
        let report_json = get_str(&p, "report_json")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(feedback::commands::feedback_save_report(report_json)))
    });

    // -----------------------------------------------------------------------
    // Script Gist commands
    // -----------------------------------------------------------------------

    app.command("script_gist_save", |p| {
        let gist_json = get_str(&p, "gist_json")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(script_gist::commands::script_gist_save(gist_json)))
    });
    app.command("script_gist_execute", |p| {
        let gist_json = get_str(&p, "gist_json")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(script_gist::commands::script_gist_execute(gist_json)))
    });
    app.command("script_gist_restore_snapshot", |p| {
        let snapshot_json = get_str(&p, "snapshot_json")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(script_gist::commands::script_gist_restore_snapshot(snapshot_json)))
    });
    app.command("script_gist_list", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(script_gist::commands::script_gist_list()))
    });

    // -----------------------------------------------------------------------
    // Wiring Inspector commands
    // -----------------------------------------------------------------------

    app.command("wiring_inspector_verify", |_p| {
        result_to_json(tokio::runtime::Handle::current().block_on(wiring_inspector::commands::wiring_inspector_verify()))
    });
    app.command("wiring_inspector_verify_panel", |p| {
        let panel_id = get_str(&p, "panel_id")?.to_string();
        result_to_json(tokio::runtime::Handle::current().block_on(wiring_inspector::commands::wiring_inspector_verify_panel(panel_id)))
    });

    // -----------------------------------------------------------------------
    // LLM Coding commands
    // -----------------------------------------------------------------------

    app.command("llm_coding_list_sessions", |_p| { result_to_json(llm_coding::commands::llm_coding_list_sessions()) });
    app.command("llm_coding_spawn", |p| {
        let request: llm_coding::types::SpawnRequest = serde_json::from_value(p)
            .map_err(|e| format!("Invalid spawn request: {e}"))?;
        result_to_json(llm_coding::commands::llm_coding_spawn(request))
    });
    app.command("llm_coding_freeze", |p| {
        let id = get_str(&p, "session_id")?.to_string();
        result_to_json(llm_coding::commands::llm_coding_freeze(id))
    });
    app.command("llm_coding_thaw", |p| {
        let id = get_str(&p, "session_id")?.to_string();
        result_to_json(llm_coding::commands::llm_coding_thaw(id))
    });
    app.command("llm_coding_kill", |p| {
        let id = get_str(&p, "session_id")?.to_string();
        result_to_json(llm_coding::commands::llm_coding_kill(id))
    });
    app.command("llm_coding_system_resources", |_p| { result_to_json(llm_coding::commands::llm_coding_system_resources()) });
    app.command("llm_coding_list_locks", |_p| { result_to_json(llm_coding::commands::llm_coding_list_locks()) });
    app.command("llm_coding_list_messages", |_p| {
        result_to_json(llm_coding::commands::llm_coding_list_messages())
    });

    // -----------------------------------------------------------------------
    // Startup — groove discovery + navigate to frontend
    // -----------------------------------------------------------------------

    // Spawn the groove discovery server on port 8000 (same as old Tauri setup).
    groove::spawn();

    // Navigate to the bundled frontend.
    // In development, this would be the dev server at http://localhost:8000.
    // In production, the frontend HTML is loaded directly.
    app.navigate("http://localhost:8000")?;

    // Run the webview event loop (blocks until window is closed).
    app.run();

    Ok(())
}
