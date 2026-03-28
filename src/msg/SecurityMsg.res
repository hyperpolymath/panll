// SPDX-License-Identifier: PMPL-1.0-or-later

/// Security messages -- redaction, vault, 2FA, Trustfile (DD-026/027).

open Model

type securityMsg =
  /// Toggle a redaction pattern's enabled state.
  | TogglePattern(string)
  /// Add a custom redaction pattern.
  | AddPattern(redactionPattern)
  /// Remove a custom pattern.
  | RemovePattern(string)
  /// Set the redaction mode.
  | SetRedactionMode(redactionMode)
  /// Request text redaction via backend.
  | RedactText(string, string)
  /// Redaction result from backend.
  | RedactionResult(result<string, string>)
  /// Store a secret in the vault.
  | VaultStore(string, string)
  /// Vault store result.
  | VaultStoreResult(result<string, string>)
  /// Retrieve a secret from the vault.
  | VaultRetrieve(string)
  /// Vault retrieve result.
  | VaultRetrieveResult(result<string, string>)
  /// List vault keys.
  | VaultList
  /// Vault list result.
  | VaultListResult(result<string, string>)
  /// Submit TOTP code for 2FA.
  | SubmitTotp(string)
  /// 2FA verification result.
  | TotpResult(result<string, string>)
  /// Update TOTP input field.
  | SetTotpInput(string)
  /// Load Trustfile from repo.
  | LoadTrustfile(string)
  /// Trustfile loaded.
  | TrustfileLoaded(result<string, string>)
  /// Toggle shoulder-safe mode.
  | ToggleShoulderSafe
  /// Set security category tab.
  | SetSecurityCategory(securityCategory)
  /// Update new pattern form: label field.
  | SetNewPatternLabel(string)
  /// Update new pattern form: regex field.
  | SetNewPatternRegex(string)
  /// Submit the new pattern form.
  | SubmitNewPattern
  /// TypeLL cross-panel type check result for trustfile types.
  | TypeCheckResult(result<string, string>)
