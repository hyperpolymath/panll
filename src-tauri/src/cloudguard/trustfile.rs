// SPDX-License-Identifier: PMPL-1.0-or-later

//! CloudGuard Trustfile policy evaluation.
//!
//! Parses security policy constraints from Trustfile (.a2ml) and Nickel
//! (.k9.ncl) configuration files, then evaluates live Cloudflare zone
//! settings against those constraints to produce audit findings.
//!
//! This is the backend component of Panel-L's constraint list. The policy
//! file defines the desired state; this module checks whether reality matches.
//!
//! Phase 4 will add full Nickel integration. For now, we use hardcoded
//! security defaults that match the hardening session we did manually.

use serde::Serialize;
use serde_json::Value;

use super::types::CfZoneSetting;

/// A single policy constraint — a rule that a setting must satisfy.
#[derive(Debug, Serialize, Clone)]
pub struct PolicyConstraint {
    /// Unique constraint ID (e.g. "ssl.mode.full_strict").
    pub id: String,
    /// Human-readable rule expression (e.g. "ssl.mode == \"full_strict\"").
    pub expression: String,
    /// Setting category for grouping in Panel-L.
    pub category: String,
    /// Severity if violated: "critical", "high", "medium", "low", "info".
    pub severity: String,
    /// Explanation of why this constraint matters.
    pub description: String,
    /// The CF setting ID this constraint checks.
    pub setting_id: String,
    /// The expected value (JSON-serialised).
    pub expected_value: String,
}

/// An audit finding — one constraint that failed evaluation.
#[derive(Debug, Serialize, Clone)]
pub struct AuditFinding {
    /// Which domain this applies to.
    pub domain: String,
    /// The constraint that failed.
    pub constraint_id: String,
    /// Setting ID that failed.
    pub setting_id: String,
    /// Setting category.
    pub category: String,
    /// Severity of the finding.
    pub severity: String,
    /// Human-readable finding message.
    pub message: String,
    /// Current value (stringified).
    pub current_value: String,
    /// Expected value (stringified).
    pub expected_value: String,
    /// Whether CloudGuard can auto-fix this.
    pub auto_fixable: bool,
}

/// Audit result for a zone.
#[derive(Debug, Serialize)]
pub struct AuditResult {
    /// Domain name.
    pub domain: String,
    /// ISO 8601 timestamp.
    pub timestamp: String,
    /// All findings (failed constraints).
    pub findings: Vec<AuditFinding>,
    /// Number of constraints that passed.
    pub passed: u32,
    /// Number of constraints that failed.
    pub failed: u32,
    /// Overall compliance score (0.0 - 1.0).
    pub score: f64,
}

