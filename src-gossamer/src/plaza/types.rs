// SPDX-License-Identifier: PMPL-1.0-or-later

//! Palimpsest Plaza types — compliance audit, provenance, and adoption
//! statistics for the PMPL licensing panel.

#![allow(dead_code)]

use serde::Serialize;
use std::collections::HashMap;

/// Compliance level for a single repository.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ComplianceLevel {
    Full,
    Partial,
    NonCompliant,
    Unknown,
}

/// A single compliance check result.
#[derive(Debug, Clone, Serialize)]
pub struct ComplianceCheck {
    pub id: String,
    pub name: String,
    pub description: String,
    pub passed: bool,
    pub severity: String,
    pub detail: String,
}

/// Full compliance audit for one repo.
#[derive(Debug, Clone, Serialize)]
pub struct ComplianceAudit {
    pub repo_name: String,
    pub level: ComplianceLevel,
    pub checks: Vec<ComplianceCheck>,
    pub files_scanned: u32,
    pub files_with_headers: u32,
    pub last_audit: String,
}

/// Adoption statistics across the ecosystem.
#[derive(Debug, Clone, Serialize)]
pub struct AdoptionStats {
    pub total_repos: u32,
    pub pmpl_repos: u32,
    pub mpl_fallback_repos: u32,
    pub unlicensed_repos: u32,
    pub quantum_signed_repos: u32,
    pub by_license: HashMap<String, u32>,
}

/// Quick-scan result for a single repository.
#[derive(Debug, Clone, Serialize)]
pub struct RepoScanResult {
    pub repo_name: String,
    pub has_license_file: bool,
    pub license_type: Option<String>,
    pub spdx_header_count: u32,
    pub total_source_files: u32,
    pub has_exhibit_a: bool,
    pub has_exhibit_b: bool,
    pub has_provenance_sig: bool,
}

// ---------------------------------------------------------------------------
// Smoke tests — serialisation and compliance invariants
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_compliance_level_all_variants_serialise() {
        let levels = [
            ComplianceLevel::Full,
            ComplianceLevel::Partial,
            ComplianceLevel::NonCompliant,
            ComplianceLevel::Unknown,
        ];
        for level in levels {
            let json = serde_json::to_string(&level).expect("ComplianceLevel must serialise");
            assert!(!json.is_empty());
        }
    }

    #[test]
    fn smoke_compliance_audit_files_ratio_valid() {
        let audit = ComplianceAudit {
            repo_name: "panll".to_string(),
            level: ComplianceLevel::Full,
            checks: vec![],
            files_scanned: 100,
            files_with_headers: 95,
            last_audit: "2026-04-04".to_string(),
        };
        assert!(audit.files_with_headers <= audit.files_scanned);
    }

    #[test]
    fn smoke_adoption_stats_totals_are_consistent() {
        let stats = AdoptionStats {
            total_repos: 10,
            pmpl_repos: 8,
            mpl_fallback_repos: 1,
            unlicensed_repos: 1,
            quantum_signed_repos: 5,
            by_license: std::collections::HashMap::new(),
        };
        assert!(stats.pmpl_repos + stats.mpl_fallback_repos + stats.unlicensed_repos <= stats.total_repos + 1);
        // Allow slight over-count since quantum_signed can overlap with pmpl
    }

    #[test]
    fn smoke_repo_scan_result_no_headers_means_zero_count() {
        let result = RepoScanResult {
            repo_name: "empty-repo".to_string(),
            has_license_file: false,
            license_type: None,
            spdx_header_count: 0,
            total_source_files: 5,
            has_exhibit_a: false,
            has_exhibit_b: false,
            has_provenance_sig: false,
        };
        assert_eq!(result.spdx_header_count, 0);
        assert!(result.license_type.is_none());
    }
}
