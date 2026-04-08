// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Minter Types — data structures for the Panel Minter backend.
//!
//! These types mirror the ReScript `MinterModel.res` definitions so the
//! backend command boundary can deserialise frontend requests and serialise
//! results back. The frontend communicates via RuntimeBridge (Gossamer or
//! Tauri).

#![allow(dead_code)]

use serde::{Deserialize, Serialize};

/// Backend type for the panel — determines what kind of Rust backend
/// and command stubs are scaffolded.
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

/// The minting request — sent from the ReScript frontend via RuntimeBridge.
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
    /// Optional plugin type: "UI", "Backend", "Hybrid".
    pub plugin_type: Option<String>,
    /// Optional JSON-encoded protocol dependencies array.
    pub protocol_dependencies: Option<String>,
    /// Optional JSON-encoded sandbox policy.
    pub sandbox_policy: Option<String>,
    /// Optional groove endpoint path.
    pub groove_endpoint: Option<String>,
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
    /// Wiring completeness score (connected / total). 7/7 = fully wired.
    pub wiring_score: String,
    /// Per-wiring-point status for the Wiring Inspector.
    pub wiring_details: Vec<WiringDetail>,
    /// Bot validation findings from post-mint checks.
    pub bot_findings: Vec<BotFinding>,
}

/// Status of a single wiring connection point — shown in the Wiring Inspector.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WiringDetail {
    /// Which file this wiring point is in.
    pub file: String,
    /// What the wiring point does.
    pub description: String,
    /// Whether this wiring point is connected.
    pub connected: bool,
    /// Warning message if disconnected.
    pub note: Option<String>,
}

/// A finding from a post-mint bot validation — lightweight version for the UI.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BotFinding {
    /// Which bot produced this finding (e.g. "rhodibot", "glambot").
    pub bot: String,
    /// Rule ID (e.g. "PANEL-001").
    pub rule_id: String,
    /// Severity: "error", "warning", "info", "suggestion".
    pub severity: String,
    /// Human-readable message.
    pub message: String,
    /// File involved (if any).
    pub file: Option<String>,
}

// ---------------------------------------------------------------------------
// Smoke tests — construction, serialisation, and field invariants
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_backend_kind_all_variants_serialise() {
        let kinds = [
            BackendKind::NoBackend,
            BackendKind::FilesystemBackend,
            BackendKind::HttpBackend,
            BackendKind::DatabaseBackend,
        ];
        for kind in kinds {
            serde_json::to_string(&kind).expect("BackendKind must serialise");
        }
    }

    #[test]
    fn smoke_mint_result_success_fields() {
        let result = MintResult {
            success: true,
            files_created: vec!["src/components/Wharf.res".to_string()],
            files_patched: vec!["src/Msg.res".to_string()],
            warnings: vec![],
            error: None,
            wiring_score: "7/7".to_string(),
            wiring_details: vec![],
            bot_findings: vec![],
        };
        assert!(result.success);
        assert_eq!(result.wiring_score, "7/7");
        assert!(result.error.is_none());
        assert_eq!(result.files_created.len(), 1);
    }

    #[test]
    fn smoke_wiring_detail_connected() {
        let detail = WiringDetail {
            file: "src/Msg.res".to_string(),
            description: "Msg variant added".to_string(),
            connected: true,
            note: None,
        };
        let json = serde_json::to_string(&detail).expect("serialise must succeed");
        assert!(json.contains("Msg.res"));
    }

    #[test]
    fn smoke_bot_finding_severity_values() {
        for severity in ["error", "warning", "info", "suggestion"] {
            let finding = BotFinding {
                bot: "rhodibot".to_string(),
                rule_id: "PANEL-001".to_string(),
                severity: severity.to_string(),
                message: "Test finding".to_string(),
                file: None,
            };
            assert_eq!(finding.severity, severity);
        }
    }

    #[test]
    fn smoke_capability_roundtrip() {
        let cap = Capability {
            id: "repo-inventory".to_string(),
            label: "Repository Inventory".to_string(),
        };
        let json = serde_json::to_string(&cap).expect("serialise must succeed");
        let back: Capability = serde_json::from_str(&json).expect("deserialise must succeed");
        assert_eq!(back.id, "repo-inventory");
    }
}

// ---------------------------------------------------------------------------
// Plugin-specific types (added for cartridge/plugin support)
// ---------------------------------------------------------------------------

/// Protocol dependency for a plugin cartridge.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ProtocolDependency {
    /// Protocol name (e.g., "MCP", "LSP", "DAP").
    pub name: String,
    /// Version requirement.
    pub version: String,
    /// Trust tier: "teranga", "shield", or "ayo".
    pub tier: String,
}

/// Sandbox policy for plugin isolation.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SandboxPolicy {
    /// Allowed capabilities.
    pub capabilities: Vec<String>,
    /// Isolation level.
    pub isolation_level: String,
    /// Network access permission.
    pub network_access: bool,
    /// Filesystem access permission.
    pub filesystem_access: bool,
}

/// Plugin type enumeration.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum PluginType {
    /// UI-only plugin (ReScript frontend).
    UI,
    /// Backend-only plugin (Rust service).
    Backend,
    /// Hybrid plugin (both frontend and backend).
    Hybrid,
}

#[cfg(test)]
mod plugin_tests {
    use super::*;

    #[test]
    fn smoke_protocol_dependency_serialization() {
        let dep = ProtocolDependency {
            name: "MCP".to_string(),
            version: "1.0".to_string(),
            tier: "teranga".to_string(),
        };
        let json = serde_json::to_string(&dep).expect("must serialise");
        assert!(json.contains("MCP"));
        let back: ProtocolDependency = serde_json::from_str(&json).expect("must deserialise");
        assert_eq!(back.name, "MCP");
    }

    #[test]
    fn smoke_sandbox_policy_defaults() {
        let policy = SandboxPolicy {
            capabilities: vec!["filesystem".to_string()],
            isolation_level: "StandardPod".to_string(),
            network_access: false,
            filesystem_access: true,
        };
        assert_eq!(policy.isolation_level, "StandardPod");
        assert!(!policy.network_access);
    }

    #[test]
    fn smoke_plugin_type_variants() {
        let variants = vec![PluginType::UI, PluginType::Backend, PluginType::Hybrid];
        for variant in variants {
            serde_json::to_string(&variant).expect("must serialise");
        }
    }
}