/// Returns the default hardening policy constraints. These encode the same
/// security settings we applied manually during the domain hardening session.
/// Phase 4 will replace this with Nickel/Trustfile parsing.
pub fn default_constraints() -> Vec<PolicyConstraint> {
    vec![
        PolicyConstraint {
            id: "ssl.mode.full_strict".to_string(),
            expression: "ssl == \"full_strict\"".to_string(),
            category: "ssl_tls".to_string(),
            severity: "critical".to_string(),
            description: "SSL/TLS mode must be Full (Strict) to ensure end-to-end encryption with valid certificates.".to_string(),
            setting_id: "ssl".to_string(),
            expected_value: "\"full_strict\"".to_string(),
        },
        PolicyConstraint {
            id: "tls.min_version.1_2".to_string(),
            expression: "min_tls_version == \"1.2\"".to_string(),
            category: "ssl_tls".to_string(),
            severity: "critical".to_string(),
            description: "Minimum TLS version must be 1.2 to prevent downgrade attacks.".to_string(),
            setting_id: "min_tls_version".to_string(),
            expected_value: "\"1.2\"".to_string(),
        },
        PolicyConstraint {
            id: "https.always_on".to_string(),
            expression: "always_use_https == \"on\"".to_string(),
            category: "ssl_tls".to_string(),
            severity: "critical".to_string(),
            description: "Always Use HTTPS must be enabled to redirect all HTTP to HTTPS.".to_string(),
            setting_id: "always_use_https".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "https.auto_rewrites".to_string(),
            expression: "automatic_https_rewrites == \"on\"".to_string(),
            category: "ssl_tls".to_string(),
            severity: "high".to_string(),
            description: "Automatic HTTPS Rewrites should fix mixed content by rewriting HTTP URLs in page content.".to_string(),
            setting_id: "automatic_https_rewrites".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "tls.1_3.zrt".to_string(),
            expression: "tls_1_3 == \"zrt\"".to_string(),
            category: "ssl_tls".to_string(),
            severity: "high".to_string(),
            description: "TLS 1.3 should be enabled with 0-RTT for best performance and security.".to_string(),
            setting_id: "tls_1_3".to_string(),
            expected_value: "\"zrt\"".to_string(),
        },
        PolicyConstraint {
            id: "opp_encryption.on".to_string(),
            expression: "opportunistic_encryption == \"on\"".to_string(),
            category: "ssl_tls".to_string(),
            severity: "medium".to_string(),
            description: "Opportunistic Encryption enables HTTPS for HTTP/2 Alt-Svc.".to_string(),
            setting_id: "opportunistic_encryption".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "hsts.enabled".to_string(),
            expression: "security_header.strict_transport_security.enabled == true".to_string(),
            category: "headers".to_string(),
            severity: "critical".to_string(),
            description: "HSTS must be enabled with preload to prevent SSL stripping attacks.".to_string(),
            setting_id: "security_header".to_string(),
            expected_value: "HSTS enabled with max-age 31536000, includeSubDomains, preload".to_string(),
        },
        PolicyConstraint {
            id: "browser_check.on".to_string(),
            expression: "browser_check == \"on\"".to_string(),
            category: "waf".to_string(),
            severity: "medium".to_string(),
            description: "Browser Integrity Check validates browser headers to block bots.".to_string(),
            setting_id: "browser_check".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "hotlink_protection.on".to_string(),
            expression: "hotlink_protection == \"on\"".to_string(),
            category: "waf".to_string(),
            severity: "low".to_string(),
            description: "Hotlink Protection prevents other sites from embedding your images.".to_string(),
            setting_id: "hotlink_protection".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "email_obfuscation.on".to_string(),
            expression: "email_obfuscation == \"on\"".to_string(),
            category: "waf".to_string(),
            severity: "low".to_string(),
            description: "Email Obfuscation hides email addresses from scrapers.".to_string(),
            setting_id: "email_obfuscation".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "ip_geolocation.on".to_string(),
            expression: "ip_geolocation == \"on\"".to_string(),
            category: "network".to_string(),
            severity: "low".to_string(),
            description: "IP Geolocation adds the CF-IPCountry header for geo-aware applications.".to_string(),
            setting_id: "ip_geolocation".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "websockets.on".to_string(),
            expression: "websockets == \"on\"".to_string(),
            category: "network".to_string(),
            severity: "medium".to_string(),
            description: "WebSockets support must be enabled for real-time applications.".to_string(),
            setting_id: "websockets".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "http3.on".to_string(),
            expression: "http3 == \"on\"".to_string(),
            category: "performance".to_string(),
            severity: "medium".to_string(),
            description: "HTTP/3 (QUIC) improves performance, especially on mobile networks.".to_string(),
            setting_id: "http3".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "0rtt.on".to_string(),
            expression: "0rtt == \"on\"".to_string(),
            category: "performance".to_string(),
            severity: "low".to_string(),
            description: "0-RTT Connection Resumption improves initial page load for returning visitors.".to_string(),
            setting_id: "0rtt".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "brotli.on".to_string(),
            expression: "brotli == \"on\"".to_string(),
            category: "performance".to_string(),
            severity: "medium".to_string(),
            description: "Brotli compression reduces bandwidth and improves page load times.".to_string(),
            setting_id: "brotli".to_string(),
            expected_value: "\"on\"".to_string(),
        },
        PolicyConstraint {
            id: "early_hints.on".to_string(),
            expression: "early_hints == \"on\"".to_string(),
            category: "performance".to_string(),
            severity: "low".to_string(),
            description: "Early Hints (103) preloads resources before the full response, improving LCP.".to_string(),
            setting_id: "early_hints".to_string(),
            expected_value: "\"on\"".to_string(),
        },
    ]
}

