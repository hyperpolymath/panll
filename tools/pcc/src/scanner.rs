// SPDX-License-Identifier: PMPL-1.0-or-later

//! Repo fact extraction — deterministic text search against .res source files.
//!
//! The scanner reads PanLL source files and searches for specific text patterns
//! that confirm each wiring point. All matching is line-by-line text search —
//! no parsing, no inference, fully deterministic.

use crate::contract::PanelContract;
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

    /// Search a file for the first line containing a substring.
    ///
    /// Returns a `ScanResult` with the 1-indexed line number and trimmed
    /// line content if found.
    fn search_file(&self, relative_path: &str, needle: &str) -> ScanResult {
        match self.read_file(relative_path) {
            None => ScanResult {
                found: false,
                file: relative_path.to_string(),
                line: None,
                evidence: Some(format!("File not found: {}", relative_path)),
            },
            Some(content) => {
                for (idx, line) in content.lines().enumerate() {
                    if line.contains(needle) {
                        return ScanResult {
                            found: true,
                            file: relative_path.to_string(),
                            line: Some(idx + 1),
                            evidence: Some(line.trim().to_string()),
                        };
                    }
                }
                ScanResult {
                    found: false,
                    file: relative_path.to_string(),
                    line: None,
                    evidence: None,
                }
            }
        }
    }

    /// Check that the panel is registered in PanelRegistry.res.
    ///
    /// Searches for `id: {view_route}` (e.g. `id: PanelMyLang`) in the
    /// registry file. The PanelRegistry uses `panelId` variant constructors
    /// that match the `view_route` field of the contract.
    pub fn check_registry(&self, contract: &PanelContract) -> ScanResult {
        let needle = format!("id: {}", contract.view_route);
        self.search_file("src/modules/PanelRegistry.res", &needle)
    }

    /// Check that the model includes the panel's model module.
    ///
    /// Searches for `include {module_name}Model` in Model.res to confirm
    /// that the panel's state types are re-exported into the unified model.
    pub fn check_model_include(&self, contract: &PanelContract) -> ScanResult {
        let needle = format!("include {}Model", contract.module_name);
        self.search_file("src/Model.res", &needle)
    }

    /// Check that the model record contains the panel's state field.
    ///
    /// Searches for `{model_slice}:` in Model.res to confirm the field
    /// exists in the `type model` record.
    pub fn check_model_slice(&self, contract: &PanelContract) -> ScanResult {
        let needle = format!("{}: ", contract.model_slice);
        self.search_file("src/Model.res", &needle)
    }

    /// Check that the message namespace type is defined in Msg.res.
    ///
    /// Searches for `type {msg_namespace}` to confirm the message type
    /// exists (e.g. `type myLangMsg =`).
    pub fn check_msg_type(&self, contract: &PanelContract) -> ScanResult {
        let needle = format!("type {}", contract.msg_namespace);
        self.search_file("src/Msg.res", &needle)
    }

    /// Check that the message routing variant exists in the `msg` union.
    ///
    /// Searches for `| {module_name}({msg_namespace})` or
    /// `{module_name}({msg_namespace})` to confirm the variant is wired
    /// into the top-level msg type.
    pub fn check_msg_variant(&self, contract: &PanelContract) -> ScanResult {
        let needle = format!("{}({})", contract.module_name, contract.msg_namespace);
        self.search_file("src/Msg.res", &needle)
    }

    /// Check that the view routes to this panel.
    ///
    /// Searches for `Some({view_route})` in View.res to confirm the
    /// panel switcher dispatches to this panel's view function.
    pub fn check_view_route(&self, contract: &PanelContract) -> ScanResult {
        let needle = format!("Some({})", contract.view_route);
        self.search_file("src/View.res", &needle)
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
    /// 3. `tests/{panel_id lower}_engine_test.js` (e.g. `cloudguard_engine_test.js`)
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
