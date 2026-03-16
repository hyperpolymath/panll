// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Reasoning Mode Selector Model — types for neural-symbolic
/// reasoning strategy selection.
///
/// Provides 6 reasoning modes spanning pure symbolic through pure neural,
/// with hybrid combinations. Each mode has metadata describing which
/// subsystems are active.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Reasoning Modes
// ============================================================================

/// Available neural-symbolic reasoning modes.
type reasoningMode =
  /// Pure symbolic reasoning — formal proofs only, no neural.
  | PureSymbolic
  /// Symbolic-first hybrid — try symbolic proof, fall back to neural.
  | SymbolicFirst
  /// Balanced hybrid — run both subsystems, harmonize results.
  | Balanced
  /// Neural-first hybrid — try neural, verify with symbolic.
  | NeuralFirst
  /// Pure neural reasoning — neural model only, no symbolic.
  | PureNeural
  /// Adaptive — dynamically selects mode based on input characteristics.
  | Adaptive

// ============================================================================
// Mode Metadata
// ============================================================================

/// Metadata describing a reasoning mode's capabilities and subsystem usage.
type modeInfo = {
  /// The reasoning mode this info describes.
  mode: reasoningMode,
  /// Whether this mode uses the symbolic reasoning subsystem.
  usesSymbolic: bool,
  /// Whether this mode uses the neural reasoning subsystem.
  usesNeural: bool,
  /// Whether this mode is a hybrid of both subsystems.
  isHybrid: bool,
  /// Human-readable display name for the mode.
  displayName: string,
  /// Short description of how this mode operates.
  description: string,
}

// ============================================================================
// Panel State
// ============================================================================

/// Top-level state for the NeSy Reasoning Mode Selector panel.
type nesyModesState = {
  /// Currently active reasoning mode.
  activeMode: reasoningMode,
  /// All available modes with their metadata.
  availableModes: array<modeInfo>,
  /// Whether a mode change is in progress (loading indicator).
  switching: bool,
  /// Error message from the last failed mode switch, if any.
  lastError: option<string>,
}
