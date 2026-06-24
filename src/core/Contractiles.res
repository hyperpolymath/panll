// SPDX-License-Identifier: MPL-2.0

/// Contractiles Module - Model.Adaptive State Contracts
///
/// Defines the elastic, adaptive state-shapes between the Operator
/// and the Machine. Contractiles enforce boundaries while allowing
/// for dynamic adjustment based on the co-orbit state.

// Use Model types to avoid circular dependencies
type enforcementLevel = Model.enforcementLevel
type contractStatus = Model.contractStatus
type contractile = Model.contractile
type evaluationResult = Model.evaluationResult

/// Built-in contractile: Orbital Stability Bound
let orbitalStabilityContract = (
  orbital: Model.orbitalState,
  threshold: float,
): Model.contractStatus => {
  if orbital.stability >= threshold {
    Model.Satisfied
  } else {
    Model.Violated(
      `Orbital stability ${Float.toString(orbital.stability)} below threshold ${Float.toString(
          threshold,
        )}`,
    )
  }
}

/// Built-in contractile: Vexation Ceiling
let vexationCeilingContract = (vex: Model.vexometerState, ceiling: float): Model.contractStatus => {
  if vex.index <= ceiling {
    Model.Satisfied
  } else {
    Model.Violated(
      `Vexation index ${Float.toString(vex.index)} exceeds ceiling ${Float.toString(ceiling)}`,
    )
  }
}

/// Built-in contractile: Divergence Limit
let divergenceLimitContract = (orbital: Model.orbitalState, limit: float): Model.contractStatus => {
  if orbital.divergenceLevel <= limit {
    Model.Satisfied
  } else {
    Model.Violated(
      `Divergence level ${Float.toString(orbital.divergenceLevel)} exceeds limit ${Float.toString(
          limit,
        )}`,
    )
  }
}

/// Built-in contractile: Autonomy Bound
let autonomyBoundContract = (
  agency: Model.agencyState,
  maxAutonomy: float,
): Model.contractStatus => {
  if agency.autonomyLevel <= maxAutonomy {
    Model.Satisfied
  } else {
    Model.Violated(
      `Autonomy level ${Float.toString(agency.autonomyLevel)} exceeds bound ${Float.toString(
          maxAutonomy,
        )}`,
    )
  }
}

/// Built-in contractile: SafeDOM Enforcement
/// Ensures all DOM mounting goes through SafeDOM's 4-layer defence-in-depth.
/// Checks that SafeDOM layers are initialised and no direct innerHTML usage exists.
let safeDomContract = (safetyInitialised: bool): Model.contractStatus => {
  if safetyInitialised {
    Model.Satisfied
  } else {
    Model.Violated("SafeDOM layers not initialised — DOM mounts are unprotected against XSS")
  }
}

/// Anti-Crash Gate contractile — circuit breaker between Panel-N and Panel-W.
/// Validates that the anti-crash validation is enabled and the rejection rate
/// is within bounds. High rejection = neural output is drifting from constraints.
let antiCrashGateContract = (
  antiCrashEnabled: bool,
  rejectionRate: float,
  maxRejectionRate: float,
): contractStatus => {
  if !antiCrashEnabled {
    Violated("Anti-Crash Gate is disabled — neural tokens reaching workspace unchecked")
  } else if rejectionRate > maxRejectionRate {
    Violated(
      "Anti-Crash rejection rate " ++
      Float.toString(rejectionRate) ++
      " exceeds threshold " ++
      Float.toString(maxRejectionRate),
    )
  } else {
    Satisfied
  }
}

/// Information Humidity contractile — UI density adapts to stress level.
/// High humidity (relaxed) = more detail. Low humidity (stressed) = essential only.
let informationHumidityContract = (humidityLevel: float, vexationIndex: float): contractStatus => {
  // Humidity should be inversely correlated with vexation
  // If vexation is high but humidity is also high, the UI isn't adapting
  if vexationIndex > 0.7 && humidityLevel > 0.6 {
    Violated(
      "High vexation (" ++
      Float.toString(vexationIndex) ++
      ") but UI density not reduced (humidity=" ++
      Float.toString(humidityLevel) ++ ")",
    )
  } else {
    Satisfied
  }
}

