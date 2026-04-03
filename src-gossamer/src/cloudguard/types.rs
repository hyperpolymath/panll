// SPDX-License-Identifier: PMPL-1.0-or-later

//! CloudGuard Rust-side types — serde structs for Cloudflare API responses
//! and internal data structures.
//!
//! These types mirror the ReScript `CloudGuardModel.res` leaf types but are
//! designed for serde JSON serialisation/deserialisation against the CF API
//! v4 response envelope `{ success, errors, messages, result }`.

#![allow(dead_code)]

use serde::{Deserialize, Serialize};

// ============================================================================
// Cloudflare API envelope — wraps all CF API responses
// ============================================================================

/// Generic Cloudflare API response envelope. All v4 endpoints return this
/// shape. `T` is the type of the `result` field (varies per endpoint).
#[derive(Debug, Deserialize)]
pub struct CfApiResponse<T> {
    /// Whether the API call succeeded.
    pub success: bool,
    /// Error messages from the API (non-empty on failure).
    pub errors: Vec<CfApiError>,
    /// Informational messages from the API.
    pub messages: Vec<CfApiMessage>,
    /// The actual response data (None on failure for some endpoints).
    pub result: Option<T>,
    /// Pagination info (present on list endpoints).
    pub result_info: Option<CfResultInfo>,
}

/// A single error from the CF API error array.
#[derive(Debug, Deserialize)]
pub struct CfApiError {
    /// Numeric error code.
    pub code: i64,
    /// Human-readable error message.
    pub message: String,
}

/// A single message from the CF API messages array.
#[derive(Debug, Deserialize)]
pub struct CfApiMessage {
    /// Numeric message code.
    pub code: i64,
    /// Human-readable message text.
    pub message: String,
}

/// Pagination metadata returned by list endpoints.
#[derive(Debug, Deserialize)]
pub struct CfResultInfo {
    /// Current page number (1-indexed).
    pub page: u32,
    /// Results per page.
    pub per_page: u32,
    /// Total number of results across all pages.
    pub total_count: u32,
    /// Total number of pages.
    pub total_pages: u32,
}

// ============================================================================
// Zone types
// ============================================================================

/// A Cloudflare zone (domain) as returned by `GET /zones`.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CfZone {
    /// Zone ID (32-char hex).
    pub id: String,
    /// Domain name (e.g. "axel-protocol.org").
    pub name: String,
    /// Zone status: "active", "pending", "moved", "deleted".
    pub status: String,
    /// Whether the zone is paused (traffic bypasses Cloudflare).
    pub paused: bool,
    /// Plan information.
    pub plan: CfPlan,
    /// Assigned Cloudflare nameservers.
    #[serde(default)]
    pub name_servers: Vec<String>,
    /// Original registrar nameservers (before migration to CF).
    #[serde(default)]
    pub original_name_servers: Vec<String>,
    /// ISO 8601 creation timestamp.
    #[serde(default)]
    pub created_on: String,
    /// ISO 8601 last modification timestamp.
    #[serde(default)]
    pub modified_on: String,
}

/// Cloudflare plan info nested within a zone response.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CfPlan {
    /// Plan ID.
    pub id: String,
    /// Plan name (e.g. "Free Website", "Pro Website").
    pub name: String,
    /// Price in cents (0 for free).
    #[serde(default)]
    pub price: f64,
    /// Billing currency.
    #[serde(default)]
    pub currency: String,
    /// Whether this is a legacy plan.
    #[serde(default)]
    pub is_subscribed: bool,
}

// ============================================================================
// Zone setting types
// ============================================================================

/// A single zone setting as returned by `GET /zones/{zone_id}/settings`.
/// The `value` field is polymorphic (bool, string, int, or nested object),
/// so we deserialise it as `serde_json::Value` and let the frontend parse it.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CfZoneSetting {
    /// Setting ID (e.g. "ssl", "always_use_https", "min_tls_version").
    pub id: String,
    /// Current value — polymorphic: "on"/"off", "full_strict", 31536000, or nested object.
    pub value: serde_json::Value,
    /// Whether the setting is editable on the current plan.
    #[serde(default = "default_true")]
    pub editable: bool,
    /// ISO 8601 last modification timestamp.
    #[serde(default)]
    pub modified_on: String,
}

fn default_true() -> bool {
    true
}

// ============================================================================
// DNS record types
// ============================================================================

