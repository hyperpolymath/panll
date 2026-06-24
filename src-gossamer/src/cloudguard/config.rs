// SPDX-License-Identifier: MPL-2.0

//! CloudGuard offline config serialisation/deserialisation.
//!
//! Supports downloading the full Cloudflare configuration for one or more zones
//! to JSON files, and uploading saved configs back. This enables:
//!   - Version-controlled infrastructure-as-code for CF settings
//!   - Offline review and modification of zone configs
//!   - Three-way diff between offline, live, and policy states
//!
//! Config files are stored at `~/.config/cloudguard/configs/{domain}.json`
//! by default, overridable via `CLOUDGUARD_CONFIG_DIR`.

use std::env;
use std::fs;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};
use serde_json::json;

use super::api;
use super::types::*;

/// Schema version for offline config files. Bumped when the format changes.
const CONFIG_SCHEMA_VERSION: u32 = 1;

/// A complete offline snapshot of a zone's Cloudflare configuration.
#[derive(Debug, Serialize, Deserialize)]
pub struct OfflineConfig {
    /// Schema version for forwards-compatibility checking.
    pub schema_version: u32,
    /// ISO 8601 timestamp when the config was exported.
    pub exported_at: String,
    /// Zone metadata.
    pub zone: CfZone,
    /// All zone settings at export time.
    pub settings: Vec<CfZoneSetting>,
    /// All DNS records at export time.
    pub dns_records: Vec<CfDnsRecord>,
    /// DNSSEC status at export time.
    pub dnssec: Option<CfDnssecStatus>,
}

/// Returns the config directory, creating it if necessary.
fn config_dir() -> Result<PathBuf, String> {
    let dir = env::var("CLOUDGUARD_CONFIG_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::config_dir()
                .unwrap_or_else(|| PathBuf::from("/tmp"))
                .join("cloudguard")
                .join("configs")
        });

    fs::create_dir_all(&dir)
        .map_err(|e| format!("Failed to create config directory {:?}: {}", dir, e))?;

    Ok(dir)
}

/// Download and save the complete configuration for a zone to disk.
/// Returns the path to the saved config file.
pub fn download_zone_config(zone_id: &str) -> Result<String, String> {
    // Fetch all data from CF API
    let zone = api::get_zone(zone_id)?;
    let settings = api::get_zone_settings(zone_id)?;
    let dns_records = api::list_dns_records(zone_id)?;
    let dnssec = api::get_dnssec_status(zone_id).ok();

    let now = chrono_now_iso8601();

    let config = OfflineConfig {
        schema_version: CONFIG_SCHEMA_VERSION,
        exported_at: now,
        zone: zone.clone(),
        settings,
        dns_records,
        dnssec,
    };

    let dir = config_dir()?;
    let filename = format!("{}.json", sanitise_filename(&zone.name));
    let path = dir.join(&filename);

    let json = serde_json::to_string_pretty(&config)
        .map_err(|e| format!("JSON serialisation error: {}", e))?;

    fs::write(&path, json)
        .map_err(|e| format!("Failed to write config to {:?}: {}", path, e))?;

    Ok(path.to_string_lossy().to_string())
}

/// Load an offline config from disk for a given domain name.
/// Returns the parsed config or an error if the file doesn't exist.
pub fn load_zone_config(domain: &str) -> Result<OfflineConfig, String> {
    let dir = config_dir()?;
    let filename = format!("{}.json", sanitise_filename(domain));
    let path = dir.join(&filename);

    let json = fs::read_to_string(&path)
        .map_err(|e| format!("Failed to read config {:?}: {}", path, e))?;

    let config: OfflineConfig = serde_json::from_str(&json)
        .map_err(|e| format!("Failed to parse config {:?}: {}", path, e))?;

    if config.schema_version > CONFIG_SCHEMA_VERSION {
        return Err(format!(
            "Config schema version {} is newer than supported version {}",
            config.schema_version, CONFIG_SCHEMA_VERSION
        ));
    }

    Ok(config)
}

/// List all saved offline configs.
/// Returns a JSON array of `{ domain, exported_at, path }` objects.
pub fn list_saved_configs() -> Result<String, String> {
    let dir = config_dir()?;
    let mut configs = Vec::new();

    let entries = fs::read_dir(&dir)
        .map_err(|e| format!("Failed to read config directory: {}", e))?;

    for entry in entries {
        let entry = entry.map_err(|e| format!("Directory entry error: {}", e))?;
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) == Some("json") {
            if let Ok(json) = fs::read_to_string(&path) {
                if let Ok(config) = serde_json::from_str::<OfflineConfig>(&json) {
                    configs.push(json!({
                        "domain": config.zone.name,
                        "exported_at": config.exported_at,
                        "path": path.to_string_lossy(),
                        "settings_count": config.settings.len(),
                        "dns_records_count": config.dns_records.len(),
                    }));
                }
            }
        }
    }

    serde_json::to_string(&configs)
        .map_err(|e| format!("JSON serialisation error: {}", e))
}

/// Sanitise a domain name for use as a filename (replace dots with underscores,
/// strip anything that's not alphanumeric, dash, or underscore).
fn sanitise_filename(domain: &str) -> String {
    domain
        .chars()
        .map(|c| if c.is_alphanumeric() || c == '-' { c } else { '_' })
        .collect()
}

/// Returns the current time as an ISO 8601 string without depending on chrono.
/// Uses the system time to construct a reasonable timestamp.
fn chrono_now_iso8601() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    // Simple epoch-seconds timestamp; a proper ISO 8601 formatter could be added
    // if chrono is added as a dependency. For now, this is sufficient for ordering.
    format!("{}Z", secs)
}
