// SPDX-License-Identifier: PMPL-1.0-or-later

//! CloudGuard Cloudflare API client — rate-limited reqwest wrapper.
//!
//! All Cloudflare API v4 calls go through this module. It handles:
//! - Bearer token authentication (token from env var or OS keyring)
//! - Request rate limiting (1200 req/5min = 4 req/sec average; we use 3/sec)
//! - Pagination for list endpoints
//! - Error extraction from the CF API envelope
//!
//! Uses `reqwest::blocking` to match PanLL's existing pattern (VeriSimDB,
//! ECHIDNA). Tauri spawns these on a blocking thread pool automatically.

use std::env;
use std::sync::Mutex;
use std::time::{Duration, Instant};

use once_cell::sync::Lazy;
use reqwest::blocking::Client;

use super::types::*;

/// Cloudflare API base URL. Override with `CLOUDFLARE_API_URL` for testing.
const CF_API_BASE: &str = "https://api.cloudflare.com/client/v4";

/// Rate limiter: minimum interval between requests (333ms = ~3 req/sec).
/// CF allows 1200/5min for most endpoints, but we leave headroom for
/// concurrent browser sessions and other API consumers.
const MIN_REQUEST_INTERVAL: Duration = Duration::from_millis(333);

/// Thread-safe timestamp of the last API request, used for rate limiting.
static LAST_REQUEST: Lazy<Mutex<Instant>> = Lazy::new(|| {
    Mutex::new(Instant::now() - MIN_REQUEST_INTERVAL)
});

/// Returns the CF API base URL, respecting the `CLOUDFLARE_API_URL` override.
fn cf_api_base() -> String {
    env::var("CLOUDFLARE_API_URL").unwrap_or_else(|_| CF_API_BASE.to_string())
}

/// Returns the CF API token from `CLOUDFLARE_API_TOKEN` env var.
/// In the Tauri app, this is set from the OS keyring at startup.
/// Returns an error if no token is configured.
fn cf_api_token() -> Result<String, String> {
    env::var("CLOUDFLARE_API_TOKEN")
        .map_err(|_| "CLOUDFLARE_API_TOKEN not set. Configure your Cloudflare API token.".to_string())
}

/// Waits if necessary to respect the rate limit, then updates the timestamp.
/// This is a simple token-bucket with a capacity of 1 and a refill rate of
/// 3 tokens/sec. Fine for sequential Tauri commands; for bulk operations,
/// the caller should batch and pace explicitly.
fn rate_limit_wait() {
    let mut last = LAST_REQUEST.lock().unwrap_or_else(|e| e.into_inner());
    let elapsed = last.elapsed();
    if elapsed < MIN_REQUEST_INTERVAL {
        std::thread::sleep(MIN_REQUEST_INTERVAL - elapsed);
    }
    *last = Instant::now();
}

/// Creates a configured reqwest blocking client with sensible timeouts.
fn http_client(timeout_secs: u64) -> Result<Client, String> {
    Client::builder()
        .timeout(Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))
}

/// Extracts a human-readable error from a CF API response that failed.
fn extract_cf_errors<T>(resp: &CfApiResponse<T>) -> String {
    if resp.errors.is_empty() {
        "Unknown Cloudflare API error".to_string()
    } else {
        resp.errors
            .iter()
            .map(|e| format!("[{}] {}", e.code, e.message))
            .collect::<Vec<_>>()
            .join("; ")
    }
}

// ============================================================================
// Zone operations
// ============================================================================

/// List all zones in the account, paginating automatically.
/// Returns all zones across all pages.
pub fn list_zones() -> Result<Vec<CfZone>, String> {
    let token = cf_api_token()?;
    let client = http_client(15)?;
    let base = cf_api_base();
    let mut all_zones = Vec::new();
    let mut page = 1u32;

    loop {
        rate_limit_wait();
        let url = format!("{}/zones?page={}&per_page=50&order=name", base, page);
        let resp = client
            .get(&url)
            .bearer_auth(&token)
            .send()
            .map_err(|e| format!("CF API request failed: {}", e))?;

        let body: CfApiResponse<Vec<CfZone>> = resp
            .json()
            .map_err(|e| format!("Failed to parse zones response: {}", e))?;

        if !body.success {
            return Err(extract_cf_errors(&body));
        }

        if let Some(zones) = body.result {
            let count = zones.len();
            all_zones.extend(zones);
            // Check if we've fetched all pages
            if let Some(info) = &body.result_info {
                if page >= info.total_pages || count == 0 {
                    break;
                }
            } else if count < 50 {
                break;
            }
        } else {
            break;
        }
        page += 1;
    }

    Ok(all_zones)
}

