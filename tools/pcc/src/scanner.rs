// SPDX-License-Identifier: MPL-2.0

//! Repo fact extraction.
//!
//! The frontend-wiring checks (registry, model, msg, view, contractiles)
//! scanned ReScript `.res` sources. #107 removed those sources, so the
//! ReScript scanner is retired and each of those checks reports itself as
//! retired (`found: false`) until an AffineScript scanner exists (#148).
//! The test-bundle check does not read frontend sources and still runs.

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

    /// A frontend-wiring check whose ReScript source no longer exists.
    fn retired(relative_path: &str) -> ScanResult {
        ScanResult {
            found: false,
            file: relative_path.to_string(),
            line: None,
            evidence: Some(format!(
                "Check retired: {relative_path} was ReScript, removed in #107; \
                 an AffineScript scanner is tracked in #148"
            )),
        }
    }

    /// Check that the panel is registered in PanelRegistry.res.
    ///
    /// Retired with the ReScript scanner; see [`Scanner::retired`].
    pub fn check_registry(&self, _contract: &PanelContract) -> ScanResult {
        Self::retired("src/modules/PanelRegistry.res")
    }

    /// Check that the model includes the panel's model module.
    ///
    /// Retired with the ReScript scanner; see [`Scanner::retired`].
    pub fn check_model_include(&self, _contract: &PanelContract) -> ScanResult {
        Self::retired("src/Model.res")
    }

    /// Check that the model record contains the panel's state field.
    ///
    /// Retired with the ReScript scanner; see [`Scanner::retired`].
    pub fn check_model_slice(&self, _contract: &PanelContract) -> ScanResult {
        Self::retired("src/Model.res")
    }

    /// Check that the message namespace type is defined in Msg.res.
    ///
    /// Retired with the ReScript scanner; see [`Scanner::retired`].
    pub fn check_msg_type(&self, _contract: &PanelContract) -> ScanResult {
        Self::retired("src/Msg.res")
    }

    /// Check that the message routing variant exists in the `msg` union.
    ///
    /// Retired with the ReScript scanner; see [`Scanner::retired`].
    pub fn check_msg_variant(&self, _contract: &PanelContract) -> ScanResult {
        Self::retired("src/Msg.res")
    }

    /// Check that the view routes to this panel.
    ///
    /// Retired with the ReScript scanner; see [`Scanner::retired`].
    pub fn check_view_route(&self, _contract: &PanelContract) -> ScanResult {
        Self::retired("src/View.res")
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
    /// Retired with the ReScript scanner; see [`Scanner::retired`].
    pub fn check_contractile_health(&self, _min_count: usize) -> ScanResult {
        Self::retired("src/core/Contractiles.res")
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
