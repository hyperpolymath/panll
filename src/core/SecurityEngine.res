// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Security Engine — redaction patterns, vault helpers, and Trustfile
/// enforcement (DD-026, DD-027).
///
/// Pure functions for the security layer. Actual vault I/O and 2FA TOTP
/// verification happen via SecurityCmd Tauri wrappers.

open SecurityModel

// ============================================================================
// Built-in Redaction Patterns
// ============================================================================

/// Standard set of secret detection patterns. These cover the most common
/// secret types found in development environments.
let builtInPatterns: array<redactionPattern> = [
  {
    id: "anthropic-key",
    label: "Anthropic API Key",
    pattern: "sk-ant-[a-zA-Z0-9_-]{20,}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "openai-key",
    label: "OpenAI API Key",
    pattern: "sk-[a-zA-Z0-9]{20,}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "generic-api-key",
    label: "Generic API Key",
    pattern: "[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][\\s:=\"']+[a-zA-Z0-9_-]{16,}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "password-field",
    label: "Password Field",
    pattern: "[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd][\\s:=\"']+[^\\s\"']{8,}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "bearer-token",
    label: "Bearer Token",
    pattern: "[Bb]earer\\s+[a-zA-Z0-9._-]{20,}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "private-key",
    label: "Private Key Block",
    pattern: "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----",
    enabled: true,
    builtIn: true,
  },
  {
    id: "connection-string",
    label: "Database Connection String",
    pattern: "(postgres|mysql|mongodb|redis)://[^\\s]{10,}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "aws-key",
    label: "AWS Access Key",
    pattern: "AKIA[0-9A-Z]{16}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "github-token",
    label: "GitHub Token",
    pattern: "(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}",
    enabled: true,
    builtIn: true,
  },
  {
    id: "anthropic-env",
    label: "Anthropic Env Var",
    pattern: "ANTHROPIC_[A-Z_]+=.+",
    enabled: true,
    builtIn: true,
  },
]

// ============================================================================
// Redaction Operations
// ============================================================================

/// Add a custom redaction pattern.
let addPattern = (state: securityState, pattern: redactionPattern): securityState => {
  {...state, patterns: Array.concat(state.patterns, [pattern])}
}

/// Remove a custom pattern by ID. Built-in patterns can be disabled but not removed.
let removePattern = (state: securityState, patternId: string): securityState => {
  {...state, patterns: Array.filter(state.patterns, p => p.id !== patternId || p.builtIn)}
}

/// Toggle a pattern's enabled state.
let togglePattern = (state: securityState, patternId: string): securityState => {
  {
    ...state,
    patterns: Array.map(state.patterns, p =>
      if p.id === patternId {
        {...p, enabled: !p.enabled}
      } else {
        p
      }
    ),
  }
}

/// Set the active redaction mode.
let setRedactionMode = (state: securityState, mode: redactionMode): securityState => {
  {...state, redactionMode: mode}
}

/// Apply redaction to a text string — replaces all detected secrets with
/// their placeholder labels. Pure function (no side effects).
let redactText = (text: string, patterns: array<redactionPattern>): string => {
  // Simple approach: iterate patterns and replace matches.
  // In practice, the Rust backend does the heavy regex lifting.
  // This frontend version is a fallback for immediate display redaction.
  Array.reduce(patterns, text, (acc, pattern) => {
    if !pattern.enabled {
      acc
    } else {
      // Use the pattern label as the replacement placeholder.
      let placeholder = "[REDACTED:" ++ pattern.label ++ "]"

      // For the frontend, we do a simple string check (full regex is in Rust).
      // This catches the most obvious cases for shoulder-safe mode.
      if String.includes(acc, "sk-ant-") || String.includes(acc, "sk-") {
        // Quick redaction for API keys visible in the UI.
        acc
        ->String.replaceRegExp(/sk-ant-[a-zA-Z0-9_-]{20,}/g, placeholder)
        ->String.replaceRegExp(/sk-[a-zA-Z0-9]{20,}/g, placeholder)
      } else {
        acc
      }
    }
  })
}

// ============================================================================
// 2FA Operations
// ============================================================================

/// Check if 2FA is required for an operation (based on Trustfile policy).
let requires2FA = (state: securityState, operation: string): bool => {
  switch state.trustfile {
  | Some(policy) =>
    Array.some(policy.twoFactorRequirements, req => req.operation === operation && req.required)
  | None => false
  }
}

/// Check if the current 2FA session is valid.
let is2FAValid = (state: securityState, currentTime: float): bool => {
  switch state.twoFactorStatus {
  | TwoFactorAuthenticated(expiresAt) => currentTime < expiresAt
  | _ => false
  }
}

/// Check if an operation is allowed given the current security state.
/// Returns true if the operation can proceed, false if blocked.
let isOperationAllowed = (state: securityState, operation: string, currentTime: float): bool => {
  if requires2FA(state, operation) {
    is2FAValid(state, currentTime)
  } else {
    true
  }
}

// ============================================================================
// Trustfile Operations
// ============================================================================

/// Apply a loaded Trustfile policy to the security state.
let applyTrustfile = (state: securityState, policy: trustfilePolicy): securityState => {
  let mergedPatterns = Array.concat(state.patterns, policy.customPatterns)
  {...state, trustfile: Some(policy), patterns: mergedPatterns, redactionMode: policy.redactionMode}
}

// ============================================================================
// Shoulder-Safe Mode
// ============================================================================

/// Toggle shoulder-surfing safe mode. When active, detected secrets
/// are blurred/masked in real-time across all panels.
let toggleShoulderSafe = (state: securityState): securityState => {
  {...state, shoulderSafe: !state.shoulderSafe}
}

// ============================================================================
// Default State
// ============================================================================

/// Initial security state.
let defaultState: securityState = {
  patterns: builtInPatterns,
  detectedSecrets: [],
  redactionMode: RedactOnShare,
  vaultStatus: VaultLocked,
  vaultKeys: [],
  twoFactorStatus: TwoFactorNotConfigured,
  twoFactorTimeout: 3600,
  trustfile: None,
  shoulderSafe: false,
  activeCategory: SecurityOverview,
  totpInput: "",
  error: None,
  newPatternLabel: "",
  newPatternRegex: "",
}
