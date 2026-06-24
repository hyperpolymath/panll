// SPDX-License-Identifier: MPL-2.0

/// Code MRI — Attribution-to-Licensing Model (Layer 4)
///
/// Types for linking code provenance (who wrote what) to licensing obligations.
/// Layer 4 combines Layer 1 provenance data (git blame trust levels) with
/// license metadata to detect licensing inconsistencies:
///
///   - AI-generated code in AGPL repos (attribution question)
///   - Files missing SPDX headers
///   - Third-party code without original license preserved
///   - License conflicts between dependencies and project license
///   - Co-authored code where licensing terms are ambiguous
///
/// This layer makes licensing visible and actionable rather than an afterthought.
/// It integrates with Palimpsest Plaza for license management and the Code
/// Provenance Map for trust-level data.
///
/// DESIGN NOTE: This is NOT a legal tool. It detects mismatches and flags them
/// for human review. The system never makes licensing decisions autonomously.

// ===========================================================================
// License Types
// ===========================================================================

/// Known license families. Not exhaustive — CustomLicense covers everything else.
type licenseFamiliy =
  | PMPL         // Palimpsest License (hyperpolymath default)
  | MPL2         // Mozilla Public License 2.0 (fallback)
  | MIT
  | Apache2
  | BSD2
  | BSD3
  | GPL2
  | GPL3
  | AGPL3
  | LGPL21
  | ISC
  | Unlicense
  | CC0
  | Proprietary
  | CustomLicense(string)

/// SPDX header status for a single file.
type spdxStatus =
  /// File has a valid SPDX-License-Identifier header.
  | Present(string)
  /// File has no SPDX header.
  | Missing
  /// File has a malformed SPDX header.
  | Malformed(string)
  /// File is binary or otherwise not applicable.
  | NotApplicable

/// Attribution clarity for a code region.
type attributionClarity =
  /// Single human author, clear ownership.
  | ClearHuman
  /// Human + AI co-authored, human reviewed.
  | CoAuthoredReviewed
  /// Human + AI co-authored, NOT yet reviewed.
  | CoAuthoredUnreviewed
  /// AI-only authorship, needs human sign-off for licensing.
  | AiOnlyUnresolved
  /// Third-party code with preserved original license.
  | ThirdPartyPreserved
  /// Third-party code with missing/unclear license.
  | ThirdPartyUnclear
  /// Unknown attribution.
  | Unknown

// ===========================================================================
// Issue Types
// ===========================================================================

/// A detected licensing issue.
type rec licenseIssue = {
  /// Unique ID.
  id: string,
  /// File path relative to repo root.
  file: string,
  /// Line range (start, end) or None for whole-file issues.
  lineRange: option<(int, int)>,
  /// What the issue is.
  kind: licenseIssueKind,
  /// How severe this is.
  severity: licenseSeverity,
  /// Human-readable explanation.
  description: string,
  /// Suggested remediation.
  suggestion: string,
  /// Whether the developer has resolved this.
  resolved: bool,
}

/// Categories of licensing issues.
and licenseIssueKind =
  /// SPDX header missing from source file.
  | MissingSpdxHeader
  /// SPDX header doesn't match project license.
  | SpdxMismatch
  /// AI-generated code in a license that requires clear attribution.
  | AiAttributionGap
  /// Third-party code without preserved original license.
  | ThirdPartyLicenseMissing
  /// Dependency license conflicts with project license.
  | DependencyConflict(string)
  /// Co-authored code where licensing terms are ambiguous.
  | CoAuthorAmbiguity
  /// File uses a deprecated/old license (e.g., AGPL instead of PMPL).
  | DeprecatedLicense(string)

/// Severity of licensing issues.
and licenseSeverity =
  | LicenseInfo        // Informational (e.g., "this file has no SPDX header but is config")
  | LicenseWarning     // Should fix (e.g., missing SPDX on source file)
  | LicenseCritical    // Must fix (e.g., license conflict, third-party without attribution)

// ===========================================================================
// Summary Types
// ===========================================================================

/// Per-file attribution + licensing summary.
type fileLicenseSummary = {
  /// File path.
  path: string,
  /// SPDX header status.
  spdxStatus: spdxStatus,
  /// Dominant attribution clarity.
  attribution: attributionClarity,
  /// Project license family.
  projectLicense: licenseFamiliy,
  /// Issues found for this file.
  issues: array<licenseIssue>,
}

/// Codebase-wide licensing health score.
type licensingHealth = {
  /// Total files scanned.
  totalFiles: int,
  /// Files with valid SPDX headers.
  filesWithSpdx: int,
  /// Files with clear attribution.
  filesClearAttribution: int,
  /// Total issues (all severities).
  totalIssues: int,
  /// Critical issues only.
  criticalIssues: int,
  /// Health score 0.0-100.0 (higher = better).
  healthScore: float,
}

// ===========================================================================
// State
// ===========================================================================

/// Attribution-to-licensing state — included in the main Model.
type attributionLicenseState = {
  /// Per-file summaries (most recent scan).
  fileSummaries: array<fileLicenseSummary>,
  /// All detected issues.
  issues: array<licenseIssue>,
  /// Codebase health summary.
  health: licensingHealth,
  /// Whether the panel is expanded.
  expanded: bool,
  /// Filter: show resolved issues.
  showResolved: bool,
  /// Filter: minimum severity.
  minSeverity: licenseSeverity,
  /// Last scan timestamp.
  lastScan: option<string>,
  /// Scanning in progress.
  scanning: bool,
}

/// Initial empty state.
let init: attributionLicenseState = {
  fileSummaries: [],
  issues: [],
  health: {
    totalFiles: 0,
    filesWithSpdx: 0,
    filesClearAttribution: 0,
    totalIssues: 0,
    criticalIssues: 0,
    healthScore: 0.0,
  },
  expanded: false,
  showResolved: false,
  minSeverity: LicenseInfo,
  lastScan: None,
  scanning: false,
}
