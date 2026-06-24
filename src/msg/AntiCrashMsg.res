// SPDX-License-Identifier: MPL-2.0

/// Anti-Crash validation messages -- token validation and operator intervention.

open Model

type antiCrashMsg =
  | ValidateToken(neuralToken)
  | ValidationPassed(neuralToken)
  | ValidationFailed(neuralToken, string)
  | RequestOperatorIntervention(string)
  /// TypeLL type-level validation result for a token.
  | TokenTypeCheckResult(result<string, string>)
