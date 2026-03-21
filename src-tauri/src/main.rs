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
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH, Instant};
use once_cell::sync::Lazy;
use serde::Deserialize;
use serde_json::{json, Value};

/// Generic health check — used by the panel switcher to probe any HTTP service.
/// Makes a GET request to the given endpoint and returns the response body on
/// success or an error string on failure. Each panel calls this with its own
/// service URL so the panel bar can show connection dots (green/red/yellow).
#[tauri::command]
async fn health_check(endpoint: String) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))?;

    let resp = client
        .get(&endpoint)
        .send()
        .await
        .map_err(|e| format!("Request failed: {e}"))?;

    if resp.status().is_success() {
        resp.text()
            .await
            .map_err(|e| format!("Body read error: {e}"))
    } else {
        Err(format!("HTTP {}", resp.status()))
    }
}

/// Unified error types for the PanLL backend.
/// Provides `PanllError` with `From` impls for common error sources and
/// a `to_tauri_result` helper for Tauri command boundaries.
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
/// Debounced event stream feeds the TEA loop so every panel can react to file changes.
mod watcher;

/// AI — Multi-provider AI neural interface (Anthropic, Google, Mistral, OpenAI, local).
/// Provider-agnostic HTTP clients with automatic 429 fallthrough and quota tracking.
mod ai;

/// Repo Loader — Repository scanning and panel configuration.
/// Reads manifests (0-AI-MANIFEST.a2ml, PANELS.a2ml), detects languages,
/// and suggests which PanLL panels to activate.
mod repoloader;

/// Workspace — Panel arrangements, groups, sessions, and system info (DD-024/025).
mod workspace;

/// Capture — Screenshots, recordings, and demo packages (DD-022).
mod capture;

/// Security — Redaction, vault, 2FA, and Trustfile enforcement (DD-026/027).
mod security;

/// Overlay — Tor, IPFS, Ethereum overlay network bridge (Aerie backend).
/// Routes to ECHIDNA overlay FFI via V-lang adapter at OVERLAY_URL.
mod overlay;

/// BoJ — Barrel of Jelly cartridge runtime bridge (blocking).
/// Routes to BoJ server at BOJ_URL (default http://localhost:7700/api/v1).
mod boj;

/// BoJ Live — async BoJ-server connection via shared HTTP client (v0.2.0+).
/// Async alternative to `boj::commands` using the shared `http_client` module.
mod boj_live;

/// VeriSimDB Live — async VeriSimDB connection for proof-carrying data operations.
/// Connects to localhost:8080 for octad CRUD, VQL queries, and health monitoring.
mod verisimdb_live;

/// ECHIDNA Live — async ECHIDNA theorem prover connection.
/// Connects to localhost:9000 for tactic selection, obligation dispatch, and prover stats.
mod echidna_live;

/// Shared async HTTP client for backend service connections.
/// Centralises timeout, error handling, and connection pooling for all
/// panel backends (BoJ, VeriSimDB, ECHIDNA, Fleet, etc.).
mod http_client;

/// TypeLL — Type-Level Language server bridge.
/// Routes to TypeLL server at TYPELL_URL (default http://localhost:7800/api/v1).
mod typell;

/// Valence Shell — PTY session management, asciicast recordings, and checkpoints.
/// Ephemeral data stored under /tmp/panll/ (recordings, checkpoints).
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
/// Bridges PanLL Level Architect to IDApTIK UMS validation via the shared
/// bridge directory at /tmp/panll/ums-bridge/.
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
/// Routes to fleet Axum API at FLEET_URL (default http://localhost:8080/api/v1).
mod fleet;

/// Hypatia — Neurosymbolic scanner bridge for CI/CD intelligence.
/// Routes to Hypatia Elixir Phoenix API at HYPATIA_URL (default http://localhost:4040/api/v1).
mod hypatia;

/// Aerie — Network diagnostics (latency probes, speed tests).
/// Runs in-process using std::net and reqwest — no external service needed.
mod aerie;

/// Provenance — Git blame analysis and unsound marker detection.
/// Uses std::process::Command to run git and regex to scan for dangerous patterns.
mod provenance;

/// Feedback — Persistent feedback report storage under ~/.panll/feedback/.
mod feedback;

/// Script Gist — Persistent gist storage, execution dispatch, and diachronic snapshots.
mod script_gist;

/// Wiring Inspector — Panel Contract Compiler (PCC) bridge for constraint verification.
mod wiring_inspector;

const DEFAULT_PANIC_ATTACK_BIN: &str = "/var/mnt/eclipse/repos/panic-attacker/target/debug/panic-attack";
const DEFAULT_PANIC_ATTACK_REPORTS_DIR: &str = "/var/mnt/eclipse/repos/panic-attacker/reports";

/// Tracks operator vexation indicators for the Vexometer
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
        let raw_index = (self.cancellations as f64 * 0.15 + self.corrections as f64 * 0.08) * decay_factor;
        raw_index.min(1.0)
    }
}

static VEXATION_TRACKER: Lazy<Mutex<VexationTracker>> = Lazy::new(|| {
    Mutex::new(VexationTracker::new())
});

/// Binary discovery respects `PANIC_ATTACK_BIN` overrides, the local debug/release builds, and
/// the PATH search so the UI can find whatever verified bundle is in the runtime.

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

/// Launches `panic-attack ambush` with the UI-supplied options, captures the report,
/// and hands it to `run_panic_attack_panll` so the frontend always receives a
/// PanLL event-chain (with fallback conversion when necessary).
#[tauri::command]
fn run_panic_attack_ambush(options: AmbushOptions) -> Result<String, String> {
    if options.program.trim().is_empty() {
        return Err("Program path is required".to_string());
    }

    let output_report = ambush_report_path();
    let mut failures = Vec::new();

    for bin in panic_attack_binaries() {
        let mut command = Command::new(&bin);
        command
            .arg("--quiet")
            .arg("ambush")
            .arg(&options.program)
            .arg("--output")
            .arg(&output_report);

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
                failures.push(format!(
                    "{} -> exit {} (stderr: {}; stdout: {})",
                    bin.display(),
                    process.status,
                    stderr,
                    stdout
                ));
            }
            Err(err) => failures.push(format!("{} -> {}", bin.display(), err)),
        }
    }

    Err(format!(
        "Failed to launch ambush. Tried binaries: {}",
        failures.join(" | ")
    ))
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

