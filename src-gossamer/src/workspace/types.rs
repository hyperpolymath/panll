// SPDX-License-Identifier: MPL-2.0

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

// ---------------------------------------------------------------------------
// Smoke tests — serde round-trips and invariants for workspace types
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_panel_position_roundtrip() {
        let pos = PanelPosition {
            panel_id: "panel-l".to_string(),
            x: 0.0,
            y: 0.0,
            width: 800.0,
            height: 600.0,
            z_index: 1,
            visible: true,
        };
        let json = serde_json::to_string(&pos).expect("PanelPosition must serialise");
        let back: PanelPosition = serde_json::from_str(&json).expect("PanelPosition must deserialise");
        assert_eq!(back.panel_id, "panel-l");
        assert!(back.visible);
        assert!(back.width > 0.0);
    }

    #[test]
    fn smoke_arrangement_empty_positions() {
        let arr = Arrangement {
            id: "arr-001".to_string(),
            name: "Default".to_string(),
            positions: vec![],
            groups: vec![],
            built_in: true,
            last_saved: 1_700_000_000.0,
        };
        assert!(arr.built_in);
        assert!(arr.positions.is_empty());
    }

    #[test]
    fn smoke_workspace_mode_all_variants_serialise() {
        let modes = [
            WorkspaceMode::RhodiumMode,
            WorkspaceMode::EverythingMode,
            WorkspaceMode::CodeMode,
            WorkspaceMode::BespokeMode,
        ];
        for mode in modes {
            let json = serde_json::to_string(&mode).expect("WorkspaceMode must serialise");
            assert!(!json.is_empty());
        }
    }

    #[test]
    fn smoke_session_protection_sandboxed() {
        let prot = SessionProtection::Sandboxed;
        let json = serde_json::to_string(&prot).expect("SessionProtection must serialise");
        assert!(json.contains("Sandboxed"));
    }

    #[test]
    fn smoke_system_info_memory_invariant() {
        let info = SystemInfo {
            cpu_usage: 25.0,
            memory_total: 16_000_000_000,
            memory_used: 8_000_000_000,
            disk_total: 500_000_000_000,
            disk_used: 100_000_000_000,
            uptime_seconds: 86400,
        };
        assert!(info.memory_used <= info.memory_total, "used memory must not exceed total");
        assert!(info.disk_used <= info.disk_total, "used disk must not exceed total");
        assert!(info.cpu_usage >= 0.0 && info.cpu_usage <= 100.0, "CPU must be in [0,100]");
    }

    #[test]
    fn smoke_panel_group_panel_ids_are_unique() {
        let group = PanelGroup {
            id: "grp-001".to_string(),
            name: "Dev Tools".to_string(),
            panel_ids: vec!["panel-l".to_string(), "panel-n".to_string(), "panel-w".to_string()],
            locked: false,
            visible: true,
            z_index: 0,
            shared_with: vec![],
        };
        let ids: std::collections::HashSet<_> = group.panel_ids.iter().collect();
        assert_eq!(ids.len(), group.panel_ids.len(), "panel IDs in group must be unique");
    }
}
