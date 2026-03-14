// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Minter Types — data structures for the Panel Minter backend.
//!
//! These types mirror the ReScript `MinterModel.res` definitions so the
//! Tauri command boundary can deserialise frontend requests and serialise
//! results back.

#![allow(dead_code)]

use serde::{Deserialize, Serialize};

/// Backend type for the panel — determines what kind of Rust backend
/// and Tauri commands are scaffolded.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum BackendKind {
    /// No backend — pure frontend panel (e.g. documentation viewer).
    NoBackend,
    /// Filesystem-only backend — reads local files, no HTTP.
    FilesystemBackend,
    /// HTTP API backend — connects to an external service.
    HttpBackend,
    /// Database backend — connects to a database via existing DB module.
    DatabaseBackend,
}

/// A single capability declaration for the new panel.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Capability {
    /// Machine-readable identifier (e.g. "repo-inventory").
    pub id: String,
    /// Human-readable label (e.g. "Repository Inventory").
    pub label: String,
}

/// The minting request — sent from the ReScript frontend via Tauri invoke.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MintRequest {
    /// PascalCase panel name (e.g. "Wharf", "Statistease").
    pub panel_name: String,
    /// Short name for the panel bar (max ~8 chars).
    pub short_name: String,
    /// One-line description of what this panel does.
    pub description: String,
    /// Icon identifier for the panel bar.
    pub icon: String,
    /// Backend type string: "No Backend", "Filesystem", "HTTP API", "Database".
    pub backend_kind: String,
    /// Accessibility level string: "Standard", "Enhanced".
    pub accessibility: String,
    /// JSON-encoded capabilities array.
    pub capabilities: String,
    /// Endpoint URL for HTTP/Database backends (empty string if not applicable).
    pub endpoint: String,
}

/// Result of a minting operation — returned to the ReScript frontend.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MintResult {
    /// Whether the operation succeeded.
    pub success: bool,
    /// Files that were created.
    pub files_created: Vec<String>,
    /// Files that were patched (modified).
    pub files_patched: Vec<String>,
    /// Any warnings encountered during generation.
    pub warnings: Vec<String>,
    /// Error message if the operation failed.
    pub error: Option<String>,
}