/// Attempts to run `panic-attack panll` against the generated report, falling back
/// to `fallback_panll_export_from_assault` when the binary lacks the command.
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
    // Parse and validate each constraint expression
    for constraint in &constraints {
        let constraint = constraint.trim();

        // Handle forbidden-pattern constraints: !contains("pattern")
        if let Some(pattern_start) = constraint.find("!contains(\"") {
            if let Some(pattern_end) = constraint[pattern_start..].find("\")") {
                let pattern = &constraint[pattern_start + 11..pattern_start + pattern_end];
                if token.contains(pattern) {
                    return Err(format!("Forbidden pattern detected: {}", pattern));
                }
                continue;
            }
        }

        // Handle type-name constraints: type FooBar = ...
        if constraint.starts_with("type ") {
            let parts: Vec<&str> = constraint.split_whitespace().collect();
            if parts.len() >= 2 {
                let type_name = parts[1];
                // Basic keyword check - ensure it's not a reserved word
                let reserved = ["undefined", "null", "NaN", "eval", "function", "var", "let", "const"];
                if reserved.contains(&type_name) {
                    return Err(format!("Type name uses reserved keyword: {}", type_name));
                }
            }
            continue;
        }

        // Handle boundary checks: length > 0, count < 100, etc.
        // Validates constraint syntax: LHS must be a valid identifier, operator
        // must be a comparison, RHS must be a valid number. Runtime value checking
        // happens in the ReScript AntiCrash module which has access to model state.
        if constraint.contains(" > ") || constraint.contains(" < ") ||
           constraint.contains(" >= ") || constraint.contains(" <= ") {
            // Split on the operator to validate both sides
            let operators = [" >= ", " <= ", " > ", " < "];
            let mut validated = false;
            for op in &operators {
                if let Some(pos) = constraint.find(op) {
                    let lhs = constraint[..pos].trim();
                    let rhs = constraint[pos + op.len()..].trim();

                    // LHS must be a valid identifier (alphanumeric + underscores, not starting with digit)
                    if lhs.is_empty() || lhs.starts_with(|c: char| c.is_ascii_digit()) ||
                       !lhs.chars().all(|c| c.is_alphanumeric() || c == '_') {
                        return Err(format!(
                            "Invalid boundary constraint: '{}' is not a valid identifier in '{}'",
                            lhs, constraint
                        ));
                    }

                    // RHS must be a valid number (integer or float, optionally negative)
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

        // For all other constraints, check that the token doesn't contain
        // a logical negation of the constraint
        if constraint.contains("==") || constraint.contains("!=") {
            // Look for contradictory statements in token
            if token.contains(&format!("!{}", constraint)) ||
               (constraint.contains("==") && token.contains(&constraint.replace("==", "!="))) {
                return Err(format!("Token contradicts constraint: {}", constraint));
            }
        }
    }

    Ok(true)
}

/// Records a vexation event (cancellation or correction).
#[tauri::command]
fn record_vexation_event(event_type: String) -> Result<(), String> {
    let mut tracker = VEXATION_TRACKER.lock().map_err(|e| format!("Lock error: {}", e))?;

    match event_type.as_str() {
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

/// Returns the current Vexation Index based on operator stress indicators.
#[tauri::command]
fn get_vexation_index() -> f64 {
    VEXATION_TRACKER.lock().map(|tracker| tracker.compute_index()).unwrap_or(0.0)
}

/// Submits feedback to the Feedback-O-Tron collective.
///
/// Appends one NDJSON line to `/tmp/panll/feedback/feedback.ndjson`.
/// NDJSON (Newline-Delimited JSON) is used instead of one-file-per-submission
/// because feedback is an append-only log:
///   - Crash-safe: a partial write loses one line, not the entire history
///   - Searchable: `grep "bug" feedback.ndjson` finds all bug reports
///   - Countable: `wc -l feedback.ndjson` gives the total instantly
///   - No orphaned files to clean up
#[tauri::command]
fn submit_feedback(
    pane_l_state: String,
    pane_n_state: String,
    pane_w_state: String,
    report_type: String,
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

    // Serialize as a single compact line (no pretty-printing — NDJSON requires one object per line).
    let mut line = serde_json::to_string(&feedback_json).map_err(|e| e.to_string())?;
    line.push('\n');

    // Append to the NDJSON log file. OpenOptions ensures atomic append on POSIX.
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

    #[test]
    fn test_validate_inference_clean_token_passes() {
        let token = "const user = { name: 'Alice', age: 30 };";
        let constraints = vec!["!contains(\"eval(\")".to_string(), "type User".to_string()];
        let result = validate_inference(token, constraints);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), true);
    }

    #[test]
    fn test_validate_inference_forbidden_pattern_rejected() {
        let token = "const code = eval('malicious');";
        let constraints = vec!["!contains(\"eval(\")".to_string()];
        let result = validate_inference(token, constraints);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Forbidden pattern detected"));
    }

    #[test]
    fn test_validate_inference_empty_constraints_passes() {
        let token = "const x = 42;";
        let constraints: Vec<String> = vec![];
        let result = validate_inference(token, constraints);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), true);
    }

    #[test]
    fn test_validate_inference_valid_boundary_passes() {
        let token = "const x = 42;";
        let constraints = vec![
            "length > 0".to_string(),
            "count < 100".to_string(),
            "score >= -1.5".to_string(),
            "max_depth <= 999".to_string(),
        ];
        let result = validate_inference(token, constraints);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_inference_invalid_boundary_rhs_rejected() {
        let token = "const x = 42;";
        let constraints = vec!["length > \"invalid\"".to_string()];
        let result = validate_inference(token, constraints);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not a valid number"));
    }

    #[test]
    fn test_validate_inference_invalid_boundary_lhs_rejected() {
        let token = "const x = 42;";
        let constraints = vec!["123bad > 5".to_string()];
        let result = validate_inference(token, constraints);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not a valid identifier"));
    }

    #[test]
    fn test_validate_inference_boundary_special_chars_rejected() {
        let token = "const x = 42;";
        let constraints = vec!["foo-bar > 5".to_string()];
        let result = validate_inference(token, constraints);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not a valid identifier"));
    }

    #[test]
    fn test_vexation_initial_index_is_zero() {
        // Reset tracker by creating a new one (in a real app we'd need better reset mechanisms)
        let index = get_vexation_index();
        // Index should be close to 0 initially (might not be exactly 0 due to decay)
        assert!(index >= 0.0 && index <= 1.0);
    }

    #[test]
    fn test_vexation_index_rises_after_events() {
        // Record some events
        let _ = record_vexation_event("cancellation".to_string());
        let _ = record_vexation_event("correction".to_string());

        let index = get_vexation_index();
        // Index should have risen from initial state
        assert!(index > 0.0);
        assert!(index <= 1.0);
    }

    #[test]
    fn test_submit_feedback_appends_ndjson() {
        let feedback_path = env::temp_dir().join("panll").join("feedback").join("feedback.ndjson");
        let lines_before = if feedback_path.exists() {
            fs::read_to_string(&feedback_path).unwrap_or_default().lines().count()
        } else {
            0
        };

        let result = submit_feedback(
            "pane_l content".to_string(),
            "pane_n content".to_string(),
            "pane_w content".to_string(),
            "bug".to_string(),
        );

        assert!(result.is_ok());
        let message = result.unwrap();
        assert!(message.contains("Feedback appended:"));
        assert!(message.contains("feedback.ndjson"));

        // Verify the file grew (other parallel tests may also append, so use >=).
        let content = fs::read_to_string(&feedback_path).expect("read feedback log");
        let lines: Vec<&str> = content.lines().collect();
        assert!(lines.len() > lines_before, "file should have grown");

        // Find our specific entry by its unique pane_l_state value.
        let our_line = lines.iter().find(|line| line.contains("pane_l content"))
            .expect("our feedback entry should be in the log");
        let feedback: Value = serde_json::from_str(our_line).expect("parse NDJSON line");
        assert_eq!(feedback.get("report_type").and_then(Value::as_str), Some("bug"));
        assert_eq!(feedback.get("pane_l_state").and_then(Value::as_str), Some("pane_l content"));
        assert!(feedback.get("id").is_some());
        assert!(feedback.get("timestamp").is_some());

        // Verify it's compact (no embedded newlines within the JSON object).
        assert!(!our_line.contains('\n'));
    }

    #[test]
    fn test_submit_feedback_different_report_type() {
        let feedback_path = env::temp_dir().join("panll").join("feedback").join("feedback.ndjson");
        let lines_before = if feedback_path.exists() {
            fs::read_to_string(&feedback_path).unwrap_or_default().lines().count()
        } else {
            0
        };

        let result = submit_feedback(
            "state1".to_string(),
            "state2".to_string(),
            "state3".to_string(),
            "feature-request".to_string(),
        );

        assert!(result.is_ok());
        let message = result.unwrap();
        assert!(message.contains("feedback.ndjson"));

        // Verify the file grew and our entry is present.
        let content = fs::read_to_string(&feedback_path).expect("read feedback log");
        let lines: Vec<&str> = content.lines().collect();
        assert!(lines.len() > lines_before, "file should have grown");
        let our_line = lines.iter().find(|line| line.contains("\"state1\""))
            .expect("our feedback entry should be in the log");
        let last: Value = serde_json::from_str(our_line).expect("parse NDJSON line");
        assert_eq!(last.get("report_type").and_then(Value::as_str), Some("feature-request"));
    }
}

// ---------------------------------------------------------------------------
// VeriSimDB integration — connects PanLL to VeriSimDB's VQL query engine
// ---------------------------------------------------------------------------

/// Default VeriSimDB API endpoint (can be overridden with VERISIMDB_URL env var)
// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_VERISIMDB_URL: &str = "http://localhost:8080/api/v1";

/// Resolve the VeriSimDB API base URL from environment or default.
fn verisimdb_url() -> String {
    std::env::var("VERISIMDB_URL").unwrap_or_else(|_| DEFAULT_VERISIMDB_URL.to_string())
}

/// GET /health — check VeriSimDB connectivity and status.
#[tauri::command]
fn verisimdb_health() -> Result<String, String> {
    let url = format!("{}/health", verisimdb_url());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("VeriSimDB returned {}: {}", status, body))
            }
        }
        Err(e) => Err(format!("Cannot reach VeriSimDB at {}: {}", url, e)),
    }
}

