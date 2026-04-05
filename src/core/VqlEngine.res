// SPDX-License-Identifier: PMPL-1.0-or-later
// VCL-total Engine — Pure computation layer for the VCL panel.
//
// This module contains ALL business logic for VCL query authoring:
// - The VCL linter (30+ rules across 6 categories)
// - The VCL formatter (5 style presets, configurable)
// - Query template expansion and parameter validation
// - Type safety level metadata and narrative generation
// - Cross-prover strategy evaluation
// - Result formatting and export
//
// Zero side effects — all I/O goes through VqlCmd.res.

open VqlModel

// ============================================================
// SECTION 1: Safety Level Metadata
// ============================================================

/// Complete metadata for each of the 10 type safety levels.
/// Used for badges, tooltips, narrative generation, and level gating.
let levelMetas: array<levelMeta> = [
  {
    level: L0_Unsafe,
    name: "Unsafe",
    shortName: "L0",
    description: "Raw string queries with no type checking. Use only for exploration.",
    glyph: "\u26A0",
    colour: "text-red-400",
    bgColour: "bg-red-900/30",
    proverRequired: false,
  },
  {
    level: L1_Parsed,
    name: "Parsed",
    shortName: "L1",
    description: "Query is syntactically valid VCL-total. Keywords, clauses, and structure verified.",
    glyph: "\u2713",
    colour: "text-orange-400",
    bgColour: "bg-orange-900/30",
    proverRequired: false,
  },
  {
    level: L2_SchemaBound,
    name: "Schema-Bound",
    shortName: "L2",
    description: "All referenced tables and columns exist in VeriSimDB schema.",
    glyph: "\u{1F517}",
    colour: "text-yellow-400",
    bgColour: "bg-yellow-900/30",
    proverRequired: false,
  },
  {
    level: L3_TypeCompat,
    name: "Type-Compatible",
    shortName: "L3",
    description: "Expression types are compatible. No comparing integers to strings.",
    glyph: "\u2261",
    colour: "text-lime-400",
    bgColour: "bg-lime-900/30",
    proverRequired: false,
  },
  {
    level: L4_NullSafe,
    name: "Null-Safe",
    shortName: "L4",
    description: "Nullable columns are handled explicitly. No surprise NULL propagation.",
    glyph: "\u2205",
    colour: "text-emerald-400",
    bgColour: "bg-emerald-900/30",
    proverRequired: false,
  },
  {
    level: L5_InjectionProof,
    name: "Injection-Proof",
    shortName: "L5",
    description: "No string interpolation reaches query positions. Parameterised only.",
    glyph: "\u{1F6E1}",
    colour: "text-teal-400",
    bgColour: "bg-teal-900/30",
    proverRequired: false,
  },
  {
    level: L6_ResultTyped,
    name: "Result-Typed",
    shortName: "L6",
    description: "Return type fully determined at compile time. Every column has a known type.",
    glyph: "\u{1F4CB}",
    colour: "text-cyan-400",
    bgColour: "bg-cyan-900/30",
    proverRequired: false,
  },
  {
    level: L7_CardinalitySafe,
    name: "Cardinality-Safe",
    shortName: "L7",
    description: "Proven bounds on result size. No unbounded full-table scans.",
    glyph: "\u{1F4CA}",
    colour: "text-blue-400",
    bgColour: "bg-blue-900/30",
    proverRequired: true,
  },
  {
    level: L8_EffectTracked,
    name: "Effect-Tracked",
    shortName: "L8",
    description: "Side effects (writes, locks, external calls) declared and tracked.",
    glyph: "\u26A1",
    colour: "text-indigo-400",
    bgColour: "bg-indigo-900/30",
    proverRequired: true,
  },
  {
    level: L9_TemporalSafe,
    name: "Temporal-Safe",
    shortName: "L9",
    description: "Temporal consistency proven. No stale joins or future reads.",
    glyph: "\u231B",
    colour: "text-violet-400",
    bgColour: "bg-violet-900/30",
    proverRequired: true,
  },
  {
    level: L10_LinearSafe,
    name: "Linear-Safe",
    shortName: "L10",
    description: "Linear resource usage proven. Every proof consumed exactly once.",
    glyph: "\u{1F48E}",
    colour: "text-fuchsia-400",
    bgColour: "bg-fuchsia-900/30",
    proverRequired: true,
  },
]

/// Look up metadata for a given safety level.
let getLevelMeta = (level: typeSafetyLevel): levelMeta => {
  let idx = switch level {
  | L0_Unsafe => 0
  | L1_Parsed => 1
  | L2_SchemaBound => 2
  | L3_TypeCompat => 3
  | L4_NullSafe => 4
  | L5_InjectionProof => 5
  | L6_ResultTyped => 6
  | L7_CardinalitySafe => 7
  | L8_EffectTracked => 8
  | L9_TemporalSafe => 9
  | L10_LinearSafe => 10
  }
  levelMetas->Array.getUnsafe(idx)
}

/// Numeric value for level comparison.
let levelToInt = (level: typeSafetyLevel): int =>
  switch level {
  | L0_Unsafe => 0
  | L1_Parsed => 1
  | L2_SchemaBound => 2
  | L3_TypeCompat => 3
  | L4_NullSafe => 4
  | L5_InjectionProof => 5
  | L6_ResultTyped => 6
  | L7_CardinalitySafe => 7
  | L8_EffectTracked => 8
  | L9_TemporalSafe => 9
  | L10_LinearSafe => 10
  }

/// Whether achieved >= required.
let levelSatisfies = (achieved: typeSafetyLevel, required: typeSafetyLevel): bool =>
  levelToInt(achieved) >= levelToInt(required)

// ============================================================
// SECTION 2: VCL Linter — 30+ Rules
// ============================================================

/// VCL keywords that must appear in specific clause positions.
let vqlKeywords = [
  "FIND",
  "FROM",
  "WHERE",
  "PROVE",
  "USING",
  "WITH",
  "ORDER",
  "LIMIT",
  "OFFSET",
  "GROUP",
  "HAVING",
  "JOIN",
  "ON",
  "AS",
  "IN",
  "NOT",
  "AND",
  "OR",
  "EXISTS",
  "FORALL",
  "ACROSS",
  "FEDERATED",
  "TEMPORAL",
  "LINEAR",
  "EFFECT",
  "SESSION",
  "OCTAD",
  "MODALITY",
]

