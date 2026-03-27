// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL VerificationDashboard Engine — pure computation for the verification panel.
///
/// Provides labels, filtering, sorting, aggregation, and hardcoded verification
/// data from the nextgen-languages audit. All functions are pure.

open VerificationDashboardModel

// ============================================================================
// Labels & Colours
// ============================================================================

/// Human-readable label for a proof system.
let proofSystemLabel = (ps: proofSystem): string =>
  switch ps {
  | Idris2Proof => "Idris 2"
  | CoqProof => "Coq"
  | LeanProof => "Lean 4"
  | IsabelleProof => "Isabelle"
  | AgdaProof => "Agda"
  | ManualProof => "Manual"
  }

/// Short code for a proof system.
let proofSystemCode = (ps: proofSystem): string =>
  switch ps {
  | Idris2Proof => "Idr"
  | CoqProof => "Coq"
  | LeanProof => "Lean"
  | IsabelleProof => "Isa"
  | AgdaProof => "Agda"
  | ManualProof => "Man"
  }

/// Colour for a proof system badge.
let proofSystemColour = (ps: proofSystem): string =>
  switch ps {
  | Idris2Proof => "text-violet-400 bg-violet-900/30"
  | CoqProof => "text-amber-400 bg-amber-900/30"
  | LeanProof => "text-blue-400 bg-blue-900/30"
  | IsabelleProof => "text-green-400 bg-green-900/30"
  | AgdaProof => "text-cyan-400 bg-cyan-900/30"
  | ManualProof => "text-gray-400 bg-gray-800/50"
  }

/// Human-readable label for a conformance level.
let conformanceLabel = (cl: conformanceLevel): string =>
  switch cl {
  | FullConformance => "Full"
  | PartialConformance => "Partial"
  | FailingConformance => "Failing"
  | NoConformanceSuite => "None"
  }

/// Colour for a conformance level.
let conformanceColour = (cl: conformanceLevel): string =>
  switch cl {
  | FullConformance => "text-emerald-400"
  | PartialConformance => "text-amber-400"
  | FailingConformance => "text-red-400"
  | NoConformanceSuite => "text-gray-600"
  }

/// Category tab label.
let categoryLabel = (cat: verificationDashboardCategory): string =>
  switch cat {
  | VdSummary => "Summary"
  | VdByLanguage => "By Language"
  | VdProofs => "Proofs"
  | VdBenchmarks => "Benchmarks"
  | VdFuzzing => "Fuzzing"
  }

/// All category tabs.
let allCategories: array<verificationDashboardCategory> = [
  VdSummary,
  VdByLanguage,
  VdProofs,
  VdBenchmarks,
  VdFuzzing,
]

/// Sort criterion label.
let sortLabel = (s: verificationSortBy): string =>
  switch s {
  | VdSortByName => "Name"
  | VdSortByTests => "Tests"
  | VdSortByPassRate => "Pass Rate"
  | VdSortByAdmitted => "Admitted"
  }

// ============================================================================
// Computed Metrics
// ============================================================================

/// Calculate pass rate as a percentage.
let passRate = (status: languageVerificationStatus): int => {
  if status.totalTests > 0 {
    status.passingTests * 100 / status.totalTests
  } else {
    0
  }
}

/// Colour for a pass rate percentage.
let passRateColour = (pct: int): string =>
  if pct >= 95 {
    "text-emerald-400"
  } else if pct >= 80 {
    "text-green-400"
  } else if pct >= 60 {
    "text-amber-400"
  } else {
    "text-red-400"
  }

/// Colour for admitted count.
let admittedColour = (count: int): string =>
  if count === 0 {
    "text-emerald-400"
  } else if count <= 5 {
    "text-amber-400"
  } else {
    "text-red-400"
  }

/// Progress bar string (10 chars wide).
let progressBar = (pct: int): string => {
  let filled = pct / 10
  let empty = 10 - filled
  let filledStr = String.repeat(String.fromCharCode(9608), filled)
  let emptyStr = String.repeat(String.fromCharCode(9617), empty)
  filledStr ++ emptyStr
}

// ============================================================================
// Filtering & Sorting
// ============================================================================

/// Filter by search text.
let filterBySearch = (statuses: array<languageVerificationStatus>, query: string): array<
  languageVerificationStatus,
> =>
  if query === "" {
    statuses
  } else {
    let q = String.toLowerCase(query)
    statuses->Array.filter(s => String.includes(String.toLowerCase(s.name), q))
  }

/// Filter to only languages with admitted/sorry debt.
let filterDebtOnly = (statuses: array<languageVerificationStatus>): array<
  languageVerificationStatus,
> => statuses->Array.filter(s => s.admittedCount > 0)

