// SPDX-License-Identifier: MPL-2.0

/// PanLL Language Forge Engine — pure computation for the nextgen-languages panel.
///
/// All functions are pure (no side effects, no API calls). Provides filtering,
/// sorting, labelling, and the hardcoded language assessment data for all 14
/// nextgen-languages projects.

open LanguageForgeModel

/// Human-readable label for a development phase.
let phaseLabel = (phase: languagePhase): string => {
  switch phase {
  | Production => "Production"
  | NearProduction => "Near-Production"
  | Alpha => "Alpha"
  | DesignOnly => "Design Only"
  | Concept => "Concept"
  | Vaporware => "Vaporware"
  }
}

/// CSS colour class for a development phase.
let phaseColor = (phase: languagePhase): string => {
  switch phase {
  | Production => "text-emerald-400"
  | NearProduction => "text-green-400"
  | Alpha => "text-amber-400"
  | DesignOnly => "text-orange-400"
  | Concept => "text-red-400"
  | Vaporware => "text-gray-500"
  }
}

/// Background badge colour for a development phase.
let phaseBadgeClass = (phase: languagePhase): string => {
  switch phase {
  | Production => "bg-emerald-900/50 text-emerald-300 border-emerald-700"
  | NearProduction => "bg-green-900/50 text-green-300 border-green-700"
  | Alpha => "bg-amber-900/50 text-amber-300 border-amber-700"
  | DesignOnly => "bg-orange-900/50 text-orange-300 border-orange-700"
  | Concept => "bg-red-900/50 text-red-300 border-red-700"
  | Vaporware => "bg-gray-800/50 text-gray-400 border-gray-700"
  }
}

/// Human-readable label for a filter category tab.
let categoryLabel = (cat: forgeCategory): string => {
  switch cat {
  | AllLanguages => "All Languages"
  | ProductionReady => "Production Ready"
  | InProgress => "In Progress"
  | NeedsWork => "Needs Work"
  }
}

/// All category tabs in display order.
let allCategories: array<forgeCategory> = [AllLanguages, ProductionReady, InProgress, NeedsWork]

/// Human-readable label for a sort criterion.
let sortLabel = (s: forgeSortBy): string => {
  switch s {
  | SortByName => "Name"
  | SortByScore => "Score"
  | SortByPhase => "Phase"
  }
}

/// Numeric rank for a phase (lower = more mature).
let phaseRank = (phase: languagePhase): int => {
  switch phase {
  | Production => 0
  | NearProduction => 1
  | Alpha => 2
  | DesignOnly => 3
  | Concept => 4
  | Vaporware => 5
  }
}

/// Filter languages by category and text search.
let filterLanguages = (
  languages: array<languageEntry>,
  category: forgeCategory,
  filterText: string,
): array<languageEntry> => {
  let byCat = switch category {
  | AllLanguages => languages
  | ProductionReady =>
    languages->Array.filter(l => l.phase === Production || l.phase === NearProduction)
  | InProgress => languages->Array.filter(l => l.phase === Alpha || l.phase === DesignOnly)
  | NeedsWork => languages->Array.filter(l => l.phase === Concept || l.phase === Vaporware)
  }
  if filterText === "" {
    byCat
  } else {
    let q = String.toLowerCase(filterText)
    byCat->Array.filter(l =>
      String.includes(String.toLowerCase(l.name), q) ||
      String.includes(String.toLowerCase(l.implLang), q)
    )
  }
}

/// Sort languages by the given criterion.
let sortLanguages = (languages: array<languageEntry>, sortBy: forgeSortBy): array<
  languageEntry,
> => {
  let sorted = Array.copy(languages)
  sorted->Array.sort((a, b) => {
    switch sortBy {
    | SortByName => String.compare(a.name, b.name)
    | SortByScore => Int.compare(b.score, a.score) // Descending
    | SortByPhase => Int.compare(phaseRank(a.phase), phaseRank(b.phase))
    }
  })
  sorted
}

