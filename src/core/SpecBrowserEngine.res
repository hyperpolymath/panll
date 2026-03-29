// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL SpecBrowser Engine — pure computation for the language specification browser.
///
/// Provides labels, filtering, sorting, taxonomy completeness calculations,
/// and hardcoded spec data for all 16 nextgen-languages projects.
///
/// No side effects — all filesystem scanning would go through Gossamer commands.

open SpecBrowserModel

// ============================================================================
// File Kind Labels & Paths
// ============================================================================

/// Human-readable label for a spec file kind.
let fileKindLabel = (kind: specFileKind): string =>
  switch kind {
  | GrammarEbnf => "Grammar (EBNF)"
  | SpecCoreScm => "SPEC.core.scm"
  | TypingRules => "Typing Rules"
  | OperationalSemantics => "Operational Semantics"
  | DenotationalSemantics => "Denotational Semantics"
  | ConformanceTests => "Conformance Tests"
  | Benchmarks => "Benchmarks"
  | ProofArtefacts => "Proof Artefacts"
  }

/// Short code for a spec file kind.
let fileKindCode = (kind: specFileKind): string =>
  switch kind {
  | GrammarEbnf => "EBNF"
  | SpecCoreScm => "SPEC"
  | TypingRules => "TYPE"
  | OperationalSemantics => "OPSEM"
  | DenotationalSemantics => "DENSEM"
  | ConformanceTests => "TEST"
  | Benchmarks => "BENCH"
  | ProofArtefacts => "PROOF"
  }

/// Expected relative path for a standard file within a language project.
let fileKindPath = (kind: specFileKind): string =>
  switch kind {
  | GrammarEbnf => "grammar.ebnf"
  | SpecCoreScm => "SPEC.core.scm"
  | TypingRules => "typing-rules.md"
  | OperationalSemantics => "operational-semantics.md"
  | DenotationalSemantics => "denotational-semantics.md"
  | ConformanceTests => "tests/conformance/"
  | Benchmarks => "benchmarks/"
  | ProofArtefacts => "proofs/"
  }

/// Colour for file presence indicator.
let presenceColour = (exists: bool): string =>
  if exists {
    "text-emerald-400"
  } else {
    "text-red-400"
  }

/// All standard file kinds in display order.
let allFileKinds: array<specFileKind> = [
  GrammarEbnf,
  SpecCoreScm,
  TypingRules,
  OperationalSemantics,
  DenotationalSemantics,
  ConformanceTests,
  Benchmarks,
  ProofArtefacts,
]

// ============================================================================
// Category Tab Labels
// ============================================================================

/// Label for a category tab.
let categoryLabel = (cat: specBrowserCategory): string =>
  switch cat {
  | SpecOverview => "Overview"
  | SpecComparison => "Compare"
  | SpecGrammar => "Grammar"
  | SpecTypingRules => "Typing Rules"
  | SpecVerification => "Verification"
  }

/// All category tabs in display order.
let allCategories: array<specBrowserCategory> = [
  SpecOverview,
  SpecComparison,
  SpecGrammar,
  SpecTypingRules,
  SpecVerification,
]

// ============================================================================
// Taxonomy Completeness
// ============================================================================

/// Calculate taxonomy completeness for a language (percentage of standard files present).
let computeTaxonomyCompleteness = (files: array<filePresence>): int => {
  let total = Array.length(files)
  if total === 0 {
    0
  } else {
    let present = files->Array.filter(f => f.exists)->Array.length
    present * 100 / total
  }
}

/// Colour for taxonomy completeness percentage.
let completenessColour = (pct: int): string =>
  if pct >= 80 {
    "text-emerald-400"
  } else if pct >= 50 {
    "text-amber-400"
  } else if pct >= 25 {
    "text-orange-400"
  } else {
    "text-red-400"
  }

/// Badge class for taxonomy completeness.
let completenessBadge = (pct: int): string =>
  if pct >= 80 {
    "bg-emerald-900/30 text-emerald-300 border-emerald-700"
  } else if pct >= 50 {
    "bg-amber-900/30 text-amber-300 border-amber-700"
  } else if pct >= 25 {
    "bg-orange-900/30 text-orange-300 border-orange-700"
  } else {
    "bg-red-900/30 text-red-300 border-red-700"
  }