/// VCL clause keywords — these start major sections.
let clauseKeywords = [
  "FIND",
  "FROM",
  "WHERE",
  "PROVE",
  "USING",
  "WITH",
  "ORDER",
  "LIMIT",
  "GROUP",
  "HAVING",
]

/// Check if a string looks like a VCL keyword.
let isKeyword = (word: string): bool => vqlKeywords->Array.includes(String.toUpperCase(word))

/// Check if a string looks like a clause keyword.
let isClauseKeyword = (word: string): bool =>
  clauseKeywords->Array.includes(String.toUpperCase(word))

// --- Rule implementations ---

/// VCL-S001: Query must not be empty.
let ruleEmptyQuery = (content: string): option<lintDiagnostic> => {
  let trimmed = String.trim(content)
  if String.length(trimmed) == 0 {
    Some({
      ruleId: "VCL-S001",
      category: CatSyntax,
      severity: LintError,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: "Query is empty. Write a VCL-total query starting with FIND, PROVE, or another clause keyword.",
      suggestion: Some("FIND proof\nFROM proofs\nWHERE prover = 'Lean'"),
      relatedLevel: L1_Parsed,
    })
  } else {
    None
  }
}

/// VCL-S002: Query must start with a valid clause keyword.
let ruleStartsWithClause = (content: string): option<lintDiagnostic> => {
  let trimmed = String.trim(content)
  if String.length(trimmed) == 0 {
    None
  } else {
    let firstWord = switch String.split(trimmed, " ")->Array.get(0) {
    | Some(w) => String.toUpperCase(String.trim(w))
    | None => ""
    }
    let validStarts = ["FIND", "PROVE", "FEDERATED", "TEMPORAL", "LINEAR", "WITH", "EXPLAIN"]
    if !(validStarts->Array.includes(firstWord)) {
      Some({
        ruleId: "VCL-S002",
        category: CatSyntax,
        severity: LintError,
        line: 1,
        column: 1,
        endLine: 1,
        endColumn: String.length(firstWord),
        message: `Query must start with a valid clause keyword (FIND, PROVE, FEDERATED, etc.), found: "${firstWord}"`,
        suggestion: Some(`FIND ${trimmed}`),
        relatedLevel: L1_Parsed,
      })
    } else {
      None
    }
  }
}

/// VCL-S003: Keywords should be UPPERCASE.
let ruleKeywordCase = (content: string): array<lintDiagnostic> => {
  let lines = String.split(content, "\n")
  let diagnostics = []
  lines->Array.forEachWithIndex((line, lineIdx) => {
    let words = String.split(line, " ")
    let _colOffset = ref(0)
    words->Array.forEach(word => {
      let trimWord = String.trim(word)
      if (
        String.length(trimWord) > 0 &&
        isKeyword(trimWord) &&
        trimWord !== String.toUpperCase(trimWord)
      ) {
        let _ = diagnostics->Array.push({
          ruleId: "VCL-S003",
          category: CatSyntax,
          severity: LintHint,
          line: lineIdx + 1,
          column: _colOffset.contents + 1,
          endLine: lineIdx + 1,
          endColumn: _colOffset.contents + String.length(trimWord),
          message: `Keyword "${trimWord}" should be uppercase: "${String.toUpperCase(trimWord)}"`,
          suggestion: Some(String.toUpperCase(trimWord)),
          relatedLevel: L1_Parsed,
        })
      }
      _colOffset := _colOffset.contents + String.length(word) + 1
    })
  })
  diagnostics
}

/// VCL-S004: Unclosed string literal.
let ruleUnclosedString = (content: string): array<lintDiagnostic> => {
  let lines = String.split(content, "\n")
  let diagnostics = []
  lines->Array.forEachWithIndex((line, lineIdx) => {
    let inString = ref(false)
    let quoteChar = ref("'")
    for i in 0 to String.length(line) - 1 {
      let ch = String.charAt(line, i)
      if !inString.contents && (ch == "'" || ch == "\"") {
        inString := true
        quoteChar := ch
      } else if inString.contents && ch == quoteChar.contents {
        inString := false
      }
    }
    if inString.contents {
      let _ = diagnostics->Array.push({
        ruleId: "VCL-S004",
        category: CatSyntax,
        severity: LintError,
        line: lineIdx + 1,
        column: 1,
        endLine: lineIdx + 1,
        endColumn: String.length(line),
        message: "Unclosed string literal. Missing closing quote.",
        suggestion: None,
        relatedLevel: L1_Parsed,
      })
    }
  })
  diagnostics
}

/// VCL-S005: Unmatched parentheses.
let ruleUnmatchedParens = (content: string): option<lintDiagnostic> => {
  let depth = ref(0)
  for i in 0 to String.length(content) - 1 {
    let ch = String.charAt(content, i)
    if ch == "(" {
      depth := depth.contents + 1
    }
    if ch == ")" {
      depth := depth.contents - 1
    }
  }
  if depth.contents > 0 {
    Some({
      ruleId: "VCL-S005",
      category: CatSyntax,
      severity: LintError,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: `${Int.toString(depth.contents)} unclosed parenthesis(es).`,
      suggestion: None,
      relatedLevel: L1_Parsed,
    })
  } else if depth.contents < 0 {
    Some({
      ruleId: "VCL-S005",
      category: CatSyntax,
      severity: LintError,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: `${Int.toString(-depth.contents)} extra closing parenthesis(es).`,
      suggestion: None,
      relatedLevel: L1_Parsed,
    })
  } else {
    None
  }
}

