// SPDX-License-Identifier: PMPL-1.0-or-later

//! Provenance Tauri commands — git blame analysis and unsound marker detection.
//!
//! Commands:
//!   - `provenance_analyse_file`: Run `git blame --porcelain` on a file and
//!     extract unique authors plus Co-Authored-By trailers.
//!   - `provenance_scan_unsound`: Scan a file for dangerous patterns that
//!     undermine formal verification (believe_me, sorry, Admitted, etc.).
//!
//! These run entirely via std::process::Command and std::fs — no external
//! service or HTTP dependency.

use std::collections::{HashMap, HashSet};
use std::fs;
use std::process::Command;

use regex::Regex;
use serde_json::json;

/// Analyse a file's provenance via git blame + Co-Authored-By parsing.
///
/// Runs `git blame --porcelain <file_path>` in the given repo directory,
/// parses the porcelain output to extract unique authors and commit metadata,
/// and also searches commit messages for Co-Authored-By trailers.
///
/// Returns a JSON object with `authors` (array of {name, email, lines}),
/// `co_authors` (array of {name, email}), and `total_lines`.
#[tauri::command]
pub async fn provenance_analyse_file(
    repo_path: String,
    file_path: String,
) -> Result<String, String> {
    // Run git blame --porcelain to get structured blame output.
    let output = Command::new("git")
        .args(["blame", "--porcelain", &file_path])
        .current_dir(&repo_path)
        .output()
        .map_err(|e| format!("Failed to run git blame: {e}"))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("git blame failed: {stderr}"));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);

    // Parse porcelain output.
    // Format: each blame region starts with a 40-char SHA line, followed by
    // header lines like "author <name>", "author-mail <email>", etc.
    let mut authors: HashMap<String, (String, u32)> = HashMap::new(); // name -> (email, line_count)
    let mut current_author = String::new();
    let mut current_email = String::new();
    let mut total_lines: u32 = 0;

    for line in stdout.lines() {
        if line.starts_with("author ") {
            current_author = line.strip_prefix("author ").unwrap_or("").to_string();
        } else if line.starts_with("author-mail ") {
            current_email = line
                .strip_prefix("author-mail ")
                .unwrap_or("")
                .trim_matches(|c| c == '<' || c == '>')
                .to_string();
        } else if line.starts_with('\t') {
            // Tab-prefixed line = actual content line; count it for current author.
            total_lines += 1;
            if !current_author.is_empty() {
                let entry = authors
                    .entry(current_author.clone())
                    .or_insert_with(|| (current_email.clone(), 0));
                entry.1 += 1;
            }
        }
    }

    // Extract Co-Authored-By trailers from commit messages.
    // Run git log to find all commits that touch this file.
    let co_authors = extract_co_authors(&repo_path, &file_path);

    // Build the authors array sorted by line count (descending).
    let mut author_list: Vec<serde_json::Value> = authors
        .into_iter()
        .map(|(name, (email, lines))| {
            json!({ "name": name, "email": email, "lines": lines })
        })
        .collect();
    author_list.sort_by(|a, b| {
        b["lines"].as_u64().unwrap_or(0).cmp(&a["lines"].as_u64().unwrap_or(0))
    });

    let result = json!({
        "authors": author_list,
        "co_authors": co_authors,
        "total_lines": total_lines,
        "file": file_path,
        "repo": repo_path,
    });

    Ok(result.to_string())
}

