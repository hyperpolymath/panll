// SPDX-License-Identifier: PMPL-1.0-or-later

//! Release Manager Tauri commands — changelog generation, artifact building,
//! release publishing, version history, and semver bumping.
//!
//! Commands:
//!   - `release_generate_changelog`: Generate a changelog from git history.
//!   - `release_build_artifacts`: Build artifacts for specified platforms.
//!   - `release_publish`: Publish a release to a channel.
//!   - `release_read_history`: Read release history.
//!   - `release_bump_version`: Bump the version number (major/minor/patch).

use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use serde_json::json;

/// Base directory for release manager storage.
const RELEASES_DIR: &str = "/tmp/panll/releases";

/// Ensure the releases directory exists, creating it lazily if needed.
fn ensure_releases_dir() -> Result<PathBuf, String> {
    let path = PathBuf::from(RELEASES_DIR);
    fs::create_dir_all(&path)
        .map_err(|e| format!("Cannot create releases directory {RELEASES_DIR}: {e}"))?;
    Ok(path)
}

/// Return the current Unix timestamp in seconds.
fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

/// Parse a semver string into (major, minor, patch).
/// Returns None if the version string is not valid semver.
fn parse_semver(version: &str) -> Option<(u32, u32, u32)> {
    let trimmed = version.strip_prefix('v').unwrap_or(version);
    let parts: Vec<&str> = trimmed.split('.').collect();
    if parts.len() != 3 {
        return None;
    }
    let major = parts[0].parse::<u32>().ok()?;
    let minor = parts[1].parse::<u32>().ok()?;
    let patch = parts[2].parse::<u32>().ok()?;
    Some((major, minor, patch))
}

