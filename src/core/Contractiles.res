// SPDX-License-Identifier: AGPL-3.0-or-later

/// Contractiles Module - Adaptive State Contracts
///
/// Defines the elastic, adaptive state-shapes between the Operator
/// and the Machine. Contractiles enforce boundaries while allowing
/// for dynamic adjustment based on the co-orbit state.

open Model

/// Contract enforcement level
type enforcementLevel =
  | Strict    // Halt on violation
  | Warn      // Log warning, continue
  | Adaptive  // Adjust contract based on context

/// Contract status
type contractStatus =
  | Satisfied
  | Violated(string)
  | Pending
  | Suspended

/// A contractile definition
type contractile = {
  id: string,
  name: string,
  description: string,
  enforcement: enforcementLevel,
  status: contractStatus,
  elasticity: float, // 0.0 = rigid, 1.0 = fully elastic
  lastEvaluated: float,
}

/// Contractile evaluation result
type evaluationResult = {
  contractId: string,
  status: contractStatus,
  message: string,
  adjustmentSuggestion: option<string>,
}

/// Built-in contractile: Orbital Stability Bound
let orbitalStabilityContract = (orbital: orbitalState, threshold: float): contractStatus => {
  if orbital.stability >= threshold {
    Satisfied
  } else {
    Violated(`Orbital stability ${Float.toString(orbital.stability)} below threshold ${Float.toString(threshold)}`)
  }
}

/// Built-in contractile: Vexation Ceiling
let vexationCeilingContract = (vex: vexometerState, ceiling: float): contractStatus => {
  if vex.index <= ceiling {
    Satisfied
  } else {
    Violated(`Vexation index ${Float.toString(vex.index)} exceeds ceiling ${Float.toString(ceiling)}`)
  }
}

/// Built-in contractile: Divergence Limit
let divergenceLimitContract = (orbital: orbitalState, limit: float): contractStatus => {
  if orbital.divergenceLevel <= limit {
    Satisfied
  } else {
    Violated(`Divergence level ${Float.toString(orbital.divergenceLevel)} exceeds limit ${Float.toString(limit)}`)
  }
}

/// Built-in contractile: Autonomy Bound
let autonomyBoundContract = (agency: agencyState, maxAutonomy: float): contractStatus => {
  if agency.autonomyLevel <= maxAutonomy {
    Satisfied
  } else {
    Violated(`Autonomy level ${Float.toString(agency.autonomyLevel)} exceeds bound ${Float.toString(maxAutonomy)}`)
  }
}

/// Default contractile set for PanLL
let defaultContractiles = (): array<contractile> => [
  {
    id: "orbital-stability",
    name: "Orbital Stability Bound",
    description: "Ensures the Binary Star co-orbit remains stable",
    enforcement: Strict,
    status: Pending,
    elasticity: 0.2,
    lastEvaluated: 0.0,
  },
  {
    id: "vexation-ceiling",
    name: "Vexation Ceiling",
    description: "Prevents operator friction from exceeding acceptable levels",
    enforcement: Adaptive,
    status: Pending,
    elasticity: 0.5,
    lastEvaluated: 0.0,
  },
  {
    id: "divergence-limit",
    name: "Divergence Limit",
    description: "Limits drift between symbolic and neural subsystems",
    enforcement: Warn,
    status: Pending,
    elasticity: 0.3,
    lastEvaluated: 0.0,
  },
  {
    id: "autonomy-bound",
    name: "Autonomy Bound",
    description: "Constrains the machine's autonomous action level",
    enforcement: Strict,
    status: Pending,
    elasticity: 0.4,
    lastEvaluated: 0.0,
  },
]

/// Evaluate all contractiles against current model state
let evaluateAll = (model: model, contractiles: array<contractile>): array<evaluationResult> => {
  Array.map(contractiles, c => {
    let status = switch c.id {
    | "orbital-stability" => orbitalStabilityContract(model.orbital, 0.5)
    | "vexation-ceiling" => vexationCeilingContract(model.vexometer, 0.8)
    | "divergence-limit" => divergenceLimitContract(model.orbital, 0.6)
    | "autonomy-bound" => autonomyBoundContract(model.paneN.agency, 0.7)
    | _ => Pending
    }

    let message = switch status {
    | Satisfied => "Contract satisfied"
    | Violated(msg) => msg
    | Pending => "Awaiting evaluation"
    | Suspended => "Contract suspended"
    }

    // Suggest adjustments for violated contracts with high elasticity
    let suggestion = switch status {
    | Violated(_) if c.elasticity > 0.3 =>
      Some("Consider relaxing constraint threshold based on current context")
    | _ => None
    }

    {
      contractId: c.id,
      status,
      message,
      adjustmentSuggestion: suggestion,
    }
  })
}

/// Apply adaptive adjustments based on elasticity
let adaptContract = (contractile: contractile, model: model): contractile => {
  // Higher vexation = more elastic contracts
  let vexationFactor = model.vexometer.index
  let adjustedElasticity = contractile.elasticity +. (vexationFactor *. 0.2)

  // Clamp elasticity to [0.0, 1.0]
  let clampedElasticity = Float.Math.min(1.0, Float.Math.max(0.0, adjustedElasticity))

  {...contractile, elasticity: clampedElasticity}
}
