// SPDX-License-Identifier: PMPL-1.0-or-later

/// Anti-Crash validation messages -- token validation and operator intervention.

open Model

type antiCrashMsg =
  | ValidateToken(neuralToken)
  | ValidationPassed(neuralToken)
  | ValidationFailed(neuralToken, string)
  | RequestOperatorIntervention(string)
  /// TypeLL type-level validation result for a token.
  | TokenTypeCheckResult(result<string, string>)
