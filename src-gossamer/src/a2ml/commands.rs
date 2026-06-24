// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! A2ML Tauri commands — filesystem operations for A2ML manifest files.
//!
//! These commands provide the bridge between the PanLL frontend (ReScript) and
//! the host filesystem. They handle:
//!   - Loading A2ML file content for client-side parsing
//!   - Basic structural validation (existence, encoding, non-empty)
//!   - Recursive discovery of .a2ml files in the repository tree

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

/// Recursively collect all `.a2ml` files under a directory.
fn collect_a2ml_files(dir: &Path, results: &mut Vec<String>, root: &Path) {
    if let Ok(entries) = std::fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                // Skip hidden directories (except .machine_readable) and common
                // non-source directories to keep discovery fast.
                let name = entry.file_name();
                let name_str = name.to_string_lossy();
                if name_str == ".machine_readable"
                    || name_str == "panel-clades"
                    || name_str == "layouts"
                    || name_str == "src"
                    || name_str == "docs"
                {
                    collect_a2ml_files(&path, results, root);
                } else if !name_str.starts_with('.') && name_str != "node_modules" && name_str != "target" && name_str != "lib" {
                    collect_a2ml_files(&path, results, root);
                }
            } else if let Some(ext) = path.extension() {
                if ext == "a2ml" {
                    if let Ok(rel) = path.strip_prefix(root) {
                        results.push(rel.to_string_lossy().to_string());
                    } else {
                        results.push(path.to_string_lossy().to_string());
                    }
                }
            }
        }
    }
}

/// Load an A2ML manifest file from disk.
///
/// Returns the file content as a JSON object with `path` and `content` fields.
/// The ReScript A2mlEngine handles the actual parsing.

pub fn a2ml_load_manifest(path: String) -> Result<String, String> {
    let file_path = if Path::new(&path).is_absolute() {
        PathBuf::from(&path)
    } else {
        let root = find_repo_root()?;
        root.join(&path)
    };

    if !file_path.exists() {
        return Err(format!("A2ML file not found: {}", path));
    }

    let content = std::fs::read_to_string(&file_path)
        .map_err(|e| format!("Failed to read {}: {}", path, e))?;

    let result = json!({
        "path": path,
        "content": content,
        "size": content.len(),
    });

    Ok(result.to_string())
}

/// Validate an A2ML manifest file.
///
/// Performs basic structural checks:
///   - File exists and is readable
///   - File is non-empty
///   - File is valid UTF-8
///   - File contains recognisable A2ML markers (sections, S-expressions, or headers)
///
/// Returns a JSON object with `valid`, `errors`, and `warnings` fields.

pub fn a2ml_validate(path: String) -> Result<String, String> {
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
            });
            return Ok(result.to_string());
        }
    };

    // Check non-empty
    let trimmed = content.trim();
    if trimmed.is_empty() {
        errors.push("File is empty".to_string());
    }

    // Check for recognisable A2ML markers
    let has_sexpr = trimmed.starts_with(';') || trimmed.starts_with('(');
    let has_sections = trimmed.contains('[') && trimmed.contains(']');
    let has_dividers = trimmed.contains("---") && trimmed.contains("### [");
    let has_spdx = trimmed.contains("SPDX-License-Identifier");

    if !has_sexpr && !has_sections && !has_dividers {
        warnings.push("No recognisable A2ML structure (S-expressions, sections, or headers)".to_string());
    }

    if !has_spdx {
        warnings.push("Missing SPDX-License-Identifier header".to_string());
    }

    // Check file size (warn if very large — manifests should be concise)
    if content.len() > 50_000 {
        warnings.push(format!(
            "File is very large ({} bytes) — A2ML manifests should be concise",
            content.len()
        ));
    }

    let valid = errors.is_empty();
    let result = json!({
        "valid": valid,
        "errors": errors,
        "warnings": warnings,
        "path": path,
        "size": content.len(),
        "lineCount": content.lines().count(),
    });

    Ok(result.to_string())
}

/// List all `.a2ml` files in the repository.
///
/// Recursively searches the repository tree (excluding `node_modules`, `target`,
/// `lib`, and hidden directories other than `.machine_readable`). Returns a
/// JSON array of relative file paths.

pub fn a2ml_list() -> Result<String, String> {
    let root = find_repo_root()?;
    let mut files: Vec<String> = Vec::new();
    collect_a2ml_files(&root, &mut files, &root);
    files.sort();

    let result = json!({
        "files": files,
        "count": files.len(),
        "root": root.to_string_lossy(),
    });

    Ok(result.to_string())
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_find_repo_root_from_subdir() {
        // This test will work when run from within the PanLL repo
        let result = find_repo_root();
        // Should succeed or fail gracefully — we just check it doesn't panic
        match result {
            Ok(path) => assert!(path.exists()),
            Err(_) => {} // OK if not in a repo context
        }
    }

    #[test]
    fn test_a2ml_validate_missing_file() {
        let result = a2ml_validate("/nonexistent/path/to/file.a2ml".to_string());
        assert!(result.is_ok());
        let json_str = result.unwrap();
        assert!(json_str.contains("\"valid\":false"));
        assert!(json_str.contains("File not found"));
    }

    #[test]
    fn test_a2ml_load_manifest_missing_file() {
        let result = a2ml_load_manifest("/nonexistent/path/to/file.a2ml".to_string());
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not found"));
    }

    #[test]
    fn test_collect_a2ml_files_empty_dir() {
        let tmp = std::env::temp_dir().join("panll-a2ml-test");
        let _ = std::fs::create_dir_all(&tmp);
        let mut results = Vec::new();
        collect_a2ml_files(&tmp, &mut results, &tmp);
        // Empty directory should yield no results
        assert!(results.is_empty());
        let _ = std::fs::remove_dir_all(&tmp);
    }

    #[test]
    fn test_collect_a2ml_files_with_files() {
        let tmp = std::env::temp_dir().join("panll-a2ml-test-2");
        let _ = std::fs::create_dir_all(&tmp);
        // Create a test .a2ml file
        let test_file = tmp.join("test.a2ml");
        std::fs::write(&test_file, "; test manifest").unwrap();
        let mut results = Vec::new();
        collect_a2ml_files(&tmp, &mut results, &tmp);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0], "test.a2ml");
        let _ = std::fs::remove_dir_all(&tmp);
    }

    #[test]
    fn test_a2ml_validate_with_temp_file() {
        let tmp = std::env::temp_dir().join("panll-a2ml-validate-test.a2ml");
        std::fs::write(
            &tmp,
            "; SPDX-License-Identifier: MPL-2.0\n(manifest (identity (name \"test\")))",
        )
        .unwrap();
        let result = a2ml_validate(tmp.to_string_lossy().to_string());
        assert!(result.is_ok());
        let json_str = result.unwrap();
        assert!(json_str.contains("\"valid\":true"));
        let _ = std::fs::remove_file(&tmp);
    }

    #[test]
    fn test_a2ml_validate_empty_file() {
        let tmp = std::env::temp_dir().join("panll-a2ml-empty-test.a2ml");
        std::fs::write(&tmp, "").unwrap();
        let result = a2ml_validate(tmp.to_string_lossy().to_string());
        assert!(result.is_ok());
        let json_str = result.unwrap();
        assert!(json_str.contains("\"valid\":false"));
        assert!(json_str.contains("empty"));
        let _ = std::fs::remove_file(&tmp);
    }
}
