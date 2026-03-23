// SPDX-License-Identifier: PMPL-1.0-or-later

//! Workspace types — serde-compatible structs for arrangements, groups, sessions.
//!
//! These mirror the ReScript WorkspaceModel types, enabling JSON round-tripping
//! between the frontend state and on-disk persistence. The Tauri commands in
//! `commands.rs` use these for serialisation.

use serde::{Deserialize, Serialize};

/// Position and size of a single panel within an arrangement.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PanelPosition {
    pub panel_id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub z_index: i32,
    pub visible: bool,
}

/// A group of panels that move/resize/show/hide together.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PanelGroup {
    pub id: String,
    pub name: String,
    pub panel_ids: Vec<String>,
    pub locked: bool,
    pub visible: bool,
    pub z_index: i32,
    pub shared_with: Vec<String>,
}

/// A named arrangement: complete layout state of all panels.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Arrangement {
    pub id: String,
    pub name: String,
    pub positions: Vec<PanelPosition>,
    pub groups: Vec<PanelGroup>,
    pub built_in: bool,
    pub last_saved: f64,
}

/// A checkpoint within a session.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Checkpoint {
    pub id: String,
    pub label: String,
    pub timestamp: f64,
    pub automatic: bool,
}

/// Session protection level.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "value")]
pub enum SessionProtection {
    Open,
    ReadOnly,
    Sandboxed,
    LanguageLocked(Vec<String>),
    TranspilationGuarded,
    ProductionGated,
}

/// Execution mode for safe testing.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ExecutionMode {
    Live,
    DryRun,
    Simulation,
    Emulation,
}

/// Workspace personality mode.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum WorkspaceMode {
    RhodiumMode,
    EverythingMode,
    CodeMode,
    BespokeMode,
}

/// A complete session record.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Session {
    pub id: String,
    pub name: String,
    pub repo_path: Option<String>,
    pub arrangement_id: Option<String>,
    pub protection: SessionProtection,
    pub execution_mode: ExecutionMode,
    pub workspace_mode: WorkspaceMode,
    pub checkpoints: Vec<Checkpoint>,
    pub created: f64,
    pub last_active: f64,
    pub forked_from: Option<String>,
}

/// System information snapshot for status bar widgets.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SystemInfo {
    /// CPU usage as a percentage (0.0–100.0).
    pub cpu_usage: f64,
    /// Total physical memory in bytes.
    pub memory_total: u64,
    /// Used physical memory in bytes.
    pub memory_used: u64,
    /// Total disk space in bytes (for the repo drive).
    pub disk_total: u64,
    /// Used disk space in bytes.
    pub disk_used: u64,
    /// System uptime in seconds.
    pub uptime_seconds: u64,
}
