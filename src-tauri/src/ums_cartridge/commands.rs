// SPDX-License-Identifier: PMPL-1.0-or-later
//
// commands.rs — Tauri IPC commands for the UMS BoJ cartridge proxy.
//
// Author: Jonathan D.A. Jewell
//
// This module implements the cartridge-side handlers that BoJ routes to when
// `ums-mcp` is the target. Each command mirrors a tool from the CartridgeAbi
// definition so the BoJ runtime can dispatch `invoke("ums_cartridge_*", ...)`
// calls transparently.
//
// ## Architecture
//
// The validation logic is implemented as standalone functions (not tied to
// Tauri) so that unit tests can call them directly without an async runtime
// where possible. The Tauri `#[tauri::command]` wrappers are thin shells
// around these core functions.
//
// ## Shared bridge directory
//
// All level data flows through `/tmp/panll/ums-bridge/`. This is separate
// from the UMS panel's `/tmp/panll/ums-projects/` to avoid cross-contamination
// between the cartridge proxy and the full UMS project manager.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Shared bridge directory for level data exchange between PanLL and IDApTIK.
///
/// This path is used exclusively by the cartridge proxy. The UMS panel uses
/// `/tmp/panll/ums-projects/` instead — the two must not overlap.
const BRIDGE_DIR: &str = "/tmp/panll/ums-bridge";

// ---------------------------------------------------------------------------
// Data types — mirrors of the Idris2/Zig/idaptik-ums level structures
// ---------------------------------------------------------------------------

/// A device in the level's network topology.
///
/// Corresponds to `DeviceSpec` in the IDApTIK ABI (`src/abi/Devices.idr`)
/// and `types.DeviceSpec` in the Zig FFI (`ffi/zig/src/types.zig`).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DeviceSpec {
    /// IPv4 address string (e.g. "192.168.1.10").
    pub ip: String,
    /// Device category (laptop, server, router, etc.).
    pub kind: String,
    /// Human-readable label shown in the editor.
    pub label: Option<String>,
}

/// Defence configuration flags for a device.
///
/// Corresponds to the `DefenceFlags` record in `src/abi/Devices.idr`.
/// Optional IP fields are `Option<String>` — `None` maps to the Idris2
/// `Nothing` / Zig `OptionalIpAddress { .has_value = false }`.
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct DefenceFlags {
    /// If set, traffic fails over to this device when the primary goes down.
    pub failover_target: Option<String>,
    /// If set, a trap cascades to this device on intrusion detection.
    pub cascade_trap: Option<String>,
    /// If set, traffic is mirrored to this device for monitoring.
    pub mirror_target: Option<String>,
}

/// Per-device defence configuration.
///
/// Each entry ties a device IP to its defence flags. The IP must exist in the
/// level's device registry — this is the `InRegistry` proof in Idris2.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DeviceDefenceConfig {
    /// IP address of the device this config applies to.
    pub ip: String,
    /// Defence behaviour flags.
    pub flags: DefenceFlags,
}

/// A guard placement in the level.
///
/// Corresponds to `GuardPlacement` in `src/abi/Guards.idr`. The `zone` field
/// must name a zone that exists in the level's zone list — this is the
/// `GuardsInZones` proof.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct GuardPlacement {
    /// Zone name where this guard patrols.
    pub zone: String,
    /// Guard rank (basic_guard, enforcer, anti_hacker, etc.).
    pub rank: String,
}

/// A zone in the level layout.
///
/// Corresponds to `Zone` in `src/abi/Zones.idr`.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Zone {
    /// Unique zone name (referenced by guards, transitions, etc.).
    pub name: String,
}

/// A zone transition boundary.
///
/// When the player crosses this X coordinate, they enter a new zone.
/// Transitions must be monotonically ordered by `world_x` — this is the
/// `ZonesOrdered` proof.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ZoneTransition {
    /// World X position of the transition boundary.
    pub world_x: f64,
    /// Target zone name.
    pub target_zone: String,
}