/// Sort languages by the given criterion.
let sortLanguages = (
  statuses: array<languageVerificationStatus>,
  sortBy: verificationSortBy,
): array<languageVerificationStatus> => {
  let copy = Array.copy(statuses)
  copy->Array.sort((a, b) =>
    switch sortBy {
    | VdSortByName => String.compare(a.name, b.name)
    | VdSortByTests => Float.fromInt(b.totalTests - a.totalTests)
    | VdSortByPassRate => Float.fromInt(passRate(a) - passRate(b))
    | VdSortByAdmitted => Float.fromInt(b.admittedCount - a.admittedCount)
    }
  )
  copy
}

// ============================================================================
// Aggregation
// ============================================================================

/// Aggregate summary across all languages.
type portfolioVerificationSummary = {
  totalLanguages: int,
  totalTests: int,
  totalPassing: int,
  totalFailing: int,
  totalAdmitted: int,
  totalProved: int,
  avgPassRate: int,
  languagesWithFuzzing: int,
  languagesFullConformance: int,
}

/// Compute the portfolio summary.
let computeSummary = (
  statuses: array<languageVerificationStatus>,
): portfolioVerificationSummary => {
  let total = Array.length(statuses)
  let totalTests = statuses->Array.reduce(0, (acc, s) => acc + s.totalTests)
  let totalPassing = statuses->Array.reduce(0, (acc, s) => acc + s.passingTests)
  let totalFailing = statuses->Array.reduce(0, (acc, s) => acc + s.failingTests)
  let totalAdmitted = statuses->Array.reduce(0, (acc, s) => acc + s.admittedCount)
  let totalProved = statuses->Array.reduce(0, (acc, s) => acc + s.provedCount)
  let avgPassRate = if totalTests > 0 {
    totalPassing * 100 / totalTests
  } else {
    0
  }
  let languagesWithFuzzing = statuses->Array.filter(s => s.fuzzing !== None)->Array.length
  let languagesFullConformance =
    statuses->Array.filter(s => s.conformance === FullConformance)->Array.length
  {
    totalLanguages: total,
    totalTests,
    totalPassing,
    totalFailing,
    totalAdmitted,
    totalProved,
    avgPassRate,
    languagesWithFuzzing,
    languagesFullConformance,
  }
}

// ============================================================================
// Hardcoded Verification Data — from nextgen-languages audit
// ============================================================================

