// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! K9 Tauri commands — filesystem operations for K9 contractile files.
//!
//! These commands provide the bridge between the PanLL frontend (ReScript) and
//! the host filesystem for K9 (.k9.ncl) files. They handle:
//!   - Loading K9 file content for client-side parsing
//!   - Basic structural validation (existence, encoding, K9 markers)
//!   - Layout preset discovery and application

use serde_json::json;
use std::path::{Path, PathBuf};

/// Locate the repository root by searching upward for `.git` or `0-AI-MANIFEST.a2ml`.
fn find_repo_root() -> Result<PathBuf, String> {
    let cwd = std::env::current_dir()
        .map_err(|e| format!("Cannot determine working directory: {}", e))?;

    let mut dir = cwd.as_path();
    loop {
        if dir.join(".git").exists() || dir.join("0-AI-MANIFEST.a2ml").exists() {
            return Ok(dir.to_path_buf());
        }
        match dir.parent() {
            Some(parent) => dir = parent,
            None => return Err("Could not find repository root".to_string()),
        }
    }
}

/// Detect the K9 security level from file content.
///
/// Returns one of "kennel", "yard", or "hunt" based on:
///   1. Explicit `leash = 'Level` declaration (takes priority)
///   2. Presence of `recipes` block → Hunt
///   3. Presence of Nickel contracts (`| Type`) → Yard
///   4. Otherwise → Kennel
fn detect_security_level(content: &str) -> &'static str {
    // Check explicit leash declarations first
    if content.contains("leash = 'Hunt") {
        return "hunt";
    }
    if content.contains("leash = 'Yard") {
        return "yard";
    }
    if content.contains("leash = 'Kennel") {
        return "kennel";
    }

    // Implicit detection
    if content.contains("recipes = {") || content.contains("recipes=") {
        "hunt"
    } else if content.contains("| String")
        || content.contains("| Number")
        || content.contains("| Bool")
        || content.contains("| Array")
        || content.contains("| std.contract")
        || content.contains("| std.string")
        || content.contains("| std.array")
    {
        "yard"
    } else {
        "kennel"
    }
}

/// Load a K9 contractile file from disk.
///
/// Returns the file content as a JSON object with `path`, `content`,
/// `securityLevel`, and `hasK9Magic` fields.

pub fn k9_load_contractile(path: String) -> Result<String, String> {
    let file_path = if Path::new(&path).is_absolute() {
        PathBuf::from(&path)
    } else {
        let root = find_repo_root()?;
        root.join(&path)
    };

    if !file_path.exists() {
        return Err(format!("K9 file not found: {}", path));
    }

    let content = std::fs::read_to_string(&file_path)
        .map_err(|e| format!("Failed to read {}: {}", path, e))?;

    let security_level = detect_security_level(&content);
    let has_k9_magic = content.trim_start().starts_with("K9!");

    let result = json!({
        "path": path,
        "content": content,
        "size": content.len(),
        "securityLevel": security_level,
        "hasK9Magic": has_k9_magic,
    });

    Ok(result.to_string())
}

/// Validate a K9 contractile file.
///
/// Performs basic structural checks:
///   - File exists and is readable
///   - File is non-empty
///   - File is valid UTF-8
///   - K9 magic header present (for K9 template files)
///   - Pedigree block present
///   - Security level detection
///   - Hunt-level files must have `signature_required = true`
///
/// Returns a JSON object with `valid`, `errors`, `warnings`, and `securityLevel`.

