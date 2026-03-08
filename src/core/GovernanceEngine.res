// SPDX-License-Identifier: PMPL-1.0-or-later

/// GovernanceEngine — Neurosymbolic Coherence Orchestrator
///
/// Closes the feedback loops between PanLL's five governance subsystems:
///
///   Anti-Crash (circuit breaker) → Governance → Contractiles (elastic bounds)
///   Vexometer (operator frustration) → Governance → Contractiles (elasticity)
///   OrbitalSync (L↔N↔W divergence) → Governance → Anti-Crash (confidence)
///
/// This is the missing piece that makes PanLL "wholly neurosymbolic" — without
/// it, each subsystem validates in isolation but never learns from the others.
///
/// Called after every applyContractiles pass in the main update loop.

open Model

// ---------------------------------------------------------------------------
// Governance decision — what this engine concludes after inspecting the system
// ---------------------------------------------------------------------------

/// A governance adjustment to be applied to the model after evaluation.
type governanceAdjustment =
  /// Tighten Anti-Crash: too many violations, reduce confidence threshold.
  | TightenAntiCrash
  /// Loosen Anti-Crash: low violations + high vexation = operator frustrated by strictness.
  | LoosenAntiCrash
  /// Increase contractile elasticity: operator vexation is high.
  | IncreaseElasticity(string) // contractile id
  /// Decrease contractile elasticity: stability is high, can be stricter.
  | DecreaseElasticity(string) // contractile id
  /// Halt inference: critical governance failure.
  | HaltInference(string) // reason
  /// Resume inference: conditions have improved.
  | ResumeInference
  /// Adjust humidity: stress level changed.
  | AdjustHumidity(humidityLevel)
  /// Emit sync event: cross-panel state changed.
  | EmitSyncEvent(syncEvent)

// ---------------------------------------------------------------------------
// Thresholds (tuned for the Binary Star co-orbit)
// ---------------------------------------------------------------------------

let violationSpikeThreshold = 5
let vexationHighThreshold = 0.7
let vexationLowThreshold = 0.3
let stabilityDangerThreshold = 0.4
let stabilityHealthyThreshold = 0.7
let divergenceHighThreshold = 0.6
let elasticityIncrement = 0.05
let elasticityDecrement = 0.03

// ---------------------------------------------------------------------------
// Analysis functions
// ---------------------------------------------------------------------------

/// Count recent Anti-Crash violations. Used to detect violation spikes.
let violationCount = (antiCrash: antiCrashState): int => {
  Array.length(antiCrash.violations)
}

/// Determine if operator frustration should loosen constraints.
let shouldLoosenForVexation = (vex: vexometerState, antiCrash: antiCrashState): bool => {
  vex.index > vexationHighThreshold &&
    violationCount(antiCrash) < violationSpikeThreshold &&
    !vex.inertiaDetected
}

/// Determine if low violations + stable orbit should tighten constraints.
let shouldTightenForStability = (
  orbital: orbitalState,
  antiCrash: antiCrashState,
  vex: vexometerState,
): bool => {
  orbital.stability > stabilityHealthyThreshold &&
    violationCount(antiCrash) > violationSpikeThreshold &&
    vex.index < vexationLowThreshold
}

/// Determine the appropriate humidity level from current system state.
let computeHumidity = (vex: vexometerState, orbital: orbitalState): humidityLevel => {
  if vex.index > vexationHighThreshold || orbital.stability < stabilityDangerThreshold {
    Low // High stress — shed visual noise
  } else if vex.index > vexationLowThreshold || orbital.stability < stabilityHealthyThreshold {
    Medium
  } else {
    High // Low stress — show more detail
  }
}

// ---------------------------------------------------------------------------
// Main governance evaluation
// ---------------------------------------------------------------------------

