// SPDX-License-Identifier: MPL-2.0

/// TypeLL verification kernel messages.

open Model

type typellMsg =
  /// Set the active category tab.
  | SetTlCategory(typellCategory)
  /// Set the view layer (progressive disclosure level).
  | SetViewLayer(viewLayer)
  /// Check TypeLL server health.
  | CheckTlHealth
  /// Health check result.
  | TlHealthResult(result<string, string>)
  /// Update checker input.
  | UpdateCheckerInput(string)
  /// Run type check on current input.
  | RunCheck
  /// Type check result.
  | CheckResult(result<string, string>)
  /// Run type inference on current input.
  | RunInfer
  /// Type inference result.
  | InferResult(result<string, string>)
  /// Load signatures from server.
  | LoadSignatures
  /// Signatures loaded.
  | SignaturesLoaded(result<string, string>)
  /// Load universe hierarchy.
  | LoadUniverses
  /// Universes loaded.
  | UniversesLoaded(result<string, string>)
  /// Set signature search filter.
  | SetSignatureFilter(string)
  /// Set tier filter.
  | SetTierFilter(option<typeTier>)
  /// Update refinement spec.
  | UpdateRefinementSpec(string)
  /// Update refinement constraints.
  | UpdateRefinementConstraints(string)
  /// Run refinement.
  | RunRefine
  /// Refinement result.
  | RefineResult(result<string, string>)
  /// Toggle BoJ routing for TypeLL operations (nesy-mcp cartridge).
  | ToggleTypellBojRouting
  /// Set the default type discipline for modules without a declaration.
  | SetDefaultDiscipline(typeDiscipline)
  /// Add or update a module-level discipline declaration.
  | SetModuleDiscipline(string, typeDiscipline) // (scope, discipline)
  /// Remove a module-level discipline declaration (revert to default).
  | RemoveModuleDiscipline(string) // scope
