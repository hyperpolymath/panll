// SPDX-License-Identifier: MPL-2.0

//! AI Context Assembly — builds system prompts from repo metadata.
//!
//! Reads the repo's SCM files (STATE.scm, ECOSYSTEM.scm, META.scm),
//! AI manifest (0-AI-MANIFEST.a2ml), and active panel state to assemble
//! a rich system prompt that gives the AI full awareness of the current
//! development context.

use std::fs;
use std::path::{Path, PathBuf};

/// Read a file's contents, returning empty string if it doesn't exist.
fn read_optional(path: &Path) -> String {
    fs::read_to_string(path).unwrap_or_default()
}

/// Build the auto-context string from a repo path.
///
/// Scans for and reads:
///   - `0-AI-MANIFEST.a2ml` or `AI.a2ml` (AI agent entry point)
///   - `.machine_readable/STATE.scm` (project state)
///   - `.machine_readable/ECOSYSTEM.scm` (ecosystem position)
///   - `.machine_readable/META.scm` (meta-level decisions)
///   - `.machine_readable/PANELS.a2ml` (PanLL panel config)
///   - `.claude/CLAUDE.md` (AI instructions)
///
/// Returns a structured context string suitable for inclusion in a system prompt.
pub fn build_repo_context(repo_path: &str) -> Result<String, String> {
    let root = PathBuf::from(repo_path);
    if !root.exists() {
        return Err(format!("Repository path does not exist: {repo_path}"));
    }

    let mut sections: Vec<String> = Vec::new();

    // Repository identity.
    let repo_name = root
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown");
    sections.push(format!("## Repository: {repo_name}"));
    sections.push(format!("Path: {repo_path}"));

    // AI Manifest (entry point for all AI agents).
    let manifest_path = if root.join("0-AI-MANIFEST.a2ml").exists() {
        Some(root.join("0-AI-MANIFEST.a2ml"))
    } else if root.join("AI.a2ml").exists() {
        Some(root.join("AI.a2ml"))
    } else {
        None
    };
    if let Some(path) = manifest_path {
        let content = read_optional(&path);
        if !content.is_empty() {
            sections.push("## AI Manifest".to_string());
            sections.push(content);
        }
    }

    // Machine-readable checkpoint files.
    let mr_dir = root.join(".machine_readable");
    if mr_dir.exists() {
        let state = read_optional(&mr_dir.join("STATE.scm"));
        if !state.is_empty() {
            sections.push("## Project State (STATE.scm)".to_string());
            // Truncate very large state files to keep context manageable.
            if state.len() > 4000 {
                sections.push(state[..4000].to_string());
                sections.push("... (truncated)".to_string());
            } else {
                sections.push(state);
            }
        }

        let ecosystem = read_optional(&mr_dir.join("ECOSYSTEM.scm"));
        if !ecosystem.is_empty() {
            sections.push("## Ecosystem Position (ECOSYSTEM.scm)".to_string());
            if ecosystem.len() > 2000 {
                sections.push(ecosystem[..2000].to_string());
                sections.push("... (truncated)".to_string());
            } else {
                sections.push(ecosystem);
            }
        }

        let meta = read_optional(&mr_dir.join("META.scm"));
        if !meta.is_empty() {
            sections.push("## Architecture Decisions (META.scm)".to_string());
            if meta.len() > 2000 {
                sections.push(meta[..2000].to_string());
                sections.push("... (truncated)".to_string());
            } else {
                sections.push(meta);
            }
        }

        let panels = read_optional(&mr_dir.join("PANELS.a2ml"));
        if !panels.is_empty() {
            sections.push("## Panel Configuration (PANELS.a2ml)".to_string());
            sections.push(panels);
        }
    }

    // Claude-specific instructions.
    let claude_md = read_optional(&root.join(".claude").join("CLAUDE.md"));
    if !claude_md.is_empty() {
        sections.push("## Project AI Instructions (CLAUDE.md)".to_string());
        if claude_md.len() > 3000 {
            sections.push(claude_md[..3000].to_string());
            sections.push("... (truncated)".to_string());
        } else {
            sections.push(claude_md);
        }
    }

    // Detect languages from common file extensions in the root.
    let languages = detect_languages(&root);
    if !languages.is_empty() {
        sections.push(format!("## Detected Languages: {}", languages.join(", ")));
    }

    Ok(sections.join("\n\n"))
}

/// Detect programming languages present in a repo by scanning for common
/// file extensions in the top two directory levels.
fn detect_languages(root: &Path) -> Vec<String> {
    let mut langs = std::collections::HashSet::new();

    let extensions_map = [
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
    ];

    // Scan top-level and src/ directory.
    let dirs_to_scan: Vec<PathBuf> = vec![root.to_path_buf(), root.join("src")];

    for dir in dirs_to_scan {
        if let Ok(entries) = fs::read_dir(&dir) {
            for entry in entries.flatten() {
                if let Some(ext) = entry.path().extension().and_then(|e| e.to_str()) {
                    for (file_ext, lang) in &extensions_map {
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
