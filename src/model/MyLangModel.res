// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL My-Lang Model — types for the AI-native language panel.
///
/// My-lang is an AI-native language with 4 dialects: Solo (systems),
/// Duet (AI-assisted), Ensemble (AI-native), Me (personal agent).
/// It compiles to LLVM IR → native binaries and has a REPL, LSP,
/// and package manager.
///
/// This panel provides a code editor, compilation output, REPL
/// interaction, and dialect switching.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// My-lang dialect.
type myLangDialect =
  /// Dependable foundation for systems programming.
  | Solo
  /// AI-assisted development with verification.
  | Duet
  /// AI as first-class native component.
  | Ensemble
  /// Personal AI agent dialect.
  | Me

/// Compilation result from the my-lang compiler.
type compilationResult = {
  /// Whether compilation succeeded.
  success: bool,
  /// Compiler output (stdout).
  output: string,
  /// Compiler errors/warnings (stderr).
  diagnostics: string,
  /// Number of errors.
  errorCount: int,
  /// Number of warnings.
  warningCount: int,
  /// Compilation time in milliseconds.
  compileTimeMs: int,
}

/// REPL interaction — a single input/output pair.
type replEntry = {
  /// User input line.
  input: string,
  /// REPL output.
  output: string,
  /// Whether the output is an error.
  isError: bool,
}

/// Category tabs for the My-Lang panel.
type myLangCategory =
  /// Code editor with syntax highlighting.
  | MlEditor
  /// REPL interaction.
  | MlRepl
  /// Compilation output.
  | MlCompile
  /// Dialect reference and comparison.
  | MlDialects

/// Root state for the My-Lang panel.
type myLangState = {
  /// Whether the my-lang CLI binary is available.
  cliAvailable: bool,
  /// Whether an operation is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Active category tab.
  activeCategory: myLangCategory,
  /// Active dialect.
  activeDialect: myLangDialect,
  /// Editor content.
  editorContent: string,
  /// REPL input line.
  replInput: string,
  /// REPL history (most recent last).
  replHistory: array<replEntry>,
  /// Most recent compilation result.
  lastCompilation: option<compilationResult>,
}
