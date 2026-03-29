// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — Attribution-to-Licensing Engine (Layer 4)
///
/// Pure computation for linking code provenance to licensing obligations.
/// Combines git blame trust levels (Layer 1) with SPDX header scanning
/// to detect licensing inconsistencies.
///
/// All functions are pure — no side effects, no Gossamer invocations.
/// File system scanning and git operations happen in the command layer.

open AttributionLicenseModel

// ===========================================================================
// SPDX Parsing
// ===========================================================================

/// Extract SPDX-License-Identifier from a file's first 10 lines.
/// Returns Present(id) if found, Missing if not, Malformed if unparseable.
let parseSpdxHeader = (lines: array<string>): spdxStatus => {
  let header = ref(Missing)
  let _ = lines->Array.forEach(line => {
    if header.contents === Missing {
      let trimmed = String.trim(line)
      if String.includes(trimmed, "SPDX-License-Identifier:") {
        let parts = String.split(trimmed, "SPDX-License-Identifier:")
        switch parts->Array.get(1) {
        | Some(id) =>
          let cleaned = String.trim(id)
          if String.length(cleaned) > 0 {
            header := Present(cleaned)
          } else {
            header := Malformed("Empty SPDX identifier")
          }
        | None => header := Malformed("Malformed SPDX line")
        }
      }
    }
  })
  header.contents
}

/// Map SPDX identifier to license family.
let spdxToFamily = (spdx: string): licenseFamiliy => {
  let normalised = String.trim(spdx)
  if String.includes(normalised, "PMPL") {
    PMPL
  } else if normalised === "MPL-2.0" {
    MPL2
  } else if normalised === "MIT" {
    MIT
  } else if normalised === "Apache-2.0" {
    Apache2
  } else if normalised === "BSD-2-Clause" {
    BSD2
  } else if normalised === "BSD-3-Clause" {
    BSD3
  } else if normalised === "GPL-2.0-only" || normalised === "GPL-2.0-or-later" {
    GPL2
  } else if normalised === "GPL-3.0-only" || normalised === "GPL-3.0-or-later" {
    GPL3
  } else if normalised === "AGPL-3.0-only" || normalised === "AGPL-3.0-or-later" {
    AGPL3
  } else if normalised === "LGPL-2.1-only" || normalised === "LGPL-2.1-or-later" {
    LGPL21
  } else if normalised === "ISC" {
    ISC
  } else if normalised === "Unlicense" {
    Unlicense
  } else if normalised === "CC0-1.0" {
    CC0
  } else {
    CustomLicense(normalised)
  }
}

// ===========================================================================
// Attribution Clarity
// ===========================================================================

/// Derive attribution clarity from provenance data.
let deriveAttributionClarity = (
  trustLevel: ProvenanceModel.trustLevel,
  hasOriginalLicense: bool,
): attributionClarity =>
  switch trustLevel {
  | Verified => ClearHuman
  | HumanReviewed => if hasOriginalLicense { ThirdPartyPreserved } else { ClearHuman }
  | AiAssisted => CoAuthoredReviewed
  | UnreviewedAi => CoAuthoredUnreviewed
  | Unknown => if hasOriginalLicense { ThirdPartyUnclear } else { Unknown
  }
  }

// ===========================================================================
// Issue Detection
// ===========================================================================

/// Check a single file for licensing issues.
let checkFile = (
  path: string,
  spdx: spdxStatus,
  attribution: attributionClarity,
  projectLicense: licenseFamiliy,
): array<licenseIssue> => {
  let issues = ref([])
  let nextId = ref(0)
  let addIssue = (kind, severity, desc, suggestion) => {
    nextId := nextId.contents + 1
    issues :=
      Array.concat(
        issues.contents,
        [
          {
            id: path ++ "-" ++ Int.toString(nextId.contents),
            file: path,
            lineRange: None,
            kind,
            severity,
            description: desc,
            suggestion,
            resolved: false,
          },
        ],
      )
  }

  // Check SPDX header.
  switch spdx {
  | Missing =>
    addIssue(
      MissingSpdxHeader,
      LicenseWarning,
      "File has no SPDX-License-Identifier header",
      "Add '// SPDX-License-Identifier: PMPL-1.0-or-later' to the first line",
    )
  | Malformed(reason) =>
    addIssue(
      MissingSpdxHeader,
      LicenseWarning,
      "Malformed SPDX header: " ++ reason,
      "Fix the SPDX-License-Identifier line to contain a valid SPDX expression",
    )
  | Present(id) => {
      let fileFamily = spdxToFamily(id)
      // Check for deprecated licenses.
      switch fileFamily {
      | AGPL3 =>
        addIssue(
          DeprecatedLicense("AGPL-3.0"),
          LicenseCritical,
          "File uses AGPL-3.0 which has been replaced by PMPL-1.0-or-later",
          "Update SPDX header to PMPL-1.0-or-later",
        )
      | _ => ()
      }
      // Check SPDX matches project license (allow MPL-2.0 as fallback).
      let _ = switch (projectLicense, fileFamily) {
      | (PMPL, PMPL) | (PMPL, MPL2) | (MPL2, MPL2) => ()
      | (expected, actual) =>
        if expected !== actual {
          addIssue(
            SpdxMismatch,
            LicenseInfo,
            "File license differs from project license",
            "Verify this is intentional (third-party code or platform requirement)",
          )
        }
      }
    }
  | NotApplicable => ()
  }

  // Check AI attribution clarity.
  switch attribution {
  | CoAuthoredUnreviewed =>
    addIssue(
      AiAttributionGap,
      LicenseWarning,
      "AI co-authored code has not been reviewed by a human",
      "Review and commit a follow-up to establish clear attribution",
    )
  | AiOnlyUnresolved =>
    addIssue(
      AiAttributionGap,
      LicenseCritical,
      "AI-only authored code with unresolved licensing",
      "Human must review, modify, and commit to establish copyright",
    )
  | ThirdPartyUnclear =>
    addIssue(
      ThirdPartyLicenseMissing,
      LicenseCritical,
      "Third-party code without clear license preservation",
      "Add original license header and SPDX identifier",
    )
  | _ => ()
  }

  issues.contents
}

/// Compute codebase-wide licensing health from file summaries.
let computeHealth = (summaries: array<fileLicenseSummary>): licensingHealth => {
  let total = Array.length(summaries)
  let withSpdx =
    summaries->Array.filter(s =>
      switch s.spdxStatus {
      | Present(_) => true
      | _ => false
      }
    )->Array.length
  let clearAttribution =
    summaries->Array.filter(s =>
      switch s.attribution {
      | ClearHuman | CoAuthoredReviewed | ThirdPartyPreserved => true
      | _ => false
      }
    )->Array.length
  let allIssues = summaries->Array.flatMap(s => s.issues)
  let totalIssues = Array.length(allIssues)
  let criticalCount =
    allIssues->Array.filter(i => i.severity === LicenseCritical)->Array.length
  let healthScore = if total == 0 {
    100.0
  } else {
    let spdxRatio = Int.toFloat(withSpdx) /. Int.toFloat(total) *. 40.0
    let attrRatio = Int.toFloat(clearAttribution) /. Int.toFloat(total) *. 40.0
    let issuePenalty = Float.fromInt(Math.Int.min(totalIssues, 20)) *. 1.0
    Math.max(0.0, spdxRatio +. attrRatio +. 20.0 -. issuePenalty)
  }
  {
    totalFiles: total,
    filesWithSpdx: withSpdx,
    filesClearAttribution: clearAttribution,
    totalIssues,
    criticalIssues: criticalCount,
    healthScore,
  }
}