/// A DNS record as returned by `GET /zones/{zone_id}/dns_records`.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CfDnsRecord {
    /// Record ID (32-char hex).
    pub id: String,
    /// Parent zone ID.
    pub zone_id: String,
    /// Record type: "A", "AAAA", "CNAME", "MX", "TXT", "SRV", "NS", "CAA", etc.
    #[serde(rename = "type")]
    pub record_type: String,
    /// Hostname (e.g. "www.example.com").
    pub name: String,
    /// Record value (IP address, CNAME target, TXT data, etc.).
    pub content: String,
    /// Time to live in seconds (1 = automatic when proxied).
    #[serde(default = "default_ttl")]
    pub ttl: u32,
    /// Whether Cloudflare proxies this record (orange cloud icon).
    #[serde(default)]
    pub proxied: bool,
    /// Priority for MX/SRV records.
    pub priority: Option<u16>,
    /// Optional record comment (CF API v4 feature).
    #[serde(default)]
    pub comment: Option<String>,
    /// Record tags for filtering and organisation.
    #[serde(default)]
    pub tags: Vec<String>,
    /// Whether the record is locked (managed by Cloudflare, e.g. CNAME flattening).
    #[serde(default)]
    pub locked: bool,
    /// ISO 8601 creation timestamp.
    #[serde(default)]
    pub created_on: String,
    /// ISO 8601 last modification timestamp.
    #[serde(default)]
    pub modified_on: String,
}

fn default_ttl() -> u32 {
    1
}

// ============================================================================
// DNSSEC types
// ============================================================================

/// DNSSEC status as returned by `GET /zones/{zone_id}/dnssec`.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CfDnssecStatus {
    /// DNSSEC status: "active", "pending", "disabled", "error".
    pub status: String,
    /// DS record content (for registrar configuration).
    #[serde(default)]
    pub ds: Option<String>,
    /// Key tag.
    #[serde(default)]
    pub key_tag: Option<u32>,
    /// Algorithm number.
    #[serde(default)]
    pub algorithm: Option<String>,
    /// Digest type.
    #[serde(default)]
    pub digest_type: Option<String>,
    /// Digest value.
    #[serde(default)]
    pub digest: Option<String>,
}

// ============================================================================
// Settings update payload
// ============================================================================

/// Payload for `PATCH /zones/{zone_id}/settings/{setting_id}`.
#[derive(Debug, Serialize)]
pub struct CfSettingPatch {
    /// New value for the setting.
    pub value: serde_json::Value,
}

/// Payload for creating a DNS record via `POST /zones/{zone_id}/dns_records`.
#[derive(Debug, Serialize)]
pub struct CfDnsRecordCreate {
    /// Record type: "A", "AAAA", "CNAME", "MX", "TXT", etc.
    #[serde(rename = "type")]
    pub record_type: String,
    /// Hostname.
    pub name: String,
    /// Record value.
    pub content: String,
    /// TTL in seconds (1 = automatic).
    pub ttl: u32,
    /// Whether to proxy through Cloudflare.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub proxied: Option<bool>,
    /// Priority for MX/SRV records.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<u16>,
    /// Optional comment.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub comment: Option<String>,
}

/// Payload for updating a DNS record via `PATCH /zones/{zone_id}/dns_records/{record_id}`.
#[derive(Debug, Serialize)]
pub struct CfDnsRecordPatch {
    /// Record type (required even for patches).
    #[serde(rename = "type")]
    pub record_type: String,
    /// Hostname.
    pub name: String,
    /// Record value.
    pub content: String,
    /// TTL in seconds.
    pub ttl: u32,
    /// Whether to proxy through Cloudflare.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub proxied: Option<bool>,
    /// Priority for MX/SRV records.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<u16>,
    /// Optional comment.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub comment: Option<String>,
}

// ============================================================================
// Bulk operation types (internal, not from CF API)
// ============================================================================

/// Progress update for a bulk hardening operation. Serialised to JSON and
/// sent to the frontend via Tauri events for real-time progress updates.
#[derive(Debug, Serialize, Clone)]
pub struct BulkOperationProgress {
    /// Total number of zone operations.
    pub total: u32,
    /// Number completed so far.
    pub completed: u32,
    /// Number that failed.
    pub failed: u32,
    /// Which domain is currently being processed.
    pub current_domain: Option<String>,
    /// ISO 8601 when the operation started.
    pub started_at: String,
    /// (domain, error_message) pairs for failures.
    pub errors: Vec<(String, String)>,
}

// ---------------------------------------------------------------------------
// Smoke tests — CF API envelope and type invariants
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_cf_api_response_success_parse() {
        let json = r#"{"success":true,"errors":[],"messages":[],"result":"ok"}"#;
        let resp: CfApiResponse<String> = serde_json::from_str(json)
            .expect("CfApiResponse<String> must parse");
        assert!(resp.success);
        assert!(resp.errors.is_empty());
        assert_eq!(resp.result, Some("ok".to_string()));
    }

    #[test]
    fn smoke_cf_api_response_failure_parse() {
        let json = r#"{"success":false,"errors":[{"code":1003,"message":"Invalid zone"}],"messages":[],"result":null}"#;
        let resp: CfApiResponse<serde_json::Value> = serde_json::from_str(json)
            .expect("Failed CfApiResponse must parse");
        assert!(!resp.success);
        assert_eq!(resp.errors.len(), 1);
        assert_eq!(resp.errors[0].code, 1003);
    }

    #[test]
    fn smoke_cf_api_error_has_code_and_message() {
        let err = CfApiError { code: 7003, message: "Could not route to /zones".to_string() };
        assert_eq!(err.code, 7003);
        assert!(!err.message.is_empty());
    }
}
