// SPDX-License-Identifier: PMPL-1.0-or-later

/// AntiCrash Module - The Logical Circuit Breaker
///
/// Implements the Transduction Controller that intercepts all neural
/// tokens and validates them against symbolic constraints before
/// allowing them to reach the Task Barycentre.
///
/// No inference passes without symbolic validation.

open Model

/// Validation result
type validationResult =
  | Valid
  | Invalid(string)
  | RequiresReview(string)

/// Initial Anti-Crash state
let init = (): antiCrashState => {
  enabled: true,
  strictMode: true,
  violations: [],
  halted: false,
  pendingReview: None,
}

/// Check if a token violates type constraints
let checkTypeConstraints = (token: neuralToken, constraints: array<symbolicConstraint>): option<violationType> => {
  let activeConstraints = Array.filter(constraints, c => c.active)

  let violation = Array.find(activeConstraints, c => {
    let expr = c.expression

    // Check forbidden patterns: !contains("pattern")
    if String.includes(expr, "!contains(") {
      let pattern = expr
        ->String.replaceAll("!contains(\"", "")
        ->String.replaceAll("\")", "")
        ->String.trim

      if String.includes(token.content, pattern) {
        true
      } else {
        false
      }
    }
    // Check type declarations: type FooBar
    else if String.startsWith(expr, "type ") {
      let parts = String.split(expr, " ")
      if Array.length(parts) >= 2 {
        switch parts[1] {
        | Some(typeName) => {
            let reserved = ["undefined", "null", "NaN", "eval", "function"]
            Array.includes(reserved, typeName)
          }
        | None => false
        }
      } else {
        false
      }
    }
    // Fallback: check for dangerous keywords
    else {
      String.includes(token.content, "undefined") ||
      String.includes(token.content, "null") ||
      String.includes(token.content, "NaN")
    }
  })

  switch violation {
  | Some(c) => Some(TypeMismatch(c.expression, "inferred type"))
  | None => None
  }
}

/// Check for security violations
let checkSecurityConstraints = (token: neuralToken): option<violationType> => {
  // panic-attack:allow dynamic-code-detection-string — these are detection
  // patterns for security scanning, not actual code execution. Each string
  // is matched against user input to detect dangerous patterns.
  let dangerousPatterns = [
    "eval(",
    "exec(",
    "rm -rf",
    "DROP TABLE",
    "DELETE FROM",
    "<script>",
  ]

  let found = Array.find(dangerousPatterns, pattern =>
    String.includes(token.content, pattern)
  )

  switch found {
  | Some(pattern) => Some(SecurityViolation(pattern))
  | None => None
  }
}

/// Check for logical contradictions
let checkLogicConstraints = (token: neuralToken, constraints: array<symbolicConstraint>): option<violationType> => {
  let activeConstraints = Array.filter(constraints, c => c.active)

  // Check for obvious boolean contradictions
  if String.includes(token.content, "true && false") ||
     String.includes(token.content, "!true && true") ||
     String.includes(token.content, "false || false && true") {
    Some(LogicContradiction("Boolean contradiction detected"))
  } else {
    // Check if token contradicts any constraint expression
    let violation = Array.find(activeConstraints, c => {
      let expr = c.expression

      // Handle equality/inequality constraints
      if String.includes(expr, "==") {
        let negated = String.replaceAll(expr, "==", "!=")
        String.includes(token.content, negated)
      } else if String.includes(expr, "!=") {
        let negated = String.replaceAll(expr, "!=", "==")
        String.includes(token.content, negated)
      } else if String.includes(expr, ">") || String.includes(expr, "<") {
        // For boundary checks, look for obvious contradictions
        // e.g., constraint says "x > 0" but token contains "x = -1"
        false // Basic implementation - would need symbolic math
      } else {
        false
      }
    })

    switch violation {
    | Some(c) => Some(LogicContradiction(`Token contradicts constraint: ${c.expression}`))
    | None => None
    }
  }
}

/// Main validation function - the Circuit Breaker
let validate = (token: neuralToken, constraints: array<symbolicConstraint>): validationResult => {
  // Check security first (highest priority)
  switch checkSecurityConstraints(token) {
  | Some(SecurityViolation(pattern)) =>
    Invalid(`Security violation: dangerous pattern "${pattern}" detected`)
  | Some(_) => Invalid("Security violation detected")
  | None =>
    // Check type constraints
    switch checkTypeConstraints(token, constraints) {
    | Some(TypeMismatch(expected, actual)) =>
      Invalid(`Type mismatch: expected ${expected}, got ${actual}`)
    | Some(_) => Invalid("Type constraint violation")
    | None =>
      // Check logic constraints
      switch checkLogicConstraints(token, constraints) {
      | Some(LogicContradiction(msg)) => Invalid(`Logic contradiction: ${msg}`)
      | Some(_) => Invalid("Logic constraint violation")
      | None =>
        // Low confidence tokens require review
        if token.confidence < 0.7 {
          RequiresReview("Low confidence inference requires operator review")
        } else {
          Valid
        }
      }
    }
  }
}

/// Process a token through the Anti-Crash pipeline
let processToken = (
  token: neuralToken,
  constraints: array<symbolicConstraint>,
  state: antiCrashState,
): (antiCrashState, option<neuralToken>) => {
  if !state.enabled {
    // Pass through if Anti-Crash is disabled
    (state, Some({...token, validated: false}))
  } else if state.halted {
    // Block all tokens when halted
    (state, None)
  } else {
    switch validate(token, constraints) {
    | Valid => (state, Some({...token, validated: true}))
    | Invalid(reason) => {
        let violation = LogicContradiction(reason)
        let newState = {
          ...state,
          violations: Array.concat(state.violations, [violation]),
          halted: state.strictMode,
        }
        (newState, None)
      }
    | RequiresReview(_reason) => {
        let newState = {
          ...state,
          pendingReview: Some(token),
        }
        // In strict mode, halt until reviewed
        let finalState = state.strictMode ? {...newState, halted: true} : newState
        (finalState, None)
      }
    }
  }
}

/// Clear the halt state after operator intervention
let clearHalt = (state: antiCrashState): antiCrashState => {
  {...state, halted: false, pendingReview: None}
}

/// Approve a pending review
let approveReview = (state: antiCrashState): (antiCrashState, option<neuralToken>) => {
  switch state.pendingReview {
  | Some(token) => (
      {...state, pendingReview: None, halted: false},
      Some({...token, validated: true}),
    )
  | None => (state, None)
  }
}

/// Reject a pending review
let rejectReview = (state: antiCrashState): antiCrashState => {
  {...state, pendingReview: None, halted: false}
}