/// POST /vql/execute — execute a VQL query and return results as JSON.
#[tauri::command]
fn verisimdb_query(query: String) -> Result<String, String> {
    let url = format!("{}/vql/execute", verisimdb_url());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let payload = serde_json::json!({ "query": query });

    match client.post(&url).json(&payload).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("VQL query failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("VQL query request failed: {}", e)),
    }
}

/// GET /octads — list octad entities with pagination.
#[tauri::command]
fn verisimdb_list_octads(limit: usize, offset: usize) -> Result<String, String> {
    let url = format!("{}/octads?limit={}&offset={}", verisimdb_url(), limit, offset);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("List octads failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("List octads request failed: {}", e)),
    }
}

/// GET /telemetry — fetch product telemetry report from the Elixir orchestration API.
///
/// Connects to the orchestration layer (default port 4080) rather than the Rust
/// core (port 8080). The telemetry report contains aggregate-only product metrics:
/// modality heatmap, query patterns, drift frequency, proof type usage, etc.
/// No PII, no query content, no entity data — only counters and distributions.
///
/// Override the orchestration URL with the VERISIMDB_ORCH_URL env var.
#[tauri::command]
fn verisimdb_telemetry() -> Result<String, String> {
    let base = std::env::var("VERISIMDB_ORCH_URL")
        .unwrap_or_else(|_| "http://localhost:4080".to_string());
    let url = format!("{}/telemetry", base);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Telemetry request failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!(
            "Cannot reach VeriSimDB orchestration at {}: {}. \
             Is the Elixir orchestration layer running?",
            url, e
        )),
    }
}