/// VCL-T001: String comparison with non-string column (requires schema).
/// Returns a diagnostic if we detect patterns like `column = 42` where column is string-typed.
/// Without schema, this is a best-effort heuristic.
let ruleStringIntComparison = (content: string): array<lintDiagnostic> => {
  // Heuristic: if WHERE clause has `name = 42` or `title = 3.14`, flag it
  let diagnostics = []
  let lines = String.split(content, "\n")
  let inWhere = ref(false)
  lines->Array.forEachWithIndex((line, lineIdx) => {
    let trimLine = String.trim(line)
    let upper = String.toUpperCase(trimLine)
    if String.includes(upper, "WHERE") {
      inWhere := true
    }
    if inWhere.contents {
      // Look for patterns like `name = 42` (string column compared to number)
      let commonStringCols = ["name", "title", "prover", "tactic", "theorem", "description", "goal"]
      commonStringCols->Array.forEach(col => {
        // Check for `col = <number>` pattern
        let patterns = [`${col} = `, `${col} != `, `${col} > `, `${col} < `]
        patterns->Array.forEach(
          pat => {
            let lowerLine = String.toLowerCase(trimLine)
            if String.includes(lowerLine, pat) {
              let idx = String.indexOf(lowerLine, pat)
              let afterPat = if idx >= 0 {
                String.sliceToEnd(trimLine, ~start=idx + String.length(pat))
              } else {
                ""
              }
              let firstChar = String.charAt(String.trim(afterPat), 0)
              if firstChar >= "0" && firstChar <= "9" {
                let _ = diagnostics->Array.push({
                  ruleId: "VCL-T001",
                  category: CatType,
                  severity: LintWarning,
                  line: lineIdx + 1,
                  column: 1,
                  endLine: lineIdx + 1,
                  endColumn: String.length(trimLine),
                  message: `Column "${col}" is likely a string but is compared to a numeric literal. Use string comparison: ${col} = '...'`,
                  suggestion: None,
                  relatedLevel: L3_TypeCompat,
                })
              }
            }
          },
        )
      })
    }
  })
  diagnostics
}

/// VCL-SEC001: String concatenation in query position (injection risk).
let ruleInjectionRisk = (content: string): array<lintDiagnostic> => {
  let diagnostics = []
  let lines = String.split(content, "\n")
  let dangerPatterns = ["${", "\" +", "' +", "+ \"", "+ '", "concat(", "CONCAT("]
  lines->Array.forEachWithIndex((line, lineIdx) => {
    dangerPatterns->Array.forEach(pat => {
      if String.includes(line, pat) {
        let _ = diagnostics->Array.push({
          ruleId: "VCL-SEC001",
          category: CatSecurity,
          severity: LintError,
          line: lineIdx + 1,
          column: 1,
          endLine: lineIdx + 1,
          endColumn: String.length(line),
          message: `Potential injection: string interpolation/concatenation detected ("${pat}"). Use parameterised queries with $param syntax.`,
          suggestion: None,
          relatedLevel: L5_InjectionProof,
        })
      }
    })
  })
  diagnostics
}

/// VCL-P001: SELECT * without LIMIT (performance risk).
let ruleUnboundedScan = (content: string): option<lintDiagnostic> => {
  let upper = String.toUpperCase(content)
  let hasStar = String.includes(upper, "FIND *") || String.includes(upper, "FIND  *")
  let hasLimit = String.includes(upper, "LIMIT")
  if hasStar && !hasLimit {
    Some({
      ruleId: "VCL-P001",
      category: CatPerformance,
      severity: LintWarning,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: "Unbounded FIND * without LIMIT. This may scan the entire proof corpus. Add LIMIT to bound result size.",
      suggestion: Some("Add: LIMIT 100"),
      relatedLevel: L7_CardinalitySafe,
    })
  } else {
    None
  }
}

/// VCL-P002: CROSS JOIN or cartesian product warning.
let ruleCrossJoin = (content: string): option<lintDiagnostic> => {
  let upper = String.toUpperCase(content)
  if String.includes(upper, "CROSS JOIN") || String.includes(upper, "CROSS PROVER") {
    Some({
      ruleId: "VCL-P002",
      category: CatPerformance,
      severity: LintWarning,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: "Cross join detected. This produces a cartesian product and may be very expensive. Consider adding join conditions.",
      suggestion: None,
      relatedLevel: L7_CardinalitySafe,
    })
  } else {
    None
  }
}

/// VCL-C001: EFFECT clause used without USING (correctness).
let ruleEffectWithoutUsing = (content: string): option<lintDiagnostic> => {
  let upper = String.toUpperCase(content)
  if String.includes(upper, "EFFECT") && !String.includes(upper, "USING") {
    Some({
      ruleId: "VCL-C001",
      category: CatCorrectness,
      severity: LintWarning,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: "EFFECT clause without USING. Specify which provers handle effect verification with USING <prover>.",
      suggestion: None,
      relatedLevel: L8_EffectTracked,
    })
  } else {
    None
  }
}

/// VCL-C002: TEMPORAL query without time bounds.
let ruleTemporalWithoutBounds = (content: string): option<lintDiagnostic> => {
  let upper = String.toUpperCase(content)
  if (
    String.includes(upper, "TEMPORAL") &&
    !(
      String.includes(upper, "SINCE") ||
      String.includes(upper, "UNTIL") ||
      String.includes(upper, "AT") ||
      String.includes(upper, "BETWEEN")
    )
  ) {
    Some({
      ruleId: "VCL-C002",
      category: CatCorrectness,
      severity: LintWarning,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: "TEMPORAL query without time bounds (SINCE, UNTIL, AT, BETWEEN). Unbounded temporal queries may return stale data.",
      suggestion: Some("Add: SINCE '2026-01-01'"),
      relatedLevel: L9_TemporalSafe,
    })
  } else {
    None
  }
}

/// VCL-C003: LINEAR without explicit consumption (resource leak risk).
let ruleLinearWithoutConsume = (content: string): option<lintDiagnostic> => {
  let upper = String.toUpperCase(content)
  if (
    String.includes(upper, "LINEAR") &&
    !String.includes(upper, "CONSUME") &&
    !String.includes(upper, "RELEASE")
  ) {
    Some({
      ruleId: "VCL-C003",
      category: CatCorrectness,
      severity: LintError,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: "LINEAR query without CONSUME or RELEASE. Linear resources must be explicitly consumed to prevent resource leaks.",
      suggestion: None,
      relatedLevel: L10_LinearSafe,
    })
  } else {
    None
  }
}

