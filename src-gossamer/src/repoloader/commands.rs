// SPDX-License-Identifier: MPL-2.0

//! Repo Loader Tauri Commands — exposed to the ReScript frontend.
//!
//! Commands:
//!   - `repoloader_scan`: Scan a repo and return info + panel suggestions.
//!   - `repoloader_save_panels`: Save panel config to PANELS.a2ml.
//!   - `repoloader_list_recent`: List recently loaded repos.
//!   - `repoloader_search_farm`: Search the git-private-farm for repos.

use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use super::scanner;
use super::types::*;

/// Resolve the recent repos file: `~/.config/panll/recent-repos.json`.
fn recent_repos_path() -> Result<PathBuf, String> {
    let config_dir = dirs::config_dir().ok_or("Cannot determine config directory")?;
    Ok(config_dir.join("panll").join("recent-repos.json"))
}

/// Load recent repos from disk.
fn load_recent() -> RecentReposFile {
    let path = match recent_repos_path() {
        Ok(p) => p,
        Err(_) => return RecentReposFile { repos: vec![] },
    };
    if !path.exists() {
        return RecentReposFile { repos: vec![] };
    }
    fs::read_to_string(&path)
        .ok()
        .and_then(|content| serde_json::from_str(&content).ok())
        .unwrap_or(RecentReposFile { repos: vec![] })
}

/// Save recent repos to disk.
fn save_recent(recent: &RecentReposFile) -> Result<(), String> {
    let path = recent_repos_path()?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Cannot create config directory: {e}"))?;
    }
    let json = serde_json::to_string_pretty(recent)
        .map_err(|e| format!("Cannot serialise recent repos: {e}"))?;
    fs::write(&path, json).map_err(|e| format!("Cannot write recent repos: {e}"))
}

/// Add a repo to the recent list (front of queue, max 20 entries).
fn update_recent(repo_path: &str, repo_name: &str) -> Result<(), String> {
    let mut recent = load_recent();

    // Remove existing entry for this path.
    recent.repos.retain(|r| r.path != repo_path);

    // Add to front.
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();

    recent.repos.insert(
        0,
        RecentRepo {
            path: repo_path.to_string(),
            name: repo_name.to_string(),
            last_loaded: now,
        },
    );

    // Keep max 20 entries.
    recent.repos.truncate(20);

    save_recent(&recent)
}

/// Scan a repository directory and return information + panel suggestions.
///
/// If the repo has a `.machine_readable/PANELS.a2ml`, parses it and returns
/// the saved config. Otherwise, generates fresh suggestions from scan data.

pub async fn repoloader_scan(repo_path: String) -> Result<String, String> {
    let path = PathBuf::from(&repo_path);
    let repo = scanner::scan_repo(&path)?;

    // Update recent repos list.
    let _ = update_recent(&repo_path, &repo.name);

    // Check for existing PANELS.a2ml.
    let panels_path = path.join(".machine_readable").join("PANELS.a2ml");
    let suggestions = if panels_path.exists() {
        // Parse existing manifest and convert to suggestions.
        let content = fs::read_to_string(&panels_path)
            .map_err(|e| format!("Cannot read PANELS.a2ml: {e}"))?;
        if let Some(manifest) = scanner::parse_panels_manifest(&content) {
            manifest
                .panels
                .iter()
                .map(|p| PanelSuggestion {
                    panel_name: p.name.clone(),
                    reason: "From saved PANELS.a2ml configuration".to_string(),
                    priority: p.priority.clone(),
                    enabled: p.enabled,
                })
                .collect()
        } else {
            scanner::suggest_panels(&repo)
        }
    } else {
        scanner::suggest_panels(&repo)
    };

    let result = ScanResult { repo, suggestions };
    serde_json::to_string(&result).map_err(|e| format!("Serialisation error: {e}"))
}

/// Save panel configuration to `.machine_readable/PANELS.a2ml`.
///
/// Takes the repo path and a JSON array of panel entries.

