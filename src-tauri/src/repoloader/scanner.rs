// SPDX-License-Identifier: PMPL-1.0-or-later

//! Repo Scanner — analyses a repository to produce panel suggestions.
//!
//! Reads manifests, detects languages, and infers which PanLL panels
//! are relevant based on the repo's contents and metadata.

use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

use super::types::*;

/// File extension → language name mappings for detection.
const LANG_EXTENSIONS: &[(&str, &str)] = &[
    ("rs", "Rust"),
    ("res", "ReScript"),
    ("idr", "Idris2"),
    ("zig", "Zig"),
    ("gleam", "Gleam"),
    ("ex", "Elixir"),
    ("exs", "Elixir"),
    ("ml", "OCaml"),
    ("hs", "Haskell"),
    ("jl", "Julia"),
    ("adb", "Ada"),
    ("ads", "Ada"),
    ("v", "V-lang"),
    ("js", "JavaScript"),
    ("ncl", "Nickel"),
    ("scm", "Scheme"),
    ("lean", "Lean"),
    ("nix", "Nix"),
    ("go", "Go"),
    ("py", "Python"),
    ("rb", "Ruby"),
    ("ts", "TypeScript"),
    ("tsx", "TypeScript"),
    ("c", "C"),
    ("h", "C"),
    ("cpp", "C++"),
];

/// Scan a repo directory and build a `RepoInfo` with detected metadata.
pub fn scan_repo(repo_path: &Path) -> Result<RepoInfo, String> {
    if !repo_path.exists() {
        return Err(format!("Path does not exist: {}", repo_path.display()));
    }
    if !repo_path.is_dir() {
        return Err(format!("Not a directory: {}", repo_path.display()));
    }

    let name = repo_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown")
        .to_string();

    let mr_dir = repo_path.join(".machine_readable");
    let has_machine_readable = mr_dir.exists();
    let has_panels_manifest = mr_dir.join("PANELS.a2ml").exists();
    let has_state = mr_dir.join("STATE.scm").exists();
    let has_ai_manifest = repo_path.join("0-AI-MANIFEST.a2ml").exists()
        || repo_path.join("AI.a2ml").exists();

    // Extract description from AI manifest if available.
    let description = extract_description(repo_path).unwrap_or_default();

    // Detect languages by scanning file extensions.
    let languages = detect_languages(repo_path);

    Ok(RepoInfo {
        path: repo_path.to_string_lossy().to_string(),
        name,
        description,
        languages,
        has_machine_readable,
        has_panels_manifest,
        has_ai_manifest,
        has_state,
    })
}

/// Extract a description from the AI manifest or README.
fn extract_description(repo_path: &Path) -> Option<String> {
    // Try AI manifest first.
    let manifest_path = if repo_path.join("0-AI-MANIFEST.a2ml").exists() {
        repo_path.join("0-AI-MANIFEST.a2ml")
    } else if repo_path.join("AI.a2ml").exists() {
        repo_path.join("AI.a2ml")
    } else {
        return None;
    };

    let content = fs::read_to_string(&manifest_path).ok()?;
    // Look for a description line (simple heuristic: first non-comment, non-empty line).
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with(';') || trimmed.starts_with('#') {
            continue;
        }
        // If it looks like an S-expression field, extract value.
        if trimmed.contains("description") || trimmed.contains("purpose") {
            if let Some(start) = trimmed.find('"') {
                if let Some(end) = trimmed[start + 1..].find('"') {
                    return Some(trimmed[start + 1..start + 1 + end].to_string());
                }
            }
        }
    }
    None
}

/// Detect languages by scanning file extensions in top-level and src/.
fn detect_languages(repo_path: &Path) -> Vec<String> {
    let mut langs = HashSet::new();
    let dirs_to_scan = [
        repo_path.to_path_buf(),
        repo_path.join("src"),
        repo_path.join("lib"),
        repo_path.join("src-tauri").join("src"),
    ];

    for dir in &dirs_to_scan {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                if let Some(ext) = entry.path().extension().and_then(|e| e.to_str()) {
                    for (file_ext, lang) in LANG_EXTENSIONS {
                        if ext == *file_ext {
                            langs.insert(lang.to_string());
                        }
                    }
                }
            }
        }
    }

    let mut result: Vec<String> = langs.into_iter().collect();
    result.sort();
    result
}