pub fn k9_validate(path: String) -> Result<String, String> {
    let file_path = if Path::new(&path).is_absolute() {
        PathBuf::from(&path)
    } else {
        let root = find_repo_root()?;
        root.join(&path)
    };

    let mut errors: Vec<String> = Vec::new();
    let mut warnings: Vec<String> = Vec::new();

    // Check existence
    if !file_path.exists() {
        errors.push(format!("File not found: {}", path));
        let result = json!({
            "valid": false,
            "errors": errors,
            "warnings": warnings,
            "path": path,
            "securityLevel": "unknown",
        });
        return Ok(result.to_string());
    }

    // Read content
    let content = match std::fs::read_to_string(&file_path) {
        Ok(c) => c,
        Err(e) => {
            errors.push(format!("Cannot read file (encoding error?): {}", e));
            let result = json!({
                "valid": false,
                "errors": errors,
                "warnings": warnings,
                "path": path,
                "securityLevel": "unknown",
            });
            return Ok(result.to_string());
        }
    };

    // Check non-empty
    let trimmed = content.trim();
    if trimmed.is_empty() {
        errors.push("File is empty".to_string());
        let result = json!({
            "valid": false,
            "errors": errors,
            "warnings": warnings,
            "path": path,
            "securityLevel": "unknown",
        });
        return Ok(result.to_string());
    }

    let security_level = detect_security_level(&content);
    let has_k9_magic = trimmed.starts_with("K9!");

    // Check for pedigree block (unless it's a layout file that imports pedigree)
    let has_pedigree = content.contains("pedigree = {") || content.contains("pedigree=");
    let is_layout = content.contains("LayoutPreset") || content.contains("import");
    if !has_pedigree && !is_layout {
        errors.push("Missing pedigree block".to_string());
    }

    // K9 magic check for template-derived files
    if has_pedigree && !has_k9_magic && !is_layout {
        warnings.push("K9 template file missing K9! magic header".to_string());
    }

    // SPDX check
    if !content.contains("SPDX-License-Identifier") {
        warnings.push("Missing SPDX-License-Identifier header".to_string());
    }

    // Hunt-level specific checks
    if security_level == "hunt" {
        if !content.contains("signature_required = true") {
            errors.push("Hunt-level K9 must have signature_required = true".to_string());
        }
        if !content.contains("side_effects") {
            errors.push("Hunt-level K9 must declare side_effects".to_string());
        }
        if !content.contains("warnings") {
            warnings.push("Hunt-level K9 should include warnings list".to_string());
        }
    }

    let valid = errors.is_empty();
    let result = json!({
        "valid": valid,
        "errors": errors,
        "warnings": warnings,
        "path": path,
        "securityLevel": security_level,
        "hasK9Magic": has_k9_magic,
        "isLayout": is_layout,
        "size": content.len(),
        "lineCount": content.lines().count(),
    });

    Ok(result.to_string())
}

/// Apply a K9 layout preset by name.
///
/// Searches the `layouts/` directory for a matching `.k9.ncl` file and returns
/// its content as JSON for client-side parsing by K9Engine. The layout name
/// is matched case-insensitively with hyphens replacing spaces.
///
/// Example: `name = "Protocol Design"` matches `layouts/protocol-design.k9.ncl`.

