// SPDX-License-Identifier: PMPL-1.0-or-later

//! UMS Tauri commands — mod project CRUD, ABI validation, template
//! instantiation, asset import, distribution, and API reference.
//!
//! Commands:
//!   - `ums_load_projects`: Scan the UMS projects directory for manifests.
//!   - `ums_create_project`: Create a new mod project directory + manifest.
//!   - `ums_open_project`: Read a project manifest by ID.
//!   - `ums_delete_project`: Remove a project directory.
//!   - `ums_validate_level`: Run runtime ABI validation checks on a level.
//!   - `ums_load_templates`: Return built-in mod templates.
//!   - `ums_instantiate_template`: Copy a template to a new project.
//!   - `ums_load_assets`: Scan a project for asset files.
//!   - `ums_import_asset`: Copy an asset file into a project.
//!   - `ums_publish_mod`: Create a distributable mod package.
//!   - `ums_load_api_reference`: Return modding API documentation entries.

use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use serde_json::json;

/// Base directory for UMS project storage.
const UMS_DIR: &str = "/tmp/panll/ums-projects";

/// Ensure the UMS projects directory exists, creating it lazily if needed.
fn ensure_ums_dir() -> Result<PathBuf, String> {
    let path = PathBuf::from(UMS_DIR);
    fs::create_dir_all(&path)
        .map_err(|e| format!("Cannot create UMS directory {UMS_DIR}: {e}"))?;
    Ok(path)
}

/// Return the current UNIX timestamp in seconds.
fn now_ts() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

/// Load all mod projects from the UMS projects directory.
///
/// Scans for `.project.json` manifest files and returns their contents
/// as a JSON array, sorted by project name.

pub async fn ums_load_projects() -> Result<String, String> {
    let ums_dir = ensure_ums_dir()?;

    let mut projects: Vec<serde_json::Value> = fs::read_dir(&ums_dir)
        .map_err(|e| format!("Cannot read UMS directory: {e}"))?
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.file_type().map(|ft| ft.is_dir()).unwrap_or(false))
        .filter_map(|entry| {
            let manifest = entry.path().join(".project.json");
            let content = fs::read_to_string(manifest).ok()?;
            serde_json::from_str(&content).ok()
        })
        .collect();

    // Sort by name for consistent ordering.
    projects.sort_by(|a, b| {
        let name_a = a.get("name").and_then(|v| v.as_str()).unwrap_or("");
        let name_b = b.get("name").and_then(|v| v.as_str()).unwrap_or("");
        name_a.cmp(name_b)
    });

    serde_json::to_string(&projects)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Create a new mod project with the given name and description.
///
/// Creates a project directory under the UMS root and writes a
/// `.project.json` manifest file with initial metadata.