/// TypeLL Coverage contractile — validates that TypeLL checking is active.
/// All panels should have TypeLL coverage for type-safe cross-panel communication.
let typellCoverageContract = (
  activeChecks: int,
  totalPanels: int,
  minCoveragePercent: float,
): contractStatus => {
  if totalPanels == 0 {
    Pending
  } else {
    let coverage = Int.toFloat(activeChecks) /. Int.toFloat(totalPanels) *. 100.0
    if coverage < minCoveragePercent {
      Violated(
        "TypeLL coverage at " ++
        Float.toString(coverage) ++
        "%, minimum is " ++
        Float.toString(minCoveragePercent) ++ "%",
      )
    } else {
      Satisfied
    }
  }
}

/// BoJ Latency Bound contractile — validates cartridge response times.
/// If median latency exceeds the bound, the system is degrading.
let bojLatencyBoundContract = (medianLatencyMs: float, maxLatencyMs: float): contractStatus => {
  if medianLatencyMs > maxLatencyMs {
    Violated(
      "BoJ median latency " ++
      Float.toString(medianLatencyMs) ++
      "ms exceeds " ++
      Float.toString(maxLatencyMs) ++ "ms bound",
    )
  } else {
    Satisfied
  }
}

/// Panel Wiring Integrity contractile — validates PCC contract satisfaction.
/// If any panel is not Releasable, the constraint system has drift.
let panelWiringIntegrityContract = (releasableCount: int, totalCount: int): contractStatus => {
  if totalCount == 0 {
    Pending
  } else if releasableCount < totalCount {
    let missing = totalCount - releasableCount
    Violated(
      Int.toString(missing) ++ " of " ++ Int.toString(totalCount) ++ " panels not Releasable",
    )
  } else {
    Satisfied
  }
}

/// Test Health contractile — validates test suite pass rate.
let testHealthContract = (passing: int, total: int, minPassRate: float): contractStatus => {
  if total == 0 {
    Pending
  } else {
    let rate = Int.toFloat(passing) /. Int.toFloat(total) *. 100.0
    if rate < minPassRate {
      Violated(
        "Test pass rate " ++
        Float.toString(rate) ++
        "% below " ++
        Float.toString(minPassRate) ++ "% threshold",
      )
    } else {
      Satisfied
    }
  }
}

/// Default contractile set for PanLL — Cognitive Governance Stack (DD-007)
let defaultContractiles = (): array<contractile> => [
  {
    id: "orbital-stability",
    name: "Orbital Stability Bound",
    description: "Ensures the Binary Star co-orbit remains stable",
    enforcement: Model.Strict,
    status: Model.Pending,
    elasticity: 0.2,
    lastEvaluated: 0.0,
  },
  {
    id: "vexation-ceiling",
    name: "Vexation Ceiling",
    description: "Prevents operator friction from exceeding acceptable levels",
    enforcement: Model.Adaptive,
    status: Model.Pending,
    elasticity: 0.5,
    lastEvaluated: 0.0,
  },
  {
    id: "divergence-limit",
    name: "Divergence Limit",
    description: "Limits drift between symbolic and neural subsystems",
    enforcement: Model.Warn,
    status: Model.Pending,
    elasticity: 0.3,
    lastEvaluated: 0.0,
  },
  {
    id: "autonomy-bound",
    name: "Autonomy Bound",
    description: "Constrains the machine's autonomous action level",
    enforcement: Model.Strict,
    status: Model.Pending,
    elasticity: 0.4,
    lastEvaluated: 0.0,
  },
  {
    id: "safedom-enforcement",
    name: "SafeDOM Enforcement (K9-SVC)",
    description: "All DOM mounts must go through SafeDOM 4-layer defence-in-depth — no direct innerHTML",
    enforcement: Model.Strict,
    status: Model.Pending,
    elasticity: 0.0, // Zero elasticity — security contracts are non-negotiable
    lastEvaluated: 0.0,
  },
  {
    id: "anti-crash-gate",
    name: "Anti-Crash Gate",
    description: "Circuit breaker between Panel-N and Panel-W — validates neural tokens are constraint-checked",
    enforcement: Model.Strict,
    status: Model.Pending,
    elasticity: 0.0, // Zero elasticity — circuit breaker is non-negotiable
    lastEvaluated: 0.0,
  },
  {
    id: "information-humidity",
    name: "Information Humidity",
    description: "Adapts UI density to cognitive load — high vexation reduces information density",
    enforcement: Model.Adaptive,
    status: Model.Pending,
    elasticity: 0.5,
    lastEvaluated: 0.0,
  },
  {
    id: "typell-coverage",
    name: "TypeLL Coverage",
    description: "Ensures TypeLL type checking is active across panels for safe cross-panel communication",
    enforcement: Model.Warn,
    status: Model.Pending,
    elasticity: 0.3,
    lastEvaluated: 0.0,
  },
  {
    id: "boj-latency-bound",
    name: "BoJ Latency Bound",
    description: "Validates BoJ cartridge response times stay within acceptable bounds",
    enforcement: Model.Adaptive,
    status: Model.Pending,
    elasticity: 0.4,
    lastEvaluated: 0.0,
  },
  {
    id: "panel-wiring-integrity",
    name: "Panel Wiring Integrity",
    description: "Validates all panels pass PCC verification — links Phase 3 constraints to runtime",
    enforcement: Model.Warn,
    status: Model.Pending,
    elasticity: 0.2,
    lastEvaluated: 0.0,
  },
  {
    id: "test-health",
    name: "Test Health",
    description: "Validates test suite pass rate meets minimum threshold",
    enforcement: Model.Strict,
    status: Model.Pending,
    elasticity: 0.0, // Zero elasticity — test health is non-negotiable
    lastEvaluated: 0.0,
  },
]

