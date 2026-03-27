// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Evangeliser Model Types — JS-to-ReScript code transformation teaching tool.
///
/// State types for the ReScript Evangeliser panel. The evangeliser scans JavaScript
/// code, detects patterns, and shows encouraging "Celebrate good, minimize bad,
/// show better" narratives with Makaton-inspired glyphs.
///
/// Three-panel model:
///   Panel-L -> Pattern constraints (which JS patterns to detect, confidence
///              thresholds, difficulty filters, category selection)
///   Panel-N -> Narrative reasoning (celebrate/minimize/better agent reasoning,
///              glyph annotations, learning progress tracking)
///   Panel-W -> Transformation results (JS→ReScript side-by-side with glyphs,
///              pattern match highlights, coverage stats)
///
/// This module has NO dependencies on other PanLL modules — leaf of the
/// type dependency graph, following the same pattern as StapelnModel.

// ============================================================================
// Pattern Categories — what the evangeliser can detect in JS code
// ============================================================================

/// Categories of JS→ReScript transformation patterns.
type evangeliserCategory =
  | NullSafety
  | Async
  | ErrorHandling
  | ArrayOperations
  | Conditionals
  | Destructuring
  | Defaults
  | Functional
  | Templates
  | ArrowFunctions
  | Variants
  | Modules
  | TypeSafety
  | Immutability
  | PatternMatching
  | PipeOperator
  | OopToFp
  | ClassesToRecords
  | InheritanceToComposition
  | StateMachines
  | DataModeling

/// Difficulty levels for patterns — filters what gets shown.
type evangeliserDifficulty =
  | Beginner
  | Intermediate
  | Advanced

/// View layer selection for result rendering.
type evangeliserViewLayer =
  | ViewRaw // Side-by-side JS/ReScript
  | ViewFolded // Grouped by category, collapsible
  | ViewGlyphed // With Makaton glyph annotations
  | ViewWysiwyg // Rich editor preview (future)

/// Semantic category for glyphs.
type evangeliserSemanticCategory =
  | Transformation
  | Safety
  | Flow
  | Structure
  | State
  | Data

// ============================================================================
// Glyph System — Makaton-inspired semantic symbols
// ============================================================================

/// A Makaton-inspired glyph that represents semantic meaning beyond syntax.
type evangeliserGlyph = {
  symbol: string,
  name: string,
  meaning: string,
  semanticCategory: evangeliserSemanticCategory,
}

// ============================================================================
// Narrative System — "Celebrate good, minimize bad, show better"
// ============================================================================

/// A narrative encouraging the JS→ReScript transformation.
type evangeliserNarrative = {
  celebrate: string, // What the JS code does well
  minimize: string, // Gently acknowledge limitations
  better: string, // How ReScript improves it
  safety: string, // Type-level guarantees gained
}

// ============================================================================
// Pattern Definition and Matching
// ============================================================================

/// A transformation pattern from JavaScript to ReScript.
type evangeliserPattern = {
  id: string,
  name: string,
  category: evangeliserCategory,
  difficulty: evangeliserDifficulty,
  jsPattern: string, // Regex to detect in JS
  confidence: float, // Base confidence 0.0-1.0
  jsExample: string, // Example JS code
  rescriptExample: string, // Equivalent ReScript
  narrative: evangeliserNarrative,
  glyphs: array<string>, // Glyph keys to display
  tags: array<string>,
  relatedPatterns: array<string>,
  learningObjectives: array<string>,
}

/// A matched pattern found in user's JS code.
type evangeliserMatch = {
  patternId: string,
  patternName: string,
  category: evangeliserCategory,
  code: string, // Matched JS snippet
  startLine: int,
  endLine: int,
  confidence: float,
  jsExample: string,
  rescriptExample: string,
  narrative: evangeliserNarrative,
  glyphs: array<string>,
}

// ============================================================================
// Analysis Results — Panel-W output
// ============================================================================

/// Analysis result for scanned JS code.
type evangeliserAnalysis = {
  matches: array<evangeliserMatch>,
  totalPatterns: int,
  coveragePercentage: float,
  difficulty: evangeliserDifficulty,
  analysisTime: float,
}

// ============================================================================
// Panel-L Constraints — what to scan for
// ============================================================================

/// Constraints controlling which patterns the scanner applies.
type evangeliserConstraints = {
  enabledCategories: array<evangeliserCategory>,
  minConfidence: float, // 0.0-1.0, default 0.5
  difficultyFilter: option<evangeliserDifficulty>,
  maxResults: int, // Cap on matches shown
}

// ============================================================================
// UI Tab Navigation
// ============================================================================

/// Active tab in the evangeliser panel.
type evangeliserTab =
  | TabScan // Input JS code and run scan
  | TabPatterns // Browse the pattern library
  | TabResults // View analysis results
  | TabLegend // Glyph legend

// ============================================================================
// Evangeliser Panel State — the top-level state record
// ============================================================================

/// The complete Evangeliser panel state, stored as a sub-record in the main model.
type evangeliserState = {
  // Panel-L: Constraints
  constraints: evangeliserConstraints,
  // Panel-N: Code input and scanning
  jsInput: string, // JS code to scan
  scanning: bool, // Whether a scan is in progress
  scanError: option<string>,
  // Panel-W: Results
  analysis: option<evangeliserAnalysis>,
  viewLayer: evangeliserViewLayer,
  // Pattern library (populated at init)
  patterns: array<evangeliserPattern>,
  glyphs: array<evangeliserGlyph>,
  // UI state
  activeTab: evangeliserTab,
  filterText: string,
  selectedMatchIndex: option<int>, // Which match is selected in results
  legendExpanded: bool,
  error: option<string>,
}
