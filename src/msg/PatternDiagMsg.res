// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — Pattern Diagnostics Messages (Layer 3)

open PatternDiagModel

/// Messages for the pattern diagnostics panel.
type patternDiagMsg =
  /// Run all pattern detectors against the current timeline.
  | AnalysePatterns
  /// Pattern analysis completed with results.
  | PatternsDetected(array<patternInstance>)
  /// Acknowledge/dismiss a specific pattern.
  | AcknowledgePattern(string)
  /// Toggle the expanded state of the panel.
  | TogglePatternPanel
  /// Change the minimum severity filter.
  | SetMinPatternSeverity(patternSeverity)
  /// Toggle gamification on/off.
  | ToggleGamification
  /// Reset gamification profile (requires confirmation).
  | ResetProfile
