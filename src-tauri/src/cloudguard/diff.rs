// SPDX-License-Identifier: PMPL-1.0-or-later

//! CloudGuard three-way config diff engine.
//!
//! Compares three sources of truth for zone settings:
//!   1. **Offline** — saved config from `config.rs`
//!   2. **Live** — current state from Cloudflare API
//!   3. **Policy** — desired state from Trustfile/Nickel policy
//!
//! Produces a list of diff entries, each describing one setting that differs
//! between at least two sources. The frontend renders these in the
//! `CloudGuardDiffViewer.res` component with merge-conflict-style UI.

use serde::Serialize;
use serde_json::Value;

use super::api;
use super::config;
use super::types::*;

/// A single entry in the three-way diff. One per setting that differs.
#[derive(Debug, Serialize, Clone)]
pub struct DiffEntry {
    /// CF setting ID (e.g. "ssl", "min_tls_version").
    pub setting_id: String,
    /// Domain name for context.
    pub domain: String,
    /// Value in the offline config (None if setting absent).
    pub offline_value: Option<String>,
    /// Value currently live on Cloudflare (None if setting absent).
    pub live_value: Option<String>,
    /// Value from the policy (None if not specified by policy).
    pub policy_value: Option<String>,
    /// Whether all three sources agree (false if any differ).
    pub in_sync: bool,
    /// Whether this is a three-way conflict (all three differ).
    pub is_conflict: bool,
}

/// Complete diff result for a zone.
#[derive(Debug, Serialize)]
pub struct DiffResult {
    /// Domain name.
    pub domain: String,
    /// When the diff was computed (epoch seconds).
    pub timestamp: String,
    /// All diff entries.
    pub entries: Vec<DiffEntry>,
    /// Number of settings in sync across all three sources.
    pub in_sync_count: u32,
    /// Number of two-way drifts (offline vs live, or either vs policy).
    pub drift_count: u32,
    /// Number of three-way conflicts.
    pub conflict_count: u32,
}

/// Stringify a serde_json::Value for comparison. Normalises "on"/"off" booleans,
/// removes whitespace from objects, and handles nested structures.
fn normalise_value(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        Value::Bool(b) => if *b { "on".to_string() } else { "off".to_string() },
        Value::Number(n) => n.to_string(),
        Value::Null => "null".to_string(),
        _ => serde_json::to_string(v).unwrap_or_else(|_| "?".to_string()),
    }
}

/// Compute a three-way diff for a zone. Loads the offline config from disk,
/// fetches live settings from CF API, and compares against the provided policy
/// defaults.
///
/// `policy_defaults` is a map of setting_id -> expected value (as JSON strings).
/// If no policy is provided, the diff is two-way (offline vs live).
pub fn compute_diff(
    zone_id: &str,
    domain: &str,
    policy_defaults: &[(String, String)],
) -> Result<DiffResult, String> {
    // Fetch live settings from CF API
    let live_settings = api::get_zone_settings(zone_id)?;

    // Load offline config (may not exist)
    let offline_settings = config::load_zone_config(domain)
        .ok()
        .map(|c| c.settings)
        .unwrap_or_default();

    // Build lookup maps
    let live_map: std::collections::HashMap<&str, &Value> = live_settings
        .iter()
        .map(|s| (s.id.as_str(), &s.value))
        .collect();

    let offline_map: std::collections::HashMap<&str, &Value> = offline_settings
        .iter()
        .map(|s| (s.id.as_str(), &s.value))
        .collect();

    let policy_map: std::collections::HashMap<&str, &str> = policy_defaults
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_str()))
        .collect();

    // Collect all setting IDs from all three sources
    let mut all_ids: Vec<&str> = Vec::new();
    for id in live_map.keys() {
        if !all_ids.contains(id) {
            all_ids.push(id);
        }
    }
    for id in offline_map.keys() {
        if !all_ids.contains(id) {
            all_ids.push(id);
        }
    }
    for id in policy_map.keys() {
        if !all_ids.contains(id) {
            all_ids.push(id);
        }
    }
    all_ids.sort();

    let mut entries = Vec::new();
    let mut in_sync_count = 0u32;
    let mut drift_count = 0u32;
    let mut conflict_count = 0u32;

    for id in &all_ids {
        let offline_val = offline_map.get(id).map(|v| normalise_value(v));
        let live_val = live_map.get(id).map(|v| normalise_value(v));
        let policy_val = policy_map.get(id).map(|s| s.to_string());

        // Check if all present values agree
        let values: Vec<&String> = [&offline_val, &live_val, &policy_val]
            .iter()
            .filter_map(|v| v.as_ref())
            .collect();

        let all_same = values.windows(2).all(|w| w[0] == w[1]);
        let all_differ = values.len() >= 3
            && values[0] != values[1]
            && values[1] != values[2]
            && values[0] != values[2];

        if all_same && values.len() > 1 {
            in_sync_count += 1;
        } else if all_differ {
            conflict_count += 1;
            entries.push(DiffEntry {
                setting_id: id.to_string(),
                domain: domain.to_string(),
                offline_value: offline_val,
                live_value: live_val,
                policy_value: policy_val,
                in_sync: false,
                is_conflict: true,
            });
        } else if !all_same && values.len() > 1 {
            drift_count += 1;
            entries.push(DiffEntry {
                setting_id: id.to_string(),
                domain: domain.to_string(),
                offline_value: offline_val,
                live_value: live_val,
                policy_value: policy_val,
                in_sync: false,
                is_conflict: false,
            });
        }
        // If only one source has the value, skip it (no comparison possible)
    }

    let timestamp = super::config::list_saved_configs()
        .ok()
        .and_then(|_| Some(format!("{}Z", std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0))))
        .unwrap_or_default();

    Ok(DiffResult {
        domain: domain.to_string(),
        timestamp,
        entries,
        in_sync_count,
        drift_count,
        conflict_count,
    })
}