/// Normalise a CF setting value for comparison against expected values.
fn normalise_setting_value(v: &Value) -> String {
    match v {
        Value::String(s) => format!("\"{}\"", s),
        Value::Bool(b) => if *b { "\"on\"".to_string() } else { "\"off\"".to_string() },
        Value::Number(n) => n.to_string(),
        Value::Null => "null".to_string(),
        _ => serde_json::to_string(v).unwrap_or_else(|_| "?".to_string()),
    }
}

/// Evaluate all constraints against a zone's live settings.
/// Returns an audit result with findings for every constraint that fails.
pub fn evaluate_constraints(
    domain: &str,
    settings: &[CfZoneSetting],
    constraints: &[PolicyConstraint],
) -> AuditResult {
    let settings_map: std::collections::HashMap<&str, &Value> = settings
        .iter()
        .map(|s| (s.id.as_str(), &s.value))
        .collect();

    let mut findings = Vec::new();
    let mut passed = 0u32;

    for constraint in constraints {
        let actual = settings_map.get(constraint.setting_id.as_str());

        let matches = match actual {
            Some(value) => {
                // Special handling for HSTS (nested object)
                if constraint.setting_id == "security_header" {
                    check_hsts_constraint(value)
                } else {
                    let normalised = normalise_setting_value(value);
                    normalised == constraint.expected_value
                }
            }
            None => false, // Setting not present = constraint fails
        };

        if matches {
            passed += 1;
        } else {
            let current_value = actual
                .map(|v| normalise_setting_value(v))
                .unwrap_or_else(|| "not set".to_string());

            findings.push(AuditFinding {
                domain: domain.to_string(),
                constraint_id: constraint.id.clone(),
                setting_id: constraint.setting_id.clone(),
                category: constraint.category.clone(),
                severity: constraint.severity.clone(),
                message: format!(
                    "{}: expected {}, got {}",
                    constraint.expression, constraint.expected_value, current_value
                ),
                current_value,
                expected_value: constraint.expected_value.clone(),
                auto_fixable: constraint.setting_id != "security_header", // HSTS needs special handling
            });
        }
    }

    let total = (passed + findings.len() as u32) as f64;
    let score = if total > 0.0 { passed as f64 / total } else { 0.0 };

    let timestamp = format!(
        "{}Z",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0)
    );

    let failed = findings.len() as u32;
    AuditResult {
        domain: domain.to_string(),
        timestamp,
        findings,
        passed,
        failed,
        score,
    }
}

/// Check if the HSTS setting matches the expected configuration:
/// enabled=true, max_age>=31536000, includeSubDomains=true, preload=true, nosniff=true.
fn check_hsts_constraint(value: &Value) -> bool {
    let sts = value
        .get("strict_transport_security")
        .or_else(|| value.get("value").and_then(|v| v.get("strict_transport_security")));

    match sts {
        Some(obj) => {
            let enabled = obj.get("enabled").and_then(|v| v.as_bool()).unwrap_or(false);
            let max_age = obj.get("max_age").and_then(|v| v.as_u64()).unwrap_or(0);
            let subdomains = obj.get("include_subdomains").and_then(|v| v.as_bool()).unwrap_or(false);
            let preload = obj.get("preload").and_then(|v| v.as_bool()).unwrap_or(false);
            let nosniff = obj.get("nosniff").and_then(|v| v.as_bool()).unwrap_or(false);

            enabled && max_age >= 31536000 && subdomains && preload && nosniff
        }
        None => false,
    }
}