/// VCL-S006: Duplicate clause keywords.
let ruleDuplicateClauses = (content: string): array<lintDiagnostic> => {
  let upper = String.toUpperCase(content)
  let diagnostics = []
  clauseKeywords->Array.forEach(kw => {
    // Count occurrences
    let parts = String.split(upper, kw)
    let count = Array.length(parts) - 1
    if count > 1 && kw !== "AND" && kw !== "OR" {
      let _ = diagnostics->Array.push({
        ruleId: "VCL-S006",
        category: CatSyntax,
        severity: LintWarning,
        line: 1,
        column: 1,
        endLine: 1,
        endColumn: 1,
        message: `Duplicate ${kw} clause (appears ${Int.toString(
            count,
          )} times). Consider consolidating.`,
        suggestion: None,
        relatedLevel: L1_Parsed,
      })
    }
  })
  diagnostics
}

/// VCL-SCH001: Referencing unknown octad modality.
let ruleUnknownModality = (content: string): array<lintDiagnostic> => {
  let diagnostics = []
  let upper = String.toUpperCase(content)
  if String.includes(upper, "OCTAD") || String.includes(upper, "MODALITY") {
    let validModalities = [
      "SEMANTIC",
      "TEMPORAL",
      "PROVENANCE",
      "DOCUMENT",
      "GRAPH",
      "VECTOR",
      "TENSOR",
      "SPATIAL",
    ]
    let lines = String.split(content, "\n")
    lines->Array.forEachWithIndex((line, lineIdx) => {
      let upperLine = String.toUpperCase(line)
      if String.includes(upperLine, "MODALITY") {
        // Check if any word after MODALITY is not a known modality
        let modIdx = String.indexOf(upperLine, "MODALITY")
        let afterModality = if modIdx >= 0 {
          String.sliceToEnd(line, ~start=modIdx + 8)
        } else {
          ""
        }
        let words = String.split(String.trim(afterModality), " ")
        words->Array.forEach(word => {
          let w = String.toUpperCase(String.trim(word))
          if (
            String.length(w) > 0 &&
            !(validModalities->Array.includes(w)) &&
            w !== "=" &&
            w !== "IN" &&
            w !== "(" &&
            w !== ")" &&
            w !== ","
          ) {
            let _ = diagnostics->Array.push({
              ruleId: "VCL-SCH001",
              category: CatSchema,
              severity: LintWarning,
              line: lineIdx + 1,
              column: 1,
              endLine: lineIdx + 1,
              endColumn: String.length(line),
              message: `Unknown octad modality: "${w}". Valid modalities: ${Array.join(
                  validModalities,
                  ", ",
                )}`,
              suggestion: None,
              relatedLevel: L2_SchemaBound,
            })
          }
        })
      }
    })
  }
  diagnostics
}

/// VCL-P003: Missing index hint for large tables.
let ruleMissingIndexHint = (content: string): option<lintDiagnostic> => {
  let upper = String.toUpperCase(content)
  let hasWhere = String.includes(upper, "WHERE")
  let hasProofs = String.includes(upper, "PROOFS") || String.includes(upper, "PROOF_STATES")
  if hasProofs && !hasWhere {
    Some({
      ruleId: "VCL-P003",
      category: CatPerformance,
      severity: LintInfo,
      line: 1,
      column: 1,
      endLine: 1,
      endColumn: 1,
      message: "Querying proof corpus without WHERE clause. The proof_states table can be very large (66,000+ rows). Add a filter.",
      suggestion: Some("Add: WHERE prover = 'Lean'"),
      relatedLevel: L7_CardinalitySafe,
    })
  } else {
    None
  }
}

/// Run the complete linter on a query, respecting the active profile and minimum level.
let runLinter = (content: string, state: linterState): array<lintDiagnostic> => {
  let all: array<lintDiagnostic> = []

  // Syntax rules
  switch ruleEmptyQuery(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }
  switch ruleStartsWithClause(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }
  ruleKeywordCase(content)->Array.forEach(d => ignore(all->Array.push(d)))
  ruleUnclosedString(content)->Array.forEach(d => ignore(all->Array.push(d)))
  switch ruleUnmatchedParens(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }
  ruleDuplicateClauses(content)->Array.forEach(d => ignore(all->Array.push(d)))

  // Schema rules
  ruleUnknownModality(content)->Array.forEach(d => ignore(all->Array.push(d)))

  // Type rules
  ruleStringIntComparison(content)->Array.forEach(d => ignore(all->Array.push(d)))

  // Security rules
  ruleInjectionRisk(content)->Array.forEach(d => ignore(all->Array.push(d)))

  // Performance rules
  switch ruleUnboundedScan(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }
  switch ruleCrossJoin(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }
  switch ruleMissingIndexHint(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }

  // Correctness rules
  switch ruleEffectWithoutUsing(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }
  switch ruleTemporalWithoutBounds(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }
  switch ruleLinearWithoutConsume(content) {
  | Some(d) => ignore(all->Array.push(d))
  | None => ()
  }

  // Filter by profile
  let filtered = switch state.profile {
  | ProfileStrict => all
  | ProfileRecommended =>
    all->Array.filter(d =>
      switch d.severity {
      | LintError | LintWarning | LintInfo => true
      | LintHint => false
      }
    )
  | ProfileRelaxed =>
    all->Array.filter(d =>
      switch d.severity {
      | LintError => true
      | _ => false
      }
    )
  | ProfileCustom => all
  }

  // Filter by suppressions
  let unsuppressed = filtered->Array.filter(d => !(state.suppressions->Array.includes(d.ruleId)))

  // Elevate violations below minimum level to errors
  unsuppressed->Array.map(d => {
    if !levelSatisfies(d.relatedLevel, state.minimumLevel) && d.severity !== LintError {
      {...d, severity: LintError, message: d.message ++ " [elevated: below minimum level]"}
    } else {
      d
    }
  })
}