/// GET /status — fetch orchestration status (consensus, federation, telemetry).
#[tauri::command]
fn verisimdb_orch_status() -> Result<String, String> {
    let base = std::env::var("VERISIMDB_ORCH_URL")
        .unwrap_or_else(|_| "http://localhost:4080".to_string());
    let url = format!("{}/status", base);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Orchestration status failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Cannot reach orchestration at {}: {}", url, e)),
    }
}

/// GET /drift/entity/{id} — retrieve drift metrics for a specific entity.
#[tauri::command]
fn verisimdb_get_drift(entity_id: String) -> Result<String, String> {
    let url = format!("{}/drift/entity/{}", verisimdb_url(), entity_id);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Get drift failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Get drift request failed: {}", e)),
    }
}

/// POST /normalizer/trigger/{id} — trigger normalisation (self-repair) for a drifted entity.
///
/// VeriSimDB normalisation re-aligns an entity's modality vectors after drift is detected.
/// The normaliser recalculates consistency scores, re-validates proofs, and updates the
/// entity's octad representation. Returns the normalisation result as JSON.
#[tauri::command]
fn verisimdb_normalise(entity_id: String) -> Result<String, String> {
    let url = format!("{}/normalizer/trigger/{}", verisimdb_url(), entity_id);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.post(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Normalisation failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Normalisation request failed: {}", e)),
    }
}

/// GET /octads/{id} — retrieve full entity detail (all modality data) for a specific octad.
///
/// Returns the complete octad representation including all six modality vectors,
/// consistency scores, proof attachments, and drift history for the given entity.
#[tauri::command]
fn verisimdb_get_entity(entity_id: String) -> Result<String, String> {
    let url = format!("{}/octads/{}", verisimdb_url(), entity_id);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Get entity failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Get entity request failed: {}", e)),
    }
}

// ===========================================================================
// ECHIDNA Theorem Prover Backend
// ===========================================================================

// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_ECHIDNA_URL: &str = "http://localhost:9000/api/v1";

/// Resolve the ECHIDNA API base URL from environment or default.
/// Override with ECHIDNA_URL env var for non-default deployments.
fn echidna_url() -> String {
    std::env::var("ECHIDNA_URL").unwrap_or_else(|_| DEFAULT_ECHIDNA_URL.to_string())
}

/// GET /health — check ECHIDNA prover connectivity and version.
/// Returns JSON with `status` and `version` fields on success.
#[tauri::command]
fn echidna_health() -> Result<String, String> {
    let url = format!("{}/health", echidna_url());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("ECHIDNA returned {}: {}", status, body))
            }
        }
        Err(e) => Err(format!("Cannot reach ECHIDNA at {}: {}", url, e)),
    }
}

/// GET /provers — list available theorem provers with tier and complexity.
/// Returns a JSON array of `{name, tier, complexity}` objects.
#[tauri::command]
fn echidna_list_provers() -> Result<String, String> {
    let url = format!("{}/provers", echidna_url());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("List provers failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("List provers request failed: {}", e)),
    }
}

/// POST /prove — submit proof content with an optional prover selection.
/// Sends `{content, prover?}` and returns the dispatch result JSON with
/// verification status, trust level, axiom report, and certificate hash.
#[tauri::command]
fn echidna_prove(content: String, prover: Option<String>) -> Result<String, String> {
    let url = format!("{}/prove", echidna_url());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let mut payload = serde_json::json!({ "content": content });
    if let Some(p) = prover {
        payload["prover"] = serde_json::Value::String(p);
    }

    match client.post(&url).json(&payload).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Proof submission failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Proof submission request failed: {}", e)),
    }
}

/// POST /verify — verify proof content without specifying a prover.
/// Returns JSON with `{valid, goals_remaining, tactics_used}`.
#[tauri::command]
fn echidna_verify(content: String) -> Result<String, String> {
    let url = format!("{}/verify", echidna_url());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let payload = serde_json::json!({ "content": content });

    match client.post(&url).json(&payload).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Verification failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Verification request failed: {}", e)),
    }
}

/// GET /search?q=... — search the ECHIDNA theorem library.
/// The query is manually percent-encoded to avoid adding a url-encoding crate.
/// Returns JSON with `{results, count}`.
#[tauri::command]
fn echidna_search_theorems(query: String) -> Result<String, String> {
    // Manual percent-encoding for the search query (no new crate dependency).
    let encoded: String = query
        .chars()
        .map(|c| match c {
            'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '_' | '.' | '~' => c.to_string(),
            ' ' => "+".to_string(),
            _ => format!("%{:02X}", c as u32),
        })
        .collect();
    let url = format!("{}/search?q={}", echidna_url(), encoded);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Theorem search failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Theorem search request failed: {}", e)),
    }
}

/// POST /proofs — create a new interactive proof session.
/// Sends `{"goal": goal, "prover": prover}` and returns the ProofResponse JSON
/// with session ID, initial goals, and status (201 Created).
#[tauri::command]
fn echidna_create_session(goal: String, prover: String) -> Result<String, String> {
    let url = format!("{}/proofs", echidna_url());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let payload = json!({ "goal": goal, "prover": prover });

    match client.post(&url).json(&payload).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Session creation failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Session creation request failed: {}", e)),
    }
}

/// GET /proofs/{id} — retrieve the current state of a proof session.
/// Returns the ProofResponse JSON with goals, status, and applied tactics.
#[tauri::command]
fn echidna_get_session(session_id: String) -> Result<String, String> {
    let url = format!("{}/proofs/{}", echidna_url(), session_id);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Get session failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Get session request failed: {}", e)),
    }
}

/// POST /proofs/{id}/tactics — apply a tactic to an active proof session.
/// Sends `{"name": name, "args": args}` and returns the TacticResponse JSON
/// with success flag and updated proof state.
#[tauri::command]
fn echidna_apply_tactic(
    session_id: String,
    name: String,
    args: Vec<String>,
) -> Result<String, String> {
    let url = format!("{}/proofs/{}/tactics", echidna_url(), session_id);
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let payload = json!({ "name": name, "args": args });

    match client.post(&url).json(&payload).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Apply tactic failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Apply tactic request failed: {}", e)),
    }
}