/// All 16 languages with their verification status.
let allLanguageStatuses: array<languageVerificationStatus> = [
  {
    name: "AffineScript",
    totalTests: 247,
    passingTests: 241,
    failingTests: 6,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 12,
    proofSystems: [Idris2Proof],
    conformance: FullConformance,
    benchmarks: [
      {
        name: "typecheck-100",
        language: "AffineScript",
        meanMs: 12.3,
        stddevMs: 1.1,
        iterations: 1000,
        regression: false,
      },
      {
        name: "affine-verify",
        language: "AffineScript",
        meanMs: 45.7,
        stddevMs: 3.2,
        iterations: 500,
        regression: false,
      },
    ],
    fuzzing: None,
    lastRun: Some("2026-03-12T14:30:00Z"),
  },
  {
    name: "Eclexia",
    totalTests: 89,
    passingTests: 67,
    failingTests: 22,
    skippedTests: 0,
    admittedCount: 22,
    provedCount: 22,
    proofSystems: [Idris2Proof, CoqProof],
    conformance: FailingConformance,
    benchmarks: [
      {
        name: "dimensional-check",
        language: "Eclexia",
        meanMs: 28.5,
        stddevMs: 2.8,
        iterations: 500,
        regression: true,
      },
    ],
    fuzzing: None,
    lastRun: Some("2026-03-10T09:15:00Z"),
  },
  {
    name: "Anvomidav",
    totalTests: 56,
    passingTests: 48,
    failingTests: 8,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: FullConformance,
    benchmarks: [
      {
        name: "array-mul-1k",
        language: "Anvomidav",
        meanMs: 3.2,
        stddevMs: 0.4,
        iterations: 2000,
        regression: false,
      },
    ],
    fuzzing: None,
    lastRun: Some("2026-03-11T16:45:00Z"),
  },
  {
    name: "Ephapax",
    totalTests: 134,
    passingTests: 130,
    failingTests: 4,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 8,
    proofSystems: [Idris2Proof],
    conformance: FullConformance,
    benchmarks: [],
    fuzzing: None,
    lastRun: Some("2026-03-12T11:00:00Z"),
  },
  {
    name: "WokeLang",
    totalTests: 0,
    passingTests: 0,
    failingTests: 0,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: NoConformanceSuite,
    benchmarks: [],
    fuzzing: None,
    lastRun: None,
  },
  {
    name: "BetLang",
    totalTests: 45,
    passingTests: 38,
    failingTests: 7,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: FailingConformance,
    benchmarks: [],
    fuzzing: None,
    lastRun: Some("2026-03-09T08:30:00Z"),
  },
  {
    name: "Tangle",
    totalTests: 112,
    passingTests: 108,
    failingTests: 4,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 15,
    proofSystems: [Idris2Proof, LeanProof],
    conformance: FullConformance,
    benchmarks: [
      {
        name: "braid-compose",
        language: "Tangle",
        meanMs: 8.1,
        stddevMs: 0.9,
        iterations: 1000,
        regression: false,
      },
      {
        name: "jones-polynomial",
        language: "Tangle",
        meanMs: 156.3,
        stddevMs: 12.4,
        iterations: 200,
        regression: false,
      },
    ],
    fuzzing: Some({
      language: "Tangle",
      targets: 12,
      linesCovered: 3400,
      totalLines: 5200,
      crashesFound: 0,
      fuzzHours: 48.0,
    }),
    lastRun: Some("2026-03-13T10:00:00Z"),
  },
  {
    name: "My-Lang",
    totalTests: 78,
    passingTests: 72,
    failingTests: 6,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: FullConformance,
    benchmarks: [],
    fuzzing: None,
    lastRun: Some("2026-03-12T15:30:00Z"),
  },
  {
    name: "Crank",
    totalTests: 34,
    passingTests: 30,
    failingTests: 4,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: FailingConformance,
    benchmarks: [
      {
        name: "stack-ops-10k",
        language: "Crank",
        meanMs: 1.8,
        stddevMs: 0.2,
        iterations: 5000,
        regression: false,
      },
    ],
    fuzzing: None,
    lastRun: Some("2026-03-10T14:20:00Z"),
  },
  {
    name: "Delimit",
    totalTests: 98,
    passingTests: 91,
    failingTests: 5,
    skippedTests: 2,
    admittedCount: 2,
    provedCount: 11,
    proofSystems: [Idris2Proof],
    conformance: FullConformance,
    benchmarks: [],
    fuzzing: None,
    lastRun: Some("2026-03-11T09:00:00Z"),
  },
  {
    name: "Sunyata",
    totalTests: 0,
    passingTests: 0,
    failingTests: 0,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: NoConformanceSuite,
    benchmarks: [],
    fuzzing: None,
    lastRun: None,
  },
  {
    name: "HexSweep",
    totalTests: 23,
    passingTests: 19,
    failingTests: 4,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: FailingConformance,
    benchmarks: [
      {
        name: "hex-fill-100x100",
        language: "HexSweep",
        meanMs: 34.2,
        stddevMs: 4.1,
        iterations: 300,
        regression: false,
      },
    ],
    fuzzing: None,
    lastRun: Some("2026-03-08T11:15:00Z"),
  },
  {
    name: "Cascade",
    totalTests: 41,
    passingTests: 35,
    failingTests: 6,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: FailingConformance,
    benchmarks: [],
    fuzzing: None,
    lastRun: Some("2026-03-09T16:30:00Z"),
  },
  {
    name: "Polytope",
    totalTests: 76,
    passingTests: 68,
    failingTests: 8,
    skippedTests: 0,
    admittedCount: 5,
    provedCount: 18,
    proofSystems: [Idris2Proof, CoqProof],
    conformance: FullConformance,
    benchmarks: [],
    fuzzing: None,
    lastRun: Some("2026-03-12T08:45:00Z"),
  },
  {
    name: "Coda",
    totalTests: 28,
    passingTests: 22,
    failingTests: 6,
    skippedTests: 0,
    admittedCount: 0,
    provedCount: 0,
    proofSystems: [],
    conformance: FailingConformance,
    benchmarks: [],
    fuzzing: None,
    lastRun: Some("2026-03-07T13:00:00Z"),
  },
  {
    name: "Strata",
    totalTests: 145,
    passingTests: 138,
    failingTests: 5,
    skippedTests: 2,
    admittedCount: 3,
    provedCount: 24,
    proofSystems: [Idris2Proof, LeanProof, CoqProof],
    conformance: FullConformance,
    benchmarks: [
      {
        name: "universe-check",
        language: "Strata",
        meanMs: 67.8,
        stddevMs: 5.3,
        iterations: 500,
        regression: false,
      },
      {
        name: "stratification",
        language: "Strata",
        meanMs: 23.1,
        stddevMs: 2.0,
        iterations: 1000,
        regression: false,
      },
    ],
    fuzzing: Some({
      language: "Strata",
      targets: 8,
      linesCovered: 4100,
      totalLines: 6800,
      crashesFound: 1,
      fuzzHours: 72.0,
    }),
    lastRun: Some("2026-03-13T09:30:00Z"),
  },
]

/// Find a language verification status by name.
let findLanguage = (name: string): option<languageVerificationStatus> => {
  allLanguageStatuses->Array.find(s => s.name === name)
}

/// Get all benchmark entries across all languages.
let allBenchmarks = (): array<benchmarkEntry> => {
  allLanguageStatuses->Array.flatMap(s => s.benchmarks)
}

/// Get all fuzzing coverage entries.
let allFuzzingCoverage = (): array<fuzzingCoverage> => {
  allLanguageStatuses->Array.filterMap(s => s.fuzzing)
}
