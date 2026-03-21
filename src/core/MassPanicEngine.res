// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Mass Panic Engine — pure functions for organisation-scale batch
/// scanning: repo filtering, sorting, delta computation, imaging helpers,
/// and temporal snapshot navigation.
///
/// All functions are side-effect-free and operate on MassPanicModel types.
/// Tauri commands and I/O live in MassPanicCmd; this module is for
/// deterministic transformations only.

open MassPanicModel

// =========================================================================
// Default state
// =========================================================================

/// Initial state for the Mass Panic panel. Incremental mode is on by
/// default because repeat scans are the common case.
let defaultState: massPanicState = init

// =========================================================================
// Sorting helpers
// =========================================================================

/// Sort repos by the active sort mode. Each mode produces a stable
/// ordering so the list does not jump around during a scan.
let sortRepos = (repos: array<repoResult>, mode: repoSortMode): array<repoResult> => {
  let sorted = Array.copy(repos)
  sorted->Array.sort((a, b) =>
    switch mode {
    | ByRisk =>
      // Riskiest first: compare by critical desc, then high desc.
      let cmp = Int.compare(b.critical, a.critical)
      if cmp != 0.0 {
        cmp
      } else {
        Int.compare(b.high, a.high)
      }
    | ByName => String.compare(a.repoName, b.repoName)
    | ByFindings => Int.compare(b.totalFindings, a.totalFindings)
    | ByDuration =>
      let da = a.scanDuration->Option.getOr(0.0)
      let db = b.scanDuration->Option.getOr(0.0)
      Float.compare(db, da)
    }
  )
  sorted
}

// =========================================================================
// Filtering helpers
// =========================================================================

/// Filter repos by the active filter mode.
let filterRepos = (repos: array<repoResult>, mode: repoFilterMode): array<repoResult> =>
  switch mode {
  | AllRepos => repos
  | FindingsOnly => repos->Array.filter(r => r.totalFindings > 0)
  | CriticalOnly => repos->Array.filter(r => r.critical > 0)
  | FailedOnly =>
    repos->Array.filter(r =>
      switch r.status {
      | Failed(_) => true
      | _ => false
      }
    )
  }

/// Apply text search across repo names.
let searchRepos = (repos: array<repoResult>, query: string): array<repoResult> =>
  if query == "" {
    repos
  } else {
    let q = String.toLowerCase(query)
    repos->Array.filter(r => String.includes(String.toLowerCase(r.repoName), q))
  }

/// Composite: filter → search → sort in one pass.
let applyFilters = (
  repos: array<repoResult>,
  filterMode: repoFilterMode,
  searchText: string,
  sortMode: repoSortMode,
): array<repoResult> =>
  repos->filterRepos(filterMode)->searchRepos(searchText)->sortRepos(sortMode)

// =========================================================================
// Selection helpers
// =========================================================================

/// Check whether a given index is in the selected set.
let isSelected = (selected: array<int>, idx: int): bool =>
  selected->Array.some(i => i == idx)

/// Toggle a repo index in/out of the selected set.
let toggleSelection = (selected: array<int>, idx: int): array<int> =>
  if isSelected(selected, idx) {
    selected->Array.filter(i => i != idx)
  } else {
    Array.concat(selected, [idx])
  }

/// Select all repo indices (0..n-1).
let selectAllIndices = (count: int): array<int> =>
  Array.fromInitializer(~length=count, i => i)

// =========================================================================
// Aggregate statistics
// =========================================================================

/// Count repos that completed scanning (not queued, not failed).
let completedCount = (repos: array<repoResult>): int =>
  repos->Array.filter(r =>
    switch r.status {
    | Complete | Skipped => true
    | _ => false
    }
  )->Array.length

/// Count repos with at least one critical finding.
let criticalRepoCount = (repos: array<repoResult>): int =>
  repos->Array.filter(r => r.critical > 0)->Array.length

/// Total findings across all repos.
let totalFindings = (repos: array<repoResult>): int =>
  repos->Array.reduce(0, (acc, r) => acc + r.totalFindings)

/// Compute overall scan progress as a fraction (0.0–1.0).
let computeProgress = (repos: array<repoResult>): float => {
  let total = repos->Array.length
  if total == 0 {
    0.0
  } else {
    let done = completedCount(repos)
    Float.fromInt(done) /. Float.fromInt(total)
  }
}

// =========================================================================
// Delta helpers
// =========================================================================