pub fn k9_apply_layout(name: String) -> Result<String, String> {
    let root = find_repo_root()?;
    let layouts_dir = root.join("layouts");

    if !layouts_dir.exists() {
        return Err("No layouts/ directory found in repository".to_string());
    }

    // Normalise the name: lowercase and replace spaces with hyphens
    let normalised = name.to_lowercase().replace(' ', "-");

    // Search for matching layout file
    let entries = std::fs::read_dir(&layouts_dir)
        .map_err(|e| format!("Cannot read layouts directory: {}", e))?;

    for entry in entries.flatten() {
        let path = entry.path();
        if let Some(filename) = path.file_name() {
            let filename_str = filename.to_string_lossy().to_lowercase();
            if filename_str.ends_with(".k9.ncl")
                && filename_str.contains(&normalised)
            {
                let content = std::fs::read_to_string(&path)
                    .map_err(|e| format!("Failed to read layout {}: {}", filename_str, e))?;

                let rel_path = path
                    .strip_prefix(&root)
                    .map(|p| p.to_string_lossy().to_string())
                    .unwrap_or_else(|_| path.to_string_lossy().to_string());

                let result = json!({
                    "path": rel_path,
                    "content": content,
                    "name": name,
                    "securityLevel": detect_security_level(&content),
                });

                return Ok(result.to_string());
            }
        }
    }

    // List available layouts for helpful error message
    let available: Vec<String> = std::fs::read_dir(&layouts_dir)
        .map(|entries| {
            entries
                .flatten()
                .filter_map(|e| {
                    let name = e.file_name().to_string_lossy().to_string();
                    if name.ends_with(".k9.ncl") {
                        Some(name.replace(".k9.ncl", ""))
                    } else {
                        None
                    }
                })
                .collect()
        })
        .unwrap_or_default();

    Err(format!(
        "Layout '{}' not found. Available layouts: {}",
        name,
        available.join(", ")
    ))
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_security_level_kennel() {
        let content = r#"
K9!
{
  pedigree = {
    security = { leash = 'Kennel },
  },
  config = { key = "value" },
}
"#;
        assert_eq!(detect_security_level(content), "kennel");
    }

    #[test]
    fn test_detect_security_level_yard() {
        let content = r#"
K9!
{
  pedigree = {
    security = { leash = 'Yard },
  },
  config = {
    name | String | std.string.NonEmpty = "test",
  },
}
"#;
        assert_eq!(detect_security_level(content), "yard");
    }

    #[test]
    fn test_detect_security_level_hunt() {
        let content = r#"
K9!
{
  pedigree = {
    security = { leash = 'Hunt, signature_required = true },
    side_effects = ["writes files"],
  },
  recipes = {
    default = { recipe = "build" },
  },
}
"#;
        assert_eq!(detect_security_level(content), "hunt");
    }

    #[test]
    fn test_detect_security_level_implicit_yard() {
        // No explicit leash, but has Nickel contracts
        let content = r#"
{
  config = {
    port | Number = 8080,
    name | String = "test",
  },
}
"#;
        assert_eq!(detect_security_level(content), "yard");
    }

    #[test]
    fn test_detect_security_level_implicit_hunt() {
        // No explicit leash, but has recipes
        let content = r#"
{
  config = { target = "/tmp" },
  recipes = {
    build = { commands = ["echo hello"] },
  },
}
"#;
        assert_eq!(detect_security_level(content), "hunt");
    }

    #[test]
    fn test_detect_security_level_implicit_kennel() {
        // No leash, no contracts, no recipes
        let content = r#"
{
  config = {
    key = "value",
    count = 42,
  },
}
"#;
        assert_eq!(detect_security_level(content), "kennel");
    }

    #[test]
    fn test_k9_load_contractile_missing_file() {
        let result = k9_load_contractile("/nonexistent/path/to/file.k9.ncl".to_string());
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not found"));
    }

    #[test]
    fn test_k9_validate_missing_file() {
        let result = k9_validate("/nonexistent/path/to/file.k9.ncl".to_string());
        assert!(result.is_ok());
        let json_str = result.unwrap();
        assert!(json_str.contains("\"valid\":false"));
        assert!(json_str.contains("File not found"));
    }

    #[test]
    fn test_k9_validate_with_kennel_file() {
        let tmp = std::env::temp_dir().join("panll-k9-kennel-test.k9.ncl");
        std::fs::write(
            &tmp,
            r#"K9!
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    security = { leash = 'Kennel },
  },
  config = { key = "value" },
}"#,
        )
        .unwrap();

        let result = k9_validate(tmp.to_string_lossy().to_string());
        assert!(result.is_ok());
        let json_str = result.unwrap();
        assert!(json_str.contains("\"valid\":true"));
        assert!(json_str.contains("\"securityLevel\":\"kennel\""));
        let _ = std::fs::remove_file(&tmp);
    }

    #[test]
    fn test_k9_validate_hunt_without_signature() {
        let tmp = std::env::temp_dir().join("panll-k9-hunt-nosig-test.k9.ncl");
        std::fs::write(
            &tmp,
            r#"K9!
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    security = { leash = 'Hunt },
  },
  recipes = {
    build = { commands = ["echo hello"] },
  },
}"#,
        )
        .unwrap();

        let result = k9_validate(tmp.to_string_lossy().to_string());
        assert!(result.is_ok());
        let json_str = result.unwrap();
        assert!(json_str.contains("\"valid\":false"));
        assert!(json_str.contains("signature_required"));
        let _ = std::fs::remove_file(&tmp);
    }

    #[test]
    fn test_k9_validate_empty_file() {
        let tmp = std::env::temp_dir().join("panll-k9-empty-test.k9.ncl");
        std::fs::write(&tmp, "").unwrap();
        let result = k9_validate(tmp.to_string_lossy().to_string());
        assert!(result.is_ok());
        let json_str = result.unwrap();
        assert!(json_str.contains("\"valid\":false"));
        assert!(json_str.contains("empty"));
        let _ = std::fs::remove_file(&tmp);
    }

    #[test]
    fn test_k9_apply_layout_not_found() {
        let result = k9_apply_layout("nonexistent-layout".to_string());
        assert!(result.is_err());
    }
}
