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

// ---------------------------------------------------------------------------
// Smoke tests — verify serde round-trips and default field values
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_redaction_pattern_roundtrip() {
        let pattern = RedactionPattern {
            id: "test-key".to_string(),
            label: "Test Key".to_string(),
            pattern: r"sk-[A-Za-z0-9]{20}".to_string(),
            enabled: true,
            built_in: false,
        };
        let json = serde_json::to_string(&pattern).expect("serialise must succeed");
        let back: RedactionPattern = serde_json::from_str(&json).expect("deserialise must succeed");
        assert_eq!(back.id, "test-key");
        assert_eq!(back.label, "Test Key");
        assert!(back.enabled);
        assert!(!back.built_in);
    }

    #[test]
    fn smoke_detected_secret_roundtrip() {
        let secret = DetectedSecret {
            pattern_id: "anthropic-key".to_string(),
            panel_id: "panel-n".to_string(),
            offset: 42,
            length: 20,
            placeholder: "[REDACTED:Anthropic Key]".to_string(),
        };
        let json = serde_json::to_string(&secret).expect("serialise must succeed");
        let back: DetectedSecret = serde_json::from_str(&json).expect("deserialise must succeed");
        assert_eq!(back.offset, 42);
        assert_eq!(back.length, 20);
        assert_eq!(back.panel_id, "panel-n");
    }

    #[test]
    fn smoke_redaction_result_total_redacted_non_negative() {
        let result = RedactionResult {
            redacted_text: "hello [REDACTED:Key]".to_string(),
            secrets_found: vec![],
            total_redacted: 0,
        };
        assert_eq!(result.total_redacted, 0);
    }

    #[test]
    fn smoke_trustfile_policy_defaults() {
        let policy = TrustfilePolicy {
            security_level: "standard".to_string(),
            redaction_mode: "auto".to_string(),
            custom_patterns: vec![],
            two_factor_requirements: vec![],
            default_sharing_permission: "ask".to_string(),
            require_approval: false,
            loaded: false,
            file_path: None,
        };
        assert!(!policy.loaded);
        assert!(policy.file_path.is_none());
        assert!(policy.custom_patterns.is_empty());
    }

    #[test]
    fn smoke_vault_key_roundtrip() {
        let key = VaultKey {
            key: "ANTHROPIC_API_KEY".to_string(),
            description: "Anthropic API key".to_string(),
            last_updated: 1_700_000_000.0,
        };
        let json = serde_json::to_string(&key).expect("serialise must succeed");
        let back: VaultKey = serde_json::from_str(&json).expect("deserialise must succeed");
        assert_eq!(back.key, "ANTHROPIC_API_KEY");
        assert!(back.last_updated > 0.0);
    }
}
