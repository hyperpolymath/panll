// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Harmonization Engine — pure helpers for the harmonization
/// monitor panel.
///
/// All functions are pure (no side effects). Provides stats computation,
/// entry filtering, sorting, and verdict colour mappings.

open NesyHarmonizeModel

// ============================================================================
// Statistics Computation
// ============================================================================

/// Compute aggregate statistics from a list of harmonization entries.
/// Counts verdicts by type and calculates the symbolic win rate.
let computeStats = (entries: array<harmonizationEntry>): harmonizeStats => {
  let totalCount = Array.length(entries)
  let certifiedSafe = entries->Array.filter(e => e.verdict == CertifiedSafe)->Array.length
  let requiresReview = entries->Array.filter(e => e.verdict == RequiresReview)->Array.length
  let criticalUnsafe = entries->Array.filter(e => e.verdict == CriticalUnsafe)->Array.length
  let symbolicWins = entries->Array.filter(e => e.symbolicWins)->Array.length
  let symbolicWinRate = if totalCount > 0 {
    Int.toFloat(symbolicWins) /. Int.toFloat(totalCount)
  } else {
    0.0
  }
  {totalCount, certifiedSafe, requiresReview, criticalUnsafe, symbolicWinRate}
}

// ============================================================================
// Filtering
// ============================================================================

/// Filter entries by harmonized verdict type. Returns all entries if filter
/// is None.
let filterEntries = (
  entries: array<harmonizationEntry>,
  filter: option<harmonizedVerdict>,
): array<harmonizationEntry> => {
  switch filter {
  | None => entries
  | Some(verdict) => entries->Array.filter(e => e.verdict == verdict)
  }
}

// ============================================================================
// Entry Management
// ============================================================================

/// Add a new entry to the front of the entries array (newest first).
let addEntry = (
  entries: array<harmonizationEntry>,
  entry: harmonizationEntry,
): array<harmonizationEntry> => {
  Array.concat([entry], entries)
}

/// Sort entries by timestamp (newest first, lexicographic ISO 8601 sort).
let sortByTimestamp = (
  entries: array<harmonizationEntry>,
): array<harmonizationEntry> => {
  let sorted = Array.copy(entries)
  sorted->Array.sort((a, b) => String.compare(b.timestamp, a.timestamp))
  sorted
}

// ============================================================================
// Colour Mappings
// ============================================================================

/// Tailwind background colour class for a harmonized verdict.
/// Green for safe, amber for review, red for unsafe.
let verdictColor = (verdict: harmonizedVerdict): string => {
  switch verdict {
  | CertifiedSafe => "bg-emerald-600 text-white"
  | RequiresReview => "bg-amber-500 text-white"
  | CriticalUnsafe => "bg-red-600 text-white"
  }
}

/// Tailwind text colour class for a neural verdict.
let neuralVerdictColor = (verdict: neuralVerdict): string => {
  switch verdict {
  | ProbableSafe => "text-emerald-400"
  | Unsure => "text-amber-400"
  | ProbableUnsafe => "text-red-400"
  }
}

/// Tailwind text colour class for a symbolic verdict.
let symbolicVerdictColor = (verdict: symbolicVerdict): string => {
  switch verdict {
  | ProvenSafe => "text-emerald-400"
  | NoProof => "text-gray-400"
  | ProvenUnsafe => "text-red-400"
  }
}

/// Tailwind text colour class for a confidence level.
let confidenceColor = (confidence: confidenceLevel): string => {
  switch confidence {
  | Low => "text-gray-400"
  | High => "text-blue-400"
  | Absolute => "text-emerald-400"
  }
}

// ============================================================================
// Display Labels
// ============================================================================

/// Human-readable label for a neural verdict.
let neuralLabel = (verdict: neuralVerdict): string => {
  switch verdict {
  | ProbableSafe => "Probable Safe"
  | Unsure => "Unsure"
  | ProbableUnsafe => "Probable Unsafe"
  }
}

/// Human-readable label for a symbolic verdict.
let symbolicLabel = (verdict: symbolicVerdict): string => {
  switch verdict {
  | ProvenSafe => "Proven Safe"
  | NoProof => "No Proof"
  | ProvenUnsafe => "Proven Unsafe"
  }
}

/// Human-readable label for a harmonized verdict.
let verdictLabel = (verdict: harmonizedVerdict): string => {
  switch verdict {
  | CertifiedSafe => "Certified Safe"
  | RequiresReview => "Requires Review"
  | CriticalUnsafe => "Critical Unsafe"
  }
}

/// Human-readable label for a confidence level.
let confidenceLabel = (confidence: confidenceLevel): string => {
  switch confidence {
  | Low => "Low"
  | High => "High"
  | Absolute => "Absolute"
  }
}

// ============================================================================
// Initial State
// ============================================================================

/// Default initial state for the NeSy Harmonization Monitor.
let init: nesyHarmonizeState = {
  entries: [],
  filter: None,
  autoRefresh: true,
  refreshIntervalMs: 5000,
  stats: {
    totalCount: 0,
    certifiedSafe: 0,
    requiresReview: 0,
    criticalUnsafe: 0,
    symbolicWinRate: 0.0,
  },
}