/// Extract Co-Authored-By trailers from commits that touch a given file.
fn extract_co_authors(repo_path: &str, file_path: &str) -> Vec<serde_json::Value> {
    let output = Command::new("git")
        .args(["log", "--format=%b", "--", file_path])
        .current_dir(repo_path)
        .output();

    let Ok(output) = output else {
        return Vec::new();
    };

    if !output.status.success() {
        return Vec::new();
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    // SAFETY: This regex is a compile-time constant and is known to be valid.
    let re = Regex::new(r"(?i)Co-Authored-By:\s*(.+?)\s*<([^>]+)>")
        .expect("co-authored-by regex: pattern is a compile-time constant");

    let mut seen = HashSet::new();
    let mut co_authors = Vec::new();

    for caps in re.captures_iter(&stdout) {
        let name = caps.get(1).map_or("", |m| m.as_str()).trim().to_string();
        let email = caps.get(2).map_or("", |m| m.as_str()).trim().to_string();
        let key = format!("{name}<{email}>");
        if seen.insert(key) {
            co_authors.push(json!({ "name": name, "email": email }));
        }
    }

    co_authors
}

/// Dangerous patterns that undermine formal verification.
///
/// Each entry is (pattern, language_hint, severity) where severity indicates
/// how dangerous the pattern is: "critical" means it silently breaks proofs,
/// "warning" means it's suspect but may have legitimate uses with justification.
const UNSOUND_PATTERNS: &[(&str, &str, &str)] = &[
    ("believe_me", "Idris2", "critical"),
    ("assert_total", "Idris2", "critical"),
    ("assert_smaller", "Idris2", "critical"),
    ("unsafePerformIO", "Idris2/Haskell", "critical"),
    ("unsafeCoerce", "Haskell", "critical"),
    ("Admitted", "Coq", "critical"),
    ("sorry", "Lean", "critical"),
    ("Obj.magic", "OCaml", "critical"),
    ("Obj.repr", "OCaml", "critical"),
    ("Obj.obj", "OCaml", "critical"),
    ("undefined", "Haskell", "warning"),
];

/// Scan a file for dangerous patterns that undermine formal verification.
///
/// Reads the file and searches for known unsound markers (believe_me, sorry,
/// Admitted, assert_total, unsafeCoerce, unsafePerformIO, Obj.magic, etc.).
/// Returns a JSON object with `matches` (array of {pattern, line, line_number,
/// language, severity}) and `total_matches`.
#[tauri::command]
pub async fn provenance_scan_unsound(file_path: String) -> Result<String, String> {
    let content = fs::read_to_string(&file_path)
        .map_err(|e| format!("Cannot read {file_path}: {e}"))?;

    let mut matches = Vec::new();

    for (line_number, line) in content.lines().enumerate() {
        for &(pattern, language, severity) in UNSOUND_PATTERNS {
            if line.contains(pattern) {
                // Skip matches inside comments that discuss the pattern.
                // Simple heuristic: if the line is a comment explaining why
                // the pattern is banned, don't flag it. This avoids false
                // positives on documentation files and READMEs.
                let trimmed = line.trim();
                let is_doc_comment = trimmed.starts_with("//!")
                    || trimmed.starts_with("///")
                    || trimmed.starts_with("-- |")
                    || trimmed.starts_with("{-");

                matches.push(json!({
                    "pattern": pattern,
                    "line": line.trim(),
                    "line_number": line_number + 1,
                    "language": language,
                    "severity": severity,
                    "is_doc_comment": is_doc_comment,
                }));
            }
        }
    }

    let result = json!({
        "matches": matches,
        "total_matches": matches.len(),
        "file": file_path,
    });

    Ok(result.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[tokio::test]
    async fn test_provenance_scan_unsound_finds_patterns() {
        // Create a temporary file with known unsound patterns.
        let dir = std::env::temp_dir().join("panll-test-provenance");
        let _ = fs::create_dir_all(&dir);
        let test_file = dir.join("test_unsound.idr");
        {
            let mut f = fs::File::create(&test_file).unwrap();
            writeln!(f, "module Test").unwrap();
            writeln!(f, "x = believe_me 42").unwrap();
            writeln!(f, "y = assert_total (head [])").unwrap();
            writeln!(f, "z = pure 1  -- safe line").unwrap();
        }

        let result = provenance_scan_unsound(test_file.to_string_lossy().to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["total_matches"], 2);
        let matches = json["matches"].as_array().unwrap();
        assert_eq!(matches[0]["pattern"], "believe_me");
        assert_eq!(matches[1]["pattern"], "assert_total");

        // Clean up.
        let _ = fs::remove_file(&test_file);
    }

    #[tokio::test]
    async fn test_provenance_scan_unsound_empty_file() {
        let dir = std::env::temp_dir().join("panll-test-provenance");
        let _ = fs::create_dir_all(&dir);
        let test_file = dir.join("test_empty.idr");
        fs::File::create(&test_file).unwrap();

        let result = provenance_scan_unsound(test_file.to_string_lossy().to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["total_matches"], 0);

        let _ = fs::remove_file(&test_file);
    }

    #[tokio::test]
    async fn test_provenance_scan_unsound_nonexistent_file() {
        let result = provenance_scan_unsound("/nonexistent/path/file.idr".into()).await;
        assert!(result.is_err());
    }
}