/// Human-readable label for a change direction.
let changeDirectionLabel = (dir: string): string =>
  switch dir {
  | "improved" => "Improved"
  | "regressed" => "Regressed"
  | "unchanged" => "Unchanged"
  | "new" => "New"
  | other => other
  }

/// CSS colour class for a change direction.
let changeDirectionColour = (dir: string): string =>
  switch dir {
  | "improved" => "text-emerald-400"
  | "regressed" => "text-red-400"
  | "unchanged" => "text-gray-400"
  | "new" => "text-cyan-400"
  | _ => "text-gray-500"
  }

/// Count deltas that regressed.
let regressedCount = (deltas: array<deltaEntry>): int =>
  deltas->Array.filter(d => d.changeDirection == "regressed")->Array.length

/// Count deltas that improved.
let improvedCount = (deltas: array<deltaEntry>): int =>
  deltas->Array.filter(d => d.changeDirection == "improved")->Array.length

// =========================================================================
// Imaging helpers (fNIRS-style spatial health map)
// =========================================================================

/// Format a health score as a percentage string (e.g. "87.3%").
let healthLabel = (score: float): string =>
  Float.toFixed(score *. 100.0, ~digits=1) ++ "%"

/// CSS colour class for a health score (green→yellow→red gradient).
let healthColour = (score: float): string =>
  if score >= 0.8 {
    "text-emerald-400"
  } else if score >= 0.6 {
    "text-amber-400"
  } else if score >= 0.4 {
    "text-orange-400"
  } else {
    "text-red-400"
  }

/// Total weak points from a risk distribution.
let riskDistTotal = (dist: riskDistribution): int =>
  dist.healthy + dist.low + dist.moderate + dist.high + dist.critical

/// Find the top-N riskiest nodes in a system image.
let topRiskyNodes = (image: systemImage, n: int): array<imageNode> => {
  let sorted = Array.copy(image.nodes)
  sorted->Array.sort((a, b) => Float.compare(b.riskIntensity, a.riskIntensity))
  sorted->Array.slice(~start=0, ~end=n)
}

// =========================================================================
// Temporal helpers
// =========================================================================

/// Human-readable trend label.
let trendLabel = (trend: string): string =>
  switch trend {
  | "improving" => "Improving"
  | "degrading" => "Degrading"
  | "stable" => "Stable"
  | other => other
  }

/// CSS colour class for a temporal trend.
let trendColour = (trend: string): string =>
  switch trend {
  | "improving" => "text-emerald-400"
  | "degrading" => "text-red-400"
  | "stable" => "text-gray-400"
  | _ => "text-gray-500"
  }

/// Sub-view tab labels.
let viewLabel = (v: massPanicView): string =>
  switch v {
  | ScanView => "Scan"
  | ImagingView => "Imaging"
  | TemporalView => "Temporal"
  }

/// All sub-view tabs.
let allViews: array<massPanicView> = [ScanView, ImagingView, TemporalView]

/// Format a scan duration in seconds as a human-readable string.
let formatDuration = (seconds: float): string =>
  if seconds < 60.0 {
    Float.toFixed(seconds, ~digits=1) ++ "s"
  } else {
    let mins = Float.toInt(seconds /. 60.0)
    let secs = mod(Float.toInt(seconds), 60)
    Int.toString(mins) ++ "m " ++ Int.toString(secs) ++ "s"
  }

/// Human-readable label for repo scan status.
let statusLabel = (status: repoScanStatus): string =>
  switch status {
  | Queued => "Queued"
  | Scanning => "Scanning"
  | Complete => "Complete"
  | Skipped => "Skipped"
  | Failed(reason) => "Failed: " ++ reason
  }

/// Human-readable label for filter mode.
let filterModeLabel = (mode: repoFilterMode): string =>
  switch mode {
  | AllRepos => "All"
  | FindingsOnly => "With Findings"
  | CriticalOnly => "Critical Only"
  | FailedOnly => "Failed"
  }

/// All filter modes for the filter dropdown.
let allFilterModes: array<repoFilterMode> = [AllRepos, FindingsOnly, CriticalOnly, FailedOnly]

/// Human-readable label for sort mode.
let sortModeLabel = (mode: repoSortMode): string =>
  switch mode {
  | ByRisk => "Risk"
  | ByName => "Name"
  | ByFindings => "Findings"
  | ByDuration => "Duration"
  }

/// All sort modes for the sort dropdown.
let allSortModes: array<repoSortMode> = [ByRisk, ByName, ByFindings, ByDuration]