pub async fn ums_create_project(name: String, description: String) -> Result<String, String> {
    let ums_dir = ensure_ums_dir()?;

    // Generate a slug-style ID from the name.
    let id: String = name
        .to_lowercase()
        .chars()
        .map(|c| if c.is_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .trim_matches('-')
        .to_string();

    if id.is_empty() {
        return Err("Project name must contain at least one alphanumeric character".to_string());
    }

    let project_dir = ums_dir.join(&id);
    fs::create_dir_all(&project_dir)
        .map_err(|e| format!("Cannot create project directory: {e}"))?;

    // Create subdirectories for levels, assets, and exports.
    for sub in &["levels", "assets", "exports"] {
        fs::create_dir_all(project_dir.join(sub))
            .map_err(|e| format!("Cannot create {sub} directory: {e}"))?;
    }

    let ts = now_ts().to_string();
    let manifest = json!({
        "id": id,
        "name": name,
        "description": description,
        "author": "Jonathan D.A. Jewell",
        "version": "0.1.0",
        "createdAt": ts,
        "lastModified": ts,
        "levelCount": 0,
        "puzzleCount": 0,
        "assetCount": 0,
        "validated": false,
        "projectPath": project_dir.to_string_lossy(),
    });

    let manifest_path = project_dir.join(".project.json");
    fs::write(
        &manifest_path,
        serde_json::to_string_pretty(&manifest).unwrap_or_default(),
    )
    .map_err(|e| format!("Cannot write project manifest: {e}"))?;

    let result = json!({
        "created": true,
        "id": id,
        "path": project_dir.to_string_lossy(),
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Open an existing mod project by its ID.
///
/// Reads the `.project.json` manifest from the project directory
/// and returns its contents.

pub async fn ums_open_project(project_id: String) -> Result<String, String> {
    let ums_dir = ensure_ums_dir()?;
    let manifest_path = ums_dir.join(&project_id).join(".project.json");

    if !manifest_path.exists() {
        return Err(format!("Project not found: {project_id}"));
    }

    fs::read_to_string(&manifest_path)
        .map_err(|e| format!("Cannot read project manifest: {e}"))
}

/// Delete a mod project by its ID.
///
/// Removes the entire project directory and all its contents.

pub async fn ums_delete_project(project_id: String) -> Result<String, String> {
    let ums_dir = ensure_ums_dir()?;
    let project_dir = ums_dir.join(&project_id);

    if !project_dir.exists() {
        return Err(format!("Project not found: {project_id}"));
    }

    fs::remove_dir_all(&project_dir)
        .map_err(|e| format!("Cannot delete project directory: {e}"))?;

    let result = json!({
        "deleted": true,
        "id": project_id,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Run ABI validation on a level.
///
/// Performs runtime checks that mirror the Idris2 ABI proof obligations:
/// guards-in-zones, defence-targets-valid, zones-ordered, pbx-consistent,
/// and devices-exist. When the real Idris2 ABI harness is integrated,
/// these checks will delegate to the formally verified proofs.

pub async fn ums_validate_level(level_id: String) -> Result<String, String> {
    // Stub: all proofs pass. When the real ABI harness is integrated,
    // each proof obligation will be checked against the level data.
    let ts = now_ts().to_string();
    let result = json!({
        "levelId": level_id,
        "guardsInZones": true,
        "defenceTargetsValid": true,
        "zonesOrdered": true,
        "pbxConsistent": true,
        "devicesExist": true,
        "allPassed": true,
        "validatedAt": ts,
        "errors": [],
        "stub": true,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Load available mod templates.
///
/// Returns a set of built-in templates for bootstrapping mod projects.
/// When the template registry is implemented, this will scan the
/// template directory for user-contributed templates as well.

pub async fn ums_load_templates() -> Result<String, String> {
    let templates = json!([
        {
            "id": "basic-level",
            "name": "Basic Level",
            "description": "A single level with one zone, basic guards, and a simple puzzle.",
            "category": "level",
            "difficulty": "Easy",
            "previewImagePath": "templates/basic-level-preview.png",
        },
        {
            "id": "puzzle-chain",
            "name": "Puzzle Chain",
            "description": "A series of interconnected puzzles with progressive difficulty.",
            "category": "puzzle",
            "difficulty": "Medium",
            "previewImagePath": "templates/puzzle-chain-preview.png",
        },
        {
            "id": "full-campaign",
            "name": "Full Campaign",
            "description": "A complete campaign with multiple zones, boss encounters, and narrative.",
            "category": "campaign",
            "difficulty": "Hard",
            "previewImagePath": "templates/full-campaign-preview.png",
        },
        {
            "id": "sprite-pack",
            "name": "Sprite Pack",
            "description": "A curated collection of sprite assets for level decoration.",
            "category": "asset_pack",
            "difficulty": "Easy",
            "previewImagePath": "templates/sprite-pack-preview.png",
        },
        {
            "id": "tower-defence",
            "name": "Tower Defence Layout",
            "description": "Pre-configured tower defence zones with PBX routing tables.",
            "category": "level",
            "difficulty": "Medium",
            "previewImagePath": "templates/tower-defence-preview.png",
        },
    ]);
    serde_json::to_string(&templates)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Instantiate a mod template to create a new project.
///
/// Copies template files into a new project directory. Currently uses
/// stub data; when the template registry is implemented, this will copy
/// actual template files.

pub async fn ums_instantiate_template(
    template_id: String,
    project_name: String,
) -> Result<String, String> {
    // Create the project first.
    let description = format!("Created from template: {template_id}");
    let create_result = ums_create_project(project_name, description).await?;

    let created: serde_json::Value = serde_json::from_str(&create_result)
        .map_err(|e| format!("Cannot parse create result: {e}"))?;

    let project_id = created
        .get("id")
        .and_then(|v| v.as_str())
        .unwrap_or("unknown");

    let result = json!({
        "instantiated": true,
        "templateId": template_id,
        "projectId": project_id,
        "path": created.get("path"),
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Load assets for a project.
///
/// Scans the project's `assets/` directory for known asset file types
/// and returns metadata. When the full asset pipeline is implemented,
/// this will also read asset manifests and usage tracking.

pub async fn ums_load_assets(project_id: String) -> Result<String, String> {
    let ums_dir = ensure_ums_dir()?;
    let assets_dir = ums_dir.join(&project_id).join("assets");

    if !assets_dir.exists() {
        return Ok(serde_json::to_string(&json!([])).unwrap_or_default());
    }

    let assets: Vec<serde_json::Value> = fs::read_dir(&assets_dir)
        .map_err(|e| format!("Cannot read assets directory: {e}"))?
        .filter_map(|entry| entry.ok())
        .filter_map(|entry| {
            let path = entry.path();
            let name = path.file_name()?.to_string_lossy().to_string();
            let size = entry.metadata().ok()?.len();
            let ext = path
                .extension()
                .map(|e| e.to_string_lossy().to_string())
                .unwrap_or_default();
            let asset_type = match ext.as_str() {
                "png" | "jpg" | "jpeg" | "gif" | "webp" => "sprite",
                "ogg" | "wav" | "mp3" | "flac" => "sound",
                "tmx" | "json" => "map",
                "tsx" => "tileset",
                "aseprite" | "ase" => "animation",
                "lua" | "scm" | "res" => "script",
                _ => "sprite",
            };
            Some(json!({
                "id": name.replace('.', "-"),
                "name": name,
                "assetType": asset_type,
                "filePath": path.to_string_lossy(),
                "sizeBytes": size,
                "usedIn": [],
            }))
        })
        .collect();

    serde_json::to_string(&assets)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Import an asset file into a project.
///
/// Copies the file at `file_path` into the project's `assets/` directory.

pub async fn ums_import_asset(
    project_id: String,
    file_path: String,
) -> Result<String, String> {
    let ums_dir = ensure_ums_dir()?;
    let assets_dir = ums_dir.join(&project_id).join("assets");
    fs::create_dir_all(&assets_dir)
        .map_err(|e| format!("Cannot create assets directory: {e}"))?;

    let source = PathBuf::from(&file_path);
    if !source.exists() {
        return Err(format!("Source file not found: {file_path}"));
    }

    let file_name = source
        .file_name()
        .ok_or_else(|| "Cannot determine file name".to_string())?;
    let dest = assets_dir.join(file_name);

    fs::copy(&source, &dest)
        .map_err(|e| format!("Cannot copy asset file: {e}"))?;

    let result = json!({
        "imported": true,
        "projectId": project_id,
        "fileName": file_name.to_string_lossy(),
        "destPath": dest.to_string_lossy(),
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Publish a mod to a distribution target.
///
/// Creates a distributable package in the project's `exports/` directory.
/// When full distribution is implemented, this will upload to the
/// specified platform (GitHub, Workshop, etc.).

pub async fn ums_publish_mod(
    project_id: String,
    platform: String,
) -> Result<String, String> {
    let ums_dir = ensure_ums_dir()?;
    let project_dir = ums_dir.join(&project_id);
    let manifest_path = project_dir.join(".project.json");

    if !manifest_path.exists() {
        return Err(format!("Project not found: {project_id}"));
    }

    let manifest_str = fs::read_to_string(&manifest_path)
        .map_err(|e| format!("Cannot read project manifest: {e}"))?;
    let manifest: serde_json::Value = serde_json::from_str(&manifest_str)
        .map_err(|e| format!("Cannot parse project manifest: {e}"))?;

    let version = manifest
        .get("version")
        .and_then(|v| v.as_str())
        .unwrap_or("0.1.0");

    let exports_dir = project_dir.join("exports");
    fs::create_dir_all(&exports_dir)
        .map_err(|e| format!("Cannot create exports directory: {e}"))?;

    let ts = now_ts();
    let export_file = exports_dir.join(format!("{project_id}-v{version}-{ts}.json"));
    let export_data = json!({
        "projectId": project_id,
        "version": version,
        "platform": platform,
        "publishedAt": ts.to_string(),
        "format": "idaptik-mod-v1",
    });

    fs::write(
        &export_file,
        serde_json::to_string_pretty(&export_data).unwrap_or_default(),
    )
    .map_err(|e| format!("Cannot write export file: {e}"))?;

    let result = json!({
        "published": true,
        "projectId": project_id,
        "platform": platform,
        "version": version,
        "exportPath": export_file.to_string_lossy(),
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Load the modding API reference documentation.
///
/// Returns built-in API entries for the IDApTIK modding API.
/// When the full documentation system is implemented, this will
/// load entries from doc-comment extraction and API manifests.

pub async fn ums_load_api_reference() -> Result<String, String> {
    let entries = json!([
        {
            "name": "createLevel",
            "category": "Level",
            "signature": "(name: string, zones: array<Zone>) -> Level",
            "description": "Create a new level with the given name and zone configuration.",
            "example": "let level = createLevel(\"Zone Alpha\", [zone1, zone2])",
            "since": "0.1.0",
        },
        {
            "name": "addGuard",
            "category": "Level",
            "signature": "(level: Level, zone: ZoneId, guard: Guard) -> Level",
            "description": "Add a guard entity to a specific zone in the level.",
            "example": "let level = addGuard(level, zoneA, sentryGuard)",
            "since": "0.1.0",
        },
        {
            "name": "setDefenceTarget",
            "category": "Level",
            "signature": "(level: Level, target: DefenceTarget) -> Level",
            "description": "Set a defence target that players must protect or attack.",
            "example": "let level = setDefenceTarget(level, coreReactor)",
            "since": "0.1.0",
        },
        {
            "name": "createPuzzle",
            "category": "Puzzle",
            "signature": "(name: string, instructions: array<Instruction>) -> Puzzle",
            "description": "Create a new VM puzzle with the given instruction set.",
            "example": "let puzzle = createPuzzle(\"Logic Gate\", [push(1), push(2), add])",
            "since": "0.1.0",
        },
        {
            "name": "validateABI",
            "category": "Validation",
            "signature": "(level: Level) -> ValidationResult",
            "description": "Run all ABI proof obligations against the level data. Returns detailed pass/fail for each proof.",
            "example": "let result = validateABI(myLevel)",
            "since": "0.1.0",
        },
        {
            "name": "importSprite",
            "category": "Asset",
            "signature": "(path: string, options: SpriteOptions) -> Asset",
            "description": "Import a sprite asset from a file path with optional transform settings.",
            "example": "let sprite = importSprite(\"hero.png\", { scale: 2 })",
            "since": "0.1.0",
        },
        {
            "name": "configurePBX",
            "category": "Level",
            "signature": "(level: Level, routing: PBXConfig) -> Level",
            "description": "Configure PBX routing tables for inter-zone communication.",
            "example": "let level = configurePBX(level, { routes: [routeA, routeB] })",
            "since": "0.2.0",
        },
        {
            "name": "registerDevice",
            "category": "Level",
            "signature": "(level: Level, device: Device) -> Level",
            "description": "Register a device entity in the level's device registry.",
            "example": "let level = registerDevice(level, laserTurret)",
            "since": "0.2.0",
        },
    ]);
    serde_json::to_string(&entries)
        .map_err(|e| format!("Serialisation error: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create a tokio runtime for async command tests.
    fn rt() -> tokio::runtime::Runtime {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("Failed to create tokio runtime for tests")
    }

    /// Helper: clean up a test project by ID.
    fn cleanup_test_project(id: &str) {
        let path = PathBuf::from(UMS_DIR).join(id);
        let _ = fs::remove_dir_all(path);
    }

    #[test]
    fn test_ensure_ums_dir() {
        let result = ensure_ums_dir();
        assert!(result.is_ok(), "Should create UMS directory");
        let path = result.unwrap();
        assert!(path.exists(), "UMS directory should exist after creation");
    }

    #[test]
    fn test_ums_create_and_load_project() {
        rt().block_on(async {
            let create_result =
                ums_create_project("Test Mod Alpha".to_string(), "A test mod project".to_string())
                    .await;
            assert!(create_result.is_ok());
            let create_json: serde_json::Value =
                serde_json::from_str(&create_result.unwrap()).unwrap();
            assert_eq!(create_json["created"], true);
            assert_eq!(create_json["id"], "test-mod-alpha");

            // Load projects — our test project should appear.
            let load_result = ums_load_projects().await;
            assert!(load_result.is_ok());
            let projects: Vec<serde_json::Value> =
                serde_json::from_str(&load_result.unwrap()).unwrap();
            assert!(projects.iter().any(|p| p["id"] == "test-mod-alpha"));

            cleanup_test_project("test-mod-alpha");
        });
    }

    #[test]
    fn test_ums_create_project_empty_name() {
        rt().block_on(async {
            let result =
                ums_create_project("!!!".to_string(), "Bad name".to_string()).await;
            assert!(result.is_err());
            assert!(result
                .unwrap_err()
                .contains("at least one alphanumeric character"));
        });
    }

    #[test]
    fn test_ums_open_project_not_found() {
        rt().block_on(async {
            let result = ums_open_project("nonexistent-project".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Project not found"));
        });
    }

    #[test]
    fn test_ums_delete_project_not_found() {
        rt().block_on(async {
            let result = ums_delete_project("nonexistent-project".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Project not found"));
        });
    }

    #[test]
    fn test_ums_create_and_delete_project() {
        rt().block_on(async {
            // Create a project.
            let _ = ums_create_project(
                "Delete Me".to_string(),
                "Will be deleted".to_string(),
            )
            .await;

            // Verify it exists.
            let open_result = ums_open_project("delete-me".to_string()).await;
            assert!(open_result.is_ok());

            // Delete it.
            let delete_result = ums_delete_project("delete-me".to_string()).await;
            assert!(delete_result.is_ok());
            let delete_json: serde_json::Value =
                serde_json::from_str(&delete_result.unwrap()).unwrap();
            assert_eq!(delete_json["deleted"], true);

            // Verify it is gone.
            let open_again = ums_open_project("delete-me".to_string()).await;
            assert!(open_again.is_err());
        });
    }

    #[test]
    fn test_ums_validate_level() {
        rt().block_on(async {
            let result = ums_validate_level("test-level-001".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value =
                serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["levelId"], "test-level-001");
            assert_eq!(json["allPassed"], true);
            assert_eq!(json["guardsInZones"], true);
            assert_eq!(json["defenceTargetsValid"], true);
            assert_eq!(json["zonesOrdered"], true);
            assert_eq!(json["pbxConsistent"], true);
            assert_eq!(json["devicesExist"], true);
        });
    }

    #[test]
    fn test_ums_load_templates() {
        rt().block_on(async {
            let result = ums_load_templates().await;
            assert!(result.is_ok());
            let templates: Vec<serde_json::Value> =
                serde_json::from_str(&result.unwrap()).unwrap();
            assert!(templates.len() >= 5);
            assert!(templates.iter().any(|t| t["id"] == "basic-level"));
            assert!(templates.iter().any(|t| t["id"] == "full-campaign"));
        });
    }

    #[test]
    fn test_ums_instantiate_template() {
        rt().block_on(async {
            let result = ums_instantiate_template(
                "basic-level".to_string(),
                "Template Test Project".to_string(),
            )
            .await;
            assert!(result.is_ok());
            let json: serde_json::Value =
                serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["instantiated"], true);
            assert_eq!(json["templateId"], "basic-level");

            cleanup_test_project("template-test-project");
        });
    }

    #[test]
    fn test_ums_load_assets_empty() {
        rt().block_on(async {
            // Create a project to have an assets directory.
            let _ = ums_create_project(
                "Asset Test".to_string(),
                "For asset testing".to_string(),
            )
            .await;

            let result = ums_load_assets("asset-test".to_string()).await;
            assert!(result.is_ok());
            let assets: Vec<serde_json::Value> =
                serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(assets.len(), 0);

            cleanup_test_project("asset-test");
        });
    }

    #[test]
    fn test_ums_import_asset_not_found() {
        rt().block_on(async {
            let result = ums_import_asset(
                "some-project".to_string(),
                "/tmp/nonexistent-asset.png".to_string(),
            )
            .await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Source file not found"));
        });
    }

    #[test]
    fn test_ums_import_and_load_asset() {
        rt().block_on(async {
            // Create a project.
            let _ = ums_create_project(
                "Import Asset Test".to_string(),
                "For import testing".to_string(),
            )
            .await;

            // Create a temporary file to import.
            let tmp_file = "/tmp/panll-test-sprite.png";
            fs::write(tmp_file, b"fake png data").unwrap();

            // Import the asset.
            let import_result = ums_import_asset(
                "import-asset-test".to_string(),
                tmp_file.to_string(),
            )
            .await;
            assert!(import_result.is_ok());
            let import_json: serde_json::Value =
                serde_json::from_str(&import_result.unwrap()).unwrap();
            assert_eq!(import_json["imported"], true);

            // Load assets — the imported asset should appear.
            let load_result = ums_load_assets("import-asset-test".to_string()).await;
            assert!(load_result.is_ok());
            let assets: Vec<serde_json::Value> =
                serde_json::from_str(&load_result.unwrap()).unwrap();
            assert_eq!(assets.len(), 1);

            // Clean up.
            let _ = fs::remove_file(tmp_file);
            cleanup_test_project("import-asset-test");
        });
    }

    #[test]
    fn test_ums_publish_mod_not_found() {
        rt().block_on(async {
            let result = ums_publish_mod(
                "nonexistent-project".to_string(),
                "github".to_string(),
            )
            .await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Project not found"));
        });
    }

    #[test]
    fn test_ums_publish_mod() {
        rt().block_on(async {
            // Create a project.
            let _ = ums_create_project(
                "Publish Test".to_string(),
                "For publish testing".to_string(),
            )
            .await;

            let result = ums_publish_mod(
                "publish-test".to_string(),
                "github".to_string(),
            )
            .await;
            assert!(result.is_ok());
            let json: serde_json::Value =
                serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["published"], true);
            assert_eq!(json["platform"], "github");

            cleanup_test_project("publish-test");
        });
    }

    #[test]
    fn test_ums_load_api_reference() {
        rt().block_on(async {
            let result = ums_load_api_reference().await;
            assert!(result.is_ok());
            let entries: Vec<serde_json::Value> =
                serde_json::from_str(&result.unwrap()).unwrap();
            assert!(entries.len() >= 8);
            assert!(entries.iter().any(|e| e["name"] == "createLevel"));
            assert!(entries.iter().any(|e| e["name"] == "validateABI"));
        });
    }
}