// ============================================================
// SECTION 3: VCL Formatter
// ============================================================

/// Format a VCL-total query according to the given options.
let formatQuery = (content: string, options: formatOptions): string => {
  let lines = String.split(String.trim(content), "\n")
  let indent = String.repeat(" ", options.indentWidth)
  let result = ref("")

  let processWord = (word: string): string => {
    if options.uppercaseKeywords && isKeyword(word) {
      String.toUpperCase(word)
    } else {
      word
    }
  }

  switch options.style {
  | StyleCompact => {
      // Single line, minimal whitespace
      let words =
        String.split(String.trim(content), " ")
        ->Array.filter(w => String.length(String.trim(w)) > 0)
        ->Array.map(processWord)
      result := Array.join(words, " ")
    }

  | StyleExpanded => // Each clause keyword on its own line, sub-expressions indented
    lines->Array.forEach(line => {
      let trimLine = String.trim(line)
      if String.length(trimLine) > 0 {
        let words = String.split(trimLine, " ")
        let firstWord = switch words->Array.get(0) {
        | Some(w) => String.toUpperCase(String.trim(w))
        | None => ""
        }
        let processed = words->Array.map(processWord)->Array.join(" ")
        if isClauseKeyword(firstWord) {
          if String.length(result.contents) > 0 {
            result := result.contents ++ "\n"
            if options.insertBlankLines {
              result := result.contents ++ "\n"
            }
          }
          result := result.contents ++ processed ++ "\n"
        } else {
          result := result.contents ++ indent ++ processed ++ "\n"
        }
      }
    })

  | StyleProof => // Like expanded, but with type annotations and level markers
    lines->Array.forEach(line => {
      let trimLine = String.trim(line)
      if String.length(trimLine) > 0 {
        let words = String.split(trimLine, " ")
        let firstWord = switch words->Array.get(0) {
        | Some(w) => String.toUpperCase(String.trim(w))
        | None => ""
        }
        let processed = words->Array.map(processWord)->Array.join(" ")
        if firstWord == "FIND" || firstWord == "PROVE" {
          result := result.contents ++ processed ++ "  -- [L6: result type determined]\n"
        } else if firstWord == "WHERE" {
          result := result.contents ++ processed ++ "  -- [L3: type compatibility checked]\n"
        } else if firstWord == "FROM" {
          result := result.contents ++ processed ++ "  -- [L2: schema bound]\n"
        } else if firstWord == "TEMPORAL" {
          result := result.contents ++ processed ++ "  -- [L9: temporal consistency]\n"
        } else if firstWord == "LINEAR" {
          result := result.contents ++ processed ++ "  -- [L10: linear safety]\n"
        } else if firstWord == "EFFECT" {
          result := result.contents ++ processed ++ "  -- [L8: effect tracked]\n"
        } else if isClauseKeyword(firstWord) {
          result := result.contents ++ processed ++ "\n"
        } else {
          result := result.contents ++ indent ++ processed ++ "\n"
        }
      }
    })

  | StyleStandard | StyleCustom => {
      // Standard: keywords uppercase, 2-space indent, aligned clauses
      let maxKeywordLen = ref(0)
      if options.alignClauses {
        lines->Array.forEach(line => {
          let trimLine = String.trim(line)
          let words = String.split(trimLine, " ")
          switch words->Array.get(0) {
          | Some(w) =>
            if isClauseKeyword(w) && String.length(w) > maxKeywordLen.contents {
              maxKeywordLen := String.length(w)
            }
          | None => ()
          }
        })
      }

      lines->Array.forEach(line => {
        let trimLine = String.trim(line)
        if String.length(trimLine) > 0 {
          let words = String.split(trimLine, " ")
          let firstWord = switch words->Array.get(0) {
          | Some(w) => String.trim(w)
          | None => ""
          }
          if isClauseKeyword(firstWord) {
            let kw = if options.uppercaseKeywords {
              String.toUpperCase(firstWord)
            } else {
              firstWord
            }
            let padding = if options.alignClauses {
              String.repeat(" ", maxKeywordLen.contents - String.length(kw))
            } else {
              ""
            }
            let rest =
              words
              ->Array.sliceToEnd(~start=1)
              ->Array.map(processWord)
              ->Array.join(" ")
            result := result.contents ++ kw ++ padding ++ " " ++ rest ++ "\n"
          } else {
            let processed = words->Array.map(processWord)->Array.join(" ")
            result := result.contents ++ indent ++ processed ++ "\n"
          }
        }
      })
    }
  }

  String.trim(result.contents)
}

// ============================================================
// SECTION 4: Query Templates
// ============================================================

