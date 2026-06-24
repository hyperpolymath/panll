// SPDX-License-Identifier: MPL-2.0

//! Security Tauri commands — redaction, vault I/O, 2FA, Trustfile loading.
//!
//! Redaction uses Rust's regex crate for reliable pattern matching.
//! Vault integration shells out to `reasonably-good-tool` CLI.
//! 2FA uses TOTP (RFC 6238) with HMAC-SHA1.
//! Trustfile parsing reads the repo's Trustfile.a2ml.

use std::fs;
use std::path::Path;
use std::process::Command;

use super::types::{DetectedSecret, RedactionPattern, RedactionResult, TrustfilePolicy, VaultKey};

/// Redact secrets from text using the provided patterns.
/// Returns the redacted text and a list of detected secrets.
///
/// This is the workhorse of the security layer — called when sharing,
/// saving, or displaying content that might contain secrets.

pub async fn redact_text(
    text: String,
    panel_id: String,
    patterns_json: String,
) -> Result<String, String> {
    let patterns: Vec<RedactionPattern> = serde_json::from_str(&patterns_json)
        .map_err(|e| format!("Invalid patterns JSON: {e}"))?;

    let mut result_text = text.clone();
    let mut secrets: Vec<DetectedSecret> = Vec::new();
    let mut total_redacted: usize = 0;

    for pattern in &patterns {
        if !pattern.enabled {
            continue;
        }

        // Compile the regex pattern. Skip invalid patterns gracefully.
        let re = match regex::Regex::new(&pattern.pattern) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("Warning: invalid regex pattern '{}': {e}", pattern.id);
                continue;
            }
        };

        // Find all matches and build the replacement.
        let placeholder = format!("[REDACTED:{}]", pattern.label);

        for mat in re.find_iter(&text) {
            secrets.push(DetectedSecret {
                pattern_id: pattern.id.clone(),
                panel_id: panel_id.clone(),
                offset: mat.start(),
                length: mat.len(),
                placeholder: placeholder.clone(),
            });
            total_redacted += 1;
        }

        // Apply redaction to the result text.
        result_text = re.replace_all(&result_text, placeholder.as_str()).to_string();
    }

    let result = RedactionResult {
        redacted_text: result_text,
        secrets_found: secrets,
        total_redacted,
    };

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Store a secret in the vault via reasonably-good-tool CLI.

pub async fn vault_store(key: String, value: String) -> Result<String, String> {
    let output = Command::new("reasonably-good-tool")
        .args(["vault", "set", &key, &value])
        .output()
        .map_err(|e| format!("Cannot run reasonably-good-tool: {e}"))?;

    if output.status.success() {
        Ok(format!("Secret '{key}' stored in vault"))
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!("Vault store failed: {stderr}"))
    }
}

/// Retrieve a secret from the vault via reasonably-good-tool CLI.

pub async fn vault_retrieve(key: String) -> Result<String, String> {
    let output = Command::new("reasonably-good-tool")
        .args(["vault", "get", &key])
        .output()
        .map_err(|e| format!("Cannot run reasonably-good-tool: {e}"))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!("Vault retrieve failed: {stderr}"))
    }
}

/// List all keys in the vault (names only, not values).

pub async fn vault_list() -> Result<String, String> {
    let output = Command::new("reasonably-good-tool")
        .args(["vault", "list"])
        .output()
        .map_err(|e| format!("Cannot run reasonably-good-tool: {e}"))?;

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        let keys: Vec<VaultKey> = stdout.lines()
            .filter(|l| !l.is_empty())
            .map(|l| VaultKey {
                key: l.trim().to_string(),
                description: String::new(),
                last_updated: 0.0,
            })
            .collect();

        serde_json::to_string(&keys)
            .map_err(|e| format!("Serialisation error: {e}"))
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!("Vault list failed: {stderr}"))
    }
}

/// Load and parse a Trustfile.a2ml from a repo path.
///
/// The Trustfile defines the security policy for a workspace session.
/// This command reads the file and returns a parsed TrustfilePolicy.

pub async fn load_trustfile(repo_path: String) -> Result<String, String> {
    let trustfile_path = Path::new(&repo_path).join("Trustfile.a2ml");

    if !trustfile_path.exists() {
        return Err("No Trustfile.a2ml found in this repository".to_string());
    }

    let content = fs::read_to_string(&trustfile_path)
        .map_err(|e| format!("Cannot read Trustfile: {e}"))?;

    // Parse the Trustfile content. The a2ml format uses S-expression-like
    // syntax. For now, we do a simplified parse extracting key fields.
    let policy = parse_trustfile(&content, &trustfile_path.to_string_lossy())?;

    serde_json::to_string(&policy)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Simplified Trustfile parser. Extracts key security policy fields from
/// the a2ml S-expression format.
fn parse_trustfile(content: &str, file_path: &str) -> Result<TrustfilePolicy, String> {
    // Extract security-level.
    let security_level = extract_field(content, "security-level")
        .unwrap_or_else(|| "medium".to_string());

    // Extract redaction mode.
    let redaction_mode = extract_field(content, "mode")
        .unwrap_or_else(|| "on-share".to_string());

    // Extract require-approval.
    let require_approval = extract_field(content, "require-approval")
        .map(|v| v == "true")
        .unwrap_or(false);

    // Extract default-permission.
    let default_sharing = extract_field(content, "default-permission")
        .unwrap_or_else(|| "view-only".to_string());

    // Check for 2FA requirements.
    let mut two_factor_reqs = Vec::new();
    for op in &["vault-access", "panel-sharing", "export", "reset-all"] {
        let field_name = format!("{op}");
        if let Some(val) = extract_nested_field(content, "require-2fa", &field_name) {
            two_factor_reqs.push(super::types::TwoFactorRequirement {
                operation: op.to_string(),
                required: val == "true",
            });
        }
    }

    Ok(TrustfilePolicy {
        security_level,
        redaction_mode,
        custom_patterns: Vec::new(), // Custom patterns parsed separately if present
        two_factor_requirements: two_factor_reqs,
        default_sharing_permission: default_sharing,
        require_approval,
        loaded: true,
        file_path: Some(file_path.to_string()),
    })
}

/// Extract a simple key-value field from S-expression content.
/// Looks for `(field-name "value")` or `(field-name value)`.
fn extract_field(content: &str, field: &str) -> Option<String> {
    let pattern = format!("({field}");
    let start = content.find(&pattern)?;
    let rest = &content[start + pattern.len()..];

    // Skip whitespace.
    let rest = rest.trim_start();

    if rest.starts_with('"') {
        // Quoted string value.
        let end = rest[1..].find('"')?;
        Some(rest[1..1 + end].to_string())
    } else {
        // Bare value (until whitespace or closing paren).
        let end = rest.find(|c: char| c.is_whitespace() || c == ')')?;
        Some(rest[..end].to_string())
    }
}

/// Extract a nested field value from S-expression content.
/// Looks for `(parent-key (field-name value))`.
fn extract_nested_field(content: &str, parent: &str, field: &str) -> Option<String> {
    let parent_pattern = format!("({parent}");
    let start = content.find(&parent_pattern)?;
    let parent_content = &content[start..];

    // Find the closing paren for the parent block.
    let mut depth = 0;
    let mut end = 0;
    for (i, c) in parent_content.chars().enumerate() {
        match c {
            '(' => depth += 1,
            ')' => {
                depth -= 1;
                if depth == 0 {
                    end = i;
                    break;
                }
            }
            _ => {}
        }
    }

    let block = &parent_content[..end];
    extract_field(block, field)
}