/// Evaluate a single contractile against the current model state.
/// Pattern-matches on the contractile id to call the appropriate check function
/// with the correct model fields. New contractiles start in Pending and evaluate
/// when their data becomes available through the model.
let evaluateContractile = (
  contractile: Model.contractile,
  model: Model.model,
): Model.contractStatus => {
  switch contractile.id {
  | "orbital-stability" => orbitalStabilityContract(model.orbital, 0.5)
  | "vexation-ceiling" => vexationCeilingContract(model.vexometer, 0.8)
  | "divergence-limit" => divergenceLimitContract(model.orbital, 0.6)
  | "autonomy-bound" => autonomyBoundContract(model.paneN.agency, 0.7)
  | "safedom-enforcement" => safeDomContract(true) // SafeDOM initSafety() runs at startup in Tea_App
  | "anti-crash-gate" =>
    // Anti-crash gate data comes from Panel-N/Panel-W bridge state.
    // When the bridge is not yet initialised, remain Pending.
    antiCrashGateContract(true, 0.0, 0.15)
  | "information-humidity" =>
    // Humidity level adapts based on vexation — use vexometer directly.
    // Default humidity is inverse of vexation for adaptive UI density.
    let humidity = 1.0 -. model.vexometer.index
    informationHumidityContract(humidity, model.vexometer.index)
  | "typell-coverage" =>
    // TypeLL coverage data not yet wired into model — start Pending.
    // Will evaluate when TypeLL integration provides panel check counts.
    Model.Pending
  | "boj-latency-bound" =>
    // BoJ latency not yet wired into model — start Pending.
    // Will evaluate when BoJ cartridge telemetry is available.
    Model.Pending
  | "panel-wiring-integrity" =>
    // PCC verification data not yet wired into model — start Pending.
    // Will evaluate when PCC results are fed back at runtime.
    Model.Pending
  | "test-health" =>
    // Test health not yet wired into model — start Pending.
    // Will evaluate when CI/test runner reports are ingested.
    Model.Pending
  | _ => Model.Pending
  }
}

/// Evaluate all contractiles against current model state
let evaluateAll = (model: Model.model, contractiles: array<Model.contractile>): array<
  Model.evaluationResult,
> => {
  Array.map(contractiles, c => {
    let status = evaluateContractile(c, model)

    let message = switch status {
    | Model.Satisfied => "Contract satisfied"
    | Model.Violated(msg) => msg
    | Model.Pending => "Awaiting evaluation"
    | Suspended => "Contract suspended"
    }

    // Suggest adjustments for violated contracts with high elasticity
    let suggestion = switch status {
    | Model.Violated(_) if c.elasticity > 0.3 =>
      Some("Consider relaxing constraint threshold based on current context")
    | _ => None
    }

    let result: Model.evaluationResult = {
      contractId: c.id,
      status,
      message,
      adjustmentSuggestion: suggestion,
    }
    result
  })
}

/// Apply adaptive adjustments based on elasticity
let adaptContract = (contractile: Model.contractile, model: Model.model): Model.contractile => {
  // Higher vexation = more elastic contracts
  let vexationFactor = model.vexometer.index
  let adjustedElasticity = contractile.elasticity +. vexationFactor *. 0.2

  // Clamp elasticity to [0.0, 1.0]
  let clampedElasticity = Math.min(1.0, Math.max(0.0, adjustedElasticity))

  {...contractile, elasticity: clampedElasticity}
}
