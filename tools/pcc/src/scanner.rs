// SPDX-License-Identifier: PMPL-1.0-or-later

//! Repo fact extraction — structure-aware scanning of .res source files.
//!
//! The scanner reads PanLL source files and uses a lightweight structural
//! scanner (`rescript_scanner`) to strip comments, understand declarations
//! vs references, and match on structural patterns rather than raw text.
//! This eliminates false positives on comments, strings, and partial matches
//! while preserving accurate line numbers for diagnostics.

use crate::contract::PanelContract;
use crate::rescript_scanner::{self, StrippedLine};
use std::path::{Path, PathBuf};

/// Convert a PascalCase identifier to snake_case.
///
/// Examples: "MyLang" -> "my_lang", "CloudGuard" -> "cloud_guard",
/// "VAB" -> "v_a_b" (consecutive uppercase each get an underscore).
fn to_snake_case(s: &str) -> String {
    let mut result = String::with_capacity(s.len() + 4);
    for (i, ch) in s.chars().enumerate() {
        if ch.is_uppercase() {
            if i > 0 {
                result.push('_');
            }
            result.push(ch.to_lowercase().next().unwrap());
        } else {
            result.push(ch);
        }
    }
    result
}

/// Result of scanning a single source file for a specific pattern.
#[derive(Debug, Clone)]
pub struct ScanResult {
    /// Whether the expected pattern was found.
    pub found: bool,

    /// The file that was scanned (relative to repo root).
    pub file: String,

    /// 1-indexed line number where the match was found (if any).
    pub line: Option<usize>,

    /// The matching line content trimmed (if found).
    pub evidence: Option<String>,
}

/// Scanner context holding the repo root path.
///
/// All file reads are relative to this root. If a file does not exist,
/// the scanner returns `found: false` rather than an error — missing
/// files are treated as unsatisfied obligations.
pub struct Scanner {
    /// Absolute path to the PanLL repo root.
    repo_root: PathBuf,
}

impl Scanner {
    /// Create a new scanner rooted at the given directory.
    pub fn new(repo_root: &Path) -> Self {
        Self {
            repo_root: repo_root.to_path_buf(),
        }
    }

    /// Read a file relative to the repo root, returning None if it does not exist.
    fn read_file(&self, relative_path: &str) -> Option<String> {
        let full_path = self.repo_root.join(relative_path);
        std::fs::read_to_string(full_path).ok()
    }

    /// Read and strip comments from a file, returning comment-free lines
    /// with preserved original line numbers.
    ///
    /// Returns `None` if the file does not exist.
    fn read_and_strip(&self, relative_path: &str) -> Option<Vec<StrippedLine>> {
        self.read_file(relative_path)
            .map(|content| rescript_scanner::strip_comments(&content))
    }

    /// Build a not-found `ScanResult` for a missing file.
    fn file_not_found(relative_path: &str) -> ScanResult {
        ScanResult {
            found: false,
            file: relative_path.to_string(),
            line: None,
            evidence: Some(format!("File not found: {}", relative_path)),
        }
    }

    /// Build a not-found `ScanResult` when a structural query returned no match.
    fn not_found(relative_path: &str) -> ScanResult {
        ScanResult {
            found: false,
            file: relative_path.to_string(),
            line: None,
            evidence: None,
        }
    }

    /// Build a found `ScanResult` from a matched `StrippedLine`.
    fn found_from_line(relative_path: &str, line: &StrippedLine) -> ScanResult {
        ScanResult {
            found: true,
            file: relative_path.to_string(),
            line: Some(line.number),
            evidence: Some(line.raw.trim().to_string()),
        }
    }

    /// Check that the panel is registered in PanelRegistry.res.
    ///
    /// Uses structural `find_registry_entry` to locate `id: {view_route}`
    /// in the registry file, ignoring commented-out entries.
    pub fn check_registry(&self, contract: &PanelContract) -> ScanResult {
        let path = "src/modules/PanelRegistry.res";
        match self.read_and_strip(path) {
            None => Self::file_not_found(path),
            Some(lines) => {
                match rescript_scanner::find_registry_entry(&lines, &contract.view_route) {
                    Some(line) => Self::found_from_line(path, line),
                    None => Self::not_found(path),
                }
            }
        }
    }

    /// Check that the model includes the panel's model module.
    ///
    /// Uses structural `find_include` to locate `include {module_name}Model`
    /// in Model.res, ignoring commented-out includes.
    pub fn check_model_include(&self, contract: &PanelContract) -> ScanResult {
        let path = "src/Model.res";
        let include_name = format!("{}Model", contract.module_name);
        match self.read_and_strip(path) {
            None => Self::file_not_found(path),
            Some(lines) => match rescript_scanner::find_include(&lines, &include_name) {
                Some(line) => Self::found_from_line(path, line),
                None => Self::not_found(path),
            },
        }
    }

    /// Check that the model record contains the panel's state field.
    ///
    /// Uses structural `find_record_field` to locate `{model_slice}:` in
    /// Model.res, ignoring fields inside comments.
    pub fn check_model_slice(&self, contract: &PanelContract) -> ScanResult {
        let path = "src/Model.res";
        match self.read_and_strip(path) {
            None => Self::file_not_found(path),
            Some(lines) => {
                match rescript_scanner::find_record_field(&lines, &contract.model_slice) {
                    Some(line) => Self::found_from_line(path, line),
                    None => Self::not_found(path),
                }
            }
        }
    }