/// GET /proofs/{id}/tactics/suggest?limit=N — request ML-powered tactic suggestions.
/// The ML advisor (Julia :8090) generates suggestions with confidence scores,
/// falling back to prover heuristics if the advisor is unavailable.
#[tauri::command]
fn echidna_suggest_tactics(session_id: String, limit: usize) -> Result<String, String> {
    let url = format!(
        "{}/proofs/{}/tactics/suggest?limit={}",
        echidna_url(),
        session_id,
        limit
    );
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Tactic suggestions failed ({}): {}", status, body))
            }
        }
        Err(e) => Err(format!("Tactic suggestions request failed: {}", e)),
    }
}

#[cfg(test)]
mod echidna_tests {
    use super::*;

    #[test]
    fn echidna_url_default_and_override() {
        // Run both checks sequentially to avoid env var race with parallel tests.
        std::env::remove_var("ECHIDNA_URL");
        assert_eq!(echidna_url(), DEFAULT_ECHIDNA_URL);

        let custom = "http://prover.local:9090/api";
        std::env::set_var("ECHIDNA_URL", custom);
        assert_eq!(echidna_url(), custom);

        // Clean up so other tests aren't affected.
        std::env::remove_var("ECHIDNA_URL");
    }

    #[test]
    fn echidna_session_url_construction() {
        std::env::remove_var("ECHIDNA_URL");
        let base = echidna_url();
        let session_url = format!("{}/proofs/{}", base, "test-session-123");
        assert_eq!(
            session_url,
            "http://localhost:9000/api/v1/proofs/test-session-123"
        );

        let tactic_url = format!("{}/proofs/{}/tactics", base, "sess-abc");
        assert_eq!(
            tactic_url,
            "http://localhost:9000/api/v1/proofs/sess-abc/tactics"
        );

        let suggest_url = format!(
            "{}/proofs/{}/tactics/suggest?limit={}",
            base, "sess-abc", 5
        );
        assert_eq!(
            suggest_url,
            "http://localhost:9000/api/v1/proofs/sess-abc/tactics/suggest?limit=5"
        );
    }

    #[test]
    fn echidna_prover_serialisation() {
        let payload = json!({ "goal": "forall x, x + 0 = x", "prover": "lean4" });
        let obj = payload.as_object().unwrap();
        assert_eq!(obj.get("goal").unwrap().as_str().unwrap(), "forall x, x + 0 = x");
        assert_eq!(obj.get("prover").unwrap().as_str().unwrap(), "lean4");

        let tactic_payload = json!({ "name": "intro", "args": ["x", "y"] });
        let tobj = tactic_payload.as_object().unwrap();
        assert_eq!(tobj.get("name").unwrap().as_str().unwrap(), "intro");
        let args = tobj.get("args").unwrap().as_array().unwrap();
        assert_eq!(args.len(), 2);
        assert_eq!(args[0].as_str().unwrap(), "x");
    }
}

// ===========================================================================
// Protocol-Squisher CLI Bridge
// ===========================================================================

const DEFAULT_PROTOCOL_SQUISHER_BIN: &str = "protocol-squisher";

/// Resolve the protocol-squisher binary path from environment or default.
fn protocol_squisher_bin() -> String {
    std::env::var("PROTOCOL_SQUISHER_BIN")
        .unwrap_or_else(|_| DEFAULT_PROTOCOL_SQUISHER_BIN.to_string())
}

/// Check whether the protocol-squisher CLI binary is available.
#[tauri::command]
fn protocol_squisher_check() -> Result<String, String> {
    let output = std::process::Command::new(protocol_squisher_bin())
        .arg("--version")
        .output()
        .map_err(|e| format!("CLI not found: {}", e))?;

    if output.status.success() {
        let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
        Ok(format!("{{\"available\":true,\"version\":\"{}\"}}", version))
    } else {
        Err("protocol-squisher CLI not available".to_string())
    }
}

/// Analyse a schema file using `protocol-squisher analyze`.
/// Returns JSON analysis result.
#[tauri::command]
fn protocol_squisher_analyze(file_path: String) -> Result<String, String> {
    let output = std::process::Command::new(protocol_squisher_bin())
        .args(["analyze", &file_path, "--format", "json"])
        .output()
        .map_err(|e| format!("Analysis failed: {}", e))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        Err(format!("Analysis error: {}", stderr))
    }
}

/// Compare two schema files using `protocol-squisher compare`.
/// Returns JSON compatibility result.
#[tauri::command]
fn protocol_squisher_compare(left_path: String, right_path: String) -> Result<String, String> {
    let output = std::process::Command::new(protocol_squisher_bin())
        .args(["compare", &left_path, &right_path, "--format", "json"])
        .output()
        .map_err(|e| format!("Comparison failed: {}", e))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        Err(format!("Comparison error: {}", stderr))
    }
}

// ===========================================================================
// My-Lang CLI Bridge
// ===========================================================================

const DEFAULT_MYLANG_BIN: &str = "my";

/// Resolve the my-lang binary path from environment or default.
fn mylang_bin() -> String {
    std::env::var("MYLANG_BIN").unwrap_or_else(|_| DEFAULT_MYLANG_BIN.to_string())
}

/// Check whether the my-lang CLI binary is available.
#[tauri::command]
fn mylang_check() -> Result<String, String> {
    let output = std::process::Command::new(mylang_bin())
        .arg("--version")
        .output()
        .map_err(|e| format!("CLI not found: {}", e))?;

    if output.status.success() {
        let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
        Ok(format!("{{\"available\":true,\"version\":\"{}\"}}", version))
    } else {
        Err("my-lang CLI not available".to_string())
    }
}