/// Get details for a single zone by ID.
pub fn get_zone(zone_id: &str) -> Result<CfZone, String> {
    let token = cf_api_token()?;
    let client = http_client(10)?;
    rate_limit_wait();

    let url = format!("{}/zones/{}", cf_api_base(), zone_id);
    let resp = client
        .get(&url)
        .bearer_auth(&token)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<CfZone> = resp
        .json()
        .map_err(|e| format!("Failed to parse zone response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "Zone not found".to_string())
}

// ============================================================================
// Settings operations
// ============================================================================

/// Get all settings for a zone. Returns the full settings array.
pub fn get_zone_settings(zone_id: &str) -> Result<Vec<CfZoneSetting>, String> {
    let token = cf_api_token()?;
    let client = http_client(15)?;
    rate_limit_wait();

    let url = format!("{}/zones/{}/settings", cf_api_base(), zone_id);
    let resp = client
        .get(&url)
        .bearer_auth(&token)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<Vec<CfZoneSetting>> = resp
        .json()
        .map_err(|e| format!("Failed to parse settings response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "No settings returned".to_string())
}

/// Update a single zone setting by ID.
pub fn update_zone_setting(
    zone_id: &str,
    setting_id: &str,
    value: serde_json::Value,
) -> Result<CfZoneSetting, String> {
    let token = cf_api_token()?;
    let client = http_client(10)?;
    rate_limit_wait();

    let url = format!("{}/zones/{}/settings/{}", cf_api_base(), zone_id, setting_id);
    let patch = CfSettingPatch { value };

    let resp = client
        .patch(&url)
        .bearer_auth(&token)
        .json(&patch)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<CfZoneSetting> = resp
        .json()
        .map_err(|e| format!("Failed to parse setting update response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "Setting update returned no result".to_string())
}

/// Batch-update multiple settings for a zone in a single API call.
/// Uses `PATCH /zones/{zone_id}/settings` with an array of `{id, value}` items.
pub fn update_zone_settings_batch(
    zone_id: &str,
    settings: Vec<(String, serde_json::Value)>,
) -> Result<Vec<CfZoneSetting>, String> {
    let token = cf_api_token()?;
    let client = http_client(30)?;
    rate_limit_wait();

    let url = format!("{}/zones/{}/settings", cf_api_base(), zone_id);
    let items: Vec<serde_json::Value> = settings
        .into_iter()
        .map(|(id, value)| serde_json::json!({ "id": id, "value": value }))
        .collect();

    let resp = client
        .patch(&url)
        .bearer_auth(&token)
        .json(&serde_json::json!({ "items": items }))
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<Vec<CfZoneSetting>> = resp
        .json()
        .map_err(|e| format!("Failed to parse batch settings response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "Batch settings update returned no result".to_string())
}

// ============================================================================
// DNS operations
// ============================================================================

/// List all DNS records for a zone, paginating automatically.
pub fn list_dns_records(zone_id: &str) -> Result<Vec<CfDnsRecord>, String> {
    let token = cf_api_token()?;
    let client = http_client(15)?;
    let base = cf_api_base();
    let mut all_records = Vec::new();
    let mut page = 1u32;

    loop {
        rate_limit_wait();
        let url = format!(
            "{}/zones/{}/dns_records?page={}&per_page=100&order=name",
            base, zone_id, page
        );
        let resp = client
            .get(&url)
            .bearer_auth(&token)
            .send()
            .map_err(|e| format!("CF API request failed: {}", e))?;

        let body: CfApiResponse<Vec<CfDnsRecord>> = resp
            .json()
            .map_err(|e| format!("Failed to parse DNS records response: {}", e))?;

        if !body.success {
            return Err(extract_cf_errors(&body));
        }

        if let Some(records) = body.result {
            let count = records.len();
            all_records.extend(records);
            if let Some(info) = &body.result_info {
                if page >= info.total_pages || count == 0 {
                    break;
                }
            } else if count < 100 {
                break;
            }
        } else {
            break;
        }
        page += 1;
    }

    Ok(all_records)
}

/// Create a new DNS record in a zone.
pub fn create_dns_record(
    zone_id: &str,
    record: &CfDnsRecordCreate,
) -> Result<CfDnsRecord, String> {
    let token = cf_api_token()?;
    let client = http_client(10)?;
    rate_limit_wait();

    let url = format!("{}/zones/{}/dns_records", cf_api_base(), zone_id);
    let resp = client
        .post(&url)
        .bearer_auth(&token)
        .json(record)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<CfDnsRecord> = resp
        .json()
        .map_err(|e| format!("Failed to parse DNS create response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "DNS record creation returned no result".to_string())
}

/// Update an existing DNS record.
pub fn update_dns_record(
    zone_id: &str,
    record_id: &str,
    patch: &CfDnsRecordPatch,
) -> Result<CfDnsRecord, String> {
    let token = cf_api_token()?;
    let client = http_client(10)?;
    rate_limit_wait();

    let url = format!(
        "{}/zones/{}/dns_records/{}",
        cf_api_base(),
        zone_id,
        record_id
    );
    let resp = client
        .patch(&url)
        .bearer_auth(&token)
        .json(patch)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<CfDnsRecord> = resp
        .json()
        .map_err(|e| format!("Failed to parse DNS update response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "DNS record update returned no result".to_string())
}

/// Delete a DNS record by ID.
pub fn delete_dns_record(zone_id: &str, record_id: &str) -> Result<(), String> {
    let token = cf_api_token()?;
    let client = http_client(10)?;
    rate_limit_wait();

    let url = format!(
        "{}/zones/{}/dns_records/{}",
        cf_api_base(),
        zone_id,
        record_id
    );
    let resp = client
        .delete(&url)
        .bearer_auth(&token)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let status = resp.status();
    if status.is_success() {
        Ok(())
    } else {
        let body: Result<CfApiResponse<serde_json::Value>, _> = resp.json();
        match body {
            Ok(b) => Err(extract_cf_errors(&b)),
            Err(_) => Err(format!("DNS record deletion failed with status {}", status)),
        }
    }
}

// ============================================================================
// DNSSEC operations
// ============================================================================

/// Get DNSSEC status for a zone.
pub fn get_dnssec_status(zone_id: &str) -> Result<CfDnssecStatus, String> {
    let token = cf_api_token()?;
    let client = http_client(10)?;
    rate_limit_wait();

    let url = format!("{}/zones/{}/dnssec", cf_api_base(), zone_id);
    let resp = client
        .get(&url)
        .bearer_auth(&token)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<CfDnssecStatus> = resp
        .json()
        .map_err(|e| format!("Failed to parse DNSSEC response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "No DNSSEC status returned".to_string())
}

/// Enable DNSSEC for a zone via `PATCH /zones/{zone_id}/dnssec`.
pub fn enable_dnssec(zone_id: &str) -> Result<CfDnssecStatus, String> {
    let token = cf_api_token()?;
    let client = http_client(10)?;
    rate_limit_wait();

    let url = format!("{}/zones/{}/dnssec", cf_api_base(), zone_id);
    let resp = client
        .patch(&url)
        .bearer_auth(&token)
        .json(&serde_json::json!({ "status": "active" }))
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<CfDnssecStatus> = resp
        .json()
        .map_err(|e| format!("Failed to parse DNSSEC enable response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    body.result.ok_or_else(|| "DNSSEC enable returned no result".to_string())
}

// ============================================================================
// Verify token (health check)
// ============================================================================

/// Verify the API token by calling `GET /user/tokens/verify`.
/// Returns the account email on success.
pub fn verify_token() -> Result<String, String> {
    let token = cf_api_token()?;
    let client = http_client(5)?;
    rate_limit_wait();

    let url = format!("{}/user/tokens/verify", cf_api_base());
    let resp = client
        .get(&url)
        .bearer_auth(&token)
        .send()
        .map_err(|e| format!("CF API request failed: {}", e))?;

    let body: CfApiResponse<serde_json::Value> = resp
        .json()
        .map_err(|e| format!("Failed to parse token verify response: {}", e))?;

    if !body.success {
        return Err(extract_cf_errors(&body));
    }

    // Extract status from result
    if let Some(result) = &body.result {
        if let Some(status) = result.get("status").and_then(|s| s.as_str()) {
            if status == "active" {
                return Ok(format!("Token verified (status: {})", status));
            }
        }
    }

    Err("Token verification returned unexpected response".to_string())
}
