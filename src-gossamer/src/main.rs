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

    app.command("cloudguard_verify_token", |payload| {
        result_to_json(cloudguard::commands::cloudguard_verify_token(
            get_str(&payload, "token")?.to_string(),
        ))
    });

    app.command("cloudguard_list_zones", |payload| {
        result_to_json(cloudguard::commands::cloudguard_list_zones(
            get_str(&payload, "token")?.to_string(),
        ))
    });

    app.command("cloudguard_get_zone", |payload| {
        result_to_json(cloudguard::commands::cloudguard_get_zone(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_get_settings", |payload| {
        result_to_json(cloudguard::commands::cloudguard_get_settings(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_update_setting", |payload| {
        result_to_json(cloudguard::commands::cloudguard_update_setting(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
            get_str(&payload, "setting_id")?.to_string(),
            payload.get("value").cloned().unwrap_or(Value::Null),
        ))
    });

    app.command("cloudguard_update_settings_batch", |payload| {
        result_to_json(cloudguard::commands::cloudguard_update_settings_batch(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
            payload.get("settings").cloned().unwrap_or(Value::Null),
        ))
    });

    app.command("cloudguard_list_dns_records", |payload| {
        result_to_json(cloudguard::commands::cloudguard_list_dns_records(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_create_dns_record", |payload| {
        result_to_json(cloudguard::commands::cloudguard_create_dns_record(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
            payload.get("record").cloned().unwrap_or(Value::Null),
        ))
    });

    app.command("cloudguard_update_dns_record", |payload| {
        result_to_json(cloudguard::commands::cloudguard_update_dns_record(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
            get_str(&payload, "record_id")?.to_string(),
            payload.get("record").cloned().unwrap_or(Value::Null),
        ))
    });

    app.command("cloudguard_delete_dns_record", |payload| {
        result_to_json(cloudguard::commands::cloudguard_delete_dns_record(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
            get_str(&payload, "record_id")?.to_string(),
        ))
    });

    app.command("cloudguard_get_dnssec", |payload| {
        result_to_json(cloudguard::commands::cloudguard_get_dnssec(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_enable_dnssec", |payload| {
        result_to_json(cloudguard::commands::cloudguard_enable_dnssec(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_harden_zone", |payload| {
        result_to_json(cloudguard::commands::cloudguard_harden_zone(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    app.command("cloudguard_download_config", |payload| {
        result_to_json(cloudguard::commands::cloudguard_download_config(
            get_str(&payload, "token")?.to_string(),
            get_str(&payload, "zone_id")?.to_string(),
        ))
    });

    // -----------------------------------------------------------------------
    // Farm commands
    // -----------------------------------------------------------------------

    app.command("farm_list_repos", |_payload| {
        result_to_json(farm::commands::farm_list_repos())
    });

    app.command("farm_get_repo", |payload| {
        result_to_json(farm::commands::farm_get_repo(get_str(&payload, "name")?.to_string()))
    });

    app.command("farm_get_stats", |_payload| {
        result_to_json(farm::commands::farm_get_stats())
    });

    // -----------------------------------------------------------------------
    // VM Inspector commands
    // -----------------------------------------------------------------------

    app.command("vm_inspector_read_state", |_payload| {
        result_to_json(vm_inspector::commands::vm_inspector_read_state())
    });

    app.command("vm_inspector_step_forward", |_payload| {
        result_to_json(vm_inspector::commands::vm_inspector_step_forward())
    });

    app.command("vm_inspector_step_backward", |_payload| {
        result_to_json(vm_inspector::commands::vm_inspector_step_backward())
    });

    app.command("vm_inspector_run", |_payload| {
        result_to_json(vm_inspector::commands::vm_inspector_run())
    });

    app.command("vm_inspector_load_program", |payload| {
        let program = get_str(&payload, "program")?.to_string();
        result_to_json(vm_inspector::commands::vm_inspector_load_program(program))
    });

    app.command("vm_inspector_export_snapshot", |_payload| {
        result_to_json(vm_inspector::commands::vm_inspector_export_snapshot())
    });

    app.command("vm_inspector_read_file", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(vm_inspector::commands::vm_inspector_read_file(path))
    });

    // -----------------------------------------------------------------------
    // Plaza commands
    // -----------------------------------------------------------------------

    app.command("plaza_scan_repo", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(plaza::commands::plaza_scan_repo(path))
    });

    app.command("plaza_adoption_stats", |_payload| {
        result_to_json(plaza::commands::plaza_adoption_stats())
    });

    app.command("plaza_check_compatibility", |payload| {
        let license = get_str(&payload, "license")?.to_string();
        result_to_json(plaza::commands::plaza_check_compatibility(license))
    });

    // -----------------------------------------------------------------------
    // Minter commands
    // -----------------------------------------------------------------------

    app.command("minter_validate_name", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(minter::commands::minter_validate_name(name))
    });

    app.command("minter_mint_panel", |payload| {
        result_to_json(minter::commands::minter_mint_panel(payload))
    });

    // -----------------------------------------------------------------------
    // VoiceTag commands
    // -----------------------------------------------------------------------

    app.command("voicetag_load", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(voicetag::commands::voicetag_load(path))
    });

    app.command("voicetag_save", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        let data = get_str(&payload, "data")?.to_string();
        result_to_json(voicetag::commands::voicetag_save(path, data))
    });

    app.command("voicetag_delete", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(voicetag::commands::voicetag_delete(path))
    });

    app.command("voicetag_scan", |payload| {
        let dir = get_str(&payload, "dir")?.to_string();
        result_to_json(voicetag::commands::voicetag_scan(dir))
    });

    // -----------------------------------------------------------------------
    // Watcher commands
    // -----------------------------------------------------------------------

    app.command("watcher_start", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        let app_handle = compat::AppHandle::new();
        result_to_json(watcher::commands::watcher_start(app_handle, path))
    });

    app.command("watcher_stop", |_payload| {
        result_to_json(watcher::commands::watcher_stop())
    });

    app.command("watcher_add_path", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(watcher::commands::watcher_add_path(path))
    });

    app.command("watcher_remove_path", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(watcher::commands::watcher_remove_path(path))
    });

    app.command("watcher_status", |_payload| {
        result_to_json(watcher::commands::watcher_status())
    });

    // -----------------------------------------------------------------------
    // AI commands
    // -----------------------------------------------------------------------

    app.command("ai_send_message", |payload| {
        result_to_json(ai::commands::ai_send_message(payload))
    });

    app.command("ai_check_provider", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        result_to_json(ai::commands::ai_check_provider(provider_id))
    });

    app.command("ai_set_model", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        let model = get_str(&payload, "model")?.to_string();
        result_to_json(ai::commands::ai_set_model(provider_id, model))
    });

    app.command("ai_set_priority", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        let priority = get_u64(&payload, "priority")? as u32;
        result_to_json(ai::commands::ai_set_priority(provider_id, priority))
    });

    app.command("ai_toggle_provider", |payload| {
        let provider_id = get_str(&payload, "provider_id")?.to_string();
        let enabled = payload.get("enabled").and_then(Value::as_bool).unwrap_or(true);
        result_to_json(ai::commands::ai_toggle_provider(provider_id, enabled))
    });

    app.command("ai_clear_history", |_payload| {
        result_to_json(ai::commands::ai_clear_history())
    });

    app.command("ai_build_context", |payload| {
        result_to_json(ai::commands::ai_build_context(payload))
    });

    app.command("ai_get_state", |_payload| {
        result_to_json(ai::commands::ai_get_state())
    });

    // Note: ai_send_message_streaming requires AppHandle for event emission.
    // The compat shim provides AppHandle but the function is async.
    // Registered as a sync command that spawns the async work internally.
    app.command("ai_send_message_streaming", |payload| {
        let request: ai::commands::StreamingRequest = serde_json::from_value(payload)
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
        result_to_json(repoloader::commands::repoloader_scan(path))
    });

    app.command("repoloader_save_panels", |payload| {
        result_to_json(repoloader::commands::repoloader_save_panels(payload))
    });

    app.command("repoloader_list_recent", |_payload| {
        result_to_json(repoloader::commands::repoloader_list_recent())
    });

    app.command("repoloader_search_farm", |payload| {
        let query = get_str(&payload, "query")?.to_string();
        result_to_json(repoloader::commands::repoloader_search_farm(query))
    });

    // -----------------------------------------------------------------------
    // Workspace commands
    // -----------------------------------------------------------------------

    app.command("save_arrangement", |payload| {
        result_to_json(workspace::commands::save_arrangement(payload))
    });

    app.command("load_arrangements", |_payload| {
        result_to_json(workspace::commands::load_arrangements())
    });

    app.command("delete_arrangement", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(workspace::commands::delete_arrangement(name))
    });

    app.command("save_session", |payload| {
        result_to_json(workspace::commands::save_session(payload))
    });

    app.command("load_sessions", |_payload| {
        result_to_json(workspace::commands::load_sessions())
    });

    app.command("delete_session", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(workspace::commands::delete_session(name))
    });

    app.command("get_system_info", |_payload| {
        result_to_json(workspace::sysinfo::get_system_info())
    });

    // -----------------------------------------------------------------------
    // Capture commands
    // -----------------------------------------------------------------------

    app.command("save_screenshot", |payload| {
        result_to_json(capture::commands::save_screenshot(payload))
    });

    app.command("print_panel", |payload| {
        result_to_json(capture::commands::print_panel(payload))
    });

    app.command("save_demo", |payload| {
        result_to_json(capture::commands::save_demo(payload))
    });

    app.command("load_demos", |_payload| {
        result_to_json(capture::commands::load_demos())
    });

    app.command("delete_demo", |payload| {
        let name = get_str(&payload, "name")?.to_string();
        result_to_json(capture::commands::delete_demo(name))
    });

    // -----------------------------------------------------------------------
    // Security commands
    // -----------------------------------------------------------------------

    app.command("redact_text", |payload| {
        let text = get_str(&payload, "text")?.to_string();
        result_to_json(security::commands::redact_text(text))
    });

    app.command("vault_store", |payload| {
        let key = get_str(&payload, "key")?.to_string();
        let value = get_str(&payload, "value")?.to_string();
        result_to_json(security::commands::vault_store(key, value))
    });

    app.command("vault_retrieve", |payload| {
        let key = get_str(&payload, "key")?.to_string();
        result_to_json(security::commands::vault_retrieve(key))
    });

    app.command("vault_list", |_payload| {
        result_to_json(security::commands::vault_list())
    });

    app.command("load_trustfile", |payload| {
        let path = get_str(&payload, "path")?.to_string();
        result_to_json(security::commands::load_trustfile(path))
    });

    // -----------------------------------------------------------------------
    // Overlay commands (Tor, IPFS, Ethereum)
    // -----------------------------------------------------------------------

    app.command("overlay_status", |_p| { result_to_json(overlay::commands::overlay_status()) });
    app.command("overlay_health", |_p| { result_to_json(overlay::commands::overlay_health()) });
    app.command("overlay_tor_connect", |_p| { result_to_json(overlay::commands::overlay_tor_connect()) });
    app.command("overlay_tor_disconnect", |_p| { result_to_json(overlay::commands::overlay_tor_disconnect()) });
    app.command("overlay_tor_status", |_p| { result_to_json(overlay::commands::overlay_tor_status()) });
    app.command("overlay_tor_create_hidden_service", |p| { result_to_json(overlay::commands::overlay_tor_create_hidden_service(p)) });
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
    app.command("overlay_ipfs_connect", |_p| { result_to_json(overlay::commands::overlay_ipfs_connect()) });
    app.command("overlay_ipfs_disconnect", |_p| { result_to_json(overlay::commands::overlay_ipfs_disconnect()) });
    app.command("overlay_ipfs_status", |_p| { result_to_json(overlay::commands::overlay_ipfs_status()) });
    app.command("overlay_ipfs_add", |p| {
        let content = get_str(&p, "content")?.to_string();
        result_to_json(overlay::commands::overlay_ipfs_add(content))
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
    app.command("overlay_eth_connect", |_p| { result_to_json(overlay::commands::overlay_eth_connect()) });
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
    app.command("boj_invoke", |p| { result_to_json(boj::commands::boj_invoke(p)) });
    app.command("boj_umoja_status", |_p| { result_to_json(boj::commands::boj_umoja_status()) });

    // -----------------------------------------------------------------------
    // BoJ Live commands (async — dispatched as blocking via tokio block_on)
    // -----------------------------------------------------------------------

    app.command("boj_live_health", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_health())) });
    app.command("boj_live_cartridges", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_cartridges())) });
    app.command("boj_live_invoke", |p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_invoke(p))) });
    app.command("boj_live_topology", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_topology())) });
    app.command("boj_live_check", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(boj_live::boj_live_check())) });

    // -----------------------------------------------------------------------
    // VeriSimDB Live commands (async)
    // -----------------------------------------------------------------------

    app.command("verisimdb_live_health", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_health())) });
    app.command("verisimdb_live_list_octads", |p| { result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_list_octads(p))) });
    app.command("verisimdb_live_query", |p| { result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_query(p))) });
    app.command("verisimdb_live_get_octad", |p| { result_to_json(tokio::runtime::Handle::current().block_on(verisimdb_live::verisimdb_live_get_octad(p))) });

    // -----------------------------------------------------------------------
    // ECHIDNA Live commands (async)
    // -----------------------------------------------------------------------

    app.command("echidna_live_health", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_health())) });
    app.command("echidna_live_recommend_tactics", |p| { result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_recommend_tactics(p))) });
    app.command("echidna_live_submit_obligation", |p| { result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_submit_obligation(p))) });
    app.command("echidna_live_get_result", |p| { result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_get_result(p))) });
    app.command("echidna_live_stats", |_p| { result_to_json(tokio::runtime::Handle::current().block_on(echidna_live::echidna_live_stats())) });

    // -----------------------------------------------------------------------
    // TypeLL commands
    // -----------------------------------------------------------------------

    app.command("typell_health", |_p| { result_to_json(typell::commands::typell_health()) });
    app.command("typell_check", |p| { result_to_json(typell::commands::typell_check(p)) });
    app.command("typell_infer", |p| { result_to_json(typell::commands::typell_infer(p)) });
    app.command("typell_refine", |p| { result_to_json(typell::commands::typell_refine(p)) });
    app.command("typell_compute", |p| { result_to_json(typell::commands::typell_compute(p)) });
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

    app.command("scan_clade_files", |p| {
        let dir = get_str(&p, "dir")?.to_string();
        result_to_json(clade_scanner::commands::scan_clade_files(dir))
    });

    // -----------------------------------------------------------------------
    // Governance commands
    // -----------------------------------------------------------------------

    app.command("governance_nesy_query", |p| { result_to_json(governance::commands::governance_nesy_query(p)) });
    app.command("governance_nesy_validate", |p| { result_to_json(governance::commands::governance_nesy_validate(p)) });
    app.command("governance_nesy_probe", |_p| { result_to_json(governance::commands::governance_nesy_probe()) });

    // -----------------------------------------------------------------------
    // Coprocessor commands
    // -----------------------------------------------------------------------

    app.command("query_compute_engine", |p| { result_to_json(coprocessor::commands::query_compute_engine(p)) });
    app.command("discover_compute_devices", |_p| { result_to_json(coprocessor::commands::discover_compute_devices()) });
    app.command("coprocessor_dispatch_local", |p| { result_to_json(coprocessor::commands::coprocessor_dispatch_local(p)) });
    app.command("coprocessor_check_ffi", |p| { result_to_json(coprocessor::commands::coprocessor_check_ffi(p)) });
    app.command("coprocessor_benchmark", |p| { result_to_json(coprocessor::commands::coprocessor_benchmark(p)) });
    app.command("coprocessor_load_ffi", |p| { result_to_json(coprocessor::commands::coprocessor_load_ffi(p)) });
    app.command("coprocessor_local_resources", |_p| { result_to_json(coprocessor::commands::coprocessor_local_resources()) });
    app.command("coprocessor_smart_dispatch", |p| { result_to_json(coprocessor::commands::coprocessor_smart_dispatch(p)) });

    // -----------------------------------------------------------------------
    // Game Preview commands
    // -----------------------------------------------------------------------

    app.command("game_preview_check_server", |_p| { result_to_json(game_preview::commands::game_preview_check_server()) });
    app.command("game_preview_control", |p| { result_to_json(game_preview::commands::game_preview_control(p)) });
    app.command("game_preview_record_start", |p| { result_to_json(game_preview::commands::game_preview_record_start(p)) });
    app.command("game_preview_record_stop", |_p| { result_to_json(game_preview::commands::game_preview_record_stop()) });
    app.command("game_preview_screenshot", |_p| { result_to_json(game_preview::commands::game_preview_screenshot()) });
    app.command("game_preview_stats", |_p| { result_to_json(game_preview::commands::game_preview_stats()) });
    app.command("game_preview_clips_list", |_p| { result_to_json(game_preview::commands::game_preview_clips_list()) });
    app.command("game_preview_clip_delete", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(game_preview::commands::game_preview_clip_delete(name))
    });

    // -----------------------------------------------------------------------
    // Network Topology commands
    // -----------------------------------------------------------------------

    app.command("read_network_topology", |p| { result_to_json(network_topology::commands::read_network_topology(p)) });
    app.command("read_dns_table", |p| { result_to_json(network_topology::commands::read_dns_table(p)) });
    app.command("read_packet_flow", |p| { result_to_json(network_topology::commands::read_packet_flow(p)) });
    app.command("export_topology_svg", |p| { result_to_json(network_topology::commands::export_topology_svg(p)) });

    // -----------------------------------------------------------------------
    // Level Architect commands
    // -----------------------------------------------------------------------

    app.command("load_level", |p| { result_to_json(level_architect::commands::load_level(p)) });
    app.command("save_level", |p| { result_to_json(level_architect::commands::save_level(p)) });
    app.command("export_level_config", |p| { result_to_json(level_architect::commands::export_level_config(p)) });
    app.command("browse_level_assets", |p| { result_to_json(level_architect::commands::browse_level_assets(p)) });
    app.command("validate_level", |p| { result_to_json(level_architect::commands::validate_level(p)) });

    // -----------------------------------------------------------------------
    // Valence Shell commands
    // -----------------------------------------------------------------------

    app.command("valence_shell_check", |_p| { result_to_json(valence_shell::commands::valence_shell_check()) });
    app.command("valence_shell_spawn", |p| { result_to_json(valence_shell::commands::valence_shell_spawn(p)) });
    app.command("valence_shell_input", |p| { result_to_json(valence_shell::commands::valence_shell_input(p)) });
    app.command("valence_shell_record_start", |p| { result_to_json(valence_shell::commands::valence_shell_record_start(p)) });
    app.command("valence_shell_record_stop", |p| { result_to_json(valence_shell::commands::valence_shell_record_stop(p)) });
    app.command("valence_shell_recordings_list", |_p| { result_to_json(valence_shell::commands::valence_shell_recordings_list()) });
    app.command("valence_shell_recording_delete", |p| {
        let name = get_str(&p, "name")?.to_string();
        result_to_json(valence_shell::commands::valence_shell_recording_delete(name))
    });
    app.command("valence_shell_checkpoint_create", |p| { result_to_json(valence_shell::commands::valence_shell_checkpoint_create(p)) });
    app.command("valence_shell_checkpoint_restore", |p| { result_to_json(valence_shell::commands::valence_shell_checkpoint_restore(p)) });
    app.command("valence_shell_checkpoints_list", |p| { result_to_json(valence_shell::commands::valence_shell_checkpoints_list(p)) });
    app.command("valence_shell_screenshot", |p| { result_to_json(valence_shell::commands::valence_shell_screenshot(p)) });
    app.command("valence_shell_recording_export", |p| { result_to_json(valence_shell::commands::valence_shell_recording_export(p)) });

    // -----------------------------------------------------------------------
    // Multiplayer Monitor commands
    // -----------------------------------------------------------------------

    app.command("multiplayer_connect", |p| { result_to_json(multiplayer_monitor::commands::multiplayer_connect(p)) });
    app.command("multiplayer_disconnect", |_p| { result_to_json(multiplayer_monitor::commands::multiplayer_disconnect()) });
    app.command("multiplayer_read_state", |_p| { result_to_json(multiplayer_monitor::commands::multiplayer_read_state()) });
    app.command("multiplayer_read_diffs", |_p| { result_to_json(multiplayer_monitor::commands::multiplayer_read_diffs()) });
    app.command("multiplayer_read_ets", |_p| { result_to_json(multiplayer_monitor::commands::multiplayer_read_ets()) });
    app.command("multiplayer_reconnection_test", |p| { result_to_json(multiplayer_monitor::commands::multiplayer_reconnection_test(p)) });

    // -----------------------------------------------------------------------
    // DLC Workshop commands
    // -----------------------------------------------------------------------

    app.command("dlc_load_puzzles", |p| { result_to_json(dlc_workshop::commands::dlc_load_puzzles(p)) });
    app.command("dlc_save_puzzle", |p| { result_to_json(dlc_workshop::commands::dlc_save_puzzle(p)) });
    app.command("dlc_run_test", |p| { result_to_json(dlc_workshop::commands::dlc_run_test(p)) });
    app.command("dlc_run_all_tests", |p| { result_to_json(dlc_workshop::commands::dlc_run_all_tests(p)) });
    app.command("dlc_browse_assets", |p| { result_to_json(dlc_workshop::commands::dlc_browse_assets(p)) });
    app.command("dlc_package", |p| { result_to_json(dlc_workshop::commands::dlc_package(p)) });
    app.command("dlc_import_puzzle", |p| { result_to_json(dlc_workshop::commands::dlc_import_puzzle(p)) });
    app.command("dlc_export_puzzle", |p| { result_to_json(dlc_workshop::commands::dlc_export_puzzle(p)) });

    // -----------------------------------------------------------------------
    // UMS commands
    // -----------------------------------------------------------------------

    app.command("ums_load_projects", |_p| { result_to_json(ums::commands::ums_load_projects()) });
    app.command("ums_create_project", |p| { result_to_json(ums::commands::ums_create_project(p)) });
    app.command("ums_open_project", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(ums::commands::ums_open_project(id))
    });
    app.command("ums_delete_project", |p| {
        let id = get_str(&p, "id")?.to_string();
        result_to_json(ums::commands::ums_delete_project(id))
    });
    app.command("ums_validate_level", |p| { result_to_json(ums::commands::ums_validate_level(p)) });
    app.command("ums_load_templates", |_p| { result_to_json(ums::commands::ums_load_templates()) });
    app.command("ums_instantiate_template", |p| { result_to_json(ums::commands::ums_instantiate_template(p)) });
    app.command("ums_load_assets", |p| { result_to_json(ums::commands::ums_load_assets(p)) });
    app.command("ums_import_asset", |p| { result_to_json(ums::commands::ums_import_asset(p)) });
    app.command("ums_publish_mod", |p| { result_to_json(ums::commands::ums_publish_mod(p)) });
    app.command("ums_load_api_reference", |_p| { result_to_json(ums::commands::ums_load_api_reference()) });

    // -----------------------------------------------------------------------
    // UMS Cartridge commands
    // -----------------------------------------------------------------------

    app.command("ums_cartridge_validate", |p| { result_to_json(ums_cartridge::commands::ums_cartridge_validate(p)) });
    app.command("ums_cartridge_load_level", |p| { result_to_json(ums_cartridge::commands::ums_cartridge_load_level(p)) });
    app.command("ums_cartridge_save_level", |p| { result_to_json(ums_cartridge::commands::ums_cartridge_save_level(p)) });
    app.command("ums_cartridge_list_levels", |p| { result_to_json(ums_cartridge::commands::ums_cartridge_list_levels(p)) });
    app.command("ums_cartridge_export_config", |p| { result_to_json(ums_cartridge::commands::ums_cartridge_export_config(p)) });

    // -----------------------------------------------------------------------
    // Release Manager commands
    // -----------------------------------------------------------------------

    app.command("release_generate_changelog", |p| { result_to_json(release_manager::commands::release_generate_changelog(p)) });
    app.command("release_build_artifacts", |p| { result_to_json(release_manager::commands::release_build_artifacts(p)) });
    app.command("release_publish", |p| { result_to_json(release_manager::commands::release_publish(p)) });
    app.command("release_read_history", |_p| { result_to_json(release_manager::commands::release_read_history()) });
    app.command("release_bump_version", |p| { result_to_json(release_manager::commands::release_bump_version(p)) });

    // -----------------------------------------------------------------------
    // Umoja commands
    // -----------------------------------------------------------------------

    app.command("umoja_add_peer", |p| { result_to_json(umoja::commands::umoja_add_peer(p)) });
    app.command("umoja_disconnect_peer", |p| {
        let id = get_str(&p, "peer_id")?.to_string();
        result_to_json(umoja::commands::umoja_disconnect_peer(id))
    });
    app.command("umoja_trigger_gossip", |_p| { result_to_json(umoja::commands::umoja_trigger_gossip()) });
    app.command("umoja_sync_catalogue", |_p| { result_to_json(umoja::commands::umoja_sync_catalogue()) });
    app.command("umoja_peer_metrics", |_p| { result_to_json(umoja::commands::umoja_peer_metrics()) });

    // -----------------------------------------------------------------------
    // Observability commands
    // -----------------------------------------------------------------------

    app.command("observe_export_sarif", |p| { result_to_json(observability::commands::observe_export_sarif(p)) });
    app.command("observe_export_traces", |p| { result_to_json(observability::commands::observe_export_traces(p)) });
    app.command("observe_summary", |_p| { result_to_json(observability::commands::observe_summary()) });

    // -----------------------------------------------------------------------
    // A2ML commands
    // -----------------------------------------------------------------------

    app.command("a2ml_load_manifest", |p| { result_to_json(a2ml::commands::a2ml_load_manifest(p)) });
    app.command("a2ml_validate", |p| { result_to_json(a2ml::commands::a2ml_validate(p)) });
    app.command("a2ml_list", |p| { result_to_json(a2ml::commands::a2ml_list(p)) });

    // -----------------------------------------------------------------------
    // K9 commands
    // -----------------------------------------------------------------------

    app.command("k9_load_contractile", |p| { result_to_json(k9::commands::k9_load_contractile(p)) });
    app.command("k9_validate", |p| { result_to_json(k9::commands::k9_validate(p)) });
    app.command("k9_apply_layout", |p| { result_to_json(k9::commands::k9_apply_layout(p)) });

    // -----------------------------------------------------------------------
    // Fleet commands
    // -----------------------------------------------------------------------

    app.command("fleet_get_bots", |_p| { result_to_json(fleet::commands::fleet_get_bots()) });
    app.command("fleet_get_findings", |p| { result_to_json(fleet::commands::fleet_get_findings(p)) });
    app.command("fleet_dispatch", |p| { result_to_json(fleet::commands::fleet_dispatch(p)) });

    // -----------------------------------------------------------------------
    // Hypatia commands
    // -----------------------------------------------------------------------

    app.command("hypatia_get_networks", |_p| { result_to_json(hypatia::commands::hypatia_get_networks()) });
    app.command("hypatia_get_scans", |_p| { result_to_json(hypatia::commands::hypatia_get_scans()) });
    app.command("hypatia_scan_repo", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(hypatia::commands::hypatia_scan_repo(path))
    });

    // -----------------------------------------------------------------------
    // Aerie commands
    // -----------------------------------------------------------------------

    app.command("aerie_get_latency", |p| { result_to_json(aerie::commands::aerie_get_latency(p)) });
    app.command("aerie_speed_test", |_p| { result_to_json(aerie::commands::aerie_speed_test()) });

    // -----------------------------------------------------------------------
    // Provenance commands
    // -----------------------------------------------------------------------

    app.command("provenance_analyse_file", |p| {
        let path = get_str(&p, "path")?.to_string();
        result_to_json(provenance::commands::provenance_analyse_file(path))
    });
    app.command("provenance_scan_unsound", |p| {
        let dir = get_str(&p, "dir")?.to_string();
        result_to_json(provenance::commands::provenance_scan_unsound(dir))
    });

    // -----------------------------------------------------------------------
    // Feedback commands
    // -----------------------------------------------------------------------

    app.command("feedback_save_report", |p| { result_to_json(feedback::commands::feedback_save_report(p)) });

    // -----------------------------------------------------------------------
    // Script Gist commands
    // -----------------------------------------------------------------------

    app.command("script_gist_save", |p| { result_to_json(script_gist::commands::script_gist_save(p)) });
    app.command("script_gist_execute", |p| { result_to_json(script_gist::commands::script_gist_execute(p)) });
    app.command("script_gist_restore_snapshot", |p| { result_to_json(script_gist::commands::script_gist_restore_snapshot(p)) });
    app.command("script_gist_list", |_p| { result_to_json(script_gist::commands::script_gist_list()) });

    // -----------------------------------------------------------------------
    // Wiring Inspector commands
    // -----------------------------------------------------------------------

    app.command("wiring_inspector_verify", |p| { result_to_json(wiring_inspector::commands::wiring_inspector_verify(p)) });
    app.command("wiring_inspector_verify_panel", |p| { result_to_json(wiring_inspector::commands::wiring_inspector_verify_panel(p)) });

    // -----------------------------------------------------------------------
    // LLM Coding commands
    // -----------------------------------------------------------------------

    app.command("llm_coding_list_sessions", |_p| { result_to_json(llm_coding::commands::llm_coding_list_sessions()) });
    app.command("llm_coding_spawn", |p| { result_to_json(llm_coding::commands::llm_coding_spawn(p)) });
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
    app.command("llm_coding_list_messages", |p| {
        let id = get_str(&p, "session_id")?.to_string();
        result_to_json(llm_coding::commands::llm_coding_list_messages(id))
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
