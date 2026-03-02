// SPDX-License-Identifier: PMPL-1.0-or-later

//! Security types — serde-compatible structs for redaction, vault, 2FA, Trustfile.

use serde::{Deserialize, Serialize};

/// A redaction pattern for secret detection.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RedactionPattern {
    pub id: String,
    pub label: String,
    pub pattern: String,
    pub enabled: bool,
    pub built_in: bool,
}

/// A detected secret in text content.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DetectedSecret {
    pub pattern_id: String,
    pub panel_id: String,
    pub offset: usize,
    pub length: usize,
    pub placeholder: String,
}

/// Redaction result: the cleaned text + list of detected secrets.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RedactionResult {
    pub redacted_text: String,
    pub secrets_found: Vec<DetectedSecret>,
    pub total_redacted: usize,
}

/// Vault key metadata (value is never serialised to frontend).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VaultKey {
    pub key: String,
    pub description: String,
    pub last_updated: f64,
}

/// Trustfile policy parsed from .a2ml format.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TrustfilePolicy {
    pub security_level: String,
    pub redaction_mode: String,
    pub custom_patterns: Vec<RedactionPattern>,
    pub two_factor_requirements: Vec<TwoFactorRequirement>,
    pub default_sharing_permission: String,
    pub require_approval: bool,
    pub loaded: bool,
    pub file_path: Option<String>,
}

/// 2FA requirement for a specific operation.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TwoFactorRequirement {
    pub operation: String,
    pub required: bool,
}
