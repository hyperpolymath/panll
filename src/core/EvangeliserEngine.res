// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Evangeliser Engine — pure logic for JS→ReScript pattern detection.
///
/// Contains the pattern library (52 patterns across 20 categories), the
/// Makaton-inspired glyph registry, the regex-based scanner, and narrative
/// generation. All functions are pure — no side effects, no commands.
///
/// Panel mapping:
///   Panel-L: constraintSummary, filterPatterns, categoryLabel
///   Panel-N: scanCode (regex matching), narrativeFor
///   Panel-W: formatMatch, coverageStats, difficultyLabel

open EvangeliserModel

// ============================================================================
// Category and Difficulty Helpers
// ============================================================================

/// Human-readable label for a pattern category.
let categoryLabel = (cat: evangeliserCategory): string => {
  switch cat {
  | NullSafety => "Null Safety"
  | Async => "Async"
  | ErrorHandling => "Error Handling"
  | ArrayOperations => "Array Operations"
  | Conditionals => "Conditionals"
  | Destructuring => "Destructuring"
  | Defaults => "Defaults"
  | Functional => "Functional"
  | Templates => "Templates"
  | ArrowFunctions => "Arrow Functions"
  | Variants => "Variants"
  | Modules => "Modules"
  | TypeSafety => "Type Safety"
  | Immutability => "Immutability"
  | PatternMatching => "Pattern Matching"
  | PipeOperator => "Pipe Operator"
  | OopToFp => "OOP to FP"
  | ClassesToRecords => "Classes to Records"
  | InheritanceToComposition => "Inheritance to Composition"
  | StateMachines => "State Machines"
  | DataModeling => "Data Modeling"
  }
}

/// Short code for a category (for compact UI).
let categoryCode = (cat: evangeliserCategory): string => {
  switch cat {
  | NullSafety => "null"
  | Async => "async"
  | ErrorHandling => "err"
  | ArrayOperations => "arr"
  | Conditionals => "cond"
  | Destructuring => "dest"
  | Defaults => "def"
  | Functional => "fn"
  | Templates => "tmpl"
  | ArrowFunctions => "arrow"
  | Variants => "var"
  | Modules => "mod"
  | TypeSafety => "type"
  | Immutability => "imm"
  | PatternMatching => "match"
  | PipeOperator => "pipe"
  | OopToFp => "fp"
  | ClassesToRecords => "rec"
  | InheritanceToComposition => "comp"
  | StateMachines => "fsm"
  | DataModeling => "data"
  }
}

/// Tailwind colour class for a category.
let categoryColour = (cat: evangeliserCategory): string => {
  switch cat {
  | NullSafety | TypeSafety => "text-red-400"
  | Async | ErrorHandling => "text-amber-400"
  | ArrayOperations | Functional => "text-emerald-400"
  | Conditionals | PatternMatching => "text-cyan-400"
  | Destructuring | Defaults => "text-violet-400"
  | Templates | ArrowFunctions => "text-blue-400"
  | Variants | DataModeling => "text-pink-400"
  | Modules | Immutability => "text-teal-400"
  | PipeOperator => "text-indigo-400"
  | OopToFp | ClassesToRecords | InheritanceToComposition => "text-orange-400"
  | StateMachines => "text-lime-400"
  }
}

/// Human-readable label for difficulty.
let difficultyLabel = (diff: evangeliserDifficulty): string => {
  switch diff {
  | Beginner => "Beginner"
  | Intermediate => "Intermediate"
  | Advanced => "Advanced"
  }
}

/// Tailwind colour class for difficulty badge.
let difficultyColour = (diff: evangeliserDifficulty): string => {
  switch diff {
  | Beginner => "text-emerald-400 bg-emerald-900/40"
  | Intermediate => "text-amber-400 bg-amber-900/40"
  | Advanced => "text-red-400 bg-red-900/40"
  }
}

/// Human-readable label for view layer.
let viewLayerLabel = (vl: evangeliserViewLayer): string => {
  switch vl {
  | ViewRaw => "Raw"
  | ViewFolded => "Folded"
  | ViewGlyphed => "Glyphed"
  | ViewWysiwyg => "WYSIWYG"
  }
}

// ============================================================================
// All categories as an array (for iteration in UI)
// ============================================================================

let allCategories: array<evangeliserCategory> = [
  NullSafety,
  Async,
  ErrorHandling,
  ArrayOperations,
  Conditionals,
  Destructuring,
  Defaults,
  Functional,
  Templates,
  ArrowFunctions,
  Variants,
  Modules,
  TypeSafety,
  Immutability,
  PatternMatching,
  PipeOperator,
  OopToFp,
  ClassesToRecords,
  InheritanceToComposition,
  StateMachines,
  DataModeling,
]

// ============================================================================
// Glyph Registry — 21 Makaton-inspired glyphs
// ============================================================================

let builtinGlyphs: array<evangeliserGlyph> = [
  {
    symbol: "\xf0\x9f\x94\x84",
    name: "Transform",
    meaning: "Data transformation or mapping",
    semanticCategory: Transformation,
  },
  {
    symbol: "\xf0\x9f\x8e\xaf",
    name: "Target",
    meaning: "Precise type targeting",
    semanticCategory: Safety,
  },
  {
    symbol: "\xf0\x9f\x9b\xa1\xef\xb8\x8f",
    name: "Shield",
    meaning: "Protection from null/undefined",
    semanticCategory: Safety,
  },
  {
    symbol: "\xe2\x9e\xa1\xef\xb8\x8f",
    name: "Flow",
    meaning: "Pipe operator — data flows left to right",
    semanticCategory: Flow,
  },
  {
    symbol: "\xf0\x9f\x94\x80",
    name: "Branch",
    meaning: "Pattern matching — exhaustive branching",
    semanticCategory: Flow,
  },
  {
    symbol: "\xf0\x9f\x93\xa6",
    name: "Package",
    meaning: "Module encapsulation",
    semanticCategory: Structure,
  },
  {
    symbol: "\xe2\x9c\xa8",
    name: "Sparkle",
    meaning: "Type inference — types appear automatically",
    semanticCategory: Safety,
  },
  {
    symbol: "\xf0\x9f\x94\x92",
    name: "Lock",
    meaning: "Immutability — data cannot change",
    semanticCategory: State,
  },
  {
    symbol: "\xf0\x9f\x8c\xb1",
    name: "Seed",
    meaning: "Small code grows into safe patterns",
    semanticCategory: Transformation,
  },
  {
    symbol: "\xf0\x9f\x94\x8d",
    name: "Search",
    meaning: "Pattern detection in JS code",
    semanticCategory: Transformation,
  },
  {
    symbol: "\xf0\x9f\x8f\x97\xef\xb8\x8f",
    name: "Build",
    meaning: "Constructing types and records",
    semanticCategory: Structure,
  },
  {
    symbol: "\xe2\x9a\xa1",
    name: "Lightning",
    meaning: "Fast compilation — instant feedback",
    semanticCategory: Transformation,
  },
  {
    symbol: "\xf0\x9f\xa7\xa9",
    name: "Puzzle",
    meaning: "Composable pieces that fit together",
    semanticCategory: Structure,
  },
  {
    symbol: "\xf0\x9f\x8e\xad",
    name: "Masks",
    meaning: "Variants — different faces of a type",
    semanticCategory: Data,
  },
  {
    symbol: "\xf0\x9f\x93\x90",
    name: "Notebook",
    meaning: "Record types — structured data",
    semanticCategory: Data,
  },
  {
    symbol: "\xf0\x9f\x8c\x8a",
    name: "Wave",
    meaning: "Async operations with promises",
    semanticCategory: Flow,
  },
  {
    symbol: "\xf0\x9f\x94\xa7",
    name: "Wrench",
    meaning: "Utility function or helper",
    semanticCategory: Transformation,
  },
  {
    symbol: "\xf0\x9f\x8c\xb3",
    name: "Tree",
    meaning: "Recursive data structures",
    semanticCategory: Data,
  },
  {
    symbol: "\xf0\x9f\x92\xa1",
    name: "Lightbulb",
    meaning: "Insight — the 'aha' moment",
    semanticCategory: Transformation,
  },
  {
    symbol: "\xf0\x9f\x8e\xb5",
    name: "Note",
    meaning: "Harmony — code that reads naturally",
    semanticCategory: Flow,
  },
  {
    symbol: "\xf0\x9f\x97\x9d\xef\xb8\x8f",
    name: "Compress",
    meaning: "Concise expression — less boilerplate",
    semanticCategory: Structure,
  },
]

