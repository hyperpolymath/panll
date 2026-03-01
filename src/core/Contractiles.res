// SPDX-License-Identifier: PMPL-1.0-or-later

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
let orbitalStabilityContract = (orbital: Model.orbitalState, threshold: float): Model.contractStatus => {
  if orbital.stability >= threshold {
    Model.Satisfied
  } else {
    Model.Violated(`Orbital stability ${Float.toString(orbital.stability)} below threshold ${Float.toString(threshold)}`)
  }
}

/// Built-in contractile: Vexation Ceiling
let vexationCeilingContract = (vex: Model.vexometerState, ceiling: float): Model.contractStatus => {
  if vex.index <= ceiling {
    Model.Satisfied
  } else {
    Model.Violated(`Vexation index ${Float.toString(vex.index)} exceeds ceiling ${Float.toString(ceiling)}`)
  }
}

/// Built-in contractile: Divergence Limit
let divergenceLimitContract = (orbital: Model.orbitalState, limit: float): Model.contractStatus => {
  if orbital.divergenceLevel <= limit {
    Model.Satisfied
  } else {
    Model.Violated(`Divergence level ${Float.toString(orbital.divergenceLevel)} exceeds limit ${Float.toString(limit)}`)
  }
}

/// Built-in contractile: Autonomy Bound
let autonomyBoundContract = (agency: Model.agencyState, maxAutonomy: float): Model.contractStatus => {
  if agency.autonomyLevel <= maxAutonomy {
    Model.Satisfied
  } else {
    Model.Violated(`Autonomy level ${Float.toString(agency.autonomyLevel)} exceeds bound ${Float.toString(maxAutonomy)}`)
  }
}

/// Default contractile set for PanLL
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
]

/// Evaluate all contractiles against current model state
let evaluateAll = (model: Model.model, contractiles: array<Model.contractile>): array<Model.evaluationResult> => {
  Array.map(contractiles, c => {
    let status = switch c.id {
    | "orbital-stability" => orbitalStabilityContract(model.orbital, 0.5)
    | "vexation-ceiling" => vexationCeilingContract(model.vexometer, 0.8)
    | "divergence-limit" => divergenceLimitContract(model.orbital, 0.6)
    | "autonomy-bound" => autonomyBoundContract(model.paneN.agency, 0.7)
    | _ => Model.Pending
    }

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
  let adjustedElasticity = contractile.elasticity +. (vexationFactor *. 0.2)

  // Clamp elasticity to [0.0, 1.0]
  let clampedElasticity = Math.min(1.0, Math.max(0.0, adjustedElasticity))

  {...contractile, elasticity: clampedElasticity}
}