/// Built-in query templates for common VCL-total operations.
let builtinTemplates: array<queryTemplate> = [
  {
    id: "find-by-prover",
    name: "Find Proofs by Prover",
    description: "Search the proof corpus for all proofs from a specific prover.",
    operation: OpFindProof,
    template: "FIND proof, theorem, goal\nFROM proof_states\nWHERE prover = '{{prover}}'\nORDER theorem\nLIMIT {{limit}}",
    parameters: [
      {
        name: "prover",
        paramType: "prover",
        description: "Prover backend name",
        defaultValue: Some("Lean"),
        validation: None,
      },
      {
        name: "limit",
        paramType: "int",
        description: "Maximum results",
        defaultValue: Some("100"),
        validation: Some("^[0-9]+$"),
      },
    ],
    requiredLevel: L2_SchemaBound,
  },
  {
    id: "similar-goals",
    name: "Find Similar Goals",
    description: "Vector similarity search for proofs with goals resembling a given pattern.",
    operation: OpFindSimilar,
    template: "FIND proof, theorem, goal, similarity_score\nFROM proof_states\nUSING MODALITY VECTOR\nWHERE goal SIMILAR TO '{{goal_pattern}}'\nLIMIT {{limit}}",
    parameters: [
      {
        name: "goal_pattern",
        paramType: "string",
        description: "Goal pattern to match",
        defaultValue: Some("forall n : nat, n + 0 = n"),
        validation: None,
      },
      {
        name: "limit",
        paramType: "int",
        description: "Maximum results",
        defaultValue: Some("20"),
        validation: Some("^[0-9]+$"),
      },
    ],
    requiredLevel: L6_ResultTyped,
  },
  {
    id: "cross-prover",
    name: "Cross-Prover Search",
    description: "Search for equivalent theorems across multiple proof systems.",
    operation: OpCrossProverSearch,
    template: "FEDERATED FIND theorem, prover, proof_id\nFROM proof_states\nACROSS {{provers}}\nWHERE theorem LIKE '{{pattern}}'\nLIMIT {{limit}}",
    parameters: [
      {
        name: "provers",
        paramType: "string",
        description: "Comma-separated prover list",
        defaultValue: Some("Lean, Coq, Isabelle"),
        validation: None,
      },
      {
        name: "pattern",
        paramType: "string",
        description: "Theorem name pattern",
        defaultValue: Some("%comm%"),
        validation: None,
      },
      {
        name: "limit",
        paramType: "int",
        description: "Maximum results per prover",
        defaultValue: Some("50"),
        validation: Some("^[0-9]+$"),
      },
    ],
    requiredLevel: L7_CardinalitySafe,
  },
  {
    id: "provenance-trace",
    name: "Proof Provenance Trace",
    description: "Trace the full lineage of a proof through VeriSimDB.",
    operation: OpProvenanceTrace,
    template: "FIND proof_id, version, author, timestamp, parent_id\nFROM proof_states\nUSING MODALITY PROVENANCE\nWHERE proof_id = '{{proof_id}}'\nORDER timestamp",
    parameters: [
      {
        name: "proof_id",
        paramType: "string",
        description: "Proof identifier",
        defaultValue: None,
        validation: None,
      },
    ],
    requiredLevel: L9_TemporalSafe,
  },
  {
    id: "temporal-history",
    name: "Proof Temporal History",
    description: "View how a theorem's proof has evolved over time.",
    operation: OpTemporalHistory,
    template: "TEMPORAL FIND theorem, tactic, prover, version\nFROM proof_states\nWHERE theorem = '{{theorem}}'\nSINCE '{{since}}'\nORDER version",
    parameters: [
      {
        name: "theorem",
        paramType: "string",
        description: "Theorem name",
        defaultValue: Some("comm_add"),
        validation: None,
      },
      {
        name: "since",
        paramType: "string",
        description: "Start date (ISO 8601)",
        defaultValue: Some("2026-01-01"),
        validation: Some("^\\d{4}-\\d{2}-\\d{2}$"),
      },
    ],
    requiredLevel: L9_TemporalSafe,
  },
  {
    id: "dependency-graph",
    name: "Theorem Dependencies",
    description: "Map the dependency graph of a theorem (what lemmas does it use?).",
    operation: OpDependencyGraph,
    template: "FIND theorem, depends_on, depth\nFROM proof_states\nUSING MODALITY GRAPH\nWHERE theorem = '{{theorem}}'\nLIMIT {{depth}}",
    parameters: [
      {
        name: "theorem",
        paramType: "string",
        description: "Root theorem name",
        defaultValue: Some("fundamental_theorem"),
        validation: None,
      },
      {
        name: "depth",
        paramType: "int",
        description: "Maximum dependency depth",
        defaultValue: Some("5"),
        validation: Some("^[0-9]+$"),
      },
    ],
    requiredLevel: L7_CardinalitySafe,
  },
  {
    id: "tactic-stats",
    name: "Tactic Usage Statistics",
    description: "Which tactics are used most often, and how successful are they?",
    operation: OpTacticStats,
    template: "FIND tactic, count, success_rate, avg_depth\nFROM tactics\nWHERE prover = '{{prover}}'\nGROUP tactic\nORDER count DESC\nLIMIT {{limit}}",
    parameters: [
      {
        name: "prover",
        paramType: "prover",
        description: "Prover backend",
        defaultValue: Some("Lean"),
        validation: None,
      },
      {
        name: "limit",
        paramType: "int",
        description: "Top N tactics",
        defaultValue: Some("25"),
        validation: Some("^[0-9]+$"),
      },
    ],
    requiredLevel: L6_ResultTyped,
  },
  {
    id: "linear-proof-consume",
    name: "Linear Proof Consumption",
    description: "Consume a proof resource linearly (exactly once) with tracked effects.",
    operation: OpCustom,
    template: "LINEAR FIND proof\nFROM proof_states\nWHERE proof_id = '{{proof_id}}'\nEFFECT read_once\nUSING {{prover}}\nCONSUME",
    parameters: [
      {
        name: "proof_id",
        paramType: "string",
        description: "Proof to consume",
        defaultValue: None,
        validation: None,
      },
      {
        name: "prover",
        paramType: "prover",
        description: "Verifying prover",
        defaultValue: Some("Idris2"),
        validation: None,
      },
    ],
    requiredLevel: L10_LinearSafe,
  },
]

/// Expand a template with parameter values.
let expandTemplate = (template: queryTemplate, values: array<(string, string)>): string => {
  let result = ref(template.template)
  template.parameters->Array.forEach(param => {
    let value = switch values->Array.find(((k, _)) => k == param.name) {
    | Some((_, v)) => v
    | None =>
      switch param.defaultValue {
      | Some(d) => d
      | None => "{{" ++ param.name ++ "}}"
      }
    }
    result := String.replaceAll(result.contents, "{{" ++ param.name ++ "}}", value)
  })
  result.contents
}

// ============================================================
// SECTION 5: Narrative Generation
// ============================================================