/// Look up a glyph by name.
let findGlyph = (name: string): option<evangeliserGlyph> => {
  builtinGlyphs->Array.find(g => g.name === name)
}

/// Get glyph symbols for an array of glyph names.
let glyphSymbols = (names: array<string>): string => {
  names
  ->Array.filterMap(n => findGlyph(n)->Option.map(g => g.symbol))
  ->Array.join(" ")
}

// ============================================================================
// Pattern Library — 52 patterns across 20 categories
// ============================================================================

let builtinPatterns: array<evangeliserPattern> = [
  // --- NullSafety (3) ---
  {
    id: "null-check-option",
    name: "Null Check to Option",
    category: NullSafety,
    difficulty: Beginner,
    jsPattern: "!==?\\s*(null|undefined)",
    confidence: 0.85,
    jsExample: "if (user !== null && user !== undefined) { ... }",
    rescriptExample: "switch user { | Some(u) => ... | None => ... }",
    narrative: {
      celebrate: "You're being careful about null checks!",
      minimize: "But the compiler can't verify you caught every case.",
      better: "ReScript's Option type makes null impossible — the compiler checks exhaustively.",
      safety: "Option<t> eliminates null reference exceptions at compile time.",
    },
    glyphs: ["Shield", "Target"],
    tags: ["null", "undefined", "option", "safety"],
    relatedPatterns: ["optional-chain-option", "nullish-coalesce-default"],
    learningObjectives: ["Understand Option<t> as a replacement for null checks"],
  },
  {
    id: "optional-chain-option",
    name: "Optional Chaining to Option.map",
    category: NullSafety,
    difficulty: Intermediate,
    jsPattern: "\\?\\.\\w+",
    confidence: 0.80,
    jsExample: "const name = user?.profile?.name",
    rescriptExample: "let name = user->Option.flatMap(u => u.profile)->Option.map(p => p.name)",
    narrative: {
      celebrate: "Optional chaining is a great JS feature!",
      minimize: "But it silently produces undefined deep in chains.",
      better: "Option.flatMap makes every step explicit and type-checked.",
      safety: "Each step in the chain has a known type — no hidden undefined.",
    },
    glyphs: ["Shield", "Flow"],
    tags: ["optional-chaining", "option", "flatmap"],
    relatedPatterns: ["null-check-option"],
    learningObjectives: ["Chain Option operations with flatMap and map"],
  },
  {
    id: "nullish-coalesce-default",
    name: "Nullish Coalescing to Default",
    category: NullSafety,
    difficulty: Beginner,
    jsPattern: "\\?\\?",
    confidence: 0.90,
    jsExample: "const port = config.port ?? 3000",
    rescriptExample: "let port = config.port->Option.getOr(3000)",
    narrative: {
      celebrate: "Using ?? for defaults is clean!",
      minimize: "But ?? only handles null/undefined, not other falsy values.",
      better: "Option.getOr is explicit about what 'missing' means.",
      safety: "The default value must match the Option's inner type.",
    },
    glyphs: ["Shield", "Sparkle"],
    tags: ["nullish", "coalescing", "default"],
    relatedPatterns: ["null-check-option"],
    learningObjectives: ["Use Option.getOr for safe defaults"],
  },
  // --- Async (3) ---
  {
    id: "promise-then-pipe",
    name: "Promise.then to Pipe",
    category: Async,
    difficulty: Intermediate,
    jsPattern: "\\.then\\s*\\(",
    confidence: 0.75,
    jsExample: "fetch(url).then(r => r.json()).then(data => process(data))",
    rescriptExample: "Fetch.fetch(url)->Promise.then(r => r->Response.json)->Promise.then(data => process(data))",
    narrative: {
      celebrate: "Promise chains show clear async flow!",
      minimize: "Error handling in long chains can be tricky.",
      better: "ReScript preserves the chain with type-safe pipe syntax.",
      safety: "Every promise step has a known resolved type.",
    },
    glyphs: ["Wave", "Flow"],
    tags: ["promise", "then", "async", "fetch"],
    relatedPatterns: ["async-await-promise"],
    learningObjectives: ["Use Promise.then with pipe operator"],
  },
  {
    id: "async-await-promise",
    name: "Async/Await to Promise",
    category: Async,
    difficulty: Intermediate,
    jsPattern: "async\\s+function|async\\s*\\(",
    confidence: 0.70,
    jsExample: "async function getData() { const res = await fetch(url); return await res.json(); }",
    rescriptExample: "let getData = () => Fetch.fetch(url)->Promise.then(res => res->Response.json)",
    narrative: {
      celebrate: "Async/await makes async code readable!",
      minimize: "But forgotten awaits silently return promises instead of values.",
      better: "ReScript's promise chains are explicit — no hidden async.",
      safety: "The type system tracks what's a Promise and what's resolved.",
    },
    glyphs: ["Wave", "Lightning"],
    tags: ["async", "await", "promise"],
    relatedPatterns: ["promise-then-pipe"],
    learningObjectives: ["Express async operations as typed Promise chains"],
  },
  {
    id: "try-catch-async",
    name: "Try/Catch Async to Result",
    category: Async,
    difficulty: Advanced,
    jsPattern: "try\\s*\\{[^}]*await",
    confidence: 0.65,
    jsExample: "try { const data = await fetch(url); } catch (e) { handleError(e); }",
    rescriptExample: "Fetch.fetch(url)->Promise.then(data => Ok(data))->Promise.catch(_ => Error(NetworkError))",
    narrative: {
      celebrate: "Wrapping async in try/catch shows error awareness!",
      minimize: "But catch(e) gives you 'unknown' — no type information.",
      better: "Promise.catch with Result gives typed error handling.",
      safety: "Error variants are exhaustively checked by the compiler.",
    },
    glyphs: ["Shield", "Wave"],
    tags: ["try", "catch", "async", "result"],
    relatedPatterns: ["async-await-promise", "try-catch-result"],
    learningObjectives: ["Combine Promise with Result for typed error handling"],
  },
  // --- ErrorHandling (3) ---
  {
    id: "try-catch-result",
    name: "Try/Catch to Result",
    category: ErrorHandling,
    difficulty: Beginner,
    jsPattern: "try\\s*\\{",
    confidence: 0.80,
    jsExample: "try { JSON.parse(input) } catch (e) { return null }",
    rescriptExample: "switch JSON.parseExn(input) { | data => Ok(data) | exception _ => Error(ParseError) }",
    narrative: {
      celebrate: "Handling errors explicitly is great practice!",
      minimize: "But catch gives you 'any' — you don't know what went wrong.",
      better: "Result<ok, error> with typed error variants tells you exactly what failed.",
      safety: "Every error path must be handled — the compiler won't let you forget.",
    },
    glyphs: ["Shield", "Branch"],
    tags: ["try", "catch", "result", "error"],
    relatedPatterns: ["error-code-variant"],
    learningObjectives: ["Replace try/catch with Result type"],
  },
  {
    id: "error-code-variant",
    name: "Error Codes to Variants",
    category: ErrorHandling,
    difficulty: Intermediate,
    jsPattern: "error\\.code\\s*===",
    confidence: 0.75,
    jsExample: "if (error.code === 'NOT_FOUND') { ... } else if (error.code === 'FORBIDDEN') { ... }",
    rescriptExample: "switch error { | NotFound => ... | Forbidden => ... | ServerError(code) => ... }",
    narrative: {
      celebrate: "Checking error codes shows thorough handling!",
      minimize: "But string codes can be misspelled without any warning.",
      better: "Variant types make every error case a checked constructor.",
      safety: "Adding a new error variant forces you to handle it everywhere.",
    },
    glyphs: ["Branch", "Target"],
    tags: ["error", "code", "variant"],
    relatedPatterns: ["try-catch-result"],
    learningObjectives: ["Model errors as variant types"],
  },
  {
    id: "throw-panic",
    name: "Throw to Panic/Result",
    category: ErrorHandling,
    difficulty: Beginner,
    jsPattern: "throw\\s+new\\s+Error",
    confidence: 0.85,
    jsExample: "if (!valid) throw new Error('Invalid input')",
    rescriptExample: "if !valid { Error(InvalidInput) } else { Ok(data) }",
    narrative: {
      celebrate: "Throwing errors signals problems clearly!",
      minimize: "But throws are invisible in the type signature.",
      better: "Returning Result makes errors part of the function's contract.",
      safety: "Callers must handle the error — it's in the return type.",
    },
    glyphs: ["Shield", "Target"],
    tags: ["throw", "error", "result"],
    relatedPatterns: ["try-catch-result"],
    learningObjectives: ["Replace throw with Result return types"],
  },
  // --- ArrayOperations (3) ---
  {
    id: "array-map-pipe",
    name: "Array.map to Pipe",
    category: ArrayOperations,
    difficulty: Beginner,
    jsPattern: "\\.map\\s*\\(",
    confidence: 0.70,
    jsExample: "users.map(u => u.name).filter(n => n.length > 0)",
    rescriptExample: "users->Array.map(u => u.name)->Array.filter(n => String.length(n) > 0)",
    narrative: {
      celebrate: "Chaining map and filter is idiomatic functional style!",
      minimize: "Just note: JS array methods can return unexpected types.",
      better: "ReScript's pipe operator makes the data flow crystal clear.",
      safety: "Every step is type-checked — no accidental type coercion.",
    },
    glyphs: ["Transform", "Flow"],
    tags: ["array", "map", "pipe"],
    relatedPatterns: ["array-reduce-fold", "array-find-option"],
    learningObjectives: ["Use pipe operator with Array functions"],
  },
  {
    id: "array-reduce-fold",
    name: "Array.reduce to Array.reduce",
    category: ArrayOperations,
    difficulty: Intermediate,
    jsPattern: "\\.reduce\\s*\\(",
    confidence: 0.70,
    jsExample: "nums.reduce((sum, n) => sum + n, 0)",
    rescriptExample: "nums->Array.reduce(0, (sum, n) => sum + n)",
    narrative: {
      celebrate: "Reduce is the Swiss army knife of array operations!",
      minimize: "The accumulator type is often implicitly 'any'.",
      better: "ReScript's reduce has explicit initial value and typed accumulator.",
      safety: "The accumulator type is inferred and checked at every step.",
    },
    glyphs: ["Transform", "Sparkle"],
    tags: ["array", "reduce", "fold"],
    relatedPatterns: ["array-map-pipe"],
    learningObjectives: ["Use Array.reduce with explicit types"],
  },
  {
    id: "array-find-option",
    name: "Array.find to Option",
    category: ArrayOperations,
    difficulty: Beginner,
    jsPattern: "\\.find\\s*\\(",
    confidence: 0.75,
    jsExample: "const admin = users.find(u => u.role === 'admin')",
    rescriptExample: "let admin = users->Array.find(u => u.role === Admin)",
    narrative: {
      celebrate: "Using find is cleaner than manual loops!",
      minimize: "But find returns undefined when nothing matches.",
      better: "ReScript's Array.find returns Option — you must handle the None case.",
      safety: "No more 'cannot read property of undefined' from unfound elements.",
    },
    glyphs: ["Search", "Shield"],
    tags: ["array", "find", "option"],
    relatedPatterns: ["array-map-pipe"],
    learningObjectives: ["Understand Array.find returns Option<t>"],
  },
  // --- Conditionals (3) ---
  {
    id: "ternary-switch",
    name: "Ternary to Switch",
    category: Conditionals,
    difficulty: Beginner,
    jsPattern: "\\?[^?].*:",
    confidence: 0.60,
    jsExample: "const label = status === 'active' ? 'Active' : status === 'inactive' ? 'Inactive' : 'Unknown'",
    rescriptExample: "let label = switch status { | Active => \"Active\" | Inactive => \"Inactive\" | Unknown => \"Unknown\" }",
    narrative: {
      celebrate: "Ternaries are concise for simple conditions!",
      minimize: "Nested ternaries become hard to read quickly.",
      better: "Switch expressions are flat and exhaustive.",
      safety: "Add a new status? The compiler tells you every switch that needs updating.",
    },
    glyphs: ["Branch", "Sparkle"],
    tags: ["ternary", "switch", "conditional"],
    relatedPatterns: ["if-else-switch"],
    learningObjectives: ["Replace nested ternaries with switch expressions"],
  },
  {
    id: "if-else-switch",
    name: "If/Else Chain to Switch",
    category: Conditionals,
    difficulty: Beginner,
    jsPattern: "if\\s*\\(.*\\)\\s*\\{[^}]*\\}\\s*else\\s*if",
    confidence: 0.75,
    jsExample: "if (type === 'a') { ... } else if (type === 'b') { ... } else { ... }",
    rescriptExample: "switch type { | A => ... | B => ... }",
    narrative: {
      celebrate: "If/else chains handle multiple cases!",
      minimize: "But there's no guarantee you covered every case.",
      better: "Switch with variants is exhaustive — miss a case and the compiler tells you.",
      safety: "Exhaustive pattern matching eliminates 'else' as a catch-all.",
    },
    glyphs: ["Branch", "Target"],
    tags: ["if", "else", "switch", "exhaustive"],
    relatedPatterns: ["ternary-switch"],
    learningObjectives: ["Use exhaustive switch expressions"],
  },
  {
    id: "typeof-variant",
    name: "Typeof Check to Variant",
    category: Conditionals,
    difficulty: Intermediate,
    jsPattern: "typeof\\s+\\w+\\s*===",
    confidence: 0.70,
    jsExample: "if (typeof value === 'string') { ... } else if (typeof value === 'number') { ... }",
    rescriptExample: "switch value { | String(s) => ... | Number(n) => ... }",
    narrative: {
      celebrate: "Runtime type checks show defensive coding!",
      minimize: "But typeof only catches a few types and misses objects.",
      better: "Variant types carry their tag at compile time — no runtime checks needed.",
      safety: "The type is known before runtime — no typeof surprises.",
    },
    glyphs: ["Target", "Branch"],
    tags: ["typeof", "variant", "type-check"],
    relatedPatterns: ["if-else-switch"],
    learningObjectives: ["Replace typeof checks with variant types"],
  },
  // --- Destructuring (2) ---
  {
    id: "object-destructure-record",
    name: "Object Destructuring to Record",
    category: Destructuring,
    difficulty: Beginner,
    jsPattern: "const\\s*\\{[^}]+\\}\\s*=",
    confidence: 0.80,
    jsExample: "const { name, age, email } = user",
    rescriptExample: "let { name, age, email } = user",
    narrative: {
      celebrate: "Destructuring is clean and readable!",
      minimize: "But accessing a non-existent field silently gives undefined.",
      better: "ReScript records have fixed fields — destructuring only works on known fields.",
      safety: "Misspell a field name and the compiler catches it immediately.",
    },
    glyphs: ["Notebook", "Sparkle"],
    tags: ["destructuring", "record", "object"],
    relatedPatterns: ["spread-record-update"],
    learningObjectives: ["Use record destructuring with type safety"],
  },
  {
    id: "spread-record-update",
    name: "Spread to Record Update",
    category: Destructuring,
    difficulty: Intermediate,
    jsPattern: "\\.\\.\\.\\w+",
    confidence: 0.65,
    jsExample: "const updated = { ...user, name: 'New Name' }",
    rescriptExample: "let updated = { ...user, name: \"New Name\" }",
    narrative: {
      celebrate: "Spread for immutable updates is great practice!",
      minimize: "But you can accidentally spread in extra or wrong fields.",
      better: "ReScript's record update syntax only allows declared fields.",
      safety: "The spread expression must match the record type exactly.",
    },
    glyphs: ["Notebook", "Lock"],
    tags: ["spread", "record", "update", "immutable"],
    relatedPatterns: ["object-destructure-record"],
    learningObjectives: ["Use immutable record updates with spread"],
  },
  // --- Defaults (2) ---
  {
    id: "default-params",
    name: "Default Parameters to Option",
    category: Defaults,
    difficulty: Beginner,
    jsPattern: "function\\s+\\w+\\s*\\([^)]*=",
    confidence: 0.75,
    jsExample: "function greet(name = 'World') { return `Hello ${name}!` }",
    rescriptExample: "let greet = (~name=\"World\") => `Hello ${name}!`",
    narrative: {
      celebrate: "Default parameters reduce boilerplate!",
      minimize: "But defaults are invisible at the call site.",
      better: "ReScript's labeled arguments with defaults are self-documenting.",
      safety: "The type of the default must match the parameter type.",
    },
    glyphs: ["Sparkle", "Wrench"],
    tags: ["default", "parameter", "labeled"],
    relatedPatterns: ["nullish-coalesce-default"],
    learningObjectives: ["Use labeled arguments with defaults"],
  },
  {
    id: "or-default",
    name: "|| Default to Option.getOr",
    category: Defaults,
    difficulty: Beginner,
    jsPattern: "\\|\\|\\s*['\"`\\d]",
    confidence: 0.70,
    jsExample: "const name = input || 'default'",
    rescriptExample: "let name = input->Option.getOr(\"default\")",
    narrative: {
      celebrate: "Using || for defaults is a common pattern!",
      minimize: "But || treats 0, '', and false as falsy too.",
      better: "Option.getOr only triggers on None — not on empty strings or zero.",
      safety: "The fallback type must match the Option's inner type.",
    },
    glyphs: ["Shield", "Wrench"],
    tags: ["or", "default", "falsy", "option"],
    relatedPatterns: ["nullish-coalesce-default"],
    learningObjectives: ["Distinguish between falsy and None"],
  },
  // --- Functional (3) ---
  {
    id: "callback-fn",
    name: "Callback to First-Class Function",
    category: Functional,
    difficulty: Beginner,
    jsPattern: "function\\s*\\(\\w+\\s*,\\s*callback\\)",
    confidence: 0.65,
    jsExample: "function processData(data, callback) { callback(transform(data)) }",
    rescriptExample: "let processData = (data, callback) => callback(transform(data))",
    narrative: {
      celebrate: "Using callbacks shows functional thinking!",
      minimize: "But callback types are often 'any' in JS.",
      better: "ReScript functions are fully typed — the callback's signature is explicit.",
      safety: "The callback's parameter and return types are checked at the call site.",
    },
    glyphs: ["Transform", "Target"],
    tags: ["callback", "function", "higher-order"],
    relatedPatterns: ["compose-pipe"],
    learningObjectives: ["Understand typed higher-order functions"],
  },
  {
    id: "compose-pipe",
    name: "Function Composition to Pipe",
    category: Functional,
    difficulty: Intermediate,
    jsPattern: "compose\\(|pipe\\(",
    confidence: 0.70,
    jsExample: "const result = compose(toUpper, trim, validate)(input)",
    rescriptExample: "let result = input->validate->String.trim->String.toUpperCase",
    narrative: {
      celebrate: "Function composition is elegant!",
      minimize: "But compose/pipe utilities add runtime overhead and type complexity.",
      better: "ReScript's -> operator is zero-cost function composition.",
      safety: "Each step's output type must match the next step's input type.",
    },
    glyphs: ["Flow", "Lightning"],
    tags: ["compose", "pipe", "function"],
    relatedPatterns: ["callback-fn"],
    learningObjectives: ["Use pipe operator for zero-cost composition"],
  },
  {
    id: "iife-block",
    name: "IIFE to Block Expression",
    category: Functional,
    difficulty: Intermediate,
    jsPattern: "\\(\\s*\\(\\s*\\)\\s*=>\\s*\\{",
    confidence: 0.70,
    jsExample: "const result = (() => { const x = compute(); return x * 2; })()",
    rescriptExample: "let result = { let x = compute(); x * 2 }",
    narrative: {
      celebrate: "IIFEs create scoped expressions!",
      minimize: "But the syntax is verbose and easy to get wrong.",
      better: "ReScript blocks are expressions — no IIFE needed.",
      safety: "The block's return type is inferred from the last expression.",
    },
    glyphs: ["Compress", "Sparkle"],
    tags: ["iife", "block", "expression"],
    relatedPatterns: ["compose-pipe"],
    learningObjectives: ["Use block expressions instead of IIFEs"],
  },
  // --- Templates (2) ---
  {
    id: "template-literal",
    name: "Template Literal to String Interpolation",
    category: Templates,
    difficulty: Beginner,
    jsPattern: "`[^`]*\\$\\{",
    confidence: 0.85,
    jsExample: "const msg = `Hello ${name}, you have ${count} items`",
    rescriptExample: "let msg = `Hello ${name}, you have ${Int.toString(count)} items`",
    narrative: {
      celebrate: "Template literals are readable and powerful!",
      minimize: "JS implicitly converts anything to string inside ${}.",
      better: "ReScript requires explicit toString — no surprise coercions.",
      safety: "Only strings can be interpolated — Int.toString makes intent clear.",
    },
    glyphs: ["Sparkle", "Target"],
    tags: ["template", "string", "interpolation"],
    relatedPatterns: [],
    learningObjectives: ["Use explicit type conversion in string interpolation"],
  },
  {
    id: "string-concat-interp",
    name: "String Concatenation to Interpolation",
    category: Templates,
    difficulty: Beginner,
    jsPattern: "\\+\\s*['\"]|['\"]\\s*\\+",
    confidence: 0.60,
    jsExample: "const url = baseUrl + '/api/' + version + '/users'",
    rescriptExample: "let url = `${baseUrl}/api/${version}/users`",
    narrative: {
      celebrate: "Building strings dynamically is useful!",
      minimize: "Concatenation with + can accidentally coerce non-strings.",
      better: "String interpolation is cleaner and type-safe.",
      safety: "Each interpolated value must be a string type.",
    },
    glyphs: ["Sparkle", "Flow"],
    tags: ["string", "concatenation", "interpolation"],
    relatedPatterns: ["template-literal"],
    learningObjectives: ["Prefer interpolation over concatenation"],
  },
  // --- ArrowFunctions (2) ---
  {
    id: "arrow-fn-let",
    name: "Arrow Function to Let Binding",
    category: ArrowFunctions,
    difficulty: Beginner,
    jsPattern: "const\\s+\\w+\\s*=\\s*\\([^)]*\\)\\s*=>",
    confidence: 0.85,
    jsExample: "const add = (a, b) => a + b",
    rescriptExample: "let add = (a, b) => a + b",
    narrative: {
      celebrate: "Arrow functions are clean and concise!",
      minimize: "But parameter types are implicit in JS.",
      better: "ReScript infers types from usage — add works for int or float, not both.",
      safety: "The type system prevents accidentally adding a string to a number.",
    },
    glyphs: ["Lightning", "Sparkle"],
    tags: ["arrow", "function", "let"],
    relatedPatterns: ["callback-fn"],
    learningObjectives: ["Understand let bindings with type inference"],
  },
  {
    id: "arrow-implicit-return",
    name: "Implicit Return",
    category: ArrowFunctions,
    difficulty: Beginner,
    jsPattern: "=>\\s*[^{]",
    confidence: 0.55,
    jsExample: "const double = x => x * 2",
    rescriptExample: "let double = x => x * 2",
    narrative: {
      celebrate: "Implicit return is beautifully concise!",
      minimize: "In JS, forgetting braces changes the return value.",
      better: "In ReScript, every expression returns — no braces confusion.",
      safety: "The return type is always inferred and checked.",
    },
    glyphs: ["Lightning", "Compress"],
    tags: ["arrow", "return", "expression"],
    relatedPatterns: ["arrow-fn-let"],
    learningObjectives: ["Understand expression-based return values"],
  },
  // --- Variants (3) ---
  {
    id: "string-enum-variant",
    name: "String Enum to Variant",
    category: Variants,
    difficulty: Beginner,
    jsPattern: "type\\s+\\w+\\s*=\\s*['\"]\\w+['\"]\\s*\\|",
    confidence: 0.80,
    jsExample: "type Status = 'active' | 'inactive' | 'pending'",
    rescriptExample: "type status = Active | Inactive | Pending",
    narrative: {
      celebrate: "String union types model states well!",
      minimize: "But string comparisons can have typos at runtime.",
      better: "Variants are constructors — misspelling one is a compile error.",
      safety: "Pattern matching on variants is exhaustive — every case handled.",
    },
    glyphs: ["Masks", "Target"],
    tags: ["enum", "variant", "union"],
    relatedPatterns: ["tagged-union-variant"],
    learningObjectives: ["Model states with variant types"],
  },
  {
    id: "tagged-union-variant",
    name: "Tagged Union to Variant",
    category: Variants,
    difficulty: Intermediate,
    jsPattern: "type.*=.*\\{\\s*kind:\\s*['\"]",
    confidence: 0.75,
    jsExample: "type Shape = { kind: 'circle', radius: number } | { kind: 'rect', w: number, h: number }",
    rescriptExample: "type shape = Circle({ radius: float }) | Rect({ w: float, h: float })",
    narrative: {
      celebrate: "Tagged unions are a powerful JS pattern!",
      minimize: "But the tag field is a stringly-typed convention.",
      better: "ReScript variants with payloads are first-class tagged unions.",
      safety: "Each constructor's payload is typed — no accessing .radius on a Rect.",
    },
    glyphs: ["Masks", "Branch"],
    tags: ["tagged", "union", "variant", "payload"],
    relatedPatterns: ["string-enum-variant"],
    learningObjectives: ["Use variant constructors with typed payloads"],
  },
  {
    id: "discriminated-switch",
    name: "Discriminated Switch to Pattern Match",
    category: Variants,
    difficulty: Intermediate,
    jsPattern: "switch\\s*\\(\\w+\\.kind\\)",
    confidence: 0.80,
    jsExample: "switch (shape.kind) { case 'circle': ... case 'rect': ... }",
    rescriptExample: "switch shape { | Circle({radius}) => ... | Rect({w, h}) => ... }",
    narrative: {
      celebrate: "Switching on discriminant fields is idiomatic!",
      minimize: "But JS switch has fall-through and no exhaustiveness check.",
      better: "ReScript switch is an expression, has no fall-through, and is exhaustive.",
      safety: "Payload fields are destructured and typed in each branch.",
    },
    glyphs: ["Branch", "Sparkle"],
    tags: ["switch", "discriminated", "pattern-match"],
    relatedPatterns: ["tagged-union-variant"],
    learningObjectives: ["Destructure variant payloads in switch"],
  },
  // --- Modules (2) ---
  {
    id: "namespace-module",
    name: "Namespace to Module",
    category: Modules,
    difficulty: Intermediate,
    jsPattern: "export\\s+(const|function|class)\\s+",
    confidence: 0.55,
    jsExample: "export function validateEmail(email) { ... }",
    rescriptExample: "// In Validation.res\nlet validateEmail = (email: string): result<string, validationError> => ...",
    narrative: {
      celebrate: "Named exports organise code well!",
      minimize: "But JS modules need explicit import/export ceremony.",
      better: "ReScript files are modules automatically — no export keyword needed.",
      safety: "Every function's type is inferred from its implementation.",
    },
    glyphs: ["Package", "Compress"],
    tags: ["module", "export", "namespace"],
    relatedPatterns: [],
    learningObjectives: ["Understand file-as-module convention"],
  },
  {
    id: "barrel-module",
    name: "Barrel Export to Module Open",
    category: Modules,
    difficulty: Advanced,
    jsPattern: "export\\s*\\{[^}]+\\}\\s*from",
    confidence: 0.60,
    jsExample: "export { validateEmail, validatePhone } from './validation'",
    rescriptExample: "// In Utils.res\ninclude Validation // Re-exports all of Validation",
    narrative: {
      celebrate: "Barrel files simplify imports!",
      minimize: "But barrel files can cause tree-shaking issues.",
      better: "ReScript's include re-exports a module cleanly — dead code is eliminated.",
      safety: "Include brings all types and values into scope — no partial re-exports.",
    },
    glyphs: ["Package", "Flow"],
    tags: ["barrel", "export", "include"],
    relatedPatterns: ["namespace-module"],
    learningObjectives: ["Use include for module re-exports"],
  },
  // --- TypeSafety (2) ---
  {
    id: "any-generic",
    name: "Any Type to Generic",
    category: TypeSafety,
    difficulty: Intermediate,
    jsPattern: ":\\s*any",
    confidence: 0.90,
    jsExample: "function identity(x: any): any { return x }",
    rescriptExample: "let identity = (x: 'a): 'a => x",
    narrative: {
      celebrate: "At least you're using type annotations!",
      minimize: "But 'any' defeats the purpose of types entirely.",
      better: "ReScript generics ('a) preserve type information through the function.",
      safety: "identity(42) returns int, identity(\"hi\") returns string — no cast needed.",
    },
    glyphs: ["Target", "Sparkle"],
    tags: ["any", "generic", "type-parameter"],
    relatedPatterns: [],
    learningObjectives: ["Replace 'any' with type parameters"],
  },
  {
    id: "type-assertion-pattern",
    name: "Type Assertion to Pattern Match",
    category: TypeSafety,
    difficulty: Advanced,
    jsPattern: "as\\s+\\w+",
    confidence: 0.65,
    jsExample: "const el = document.getElementById('app') as HTMLDivElement",
    rescriptExample: "switch document->Document.getElementById(\"app\") { | Some(el) => ... | None => ... }",
    narrative: {
      celebrate: "Type assertions show you know the expected type!",
      minimize: "But 'as' lies to the compiler — it trusts you blindly.",
      better: "ReScript's nullable DOM APIs return Option — you handle both cases.",
      safety: "No type assertion can crash at runtime — every path is checked.",
    },
    glyphs: ["Shield", "Branch"],
    tags: ["assertion", "cast", "option"],
    relatedPatterns: ["null-check-option"],
    learningObjectives: ["Replace type assertions with Option handling"],
  },
  // --- Immutability (2) ---
  {
    id: "let-const-let",
    name: "Const/Let to Let",
    category: Immutability,
    difficulty: Beginner,
    jsPattern: "(const|let)\\s+\\w+\\s*=",
    confidence: 0.50,
    jsExample: "let count = 0; count = count + 1;",
    rescriptExample: "let count = ref(0); count := count.contents + 1",
    narrative: {
      celebrate: "Using let for mutable state is honest!",
      minimize: "But JS let allows mutation by default — bugs hide easily.",
      better: "ReScript's let is immutable. Mutation requires an explicit ref().",
      safety: "Immutable by default means fewer accidental state changes.",
    },
    glyphs: ["Lock", "Sparkle"],
    tags: ["const", "let", "immutable", "ref"],
    relatedPatterns: ["spread-record-update"],
    learningObjectives: ["Understand immutable-by-default bindings"],
  },
  {
    id: "object-freeze-record",
    name: "Object.freeze to Record",
    category: Immutability,
    difficulty: Intermediate,
    jsPattern: "Object\\.freeze\\(",
    confidence: 0.85,
    jsExample: "const config = Object.freeze({ port: 3000, host: 'localhost' })",
    rescriptExample: "let config = { port: 3000, host: \"localhost\" } // Already immutable!",
    narrative: {
      celebrate: "Freezing objects prevents accidental mutation!",
      minimize: "But freeze is shallow — nested objects are still mutable.",
      better: "ReScript records are deeply immutable by default — no freeze needed.",
      safety: "Attempting to mutate a record field is a compile error.",
    },
    glyphs: ["Lock", "Compress"],
    tags: ["freeze", "immutable", "record"],
    relatedPatterns: ["let-const-let"],
    learningObjectives: ["Understand records are immutable by default"],
  },
  // --- PatternMatching (3) ---
  {
    id: "switch-match",
    name: "Switch Statement to Pattern Match",
    category: PatternMatching,
    difficulty: Beginner,
    jsPattern: "switch\\s*\\(",
    confidence: 0.65,
    jsExample: "switch (action.type) { case 'INCREMENT': ... case 'DECREMENT': ... }",
    rescriptExample: "switch action { | Increment => ... | Decrement => ... }",
    narrative: {
      celebrate: "Switch statements handle multiple cases!",
      minimize: "But JS switch has fall-through and no exhaustiveness.",
      better: "ReScript switch is exhaustive, has no fall-through, and is an expression.",
      safety: "Add a new action type and the compiler flags every unhandled switch.",
    },
    glyphs: ["Branch", "Target"],
    tags: ["switch", "pattern-match", "exhaustive"],
    relatedPatterns: ["nested-match"],
    learningObjectives: ["Use exhaustive pattern matching"],
  },
  {
    id: "nested-match",
    name: "Nested If to Nested Match",
    category: PatternMatching,
    difficulty: Intermediate,
    jsPattern: "if\\s*\\(.*\\)\\s*\\{[^}]*if\\s*\\(",
    confidence: 0.60,
    jsExample: "if (user) { if (user.role === 'admin') { if (user.active) { ... } } }",
    rescriptExample: "switch (user, user.role, user.active) { | (Some(u), Admin, true) => ... | _ => ... }",
    narrative: {
      celebrate: "Nested checks are thorough!",
      minimize: "But deeply nested ifs are hard to follow.",
      better: "Tuple pattern matching flattens nested conditions into one switch.",
      safety: "All combinations are checked — no forgotten edge cases.",
    },
    glyphs: ["Branch", "Compress"],
    tags: ["nested", "pattern-match", "tuple"],
    relatedPatterns: ["switch-match"],
    learningObjectives: ["Flatten nested conditions with tuple matching"],
  },
  {
    id: "guard-when",
    name: "If Guard to When Clause",
    category: PatternMatching,
    difficulty: Advanced,
    jsPattern: "case\\s+.*:\\s*if\\s*\\(",
    confidence: 0.60,
    jsExample: "switch (x) { case n: if (n > 0) return 'positive' }",
    rescriptExample: "switch x { | n if n > 0 => \"positive\" | _ => \"non-positive\" }",
    narrative: {
      celebrate: "Guard clauses add precision to cases!",
      minimize: "But JS case with if is awkward and error-prone.",
      better: "ReScript's 'if' guard is part of the pattern — clean and readable.",
      safety: "Guards compose with exhaustiveness — the wildcard ensures coverage.",
    },
    glyphs: ["Branch", "Target"],
    tags: ["guard", "when", "pattern-match"],
    relatedPatterns: ["switch-match"],
    learningObjectives: ["Use guard clauses in pattern matching"],
  },
  // --- PipeOperator (2) ---
  {
    id: "method-chain-pipe",
    name: "Method Chain to Pipe",
    category: PipeOperator,
    difficulty: Beginner,
    jsPattern: "\\)\\s*\\.\\w+\\(",
    confidence: 0.55,
    jsExample: "data.filter(x => x > 0).map(x => x * 2).reduce((a, b) => a + b, 0)",
    rescriptExample: "data->Array.filter(x => x > 0)->Array.map(x => x * 2)->Array.reduce(0, (a, b) => a + b)",
    narrative: {
      celebrate: "Method chaining reads left to right!",
      minimize: "But methods are bound to the prototype — you can't chain arbitrary functions.",
      better: "The pipe operator works with any function — not just methods.",
      safety: "Each step's type flows into the next — no implicit this binding.",
    },
    glyphs: ["Flow", "Lightning"],
    tags: ["pipe", "chain", "method"],
    relatedPatterns: ["compose-pipe"],
    learningObjectives: ["Use pipe operator for data transformation chains"],
  },
  {
    id: "lodash-pipe",
    name: "Lodash/Ramda to Pipe",
    category: PipeOperator,
    difficulty: Intermediate,
    jsPattern: "_\\.chain\\(|R\\.pipe\\(",
    confidence: 0.75,
    jsExample: "_.chain(data).filter(isActive).sortBy('name').value()",
    rescriptExample: "data->Array.filter(isActive)->Array.toSorted((a, b) => compare(a.name, b.name))",
    narrative: {
      celebrate: "Lodash chains are powerful data pipelines!",
      minimize: "But they add a runtime dependency and lose type information.",
      better: "ReScript's pipe operator does the same thing with zero runtime cost.",
      safety: "Every step is type-checked — no 'string' accidentally becoming 'number'.",
    },
    glyphs: ["Flow", "Compress"],
    tags: ["lodash", "ramda", "pipe", "chain"],
    relatedPatterns: ["method-chain-pipe"],
    learningObjectives: ["Replace utility libraries with built-in pipe"],
  },
  // --- OopToFp (2) ---
  {
    id: "class-module",
    name: "Class to Module",
    category: OopToFp,
    difficulty: Intermediate,
    jsPattern: "class\\s+\\w+\\s*\\{",
    confidence: 0.70,
    jsExample: "class UserService { constructor(db) { this.db = db } getUser(id) { ... } }",
    rescriptExample: "// UserService.res\nlet getUser = (db, id) => ...",
    narrative: {
      celebrate: "Classes encapsulate related logic!",
      minimize: "But classes mix data and behaviour, making testing harder.",
      better: "ReScript modules group functions — data flows in as arguments.",
      safety: "No 'this' binding confusion — every dependency is explicit.",
    },
    glyphs: ["Package", "Wrench"],
    tags: ["class", "module", "oop", "fp"],
    relatedPatterns: ["inheritance-composition"],
    learningObjectives: ["Replace classes with modules and functions"],
  },
  {
    id: "inheritance-composition",
    name: "Inheritance to Composition",
    category: InheritanceToComposition,
    difficulty: Advanced,
    jsPattern: "extends\\s+\\w+",
    confidence: 0.70,
    jsExample: "class AdminUser extends User { ... }",
    rescriptExample: "type user = { name: string, role: role }\ntype role = Regular | Admin({ permissions: array<permission> })",
    narrative: {
      celebrate: "Inheritance models 'is-a' relationships!",
      minimize: "But deep hierarchies become brittle and hard to change.",
      better: "Composition with variants models the differences explicitly.",
      safety: "No virtual dispatch surprises — the variant tag is checked at compile time.",
    },
    glyphs: ["Tree", "Masks"],
    tags: ["inheritance", "composition", "variant"],
    relatedPatterns: ["class-module"],
    learningObjectives: ["Model hierarchies with composition"],
  },
  // --- ClassesToRecords (2) ---
  {
    id: "class-record",
    name: "Class Instance to Record",
    category: ClassesToRecords,
    difficulty: Beginner,
    jsPattern: "new\\s+\\w+\\(",
    confidence: 0.65,
    jsExample: "const user = new User('Alice', 30)",
    rescriptExample: "let user = { name: \"Alice\", age: 30 }",
    narrative: {
      celebrate: "Constructor calls create structured data!",
      minimize: "But constructors hide field names — position matters.",
      better: "Record literals name every field — self-documenting and order-independent.",
      safety: "Missing a required field is a compile error.",
    },
    glyphs: ["Notebook", "Sparkle"],
    tags: ["class", "record", "constructor"],
    relatedPatterns: ["class-module"],
    learningObjectives: ["Replace class instances with record literals"],
  },
  {
    id: "getter-field",
    name: "Getter/Setter to Record Field",
    category: ClassesToRecords,
    difficulty: Intermediate,
    jsPattern: "get\\s+\\w+\\(\\)|set\\s+\\w+\\(",
    confidence: 0.70,
    jsExample: "class User { get fullName() { return `${this.first} ${this.last}` } }",
    rescriptExample: "let fullName = (user) => `${user.first} ${user.last}`",
    narrative: {
      celebrate: "Getters provide computed properties!",
      minimize: "But they look like field access while hiding computation.",
      better: "An explicit function makes the computation visible.",
      safety: "No hidden side effects — it's just a function call.",
    },
    glyphs: ["Notebook", "Compress"],
    tags: ["getter", "setter", "field", "function"],
    relatedPatterns: ["class-record"],
    learningObjectives: ["Replace getters with explicit functions"],
  },
  // --- StateMachines (2) ---
  {
    id: "state-string-variant",
    name: "State String to Variant",
    category: StateMachines,
    difficulty: Intermediate,
    jsPattern: "state\\s*===\\s*['\"]\\w+['\"]",
    confidence: 0.75,
    jsExample: "if (state === 'loading') { ... } else if (state === 'error') { ... }",
    rescriptExample: "switch state { | Loading => ... | Error(msg) => ... | Ready(data) => ... }",
    narrative: {
      celebrate: "Tracking state explicitly is good design!",
      minimize: "But string states can be misspelled and don't carry data.",
      better: "Variant states carry associated data and are exhaustively checked.",
      safety: "Error(msg) guarantees the message exists — no checking state AND error separately.",
    },
    glyphs: ["Masks", "Branch"],
    tags: ["state", "machine", "variant"],
    relatedPatterns: ["string-enum-variant"],
    learningObjectives: ["Model state machines with variants"],
  },
  {
    id: "reducer-switch",
    name: "Reducer to Variant Actions",
    category: StateMachines,
    difficulty: Advanced,
    jsPattern: "case\\s+['\"]\\w+['\"]:\\s*return",
    confidence: 0.70,
    jsExample: "case 'SET_USER': return { ...state, user: action.payload }",
    rescriptExample: "| SetUser(user) => { ...state, user: Some(user) }",
    narrative: {
      celebrate: "Reducers with action types are a proven pattern!",
      minimize: "But string action types need constants and the payload is untyped.",
      better: "Variant actions carry typed payloads — SetUser(user) is self-describing.",
      safety: "Add a new action variant and the compiler finds every unhandled case.",
    },
    glyphs: ["Branch", "Lock"],
    tags: ["reducer", "action", "state-machine"],
    relatedPatterns: ["state-string-variant"],
    learningObjectives: ["Use variant actions in reducers"],
  },
  // --- DataModeling (2) ---
  {
    id: "interface-type",
    name: "Interface to Type",
    category: DataModeling,
    difficulty: Beginner,
    jsPattern: "interface\\s+\\w+\\s*\\{",
    confidence: 0.80,
    jsExample: "interface User { name: string; age: number; email?: string }",
    rescriptExample: "type user = { name: string, age: int, email: option<string> }",
    narrative: {
      celebrate: "Interfaces define clear data contracts!",
      minimize: "But optional fields (?) become undefined at runtime.",
      better: "ReScript's option<string> makes optionality explicit and safe.",
      safety: "Accessing email requires handling the None case.",
    },
    glyphs: ["Notebook", "Target"],
    tags: ["interface", "type", "record"],
    relatedPatterns: ["tagged-union-variant"],
    learningObjectives: ["Define data types with explicit optionality"],
  },
  {
    id: "enum-poly-variant",
    name: "Enum to Polymorphic Variant",
    category: DataModeling,
    difficulty: Advanced,
    jsPattern: "enum\\s+\\w+\\s*\\{",
    confidence: 0.75,
    jsExample: "enum Color { Red = 'red', Green = 'green', Blue = 'blue' }",
    rescriptExample: "type color = [#red | #green | #blue]",
    narrative: {
      celebrate: "Enums are great for fixed sets of values!",
      minimize: "But TS enums compile to objects with runtime overhead.",
      better: "Polymorphic variants are zero-cost — they compile to plain strings.",
      safety: "Using an invalid colour is a compile error — no runtime check needed.",
    },
    glyphs: ["Masks", "Lightning"],
    tags: ["enum", "polymorphic", "variant"],
    relatedPatterns: ["string-enum-variant"],
    learningObjectives: ["Use polymorphic variants for string enums"],
  },
]