/// Evaluate all governance subsystems and produce adjustments.
/// Pure function — returns a list of adjustments, does not mutate state.
let evaluate = (model: model): array<governanceAdjustment> => {
  let adjustments: array<governanceAdjustment> = []

  // --- Anti-Crash ↔ Vexometer feedback ---

  let adjustments = if shouldLoosenForVexation(model.vexometer, model.antiCrash) {
    // Operator is frustrated and violations are low — loosen the gate.
    Array.concat(adjustments, [LoosenAntiCrash])
  } else if shouldTightenForStability(model.orbital, model.antiCrash, model.vexometer) {
    // Orbit is stable but violations are spiking — tighten the gate.
    Array.concat(adjustments, [TightenAntiCrash])
  } else {
    adjustments
  }

  // --- Vexometer → Contractile elasticity ---

  let adjustments = if model.vexometer.index > vexationHighThreshold {
    // High vexation: increase elasticity on Adaptive contracts.
    let elasticAdj = Array.filterMap(model.contractiles, c => {
      switch c.enforcement {
      | Adaptive if c.elasticity < 0.9 => Some(IncreaseElasticity(c.id))
      | _ => None
      }
    })
    Array.concat(adjustments, elasticAdj)
  } else if model.vexometer.index < vexationLowThreshold {
    // Low vexation: decrease elasticity (can be stricter).
    let tightenAdj = Array.filterMap(model.contractiles, c => {
      switch c.enforcement {
      | Adaptive if c.elasticity > 0.1 => Some(DecreaseElasticity(c.id))
      | _ => None
      }
    })
    Array.concat(adjustments, tightenAdj)
  } else {
    adjustments
  }

  // --- OrbitalSync divergence → governance ---

  let adjustments = if model.orbital.divergenceLevel > divergenceHighThreshold {
    // L↔N divergence is high — emit a sync event and consider halting.
    let syncAdj = [
      EmitSyncEvent(CrossPaneLink("governance:divergence-high", "antiCrash")),
    ]
    let haltAdj = if model.orbital.stability < stabilityDangerThreshold {
      [HaltInference("Orbital stability critically low — L↔N divergence exceeds safe threshold")]
    } else {
      []
    }
    Array.concat(adjustments, Array.concat(syncAdj, haltAdj))
  } else {
    adjustments
  }

  // --- Inertia detection → inference resumption ---

  let adjustments = if model.vexometer.inertiaDetected && !model.paneN.inferenceActive {
    // System has been idle too long — suggest resumption if conditions are met.
    if model.orbital.stability > stabilityHealthyThreshold &&
      violationCount(model.antiCrash) === 0 {
      Array.concat(adjustments, [ResumeInference])
    } else {
      adjustments
    }
  } else {
    adjustments
  }

  // --- S5: Hypatia confidence → Anti-Crash strictness ---
  // When Hypatia neural networks have low average confidence, tighten
  // the Anti-Crash gate. When confidence is high, allow looser validation.

  let adjustments = if Array.length(model.hypatia.networks) > 0 {
    let activeNets = model.hypatia.networks->Array.filter(n =>
      switch n.status {
      | NetActive => true
      | _ => false
      }
    )
    let avgConf = if Array.length(activeNets) > 0 {
      activeNets->Array.reduce(0.0, (acc, n) => acc +. n.confidence) /.
        Int.toFloat(Array.length(activeNets))
    } else {
      0.0
    }
    if avgConf < 0.5 && !model.antiCrash.strictMode {
      // Low neural confidence → tighten validation.
      Array.concat(adjustments, [TightenAntiCrash])
    } else if avgConf > 0.8 && model.antiCrash.strictMode &&
      violationCount(model.antiCrash) < 2 {
      // High neural confidence + few violations → can loosen.
      Array.concat(adjustments, [LoosenAntiCrash])
    } else {
      adjustments
    }
  } else {
    adjustments
  }

  // --- Humidity adjustment ---

  let targetHumidity = computeHumidity(model.vexometer, model.orbital)
  let adjustments = if targetHumidity !== model.humidity {
    Array.concat(adjustments, [AdjustHumidity(targetHumidity)])
  } else {
    adjustments
  }

  adjustments
}

// ---------------------------------------------------------------------------
// Apply adjustments to model
// ---------------------------------------------------------------------------

/// Apply a single governance adjustment to the model. Pure.
let applyAdjustment = (model: model, adj: governanceAdjustment): model => {
  switch adj {
  | TightenAntiCrash => {
      ...model,
      antiCrash: {...model.antiCrash, strictMode: true},
    }

  | LoosenAntiCrash => {
      ...model,
      antiCrash: {...model.antiCrash, strictMode: false},
    }

  | IncreaseElasticity(contractId) => {
      let newContractiles = Array.map(model.contractiles, c => {
        if c.id === contractId {
          {...c, elasticity: Math.min(1.0, c.elasticity +. elasticityIncrement)}
        } else {
          c
        }
      })
      {...model, contractiles: newContractiles}
    }

  | DecreaseElasticity(contractId) => {
      let newContractiles = Array.map(model.contractiles, c => {
        if c.id === contractId {
          {...c, elasticity: Math.max(0.0, c.elasticity -. elasticityDecrement)}
        } else {
          c
        }
      })
      {...model, contractiles: newContractiles}
    }

  | HaltInference(reason) => {
      let violation = BoundaryViolation(reason)
      {
        ...model,
        paneN: {...model.paneN, inferenceActive: false},
        antiCrash: {
          ...model.antiCrash,
          halted: true,
          violations: Array.concat(model.antiCrash.violations, [violation]),
        },
      }
    }

  | ResumeInference => {
      ...model,
      paneN: {...model.paneN, inferenceActive: true},
      antiCrash: {...model.antiCrash, halted: false},
    }

  | AdjustHumidity(level) => {
      ...model,
      humidity: level,
    }

  | EmitSyncEvent(event) => {
      let newSync = {
        ...model.syncState,
        pendingSync: Array.concat(model.syncState.pendingSync, [event]),
      }
      {...model, syncState: newSync}
    }
  }
}

/// Apply all governance adjustments to the model. Pure fold.
let applyAll = (model: model, adjustments: array<governanceAdjustment>): model => {
  Array.reduce(adjustments, model, applyAdjustment)
}

/// Full governance pass: evaluate + apply. Called from the main update loop.
let govern = (model: model): model => {
  let adjustments = evaluate(model)
  applyAll(model, adjustments)
}
