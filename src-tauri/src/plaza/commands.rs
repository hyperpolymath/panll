// SPDX-License-Identifier: PMPL-1.0-or-later

//! Palimpsest Plaza Tauri commands — scan repos for PMPL compliance,
//! compute adoption statistics, and check license compatibility.
//!
//! Commands:
//!   - `plaza_scan_repo`: Scan a single repo for PMPL compliance.
//!   - `plaza_adoption_stats`: Compute adoption statistics across the ecosystem.
//!   - `plaza_check_compatibility`: Check if PMPL is compatible with a given license.

use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use super::types::*;

/// The canonical repos directory (via symlink).
fn repos_dir() -> PathBuf {
    let home = dirs::home_dir().unwrap_or_default();
    home.join("Documents").join("hyperpolymath-repos")
}

/// Check if a file contains an SPDX-License-Identifier header.
fn has_spdx_header(path: &Path) -> Option<String> {
    let content = fs::read_to_string(path).ok()?;
    // Only check the first 20 lines for performance.
    for line in content.lines().take(20) {
        if line.contains("SPDX-License-Identifier:") {
            let id = line
                .split("SPDX-License-Identifier:")
                .nth(1)?
                .trim()
                .to_string();
            return Some(id);
        }
    }
    None
}

/// Detect the license type from a LICENSE or LICENSE.txt file.
fn detect_license(repo_path: &Path) -> Option<String> {
    for name in &["LICENSE", "LICENSE.txt", "LICENSE.md", "COPYING"] {
        let path = repo_path.join(name);
        if let Ok(content) = fs::read_to_string(&path) {
            let lower = content.to_lowercase();
            if lower.contains("palimpsest") || lower.contains("pmpl") {
                return Some("PMPL-1.0-or-later".to_string());
            } else if lower.contains("mozilla public license") {
                return Some("MPL-2.0".to_string());
            } else if lower.contains("mit license") || lower.contains("permission is hereby granted") {
                return Some("MIT".to_string());
            } else if lower.contains("apache license") {
                return Some("Apache-2.0".to_string());
            } else if lower.contains("gnu general public license") {
                if lower.contains("version 3") {
                    return Some("GPL-3.0".to_string());
                }
                return Some("GPL-2.0".to_string());
            } else if lower.contains("bsd") {
                return Some("BSD".to_string());
            }
        }
    }
    None
}

/// Source file extensions to scan for SPDX headers.
const SOURCE_EXTENSIONS: &[&str] = &[
    "rs", "res", "resi", "gleam", "ex", "exs", "idr", "zig",
    "ml", "mli", "hs", "adb", "ads", "jl", "sh", "bash",
    "js", "mjs", "jsx", "ts", "tsx", "json", "toml", "yaml", "yml",
    "nix", "scm", "ncl", "v", "go", "py", "rb", "java", "kt",
    "c", "h", "cpp", "hpp", "swift", "lua", "dart", "php",
];

/// Check if a path is a source file worth scanning.
fn is_source_file(path: &Path) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|ext| SOURCE_EXTENSIONS.contains(&ext))
        .unwrap_or(false)
}

/// Scan a single repo directory for PMPL compliance indicators.
fn scan_repo(repo_path: &Path) -> RepoScanResult {
    let repo_name = repo_path
        .file_name()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();

    let license_type = detect_license(repo_path);
    let has_license_file = license_type.is_some();

    // Check for exhibits.
    let has_exhibit_a = repo_path.join("EXHIBIT-A-ETHICAL-USE.txt").exists()
        || repo_path.join("legal").join("exhibits").join("EXHIBIT-A-ETHICAL-USE.txt").exists()
        || repo_path.join("v1.0").join("exhibits").join("EXHIBIT-A-ETHICAL-USE.txt").exists();

    let has_exhibit_b = repo_path.join("EXHIBIT-B-QUANTUM-SAFE.txt").exists()
        || repo_path.join("legal").join("exhibits").join("EXHIBIT-B-QUANTUM-SAFE.txt").exists()
        || repo_path.join("v1.0").join("exhibits").join("EXHIBIT-B-QUANTUM-SAFE.txt").exists();

    // Check for provenance signatures.
    let has_provenance_sig = repo_path.join(".provenance").exists()
        || repo_path.join("PROVENANCE.sig").exists();

    // Count source files and SPDX headers (limited depth for speed).
    let mut total_source = 0u32;
    let mut with_header = 0u32;

    if let Ok(entries) = fs::read_dir(repo_path) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_file() && is_source_file(&path) {
                total_source += 1;
                if has_spdx_header(&path).is_some() {
                    with_header += 1;
                }
            }
            // One level of subdirectories (src/, lib/, etc.).
            if path.is_dir() {
                let dirname = path.file_name().unwrap_or_default().to_string_lossy();
                // Skip hidden dirs, node_modules, target, etc.
                if dirname.starts_with('.') || dirname == "node_modules" || dirname == "target"
                    || dirname == "_build" || dirname == "dist" || dirname == "build"
                {
                    continue;
                }
                if let Ok(sub_entries) = fs::read_dir(&path) {
                    for sub in sub_entries.flatten() {
                        let sp = sub.path();
                        if sp.is_file() && is_source_file(&sp) {
                            total_source += 1;
                            if has_spdx_header(&sp).is_some() {
                                with_header += 1;
                            }
                        }
                    }
                }
            }
        }
    }

    RepoScanResult {
        repo_name,
        has_license_file,
        license_type,
        spdx_header_count: with_header,
        total_source_files: total_source,
        has_exhibit_a,
        has_exhibit_b,
        has_provenance_sig,
    }
}

