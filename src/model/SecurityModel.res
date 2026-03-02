// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Security Model — types for secrets redaction, vault integration,
/// 2FA authentication, and Trustfile enforcement (DD-026, DD-027).
///
/// The security layer handles:
/// - Secret detection and redaction (on share, save, display)
/// - Vault integration via reasonably-good-tool CLI
/// - TOTP-based 2FA for sensitive operations
/// - Trustfile.a2ml-driven security policy enforcement
/// - Shoulder-surfing safe mode
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Redaction
// ============================================================================

/// When to apply secret redaction.
type redactionMode =
  | RedactOnShare
  | RedactOnSave
  | RedactOnDisplay
  | RedactAlways

/// A pattern used to detect secrets in panel content.
type redactionPattern = {
  /// Unique identifier.
  id: string,
  /// Human-readable label (e.g., "API Key", "Password", "Private Key").
  label: string,
  /// Regular expression pattern string.
  pattern: string,
  /// Whether this pattern is enabled.
  enabled: bool,
  /// Whether this is a built-in pattern (vs user-defined).
  builtIn: bool,
}

/// A detected secret in panel content.
type detectedSecret = {
  /// Which pattern matched.
  patternId: string,
  /// The panel where the secret was found.
  panelId: string,
  /// Character offset in the panel content.
  offset: int,
  /// Length of the matched secret.
  length: int,
  /// Redacted placeholder text (e.g., "[REDACTED:api-key]").
  placeholder: string,
}

// ============================================================================
// Vault
// ============================================================================

/// Status of the vault connection (reasonably-good-tool CLI).
type vaultStatus =
  | VaultLocked
  | VaultUnlocked
  | VaultUnavailable
  | VaultError(string)

/// A vault entry (key only — values are never stored in frontend state).
type vaultKey = {
  /// The secret key name.
  key: string,
  /// Human-readable description.
  description: string,
  /// When this key was last updated.
  lastUpdated: float,
}

// ============================================================================
// 2FA Authentication
// ============================================================================

/// Status of the 2FA session.
type twoFactorStatus =
  | TwoFactorNotConfigured
  | TwoFactorConfigured
  | TwoFactorAuthenticated(float)  // authenticated until timestamp
  | TwoFactorExpired

/// Which operations require 2FA (configured via Trustfile).
type twoFactorRequirement = {
  /// Operation name (e.g., "vault-access", "panel-sharing", "export").
  operation: string,
  /// Whether 2FA is required for this operation.
  required: bool,
}

// ============================================================================
// Trustfile
// ============================================================================

/// Security level defined in the Trustfile.
type securityLevel =
  | SecurityLow
  | SecurityMedium
  | SecurityHigh
  | SecurityMaximum

/// Sharing permission level.
type sharingPermission =
  | ViewOnly
  | EditWithApproval
  | FullEdit

/// Parsed Trustfile policy. This drives the entire security enforcement layer.
type trustfilePolicy = {
  /// Security level from the Trustfile.
  securityLevel: securityLevel,
  /// Redaction mode.
  redactionMode: redactionMode,
  /// Custom redaction patterns from the Trustfile.
  customPatterns: array<redactionPattern>,
  /// 2FA requirements per operation.
  twoFactorRequirements: array<twoFactorRequirement>,
  /// Default sharing permission.
  defaultSharingPermission: sharingPermission,
  /// Whether sharing requires approval.
  requireApproval: bool,
  /// Whether the Trustfile was successfully loaded.
  loaded: bool,
  /// Path to the loaded Trustfile.
  filePath: option<string>,
}

// ============================================================================
// Security State
// ============================================================================

/// Active category tab in the Security panel.
type securityCategory =
  | SecurityOverview
  | SecurityRedaction
  | SecurityVault
  | SecurityAuth
  | SecurityTrustfile
  | SecurityShoulderSafe

/// Root state for the security system.
type securityState = {
  /// Redaction patterns (built-in + custom).
  patterns: array<redactionPattern>,
  /// Currently detected secrets across all panels.
  detectedSecrets: array<detectedSecret>,
  /// Active redaction mode.
  redactionMode: redactionMode,
  /// Vault connection status.
  vaultStatus: vaultStatus,
  /// Known vault keys (names only, not values).
  vaultKeys: array<vaultKey>,
  /// 2FA session status.
  twoFactorStatus: twoFactorStatus,
  /// 2FA session timeout in seconds (default: 3600 = 1 hour).
  twoFactorTimeout: int,
  /// Loaded Trustfile policy (if any).
  trustfile: option<trustfilePolicy>,
  /// Whether shoulder-surfing safe mode is active (blurs secrets in real-time).
  shoulderSafe: bool,
  /// Active category tab.
  activeCategory: securityCategory,
  /// 2FA TOTP input field.
  totpInput: string,
  /// Error from the last security operation.
  error: option<string>,
}
