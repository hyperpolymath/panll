// SPDX-License-Identifier: PMPL-1.0-or-later

//! CloudGuard Tauri command handlers.
//!
//! Each `#[tauri::command]` function is a thin wrapper around the API client
//! (`super::api`) that serialises results to JSON strings for the frontend.
//! This matches the PanLL pattern where Tauri commands return `Result<String, String>`
//! and the ReScript frontend parses the JSON.
//!
//! Commands:
//!   - `cloudguard_verify_token` — verify CF API token (health check)
//!   - `cloudguard_list_zones` — list all zones in the account
//!   - `cloudguard_get_zone` — get details for a single zone
//!   - `cloudguard_get_settings` — get all settings for a zone
//!   - `cloudguard_update_setting` — update a single zone setting
//!   - `cloudguard_update_settings_batch` — batch-update multiple settings
//!   - `cloudguard_list_dns_records` — list DNS records for a zone
//!   - `cloudguard_create_dns_record` — create a new DNS record
//!   - `cloudguard_update_dns_record` — update an existing DNS record
//!   - `cloudguard_delete_dns_record` — delete a DNS record
//!   - `cloudguard_get_dnssec` — get DNSSEC status for a zone
//!   - `cloudguard_enable_dnssec` — enable DNSSEC for a zone
//!   - `cloudguard_harden_zone` — apply hardening settings to a zone

use serde::Deserialize;
use serde_json::json;

use super::api;
use super::types::*;

// ============================================================================
// Token verification (health check)
// ============================================================================

/// Verify the Cloudflare API token. Returns a JSON string with token status.
/// Frontend calls this on panel open and periodically to maintain connection state.

pub fn cloudguard_verify_token() -> Result<String, String> {
    let status = api::verify_token()?;
    Ok(json!({ "status": "connected", "message": status }).to_string())
}

// ============================================================================
// Zone operations
// ============================================================================

/// List all zones (domains) in the Cloudflare account.
/// Returns a JSON array of zone objects.