/// Complete level data bundle.
///
/// This is the JSON-serialisable mirror of `LevelData` in `src/abi/Level.idr`.
/// Only fields needed for validation and export are represented here. The full
/// level data flows through the ReScript frontend; Rust only needs the
/// validation-relevant subset.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct LevelData {
    /// Human-readable level name.
    pub name: String,
    /// Devices in the level's network.
    pub devices: Vec<DeviceSpec>,
    /// Zones in the level layout.
    pub zones: Vec<Zone>,
    /// Guard placements.
    pub guards: Vec<GuardPlacement>,
    /// Zone transition boundaries.
    pub zone_transitions: Vec<ZoneTransition>,
    /// Per-device defence configurations.
    pub device_defences: Vec<DeviceDefenceConfig>,
    /// Whether the level has a PBX (phone system).
    pub has_pbx: bool,
    /// IP address of the PBX device (only meaningful when `has_pbx` is true).
    pub pbx_ip: Option<String>,
}

/// Result of running the five ABI validation checks.
///
/// Mirrors `ValidationResult` in `ffi/zig/src/types.zig`. Each boolean
/// corresponds to one of the erased proof fields on `ValidatedLevel` in
/// `src/abi/Validation.idr`.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ValidationResult {
    /// True if all five checks pass.
    pub valid: bool,
    /// Check 1: every guard references a zone that exists.
    pub guards_in_zones: bool,
    /// Check 2: defence failover/cascade/mirror targets exist in registry.
    pub defence_targets_valid: bool,
    /// Check 3: zone transitions are monotonically increasing by X.
    pub zones_ordered: bool,
    /// Check 4: if PBX is enabled, its IP is in the device registry.
    pub pbx_consistent: bool,
    /// Check 5: every defence config IP exists in the device registry.
    pub devices_exist: bool,
    /// Human-readable error messages for each failed check.
    pub errors: Vec<String>,
}

// ---------------------------------------------------------------------------
// Filesystem helpers
// ---------------------------------------------------------------------------

/// Ensure the bridge directory exists, creating it lazily if needed.
///
/// Returns the canonical path to the bridge directory.
fn ensure_bridge_dir() -> Result<PathBuf, String> {
    let path = PathBuf::from(BRIDGE_DIR);
    fs::create_dir_all(&path)
        .map_err(|e| format!("Cannot create UMS bridge directory {BRIDGE_DIR}: {e}"))?;
    Ok(path)
}

/// Return the current UNIX timestamp in seconds.
fn now_ts() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

/// Derive a filesystem-safe filename from a level name.
///
/// Replaces non-alphanumeric characters (except hyphens and underscores)
/// with underscores, then appends `.json`.
fn level_filename(name: &str) -> String {
    let safe: String = name
        .chars()
        .map(|c| {
            if c.is_alphanumeric() || c == '-' || c == '_' {
                c
            } else {
                '_'
            }
        })
        .collect();
    format!("{safe}.json")
}

// ---------------------------------------------------------------------------
// Validation logic — mirrors idaptik-ums/src-tauri/src/commands.rs
// ---------------------------------------------------------------------------

/// Check whether an IP address exists in the device list.
///
/// This is the runtime equivalent of `InRegistry` in `src/abi/Validation.idr`.
fn ip_exists_in_devices(ip: &str, devices: &[DeviceSpec]) -> bool {
    devices.iter().any(|d| d.ip == ip)
}

/// Check 1: Every guard's zone field names a zone in the level.
///
/// Mirrors `Validation.GuardsInZones` (Idris2) and
/// `validate.checkGuardsInZones` (Zig).
fn check_guards_in_zones(level: &LevelData) -> (bool, Vec<String>) {
    let zone_names: Vec<&str> = level.zones.iter().map(|z| z.name.as_str()).collect();
    let mut errors = Vec::new();

    for guard in &level.guards {
        if !zone_names.contains(&guard.zone.as_str()) {
            errors.push(format!(
                "Guard (rank: {}) references non-existent zone '{}'",
                guard.rank, guard.zone
            ));
        }
    }

    (errors.is_empty(), errors)
}

