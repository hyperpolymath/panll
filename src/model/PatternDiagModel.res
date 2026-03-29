// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — Pattern Diagnostics Model (Layer 3)
///
/// Types for pattern detection, anti-pattern flagging, and developer gamification.
/// Layer 3 sits on top of the timeline (Layer 2) and provenance (Layer 1) to
/// detect recurring patterns in how code evolves: repeated fixes in the same file,
/// cyclic refactoring, growing TODO counts, AI-generated code without review, etc.
///
/// The gamification component turns pattern signals into developer XP, badges, and
/// streaks — positive reinforcement for good practices (reviewing AI code, closing
/// TODOs, reducing findings) rather than punitive scoring.
///
/// DESIGN NOTE: Patterns are detected from timeline snapshots, not real-time.
/// This is deliberate — real-time pattern detection creates cognitive overhead
/// and false positives. The dashboard updates at commit boundaries, giving the
/// developer a clear point to check their progress.

// ===========================================================================
// Pattern Types
// ===========================================================================

/// A detected code pattern — either a positive practice or an anti-pattern.
/// Patterns are derived from timeline data (Layer 2) and provenance (Layer 1).
type patternKind =
  /// Positive: AI code was reviewed within N commits.
  | ReviewedAiCode
  /// Positive: TODO count decreased.
  | TodoReduction
  /// Positive: Security findings decreased.
  | FindingsReduction
  /// Positive: Type check failures resolved.
  | TypeCheckCleanup
  /// Anti-pattern: Same file modified in N consecutive fix commits.
  | HotspotChurn(string)
  /// Anti-pattern: TODO count growing for >7 snapshots.
  | TodoCreep
  /// Anti-pattern: AI attribution rising without corresponding reviews.
  | UnreviewedAiGrowth
  /// Anti-pattern: Vexometer reading sustained above threshold.
  | SustainedFriction
  /// Anti-pattern: Library count growing faster than code.
  | DependencyBloat
  /// Custom pattern from K9 validators or user-defined rules.
  | CustomPattern(string)

/// Severity of a detected pattern.
type patternSeverity =
  | Celebration  // Positive pattern — show confetti/badge
  | Info         // Neutral observation
  | Advisory     // Worth noting, not urgent
  | Warning      // Should address soon
  | Critical     // Structural problem, address now

/// A single detected pattern instance with evidence.
type patternInstance = {
  /// Unique ID for this pattern detection.
  id: string,
  /// What kind of pattern was detected.
  kind: patternKind,
  /// Severity assessment.
  severity: patternSeverity,
  /// Human-readable description of the pattern.
  description: string,
  /// File(s) involved (empty for codebase-wide patterns).
  files: array<string>,
  /// Timestamp when detected (ISO 8601).
  detectedAt: string,
  /// Commit hash range this pattern spans.
  commitRange: option<(string, string)>,
  /// Whether the developer has acknowledged/dismissed this pattern.
  acknowledged: bool,
}

// ===========================================================================
// Gamification Types
// ===========================================================================

/// Developer XP categories — separate tracks for different good practices.
type xpCategory =
  | CodeReview     // Reviewing AI-generated code
  | Housekeeping   // Closing TODOs, FIXMEs
  | Security       // Reducing panic-attack findings
  | TypeSafety     // Resolving type check failures
  | Documentation  // Adding/updating docs and tags
  | Streaks        // Consecutive days of good practice

/// A badge earned through consistent good practice.
type rec badge = {
  /// Badge identifier.
  id: string,
  /// Display name.
  name: string,
  /// Description of what was achieved.
  description: string,
  /// XP category this badge belongs to.
  category: xpCategory,
  /// When the badge was earned (ISO 8601).
  earnedAt: string,
  /// Tier (Bronze, Silver, Gold, Diamond).
  tier: badgeTier,
}

/// Badge tier — progressive recognition.
and badgeTier =
  | Bronze   // First achievement
  | Silver   // Sustained practice (7 days)
  | Gold     // Expert level (30 days)
  | Diamond  // Mastery (90 days)

/// A streak — consecutive positive actions.
type streak = {
  /// What the streak tracks.
  category: xpCategory,
  /// Current consecutive count.
  current: int,
  /// All-time best.
  best: int,
  /// Date the current streak started (ISO 8601).
  startedAt: string,
}

/// Developer profile for gamification — accumulated over time.
type developerProfile = {
  /// XP totals per category.
  xp: array<(xpCategory, int)>,
  /// Total XP across all categories.
  totalXp: int,
  /// Earned badges.
  badges: array<badge>,
  /// Active streaks.
  streaks: array<streak>,
  /// Current level (derived from totalXp).
  level: int,
}

// ===========================================================================
// State
// ===========================================================================

/// Pattern diagnostics state — included in the main Model.
type patternDiagState = {
  /// All detected patterns (most recent first).
  patterns: array<patternInstance>,
  /// Developer gamification profile.
  profile: developerProfile,
  /// Whether the pattern diagnostics panel is expanded.
  expanded: bool,
  /// Filter: show only patterns of this severity or higher.
  minSeverity: patternSeverity,
  /// Filter: show only patterns in these categories.
  activeCategories: array<xpCategory>,
  /// Whether gamification features are enabled (user can opt out).
  gamificationEnabled: bool,
  /// Last analysis timestamp.
  lastAnalysis: option<string>,
}

/// Initial empty state.
let init: patternDiagState = {
  patterns: [],
  profile: {
    xp: [],
    totalXp: 0,
    badges: [],
    streaks: [],
    level: 1,
  },
  expanded: false,
  minSeverity: Info,
  activeCategories: [],
  gamificationEnabled: true,
  lastAnalysis: None,
}
