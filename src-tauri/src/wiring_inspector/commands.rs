// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Wiring Inspector Commands — Tauri command handlers for PCC invocation.
//!
//! Commands:
//!   - `wiring_inspector_verify`: Run PCC against all panel contracts.
//!   - `wiring_inspector_verify_panel`: Run PCC against a single panel contract.
//!
//! The PCC binary is expected at `tools/pcc/target/release/panll` relative
//! to the repository root. The repo root is resolved from the Tauri
//! resource directory or the current working directory.

use std::env;
use std::path::PathBuf;
use std::process::Command;

/// Resolve the repository root path.
///
/// Checks `PANLL_REPO_ROOT` environment variable first, then falls back
/// to the current working directory.
fn repo_root() -> Result<PathBuf, String> {
    if let Ok(root) = env::var("PANLL_REPO_ROOT") {
        let p = PathBuf::from(&root);
        if p.exists() {
            return Ok(p);
        }
    }

    // Fall back to current working directory
    env::current_dir().map_err(|e| format!("Cannot determine repo root: {e}"))
}

/// Resolve the PCC binary path.
///
/// Looks for `tools/pcc/target/release/panll` under the repo root.
/// Falls back to `tools/pcc/target/debug/panll` if release not found.
fn pcc_binary() -> Result<PathBuf, String> {
    let root = repo_root()?;

    let release_path = root.join("tools/pcc/target/release/panll");
    if release_path.exists() {
        return Ok(release_path);
    }

    let debug_path = root.join("tools/pcc/target/debug/panll");
    if debug_path.exists() {
        return Ok(debug_path);
    }

    Err(format!(
        "PCC binary not found. Expected at {} or {}. Build with: cd tools/pcc && cargo build --release",
        release_path.display(),
        debug_path.display()
    ))
}

/// Run PCC verification against all panel contracts.
///
/// Executes the PCC binary with `--json --repo-root <path>` flags and
/// returns the JSON stdout directly. The frontend parses the JSON using
/// `WiringInspectorEngine.parseVerificationJson`.
///
/// # Errors
///
/// Returns an error string if:
/// - The PCC binary is not found
/// - The subprocess fails to start
/// - The subprocess exits with a non-zero code
#[tauri::command]
pub async fn wiring_inspector_verify() -> Result<String, String> {
    let binary = pcc_binary()?;
    let root = repo_root()?;

    let output = Command::new(&binary)
        .arg("panel")
        .arg("verify")
        .arg("--json")
        .arg("--repo-root")
        .arg(root.to_string_lossy().as_ref())
        .output()
        .map_err(|e| format!("Failed to execute PCC: {e}"))?;

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        if stdout.trim().is_empty() {
            // PCC succeeded but produced no output — return empty array
            Ok("[]".to_string())
        } else {
            Ok(stdout)
        }
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        let code = output.status.code().unwrap_or(-1);
        Err(format!("PCC exited with code {code}: {stderr}"))
    }
}

/// Run PCC verification against a single panel contract.
///
/// Executes the PCC binary with `--json --repo-root <path> --panel <id>`
/// and returns the JSON stdout.
///
/// # Arguments
///
/// * `panel_id` - The panel identifier to verify (e.g. "WiringInspector").
#[tauri::command]
pub async fn wiring_inspector_verify_panel(panel_id: String) -> Result<String, String> {
    let binary = pcc_binary()?;
    let root = repo_root()?;

    let output = Command::new(&binary)
        .arg("panel")
        .arg("verify")
        .arg("--json")
        .arg("--repo-root")
        .arg(root.to_string_lossy().as_ref())
        .arg("--panel")
        .arg(&panel_id)
        .output()
        .map_err(|e| format!("Failed to execute PCC for panel {panel_id}: {e}"))?;

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        if stdout.trim().is_empty() {
            Ok("[]".to_string())
        } else {
            Ok(stdout)
        }
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        let code = output.status.code().unwrap_or(-1);
        Err(format!("PCC exited with code {code} for panel {panel_id}: {stderr}"))
    }
}
