// SPDX-License-Identifier: PMPL-1.0-or-later

//! Farm Tauri commands — reads the farm manifest and exposes repo inventory
//! to the ReScript frontend.
//!
//! Commands:
//!   - `farm_list_repos`: Load and return the full repo inventory from
//!     `~/.git-private-farm/farm-manifest.json`.
//!   - `farm_get_repo`: Get details for a single repo by name.
//!   - `farm_get_stats`: Get aggregate statistics (counts by language,
//!     forge, priority, group).

use std::collections::{HashMap, HashSet};
use std::fs;

use super::types::*;

/// Resolve the manifest path, expanding `~` to the home directory.
fn manifest_path() -> Result<std::path::PathBuf, String> {
    let home = dirs::home_dir().ok_or("Cannot determine home directory")?;
    Ok(home.join(".git-private-farm").join("farm-manifest.json"))
}

/// Read and parse the farm manifest from disk.
fn load_manifest() -> Result<FarmManifest, String> {
    let path = manifest_path()?;
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Cannot read {}: {}", path.display(), e))?;
    serde_json::from_str(&content)
        .map_err(|e| format!("Cannot parse manifest: {e}"))
}

/// Build a reverse lookup from repo name → group name.
fn build_group_lookup(manifest: &FarmManifest) -> HashMap<String, String> {
    let mut lookup = HashMap::new();
    if let Some(groups) = &manifest.repo_groups {
        for (group_name, group) in groups {
            if let Some(repos) = &group.repos {
                for repo in repos {
                    lookup.insert(repo.clone(), group_name.clone());
                }
            }
        }
    }
    lookup
}

/// Load the full repo inventory from the farm manifest.
///
/// Returns a JSON-serialised `FarmInventory` with all repos, groups,
/// distinct languages, and forge names. The frontend parses this once
/// and caches it in the model.
#[tauri::command]
pub async fn farm_list_repos() -> Result<String, String> {
    let manifest = load_manifest()?;
    let group_lookup = build_group_lookup(&manifest);

    let mut entries = Vec::new();
    let mut languages_set = HashSet::new();
    let mut forges_set = HashSet::new();

    if let Some(repos) = &manifest.repos {
        for (name, repo) in repos {
            let lang = repo.language.clone().unwrap_or_default();
            let priority = repo.priority.clone().unwrap_or_else(|| "medium".to_string());
            let forges = repo.forges.clone().unwrap_or_default();
            let auto_prop = repo.auto_propagate.unwrap_or(false);
            let description = repo.description.clone().unwrap_or_default();
            let group = group_lookup.get(name).cloned();

            if !lang.is_empty() {
                languages_set.insert(lang.clone());
            }
            for f in &forges {
                forges_set.insert(f.clone());
            }

            entries.push(FarmRepoEntry {
                name: name.clone(),
                description,
                language: lang,
                priority,
                forges,
                auto_propagate: auto_prop,
                group,
            });
        }
    }

    // Sort by name for consistent ordering.
    entries.sort_by(|a, b| a.name.cmp(&b.name));

    let mut languages: Vec<String> = languages_set.into_iter().collect();
    languages.sort();
    let mut forge_names: Vec<String> = forges_set.into_iter().collect();
    forge_names.sort();

    // Build groups map for the frontend.
    let mut groups = HashMap::new();
    if let Some(manifest_groups) = &manifest.repo_groups {
        for (name, group) in manifest_groups {
            groups.insert(
                name.clone(),
                group.repos.clone().unwrap_or_default(),
            );
        }
    }

    let inventory = FarmInventory {
        total: entries.len(),
        repos: entries,
        groups,
        languages,
        forge_names,
    };

    serde_json::to_string(&inventory)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Get details for a single repo by name.
///
/// Returns the repo entry as JSON, or an error if not found.
#[tauri::command]
pub async fn farm_get_repo(name: String) -> Result<String, String> {
    let manifest = load_manifest()?;
    let group_lookup = build_group_lookup(&manifest);

    let repos = manifest.repos.ok_or("No repos section in manifest")?;
    let repo = repos.get(&name).ok_or(format!("Repo not found: {name}"))?;

    let entry = FarmRepoEntry {
        name: name.clone(),
        description: repo.description.clone().unwrap_or_default(),
        language: repo.language.clone().unwrap_or_default(),
        priority: repo.priority.clone().unwrap_or_else(|| "medium".to_string()),
        forges: repo.forges.clone().unwrap_or_default(),
        auto_propagate: repo.auto_propagate.unwrap_or(false),
        group: group_lookup.get(&name).cloned(),
    };

    serde_json::to_string(&entry)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Get aggregate statistics from the farm manifest.
///
/// Returns counts grouped by language, forge, priority, and group.
#[tauri::command]
pub async fn farm_get_stats() -> Result<String, String> {
    let manifest = load_manifest()?;

    let mut by_language: HashMap<String, u32> = HashMap::new();
    let mut by_forge: HashMap<String, u32> = HashMap::new();
    let mut by_priority: HashMap<String, u32> = HashMap::new();
    let mut by_group: HashMap<String, u32> = HashMap::new();
    let mut total = 0u32;

    if let Some(repos) = &manifest.repos {
        for (_name, repo) in repos {
            total += 1;
            let lang = repo.language.clone().unwrap_or_else(|| "unknown".to_string());
            *by_language.entry(lang).or_insert(0) += 1;

            let pri = repo.priority.clone().unwrap_or_else(|| "medium".to_string());
            *by_priority.entry(pri).or_insert(0) += 1;

            if let Some(forges) = &repo.forges {
                for f in forges {
                    *by_forge.entry(f.clone()).or_insert(0) += 1;
                }
            }
        }
    }

    // Count repos per group.
    let group_lookup = build_group_lookup(&manifest);
    for (_repo, group) in &group_lookup {
        *by_group.entry(group.clone()).or_insert(0) += 1;
    }

    let stats = serde_json::json!({
        "total": total,
        "by_language": by_language,
        "by_forge": by_forge,
        "by_priority": by_priority,
        "by_group": by_group,
    });

    serde_json::to_string(&stats)
        .map_err(|e| format!("Serialisation error: {e}"))
}