/// Generate a changelog from git history.
///
/// Accepts a `fromVersion` string and returns stub changelog entries
/// representing commits since that version. When full git integration is
/// implemented, this will run `git log` against the IDApTIK repository.
#[tauri::command]
pub async fn release_generate_changelog(from_version: String) -> Result<String, String> {
    let ts = now_secs();

    let result = json!({
        "fromVersion": from_version,
        "entries": [
            {
                "version": "next",
                "date": format!("{}", ts),
                "category": "feature",
                "description": "Added multiplayer monitor panel",
                "commitHash": "abc1234",
                "author": "Jonathan D.A. Jewell",
            },
            {
                "version": "next",
                "date": format!("{}", ts),
                "category": "fix",
                "description": "Fixed DLC puzzle validation edge case",
                "commitHash": "def5678",
                "author": "Jonathan D.A. Jewell",
            },
            {
                "version": "next",
                "date": format!("{}", ts),
                "category": "refactor",
                "description": "Migrated game preview to async commands",
                "commitHash": "ghi9012",
                "author": "Jonathan D.A. Jewell",
            },
        ],
        "totalEntries": 3,
        "stub": true,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Build artifacts for the specified platforms.
///
/// Accepts a version string and a comma-separated list of platform targets.
/// Currently returns stub artifact metadata. When full build integration is
/// implemented, this will invoke Tauri's build pipeline for each target.
#[tauri::command]
pub async fn release_build_artifacts(
    version: String,
    platforms: String,
) -> Result<String, String> {
    if version.is_empty() {
        return Err("Version cannot be empty".to_string());
    }

    let platform_list: Vec<&str> = platforms.split(',').map(|s| s.trim()).collect();
    if platform_list.is_empty() {
        return Err("At least one platform must be specified".to_string());
    }

    let valid_platforms = [
        "web", "desktop-linux", "desktop-mac", "desktop-windows",
        "mobile-android", "mobile-ios",
    ];

    for p in &platform_list {
        if !valid_platforms.contains(p) {
            return Err(format!(
                "Unknown platform: {p}. Valid platforms: {}",
                valid_platforms.join(", ")
            ));
        }
    }

    let ts = now_secs() as f64;
    let artifacts: Vec<serde_json::Value> = platform_list
        .iter()
        .map(|p| {
            json!({
                "name": format!("idaptik-{version}-{p}"),
                "platform": p,
                "filePath": format!("/tmp/panll/releases/{version}/idaptik-{version}-{p}.tar.gz"),
                "sizeBytes": 15_000_000,
                "checksum": format!("sha256:stub-{p}-{version}"),
                "builtAt": ts,
            })
        })
        .collect();

    let result = json!({
        "version": version,
        "platforms": platform_list,
        "artifacts": artifacts,
        "status": "ready",
        "stub": true,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Publish a release to a channel.
///
/// Accepts a version string and a release channel (dev, alpha, beta, rc,
/// stable). Creates a release manifest in the releases directory. When full
/// distribution is implemented, this will upload artifacts and create a
/// GitHub release.
#[tauri::command]
pub async fn release_publish(
    version: String,
    channel: String,
) -> Result<String, String> {
    if version.is_empty() {
        return Err("Version cannot be empty".to_string());
    }

    let valid_channels = ["dev", "alpha", "beta", "rc", "stable"];
    if !valid_channels.contains(&channel.as_str()) {
        return Err(format!(
            "Unknown channel: {channel}. Valid channels: {}",
            valid_channels.join(", ")
        ));
    }

    let releases_dir = ensure_releases_dir()?;
    let ts = now_secs();

    let release = json!({
        "version": version,
        "channel": channel,
        "status": "published",
        "publishedAt": ts,
    });

    let release_path = releases_dir.join(format!("release-{version}-{channel}.json"));
    fs::write(
        &release_path,
        serde_json::to_string_pretty(&release).unwrap_or_default(),
    )
    .map_err(|e| format!("Cannot write release manifest: {e}"))?;

    let result = json!({
        "published": true,
        "version": version,
        "channel": channel,
        "manifestPath": release_path.to_string_lossy(),
        "publishedAt": ts,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Read release history.
///
/// Scans the releases directory for release manifest files and returns
/// them as a JSON array sorted by publication time (newest first).
#[tauri::command]
pub async fn release_read_history() -> Result<String, String> {
    let releases_dir = ensure_releases_dir()?;

    let mut releases: Vec<serde_json::Value> = fs::read_dir(&releases_dir)
        .map_err(|e| format!("Cannot read releases directory: {e}"))?
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            let name = entry.file_name().to_string_lossy().to_string();
            name.starts_with("release-") && name.ends_with(".json")
        })
        .filter_map(|entry| {
            let content = fs::read_to_string(entry.path()).ok()?;
            serde_json::from_str(&content).ok()
        })
        .collect();

    // Sort by publishedAt descending (newest first).
    releases.sort_by(|a, b| {
        let ts_a = a.get("publishedAt").and_then(|v| v.as_u64()).unwrap_or(0);
        let ts_b = b.get("publishedAt").and_then(|v| v.as_u64()).unwrap_or(0);
        ts_b.cmp(&ts_a)
    });

    serde_json::to_string(&releases)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Bump the version number.
///
/// Accepts a bump type ("major", "minor", or "patch") and returns the
/// bumped version. Reads the current version from a `version.json` file
/// in the releases directory, defaulting to "0.1.0" if none exists.
#[tauri::command]
pub async fn release_bump_version(bump_type: String) -> Result<String, String> {
    let valid_bump_types = ["major", "minor", "patch"];
    if !valid_bump_types.contains(&bump_type.as_str()) {
        return Err(format!(
            "Unknown bump type: {bump_type}. Expected one of: major, minor, patch"
        ));
    }

    let releases_dir = ensure_releases_dir()?;
    let version_path = releases_dir.join("version.json");

    // Read current version or default to 0.1.0.
    let current_version = if version_path.exists() {
        let content = fs::read_to_string(&version_path)
            .map_err(|e| format!("Cannot read version file: {e}"))?;
        let version_json: serde_json::Value = serde_json::from_str(&content)
            .map_err(|e| format!("Cannot parse version file: {e}"))?;
        version_json
            .get("version")
            .and_then(|v| v.as_str())
            .unwrap_or("0.1.0")
            .to_string()
    } else {
        "0.1.0".to_string()
    };

    let (major, minor, patch) = parse_semver(&current_version)
        .ok_or_else(|| format!("Cannot parse current version: {current_version}"))?;

    let (new_major, new_minor, new_patch) = match bump_type.as_str() {
        "major" => (major + 1, 0, 0),
        "minor" => (major, minor + 1, 0),
        "patch" => (major, minor, patch + 1),
        _ => unreachable!(),
    };

    let new_version = format!("{new_major}.{new_minor}.{new_patch}");

    // Persist the new version.
    let version_data = json!({
        "version": new_version,
        "previousVersion": current_version,
        "bumpType": bump_type,
        "bumpedAt": now_secs(),
    });

    fs::write(
        &version_path,
        serde_json::to_string_pretty(&version_data).unwrap_or_default(),
    )
    .map_err(|e| format!("Cannot write version file: {e}"))?;

    serde_json::to_string(&version_data)
        .map_err(|e| format!("Serialisation error: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use once_cell::sync::Lazy;

    /// Serialise tests that share filesystem state to prevent race conditions.
    static TEST_LOCK: Lazy<std::sync::Mutex<()>> = Lazy::new(|| std::sync::Mutex::new(()));

    /// Helper: create a tokio runtime for async command tests.
    fn rt() -> tokio::runtime::Runtime {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("Failed to create tokio runtime for tests")
    }

    /// Reset the version file to a known state.
    fn reset_version_file() {
        let version_path = PathBuf::from(RELEASES_DIR).join("version.json");
        let _ = fs::remove_file(version_path);
    }

    /// Clean up release manifests created during tests.
    fn cleanup_release(version: &str, channel: &str) {
        let path =
            PathBuf::from(RELEASES_DIR).join(format!("release-{version}-{channel}.json"));
        let _ = fs::remove_file(path);
    }

    #[test]
    fn test_parse_semver_valid() {
        assert_eq!(parse_semver("1.2.3"), Some((1, 2, 3)));
        assert_eq!(parse_semver("v0.1.0"), Some((0, 1, 0)));
        assert_eq!(parse_semver("10.20.30"), Some((10, 20, 30)));
    }

    #[test]
    fn test_parse_semver_invalid() {
        assert_eq!(parse_semver("not-a-version"), None);
        assert_eq!(parse_semver("1.2"), None);
        assert_eq!(parse_semver(""), None);
    }

    #[test]
    fn test_ensure_releases_dir() {
        let result = ensure_releases_dir();
        assert!(result.is_ok(), "Should create releases directory");
        let path = result.unwrap();
        assert!(path.exists(), "Releases directory should exist after creation");
    }

    #[test]
    fn test_release_generate_changelog() {
        rt().block_on(async {
            let result = release_generate_changelog("0.1.0".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["fromVersion"], "0.1.0");
            assert_eq!(json["totalEntries"], 3);
            let entries = json["entries"].as_array().unwrap();
            assert_eq!(entries.len(), 3);
        });
    }

    #[test]
    fn test_release_build_artifacts_valid() {
        rt().block_on(async {
            let result =
                release_build_artifacts("1.0.0".to_string(), "web, desktop-linux".to_string())
                    .await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["version"], "1.0.0");
            assert_eq!(json["status"], "ready");
            let artifacts = json["artifacts"].as_array().unwrap();
            assert_eq!(artifacts.len(), 2);
        });
    }

    #[test]
    fn test_release_build_artifacts_empty_version() {
        rt().block_on(async {
            let result = release_build_artifacts("".to_string(), "web".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Version cannot be empty"));
        });
    }

    #[test]
    fn test_release_build_artifacts_invalid_platform() {
        rt().block_on(async {
            let result =
                release_build_artifacts("1.0.0".to_string(), "commodore64".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Unknown platform"));
        });
    }

    #[test]
    fn test_release_publish_valid() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        rt().block_on(async {
            let result = release_publish("0.2.0-test".to_string(), "dev".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["published"], true);
            assert_eq!(json["version"], "0.2.0-test");
            assert_eq!(json["channel"], "dev");

            cleanup_release("0.2.0-test", "dev");
        });
    }

    #[test]
    fn test_release_publish_invalid_channel() {
        rt().block_on(async {
            let result =
                release_publish("1.0.0".to_string(), "nightly".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Unknown channel"));
        });
    }

    #[test]
    fn test_release_read_history() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        rt().block_on(async {
            let result = release_read_history().await;
            assert!(result.is_ok());
            let releases: Vec<serde_json::Value> =
                serde_json::from_str(&result.unwrap()).unwrap();
            // Should be a valid array (may be empty or contain previous test releases).
            assert!(releases.len() >= 0);
        });
    }

    #[test]
    fn test_release_bump_version_patch() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_version_file();
        rt().block_on(async {
            let result = release_bump_version("patch".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["version"], "0.1.1");
            assert_eq!(json["previousVersion"], "0.1.0");
            assert_eq!(json["bumpType"], "patch");
        });
        reset_version_file();
    }

    #[test]
    fn test_release_bump_version_minor() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_version_file();
        rt().block_on(async {
            let result = release_bump_version("minor".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["version"], "0.2.0");
        });
        reset_version_file();
    }

    #[test]
    fn test_release_bump_version_major() {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        reset_version_file();
        rt().block_on(async {
            let result = release_bump_version("major".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["version"], "1.0.0");
        });
        reset_version_file();
    }

    #[test]
    fn test_release_bump_version_invalid() {
        rt().block_on(async {
            let result = release_bump_version("huge".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Unknown bump type"));
        });
    }
}