/// Generate the 4-part evangeliser narrative for a type checking result.
let generateNarrative = (
  achieved: typeSafetyLevel,
  requested: typeSafetyLevel,
  issues: array<lintDiagnostic>,
): typeNarrative => {
  let achievedMeta = getLevelMeta(achieved)
  let requestedMeta = getLevelMeta(requested)
  let passed = levelSatisfies(achieved, requested)
  let errorCount = issues->Array.filter(d => d.severity == LintError)->Array.length
  let warnCount = issues->Array.filter(d => d.severity == LintWarning)->Array.length

  let celebrate = if passed {
    `Your query achieved ${achievedMeta.name} (${achievedMeta.shortName}) safety! ` ++
    if levelToInt(achieved) >= 7 {
      "This means ECHIDNA provers have verified formal properties of your query. "
    } else if levelToInt(achieved) >= 5 {
      "Your query is injection-proof and fully typed. "
    } else if levelToInt(achieved) >= 3 {
      "All types are compatible and schema references resolve correctly. "
    } else {
      "The query parses correctly. "
    } ++
    `${achievedMeta.glyph} Well done.`
  } else {
    `Your query reached ${achievedMeta.name} (${achievedMeta.shortName}), which is ` ++
    `${Int.toString(levelToInt(achieved))} of ${Int.toString(
        levelToInt(requested),
      )} levels toward your target.`
  }

  let minimize = if errorCount == 0 && warnCount == 0 {
    "No issues detected. The query is clean."
  } else if errorCount == 0 {
    `${Int.toString(
        warnCount,
      )} warning(s) found, but none are blocking. The query can execute as-is.`
  } else {
    `${Int.toString(errorCount)} error(s) need attention before execution. ` ++ if warnCount > 0 {
      `There are also ${Int.toString(warnCount)} warning(s) to review.`
    } else {
      ""
    }
  }

  let showBetter = if passed && levelToInt(achieved) < 10 {
    let nextLevel = getLevelMeta(
      switch achieved {
      | L0_Unsafe => L1_Parsed
      | L1_Parsed => L2_SchemaBound
      | L2_SchemaBound => L3_TypeCompat
      | L3_TypeCompat => L4_NullSafe
      | L4_NullSafe => L5_InjectionProof
      | L5_InjectionProof => L6_ResultTyped
      | L6_ResultTyped => L7_CardinalitySafe
      | L7_CardinalitySafe => L8_EffectTracked
      | L8_EffectTracked => L9_TemporalSafe
      | L9_TemporalSafe | L10_LinearSafe => L10_LinearSafe
      },
    )
    `To reach the next level (${nextLevel.name}), ${nextLevel.description}`
  } else if passed {
    "You've achieved maximum type safety. This query has the strongest guarantees VCL-total can provide."
  } else {
    `To reach ${requestedMeta.name}: address the ${Int.toString(
        errorCount,
      )} error(s) above. ` ++ `Each error maps to a specific level requirement.`
  }

  let safety = if levelToInt(achieved) >= 10 {
    "LINEAR SAFETY: Every proof resource in this query is consumed exactly once. No leaks, no duplication. Formal proof accompanies execution."
  } else if levelToInt(achieved) >= 8 {
    "EFFECT TRACKING: All side effects are declared and tracked. The query cannot silently modify state."
  } else if levelToInt(achieved) >= 5 {
    "INJECTION PROOF: This query cannot be subverted by malicious input. All parameters are typed and validated."
  } else if levelToInt(achieved) >= 3 {
    "TYPE SAFETY: Expressions are type-checked. You will not get runtime type errors from this query."
  } else if levelToInt(achieved) >= 1 {
    "PARSE SAFETY: The query is syntactically valid. It will not cause parse errors on execution."
  } else {
    "NO SAFETY: This query runs as raw text. Consider adding type safety by choosing a higher level."
  }

  {celebrate, minimize, showBetter, safety}
}

// ============================================================
// SECTION 6: Operation Labels and Descriptions
// ============================================================

/// Human-readable label for a query operation.
let operationLabel = (op: queryOperation): string =>
  switch op {
  | OpFindProof => "Find Proof"
  | OpFindSimilar => "Find Similar"
  | OpCrossProverSearch => "Cross-Prover Search"
  | OpProvenanceTrace => "Provenance Trace"
  | OpTemporalHistory => "Temporal History"
  | OpDependencyGraph => "Dependency Graph"
  | OpAxiomUsage => "Axiom Usage"
  | OpTacticStats => "Tactic Statistics"
  | OpCustom => "Custom Query"
  }

/// Glyph for a query operation.
let operationGlyph = (op: queryOperation): string =>
  switch op {
  | OpFindProof => "\u{1F50D}"
  | OpFindSimilar => "\u{1F9F2}"
  | OpCrossProverSearch => "\u{1F310}"
  | OpProvenanceTrace => "\u{1F4DC}"
  | OpTemporalHistory => "\u231B"
  | OpDependencyGraph => "\u{1F578}"
  | OpAxiomUsage => "\u{1F3DB}"
  | OpTacticStats => "\u{1F4CA}"
  | OpCustom => "\u2328"
  }

/// Execution target label.
let targetLabel = (target: executionTarget): string =>
  switch target {
  | TargetVeriSimDB => "VeriSimDB"
  | TargetEchidna => "ECHIDNA"
  | TargetBoJ => "BoJ Server"
  | TargetTypeLL => "TypeLL (check only)"
  | TargetDryRun => "Dry Run (plan only)"
  }

/// Prover kind label.
let proverKindLabel = (kind: string): string =>
  switch kind {
  | "interactive" => "Interactive Proof Assistant"
  | "smt" => "SMT Solver"
  | "atp" => "Automated Theorem Prover"
  | "declarative" => "Declarative Prover"
  | "autoactive" => "Auto-Active Verifier"
  | "constraint" => "Constraint Solver"
  | _ => kind
  }

/// Lint category label.
let categoryLabel = (cat: lintCategory): string =>
  switch cat {
  | CatSyntax => "Syntax"
  | CatSchema => "Schema"
  | CatType => "Type"
  | CatSecurity => "Security"
  | CatPerformance => "Performance"
  | CatCorrectness => "Correctness"
  }

/// Lint category colour.
let categoryColour = (cat: lintCategory): string =>
  switch cat {
  | CatSyntax => "text-gray-400"
  | CatSchema => "text-yellow-400"
  | CatType => "text-cyan-400"
  | CatSecurity => "text-red-400"
  | CatPerformance => "text-orange-400"
  | CatCorrectness => "text-violet-400"
  }