/// Scan a single repository for PMPL compliance.
///
/// Takes a repo name and scans its directory under the canonical repos path.
/// Returns a JSON-serialised `RepoScanResult`.
#[tauri::command]
pub async fn plaza_scan_repo(repo_name: String) -> Result<String, String> {
    let repo_path = repos_dir().join(&repo_name);
    if !repo_path.exists() {
        return Err(format!("Repository not found: {repo_name}"));
    }

    let result = scan_repo(&repo_path);
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Compute adoption statistics across the entire ecosystem.
///
/// Scans all directories under the canonical repos path and aggregates
/// license detection results. Returns JSON-serialised `AdoptionStats`.
#[tauri::command]
pub async fn plaza_adoption_stats() -> Result<String, String> {
    let base = repos_dir();
    if !base.exists() {
        return Err("Repos directory not found".to_string());
    }

    let mut total = 0u32;
    let mut pmpl = 0u32;
    let mut mpl_fallback = 0u32;
    let mut unlicensed = 0u32;
    let mut quantum_signed = 0u32;
    let mut by_license: HashMap<String, u32> = HashMap::new();

    let entries = fs::read_dir(&base)
        .map_err(|e| format!("Cannot read repos dir: {e}"))?;

    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }
        // Skip hidden directories (like .git-private-farm).
        let name = path.file_name().unwrap_or_default().to_string_lossy();
        if name.starts_with('.') {
            continue;
        }

        total += 1;
        let result = scan_repo(&path);

        match &result.license_type {
            Some(lic) => {
                *by_license.entry(lic.clone()).or_insert(0) += 1;
                if lic.contains("PMPL") {
                    pmpl += 1;
                } else if lic.contains("MPL") {
                    mpl_fallback += 1;
                }
            }
            None => {
                unlicensed += 1;
                *by_license.entry("unlicensed".to_string()).or_insert(0) += 1;
            }
        }

        if result.has_provenance_sig {
            quantum_signed += 1;
        }
    }

    let stats = AdoptionStats {
        total_repos: total,
        pmpl_repos: pmpl,
        mpl_fallback_repos: mpl_fallback,
        unlicensed_repos: unlicensed,
        quantum_signed_repos: quantum_signed,
        by_license,
    };

    serde_json::to_string(&stats)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Known compatibility matrix for PMPL with common licenses.
/// PMPL-1.0 is file-level copyleft (like MPL-2.0), so it's compatible
/// with most permissive and weak-copyleft licenses.
#[tauri::command]
pub async fn plaza_check_compatibility(license: String) -> Result<String, String> {
    let (compatible, notes) = match license.to_uppercase().as_str() {
        "MIT" => (true, "Fully compatible. MIT files can coexist with PMPL files in the same project."),
        "BSD-2-CLAUSE" | "BSD-3-CLAUSE" | "BSD" => (true, "Fully compatible. BSD files can coexist with PMPL files."),
        "APACHE-2.0" => (true, "Compatible. Apache-2.0 patent grant complements PMPL."),
        "MPL-2.0" => (true, "Fully compatible. PMPL is built on MPL-2.0 as its base layer."),
        "LGPL-2.1" | "LGPL-2.1-OR-LATER" | "LGPL-3.0" | "LGPL-3.0-OR-LATER" => {
            (true, "Compatible for library use. LGPL files may impose dynamic linking requirements.")
        }
        "GPL-2.0" | "GPL-2.0-OR-LATER" => {
            (true, "Compatible per MPL-2.0 Section 3.3. GPL may apply to combined work.")
        }
        "GPL-3.0" | "GPL-3.0-OR-LATER" => {
            (true, "Compatible per MPL-2.0 Section 3.3. GPL-3.0 applies to combined work.")
        }
        "AGPL-3.0" | "AGPL-3.0-OR-LATER" => {
            (false, "Not directly compatible. AGPL network copyleft conflicts with PMPL file-level scope.")
        }
        "CC0-1.0" | "UNLICENSE" => {
            (true, "Compatible. Public domain dedications can coexist with any license.")
        }
        "ISC" => (true, "Fully compatible. ISC is functionally equivalent to MIT."),
        "WTFPL" => (true, "Compatible. Permissive license with no restrictions."),
        _ => (false, "Unknown license. Manual compatibility review recommended."),
    };

    let result = serde_json::json!({
        "license": license,
        "compatible": compatible,
        "notes": notes,
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}
