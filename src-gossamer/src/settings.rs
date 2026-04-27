// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Settings — PanLL configuration persistence and management.
//!
//! Stores user-configurable settings in `~/.panll/config.json` with optional
//! VeriSimDB sync. The disk file is the source of truth for bootstrap (before
//! VeriSimDB is reachable); VeriSimDB holds the canonical version once connected.
//!
//! Settings include: service URLs, paths, theme, auto-save interval, and
//! service auto-connect preference.

use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::sync::Mutex;

/// PanLL user settings.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PanllSettings {
    /// VeriSimDB base URL.
    pub verisimdb_url: String,
    /// ECHIDNA theorem prover base URL.
    pub echidna_url: String,
    /// Burble voice server base URL.
    pub burble_url: String,
    /// BoJ cartridge server base URL.
    pub boj_url: String,
    /// TypeLL type verification kernel base URL.
    pub typell_url: String,
    /// PanLL configuration directory path.
    pub config_dir: String,
    /// UI theme name (e.g. "DarkStart", "LightMode", "Ambient").
    pub theme: String,
    /// Interval between automatic state saves (milliseconds).
    pub auto_save_interval_ms: u64,
    /// Whether to automatically connect to services on startup.
    pub auto_connect_services: bool,
}

impl Default for PanllSettings {
    fn default() -> Self {
        Self {
            verisimdb_url: std::env::var("VERISIMDB_URL")
                .unwrap_or_else(|_| "http://localhost:8080".into()),
            echidna_url: std::env::var("ECHIDNA_URL")
                .unwrap_or_else(|_| "http://localhost:9000".into()),
            burble_url: std::env::var("BURBLE_URL")
                .unwrap_or_else(|_| "http://localhost:6473".into()),
            boj_url: std::env::var("BOJ_URL")
                .unwrap_or_else(|_| "http://localhost:7700".into()),
            typell_url: std::env::var("TYPELL_URL")
                .unwrap_or_else(|_| "http://localhost:7800".into()),
            config_dir: config_dir().to_string_lossy().into_owned(),
            theme: "DarkStart".into(),
            auto_save_interval_ms: 30_000,
            auto_connect_services: true,
        }
    }
}

/// PanLL config directory: `~/.panll/`.
fn config_dir() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".panll")
}

/// Full path to `~/.panll/config.json`.
fn config_path() -> PathBuf {
    config_dir().join("config.json")
}

/// Global settings instance, loaded from disk on first access.
static SETTINGS: Lazy<Mutex<PanllSettings>> = Lazy::new(|| {
    let settings = match fs::read_to_string(config_path()) {
        Ok(contents) => serde_json::from_str::<PanllSettings>(&contents)
            .unwrap_or_default(),
        Err(_) => PanllSettings::default(),
    };
    Mutex::new(settings)
});

/// Persist current settings to `~/.panll/config.json`.
fn persist_to_disk(settings: &PanllSettings) -> Result<(), String> {
    let dir = config_dir();
    if !dir.exists() {
        fs::create_dir_all(&dir)
            .map_err(|e| format!("Failed to create config dir: {}", e))?;
    }
    let json = serde_json::to_string_pretty(settings)
        .map_err(|e| format!("JSON serialise error: {}", e))?;
    fs::write(config_path(), json)
        .map_err(|e| format!("Failed to write config: {}", e))
}

/// Get all settings as a JSON Value.
pub fn settings_get() -> Result<serde_json::Value, String> {
    let settings = SETTINGS.lock().map_err(|e| format!("Settings lock: {}", e))?;
    serde_json::to_value(&*settings).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Set a single setting by key. Persists to disk immediately.
pub fn settings_set(key: &str, value: &str) -> Result<serde_json::Value, String> {
    let mut settings = SETTINGS.lock().map_err(|e| format!("Settings lock: {}", e))?;

    match key {
        "verisimdb_url" => settings.verisimdb_url = value.to_string(),
        "echidna_url" => settings.echidna_url = value.to_string(),
        "burble_url" => settings.burble_url = value.to_string(),
        "boj_url" => settings.boj_url = value.to_string(),
        "typell_url" => settings.typell_url = value.to_string(),
        "theme" => settings.theme = value.to_string(),
        "auto_save_interval_ms" => {
            settings.auto_save_interval_ms = value
                .parse::<u64>()
                .map_err(|e| format!("Invalid integer: {}", e))?;
        }
        "auto_connect_services" => {
            settings.auto_connect_services = value
                .parse::<bool>()
                .map_err(|e| format!("Invalid boolean: {}", e))?;
        }
        _ => return Err(format!("Unknown setting: {}", key)),
    }

    persist_to_disk(&settings)?;
    serde_json::to_value(&*settings).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Replace all settings from a JSON string. Persists to disk immediately.
pub fn settings_save(settings_json: &str) -> Result<serde_json::Value, String> {
    let new_settings: PanllSettings = serde_json::from_str(settings_json)
        .map_err(|e| format!("Invalid settings JSON: {}", e))?;
    let mut settings = SETTINGS.lock().map_err(|e| format!("Settings lock: {}", e))?;
    *settings = new_settings;
    persist_to_disk(&settings)?;
    serde_json::to_value(&*settings).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Reset all settings to defaults. Persists to disk immediately.
pub fn settings_reset() -> Result<serde_json::Value, String> {
    let mut settings = SETTINGS.lock().map_err(|e| format!("Settings lock: {}", e))?;
    *settings = PanllSettings::default();
    persist_to_disk(&settings)?;
    serde_json::to_value(&*settings).map_err(|e| format!("JSON serialise error: {}", e))
}