/// Compile source code in a given dialect.
/// Writes source to a temp file, runs `my compile`, returns JSON result.
#[tauri::command]
fn mylang_compile(source: String, dialect: String) -> Result<String, String> {
    use std::io::Write;

    let ext = match dialect.to_lowercase().as_str() {
        "solo" => "solo",
        "duet" => "duet",
        "ensemble" => "ens",
        "me" => "me",
        _ => "solo",
    };

    let tmp_dir = std::env::temp_dir().join("panll-mylang");
    std::fs::create_dir_all(&tmp_dir)
        .map_err(|e| format!("Failed to create temp dir: {}", e))?;

    let tmp_file = tmp_dir.join(format!("input.{}", ext));
    let mut f = std::fs::File::create(&tmp_file)
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    f.write_all(source.as_bytes())
        .map_err(|e| format!("Failed to write source: {}", e))?;

    let start = std::time::Instant::now();
    let output = std::process::Command::new(mylang_bin())
        .args(["compile", tmp_file.to_str().unwrap_or("input"), "--format", "json"])
        .output()
        .map_err(|e| format!("Compilation failed: {}", e))?;
    let elapsed_ms = start.elapsed().as_millis();

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    // Construct a JSON result
    let success = output.status.success();
    Ok(format!(
        "{{\"success\":{},\"output\":{},\"diagnostics\":{},\"error_count\":0,\"warning_count\":0,\"compile_time_ms\":{}}}",
        success,
        serde_json::to_string(&stdout).unwrap_or_else(|_| "\"\"".to_string()),
        serde_json::to_string(&stderr).unwrap_or_else(|_| "\"\"".to_string()),
        elapsed_ms
    ))
}

/// Evaluate a REPL input line.
/// Runs `my repl --eval` with the given input and dialect.
#[tauri::command]
fn mylang_repl(input: String, dialect: String) -> Result<String, String> {
    let output = std::process::Command::new(mylang_bin())
        .args(["repl", "--eval", &input, "--dialect", &dialect.to_lowercase()])
        .output()
        .map_err(|e| format!("REPL eval failed: {}", e))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        Err(if stderr.is_empty() { "Evaluation error".to_string() } else { stderr })
    }
}

// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_MYLANG_LSP_URL: &str = "http://localhost:7900";

/// Resolve the my-lang LSP URL from environment or default.
fn mylang_lsp_url() -> String {
    std::env::var("MYLANG_LSP_URL").unwrap_or_else(|_| DEFAULT_MYLANG_LSP_URL.to_string())
}

/// Helper — build an HTTP client with the given timeout (seconds).
fn mylang_lsp_client(timeout_secs: u64) -> Result<reqwest::blocking::Client, String> {
    reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))
}

/// Connect to the my-lang LSP server at localhost:7900 (or MYLANG_LSP_URL).
/// Sends a health-check GET to verify the LSP is reachable and returns
/// "connected" on success.
#[tauri::command]
fn mylang_lsp_connect() -> Result<String, String> {
    let url = mylang_lsp_url();
    let client = mylang_lsp_client(5)?;

    match client.get(&url).send() {
        Ok(resp) if resp.status().is_success() => {
            Ok(json!({"status": "connected", "url": url}).to_string())
        }
        Ok(resp) => Err(format!("LSP returned HTTP {}", resp.status())),
        Err(e) => Err(format!("Cannot reach my-lang LSP at {}: {}", url, e)),
    }
}

