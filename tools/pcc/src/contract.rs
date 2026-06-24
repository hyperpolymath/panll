// SPDX-License-Identifier: MPL-2.0

//! Contract parser — reads panel contract TOML files.
//!
//! Each contract declares the wiring intent for a single PanLL panel:
//! module name, model slice, message namespace, view route, and clade.
//! The parser validates required fields and returns a strongly-typed
//! `PanelContract` ready for obligation generation.

use serde::Deserialize;
use std::path::{Path, PathBuf};

/// Helper for serde default — returns `true`.
fn default_true() -> bool {
    true
}

/// A panel contract declares the expected wiring for one PanLL panel.
///
/// Fields correspond to the canonical integration points that every
/// panel must satisfy: registry entry, model slice, message namespace,
/// and view route.
#[derive(Debug, Clone, Deserialize)]
pub struct PanelContract {
    /// PascalCase panel name (e.g. "MyLang").
    pub panel_id: String,

    /// ReScript module name (usually same as `panel_id`).
    pub module_name: String,

    /// camelCase field name in Model.res (e.g. "myLang").
    pub model_slice: String,

    /// camelCase message type name in Msg.res (e.g. "myLangMsg").
    pub msg_namespace: String,

    /// PanelSwitcherModel variant (e.g. "PanelMyLang").
    pub view_route: String,

    /// Human-readable display name.
    pub short_name: String,

    /// Clade identifier for taxonomy grouping.
    pub clade_id: String,

    /// Whether this panel has a Tauri/Rust backend.
    pub has_backend: bool,

    /// Whether this panel requires test coverage (default: true).
    #[serde(default = "default_true")]
    pub requires_tests: bool,

    /// Whether this panel requires eNSAID export configuration (default: false).
    #[serde(default)]
    pub requires_ensaid_export: bool,

    /// Whether this panel requires runtime contractile health verification (default: false).
    /// Only core panels (Panel-N, Panel-W, etc.) need this — opt-in via contract TOML.
    #[serde(default)]
    pub requires_contractile_health: bool,
}

/// Error type for contract loading.
#[derive(Debug)]
pub enum ContractError {
    /// Contract file could not be read from disk.
    IoError(PathBuf, std::io::Error),
    /// Contract file contains invalid TOML or missing fields.
    ParseError(PathBuf, toml::de::Error),
}

impl std::fmt::Display for ContractError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ContractError::IoError(path, err) => {
                write!(f, "Cannot read contract file {}: {}", path.display(), err)
            }
            ContractError::ParseError(path, err) => {
                write!(f, "Invalid contract file {}: {}", path.display(), err)
            }
        }
    }
}

/// Load a single panel contract from a TOML file.
///
/// Returns `ContractError` if the file cannot be read or parsed.
pub fn load_contract(path: &Path) -> Result<PanelContract, ContractError> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| ContractError::IoError(path.to_path_buf(), e))?;
    let contract: PanelContract =
        toml::from_str(&content).map_err(|e| ContractError::ParseError(path.to_path_buf(), e))?;
    Ok(contract)
}

/// Load all `.toml` contract files from a directory.
///
/// Reads every file with a `.toml` extension in the given directory,
/// parses each as a `PanelContract`, and returns the collected results.
/// Files that fail to parse produce errors in the returned Vec.
pub fn load_contracts_from_dir(
    dir: &Path,
) -> Result<Vec<Result<PanelContract, ContractError>>, std::io::Error> {
    let mut results = Vec::new();

    let entries = std::fs::read_dir(dir)?;
    let mut paths: Vec<PathBuf> = entries
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| p.extension().is_some_and(|ext| ext == "toml"))
        .collect();

    // Deterministic ordering — sort by filename.
    paths.sort();

    for path in paths {
        results.push(load_contract(&path));
    }

    Ok(results)
}

/// Filter a panel contract by ID, returning `Some` if `panel_id` matches
/// the optional filter (or the filter is `None`, meaning "all panels").
pub fn matches_filter(contract: &PanelContract, filter: &Option<String>) -> bool {
    match filter {
        None => true,
        Some(id) => contract.panel_id == *id,
    }
}