/// Progress bar string (10 chars wide using block characters).
let progressBar = (pct: int): string => {
  let filled = pct / 10
  let empty = 10 - filled
  let filledStr = String.repeat(String.fromCharCode(9608), filled) // U+2588 FULL BLOCK
  let emptyStr = String.repeat(String.fromCharCode(9617), empty) // U+2591 LIGHT SHADE
  filledStr ++ emptyStr
}

// ============================================================================
// Filtering & Sorting
// ============================================================================

/// Filter languages by name search text.
let filterBySearch = (langs: array<specLanguageEntry>, query: string): array<specLanguageEntry> =>
  if query === "" {
    langs
  } else {
    let q = String.toLowerCase(query)
    langs->Array.filter(l =>
      String.includes(String.toLowerCase(l.name), q) ||
      String.includes(String.toLowerCase(l.description), q) ||
      String.includes(String.toLowerCase(l.implLang), q)
    )
  }

/// Filter to only languages with incomplete taxonomy.
let filterIncomplete = (langs: array<specLanguageEntry>): array<specLanguageEntry> =>
  langs->Array.filter(l => l.taxonomyCompleteness < 100)

/// Sort languages by taxonomy completeness (ascending — worst first).
let sortByCompleteness = (langs: array<specLanguageEntry>): array<specLanguageEntry> => {
  let copy = Array.copy(langs)
  copy->Array.sort((a, b) => Float.fromInt(a.taxonomyCompleteness - b.taxonomyCompleteness))
  copy
}

/// Sort languages alphabetically by name.
let sortByName = (langs: array<specLanguageEntry>): array<specLanguageEntry> => {
  let copy = Array.copy(langs)
  copy->Array.sort((a, b) => String.compare(a.name, b.name))
  copy
}

// ============================================================================
// Hardcoded Language Spec Data — from nextgen-languages assessment
// ============================================================================

/// Helper to build a file presence with default path.
let mkFile = (kind: specFileKind, exists: bool, lines: int): filePresence => {
  {kind, exists, lineCount: lines, path: fileKindPath(kind)}
}

/// Default verification summary (no data).
let emptyVerification: verificationSummary = {
  totalTests: 0,
  passingTests: 0,
  admittedCount: 0,
  provedCount: 0,
  hasFuzzing: false,
  conformancePassing: false,
}