// ============================================================================
// Scanner — regex-based pattern matching against JS input
// ============================================================================

/// Scan JS code against a single pattern, returning matches.
let scanPattern = (code: string, pattern: evangeliserPattern): array<evangeliserMatch> => {
  let re = RegExp.fromString(pattern.jsPattern)
  let lines = code->String.split("\n")
  let matches = []
  lines->Array.forEachWithIndex((line, idx) => {
    if re->RegExp.test(line) {
      let _ = matches->Array.push({
        patternId: pattern.id,
        patternName: pattern.name,
        category: pattern.category,
        code: line->String.trim,
        startLine: idx + 1,
        endLine: idx + 1,
        confidence: pattern.confidence,
        jsExample: pattern.jsExample,
        rescriptExample: pattern.rescriptExample,
        narrative: pattern.narrative,
        glyphs: pattern.glyphs,
      })
    }
  })
  matches
}

/// Scan JS code against all patterns, applying constraints.
let scanCode = (
  code: string,
  patterns: array<evangeliserPattern>,
  constraints: evangeliserConstraints,
): evangeliserAnalysis => {
  let startTime = Date.now()

  // Filter patterns by constraints
  let activePatterns = patterns->Array.filter(p => {
    let catEnabled =
      constraints.enabledCategories->Array.length === 0 ||
        constraints.enabledCategories->Array.includes(p.category)
    let confOk = p.confidence >= constraints.minConfidence
    let diffOk = switch constraints.difficultyFilter {
    | None => true
    | Some(d) => p.difficulty === d
    }
    catEnabled && confOk && diffOk
  })

  // Run scanner
  let allMatches = activePatterns->Array.flatMap(p => scanPattern(code, p))

  // Cap results
  let capped = if Array.length(allMatches) > constraints.maxResults {
    allMatches->Array.slice(~start=0, ~end=constraints.maxResults)
  } else {
    allMatches
  }

  let elapsed = Date.now() -. startTime
  let totalLines = code->String.split("\n")->Array.length
  let matchedLines = capped->Array.map(m => m.startLine)->Array.length
  let coverage = if totalLines > 0 {
    Float.fromInt(matchedLines) /. Float.fromInt(totalLines) *. 100.0
  } else {
    0.0
  }

  // Determine overall difficulty
  let difficulty = if (
    capped->Array.some(m => {
      builtinPatterns
      ->Array.find(p => p.id === m.patternId)
      ->Option.map(p => p.difficulty === Advanced)
      ->Option.getOr(false)
    })
  ) {
    Advanced
  } else if (
    capped->Array.some(m => {
      builtinPatterns
      ->Array.find(p => p.id === m.patternId)
      ->Option.map(p => p.difficulty === Intermediate)
      ->Option.getOr(false)
    })
  ) {
    Intermediate
  } else {
    Beginner
  }

  {
    matches: capped,
    totalPatterns: Array.length(activePatterns),
    coveragePercentage: coverage,
    difficulty,
    analysisTime: elapsed,
  }
}

