// SPDX-License-Identifier: PMPL-1.0-or-later

//! Farm manifest types — mirrors the JSON schema of farm-manifest.json.
//!
//! The manifest has three top-level sections:
//!   - `forges`: target forge configurations (github, gitlab, etc.)
//!   - `repos`: the actual repo inventory with metadata
//!   - `propagation`: sync settings (schedule, parallelism, retries)
//!
//! We parse the `repos` section into `ManifestRepo` entries and flatten
//! the forge list per-repo into a simple array of forge names.

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