/// Check 2: Defence failover/cascade/mirror targets reference real devices.
///
/// Mirrors `Validation.DefenceTargetsValid` (Idris2) and
/// `validate.checkDefenceTargetsValid` (Zig).
fn check_defence_targets_valid(level: &LevelData) -> (bool, Vec<String>) {
    let mut errors = Vec::new();

    for def in &level.device_defences {
        if let Some(ref ft) = def.flags.failover_target {
            if !ip_exists_in_devices(ft, &level.devices) {
                errors.push(format!(
                    "Defence on {} has failover_target '{}' not in device registry",
                    def.ip, ft
                ));
            }
        }
        if let Some(ref ct) = def.flags.cascade_trap {
            if !ip_exists_in_devices(ct, &level.devices) {
                errors.push(format!(
                    "Defence on {} has cascade_trap '{}' not in device registry",
                    def.ip, ct
                ));
            }
        }
        if let Some(ref mt) = def.flags.mirror_target {
            if !ip_exists_in_devices(mt, &level.devices) {
                errors.push(format!(
                    "Defence on {} has mirror_target '{}' not in device registry",
                    def.ip, mt
                ));
            }
        }
    }

    (errors.is_empty(), errors)
}

/// Check 3: Zone transitions are monotonically increasing by world X.
///
/// Mirrors `Validation.ZonesOrdered` (Idris2) and
/// `validate.checkZonesOrdered` (Zig).
fn check_zones_ordered(level: &LevelData) -> (bool, Vec<String>) {
    let mut errors = Vec::new();
    let transitions = &level.zone_transitions;

    if transitions.len() <= 1 {
        return (true, errors);
    }

    for i in 1..transitions.len() {
        if transitions[i].world_x < transitions[i - 1].world_x {
            errors.push(format!(
                "Zone transition {} (x={}) is before transition {} (x={}) — not monotonically ordered",
                i, transitions[i].world_x, i - 1, transitions[i - 1].world_x
            ));
        }
    }

    (errors.is_empty(), errors)
}

/// Check 4: PBX consistency — when enabled, the PBX IP must be in the registry.
///
/// Mirrors `Validation.PBXConsistent` (Idris2) and
/// `validate.checkPBXConsistent` (Zig).
fn check_pbx_consistent(level: &LevelData) -> (bool, Vec<String>) {
    let mut errors = Vec::new();

    if level.has_pbx {
        match &level.pbx_ip {
            Some(ip) => {
                if !ip_exists_in_devices(ip, &level.devices) {
                    errors.push(format!(
                        "PBX is enabled but pbx_ip '{}' is not in the device registry",
                        ip
                    ));
                }
            }
            None => {
                errors.push("PBX is enabled but pbx_ip is null".to_string());
            }
        }
    }

    (errors.is_empty(), errors)
}

/// Check 5: Every defence config's own IP exists in the device registry.
///
/// This is part of `DefenceTargetsValid` in Idris2 (the `InRegistry (ip d) devs`
/// premise), broken out as a separate check for clearer error messages.
fn check_devices_exist(level: &LevelData) -> (bool, Vec<String>) {
    let mut errors = Vec::new();

    for def in &level.device_defences {
        if !ip_exists_in_devices(&def.ip, &level.devices) {
            errors.push(format!(
                "Defence config references device '{}' which is not in the device registry",
                def.ip
            ));
        }
    }

    (errors.is_empty(), errors)
}

/// Run all five validation checks and produce a composite result.
///
/// This is the core validation function, usable without Tauri. It mirrors
/// `validate.validateLevel` in the Zig FFI and the `ValidatedLevel` record
/// in `src/abi/Validation.idr`.
///
/// # Arguments
///
/// * `level` — Reference to the level data to validate.
///
/// # Returns
///
/// A `ValidationResult` with per-check booleans and aggregated error messages.
pub fn validate_level_data(level: &LevelData) -> ValidationResult {
    let (giz, mut errs1) = check_guards_in_zones(level);
    let (dtv, mut errs2) = check_defence_targets_valid(level);
    let (zo, mut errs3) = check_zones_ordered(level);
    let (pbx, mut errs4) = check_pbx_consistent(level);
    let (de, mut errs5) = check_devices_exist(level);

    let mut all_errors = Vec::new();
    all_errors.append(&mut errs1);
    all_errors.append(&mut errs2);
    all_errors.append(&mut errs3);
    all_errors.append(&mut errs4);
    all_errors.append(&mut errs5);

    ValidationResult {
        valid: giz && dtv && zo && pbx && de,
        guards_in_zones: giz,
        defence_targets_valid: dtv,
        zones_ordered: zo,
        pbx_consistent: pbx,
        devices_exist: de,
        errors: all_errors,
    }
}