/// Hardcoded portfolio data for all 14 nextgen-languages.
/// Based on the current assessment as of 2026-03.
let languageData = (): array<languageEntry> => [
  {
    name: "AffineScript",
    implLang: "OCaml",
    score: 95,
    phase: Production,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: true,
    hasWasmBackend: true,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 100, hasTests: true},
      {name: "Parser", completion: 100, hasTests: true},
      {name: "Type Checker", completion: 95, hasTests: true},
      {name: "WASM Backend", completion: 90, hasTests: true},
    ],
    todoCount: 5,
    locCount: 18000,
  },
  {
    name: "Error-Lang",
    implLang: "ReScript",
    score: 95,
    phase: Production,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: true,
    hasWasmBackend: false,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 100, hasTests: true},
      {name: "Parser", completion: 100, hasTests: true},
      {name: "Type Checker", completion: 95, hasTests: true},
      {name: "JS Backend", completion: 95, hasTests: true},
    ],
    todoCount: 3,
    locCount: 12000,
  },
  {
    name: "Phronesis",
    implLang: "Elixir",
    score: 95,
    phase: Production,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: true,
    hasWasmBackend: false,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 100, hasTests: true},
      {name: "Parser", completion: 100, hasTests: true},
      {name: "Type Checker", completion: 95, hasTests: true},
      {name: "BEAM Backend", completion: 95, hasTests: true},
    ],
    todoCount: 4,
    locCount: 15000,
  },
  {
    name: "WokeLang",
    implLang: "Rust",
    score: 90,
    phase: NearProduction,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: true,
    hasWasmBackend: true,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 100, hasTests: true},
      {name: "Parser", completion: 100, hasTests: true},
      {name: "Type Checker", completion: 90, hasTests: true},
      {name: "WASM Backend", completion: 85, hasTests: true},
    ],
    todoCount: 8,
    locCount: 14000,
  },
  {
    name: "Ephapax",
    implLang: "Rust",
    score: 85,
    phase: NearProduction,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: true,
    hasWasmBackend: false,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 100, hasTests: true},
      {name: "Parser", completion: 100, hasTests: true},
      {name: "Type Checker", completion: 85, hasTests: true},
      {name: "Native Backend", completion: 80, hasTests: true},
    ],
    todoCount: 12,
    locCount: 11000,
  },
  {
    name: "Oblibeny",
    implLang: "OCaml",
    score: 85,
    phase: NearProduction,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: true,
    hasWasmBackend: false,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 100, hasTests: true},
      {name: "Parser", completion: 100, hasTests: true},
      {name: "Type Checker", completion: 85, hasTests: true},
      {name: "Native Backend", completion: 80, hasTests: true},
    ],
    todoCount: 10,
    locCount: 13000,
  },
  {
    name: "Eclexia",
    implLang: "Rust",
    score: 70,
    phase: Alpha,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 90, hasTests: true},
      {name: "Parser", completion: 85, hasTests: true},
      {name: "Type Checker", completion: 50, hasTests: false},
      {name: "Runtime", completion: 45, hasTests: true},
    ],
    todoCount: 35,
    locCount: 8000,
  },
  {
    name: "BetLang",
    implLang: "Racket+Rust",
    score: 65,
    phase: Alpha,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 90, hasTests: true},
      {name: "Parser", completion: 80, hasTests: true},
      {name: "Type Checker", completion: 40, hasTests: false},
      {name: "Interpreter", completion: 60, hasTests: true},
    ],
    todoCount: 28,
    locCount: 6000,
  },
  {
    name: "My-Lang",
    implLang: "Rust",
    score: 65,
    phase: Alpha,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: true,
    components: [
      {name: "Lexer", completion: 90, hasTests: true},
      {name: "Parser", completion: 85, hasTests: true},
      {name: "Type Checker", completion: 35, hasTests: false},
      {name: "REPL", completion: 70, hasTests: true},
    ],
    todoCount: 30,
    locCount: 7500,
  },
  {
    name: "Tangle",
    implLang: "OCaml",
    score: 40,
    phase: DesignOnly,
    lexerComplete: true,
    parserComplete: true,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: false,
    components: [
      {name: "Lexer", completion: 70, hasTests: false},
      {name: "Parser", completion: 60, hasTests: false},
      {name: "Design Spec", completion: 80, hasTests: false},
    ],
    todoCount: 45,
    locCount: 3000,
  },
  {
    name: "Me-Dialect",
    implLang: "ReScript",
    score: 15,
    phase: Concept,
    lexerComplete: false,
    parserComplete: false,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: false,
    components: [
      {name: "Spec", completion: 30, hasTests: false},
      {name: "Prototype", completion: 10, hasTests: false},
    ],
    todoCount: 60,
    locCount: 500,
  },
  {
    name: "7-Tentacles",
    implLang: "",
    score: 5,
    phase: Concept,
    lexerComplete: false,
    parserComplete: false,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: false,
    components: [
      {name: "Agent Architecture", completion: 10, hasTests: false},
      {name: "OODA Framework", completion: 5, hasTests: false},
    ],
    todoCount: 80,
    locCount: 200,
  },
  {
    name: "Anvomidav",
    implLang: "",
    score: 0,
    phase: Vaporware,
    lexerComplete: false,
    parserComplete: false,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: false,
    components: [],
    todoCount: 0,
    locCount: 0,
  },
  {
    name: "Julia-Viper",
    implLang: "",
    score: 0,
    phase: Vaporware,
    lexerComplete: false,
    parserComplete: false,
    typeCheckerComplete: false,
    hasWasmBackend: false,
    hasTests: false,
    components: [],
    todoCount: 0,
    locCount: 0,
  },
]

/// Default state with language data pre-loaded.
let defaultState: languageForgeState = {
  loaded: true,
  loading: false,
  error: None,
  languages: languageData(),
  activeCategory: AllLanguages,
  selectedLanguage: None,
  filterText: "",
  sortBy: SortByScore,
  showMoscow: false,
}
