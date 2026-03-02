// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Palimpsest Plaza Engine — pure computation for the PMPL licensing panel.
///
/// All functions are pure. Handles parsing of scan results, adoption stats,
/// compatibility results, and provides display helpers for the view layer.

open PlazaModel

/// Human-readable label for a compliance level.
let complianceLevelLabel = (level: complianceLevel): string => {
  switch level {
  | FullCompliance => "Full Compliance"
  | PartialCompliance => "Partial"
  | NonCompliant => "Non-Compliant"
  | Unknown => "Not Scanned"
  }
}

/// CSS colour class for a compliance level.
let complianceLevelColour = (level: complianceLevel): string => {
  switch level {
  | FullCompliance => "text-emerald-400"
  | PartialCompliance => "text-amber-400"
  | NonCompliant => "text-red-400"
  | Unknown => "text-gray-500"
  }
}

/// Background colour class for a compliance badge.
let complianceLevelBg = (level: complianceLevel): string => {
  switch level {
  | FullCompliance => "bg-emerald-900/50 border-emerald-700"
  | PartialCompliance => "bg-amber-900/50 border-amber-700"
  | NonCompliant => "bg-red-900/50 border-red-700"
  | Unknown => "bg-gray-800/50 border-gray-700"
  }
}

/// Human-readable label for a category tab.
let categoryLabel = (cat: plazaCategory): string => {
  switch cat {
  | Dashboard => "Dashboard"
  | Compliance => "Compliance"
  | Provenance => "Provenance"
  | Compatibility => "Compatibility"
  | EthicalUse => "Ethical Use"
  | Governance => "Governance"
  | Adopt => "Adopt PMPL"
  }
}

/// All category tabs in display order.
let allCategories: array<plazaCategory> = [
  Dashboard,
  Compliance,
  Provenance,
  Compatibility,
  EthicalUse,
  Governance,
  Adopt,
]

/// Human-readable label for a signature status.
let signatureStatusLabel = (status: signatureStatus): string => {
  switch status {
  | SignatureValid => "Valid"
  | SignatureInvalid(reason) => `Invalid: ${reason}`
  | NoSignature => "None"
  | ClassicalOnly => "Classical (upgrade recommended)"
  }
}

/// Known licenses for the compatibility checker dropdown.
let commonLicenses: array<string> = [
  "MIT",
  "Apache-2.0",
  "GPL-2.0",
  "GPL-3.0",
  "LGPL-2.1",
  "LGPL-3.0",
  "AGPL-3.0",
  "BSD-2-Clause",
  "BSD-3-Clause",
  "MPL-2.0",
  "ISC",
  "CC0-1.0",
  "Unlicense",
]

/// Parse adoption stats from JSON response.
let parseAdoptionStats = (jsonStr: string): result<adoptionStats, string> => {
  try {
    let json = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(json) {
    | Object(obj) => {
        let getInt = (key: string): int =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Float.toInt(n)
            | _ => 0
            }
          | None => 0
          }

        let byLicense = switch Dict.get(obj, "by_license") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | Object(licObj) =>
            Dict.toArray(licObj)->Array.filterMap(((key, val)) =>
              switch JSON.Classify.classify(val) {
              | Number(n) => Some((key, Float.toInt(n)))
              | _ => None
              }
            )
          | _ => []
          }
        | None => []
        }

        Ok({
          totalRepos: getInt("total_repos"),
          pmplRepos: getInt("pmpl_repos"),
          mplFallbackRepos: getInt("mpl_fallback_repos"),
          unlicensedRepos: getInt("unlicensed_repos"),
          quantumSignedRepos: getInt("quantum_signed_repos"),
          byLicense,
        })
      }
    | _ => Error("Expected object in adoption stats response")
    }
  } catch {
  | _ => Error("Failed to parse adoption stats JSON")
  }
}

/// Compute the PMPL adoption percentage.
let adoptionPercentage = (stats: adoptionStats): float => {
  if stats.totalRepos === 0 {
    0.0
  } else {
    Int.toFloat(stats.pmplRepos) /. Int.toFloat(stats.totalRepos) *. 100.0
  }
}

/// Compute the overall compliance percentage (PMPL + MPL fallback).
let licensedPercentage = (stats: adoptionStats): float => {
  if stats.totalRepos === 0 {
    0.0
  } else {
    Int.toFloat(stats.totalRepos - stats.unlicensedRepos) /. Int.toFloat(stats.totalRepos) *. 100.0
  }
}
