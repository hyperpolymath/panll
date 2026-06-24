// SPDX-License-Identifier: MPL-2.0

//! Farm manifest types — mirrors the JSON schema of farm-manifest.json.
//!
//! The manifest has three top-level sections:
//!   - `forges`: target forge configurations (github, gitlab, etc.)
//!   - `repos`: the actual repo inventory with metadata
//!   - `propagation`: sync settings (schedule, parallelism, retries)
//!
//! We parse the `repos` section into `ManifestRepo` entries and flatten
//! the forge list per-repo into a simple array of forge names.

#![allow(dead_code)]

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// A single repo entry from the manifest. Fields are optional because
/// the manifest schema allows partial entries.
#[derive(Debug, Clone, Deserialize)]
pub struct ManifestRepo {
    /// Human-readable description.
    pub description: Option<String>,
    /// Target forge names (e.g., ["github", "gitlab", "sourcehut"]).
    pub forges: Option<Vec<String>>,
    /// Sync priority: "high", "medium", or "low".
    pub priority: Option<String>,
    /// Whether auto-propagation is enabled.
    pub auto_propagate: Option<bool>,
    /// Primary programming language.
    pub language: Option<String>,
}

/// Repo group definition from the manifest.
#[derive(Debug, Clone, Deserialize)]
pub struct ManifestGroup {
    /// Group description.
    pub description: Option<String>,
    /// Repo names in this group.
    pub repos: Option<Vec<String>>,
}

/// Top-level manifest structure. We only parse what the panel needs.
#[derive(Debug, Clone, Deserialize)]
pub struct FarmManifest {
    /// Repo inventory keyed by repo name.
    pub repos: Option<HashMap<String, ManifestRepo>>,
    /// Repo groups keyed by group name.
    pub repo_groups: Option<HashMap<String, ManifestGroup>>,
}

/// Serialisable repo entry sent to the frontend.
#[derive(Debug, Clone, Serialize)]
pub struct FarmRepoEntry {
    /// Repo name (key from manifest).
    pub name: String,
    /// Human-readable description.
    pub description: String,
    /// Primary language.
    pub language: String,
    /// Priority level.
    pub priority: String,
    /// Target forge names.
    pub forges: Vec<String>,
    /// Auto-propagation enabled.
    pub auto_propagate: bool,
    /// Group membership (if any).
    pub group: Option<String>,
}

/// Full inventory response sent to the frontend as JSON.
#[derive(Debug, Clone, Serialize)]
pub struct FarmInventory {
    /// Total number of repos.
    pub total: usize,
    /// All repo entries.
    pub repos: Vec<FarmRepoEntry>,
    /// Available groups with their repo lists.
    pub groups: HashMap<String, Vec<String>>,
    /// Distinct languages found.
    pub languages: Vec<String>,
    /// Distinct forges found.
    pub forge_names: Vec<String>,
}

// ---------------------------------------------------------------------------
// Smoke tests — construction and JSON serialisation
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_farm_repo_entry_serialises() {
        let entry = FarmRepoEntry {
            name: "panll".to_string(),
            description: "PanLL workspace".to_string(),
            language: "ReScript".to_string(),
            priority: "high".to_string(),
            forges: vec!["github".to_string(), "gitlab".to_string()],
            auto_propagate: true,
            group: Some("core".to_string()),
        };
        let json = serde_json::to_string(&entry).expect("serialise FarmRepoEntry must succeed");
        assert!(json.contains("panll"));
        assert!(json.contains("github"));
    }

    #[test]
    fn smoke_farm_inventory_total_matches_repos() {
        let inv = FarmInventory {
            total: 2,
            repos: vec![
                FarmRepoEntry {
                    name: "repo-a".to_string(),
                    description: "".to_string(),
                    language: "Rust".to_string(),
                    priority: "medium".to_string(),
                    forges: vec![],
                    auto_propagate: false,
                    group: None,
                },
                FarmRepoEntry {
                    name: "repo-b".to_string(),
                    description: "".to_string(),
                    language: "Gleam".to_string(),
                    priority: "low".to_string(),
                    forges: vec![],
                    auto_propagate: false,
                    group: None,
                },
            ],
            groups: HashMap::new(),
            languages: vec!["Rust".to_string(), "Gleam".to_string()],
            forge_names: vec![],
        };
        assert_eq!(inv.total, inv.repos.len());
        assert_eq!(inv.languages.len(), 2);
    }

    #[test]
    fn smoke_manifest_repo_all_optional_fields() {
        // ManifestRepo is deserialisable from a minimal JSON object
        let json = r#"{}"#;
        let repo: ManifestRepo = serde_json::from_str(json).expect("empty ManifestRepo must parse");
        assert!(repo.description.is_none());
        assert!(repo.forges.is_none());
        assert!(repo.auto_propagate.is_none());
    }
}
