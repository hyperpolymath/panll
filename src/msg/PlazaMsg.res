// SPDX-License-Identifier: PMPL-1.0-or-later

/// Palimpsest Plaza panel messages -- PMPL licensing adoption, compliance
/// scanning, and governance. The plaza backend scans local filesystem.

open Model

type plazaMsg =
  /// Load adoption statistics across the ecosystem.
  | LoadAdoptionStats
  /// Adoption stats loaded (or failed).
  | AdoptionStatsLoaded(result<string, string>)
  /// Scan a specific repo for compliance.
  | ScanRepo(string)
  /// Repo scan result.
  | RepoScanned(result<string, string>)
  /// Change the active category tab.
  | SetPlazaCategory(plazaCategory)
  /// Update the text filter.
  | SetPlazaFilter(string)
  /// TypeLL cross-panel type check result for compliance spec types.
  | TypeCheckResult(result<string, string>)