/// Generate panel suggestions based on repo metadata and detected languages.
pub fn suggest_panels(repo: &RepoInfo) -> Vec<PanelSuggestion> {
    let mut suggestions = Vec::new();

    // AI panel — always suggested (it's the neural interface).
    suggestions.push(PanelSuggestion {
        panel_name: "AI".to_string(),
        reason: "Neural interface for AI-assisted development".to_string(),
        priority: "critical".to_string(),
        enabled: true,
    });

    // VoiceTag — always suggested (code annotation is universal).
    suggestions.push(PanelSuggestion {
        panel_name: "VoiceTag".to_string(),
        reason: "Code MRI annotation for attribution tracking".to_string(),
        priority: "high".to_string(),
        enabled: true,
    });

    // Reposystem — if repo has RSR markers.
    if repo.has_machine_readable || repo.has_ai_manifest {
        suggestions.push(PanelSuggestion {
            panel_name: "Reposystem".to_string(),
            reason: "RSR compliance (has .machine_readable/ or AI manifest)".to_string(),
            priority: "medium".to_string(),
            enabled: true,
        });
    }

    // Interfaces — if Idris2 or Zig detected (ABI/FFI work).
    if repo.languages.iter().any(|l| l == "Idris2" || l == "Zig") {
        suggestions.push(PanelSuggestion {
            panel_name: "Interfaces".to_string(),
            reason: "ABI/FFI inventory (Idris2/Zig detected)".to_string(),
            priority: "high".to_string(),
            enabled: true,
        });
    }

    // Databases — if the repo name contains db/database keywords.
    let name_lower = repo.name.to_lowercase();
    if name_lower.contains("db")
        || name_lower.contains("database")
        || name_lower.contains("verisim")
        || name_lower.contains("quandle")
        || name_lower.contains("lithoglyph")
    {
        suggestions.push(PanelSuggestion {
            panel_name: "Databases".to_string(),
            reason: "Database project detected from repo name".to_string(),
            priority: "high".to_string(),
            enabled: true,
        });
    }

    // Hypatia — if the repo has CI workflows.
    let workflows_dir = PathBuf::from(&repo.path).join(".github").join("workflows");
    if workflows_dir.exists() {
        suggestions.push(PanelSuggestion {
            panel_name: "Hypatia".to_string(),
            reason: "CI/CD workflows detected".to_string(),
            priority: "medium".to_string(),
            enabled: true,
        });
    }

    // Fleet — if hypatia is suggested (fleet works with hypatia findings).
    if suggestions.iter().any(|s| s.panel_name == "Hypatia") {
        suggestions.push(PanelSuggestion {
            panel_name: "Fleet".to_string(),
            reason: "Gitbot fleet for automated fixes (works with Hypatia)".to_string(),
            priority: "low".to_string(),
            enabled: false,
        });
    }

    // VAB — if Idris2 detected (proven-servers style work).
    if repo.languages.iter().any(|l| l == "Idris2") {
        suggestions.push(PanelSuggestion {
            panel_name: "VAB".to_string(),
            reason: "Verified Assembly Building (Idris2 components detected)".to_string(),
            priority: "medium".to_string(),
            enabled: true,
        });
    }

    // Playgrounds — if multiple languages detected.
    if repo.languages.len() >= 3 {
        suggestions.push(PanelSuggestion {
            panel_name: "Playgrounds".to_string(),
            reason: format!("Multi-language repo ({} languages detected)", repo.languages.len()),
            priority: "low".to_string(),
            enabled: false,
        });
    }

    suggestions
}

/// Parse a simple PANELS.a2ml manifest from S-expression format.
/// This is a best-effort parser for the `.machine_readable/PANELS.a2ml` file.
pub fn parse_panels_manifest(content: &str) -> Option<PanelsManifest> {
    let mut panels = Vec::new();
    let mut constraints = Vec::new();
    let mut repo_name = String::new();
    let mut portfolio_name = String::new();
    let mut isolation = "native".to_string();
    let version = "1.0".to_string();

    for line in content.lines() {
        let trimmed = line.trim();

        // Extract repo name: (repo "name")
        if trimmed.starts_with("(repo ") {
            if let Some(name) = extract_quoted(trimmed) {
                repo_name = name;
            }
        }

        // Extract panel: (panel "Name" (enabled true|false) (priority "level"))
        if trimmed.starts_with("(panel ") {
            if let Some(name) = extract_quoted(trimmed) {
                let enabled = trimmed.contains("enabled true");
                let priority = if trimmed.contains("\"critical\"") {
                    "critical"
                } else if trimmed.contains("\"high\"") {
                    "high"
                } else if trimmed.contains("\"low\"") {
                    "low"
                } else {
                    "medium"
                };
                panels.push(PanelEntry {
                    name,
                    enabled,
                    priority: priority.to_string(),
                });
            }
        }

        // Extract constraint.
        if trimmed.starts_with("(constraint ") {
            if let Some(constraint) = extract_quoted(trimmed) {
                constraints.push(constraint);
            }
        }

        // Extract portfolio name.
        if trimmed.starts_with("(name ") {
            if let Some(name) = extract_quoted(trimmed) {
                portfolio_name = name;
            }
        }

        // Extract isolation.
        if trimmed.starts_with("(isolation ") {
            if let Some(iso) = extract_quoted(trimmed) {
                isolation = iso;
            }
        }
    }

    if panels.is_empty() {
        return None;
    }

    Some(PanelsManifest {
        version,
        repo: repo_name,
        panels,
        ai_constraints: constraints,
        portfolio_name,
        isolation,
    })
}

/// Extract the first quoted string from a line.
fn extract_quoted(line: &str) -> Option<String> {
    let start = line.find('"')? + 1;
    let end = start + line[start..].find('"')?;
    Some(line[start..end].to_string())
}