// ============================================================================
// Filtering and Stats
// ============================================================================

/// Filter patterns by category.
let filterByCategory = (
  patterns: array<evangeliserPattern>,
  cat: option<evangeliserCategory>,
): array<evangeliserPattern> => {
  switch cat {
  | None => patterns
  | Some(c) => patterns->Array.filter(p => p.category === c)
  }
}

/// Filter patterns by text search (name or tags).
let filterBySearch = (patterns: array<evangeliserPattern>, text: string): array<
  evangeliserPattern,
> => {
  if String.length(text) === 0 {
    patterns
  } else {
    let lower = text->String.toLowerCase
    patterns->Array.filter(p => {
      p.name->String.toLowerCase->String.includes(lower) ||
        p.tags->Array.some(t => t->String.toLowerCase->String.includes(lower))
    })
  }
}

/// Count patterns per category.
let categoryStats = (patterns: array<evangeliserPattern>): array<(evangeliserCategory, int)> => {
  allCategories->Array.map(cat => {
    let count = patterns->Array.filter(p => p.category === cat)->Array.length
    (cat, count)
  })
}

/// Count matches per category.
let matchCategoryStats = (matches: array<evangeliserMatch>): array<(evangeliserCategory, int)> => {
  allCategories->Array.filterMap(cat => {
    let count = matches->Array.filter(m => m.category === cat)->Array.length
    if count > 0 {
      Some((cat, count))
    } else {
      None
    }
  })
}

// ============================================================================
// Default State
// ============================================================================

let defaultConstraints: evangeliserConstraints = {
  enabledCategories: [], // Empty = all enabled
  minConfidence: 0.5,
  difficultyFilter: None,
  maxResults: 100,
}

let defaultState: evangeliserState = {
  constraints: defaultConstraints,
  jsInput: "",
  scanning: false,
  scanError: None,
  analysis: None,
  viewLayer: ViewRaw,
  patterns: builtinPatterns,
  glyphs: builtinGlyphs,
  activeTab: TabScan,
  filterText: "",
  selectedMatchIndex: None,
  legendExpanded: false,
  error: None,
}