// ---------------------------------------------------------------------------
// Tauri commands — CartridgeAbi tool handlers for BoJ ums-mcp routing
// ---------------------------------------------------------------------------

/// Run the five ABI proof checks on level data JSON.
///
/// This is the primary validation entry point for the BoJ cartridge. The BoJ
/// runtime calls `invoke("ums_cartridge_validate", { level })` and receives
/// a `ValidationResult` with per-check booleans and error messages.
///
/// The five checks are:
///   1. `guards_in_zones` — all guards reference valid zones
///   2. `defence_targets_valid` — failover/cascade/mirror IPs exist
///   3. `zones_ordered` — zone transitions monotonically increase
///   4. `pbx_consistent` — PBX IP in registry when enabled
///   5. `devices_exist` — all defence config IPs in registry
///
/// # Arguments
///
/// * `level` — Level data as a JSON string (serialised `LevelData`).
///
/// # Returns
///
/// JSON string containing the `ValidationResult`, or an error if parsing fails.
#[tauri::command]
pub async fn ums_cartridge_validate(level: String) -> Result<String, String> {
    let level_data: LevelData = serde_json::from_str(&level)
        .map_err(|e| format!("Failed to parse level data for validation: {e}"))?;

    let result = validate_level_data(&level_data);
    let ts = now_ts().to_string();

    let output = json!({
        "valid": result.valid,
        "guardsInZones": result.guards_in_zones,
        "defenceTargetsValid": result.defence_targets_valid,
        "zonesOrdered": result.zones_ordered,
        "pbxConsistent": result.pbx_consistent,
        "devicesExist": result.devices_exist,
        "errors": result.errors,
        "validatedAt": ts,
        "source": "ums-cartridge",
    });

    serde_json::to_string(&output)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Load level JSON from the shared bridge directory.
///
/// Reads a level file by name from `/tmp/panll/ums-bridge/` and returns its
/// contents as a JSON string. If the name is an absolute path, that path is
/// used directly.
///
/// # Arguments
///
/// * `name` — Level name (filename stem) or absolute path to the level JSON.
///
/// # Returns
///
/// The level JSON as a string, or an error if the file cannot be read.
#[tauri::command]
pub async fn ums_cartridge_load_level(name: String) -> Result<String, String> {
    let file_path = if std::path::Path::new(&name).is_absolute() {
        PathBuf::from(&name)
    } else {
        let dir = ensure_bridge_dir()?;
        dir.join(level_filename(&name))
    };

    if !file_path.exists() {
        return Err(format!(
            "Level not found: '{}'  (looked at {})",
            name,
            file_path.display()
        ));
    }

    fs::read_to_string(&file_path)
        .map_err(|e| format!("Failed to read level file '{}': {e}", file_path.display()))
}

/// Save level JSON to the shared bridge directory.
///
/// Writes the provided level data to `/tmp/panll/ums-bridge/`, deriving the
/// filename from the level's `name` field. Returns the path where the file
/// was written.
///
/// # Arguments
///
/// * `level` — Level data as a JSON string.
///
/// # Returns
///
/// JSON object with `saved: true` and the file path, or an error.
#[tauri::command]
pub async fn ums_cartridge_save_level(level: String) -> Result<String, String> {
    let dir = ensure_bridge_dir()?;

    let parsed: Value = serde_json::from_str(&level)
        .map_err(|e| format!("Failed to parse level JSON: {e}"))?;

    let name = parsed
        .get("name")
        .and_then(|v| v.as_str())
        .ok_or_else(|| "Level data must have a 'name' field".to_string())?;

    let file_path = dir.join(level_filename(name));

    let pretty = serde_json::to_string_pretty(&parsed)
        .map_err(|e| format!("Failed to serialise level: {e}"))?;

    fs::write(&file_path, &pretty)
        .map_err(|e| format!("Failed to write level file: {e}"))?;

    let result = json!({
        "saved": true,
        "name": name,
        "path": file_path.display().to_string(),
        "savedAt": now_ts().to_string(),
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// List available levels in the shared bridge directory.
///
/// Scans `/tmp/panll/ums-bridge/` for `.json` files and returns an array of
/// objects with `name` and `path` fields.
///
/// # Returns
///
/// JSON array of `{ name, path }` objects, or an error.
#[tauri::command]
pub async fn ums_cartridge_list_levels() -> Result<String, String> {
    let dir = ensure_bridge_dir()?;

    let entries: Vec<Value> = fs::read_dir(&dir)
        .map_err(|e| format!("Failed to read bridge directory: {e}"))?
        .filter_map(|entry| {
            let entry = entry.ok()?;
            let path = entry.path();
            if path.extension()?.to_str()? == "json" {
                let name = path.file_stem()?.to_str()?.to_string();
                Some(json!({
                    "name": name,
                    "path": path.display().to_string(),
                }))
            } else {
                None
            }
        })
        .collect();

    serde_json::to_string(&entries)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Generate a ReScript LevelConfig from level data.
///
/// Takes level JSON and produces a ReScript source string that defines a
/// `LevelConfig` value matching `src/LevelConfigTypes.res.mjs`. This is used
/// for embedding level data directly into the game client.
///
/// # Arguments
///
/// * `level` — Level data as a JSON string (serialised `LevelData`).
///
/// # Returns
///
/// ReScript source code as a string, or an error if parsing fails.
#[tauri::command]
pub async fn ums_cartridge_export_config(level: String) -> Result<String, String> {
    let level_data: LevelData = serde_json::from_str(&level)
        .map_err(|e| format!("Failed to parse level for export: {e}"))?;

    let mut out = String::new();

    out.push_str("// SPDX-License-Identifier: PMPL-1.0-or-later\n");
    out.push_str("// Generated by PanLL UMS Cartridge — do not edit manually.\n\n");

    // Derive a ReScript-safe binding name from the level name.
    let safe_name: String = level_data
        .name
        .replace(|c: char| !c.is_alphanumeric() && c != '_', "_");

    out.push_str(&format!("let levelConfig_{safe_name} = {{\n"));
    out.push_str(&format!("  name: \"{}\",\n", level_data.name));
    out.push_str(&format!(
        "  deviceCount: {},\n",
        level_data.devices.len()
    ));
    out.push_str(&format!(
        "  zoneCount: {},\n",
        level_data.zones.len()
    ));
    out.push_str(&format!(
        "  guardCount: {},\n",
        level_data.guards.len()
    ));
    out.push_str(&format!("  hasPbx: {},\n", level_data.has_pbx));

    // Embed device IPs for quick reference.
    out.push_str("  devices: [\n");
    for dev in &level_data.devices {
        out.push_str(&format!(
            "    {{ ip: \"{}\", kind: \"{}\" }},\n",
            dev.ip, dev.kind
        ));
    }
    out.push_str("  ],\n");

    // Embed zone names.
    out.push_str("  zones: [\n");
    for zone in &level_data.zones {
        out.push_str(&format!("    \"{}\",\n", zone.name));
    }
    out.push_str("  ],\n");

    out.push_str("}\n");

    Ok(out)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create a tokio runtime for async command tests.
    ///
    /// Uses a single-threaded runtime to keep tests deterministic. Each test
    /// that calls an `async fn` command wraps it in `rt().block_on(...)`.
    fn rt() -> tokio::runtime::Runtime {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("Failed to create tokio runtime for tests")
    }

    /// Helper: clean up a test level file from the bridge directory.
    fn cleanup_bridge_level(name: &str) {
        let path = PathBuf::from(BRIDGE_DIR).join(level_filename(name));
        let _ = fs::remove_file(path);
    }

    /// Helper: remove all JSON files from the bridge directory.
    ///
    /// Called before tests that assert on file counts to ensure a clean slate.
    fn cleanup_bridge_dir() {
        let dir = PathBuf::from(BRIDGE_DIR);
        if let Ok(entries) = fs::read_dir(&dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.extension().and_then(|e| e.to_str()) == Some("json") {
                    let _ = fs::remove_file(path);
                }
            }
        }
    }

    /// Helper: build a minimal valid level for testing.
    ///
    /// Contains 3 devices, 2 zones, 1 guard, 2 ordered transitions,
    /// 1 defence config with a valid failover target, and a PBX whose IP
    /// is in the device registry.
    fn make_valid_level() -> LevelData {
        LevelData {
            name: "cartridge_test_level".to_string(),
            devices: vec![
                DeviceSpec {
                    ip: "192.168.1.1".to_string(),
                    kind: "server".to_string(),
                    label: Some("Main Server".to_string()),
                },
                DeviceSpec {
                    ip: "192.168.1.2".to_string(),
                    kind: "router".to_string(),
                    label: Some("Edge Router".to_string()),
                },
                DeviceSpec {
                    ip: "192.168.1.3".to_string(),
                    kind: "laptop".to_string(),
                    label: None,
                },
            ],
            zones: vec![
                Zone {
                    name: "lobby".to_string(),
                },
                Zone {
                    name: "server_room".to_string(),
                },
            ],
            guards: vec![GuardPlacement {
                zone: "lobby".to_string(),
                rank: "basic_guard".to_string(),
            }],
            zone_transitions: vec![
                ZoneTransition {
                    world_x: 0.0,
                    target_zone: "lobby".to_string(),
                },
                ZoneTransition {
                    world_x: 500.0,
                    target_zone: "server_room".to_string(),
                },
            ],
            device_defences: vec![DeviceDefenceConfig {
                ip: "192.168.1.1".to_string(),
                flags: DefenceFlags {
                    failover_target: Some("192.168.1.2".to_string()),
                    cascade_trap: None,
                    mirror_target: None,
                },
            }],
            has_pbx: true,
            pbx_ip: Some("192.168.1.3".to_string()),
        }
    }

    // -- Validation unit tests (pure, no async) ----------------------------

    #[test]
    fn test_valid_level_passes_all_five_proofs() {
        let level = make_valid_level();
        let result = validate_level_data(&level);

        assert!(result.valid, "Valid level should pass all checks");
        assert!(result.guards_in_zones, "GuardsInZones should pass");
        assert!(result.defence_targets_valid, "DefenceTargetsValid should pass");
        assert!(result.zones_ordered, "ZonesOrdered should pass");
        assert!(result.pbx_consistent, "PBXConsistent should pass");
        assert!(result.devices_exist, "DevicesExist should pass");
        assert!(result.errors.is_empty(), "No errors expected for valid level");
    }

    #[test]
    fn test_invalid_zone_reference_fails_guards_in_zones() {
        let mut level = make_valid_level();
        level.guards.push(GuardPlacement {
            zone: "phantom_zone".to_string(),
            rank: "enforcer".to_string(),
        });

        let result = validate_level_data(&level);

        assert!(!result.valid, "Should fail with invalid guard zone reference");
        assert!(!result.guards_in_zones, "GuardsInZones should fail");
        assert!(
            result.errors.iter().any(|e| e.contains("phantom_zone")),
            "Error should mention the non-existent zone name"
        );
        // Other checks should still pass.
        assert!(result.defence_targets_valid);
        assert!(result.zones_ordered);
        assert!(result.pbx_consistent);
        assert!(result.devices_exist);
    }

    #[test]
    fn test_out_of_order_zones_fails_zones_ordered() {
        let mut level = make_valid_level();
        level.zone_transitions = vec![
            ZoneTransition {
                world_x: 500.0,
                target_zone: "server_room".to_string(),
            },
            ZoneTransition {
                world_x: 100.0,
                target_zone: "lobby".to_string(),
            },
        ];

        let result = validate_level_data(&level);

        assert!(!result.valid, "Should fail with unordered transitions");
        assert!(!result.zones_ordered, "ZonesOrdered should fail");
        assert!(
            result.errors.iter().any(|e| e.contains("not monotonically ordered")),
            "Error should describe the ordering violation"
        );
    }

    #[test]
    fn test_missing_pbx_ip_fails_pbx_consistent() {
        let mut level = make_valid_level();
        level.has_pbx = true;
        level.pbx_ip = Some("10.0.0.99".to_string()); // Not in device registry.

        let result = validate_level_data(&level);

        assert!(!result.valid, "Should fail with PBX IP not in registry");
        assert!(!result.pbx_consistent, "PBXConsistent should fail");
        assert!(
            result.errors.iter().any(|e| e.contains("10.0.0.99")),
            "Error should mention the missing PBX IP"
        );
    }

    #[test]
    fn test_pbx_enabled_but_null_ip_fails() {
        let mut level = make_valid_level();
        level.has_pbx = true;
        level.pbx_ip = None;

        let result = validate_level_data(&level);

        assert!(!result.valid, "Should fail with null PBX IP");
        assert!(!result.pbx_consistent);
        assert!(
            result.errors.iter().any(|e| e.contains("pbx_ip is null")),
            "Error should note the null PBX IP"
        );
    }

    #[test]
    fn test_pbx_disabled_skips_check() {
        let mut level = make_valid_level();
        level.has_pbx = false;
        level.pbx_ip = Some("10.0.0.99".to_string()); // Not in registry, but PBX is off.

        let result = validate_level_data(&level);
        assert!(result.pbx_consistent, "PBX check should pass when PBX is disabled");
    }

    #[test]
    fn test_defence_failover_target_missing_from_registry() {
        let mut level = make_valid_level();
        level.device_defences.push(DeviceDefenceConfig {
            ip: "192.168.1.1".to_string(),
            flags: DefenceFlags {
                failover_target: Some("10.99.99.99".to_string()),
                cascade_trap: None,
                mirror_target: None,
            },
        });

        let result = validate_level_data(&level);

        assert!(!result.valid, "Should fail with missing failover target");
        assert!(!result.defence_targets_valid);
        assert!(result.errors.iter().any(|e| e.contains("10.99.99.99")));
    }

    #[test]
    fn test_defence_config_ip_not_in_registry() {
        let mut level = make_valid_level();
        level.device_defences.push(DeviceDefenceConfig {
            ip: "10.0.0.50".to_string(),
            flags: DefenceFlags::default(),
        });

        let result = validate_level_data(&level);

        assert!(!result.valid, "Should fail with defence IP not in registry");
        assert!(!result.devices_exist, "DevicesExist should fail");
        assert!(result.errors.iter().any(|e| e.contains("10.0.0.50")));
    }

    #[test]
    fn test_empty_level_is_trivially_valid() {
        let level = LevelData {
            name: "empty".to_string(),
            devices: vec![],
            zones: vec![],
            guards: vec![],
            zone_transitions: vec![],
            device_defences: vec![],
            has_pbx: false,
            pbx_ip: None,
        };

        let result = validate_level_data(&level);
        assert!(result.valid, "Empty level should be trivially valid");
        assert!(result.errors.is_empty());
    }

    #[test]
    fn test_multiple_proofs_can_fail_simultaneously() {
        let mut level = make_valid_level();

        // Break guards_in_zones.
        level.guards.push(GuardPlacement {
            zone: "GHOST_ZONE".to_string(),
            rank: "enforcer".to_string(),
        });

        // Break zones_ordered.
        level.zone_transitions = vec![
            ZoneTransition { world_x: 999.0, target_zone: "server_room".to_string() },
            ZoneTransition { world_x: 1.0, target_zone: "lobby".to_string() },
        ];

        // Break pbx_consistent.
        level.has_pbx = true;
        level.pbx_ip = Some("10.0.0.1".to_string());

        let result = validate_level_data(&level);

        assert!(!result.valid);
        assert!(!result.guards_in_zones);
        assert!(!result.zones_ordered);
        assert!(!result.pbx_consistent);
        assert!(result.errors.len() >= 3, "Should have at least 3 errors");
    }

    // -- Tauri command integration tests (async) ---------------------------

    #[test]
    fn test_ums_cartridge_validate_valid_level() {
        rt().block_on(async {
            let level = make_valid_level();
            let json_str = serde_json::to_string(&level).unwrap();

            let result = ums_cartridge_validate(json_str).await;
            assert!(result.is_ok(), "Validate command should succeed");

            let parsed: Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(parsed["valid"], true);
            assert_eq!(parsed["guardsInZones"], true);
            assert_eq!(parsed["defenceTargetsValid"], true);
            assert_eq!(parsed["zonesOrdered"], true);
            assert_eq!(parsed["pbxConsistent"], true);
            assert_eq!(parsed["devicesExist"], true);
            assert_eq!(parsed["source"], "ums-cartridge");
        });
    }

    #[test]
    fn test_ums_cartridge_validate_invalid_json() {
        rt().block_on(async {
            let result = ums_cartridge_validate("not valid json!!!".to_string()).await;
            assert!(result.is_err(), "Should fail on invalid JSON");
            assert!(result.unwrap_err().contains("Failed to parse"));
        });
    }

    #[test]
    fn test_save_and_load_roundtrip() {
        rt().block_on(async {
            let level = make_valid_level();
            let json_str = serde_json::to_string_pretty(&level).unwrap();

            // Save the level.
            let save_result = ums_cartridge_save_level(json_str.clone()).await;
            assert!(save_result.is_ok(), "Save should succeed");

            let save_parsed: Value = serde_json::from_str(&save_result.unwrap()).unwrap();
            assert_eq!(save_parsed["saved"], true);
            assert_eq!(save_parsed["name"], "cartridge_test_level");

            // Load it back.
            let load_result =
                ums_cartridge_load_level("cartridge_test_level".to_string()).await;
            assert!(load_result.is_ok(), "Load should succeed after save");

            let loaded: LevelData = serde_json::from_str(&load_result.unwrap()).unwrap();
            assert_eq!(loaded.name, "cartridge_test_level");
            assert_eq!(loaded.devices.len(), 3);
            assert_eq!(loaded.zones.len(), 2);

            cleanup_bridge_level("cartridge_test_level");
        });
    }

    #[test]
    fn test_load_level_not_found() {
        rt().block_on(async {
            let result =
                ums_cartridge_load_level("nonexistent_level_12345".to_string()).await;
            assert!(result.is_err(), "Should fail for missing level");
            assert!(result.unwrap_err().contains("Level not found"));
        });
    }

    #[test]
    fn test_list_levels_returns_saved_files() {
        rt().block_on(async {
            cleanup_bridge_dir();

            // Save two levels.
            let mut level_a = make_valid_level();
            level_a.name = "list_test_alpha".to_string();
            let mut level_b = make_valid_level();
            level_b.name = "list_test_bravo".to_string();

            let _ = ums_cartridge_save_level(serde_json::to_string(&level_a).unwrap()).await;
            let _ = ums_cartridge_save_level(serde_json::to_string(&level_b).unwrap()).await;

            // List levels.
            let list_result = ums_cartridge_list_levels().await;
            assert!(list_result.is_ok(), "List should succeed");

            let entries: Vec<Value> = serde_json::from_str(&list_result.unwrap()).unwrap();
            assert!(
                entries.len() >= 2,
                "Should find at least 2 levels, got {}",
                entries.len()
            );

            let names: Vec<&str> = entries
                .iter()
                .filter_map(|e| e["name"].as_str())
                .collect();
            assert!(names.contains(&"list_test_alpha"), "Should find list_test_alpha");
            assert!(names.contains(&"list_test_bravo"), "Should find list_test_bravo");

            cleanup_bridge_level("list_test_alpha");
            cleanup_bridge_level("list_test_bravo");
        });
    }

    #[test]
    fn test_export_config_produces_rescript_output() {
        rt().block_on(async {
            let level = make_valid_level();
            let json_str = serde_json::to_string(&level).unwrap();

            let result = ums_cartridge_export_config(json_str).await;
            assert!(result.is_ok(), "Export should succeed");

            let output = result.unwrap();
            assert!(
                output.contains("SPDX-License-Identifier: PMPL-1.0-or-later"),
                "Export should contain SPDX header"
            );
            assert!(
                output.contains("levelConfig_cartridge_test_level"),
                "Export should contain the level config binding name"
            );
            assert!(
                output.contains("192.168.1.1"),
                "Export should embed device IPs"
            );
            assert!(
                output.contains("\"lobby\""),
                "Export should embed zone names"
            );
            assert!(
                output.contains("hasPbx: true"),
                "Export should include PBX flag"
            );
            assert!(
                output.contains("UMS Cartridge"),
                "Export should credit the cartridge generator"
            );
        });
    }

    #[test]
    fn test_export_config_invalid_json() {
        rt().block_on(async {
            let result = ums_cartridge_export_config("{{bad}}".to_string()).await;
            assert!(result.is_err(), "Should fail on invalid JSON");
        });
    }
}
