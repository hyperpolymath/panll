// SPDX-License-Identifier: PMPL-1.0-or-later

/// K9 contractile messages -- loading, validation, and layout application.

type k9Msg =
  /// Load a K9 contractile file.
  | LoadContractile(string)
  /// Contractile loaded result.
  | ContractileLoaded(result<string, string>)
  /// Validate a contractile file.
  | ValidateContractile(string)
  /// Validation result.
  | ContractileValidated(result<string, string>)
  /// Apply a K9 layout by name.
  | ApplyLayout(string)
  /// Layout application result.
  | LayoutApplied(result<string, string>)
  /// TypeLL cross-panel type check result for K9 contractile types.
  | TypeCheckResult(result<string, string>)