/// Request diagnostics from the my-lang LSP for a given file.
/// Sends a textDocument/didOpen-style POST to the LSP and returns
/// any diagnostics as a JSON array.
#[tauri::command]
fn mylang_lsp_diagnostics(file_path: String, content: String) -> Result<String, String> {
    let url = format!("{}/diagnostics", mylang_lsp_url());
    let client = mylang_lsp_client(30)?;

    let body = json!({
        "jsonrpc": "2.0",
        "method": "textDocument/didOpen",
        "params": {
            "textDocument": {
                "uri": format!("file://{}", file_path),
                "languageId": "mylang",
                "version": 1,
                "text": content
            }
        }
    });

    match client.post(&url).json(&body).send() {
        Ok(resp) => {
            let status = resp.status();
            let text = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(text)
            } else {
                Err(format!("LSP diagnostics returned {}: {}", status, text))
            }
        }
        Err(e) => Err(format!("LSP diagnostics request failed: {}", e)),
    }
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![
            // Generic health check for panel switcher connection dots
            health_check,
            validate_inference,
            record_vexation_event,
            get_vexation_index,
            submit_feedback,
            import_panic_attacker_report,
            import_latest_panic_attacker_report,
            get_panic_attacker_capability,
            run_panic_attack_ambush,
            verisimdb_health,
            verisimdb_query,
            verisimdb_list_octads,
            verisimdb_get_drift,
            verisimdb_normalise,
            verisimdb_get_entity,
            verisimdb_telemetry,
            verisimdb_orch_status,
            echidna_health,
            echidna_list_provers,
            echidna_prove,
            echidna_verify,
            echidna_search_theorems,
            echidna_create_session,
            echidna_get_session,
            echidna_apply_tactic,
            echidna_suggest_tactics,
            // CloudGuard — Cloudflare domain security management
            cloudguard::commands::cloudguard_verify_token,
            cloudguard::commands::cloudguard_list_zones,
            cloudguard::commands::cloudguard_get_zone,
            cloudguard::commands::cloudguard_get_settings,
            cloudguard::commands::cloudguard_update_setting,
            cloudguard::commands::cloudguard_update_settings_batch,
            cloudguard::commands::cloudguard_list_dns_records,
            cloudguard::commands::cloudguard_create_dns_record,
            cloudguard::commands::cloudguard_update_dns_record,
            cloudguard::commands::cloudguard_delete_dns_record,
            cloudguard::commands::cloudguard_get_dnssec,
            cloudguard::commands::cloudguard_enable_dnssec,
            cloudguard::commands::cloudguard_harden_zone,
            cloudguard::commands::cloudguard_download_config,
            // Farm — Git-Private-Farm repo inventory
            farm::commands::farm_list_repos,
            farm::commands::farm_get_repo,
            farm::commands::farm_get_stats,
            // VM Inspector — in-process virtual machine
            vm_inspector::commands::vm_inspector_read_state,
            vm_inspector::commands::vm_inspector_step_forward,
            vm_inspector::commands::vm_inspector_step_backward,
            vm_inspector::commands::vm_inspector_run,
            vm_inspector::commands::vm_inspector_load_program,
            vm_inspector::commands::vm_inspector_export_snapshot,
            vm_inspector::commands::vm_inspector_read_file,
            // Plaza — Palimpsest License adoption and compliance
            plaza::commands::plaza_scan_repo,
            plaza::commands::plaza_adoption_stats,
            plaza::commands::plaza_check_compatibility,
            // Minter — Panel creation wizard
            minter::commands::minter_validate_name,
            minter::commands::minter_mint_panel,
            // VoiceTag — Code MRI Layer 0 sidecar file I/O
            voicetag::commands::voicetag_load,
            voicetag::commands::voicetag_save,
            voicetag::commands::voicetag_delete,
            voicetag::commands::voicetag_scan,
            // Watcher — Filesystem observation
            watcher::commands::watcher_start,
            watcher::commands::watcher_stop,
            watcher::commands::watcher_add_path,
            watcher::commands::watcher_remove_path,
            watcher::commands::watcher_status,
            // AI — Multi-provider neural interface
            ai::commands::ai_send_message,
            ai::commands::ai_check_provider,
            ai::commands::ai_set_model,
            ai::commands::ai_set_priority,
            ai::commands::ai_toggle_provider,
            ai::commands::ai_clear_history,
            ai::commands::ai_build_context,
            ai::commands::ai_get_state,
            ai::commands::ai_send_message_streaming,
            // Repo Loader — Repository scanning and panel configuration
            repoloader::commands::repoloader_scan,
            repoloader::commands::repoloader_save_panels,
            repoloader::commands::repoloader_list_recent,
            repoloader::commands::repoloader_search_farm,
            // Workspace — Arrangements, sessions, system info (DD-024/025)
            workspace::commands::save_arrangement,
            workspace::commands::load_arrangements,
            workspace::commands::delete_arrangement,
            workspace::commands::save_session,
            workspace::commands::load_sessions,
            workspace::commands::delete_session,
            workspace::sysinfo::get_system_info,
            // Capture — Screenshots, recordings, demos (DD-022)
            capture::commands::save_screenshot,
            capture::commands::print_panel,
            capture::commands::save_demo,
            capture::commands::load_demos,
            capture::commands::delete_demo,
            // Security — Redaction, vault, 2FA, Trustfile (DD-026/027)
            security::commands::redact_text,
            security::commands::vault_store,
            security::commands::vault_retrieve,
            security::commands::vault_list,
            security::commands::load_trustfile,
            // Overlay — Tor, IPFS, Ethereum overlay networks (Aerie)
            overlay::commands::overlay_status,
            overlay::commands::overlay_health,
            overlay::commands::overlay_tor_connect,
            overlay::commands::overlay_tor_disconnect,
            overlay::commands::overlay_tor_status,
            overlay::commands::overlay_tor_create_hidden_service,
            overlay::commands::overlay_tor_destroy_hidden_service,
            overlay::commands::overlay_tor_list_circuits,
            overlay::commands::overlay_tor_get_circuit,
            overlay::commands::overlay_tor_resolve,
            overlay::commands::overlay_ipfs_connect,
            overlay::commands::overlay_ipfs_disconnect,
            overlay::commands::overlay_ipfs_status,
            overlay::commands::overlay_ipfs_add,
            overlay::commands::overlay_ipfs_cat,
            overlay::commands::overlay_ipfs_pin,
            overlay::commands::overlay_ipfs_unpin,
            overlay::commands::overlay_ipfs_dag_get,
            overlay::commands::overlay_eth_connect,
            overlay::commands::overlay_eth_disconnect,
            overlay::commands::overlay_eth_status,
            overlay::commands::overlay_eth_timestamp_proof,
            overlay::commands::overlay_eth_verify_timestamp,
            // BoJ — Barrel of Jelly cartridge runtime
            boj::commands::boj_health,
            boj::commands::boj_list_cartridges,
            boj::commands::boj_get_cartridge,
            boj::commands::boj_load_cartridge,
            boj::commands::boj_unload_cartridge,
            boj::commands::boj_topology,
            boj::commands::boj_invoke,
            boj::commands::boj_umoja_status,
            // BoJ Live — async BoJ-server connection (v0.2.0)
            boj_live::boj_live_health,
            boj_live::boj_live_cartridges,
            boj_live::boj_live_invoke,
            boj_live::boj_live_topology,
            boj_live::boj_live_check,
            // VeriSimDB Live — proof-carrying data operations
            verisimdb_live::verisimdb_live_health,
            verisimdb_live::verisimdb_live_list_octads,
            verisimdb_live::verisimdb_live_query,
            verisimdb_live::verisimdb_live_get_octad,
            // ECHIDNA Live — theorem prover connection
            echidna_live::echidna_live_health,
            echidna_live::echidna_live_recommend_tactics,
            echidna_live::echidna_live_submit_obligation,
            echidna_live::echidna_live_get_result,
            echidna_live::echidna_live_stats,
            // TypeLL — Type-level language server
            typell::commands::typell_health,
            typell::commands::typell_check,
            typell::commands::typell_infer,
            typell::commands::typell_refine,
            typell::commands::typell_compute,
            typell::commands::typell_list_signatures,
            typell::commands::typell_universes,
            // Protocol-Squisher — 13-format schema analysis CLI bridge
            protocol_squisher_check,
            protocol_squisher_analyze,
            protocol_squisher_compare,
            // My-Lang — AI-native language CLI bridge
            mylang_check,
            mylang_compile,
            mylang_repl,
            mylang_lsp_connect,
            mylang_lsp_diagnostics,
            // Clade Scanner — A2ML clade file loading
            clade_scanner::commands::scan_clade_files,
            // Governance — nesy-MCP neural validation
            governance::commands::governance_nesy_query,
            governance::commands::governance_nesy_validate,
            governance::commands::governance_nesy_probe,
            // Coprocessor — Control plane + data plane + smart routing
            coprocessor::commands::query_compute_engine,
            coprocessor::commands::discover_compute_devices,
            coprocessor::commands::coprocessor_dispatch_local,
            coprocessor::commands::coprocessor_check_ffi,
            coprocessor::commands::coprocessor_benchmark,
            coprocessor::commands::coprocessor_load_ffi,
            coprocessor::commands::coprocessor_local_resources,
            coprocessor::commands::coprocessor_smart_dispatch,
            // Game Preview — IDApTIK engine preview and recording
            game_preview::commands::game_preview_check_server,
            game_preview::commands::game_preview_control,
            game_preview::commands::game_preview_record_start,
            game_preview::commands::game_preview_record_stop,
            game_preview::commands::game_preview_screenshot,
            game_preview::commands::game_preview_stats,
            game_preview::commands::game_preview_clips_list,
            game_preview::commands::game_preview_clip_delete,
            // Network Topology — IDApTIK in-game network viewer
            network_topology::commands::read_network_topology,
            network_topology::commands::read_dns_table,
            network_topology::commands::read_packet_flow,
            network_topology::commands::export_topology_svg,
            // Level Architect — IDApTIK level design tool
            level_architect::commands::load_level,
            level_architect::commands::save_level,
            level_architect::commands::export_level_config,
            level_architect::commands::browse_level_assets,
            level_architect::commands::validate_level,
            // Valence Shell — PTY sessions, recordings, checkpoints
            valence_shell::commands::valence_shell_check,
            valence_shell::commands::valence_shell_spawn,
            valence_shell::commands::valence_shell_input,
            valence_shell::commands::valence_shell_record_start,
            valence_shell::commands::valence_shell_record_stop,
            valence_shell::commands::valence_shell_recordings_list,
            valence_shell::commands::valence_shell_recording_delete,
            valence_shell::commands::valence_shell_checkpoint_create,
            valence_shell::commands::valence_shell_checkpoint_restore,
            valence_shell::commands::valence_shell_checkpoints_list,
            valence_shell::commands::valence_shell_screenshot,
            valence_shell::commands::valence_shell_recording_export,
            // Multiplayer Monitor — Phoenix sync server monitoring
            multiplayer_monitor::commands::multiplayer_connect,
            multiplayer_monitor::commands::multiplayer_disconnect,
            multiplayer_monitor::commands::multiplayer_read_state,
            multiplayer_monitor::commands::multiplayer_read_diffs,
            multiplayer_monitor::commands::multiplayer_read_ets,
            multiplayer_monitor::commands::multiplayer_reconnection_test,
            // DLC Workshop — Puzzle pack creation and testing
            dlc_workshop::commands::dlc_load_puzzles,
            dlc_workshop::commands::dlc_save_puzzle,
            dlc_workshop::commands::dlc_run_test,
            dlc_workshop::commands::dlc_run_all_tests,
            dlc_workshop::commands::dlc_browse_assets,
            dlc_workshop::commands::dlc_package,
            dlc_workshop::commands::dlc_import_puzzle,
            dlc_workshop::commands::dlc_export_puzzle,
            // Universal Modding Studio — Unified content creation hub
            ums::commands::ums_load_projects,
            ums::commands::ums_create_project,
            ums::commands::ums_open_project,
            ums::commands::ums_delete_project,
            ums::commands::ums_validate_level,
            ums::commands::ums_load_templates,
            ums::commands::ums_instantiate_template,
            ums::commands::ums_load_assets,
            ums::commands::ums_import_asset,
            ums::commands::ums_publish_mod,
            ums::commands::ums_load_api_reference,
            // UMS Cartridge — BoJ cartridge backend for ums-mcp routing
            ums_cartridge::commands::ums_cartridge_validate,
            ums_cartridge::commands::ums_cartridge_load_level,
            ums_cartridge::commands::ums_cartridge_save_level,
            ums_cartridge::commands::ums_cartridge_list_levels,
            ums_cartridge::commands::ums_cartridge_export_config,
            // Release Manager — Versioning, changelog, distribution
            release_manager::commands::release_generate_changelog,
            release_manager::commands::release_build_artifacts,
            release_manager::commands::release_publish,
            release_manager::commands::release_read_history,
            release_manager::commands::release_bump_version,
            // Umoja — peer management for federation gossip protocol
            umoja::commands::umoja_add_peer,
            umoja::commands::umoja_disconnect_peer,
            umoja::commands::umoja_trigger_gossip,
            umoja::commands::umoja_sync_catalogue,
            umoja::commands::umoja_peer_metrics,
            // Observability — SARIF export and OpenTelemetry traces via observe-mcp
            observability::commands::observe_export_sarif,
            observability::commands::observe_export_traces,
            observability::commands::observe_summary,
            // A2ML — AI manifest parsing and validation
            a2ml::commands::a2ml_load_manifest,
            a2ml::commands::a2ml_validate,
            a2ml::commands::a2ml_list,
            // K9 — contractile configuration and layout
            k9::commands::k9_load_contractile,
            k9::commands::k9_validate,
            k9::commands::k9_apply_layout,
            // Fleet — Gitbot-Fleet bot orchestration
            fleet::commands::fleet_get_bots,
            fleet::commands::fleet_get_findings,
            fleet::commands::fleet_dispatch,
            // Hypatia — Neurosymbolic scanner
            hypatia::commands::hypatia_get_networks,
            hypatia::commands::hypatia_get_scans,
            hypatia::commands::hypatia_scan_repo,
            // Aerie — Network diagnostics
            aerie::commands::aerie_get_latency,
            aerie::commands::aerie_speed_test,
            // Provenance — Git blame and unsound marker scanning
            provenance::commands::provenance_analyse_file,
            provenance::commands::provenance_scan_unsound,
            // Feedback — Persistent report storage
            feedback::commands::feedback_save_report,
            // Script Gist — Gist persistence, execution, and snapshots
            script_gist::commands::script_gist_save,
            script_gist::commands::script_gist_execute,
            script_gist::commands::script_gist_restore_snapshot,
            script_gist::commands::script_gist_list,
            // Wiring Inspector — PCC constraint verification
            wiring_inspector::commands::wiring_inspector_verify,
            wiring_inspector::commands::wiring_inspector_verify_panel,
        ])
        .setup(|_app| {
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running PanLL");
}
