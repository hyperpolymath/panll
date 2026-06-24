// SPDX-License-Identifier: MPL-2.0

//! Repo Loader types — shared across scanner and commands.
//!
//! These types are serialised to/from JSON for the Tauri IPC bridge.
//! The frontend's RepoLoaderModel.res mirrors these types in ReScript.

use serde::{Deserialize, Serialize};

/// Information about a scanned repository.
#[derive(Debug, Clone, Serialize)]
pub struct RepoInfo {
    /// Filesystem path to the repo root.
    pub path: String,
    /// Repository name (last path component or from manifest).
    pub name: String,
    /// Short description (from AI manifest or STATE.scm).
    pub description: String,
    /// Detected programming languages.
    pub languages: Vec<String>,
    /// Whether `.machine_readable/` directory exists.
    pub has_machine_readable: bool,
    /// Whether `PANELS.a2ml` exists (previously configured).
    pub has_panels_manifest: bool,
    /// Whether `0-AI-MANIFEST.a2ml` exists.
    pub has_ai_manifest: bool,
    /// Whether `STATE.scm` exists in `.machine_readable/`.
    pub has_state: bool,
}

/// A suggested panel to activate for this repo.
#[derive(Debug, Clone, Serialize)]
pub struct PanelSuggestion {
    /// Panel name (matches a panelId).
    pub panel_name: String,
    /// Why this panel was suggested.
    pub reason: String,
    /// Priority: "critical", "high", "medium", "low".
    pub priority: String,
    /// Whether pre-selected.
    pub enabled: bool,
}

/// Scan result sent to the frontend.
#[derive(Debug, Clone, Serialize)]
pub struct ScanResult {
    /// Repository information.
    pub repo: RepoInfo,
    /// Suggested panel configurations.
    pub suggestions: Vec<PanelSuggestion>,
}

/// Panel entry in the PANELS.a2ml manifest.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PanelEntry {
    /// Panel name.
    pub name: String,
    /// Whether enabled.
    pub enabled: bool,
    /// Priority level.
    pub priority: String,
}

/// Parsed PANELS.a2ml manifest structure.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PanelsManifest {
    /// Manifest version.
    pub version: String,
    /// Repository name.
    pub repo: String,
    /// Panel configurations.
    pub panels: Vec<PanelEntry>,
    /// AI constraints for this repo.
    pub ai_constraints: Vec<String>,
    /// Portfolio name.
    pub portfolio_name: String,
    /// Isolation mode ("native", "container", "vm").
    pub isolation: String,
}

/// Recent repo entry for the quick-switch list.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecentRepo {
    /// Filesystem path.
    pub path: String,
    /// Repository name.
    pub name: String,
    /// Last loaded timestamp (Unix seconds).
    pub last_loaded: u64,
}

/// Recent repos file structure (`~/.config/panll/recent-repos.json`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecentReposFile {
    /// Recently loaded repos, most recent first.
    pub repos: Vec<RecentRepo>,
}