pub async fn repoloader_save_panels(
    repo_path: String,
    panels_json: String,
) -> Result<String, String> {
    let path = PathBuf::from(&repo_path);
    let mr_dir = path.join(".machine_readable");

    // Ensure .machine_readable/ exists.
    fs::create_dir_all(&mr_dir)
        .map_err(|e| format!("Cannot create .machine_readable/: {e}"))?;

    // Parse the panels from JSON.
    let panels: Vec<PanelEntry> = serde_json::from_str(&panels_json)
        .map_err(|e| format!("Cannot parse panels JSON: {e}"))?;

    let repo_name = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown");

    // Generate PANELS.a2ml in S-expression format.
    let mut output = String::new();
    output.push_str(";; .machine_readable/PANELS.a2ml — portable panel inventory\n");
    output.push_str(";; Any tool can parse this. PanLL is one consumer, not the gatekeeper.\n");
    output.push_str("(panel-inventory\n");
    output.push_str("  (version \"1.0\")\n");
    output.push_str(&format!("  (repo \"{}\")\n", repo_name));
    output.push_str("  (panels\n");
    for panel in &panels {
        output.push_str(&format!(
            "    (panel \"{}\"  (enabled {})  (priority \"{}\"))\n",
            panel.name,
            if panel.enabled { "true" } else { "false" },
            panel.priority,
        ));
    }
    output.push_str("  )\n");
    output.push_str("  (portfolio\n");
    output.push_str(&format!(
        "    (name \"{} Development\")\n",
        repo_name
    ));
    output.push_str("    (isolation \"native\")))\n");

    let panels_path = mr_dir.join("PANELS.a2ml");
    fs::write(&panels_path, &output)
        .map_err(|e| format!("Cannot write PANELS.a2ml: {e}"))?;

    Ok(serde_json::json!({
        "saved": true,
        "path": panels_path.to_string_lossy(),
        "panel_count": panels.len()
    })
    .to_string())
}

/// List recently loaded repositories.

pub async fn repoloader_list_recent() -> Result<String, String> {
    let recent = load_recent();
    serde_json::to_string(&recent).map_err(|e| format!("Serialisation error: {e}"))
}

/// Search the git-private-farm manifest for repos matching a query.
///
/// Searches repo names and descriptions (case-insensitive substring match).

pub async fn repoloader_search_farm(query: String) -> Result<String, String> {
    let home = dirs::home_dir().ok_or("Cannot determine home directory")?;
    let manifest_path = home.join(".git-private-farm").join("farm-manifest.json");

    if !manifest_path.exists() {
        return Ok(serde_json::json!({ "results": [] }).to_string());
    }

    let content = fs::read_to_string(&manifest_path)
        .map_err(|e| format!("Cannot read farm manifest: {e}"))?;

    let manifest: serde_json::Value = serde_json::from_str(&content)
        .map_err(|e| format!("Cannot parse farm manifest: {e}"))?;

    let query_lower = query.to_lowercase();
    let mut results: Vec<serde_json::Value> = Vec::new();

    if let Some(repos) = manifest.get("repos").and_then(|r| r.as_object()) {
        for (name, repo) in repos {
            let name_lower = name.to_lowercase();
            let desc = repo
                .get("description")
                .and_then(|d| d.as_str())
                .unwrap_or("");
            let desc_lower = desc.to_lowercase();

            if name_lower.contains(&query_lower) || desc_lower.contains(&query_lower) {
                // Determine the repo path — check common locations.
                let repo_path = home
                    .join("Documents")
                    .join("hyperpolymath-repos")
                    .join(name);

                results.push(serde_json::json!({
                    "name": name,
                    "description": desc,
                    "path": repo_path.to_string_lossy(),
                    "exists": repo_path.exists(),
                }));
            }
        }
    }

    // Sort by name.
    results.sort_by(|a, b| {
        let a_name = a["name"].as_str().unwrap_or("");
        let b_name = b["name"].as_str().unwrap_or("");
        a_name.cmp(b_name)
    });

    Ok(serde_json::json!({ "results": results }).to_string())
}
