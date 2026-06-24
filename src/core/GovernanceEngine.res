// SPDX-License-Identifier: MPL-2.0

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
    let syncAdj = [EmitSyncEvent(CrossPaneLink("governance:divergence-high", "antiCrash"))]
    let haltAdj = if model.orbital.stability < stabilityDangerThreshold {
      [
        HaltInference(
          "Orbital stability critically low — L↔N divergence exceeds safe threshold",
        ),
      ]
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
    if (
      model.orbital.stability > stabilityHealthyThreshold && violationCount(model.antiCrash) === 0
    ) {
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
    } else if avgConf > 0.8 && model.antiCrash.strictMode && violationCount(model.antiCrash) < 2 {
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

// ---------------------------------------------------------------------------
// Nesy-MCP governance queries — deferred decisions that need async validation
// ---------------------------------------------------------------------------

/// A governance query represents a decision that cannot be made purely —
/// it requires consultation with the BoJ nesy-mcp cartridge for real-time
/// neural validation before the adjustment can be applied.
type governanceQuery =
  /// Ask nesy-mcp for a confidence score on a borderline governance decision.
  | NesyConfidenceQuery(string)
  /// Request nesy-mcp to validate a governance adjustment before applying it.
  | NesyValidateAdjustment(governanceAdjustment)
  /// Probe nesy-mcp for overall stability metrics from the neural subsystem.
  | NesyStabilityProbe

// ---------------------------------------------------------------------------
// Nesy-aware governance evaluation
// ---------------------------------------------------------------------------

/// Evaluate governance subsystems, returning both immediate adjustments and
/// deferred queries that require nesy-mcp validation.
///
/// The "uncertain zone" for vexation is [0.3, 0.7] and for orbital stability
/// is [0.4, 0.7]. When both fall in these ranges simultaneously, the engine
/// cannot confidently decide — it emits a NesyConfidenceQuery instead.
///
/// Any HaltInference decision is always preceded by a NesyValidateAdjustment
/// query so the neural subsystem can double-check the halt rationale.
///
/// Pure function — returns tuples, does not mutate state.
let evaluateWithCmd = (model: model): (array<governanceAdjustment>, array<governanceQuery>) => {
  let adjustments: array<governanceAdjustment> = []
  let queries: array<governanceQuery> = []

  // --- Uncertain-zone detection ---
  // When vexation AND orbital stability are both in their borderline ranges,
  // defer the Anti-Crash decision to nesy-mcp instead of guessing.

  let vexInUncertainZone =
    model.vexometer.index >= vexationLowThreshold && model.vexometer.index <= vexationHighThreshold

  let stabilityInBorderline =
    model.orbital.stability >= stabilityDangerThreshold &&
      model.orbital.stability <= stabilityHealthyThreshold

  // --- Anti-Crash ↔ Vexometer feedback (with nesy deferral) ---

  let (adjustments, queries) = if vexInUncertainZone && stabilityInBorderline {
    // Both metrics are borderline — defer to nesy-mcp.
    let q = NesyConfidenceQuery(
      `vexation=${Float.toString(model.vexometer.index)},` ++
      `stability=${Float.toString(model.orbital.stability)},` ++
      `violations=${Int.toString(violationCount(model.antiCrash))}`,
    )
    (adjustments, Array.concat(queries, [q]))
  } else if shouldLoosenForVexation(model.vexometer, model.antiCrash) {
    (Array.concat(adjustments, [LoosenAntiCrash]), queries)
  } else if shouldTightenForStability(model.orbital, model.antiCrash, model.vexometer) {
    (Array.concat(adjustments, [TightenAntiCrash]), queries)
  } else {
    (adjustments, queries)
  }

  // --- Vexometer → Contractile elasticity ---

  let adjustments = if model.vexometer.index > vexationHighThreshold {
    let elasticAdj = Array.filterMap(model.contractiles, c => {
      switch c.enforcement {
      | Adaptive if c.elasticity < 0.9 => Some(IncreaseElasticity(c.id))
      | _ => None
      }
    })
    Array.concat(adjustments, elasticAdj)
  } else if model.vexometer.index < vexationLowThreshold {
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

  // --- OrbitalSync divergence → governance (with nesy validation on halt) ---

  let (adjustments, queries) = if model.orbital.divergenceLevel > divergenceHighThreshold {
    let syncAdj = [EmitSyncEvent(CrossPaneLink("governance:divergence-high", "antiCrash"))]
    let (haltAdj, haltQueries) = if model.orbital.stability < stabilityDangerThreshold {
      let haltReason = "Orbital stability critically low — L↔N divergence exceeds safe threshold"
      // Always validate a HaltInference through nesy-mcp first.
      let halt = HaltInference(haltReason)
      ([halt], [NesyValidateAdjustment(halt)])
    } else {
      ([], [])
    }
    (Array.concat(adjustments, Array.concat(syncAdj, haltAdj)), Array.concat(queries, haltQueries))
  } else {
    (adjustments, queries)
  }

  // --- Inertia detection → inference resumption ---

  let adjustments = if model.vexometer.inertiaDetected && !model.paneN.inferenceActive {
    if (
      model.orbital.stability > stabilityHealthyThreshold && violationCount(model.antiCrash) === 0
    ) {
      Array.concat(adjustments, [ResumeInference])
    } else {
      adjustments
    }
  } else {
    adjustments
  }

  // --- S5: Hypatia confidence → Anti-Crash strictness ---

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
      Array.concat(adjustments, [TightenAntiCrash])
    } else if avgConf > 0.8 && model.antiCrash.strictMode && violationCount(model.antiCrash) < 2 {
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

  // --- Stability probe: emit when any query was generated ---

  let queries = if Array.length(queries) > 0 {
    Array.concat(queries, [NesyStabilityProbe])
  } else {
    queries
  }

  (adjustments, queries)
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

/// Nesy-aware governance pass: evaluate, apply immediate adjustments, and
/// dispatch async nesy-mcp queries through GovernanceCmd. Returns updated
/// model plus any Tea commands for nesy queries.
let governWithCmd = (model: model, nesyTagger: result<string, string> => 'msg): (
  model,
  Tea_Cmd.t<'msg>,
) => {
  let (adjustments, queries) = evaluateWithCmd(model)
  let newModel = applyAll(model, adjustments)

  // Convert governance queries into Tea commands via GovernanceCmd.
  let cmds = queries->Array.map(query => {
    switch query {
    | NesyConfidenceQuery(q) => GovernanceCmd.queryNesyConfidence(q, nesyTagger)
    | NesyValidateAdjustment(_adj) => {
        // Serialize the adjustment type as a string descriptor for nesy-mcp.
        let adjStr = switch _adj {
        | TightenAntiCrash => "TightenAntiCrash"
        | LoosenAntiCrash => "LoosenAntiCrash"
        | HaltInference(reason) => "HaltInference:" ++ reason
        | ResumeInference => "ResumeInference"
        | IncreaseElasticity(id) => "IncreaseElasticity:" ++ id
        | DecreaseElasticity(id) => "DecreaseElasticity:" ++ id
        | AdjustHumidity(_) => "AdjustHumidity"
        | EmitSyncEvent(_) => "EmitSyncEvent"
        }
        GovernanceCmd.validateAdjustment(adjStr, nesyTagger)
      }
    | NesyStabilityProbe => GovernanceCmd.probeStability(nesyTagger)
    }
  })

  let cmd = if Array.length(cmds) > 0 {
    Tea_Cmd.batch(cmds->List.fromArray)
  } else {
    Tea_Cmd.none
  }

  (newModel, cmd)
}