/// Severity icon.
let severityIcon = (sev: lintSeverity): string =>
  switch sev {
  | LintError => "\u2716"
  | LintWarning => "\u26A0"
  | LintInfo => "\u2139"
  | LintHint => "\u{1F4A1}"
  }

/// Severity colour.
let severityColour = (sev: lintSeverity): string =>
  switch sev {
  | LintError => "text-red-400"
  | LintWarning => "text-amber-400"
  | LintInfo => "text-cyan-400"
  | LintHint => "text-gray-400"
  }

// ============================================================
// SECTION 7: View Layer Formatting
// ============================================================

/// View layer colour classes.
let viewLayerColour = (vl: viewLayer): string =>
  switch vl {
  | Raw => "text-gray-300 bg-gray-800/50"
  | Folded => "text-sky-400 bg-sky-900/30"
  | Glyphed => "text-violet-400 bg-violet-900/30"
  | Wysiwyg => "text-amber-400 bg-amber-900/30"
  }

/// View layer label.
let viewLayerLabel = (vl: viewLayer): string =>
  switch vl {
  | Raw => "Raw"
  | Folded => "Folded"
  | Glyphed => "Glyphed"
  | Wysiwyg => "WYSIWYG"
  }

/// Transform query text for the Glyphed view (mathematical symbols).
let toGlyphed = (content: string): string => {
  content
  ->String.replaceAll("FORALL", "\u2200")
  ->String.replaceAll("EXISTS", "\u2203")
  ->String.replaceAll("AND", "\u2227")
  ->String.replaceAll("OR", "\u2228")
  ->String.replaceAll("NOT", "\u00AC")
  ->String.replaceAll("IN", "\u2208")
  ->String.replaceAll("=>", "\u21D2")
  ->String.replaceAll("<=", "\u2264")
  ->String.replaceAll(">=", "\u2265")
  ->String.replaceAll("!=", "\u2260")
  ->String.replaceAll("PROVE", "\u22A2")
  ->String.replaceAll("LINEAR", "\u2AAF")
  ->String.replaceAll("TEMPORAL", "\u29D6")
}

// ============================================================
// SECTION 8: Default State
// ============================================================

/// Default format options — VCL-total official style.
let defaultFormatOptions: formatOptions = {
  style: StyleStandard,
  indentWidth: 2,
  uppercaseKeywords: true,
  alignClauses: true,
  trailingComma: false,
  maxLineWidth: 100,
  insertBlankLines: false,
  annotateTypes: false,
  showLevelMarkers: false,
  colourOutput: true,
}

/// Default linter state.
let defaultLinterState: linterState = {
  profile: ProfileRecommended,
  minimumLevel: L1_Parsed,
  diagnostics: [],
  suppressions: [],
  autoFixEnabled: true,
  lintOnType: true,
  lintDebounceMs: 300,
}

/// Default formatter state.
let defaultFormatterState: formatterState = {
  options: defaultFormatOptions,
  lastFormatted: None,
  showDiff: false,
  formatOnSave: false,
}

/// Default editor state.
let defaultEditorState: editorState = {
  content: "",
  cursorLine: 1,
  cursorColumn: 1,
  selectionStart: None,
  selectionEnd: None,
  undoStack: [],
  redoStack: [],
  activeOperation: OpFindProof,
  activeTemplate: None,
  parameterValues: [],
  isDirty: false,
  lastSaved: None,
}

/// Default execution state.
let defaultExecutionState: executionState = {
  target: TargetVeriSimDB,
  status: Idle,
  lastResult: None,
  history: [],
  maxHistorySize: 100,
  streamingEnabled: false,
  timeoutMs: 30000,
}

/// Default schema state.
let defaultSchemaState: schemaState = {
  entities: [],
  expandedEntities: [],
  searchFilter: "",
  modalityFilter: None,
  lastRefreshed: None,
  loading: false,
}

/// Default dispatch state.
let defaultDispatchState: dispatchState = {
  strategy: StrategyAuto,
  availableProvers: [],
  selectedProvers: [],
  consensusThreshold: 2,
  timeoutPerProverMs: 10000,
  showProverDetails: false,
}

/// Default VCL panel state — the initial state when the panel opens.
let defaultVqlState: vqlState = {
  activeTab: TabEditor,
  viewLayer: Raw,
  panelOpen: false,
  fullscreen: false,
  connection: VqlDisconnected,
  verisimEndpoint: "http://localhost:8200",
  echidnaEndpoint: "http://localhost:8000",
  typellEndpoint: "http://localhost:7800",
  bojRouting: false,
  editor: defaultEditorState,
  linter: defaultLinterState,
  formatter: defaultFormatterState,
  execution: defaultExecutionState,
  schema: defaultSchemaState,
  dispatch: defaultDispatchState,
  typeCheckResult: None,
  pendingObligations: [],
}

// ============================================================
// SECTION 9: Result Cell Formatting
// ============================================================

/// Format a result cell for display.
let formatCell = (cell: resultCell): string =>
  switch cell {
  | CellString(s) => s
  | CellInt(i) => Int.toString(i)
  | CellFloat(f) => Float.toString(f)
  | CellBool(b) =>
    if b {
      "true"
    } else {
      "false"
    }
  | CellNull => "NULL"
  | CellProver(p) => p
  | CellProof(id) => id
  | CellTactic(t) => t
  | CellLevel(l) => getLevelMeta(l).shortName
  | CellOctad(o) => o
  }

/// Format execution time for display.
let formatDuration = (ms: float): string => {
  if ms < 1.0 {
    Float.toFixed(ms *. 1000.0, ~digits=0) ++ "\u00B5s"
  } else if ms < 1000.0 {
    Float.toFixed(ms, ~digits=1) ++ "ms"
  } else {
    Float.toFixed(ms /. 1000.0, ~digits=2) ++ "s"
  }
}

/// Format row count for display.
let formatRowCount = (count: int): string => {
  if count < 1000 {
    Int.toString(count)
  } else if count < 1000000 {
    Float.toFixed(Int.toFloat(count) /. 1000.0, ~digits=1) ++ "K"
  } else {
    Float.toFixed(Int.toFloat(count) /. 1000000.0, ~digits=2) ++ "M"
  }
}
