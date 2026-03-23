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