    /// Check that the message namespace type is defined in Msg.res.
    ///
    /// Uses structural `find_type_declaration` to locate `type {msg_namespace}`
    /// as a declaration (not a reference), ignoring type mentions in comments.
    pub fn check_msg_type(&self, contract: &PanelContract) -> ScanResult {
        let path = "src/Msg.res";
        match self.read_and_strip(path) {
            None => Self::file_not_found(path),
            Some(lines) => {
                match rescript_scanner::find_type_declaration(&lines, &contract.msg_namespace) {
                    Some(line) => Self::found_from_line(path, line),
                    None => Self::not_found(path),
                }
            }
        }
    }

    /// Check that the message routing variant exists in the `msg` union.
    ///
    /// Uses structural `find_variant_with_arg` to locate
    /// `| {module_name}({msg_namespace})` in the stripped content,
    /// ignoring commented-out variants.
    pub fn check_msg_variant(&self, contract: &PanelContract) -> ScanResult {
        let path = "src/Msg.res";
        match self.read_and_strip(path) {
            None => Self::file_not_found(path),
            Some(lines) => {
                match rescript_scanner::find_variant_with_arg(
                    &lines,
                    &contract.module_name,
                    &contract.msg_namespace,
                ) {
                    Some(line) => Self::found_from_line(path, line),
                    None => Self::not_found(path),
                }
            }
        }
    }

    /// Check that the view routes to this panel.
    ///
    /// Uses structural `find_match_arm` to locate `Some({view_route})`
    /// in View.res, ignoring commented-out match arms.
    pub fn check_view_route(&self, contract: &PanelContract) -> ScanResult {
        let path = "src/View.res";
        let pattern = format!("Some({})", contract.view_route);
        match self.read_and_strip(path) {
            None => Self::file_not_found(path),
            Some(lines) => match rescript_scanner::find_match_arm(&lines, &pattern) {
                Some(line) => Self::found_from_line(path, line),
                None => Self::not_found(path),
            },
        }
    }

    /// Run the full model check (include + slice).
    ///
    /// Both the `include` and the field must be present for the model
    /// obligation to be satisfied.
    pub fn check_model(&self, contract: &PanelContract) -> ScanResult {
        let include_result = self.check_model_include(contract);
        if !include_result.found {
            return include_result;
        }
        let slice_result = self.check_model_slice(contract);
        if !slice_result.found {
            return slice_result;
        }
        // Return the include result (first found) as the evidence.
        include_result
    }

    /// Check whether a test file exists for the given panel.
    ///
    /// Tries multiple naming conventions because test files in the repo use
    /// inconsistent casing (e.g. `cloudguard_engine_test.js` not `cloud_guard_`).
    /// Checks in order:
    /// 1. `tests/{snake_case}_engine_test.js` (e.g. `cloud_guard_engine_test.js`)
    /// 2. `tests/{lowercase}_engine_test.js` (e.g. `cloudguard_engine_test.js`)
    pub fn check_test_bundle(&self, panel_id: &str) -> ScanResult {
        let snake = to_snake_case(panel_id);
        let lowercase = panel_id.to_lowercase();

        // Try candidates in priority order
        let candidates = [
            format!("tests/{}_engine_test.js", snake),
            format!("tests/{}_engine_test.js", lowercase),
        ];

        for candidate in &candidates {
            let test_path = self.repo_root.join(candidate);
            if test_path.exists() {
                return ScanResult {
                    found: true,
                    file: candidate.clone(),
                    line: None,
                    evidence: Some("Test file exists".to_string()),
                };
            }
        }

        // Report the first candidate as the expected path
        ScanResult {
            found: false,
            file: candidates[0].clone(),
            line: None,
            evidence: None,
        }
    }

    /// Check that the runtime contractile system is present and healthy.
    ///
    /// Validates that `src/core/Contractiles.res` exists, exports a
    /// `defaultContractiles` function, and declares at least `min_count`
    /// contractile entries. Uses structure-aware scanning to ignore
    /// commented-out contractile entries.
    pub fn check_contractile_health(&self, min_count: usize) -> ScanResult {
        let file_path = "src/core/Contractiles.res";

        match self.read_and_strip(file_path) {
            None => ScanResult {
                found: false,
                file: file_path.to_string(),
                line: None,
                evidence: Some(format!("File not found: {}", file_path)),
            },
            Some(lines) => {
                // Check that defaultContractiles function exists (comment-stripped).
                let fn_line = lines
                    .iter()
                    .find(|l| l.content.contains("let defaultContractiles"));

                if fn_line.is_none() {
                    return ScanResult {
                        found: false,
                        file: file_path.to_string(),
                        line: None,
                        evidence: Some("defaultContractiles function not found".to_string()),
                    };
                }

                // Count contractile entries by searching stripped lines for `id: "`.
                let count = lines.iter().filter(|l| l.content.contains("id: \"")).count();
                if count >= min_count {
                    ScanResult {
                        found: true,
                        file: file_path.to_string(),
                        line: fn_line.map(|l| l.number),
                        evidence: Some(format!(
                            "Found {} contractiles (minimum: {})",
                            count, min_count
                        )),
                    }
                } else {
                    ScanResult {
                        found: false,
                        file: file_path.to_string(),
                        line: None,
                        evidence: Some(format!(
                            "Only {} contractiles found, minimum is {}",
                            count, min_count
                        )),
                    }
                }
            }
        }
    }

    /// Run the full msg check (type definition + routing variant).
    ///
    /// Both the type definition and the variant must be present for the
    /// msg obligation to be satisfied.
    pub fn check_msg(&self, contract: &PanelContract) -> ScanResult {
        let type_result = self.check_msg_type(contract);
        if !type_result.found {
            return type_result;
        }
        let variant_result = self.check_msg_variant(contract);
        if !variant_result.found {
            return variant_result;
        }
        // Return the type result as the primary evidence.
        type_result
    }
}