pub fn cloudguard_list_zones() -> Result<String, String> {
    let zones = api::list_zones()?;
    serde_json::to_string(&zones).map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Get details for a single zone by ID.
/// Returns a JSON zone object.

pub fn cloudguard_get_zone(zone_id: String) -> Result<String, String> {
    let zone = api::get_zone(&zone_id)?;
    serde_json::to_string(&zone).map_err(|e| format!("JSON serialisation error: {}", e))
}

// ============================================================================
// Settings operations
// ============================================================================

/// Get all settings for a zone.
/// Returns a JSON array of setting objects with id, value, editable, modified_on.

pub fn cloudguard_get_settings(zone_id: String) -> Result<String, String> {
    let settings = api::get_zone_settings(&zone_id)?;
    serde_json::to_string(&settings).map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Update a single zone setting by ID.
/// `value` is a JSON-encoded string that gets parsed to `serde_json::Value`.
/// Returns the updated setting as JSON.

pub fn cloudguard_update_setting(
    zone_id: String,
    setting_id: String,
    value: String,
) -> Result<String, String> {
    let parsed_value: serde_json::Value =
        serde_json::from_str(&value).map_err(|e| format!("Invalid JSON value: {}", e))?;
    let updated = api::update_zone_setting(&zone_id, &setting_id, parsed_value)?;
    serde_json::to_string(&updated).map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Batch-update multiple settings for a zone.
/// `settings_json` is a JSON-encoded array of `[{"id": "...", "value": ...}]`.
/// Returns the updated settings as JSON.

pub fn cloudguard_update_settings_batch(
    zone_id: String,
    settings_json: String,
) -> Result<String, String> {
    let items: Vec<serde_json::Value> =
        serde_json::from_str(&settings_json).map_err(|e| format!("Invalid JSON: {}", e))?;

    let settings: Vec<(String, serde_json::Value)> = items
        .into_iter()
        .filter_map(|item| {
            let id = item.get("id")?.as_str()?.to_string();
            let value = item.get("value")?.clone();
            Some((id, value))
        })
        .collect();

    if settings.is_empty() {
        return Err("No valid settings to update".to_string());
    }

    let updated = api::update_zone_settings_batch(&zone_id, settings)?;
    serde_json::to_string(&updated).map_err(|e| format!("JSON serialisation error: {}", e))
}

// ============================================================================
// DNS record operations
// ============================================================================

/// List all DNS records for a zone.
/// Returns a JSON array of DNS record objects.

pub fn cloudguard_list_dns_records(zone_id: String) -> Result<String, String> {
    let records = api::list_dns_records(&zone_id)?;
    serde_json::to_string(&records).map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Deserialisable payload for creating a DNS record via Tauri command.
#[derive(Deserialize)]
pub struct CreateDnsRecordPayload {
    pub zone_id: String,
    pub record_type: String,
    pub name: String,
    pub content: String,
    pub ttl: u32,
    pub proxied: Option<bool>,
    pub priority: Option<u16>,
    pub comment: Option<String>,
}

/// Create a new DNS record in a zone.
/// Returns the created record as JSON.

pub fn cloudguard_create_dns_record(payload: CreateDnsRecordPayload) -> Result<String, String> {
    let record = CfDnsRecordCreate {
        record_type: payload.record_type,
        name: payload.name,
        content: payload.content,
        ttl: payload.ttl,
        proxied: payload.proxied,
        priority: payload.priority,
        comment: payload.comment,
    };
    let created = api::create_dns_record(&payload.zone_id, &record)?;
    serde_json::to_string(&created).map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Deserialisable payload for updating a DNS record via Tauri command.
#[derive(Deserialize)]
pub struct UpdateDnsRecordPayload {
    pub zone_id: String,
    pub record_id: String,
    pub record_type: String,
    pub name: String,
    pub content: String,
    pub ttl: u32,
    pub proxied: Option<bool>,
    pub priority: Option<u16>,
    pub comment: Option<String>,
}

/// Update an existing DNS record.
/// Returns the updated record as JSON.

pub fn cloudguard_update_dns_record(payload: UpdateDnsRecordPayload) -> Result<String, String> {
    let patch = CfDnsRecordPatch {
        record_type: payload.record_type,
        name: payload.name,
        content: payload.content,
        ttl: payload.ttl,
        proxied: payload.proxied,
        priority: payload.priority,
        comment: payload.comment,
    };
    let updated = api::update_dns_record(&payload.zone_id, &payload.record_id, &patch)?;
    serde_json::to_string(&updated).map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Delete a DNS record from a zone.
/// Returns a success message.

pub fn cloudguard_delete_dns_record(zone_id: String, record_id: String) -> Result<String, String> {
    api::delete_dns_record(&zone_id, &record_id)?;
    Ok(json!({ "status": "deleted", "record_id": record_id }).to_string())
}

// ============================================================================
// DNSSEC operations
// ============================================================================

/// Get DNSSEC status for a zone.
/// Returns DNSSEC status JSON including DS record info.

pub fn cloudguard_get_dnssec(zone_id: String) -> Result<String, String> {
    let status = api::get_dnssec_status(&zone_id)?;
    serde_json::to_string(&status).map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Enable DNSSEC for a zone.
/// Returns the updated DNSSEC status as JSON.

pub fn cloudguard_enable_dnssec(zone_id: String) -> Result<String, String> {
    let status = api::enable_dnssec(&zone_id)?;
    serde_json::to_string(&status).map_err(|e| format!("JSON serialisation error: {}", e))
}

// ============================================================================
// Hardening — apply security defaults to a zone
// ============================================================================

/// Apply the standard hardening settings to a zone. This is the "Harden" button
/// in the UI. It batch-updates SSL/TLS, HSTS, headers, and other security settings
/// to their recommended values.
///
/// Settings applied:
///   - ssl: "full_strict"
///   - min_tls_version: "1.2"
///   - always_use_https: "on"
///   - automatic_https_rewrites: "on"
///   - opportunistic_encryption: "on"
///   - tls_1_3: "zrt"
///   - security_header (HSTS): max-age 31536000, includeSubDomains, preload, nosniff
///   - browser_check: "on"
///   - hotlink_protection: "on"
///   - email_obfuscation: "on"
///   - server_side_exclude: "on"
///   - ip_geolocation: "on"
///   - websockets: "on"
///   - http3: "on"
///   - 0rtt: "on"
///   - brotli: "on"
///   - early_hints: "on"

pub fn cloudguard_harden_zone(zone_id: String) -> Result<String, String> {
    let hsts_value = json!({
        "strict_transport_security": {
            "enabled": true,
            "max_age": 31536000,
            "include_subdomains": true,
            "preload": true,
            "nosniff": true
        }
    });

    let settings: Vec<(String, serde_json::Value)> = vec![
        ("ssl".to_string(), json!("full_strict")),
        ("min_tls_version".to_string(), json!("1.2")),
        ("always_use_https".to_string(), json!("on")),
        ("automatic_https_rewrites".to_string(), json!("on")),
        ("opportunistic_encryption".to_string(), json!("on")),
        ("tls_1_3".to_string(), json!("zrt")),
        ("security_header".to_string(), hsts_value),
        ("browser_check".to_string(), json!("on")),
        ("hotlink_protection".to_string(), json!("on")),
        ("email_obfuscation".to_string(), json!("on")),
        ("server_side_exclude".to_string(), json!("on")),
        ("ip_geolocation".to_string(), json!("on")),
        ("websockets".to_string(), json!("on")),
        ("http3".to_string(), json!("on")),
        ("0rtt".to_string(), json!("on")),
        ("brotli".to_string(), json!("on")),
        ("early_hints".to_string(), json!("on")),
    ];

    let updated = api::update_zone_settings_batch(&zone_id, settings)?;
    let result = json!({
        "status": "hardened",
        "zone_id": zone_id,
        "settings_updated": updated.len(),
    });
    Ok(result.to_string())
}

/// Download the offline configuration for a zone. Fetches settings and DNS
/// records, saves them to `~/.config/cloudguard/configs/{domain}.json`,
/// and returns the file path and metadata.

pub fn cloudguard_download_config(zone_id: String) -> Result<String, String> {
    let path = super::config::download_zone_config(&zone_id)?;
    let result = json!({
        "status": "downloaded",
        "zone_id": zone_id,
        "path": path,
    });
    Ok(result.to_string())
}
