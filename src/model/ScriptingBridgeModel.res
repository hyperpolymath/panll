// SPDX-License-Identifier: MPL-2.0

/// PanLL Scripting Bridge Model — connects VM scripting to IDApTIK game
/// development. Bridges PanLL's VM inspector with a scripting REPL,
/// instruction constraint verification, and script analysis reasoning.
///
/// Three-panel model (L/N/W):
///   L: VM instruction constraints, opcode rules, tier restrictions
///   N: Script analysis reasoning about correctness and performance
///   W: VM scripting REPL with saved scripts and execution history
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Scripting Bridge panel.
type scriptingBridgeTab =
  /// Repl — interactive VM scripting REPL.
  | Repl
  /// Instructions — browse VM instruction set with constraints.
  | Instructions
  /// Scripts — manage saved scripts.
  | Scripts
  /// Analysis — script analysis reasoning and optimisation.
  | Analysis

// ============================================================================
// REPL Domain
// ============================================================================

/// A single REPL interaction (input and output pair).
type scriptReplEntry = {
  /// The script input entered by the user.
  input: string,
  /// The output produced by the VM.
  output: string,
  /// Timestamp when this entry was executed (milliseconds since epoch).
  timestamp: float,
  /// Whether execution succeeded without error.
  success: bool,
}

// ============================================================================
// VM Instruction Set
// ============================================================================

/// Instruction tier — categorises opcodes by privilege level.
/// Higher tiers require explicit authorisation in the game scripting sandbox.
type instructionTier =
  /// Tier 0 — safe, pure computation (arithmetic, comparisons).
  | TierSafe
  /// Tier 1 — controlled side effects (game state reads).
  | TierControlled
  /// Tier 2 — privileged operations (game state writes, spawning).
  | TierPrivileged
  /// Tier 3 — system-level operations (file I/O, network, debug).
  | TierSystem

/// A VM instruction (opcode) with its metadata and constraints.
type instruction = {
  /// Numeric opcode value.
  opcode: int,
  /// Mnemonic name (e.g., "PUSH", "CALL", "SPAWN_ENTITY").
  name: string,
  /// Human-readable description of what this instruction does.
  description: string,
  /// Privilege tier of this instruction.
  tier: instructionTier,
  /// Stack effect notation (e.g., "( a b -- a+b )").
  stackEffect: string,
  /// Whether this instruction is allowed in the current sandbox context.
  allowed: bool,
}

// ============================================================================
// Saved Scripts
// ============================================================================

/// A saved VM script stored for reuse.
type savedScript = {
  /// Unique script identifier.
  id: string,
  /// Human-readable script name.
  name: string,
  /// The script source code.
  code: string,
  /// Timestamp when the script was created (milliseconds since epoch).
  createdAt: float,
  /// Timestamp of last modification (milliseconds since epoch).
  updatedAt: float,
  /// Brief description of the script's purpose.
  description: string,
}

// ============================================================================
// Script Analysis
// ============================================================================

/// Severity of a script analysis finding.
type analysisSeverity =
  /// Error — script will not execute correctly.
  | AnalysisError
  /// Warning — script may have unintended behaviour.
  | AnalysisWarning
  /// Info — informational suggestion for improvement.
  | AnalysisInfo
  /// Optimisation — performance improvement opportunity.
  | AnalysisOptimisation

/// A finding from script analysis reasoning.
type analysisFinding = {
  /// Unique finding identifier.
  id: string,
  /// Line number in the script (1-based).
  line: int,
  /// Severity of this finding.
  severity: analysisSeverity,
  /// Short summary of the finding.
  summary: string,
  /// Detailed explanation and suggested fix.
  detail: string,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Scripting Bridge panel.
type scriptingBridgeState = {
  /// Active tab within the Scripting Bridge panel.
  activeTab: scriptingBridgeTab,
  /// REPL interaction history (oldest first).
  replHistory: array<scriptReplEntry>,
  /// VM instruction set catalogue.
  instructions: array<instruction>,
  /// Saved scripts library.
  savedScripts: array<savedScript>,
  /// Currently selected script for editing or execution.
  selectedScript: option<string>,
  /// Whether a script is currently executing.
  executing: bool,
  /// Current REPL input buffer.
  replInput: string,
  /// Analysis findings for the current script.
  analysisFindings: array<analysisFinding>,
  /// Error from the last operation.
  error: option<string>,
}