/// All 16 nextgen-languages with their specification inventory.
/// This data mirrors the Language Forge assessment but focuses on
/// specification artefacts rather than implementation completion.
let allLanguageSpecs: array<specLanguageEntry> = [
  {
    name: "AffineScript",
    description: "Affine type system with dependent types for systems programming",
    implLang: "OCaml",
    files: [
      mkFile(GrammarEbnf, true, 420),
      mkFile(SpecCoreScm, true, 310),
      mkFile(TypingRules, true, 180),
      mkFile(OperationalSemantics, true, 95),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 1200),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, true, 850),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      totalTests: 247,
      passingTests: 241,
      provedCount: 12,
      admittedCount: 0,
      hasFuzzing: false,
      conformancePassing: true,
    },
    taxonomyCompleteness: 75,
  },
  {
    name: "Eclexia",
    description: "Dimensional type system with physical unit tracking",
    implLang: "Idris2",
    files: [
      mkFile(GrammarEbnf, true, 380),
      mkFile(SpecCoreScm, true, 290),
      mkFile(TypingRules, true, 250),
      mkFile(OperationalSemantics, true, 120),
      mkFile(DenotationalSemantics, true, 85),
      mkFile(ConformanceTests, true, 560),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, true, 1400),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      totalTests: 89,
      passingTests: 67,
      provedCount: 22,
      admittedCount: 22,
      hasFuzzing: false,
      conformancePassing: false,
    },
    taxonomyCompleteness: 88,
  },
  {
    name: "Anvomidav",
    description: "Array-oriented numerical language with verified dimensions",
    implLang: "Rust",
    files: [
      mkFile(GrammarEbnf, true, 200),
      mkFile(SpecCoreScm, true, 150),
      mkFile(TypingRules, false, 0),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 340),
      mkFile(Benchmarks, true, 120),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 56,
      passingTests: 48,
      hasFuzzing: false,
      conformancePassing: true,
    },
    taxonomyCompleteness: 50,
  },
  {
    name: "Ephapax",
    description: "Single-use value language — every binding used exactly once",
    implLang: "Haskell",
    files: [
      mkFile(GrammarEbnf, true, 160),
      mkFile(SpecCoreScm, true, 180),
      mkFile(TypingRules, true, 200),
      mkFile(OperationalSemantics, true, 110),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 420),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, true, 600),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      totalTests: 134,
      passingTests: 130,
      provedCount: 8,
      admittedCount: 0,
      hasFuzzing: false,
      conformancePassing: true,
    },
    taxonomyCompleteness: 75,
  },
  {
    name: "WokeLang",
    description: "Socially-aware constraint language with fairness typing",
    implLang: "Elixir",
    files: [
      mkFile(GrammarEbnf, true, 140),
      mkFile(SpecCoreScm, true, 120),
      mkFile(TypingRules, false, 0),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, false, 0),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: emptyVerification,
    taxonomyCompleteness: 25,
  },
  {
    name: "BetLang",
    description: "Probabilistic programming language with Bayesian type inference",
    implLang: "OCaml",
    files: [
      mkFile(GrammarEbnf, true, 180),
      mkFile(SpecCoreScm, true, 160),
      mkFile(TypingRules, true, 140),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 280),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 45,
      passingTests: 38,
      conformancePassing: false,
    },
    taxonomyCompleteness: 50,
  },
  {
    name: "Tangle",
    description: "Topological programming — braid groups and knot invariants as types",
    implLang: "Rust",
    files: [
      mkFile(GrammarEbnf, true, 220),
      mkFile(SpecCoreScm, true, 200),
      mkFile(TypingRules, true, 170),
      mkFile(OperationalSemantics, true, 130),
      mkFile(DenotationalSemantics, true, 95),
      mkFile(ConformanceTests, true, 510),
      mkFile(Benchmarks, true, 80),
      mkFile(ProofArtefacts, true, 700),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      totalTests: 112,
      passingTests: 108,
      provedCount: 15,
      admittedCount: 0,
      hasFuzzing: true,
      conformancePassing: true,
    },
    taxonomyCompleteness: 100,
  },
  {
    name: "My-Lang",
    description: "AI-native language — 4 dialects (Solo, Duet, Ensemble, Me)",
    implLang: "Rust",
    files: [
      mkFile(GrammarEbnf, true, 300),
      mkFile(SpecCoreScm, true, 240),
      mkFile(TypingRules, true, 160),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 380),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 78,
      passingTests: 72,
      conformancePassing: true,
    },
    taxonomyCompleteness: 50,
  },
  {
    name: "Crank",
    description: "Stack-based language with certified resource bounds",
    implLang: "Rust",
    files: [
      mkFile(GrammarEbnf, true, 120),
      mkFile(SpecCoreScm, false, 0),
      mkFile(TypingRules, false, 0),
      mkFile(OperationalSemantics, true, 80),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 210),
      mkFile(Benchmarks, true, 60),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 34,
      passingTests: 30,
      conformancePassing: false,
    },
    taxonomyCompleteness: 38,
  },
  {
    name: "Delimit",
    description: "Delimited continuations as first-class types",
    implLang: "OCaml",
    files: [
      mkFile(GrammarEbnf, true, 190),
      mkFile(SpecCoreScm, true, 170),
      mkFile(TypingRules, true, 210),
      mkFile(OperationalSemantics, true, 150),
      mkFile(DenotationalSemantics, true, 120),
      mkFile(ConformanceTests, true, 450),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, true, 550),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 98,
      passingTests: 91,
      provedCount: 11,
      admittedCount: 2,
      conformancePassing: true,
    },
    taxonomyCompleteness: 88,
  },
  {
    name: "Sunyata",
    description: "Emptiness-typed language — void and bottom as first-class",
    implLang: "Haskell",
    files: [
      mkFile(GrammarEbnf, true, 100),
      mkFile(SpecCoreScm, true, 90),
      mkFile(TypingRules, true, 80),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, false, 0),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: emptyVerification,
    taxonomyCompleteness: 38,
  },
  {
    name: "HexSweep",
    description: "Hexagonal grid computation with spatial types",
    implLang: "Rust",
    files: [
      mkFile(GrammarEbnf, true, 150),
      mkFile(SpecCoreScm, false, 0),
      mkFile(TypingRules, false, 0),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 180),
      mkFile(Benchmarks, true, 45),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 23,
      passingTests: 19,
      conformancePassing: false,
    },
    taxonomyCompleteness: 25,
  },
  {
    name: "Cascade",
    description: "Dataflow language with verified pipeline types",
    implLang: "Gleam",
    files: [
      mkFile(GrammarEbnf, true, 170),
      mkFile(SpecCoreScm, true, 130),
      mkFile(TypingRules, false, 0),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 260),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 41,
      passingTests: 35,
      conformancePassing: false,
    },
    taxonomyCompleteness: 38,
  },
  {
    name: "Polytope",
    description: "Geometric type theory — polytopes and simplicial types",
    implLang: "Idris2",
    files: [
      mkFile(GrammarEbnf, true, 240),
      mkFile(SpecCoreScm, true, 220),
      mkFile(TypingRules, true, 300),
      mkFile(OperationalSemantics, true, 180),
      mkFile(DenotationalSemantics, true, 160),
      mkFile(ConformanceTests, true, 380),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, true, 900),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 76,
      passingTests: 68,
      provedCount: 18,
      admittedCount: 5,
      conformancePassing: true,
    },
    taxonomyCompleteness: 88,
  },
  {
    name: "Coda",
    description: "Musical programming — rhythmic types and harmonic constraints",
    implLang: "Elixir",
    files: [
      mkFile(GrammarEbnf, true, 130),
      mkFile(SpecCoreScm, true, 100),
      mkFile(TypingRules, false, 0),
      mkFile(OperationalSemantics, false, 0),
      mkFile(DenotationalSemantics, false, 0),
      mkFile(ConformanceTests, true, 150),
      mkFile(Benchmarks, false, 0),
      mkFile(ProofArtefacts, false, 0),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      ...emptyVerification,
      totalTests: 28,
      passingTests: 22,
      conformancePassing: false,
    },
    taxonomyCompleteness: 38,
  },
  {
    name: "Strata",
    description: "Stratified type system with universe polymorphism",
    implLang: "Idris2",
    files: [
      mkFile(GrammarEbnf, true, 260),
      mkFile(SpecCoreScm, true, 230),
      mkFile(TypingRules, true, 280),
      mkFile(OperationalSemantics, true, 160),
      mkFile(DenotationalSemantics, true, 140),
      mkFile(ConformanceTests, true, 490),
      mkFile(Benchmarks, true, 70),
      mkFile(ProofArtefacts, true, 1100),
    ],
    grammarContent: None,
    specContent: None,
    typingRulesContent: None,
    verification: {
      totalTests: 145,
      passingTests: 138,
      provedCount: 24,
      admittedCount: 3,
      hasFuzzing: true,
      conformancePassing: true,
    },
    taxonomyCompleteness: 100,
  },
]

/// Find a language entry by name.
let findLanguage = (name: string): option<specLanguageEntry> => {
  allLanguageSpecs->Array.find(l => l.name === name)
}

/// Get all language names for dropdowns.
let allLanguageNames: array<string> = allLanguageSpecs->Array.map(l => l.name)

/// Summary statistics across the entire portfolio.
let portfolioSummary = (): portfolioStats => {
  let total = Array.length(allLanguageSpecs)
  let sumCompleteness = allLanguageSpecs->Array.reduce(0, (acc, l) => acc + l.taxonomyCompleteness)
  let avgCompleteness = if total > 0 {
    sumCompleteness / total
  } else {
    0
  }
  let fullySpecified =
    allLanguageSpecs->Array.filter(l => l.taxonomyCompleteness >= 100)->Array.length
  let totalTests = allLanguageSpecs->Array.reduce(0, (acc, l) => acc + l.verification.totalTests)
  let totalAdmitted =
    allLanguageSpecs->Array.reduce(0, (acc, l) => acc + l.verification.admittedCount)
  {totalLanguages: total, avgCompleteness, fullySpecified, totalTests, totalAdmitted}
}
