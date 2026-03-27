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

/// Tea_Json decoder for adoption stats.
let adoptionStatsDecoder: Tea_Json.decoder<adoptionStats> = {
  open Decoders
  map6(
    (
      totalRepos,
      pmplRepos,
      mplFallbackRepos,
      unlicensedRepos,
      quantumSignedRepos,
      byLicense,
    ): adoptionStats => {
      totalRepos,
      pmplRepos,
      mplFallbackRepos,
      unlicensedRepos,
      quantumSignedRepos,
      byLicense,
    },
    intField("total_repos"),
    intField("pmpl_repos"),
    intField("mpl_fallback_repos"),
    intField("unlicensed_repos"),
    intField("quantum_signed_repos"),
    fieldWithDefault("by_license", intDict, []),
  )
}

/// Parse adoption stats from JSON response.
let parseAdoptionStats = (jsonStr: string): result<adoptionStats, string> =>
  Decoders.decode(adoptionStatsDecoder, jsonStr)

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
