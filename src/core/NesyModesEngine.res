// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Modes Engine — pure helpers for the reasoning mode selector
/// panel.
///
/// All functions are pure (no side effects). Provides mode metadata,
/// display labels, subsystem indicators, and the full mode catalogue.

open NesyModesModel

// ============================================================================
// Subsystem Indicators
// ============================================================================

/// Whether a reasoning mode uses the symbolic subsystem.
let modeUsesSymbolic = (mode: reasoningMode): bool => {
  switch mode {
  | PureSymbolic => true
  | SymbolicFirst => true
  | Balanced => true
  | NeuralFirst => true
  | PureNeural => false
  | Adaptive => true
  }
}

/// Whether a reasoning mode uses the neural subsystem.
let modeUsesNeural = (mode: reasoningMode): bool => {
  switch mode {
  | PureSymbolic => false
  | SymbolicFirst => true
  | Balanced => true
  | NeuralFirst => true
  | PureNeural => true
  | Adaptive => true
  }
}

/// Whether a reasoning mode is a hybrid of both subsystems.
let modeIsHybrid = (mode: reasoningMode): bool => {
  modeUsesSymbolic(mode) && modeUsesNeural(mode)
}

// ============================================================================
// Display Labels and Descriptions
// ============================================================================

/// Human-readable display name for a reasoning mode.
let modeDisplayName = (mode: reasoningMode): string => {
  switch mode {
  | PureSymbolic => "Pure Symbolic"
  | SymbolicFirst => "Symbolic First"
  | Balanced => "Balanced"
  | NeuralFirst => "Neural First"
  | PureNeural => "Pure Neural"
  | Adaptive => "Adaptive"
  }
}

/// Short description of how a reasoning mode operates.
let modeDescription = (mode: reasoningMode): string => {
  switch mode {
  | PureSymbolic => "Formal proofs only. No neural inference. Maximum safety, minimum flexibility."
  | SymbolicFirst => "Try symbolic proof first, fall back to neural if no proof found."
  | Balanced => "Run both subsystems in parallel, harmonize results for best coverage."
  | NeuralFirst => "Neural inference first, verify with symbolic proof when possible."
  | PureNeural => "Neural model only. No symbolic verification. Maximum speed, minimum safety."
  | Adaptive => "Dynamically selects the best mode based on input characteristics."
  }
}

/// Icon identifier for a reasoning mode (Lucide icon name).
let modeIcon = (mode: reasoningMode): string => {
  switch mode {
  | PureSymbolic => "book-open"
  | SymbolicFirst => "shield-check"
  | Balanced => "scale"
  | NeuralFirst => "brain"
  | PureNeural => "zap"
  | Adaptive => "refresh-cw"
  }
}

// ============================================================================
// Colour Mappings
// ============================================================================

/// Tailwind border colour class for a reasoning mode card.
let modeBorderColor = (mode: reasoningMode, isActive: bool): string => {
  if isActive {
    "border-emerald-500 ring-2 ring-emerald-500/30"
  } else {
    switch mode {
    | PureSymbolic => "border-blue-500/40"
    | SymbolicFirst => "border-cyan-500/40"
    | Balanced => "border-purple-500/40"
    | NeuralFirst => "border-amber-500/40"
    | PureNeural => "border-red-500/40"
    | Adaptive => "border-gray-500/40"
    }
  }
}

/// Tailwind background colour class for a reasoning mode card.
let modeBgColor = (mode: reasoningMode): string => {
  switch mode {
  | PureSymbolic => "bg-blue-900/20"
  | SymbolicFirst => "bg-cyan-900/20"
  | Balanced => "bg-purple-900/20"
  | NeuralFirst => "bg-amber-900/20"
  | PureNeural => "bg-red-900/20"
  | Adaptive => "bg-gray-900/20"
  }
}

// ============================================================================
// Mode Catalogue
// ============================================================================

/// Build a modeInfo record for a given reasoning mode.
let buildModeInfo = (mode: reasoningMode): modeInfo => {
  {
    mode,
    usesSymbolic: modeUsesSymbolic(mode),
    usesNeural: modeUsesNeural(mode),
    isHybrid: modeIsHybrid(mode),
    displayName: modeDisplayName(mode),
    description: modeDescription(mode),
  }
}

/// All 6 reasoning modes with their metadata.
let allModes: array<modeInfo> = [
  buildModeInfo(PureSymbolic),
  buildModeInfo(SymbolicFirst),
  buildModeInfo(Balanced),
  buildModeInfo(NeuralFirst),
  buildModeInfo(PureNeural),
  buildModeInfo(Adaptive),
]

// ============================================================================
// Initial State
// ============================================================================

/// Default initial state for the NeSy Reasoning Mode Selector.
let init: nesyModesState = {
  activeMode: Balanced,
  availableModes: allModes,
  switching: false,
  lastError: None,
}
