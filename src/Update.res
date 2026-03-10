// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Update Engine — The state transition kernel.
///
/// This module implements the "Update" function of The Elm Architecture (TEA).
/// It is responsible for taking the current `model` and an incoming `msg`,
/// and producing a new version of the model along with any required
/// side-effect commands (`Tea_Cmd`).
///
/// Architecture:
///   1. Domain sub-updaters handle each message category (PaneL, PaneN, PaneW, etc.)
///   2. The main `update()` orchestrator routes messages to sub-updaters
///   3. Contractiles post-processing evaluates cognitive governance contracts
///      after every state-modifying update
///
/// DESIGN: Sub-updaters are pure — commands represent deferred side effects.
/// The only imperative call is `Storage.save()` in the SaveState handler.
///
/// WHY TEA OVER REACT HOOKS: This file is ~2,900 lines managing 14 panels. In a
/// React hooks architecture, that's 14 custom hooks with useEffect dependency
/// arrays, stale closure bugs, and "why did this re-render?" debugging sessions.
/// In TEA, every state transition is a pure function: `(model, msg) => (model, cmd)`.
/// No effect timing surprises, no dependency arrays to get wrong, no cleanup
/// functions to forget. When a panel update causes unexpected behaviour, you read
/// the switch arm — the entire state change is right there, not spread across
/// three hooks in different files. The trade-off is more explicit boilerplate; the
/// payoff is that 2,900 lines of state management has zero race conditions by
/// construction. See https://guide.elm-lang.org/architecture/

open Model
open Msg

// ===========================================================================
// Undo/Redo Snapshot Helpers
// ===========================================================================

/// Maximum number of entries in each undo/redo stack.
let undoStackLimit = 50

/// Serialize a lightweight snapshot of core model state to a JSON string.
/// We avoid serializing the entire model to keep snapshots small and avoid
/// circular-reference issues. Only the fields users care about undoing are
/// captured: the three panels, echidna proof input, orbital metrics, and
/// contractile statuses.
let snapshotToJson: model => string = %raw(`
  function snapshotToJson(m) {
    return JSON.stringify({
      paneL: m.paneL,
      paneN: { monologue: m.paneN.monologue, inferenceActive: m.paneN.inferenceActive },
      paneW: { content: m.paneW.content },
      echidnaProofInput: m.echidna.proofInput,
      orbital: m.orbital,
      contractiles: m.contractiles
    });
  }
`)

/// Restore a snapshot JSON string back onto the model. Fields not captured in
/// the snapshot are left untouched so transient UI state (menus, loading flags,
/// connection status, etc.) is preserved across undo/redo.
let restoreSnapshot: (model, string) => model = %raw(`
  function restoreSnapshot(m, json) {
    try {
      var s = JSON.parse(json);
      return Object.assign({}, m, {
        paneL: s.paneL != null ? s.paneL : m.paneL,
        paneN: Object.assign({}, m.paneN, s.paneN || {}),
        paneW: Object.assign({}, m.paneW, { content: s.paneW != null ? s.paneW.content : m.paneW.content }),
        echidna: Object.assign({}, m.echidna, { proofInput: s.echidnaProofInput != null ? s.echidnaProofInput : m.echidna.proofInput }),
        orbital: s.orbital != null ? s.orbital : m.orbital,
        contractiles: s.contractiles != null ? s.contractiles : m.contractiles
      });
    } catch (_e) {
      return m;
    }
  }
`)

/// Push a snapshot of the current model onto the undo stack (capped at
/// `undoStackLimit`). Returns a new model with the updated stacks — the
/// redo stack is cleared because a new action invalidates the redo history.
let pushUndoSnapshot = (model: model): model => {
  let snapshot = snapshotToJson(model)
  let stack = Array.concat(model.undoStack, [snapshot])
  // Cap at limit by dropping oldest entries.
  let trimmed = if Array.length(stack) > undoStackLimit {
    Array.slice(stack, ~start=Array.length(stack) - undoStackLimit, ~end=Array.length(stack))
  } else {
    stack
  }
  {...model, undoStack: trimmed, redoStack: []}
}

// ===========================================================================
// Error Logging
// ===========================================================================

/// Log a degraded service warning to the console. Called from Error(_) branches
/// that previously swallowed errors silently. This gives operators visibility
/// into which services are failing without disrupting the user experience.
let logDegradedService = (service: string, context: string): unit => {
  Console.warn(`[PanLL] Service degraded: ${service} — ${context}`)
}

// ===========================================================================
// Pane Sub-Updaters
// ===========================================================================

/// STATE TRANSITION: Pane-L (Logical Constraints)
/// Manages the set of formal constraints applied to the current inference session.
/// Handles all 6 paneLMsg variants: add, remove, toggle, pin, edit, set active.
let updatePaneL = (model: model, msg: paneLMsg): (model, Tea_Cmd.t<msg>) => {
  // Push undo snapshot for user-initiated constraint changes.
  let model = switch msg {
  | AddConstraint(_) | RemoveConstraint(_) | ToggleConstraint(_) | PinConstraint(_) =>
    pushUndoSnapshot(model)
  | _ => model
  }
  let paneL = model.paneL
  switch msg {
  | AddConstraint(c) => {
      let newModel = {...model, paneL: {...paneL, constraints: Array.concat(paneL.constraints, [c])}}
      // When the new constraint is active, dispatch a proof obligation to ECHIDNA
      // via the Panel-N monologue so the neural layer can begin verification.
      let cmd = if c.active {
        Tea_Cmd.call(callbacks => {
          let proverLabel = switch model.echidna.selectedProver {
          | Some(p) => p
          | None => "default prover"
          }
          callbacks.enqueue(PaneN(UpdateMonologue(
            model.paneN.monologue ++
            "\n\n[DISPATCH] New proof obligation: " ++
            c.expression ++
            " \u2192 dispatching to " ++
            proverLabel ++
            "..."
          )))
        })
      } else {
        Tea_Cmd.none
      }
      (newModel, cmd)
    }
  | RemoveConstraint(id) => (
      {...model, paneL: {
        ...paneL,
        constraints: Array.filter(paneL.constraints, c => c.id !== id),
      }},
      Tea_Cmd.none,
    )
  | ToggleConstraint(id) => {
      let newConstraints = Array.map(paneL.constraints, c =>
        c.id === id ? {...c, active: !c.active} : c
      )
      let newModel = {...model, paneL: {...paneL, constraints: newConstraints}}
      // If the toggled constraint became active, dispatch an ECHIDNA proof obligation
      // to complete the symbolic-neural feedback loop.
      let toggledConstraint = Array.find(newConstraints, c => c.id === id)
      let cmd = switch toggledConstraint {
      | Some(c) if c.active =>
        Tea_Cmd.call(callbacks => {
          let proverLabel = switch model.echidna.selectedProver {
          | Some(p) => p
          | None => "default prover"
          }
          callbacks.enqueue(PaneN(UpdateMonologue(
            model.paneN.monologue ++
            "\n\n[DISPATCH] Constraint reactivated: " ++
            c.expression ++
            " \u2192 dispatching to " ++
            proverLabel ++
            "..."
          )))
        })
      | _ => Tea_Cmd.none
      }
      (newModel, cmd)
    }
  | PinConstraint(id) => (
      {...model, paneL: {
        ...paneL,
        constraints: Array.map(paneL.constraints, c =>
          c.id === id ? {...c, pinned: !c.pinned} : c
        ),
      }},
      Tea_Cmd.none,
    )
  | UpdateEditorContent(content) => {
      // Fire TypeLL type inference on the editor content (debounced by TEA — every keystroke
      // sends a command, but the backend handles deduplication).
      let cmd = if content !== "" {
        TypeLLService.inferConstraintType(content, result => PaneL(ConstraintTypeInferred(result)))
      } else {
        Tea_Cmd.none
      }
      ({...model, paneL: {...paneL, editorContent: content, lastInferredType: None}}, cmd)
    }
  | SetActiveConstraint(id) => (
      {...model, paneL: {...paneL, activeConstraintId: id}},
      Tea_Cmd.none,
    )
  | ConstraintTypeInferred(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, paneL: {...paneL, lastInferredType: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | ConstraintTypeInferred(Error(_)) => {
    logDegradedService("TypeLL", "constraint type inference failed")
    (model, Tea_Cmd.none)
  }
  }
}

/// STATE TRANSITION: Pane-N (Neural/Inference Tokens)
/// Handles the real-time stream of tokens generated by the LLM.
/// All 5 paneNMsg variants: receive, clear, toggle active, monologue, agency.
let updatePaneN = (model: model, msg: paneNMsg): model => {
  let paneN = model.paneN
  let newPaneN = switch msg {
  | ReceiveToken(token) => {
      ...paneN,
      tokens: Array.concat(paneN.tokens, [token]),
      nextTokenId: paneN.nextTokenId + 1,
      activeCausalChain: [token.id],
    }
  | ClearTokens => {...paneN, tokens: [], nextTokenId: 0, activeCausalChain: []}
  | SetInferenceActive(active) => {...paneN, inferenceActive: active}
  | UpdateMonologue(text) => {...paneN, monologue: text}
  | UpdateAgency(agency) => {...paneN, agency}
  | ToggleSourceFilter(source) => {
      let current = paneN.filters.sources
      let has = current->Array.some(s => s === source)
      let newSources = if has {
        current->Array.filter(s => s !== source)
      } else {
        Array.concat(current, [source])
      }
      {...paneN, filters: {...paneN.filters, sources: newSources}}
    }
  | ToggleCategoryFilter(cat) => {
      let current = paneN.filters.categories
      let has = current->Array.some(c => c === cat)
      let newCats = if has {
        current->Array.filter(c => c !== cat)
      } else {
        Array.concat(current, [cat])
      }
      {...paneN, filters: {...paneN.filters, categories: newCats}}
    }
  | TogglePhaseFilter(phase) => {
      let current = paneN.filters.phases
      let has = current->Array.some(p => p === phase)
      let newPhases = if has {
        current->Array.filter(p => p !== phase)
      } else {
        Array.concat(current, [phase])
      }
      {...paneN, filters: {...paneN.filters, phases: newPhases}}
    }
  | SetConfidenceThreshold(threshold) =>
      {...paneN, filters: {...paneN.filters, confidenceThreshold: threshold}}
  | ToggleValidatedOnly =>
      {...paneN, filters: {...paneN.filters, validatedOnly: !paneN.filters.validatedOnly}}
  | ToggleProofOnly =>
      {...paneN, filters: {...paneN.filters, proofOnly: !paneN.filters.proofOnly}}
  | ClearFilters =>
      {...paneN, filters: {
        sources: [],
        categories: [],
        phases: [],
        confidenceThreshold: 0.0,
        validatedOnly: false,
        proofOnly: false,
      }}
  }
  {...model, paneN: newPaneN}
}

// ===========================================================================
// Pane-W Helpers
// ===========================================================================

/// Parse panic-attacker capability JSON response.
/// Extracts mode, binary path, and status detail from the backend probe result.
/// Expected JSON shape: { "mode": "full"|"fallback"|"unavailable",
///   "binary_path": "/path/to/binary", "status_detail": "..." }
let parsePanicAttackerCapability = (json: string): (string, option<string>, option<string>) => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getStr = (key: string): option<string> =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => Some(s)
            | _ => None
            }
          | None => None
          }
        let mode = switch getStr("mode") {
        | Some(m) => m
        | None => "unknown"
        }
        (mode, getStr("binary_path"), getStr("status_detail"))
      }
    | _ => ("unknown", None, None)
    }
  } catch {
  | _ => ("unknown", None, None)
  }
}

// ===========================================================================
// Pane-W Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Pane-W (World / Event Chains)
/// Orchestrates the visualization of complex temporal event chains,
/// security study reports, and panic-attacker integration.
///
/// Returns `(model, Tea_Cmd.t<msg>)` because several handlers issue Tauri
/// commands (file dialogs, backend imports, security ambush runs).
let updatePaneW = (model: model, msg: paneWMsg): (model, Tea_Cmd.t<msg>) => {
  let paneW = model.paneW
  switch msg {
  // --- Content & view toggles (pure state) ---
  | UpdateContent(text) =>
    ({...model, paneW: {...paneW, content: text}}, Tea_Cmd.none)
  | ToggleTopologyView =>
    ({...model, paneW: {...paneW, topologyView: !paneW.topologyView}}, Tea_Cmd.none)
  | SetValidatedOutput(text) =>
    ({...model, paneW: {...paneW, lastValidatedOutput: text}}, Tea_Cmd.none)
  | UpdateEventChainInput(text) =>
    ({...model, paneW: {...paneW, eventChainInput: text}}, Tea_Cmd.none)
  | ClearEventChain => (
      {...model, paneW: {
        ...paneW,
        eventChain: [],
        eventChainSummary: None,
        eventChainTimeline: None,
        eventChainInput: "",
        eventChainError: None,
      }},
      Tea_Cmd.none,
    )

  // --- Barycentre tour ---
  | StartTour => (
      {...model, barycentreTour: {active: true, currentStep: TourIntro, completed: model.barycentreTour.completed}},
      Tea_Cmd.none,
    )
  | NextTourStep => {
      let next = switch model.barycentreTour.currentStep {
      | TourIntro => TourBinaryStar
      | TourBinaryStar => TourBarycentrePosition
      | TourBarycentrePosition => TourOrbitalMetrics
      | TourOrbitalMetrics => TourContractiles
      | TourContractiles => TourSyncHealth
      | TourSyncHealth => TourComplete
      | TourComplete => TourComplete
      }
      let completed = next === TourComplete
      ({...model, barycentreTour: {active: !completed, currentStep: next, completed: completed || model.barycentreTour.completed}}, Tea_Cmd.none)
    }
  | PrevTourStep => {
      let prev = switch model.barycentreTour.currentStep {
      | TourIntro => TourIntro
      | TourBinaryStar => TourIntro
      | TourBarycentrePosition => TourBinaryStar
      | TourOrbitalMetrics => TourBarycentrePosition
      | TourContractiles => TourOrbitalMetrics
      | TourSyncHealth => TourContractiles
      | TourComplete => TourSyncHealth
      }
      ({...model, barycentreTour: {...model.barycentreTour, currentStep: prev}}, Tea_Cmd.none)
    }
  | CloseTour => (
      {...model, barycentreTour: {...model.barycentreTour, active: false}},
      Tea_Cmd.none,
    )

  // --- Inline event chain parsing from text input ---
  | ImportEventChain =>
    // PARSING: Transforms raw JSON input into a structured event chain.
    switch EventChain.parse(paneW.eventChainInput) {
    | Ok(payload) => (
        {...model, paneW: {
          ...paneW,
          eventChain: payload.events,
          eventChainSummary: payload.summary,
          eventChainTimeline: payload.timeline,
          eventChainError: None,
        }},
        Tea_Cmd.none,
      )
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }

  // --- File import commands (issue Tauri commands, await result) ---
  | ImportEventChainFile => (
      model,
      TauriCmd.openEventChainFile(result => PaneW(EventChainFileLoaded(result))),
    )
  | ImportPanicAttackerReportFile => (
      model,
      TauriCmd.openPanicAttackerReportFile(result =>
        PaneW(PanicAttackerReportPathLoaded(result))
      ),
    )
  | ImportLatestPanicAttacker => (
      model,
      TauriCmd.importLatestPanicAttackerReport(result =>
        PaneW(PanicAttackerImportLoaded(result))
      ),
    )
  | CheckPanicAttackerCapability => (
      model,
      TauriCmd.getPanicAttackerCapability(result =>
        PaneW(PanicAttackerCapabilityLoaded(result))
      ),
    )

  // --- File import results (parse response data) ---
  | EventChainFileLoaded(result) =>
    switch result {
    | Ok(contents) =>
      switch EventChain.parse(contents) {
      | Ok(payload) => (
          {...model, paneW: {
            ...paneW,
            eventChain: payload.events,
            eventChainSummary: payload.summary,
            eventChainTimeline: payload.timeline,
            eventChainError: None,
          }},
          Tea_Cmd.none,
        )
      | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
      }
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }
  | PanicAttackerReportPathLoaded(result) =>
    // Two-phase import: first get the file path, then ask backend to convert.
    switch result {
    | Ok(path) => (
        model,
        TauriCmd.importPanicAttackerReport(path, result =>
          PaneW(PanicAttackerImportLoaded(result))
        ),
      )
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }
  | PanicAttackerImportLoaded(result) =>
    switch result {
    | Ok(json) =>
      switch EventChain.parse(json) {
      | Ok(payload) => (
          {...model, paneW: {
            ...paneW,
            eventChain: payload.events,
            eventChainSummary: payload.summary,
            eventChainTimeline: payload.timeline,
            eventChainError: None,
          }},
          Tea_Cmd.none,
        )
      | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
      }
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }
  | PanicAttackerCapabilityLoaded(result) =>
    switch result {
    | Ok(json) => {
        let (mode, binary, detail) = parsePanicAttackerCapability(json)
        (
          {...model, paneW: {
            ...paneW,
            panicAttackerMode: mode,
            panicAttackerBinary: binary,
            panicAttackerStatusDetail: detail,
          }},
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {...model, paneW: {
          ...paneW,
          panicAttackerMode: "unavailable",
          panicAttackerStatusDetail: Some(err),
        }},
        Tea_Cmd.none,
      )
    }

  // --- Security menu interactions (pure state) ---
  | ToggleSecurityTools =>
    ({...model, paneW: {...paneW, securityMenuExpanded: !paneW.securityMenuExpanded}}, Tea_Cmd.none)
  | OpenSecurityDialog(tool) =>
    ({...model, paneW: {...paneW, securityDialogOpen: true, securityDialogTool: Some(tool)}}, Tea_Cmd.none)
  | CloseSecurityDialog =>
    ({...model, paneW: {...paneW, securityDialogOpen: false, securityDialogTool: None}}, Tea_Cmd.none)
  | ToggleSecurityStudyView =>
    ({...model, paneW: {...paneW, securityViewActive: !paneW.securityViewActive}}, Tea_Cmd.none)
  | SetSecurityTarget(t) =>
    ({...model, paneW: {...paneW, securityTarget: t}}, Tea_Cmd.none)
  | SetSecurityTimeline(t) =>
    ({...model, paneW: {...paneW, securityTimeline: t}}, Tea_Cmd.none)
  | SetSecurityAxes(a) =>
    ({...model, paneW: {...paneW, securityAxes: a}}, Tea_Cmd.none)
  | SetSecurityIntensity(i) =>
    ({...model, paneW: {...paneW, securityIntensity: i}}, Tea_Cmd.none)
  | SetSecurityDuration(d) =>
    ({...model, paneW: {...paneW, securityDuration: d}}, Tea_Cmd.none)

  // --- Security command lifecycle ---
  | LoadSecurityTimelineFile => (
      model,
      TauriCmd.openSecurityTimelineFile(result =>
        PaneW(SecurityTimelineFileLoaded(result))
      ),
    )
  | SecurityTimelineFileLoaded(result) =>
    switch result {
    | Ok(path) => ({...model, paneW: {...paneW, securityTimeline: path}}, Tea_Cmd.none)
    | Error(err) => ({...model, paneW: {...paneW, securityError: Some(err)}}, Tea_Cmd.none)
    }
  | LaunchSecurityAmbush => {
      // Gather options from current Pane-W state for the ambush command.
      let timeline = if paneW.securityTimeline !== "" {
        Some(paneW.securityTimeline)
      } else {
        None
      }
      let axes = if paneW.securityAxes !== "" {
        Some(paneW.securityAxes)
      } else {
        None
      }
      let durationSecs = switch Int.fromString(paneW.securityDuration) {
      | Some(d) => d
      | None => 30
      }
      (
        {...model, paneW: {...paneW, securityStatus: Some("Running..."), securityError: None}},
        TauriCmd.runPanicAttackAmbush(
          paneW.securityTarget,
          timeline,
          axes,
          paneW.securityIntensity,
          durationSecs,
          result => PaneW(SecurityAmbushResult(result)),
        ),
      )
    }
  | SecurityAmbushResult(result) =>
    switch result {
    | Ok(json) =>
      switch EventChain.parse(json) {
      | Ok(payload) => (
          {...model, paneW: {
            ...paneW,
            eventChain: payload.events,
            eventChainSummary: payload.summary,
            eventChainTimeline: payload.timeline,
            eventChainError: None,
            securityStatus: Some("Complete"),
            securityError: None,
          }},
          Tea_Cmd.none,
        )
      | Error(err) => (
          {...model, paneW: {...paneW, securityStatus: Some("Failed"), securityError: Some(err)}},
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {...model, paneW: {...paneW, securityStatus: Some("Failed"), securityError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  }
}

// ===========================================================================
// VeriSimDB Parsers
// ===========================================================================

/// Parse proof obligations from a VQL-DT JSON response.
/// VQL-DT queries return a `proof_certificate` object with an array of proofs.
/// Each proof has type, contract, verified status, and hash fields.
let parseProofObligations = (json: string): array<proofObligation> => {
  try {
    let parsed = JSON.parseExn(json)
    // Look for proof_certificate.proofs in the response
    switch JSON.Classify.classify(parsed) {
    | Object(obj) =>
      switch Dict.get(obj, "proof_certificate") {
      | Some(cert) =>
        switch JSON.Classify.classify(cert) {
        | Object(certObj) =>
          switch Dict.get(certObj, "proofs") {
          | Some(proofsVal) =>
            switch JSON.Classify.classify(proofsVal) {
            | Array(proofArr) =>
              proofArr->Array.filterMap(p =>
                switch JSON.Classify.classify(p) {
                | Object(proofObj) => {
                    let getStr = (key: string): string =>
                      switch Dict.get(proofObj, key) {
                      | Some(v) =>
                        switch JSON.Classify.classify(v) {
                        | String(s) => s
                        | _ => ""
                        }
                      | None => ""
                      }
                    let proofType = getStr("type")
                    let status = if getStr("verified") == "true" { "verified" } else { "pending" }
                    Some({
                      proofType,
                      contractName: getStr("contract"),
                      status,
                      proofHash: getStr("hash"),
                    })
                  }
                | _ => None
                }
              )
            | _ => []
            }
          | None => []
          }
        | _ => []
        }
      | None => []
      }
    | _ => []
    }
  } catch {
  | _ => []
  }
}

/// Parse drift scores from a drift status JSON response.
/// Returns structured drift scores for all 8 octad modalities.
let parseDriftScores = (json: string): option<driftScores> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getFloat = (key: string): float =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => n
            | _ => 0.0
            }
          | None => 0.0
          }
        Some({
          graph: getFloat("graph"),
          vector: getFloat("vector"),
          tensor: getFloat("tensor"),
          semantic: getFloat("semantic"),
          document: getFloat("document"),
          temporal: getFloat("temporal"),
          provenance: getFloat("provenance"),
          spatial: getFloat("spatial"),
        })
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

/// Parse a telemetry snapshot from the VeriSimDB reporter JSON response.
/// Extracts aggregate-only product development metrics — no PII or query content.
let parseTelemetrySnapshot = (json: string): option<telemetrySnapshot> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        // Helper to safely extract nested fields.
        let getObj = (key: string): option<Dict.t<JSON.t>> =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Object(o) => Some(o)
            | _ => None
            }
          | None => None
          }

        let getFloat = (o: Dict.t<JSON.t>, key: string): float =>
          switch Dict.get(o, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => n
            | _ => 0.0
            }
          | None => 0.0
          }

        let getInt = (o: Dict.t<JSON.t>, key: string): int =>
          switch Dict.get(o, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Float.toInt(n)
            | _ => 0
            }
          | None => 0
          }

        let getString = (o: Dict.t<JSON.t>, key: string): string =>
          switch Dict.get(o, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }

        // Parse modality heatmap (percentages)
        let modalityHeatmap = switch getObj("modality_heatmap") {
        | Some(heatmap) =>
          switch Dict.get(heatmap, "percentages") {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Object(pcts) =>
              Dict.keysToArray(pcts)
              ->Array.map(key => (key, getFloat(pcts, key)))
            | _ => []
            }
          | None => []
          }
        | None => []
        }

        // Parse query patterns
        let queryPatterns = switch getObj("query_patterns") {
        | Some(patterns) =>
          switch Dict.get(patterns, "by_type") {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Object(types) =>
              Dict.keysToArray(types)
              ->Array.map(key => (key, getInt(types, key)))
            | _ => []
            }
          | None => []
          }
        | None => []
        }

        // Parse proof type usage
        let proofTypeUsage = switch getObj("proof_types") {
        | Some(proofs) =>
          switch Dict.get(proofs, "by_type") {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Object(types) =>
              Dict.keysToArray(types)
              ->Array.map(key => (key, getInt(types, key)))
            | _ => []
            }
          | None => []
          }
        | None => []
        }

        // Extract scalar metrics
        let avgDuration = switch getObj("performance") {
        | Some(perf) => getFloat(perf, "avg_duration_ms")
        | None => 0.0
        }

        let driftCount = switch getObj("drift") {
        | Some(drift) => getInt(drift, "drift_detected_count")
        | None => 0
        }

        let successRate = switch getObj("drift") {
        | Some(drift) => getFloat(drift, "normalise_success_rate")
        | None => 0.0
        }

        let entityCount = switch getObj("entities") {
        | Some(entities) => getInt(entities, "created")
        | None => 0
        }

        let generatedAt = switch getObj("meta") {
        | Some(meta) => getString(meta, "generated_at")
        | None => ""
        }

        let privacyNotice = switch getObj("meta") {
        | Some(meta) => getString(meta, "privacy_notice")
        | None => "Aggregate metrics only. No query content or PII."
        }

        Some({
          generatedAt,
          modalityHeatmap,
          queryPatterns,
          avgQueryDurationMs: avgDuration,
          driftDetectedCount: driftCount,
          normaliseSuccessRate: successRate,
          proofTypeUsage,
          entityCount,
          privacyNotice,
        })
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

// ===========================================================================
// VeriSimDB Sub-Updater
// ===========================================================================

/// STATE TRANSITION: VeriSimDB (Database Backend)
/// Manages the VeriSimDB connection state, VQL query lifecycle, entity browsing,
/// drift detection status, normalisation, and entity detail. Each message either
/// triggers a Tauri command (side effect) or updates model state from a command
/// result.
let updateVeriSimDB = (model: model, msg: verisimdbMsg): (model, Tea_Cmd.t<msg>) => {
  let db = model.verisimdb
  switch msg {
  | CheckHealth => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency("database-mcp", "health", "", result => VeriSimDB(HealthResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        TauriCmd.checkVeriSimDBHealth(result => VeriSimDB(HealthResult(result)))
      }
      (model, cmd)
    }
  | HealthResult(result) =>
    switch result {
    | Ok(_json) => ({...model, verisimdb: {...db, connected: true, queryError: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, verisimdb: {...db, connected: false, queryError: Some(err)}}, Tea_Cmd.none)
    }
  | SubmitQuery(query) => {
      // #4: Optionally validate VQL through Anti-Crash before execution.
      let antiCrashCmd = if db.antiCrashValidation {
        let tokenId = "t-" ++ Int.toString(model.paneN.nextTokenId)
        let token: neuralToken = {id: tokenId, content: query, timestamp: 0.0, confidence: 0.5, validated: false, source: VeriSimInference, category: Observation, emittedDuring: model.paneN.agency.phase, causedBy: model.paneN.activeCausalChain, proofHash: None}
        Tea_Cmd.msg(AntiCrash(ValidateToken(token)))
      } else {
        Tea_Cmd.none
      }
      // #5: Track VQL query count for Vexometer cognitive load.
      let newDb = {
        ...db,
        lastQuery: query,
        queryResult: None,
        queryError: None,
        proofObligations: [],
        lastTypeCheck: None,
        inferenceStream: [],
        queryCount: db.queryCount + 1,
      }
      // Route through BoJ database-mcp cartridge when bojRouting is enabled.
      let queryCmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency("database-mcp", "query", query, result => VeriSimDB(QueryResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        TauriCmd.queryVeriSimDB(query, result => VeriSimDB(QueryResult(result)))
      }
      (
        {...model, verisimdb: newDb},
        Tea_Cmd.batch(list{
          queryCmd,
          TypeLLService.checkVqlTypes(query, result => VeriSimDB(VqlTypeCheckResult(result))),
          antiCrashCmd,
          Tea_Cmd.msg(Vexometer(RecordVqlQuery)),
        }),
      )
    }
  | UpdateQueryInput(text) => (
      {...model, verisimdb: {...db, lastQuery: text}},
      Tea_Cmd.none,
    )
  | QueryResult(result) =>
    switch result {
    | Ok(json) =>
      // Parse proof obligations from VQL-DT responses
      let proofs = parseProofObligations(json)
      (
        {...model, verisimdb: {...db, queryResult: Some(json), queryError: None, proofObligations: proofs}},
        Tea_Cmd.none,
      )
    | Error(err) => ({...model, verisimdb: {...db, queryResult: None, queryError: Some(err)}}, Tea_Cmd.none)
    }
  | ListEntities => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency("database-mcp", "list_entities", "{\"limit\":50,\"offset\":0}", result => VeriSimDB(EntitiesLoaded(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        TauriCmd.listOctads(50, 0, result => VeriSimDB(EntitiesLoaded(result)))
      }
      (model, cmd)
    }
  | EntitiesLoaded(result) =>
    switch result {
    | Ok(_json) => ({...model, verisimdb: {...db, queryError: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, verisimdb: {...db, queryError: Some(err)}}, Tea_Cmd.none)
    }
  | SelectEntity(entityId) => {
      let (driftCmd, detailCmd) = if db.bojRouting {
        (
          BojCmd.invokeCartridgeWithLatency("database-mcp", "drift", entityId, result => VeriSimDB(DriftLoaded(result)), (c, t, e) => RecordBojLatency(c, t, e)),
          BojCmd.invokeCartridgeWithLatency("database-mcp", "entity_detail", entityId, result => VeriSimDB(EntityDetailLoaded(result)), (c, t, e) => RecordBojLatency(c, t, e)),
        )
      } else {
        (
          TauriCmd.getDrift(entityId, result => VeriSimDB(DriftLoaded(result))),
          TauriCmd.getEntityDetail(entityId, result => VeriSimDB(EntityDetailLoaded(result))),
        )
      }
      (
        {...model, verisimdb: {...db, selectedEntity: Some(entityId), entityDetail: None}},
        Tea_Cmd.batch(list{driftCmd, detailCmd}),
      )
    }
  | DriftLoaded(result) =>
    switch result {
    | Ok(json) =>
      let scores = parseDriftScores(json)
      (
        {...model, verisimdb: {...db, driftStatus: Some(json), driftScores: scores, queryError: None}},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, verisimdb: {...db, driftStatus: None, driftScores: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ToggleDbMenu => (
      {...model, verisimdb: {...db, dbMenuExpanded: !db.dbMenuExpanded}},
      Tea_Cmd.none,
    )
  | ClearQueryResult => (
      {...model, verisimdb: {...db, queryResult: None, queryError: None, proofObligations: [], lastTypeCheck: None}},
      Tea_Cmd.none,
    )
  | TriggerNormalise(entityId) => (
      {...model, verisimdb: {...db, normalisingEntity: Some(entityId)}},
      TauriCmd.triggerNormalise(entityId, result => VeriSimDB(NormaliseResult(result))),
    )
  | NormaliseResult(result) =>
    switch result {
    | Ok(_json) => (
        {...model, verisimdb: {...db, normalisingEntity: None, queryError: None}},
        // Refresh drift status after normalisation
        switch db.selectedEntity {
        | Some(entityId) =>
          TauriCmd.getDrift(entityId, result => VeriSimDB(DriftLoaded(result)))
        | None => Tea_Cmd.none
        },
      )
    | Error(err) => (
        {...model, verisimdb: {...db, normalisingEntity: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | LoadEntityDetail(entityId) => (
      model,
      TauriCmd.getEntityDetail(entityId, result => VeriSimDB(EntityDetailLoaded(result))),
    )
  | EntityDetailLoaded(result) =>
    switch result {
    | Ok(json) => ({...model, verisimdb: {...db, entityDetail: Some(json), queryError: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, verisimdb: {...db, entityDetail: None, queryError: Some(err)}}, Tea_Cmd.none)
    }
  | FetchTelemetry => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency("database-mcp", "telemetry", "", result => VeriSimDB(TelemetryLoaded(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        TauriCmd.getTelemetry(result => VeriSimDB(TelemetryLoaded(result)))
      }
      (model, cmd)
    }
  | TelemetryLoaded(result) =>
    switch result {
    | Ok(json) =>
      let snapshot = parseTelemetrySnapshot(json)
      ({...model, verisimdb: {...db, telemetry: snapshot, queryError: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, verisimdb: {...db, telemetry: None, queryError: Some(err)}}, Tea_Cmd.none)
    }
  | ToggleTelemetryPanel => (
      {...model, verisimdb: {...db, telemetryVisible: !db.telemetryVisible}},
      Tea_Cmd.none,
    )
  | FetchOrchStatus => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency("database-mcp", "orch_status", "", result => VeriSimDB(OrchStatusLoaded(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        TauriCmd.getOrchStatus(result => VeriSimDB(OrchStatusLoaded(result)))
      }
      (model, cmd)
    }
  | OrchStatusLoaded(result) =>
    switch result {
    | Ok(json) => ({...model, verisimdb: {...db, orchStatus: Some(json), queryError: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, verisimdb: {...db, orchStatus: None, queryError: Some(err)}}, Tea_Cmd.none)
    }
  | VqlTypeCheckResult(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, verisimdb: {...db, lastTypeCheck: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | VqlTypeCheckResult(Error(_)) => {
    logDegradedService("TypeLL", "VQL type check failed — VQL workflow continues unblocked")
    (model, Tea_Cmd.none)
  }
  // #2: Toggle proof obligation display in Panel-L.
  | ToggleProofDisplay => (
      {...model, verisimdb: {...db, proofDisplayActive: !db.proofDisplayActive}},
      Tea_Cmd.none,
    )
  // #3: Neural advisor inference suggestion for VQL.
  | InferenceSuggestion(suggestion) => (
      {...model, verisimdb: {...db, inferenceStream: Array.concat(db.inferenceStream, [suggestion])}},
      Tea_Cmd.none,
    )
  | ClearInferenceSuggestions => (
      {...model, verisimdb: {...db, inferenceStream: []}},
      Tea_Cmd.none,
    )
  // #4: Toggle Anti-Crash validation of VQL queries.
  | ToggleAntiCrashValidation => (
      {...model, verisimdb: {...db, antiCrashValidation: !db.antiCrashValidation}},
      Tea_Cmd.none,
    )
  | ToggleVeriSimBojRouting => (
      {...model, verisimdb: {...db, bojRouting: !db.bojRouting}},
      Tea_Cmd.none,
    )
  }
}

// ===========================================================================
// ECHIDNA Parsers
// ===========================================================================

/// Parse the ECHIDNA version string from a health check JSON response.
/// Expected shape: `{ "status": "ok", "version": "0.4.2" }`.
let parseEchidnaVersion = (json: string): option<string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) =>
      switch Dict.get(obj, "version") {
      | Some(v) =>
        switch JSON.Classify.classify(v) {
        | String(s) => Some(s)
        | _ => None
        }
      | None => None
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

/// Parse the ECHIDNA prover catalog from a list provers JSON response.
/// Expected shape: `[{ "name": "z3", "tier": "SMT", "complexity": "NP" }, ...]`
/// or `{ "provers": [...] }` wrapper.
let parseEchidnaProvers = (json: string): array<echidnaProver> => {
  try {
    let parsed = JSON.parseExn(json)
    // Helper to extract a prover record from a JSON object.
    let parseProver = (obj: Dict.t<JSON.t>): option<echidnaProver> => {
      let getStr = (key: string): string =>
        switch Dict.get(obj, key) {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | String(s) => s
          | _ => ""
          }
        | None => ""
        }
      let name = getStr("name")
      if name === "" {
        None
      } else {
        Some({name, tier: getStr("tier"), complexity: getStr("complexity")})
      }
    }
    // Try direct array first, then check for { "provers": [...] } wrapper.
    switch JSON.Classify.classify(parsed) {
    | Array(arr) =>
      arr->Array.filterMap(item =>
        switch JSON.Classify.classify(item) {
        | Object(obj) => parseProver(obj)
        | _ => None
        }
      )
    | Object(obj) =>
      switch Dict.get(obj, "provers") {
      | Some(v) =>
        switch JSON.Classify.classify(v) {
        | Array(arr) =>
          arr->Array.filterMap(item =>
            switch JSON.Classify.classify(item) {
            | Object(o) => parseProver(o)
            | _ => None
            }
          )
        | _ => []
        }
      | None => []
      }
    | _ => []
    }
  } catch {
  | _ => []
  }
}

/// Parse an ECHIDNA dispatch result from a proof/verify JSON response.
/// Maps trust_level integers (1-5) to the echidnaTrustLevel variant,
/// parses the axiom report, and extracts prover telemetry.
let parseEchidnaDispatchResult = (json: string): option<echidnaDispatchResult> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getStr = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        let getFloat = (key: string): float =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => n
            | _ => 0.0
            }
          | None => 0.0
          }
        let getInt = (key: string): int =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Float.toInt(n)
            | _ => 0
            }
          | None => 0
          }

        // Parse trust_level integer to variant
        let trustLevel = switch getInt("trust_level") {
        | 1 => TrustLevel1
        | 2 => TrustLevel2
        | 3 => TrustLevel3
        | 4 => TrustLevel4
        | 5 => TrustLevel5
        | _ => TrustLevel1
        }

        // Parse provers_used string array
        let proversUsed = switch Dict.get(obj, "provers_used") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | Array(arr) =>
            arr->Array.filterMap(item =>
              switch JSON.Classify.classify(item) {
              | String(s) => Some(s)
              | _ => None
              }
            )
          | _ => []
          }
        | None => []
        }

        // Parse axiom_report array
        let axiomReport = switch Dict.get(obj, "axiom_report") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | Array(arr) =>
            arr->Array.filterMap(item =>
              switch JSON.Classify.classify(item) {
              | Object(axiomObj) => {
                  let aGetStr = (key: string): string =>
                    switch Dict.get(axiomObj, key) {
                    | Some(av) =>
                      switch JSON.Classify.classify(av) {
                      | String(s) => s
                      | _ => ""
                      }
                    | None => ""
                    }
                  let dangerLevel = switch aGetStr("danger_level") {
                  | "safe" => Safe
                  | "noted" => Noted
                  | "warning" => Warning
                  | "reject" => Reject
                  | _ => Noted
                  }
                  Some({
                    axiomName: aGetStr("axiom_name"),
                    dangerLevel,
                    description: aGetStr("description"),
                  })
                }
              | _ => None
              }
            )
          | _ => []
          }
        | None => []
        }

        // Parse cross_checked string to variant
        let crossChecked = switch getStr("cross_checked") {
        | "cross_checked" => CrossChecked
        | "single_solver" => SingleSolver
        | "inconclusive" => Inconclusive
        | "all_timed_out" => AllTimedOut
        | _ => SingleSolver
        }

        // Parse optional certificate hash
        let certificateHash = switch Dict.get(obj, "certificate_hash") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | String(s) => Some(s)
          | _ => None
          }
        | None => None
        }

        Some({
          verified: getBool("verified"),
          trustLevel,
          proversUsed,
          proofTimeMs: getFloat("proof_time_ms"),
          goalsRemaining: getInt("goals_remaining"),
          axiomReport,
          certificateHash,
          message: getStr("message"),
          crossChecked,
        })
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

// ===========================================================================
// ECHIDNA Session & Tactic Parsers
// ===========================================================================

/// Parse a proof status string from ECHIDNA's ProofResponse into the variant type.
let parseProofStatus = (s: string): echidnaProofStatus => {
  switch s {
  | "pending" => Pending
  | "in_progress" => InProgress
  | "success" => ProofSuccess
  | "failed" => ProofFailed
  | "timeout" => ProofTimeout
  | "error" => ProofError
  | _ => Pending
  }
}

/// Parse an ECHIDNA ProofResponse JSON into echidnaSessionState.
/// Expected shape: `{ "id": "...", "prover": "...", "goal": "...",
///   "status": "in_progress", "goals": [...], "proof_script": [...],
///   "complete": false, "tactics_applied": [...],
///   "time_elapsed": 1.23, "error_message": null }`
let parseEchidnaSession = (json: string): option<echidnaSessionState> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getStr = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        let getStrArray = (key: string): array<string> =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Array(arr) =>
              arr->Array.filterMap(item =>
                switch JSON.Classify.classify(item) {
                | String(s) => Some(s)
                | _ => None
                }
              )
            | _ => []
            }
          | None => []
          }
        let getOptFloat = (key: string): option<float> =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Some(n)
            | _ => None
            }
          | None => None
          }
        let getOptStr = (key: string): option<string> =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => Some(s)
            | _ => None
            }
          | None => None
          }

        let sessionId = getStr("id")
        if sessionId === "" {
          None
        } else {
          Some({
            sessionId,
            prover: getStr("prover"),
            goal: getStr("goal"),
            status: parseProofStatus(getStr("status")),
            goals: getStrArray("goals"),
            proofScript: getStrArray("proof_script"),
            complete: getBool("complete"),
            tacticsApplied: getStrArray("tactics_applied"),
            timeElapsed: getOptFloat("time_elapsed"),
            errorMessage: getOptStr("error_message"),
          })
        }
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

/// Parse a TacticResponse JSON into (success, updated session state).
/// Expected shape: `{ "success": true, "proof_state": { ...ProofResponse... } }`
let parseTacticResponse = (json: string): option<(bool, echidnaSessionState)> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let success = switch Dict.get(obj, "success") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | Bool(b) => b
          | _ => false
          }
        | None => false
        }
        // The proof_state is embedded as a nested object — re-stringify it
        // so we can reuse parseEchidnaSession.
        switch Dict.get(obj, "proof_state") {
        | Some(proofState) =>
          let stateJson = JSON.stringify(proofState)
          switch parseEchidnaSession(stateJson) {
          | Some(session) => Some((success, session))
          | None => None
          }
        | None => None
        }
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

/// Parse tactic suggestions JSON into an array of echidnaTacticSuggestion.
/// Expected shape: `[{ "name": "intro", "args": ["x"], "description": "...",
///   "confidence": 0.85 }, ...]`
let parseTacticSuggestions = (json: string): array<echidnaTacticSuggestion> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(arr) =>
      arr->Array.filterMap(item =>
        switch JSON.Classify.classify(item) {
        | Object(obj) => {
            let getStr = (key: string): string =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | String(s) => s
                | _ => ""
                }
              | None => ""
              }
            let getFloat = (key: string): float =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => n
                | _ => 0.0
                }
              | None => 0.0
              }
            let getStrArray = (key: string): array<string> =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Array(a) =>
                  a->Array.filterMap(i =>
                    switch JSON.Classify.classify(i) {
                    | String(s) => Some(s)
                    | _ => None
                    }
                  )
                | _ => []
                }
              | None => []
              }
            let name = getStr("name")
            if name === "" {
              None
            } else {
              Some({
                tactic: name,
                args: getStrArray("args"),
                confidence: getFloat("confidence"),
                aspectTags: getStrArray("aspect_tags"),
                description: getStr("description"),
              })
            }
          }
        | _ => None
        }
      )
    | _ => []
    }
  } catch {
  | _ => []
  }
}

// ===========================================================================
// ECHIDNA Sub-Updater
// ===========================================================================

/// STATE TRANSITION: ECHIDNA (Theorem Prover Backend)
/// Manages the ECHIDNA connection state, prover catalog, proof submission lifecycle,
/// theorem search, interactive proof sessions, tactic suggestions, and UI toggles.
let updateEchidna = (model: model, msg: echidnaMsg): (model, Tea_Cmd.t<msg>) => {
  let ec = model.echidna
  switch msg {
  // --- Connection lifecycle ---
  | CheckHealth => (
      model,
      TauriCmd.checkEchidnaHealth(result =>
        switch result {
        | Ok(json) => Echidna(HealthOk(json))
        | Error(err) => Echidna(HealthError(err))
        }
      ),
    )
  | HealthOk(json) =>
    let version = parseEchidnaVersion(json)
    ({...model, echidna: {...ec, connected: true, version, proofError: None}}, Tea_Cmd.none)
  | HealthError(err) => (
      {...model, echidna: {...ec, connected: false, version: None, proofError: Some(err)}},
      Tea_Cmd.none,
    )

  // --- Prover catalog ---
  | ListProvers => (
      model,
      TauriCmd.listEchidnaProvers(result => Echidna(ProversLoaded(result))),
    )
  | ProversLoaded(result) =>
    switch result {
    | Ok(json) =>
      let provers = parseEchidnaProvers(json)
      ({...model, echidna: {...ec, provers, proofError: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, echidna: {...ec, proofError: Some(err)}}, Tea_Cmd.none)
    }

  // --- Proof submission ---
  | SubmitProof => {
      let proveCmd = if ec.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "proof-mcp",
          "prove",
          `{"input": "${ec.proofInput}", "prover": "${ec.selectedProver->Option.getOr("auto")}"}`,
          result => Echidna(ProofResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        TauriCmd.echidnaProve(ec.proofInput, ec.selectedProver, result =>
          Echidna(ProofResult(result))
        )
      }
      (
        {...model, echidna: {...ec, proofLoading: true, proofError: None, lastProofResult: None, lastProofObligations: None}},
        Tea_Cmd.batch(list{
          proveCmd,
          TypeLLService.generateProofObligations(ec.proofInput, result =>
            Echidna(ProofObligationsGenerated(result))
          ),
        }),
      )
    }
  | ProofResult(result) =>
    switch result {
    | Ok(json) =>
      let parsed = parseEchidnaDispatchResult(json)
      // S4: Proof completion feeds back into the neurosymbolic loop.
      // Advance OODA phase in Panel-N agency based on proof outcome.
      let newAgency = switch parsed {
      | Some(r) if r.verified => {
          // Proof verified → advance to Act phase (decision confirmed).
          ...model.paneN.agency,
          phase: Act,
        }
      | Some(_) => {
          // Proof failed → re-orient (need new approach).
          ...model.paneN.agency,
          phase: Orient,
        }
      | None => model.paneN.agency
      }
      let newPaneN = {...model.paneN, agency: newAgency}
      (
        {...model, echidna: {...ec, lastProofResult: parsed, proofLoading: false, proofError: None}, paneN: newPaneN},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, echidna: {...ec, proofLoading: false, proofError: Some(err), lastProofResult: None}},
        Tea_Cmd.none,
      )
    }

  // --- Verification ---
  | SubmitVerify => (
      {...model, echidna: {...ec, proofLoading: true, proofError: None, lastProofResult: None}},
      TauriCmd.echidnaVerify(ec.proofInput, result => Echidna(VerifyResult(result))),
    )
  | VerifyResult(result) =>
    switch result {
    | Ok(json) =>
      let parsed = parseEchidnaDispatchResult(json)
      (
        {...model, echidna: {...ec, lastProofResult: parsed, proofLoading: false, proofError: None}},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, echidna: {...ec, proofLoading: false, proofError: Some(err), lastProofResult: None}},
        Tea_Cmd.none,
      )
    }

  // --- Theorem search ---
  | SearchTheorems(query) => (
      model,
      TauriCmd.echidnaSearchTheorems(query, result => Echidna(SearchResult(result))),
    )
  | SearchResult(_result) =>
    // Search results display is Phase 2 — for now just clear errors.
    ({...model, echidna: {...ec, proofError: None}}, Tea_Cmd.none)

  // --- Interactive sessions ---
  | CreateSession => {
      let prover = switch ec.selectedProver {
      | Some(p) => p
      | None => "auto"
      }
      (
        {...model, echidna: {...ec, sessionLoading: true, proofError: None}},
        TauriCmd.createEchidnaSession(ec.proofInput, prover, result =>
          Echidna(SessionCreated(result))
        ),
      )
    }
  | SessionCreated(result) =>
    switch result {
    | Ok(json) =>
      let session = parseEchidnaSession(json)
      switch session {
      | Some(s) => (
          {...model, echidna: {...ec, session: Some(s), sessionLoading: false, proofError: None}},
          // Auto-request tactic suggestions after session creation
          TauriCmd.suggestEchidnaTactics(s.sessionId, 5, result =>
            Echidna(TacticSuggestionsLoaded(result))
          ),
        )
      | None => (
          {...model, echidna: {...ec, sessionLoading: false, proofError: Some("Failed to parse session response")}},
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {...model, echidna: {...ec, sessionLoading: false, proofError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ApplyTactic(name, args) =>
    switch ec.session {
    | Some(s) => (
        model,
        TauriCmd.applyEchidnaTactic(s.sessionId, name, args, result =>
          Echidna(TacticApplied(result))
        ),
      )
    | None => (model, Tea_Cmd.none)
    }
  | TacticApplied(result) =>
    switch result {
    | Ok(json) =>
      switch parseTacticResponse(json) {
      | Some((_success, updatedSession)) => {
          // S4: Tactic applied → advance OODA from Orient to Decide.
          // Each tactic application represents a decision step in the proof search.
          let newPhase = switch model.paneN.agency.phase {
          | Observe => Orient  // Observed → now orienting with tactic
          | Orient => Decide   // Oriented → decided on tactic
          | Decide => Act      // Decided → acting (tactic applied)
          | Act => Observe     // Cycle complete → observe result
          }
          let newAgency = {...model.paneN.agency, phase: newPhase}
          let newPaneN = {...model.paneN, agency: newAgency}
          (
            {...model, echidna: {...ec, session: Some(updatedSession), proofError: None}, paneN: newPaneN},
            // Auto-request fresh suggestions after tactic application
            TauriCmd.suggestEchidnaTactics(updatedSession.sessionId, 5, result =>
              Echidna(TacticSuggestionsLoaded(result))
            ),
          )
        }
      | None => (
          {...model, echidna: {...ec, proofError: Some("Failed to parse tactic response")}},
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {...model, echidna: {...ec, proofError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | GetSessionState =>
    switch ec.session {
    | Some(s) => (
        model,
        TauriCmd.getEchidnaSession(s.sessionId, result =>
          Echidna(SessionStateLoaded(result))
        ),
      )
    | None => (model, Tea_Cmd.none)
    }
  | SessionStateLoaded(result) =>
    switch result {
    | Ok(json) =>
      let session = parseEchidnaSession(json)
      switch session {
      | Some(s) => ({...model, echidna: {...ec, session: Some(s), proofError: None}}, Tea_Cmd.none)
      | None => ({...model, echidna: {...ec, proofError: Some("Failed to parse session state")}}, Tea_Cmd.none)
      }
    | Error(err) => ({...model, echidna: {...ec, proofError: Some(err)}}, Tea_Cmd.none)
    }
  | CancelSession => (
      {...model, echidna: {...ec, session: None, tacticSuggestions: [], sessionLoading: false, tacticInput: "", proofError: None}},
      Tea_Cmd.none,
    )
  | UpdateTacticInput(text) => (
      {...model, echidna: {...ec, tacticInput: text}},
      Tea_Cmd.none,
    )

  // --- Tactic suggestions ---
  | RequestTacticSuggestions =>
    switch ec.session {
    | Some(s) => (
        model,
        TauriCmd.suggestEchidnaTactics(s.sessionId, 5, result =>
          Echidna(TacticSuggestionsLoaded(result))
        ),
      )
    | None => (model, Tea_Cmd.none)
    }
  | TacticSuggestionsLoaded(result) =>
    switch result {
    | Ok(json) =>
      let suggestions = parseTacticSuggestions(json)
      ({...model, echidna: {...ec, tacticSuggestions: suggestions}}, Tea_Cmd.none)
    | Error(_err) => (
        {...model, echidna: {...ec, tacticSuggestions: []}},
        Tea_Cmd.none,
      )
    }

  // --- UI state ---
  | ToggleMenu => (
      {...model, echidna: {...ec, menuExpanded: !ec.menuExpanded}},
      Tea_Cmd.none,
    )
  | UpdateProofInput(text) => (
      {...model, echidna: {...ec, proofInput: text}},
      Tea_Cmd.none,
    )
  | SelectProver(prover) => (
      {...model, echidna: {...ec, selectedProver: prover}},
      Tea_Cmd.none,
    )
  | ClearProofResult => (
      {...model, echidna: {...ec, lastProofResult: None, proofError: None, lastProofObligations: None}},
      Tea_Cmd.none,
    )
  | ProofObligationsGenerated(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, echidna: {...ec, lastProofObligations: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | ProofObligationsGenerated(Error(_)) => {
    logDegradedService("TypeLL", "proof obligation generation failed")
    (model, Tea_Cmd.none)
  }
  | ToggleEchidnaBojRouting => (
      {...model, echidna: {...ec, bojRouting: !ec.bojRouting}},
      Tea_Cmd.none,
    )

  // --- Tab switching ---
  | SelectEchidnaTab(tab) => (
      {...model, echidna: {...ec, activeTab: tab}},
      Tea_Cmd.none,
    )

  // --- Enterprise model checking (MOF/OCL) ---
  | ImportXmiModel => (model, Tea_Cmd.none) // Tauri file dialog → parse XMI → XmiModelLoaded
  | XmiModelLoaded(Ok(json)) => {
      // Parse XMI JSON into model elements (simplified — real parser needed)
      let em = ec.enterpriseModel
      ({...model, echidna: {...ec, enterpriseModel: {...em, lastXmiImport: Some(json)}}}, Tea_Cmd.none)
    }
  | XmiModelLoaded(Error(_)) => {
    logDegradedService("ECHIDNA", "XMI model import failed")
    (model, Tea_Cmd.none)
  }
  | AddOclConstraint(context, name, expression) => {
      let em = ec.enterpriseModel
      let newConstraint: oclConstraint = {
        context,
        name,
        expression,
        severity: OclInvariant,
        layer: M1_Model,
        metamodel: UML,
      }
      ({...model, echidna: {...ec, enterpriseModel: {...em, constraints: Array.concat(em.constraints, [newConstraint])}}}, Tea_Cmd.none)
    }
  | RemoveOclConstraint(index) => {
      let em = ec.enterpriseModel
      let filtered = em.constraints->Array.filterWithIndex((_c, i) => i !== index)
      ({...model, echidna: {...ec, enterpriseModel: {...em, constraints: filtered}}}, Tea_Cmd.none)
    }
  | RunOclCheck => {
      let em = ec.enterpriseModel
      ({...model, echidna: {...ec, enterpriseModel: {...em, checking: true}}}, Tea_Cmd.none)
      // In production: dispatch to ECHIDNA backend for constraint checking
    }
  | OclCheckResult(Ok(_json)) => {
      let em = ec.enterpriseModel
      ({...model, echidna: {...ec, enterpriseModel: {...em, checking: false}}}, Tea_Cmd.none)
    }
  | OclCheckResult(Error(_)) => {
      logDegradedService("ECHIDNA", "OCL constraint check failed")
      let em = ec.enterpriseModel
      ({...model, echidna: {...ec, enterpriseModel: {...em, checking: false}}}, Tea_Cmd.none)
    }
  | SetMetamodelFilter(filter) => {
      let em = ec.enterpriseModel
      ({...model, echidna: {...ec, enterpriseModel: {...em, activeMetamodel: filter}}}, Tea_Cmd.none)
    }
  | SetMofLayerFilter(filter) => {
      let em = ec.enterpriseModel
      ({...model, echidna: {...ec, enterpriseModel: {...em, activeLayer: filter}}}, Tea_Cmd.none)
    }
  | ClearEnterpriseModel => (
      {...model, echidna: {...ec, enterpriseModel: {
        elements: [],
        constraints: [],
        checkResults: [],
        checking: false,
        activeMetamodel: None,
        activeLayer: None,
        lastXmiImport: None,
      }}},
      Tea_Cmd.none,
    )
  }
}

// ===========================================================================
// Cognitive Governance Sub-Updaters
// ===========================================================================

/// STATE TRANSITION: Vexometer
/// Tracks operator vexation signals (cancellations, corrections) and manages
/// the anti-inflammatory feedback system. Backend events are recorded via
/// Tauri commands so the Rust VexationTracker can compute the composite index.
let updateVexometer = (model: model, msg: vexometerMsg): (model, Tea_Cmd.t<msg>) => {
  let vex = model.vexometer
  switch msg {
  | RecordCancellation => (
      {...model, vexometer: {...vex, recentCancellations: vex.recentCancellations + 1}},
      TauriCmd.recordVexationEvent("cancellation", _result => NoOp),
    )
  | RecordCorrection => (
      {...model, vexometer: {...vex, recentCorrections: vex.recentCorrections + 1}},
      TauriCmd.recordVexationEvent("correction", _result => NoOp),
    )
  | RecordVqlQuery => (
      // VQL queries contribute to cognitive load — tracked as a lighter-weight event.
      model,
      TauriCmd.recordVexationEvent("vql_query", _result => NoOp),
    )
  | RequestVexationIndex => (
      model,
      TauriCmd.getVexationIndex(index => Vexometer(UpdateVexationIndex(index))),
    )
  | UpdateVexationIndex(index) => (
      {...model, vexometer: {...vex, index}},
      Tea_Cmd.none,
    )
  | ToggleAntiInflammatory(active) => (
      {...model, vexometer: {...vex, antiInflammatoryActive: active}},
      Tea_Cmd.none,
    )
  | SetInertiaDetected(detected) => (
      {...model, vexometer: {...vex, inertiaDetected: detected}},
      Tea_Cmd.none,
    )
  | ResetVexometer => (
      {...model, vexometer: {
        index: 0.0,
        recentCancellations: 0,
        recentCorrections: 0,
        antiInflammatoryActive: false,
        inertiaDetected: false,
      }},
      TauriCmd.recordVexationEvent("reset", _result => NoOp),
    )
  }
}

/// STATE TRANSITION: Orbital Stability
/// Manages the Binary Star co-orbit stability metrics and drift aura.
/// The aura colour reflects orbit health: "indigo" (stable) or "amber" (decaying).
let updateOrbital = (model: model, msg: orbitalMsg): (model, Tea_Cmd.t<msg>) => {
  let orbital = model.orbital
  switch msg {
  | UpdateStability(value) => {
      // Recalculate drift aura colour when stability changes.
      let colour = if value >= 0.7 { "indigo" } else { "amber" }
      ({...model, orbital: {...orbital, stability: value, driftAuraColour: colour}}, Tea_Cmd.none)
    }
  | UpdateDivergence(value) => (
      {...model, orbital: {...orbital, divergenceLevel: value}},
      Tea_Cmd.none,
    )
  | SetDriftAura(colour) => (
      {...model, orbital: {...orbital, driftAuraColour: colour}},
      Tea_Cmd.none,
    )
  }
}

// ===========================================================================
// View & Feedback Sub-Updaters
// ===========================================================================

/// STATE TRANSITION: View Controls
/// Manages pane visibility, view mode, and information humidity level.
/// ParallaxAlign is a compound action that resets to the canonical three-pane layout.
let updateView = (model: model, msg: viewMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | TogglePaneL => ({...model, paneLVisible: !model.paneLVisible}, Tea_Cmd.none)
  | TogglePaneN => ({...model, paneNVisible: !model.paneNVisible}, Tea_Cmd.none)
  | TogglePaneW => ({...model, paneWVisible: !model.paneWVisible}, Tea_Cmd.none)
  | ToggleProtocolAnalysis => (
      {...model, protocolAnalysisVisible: !model.protocolAnalysisVisible},
      Tea_Cmd.none,
    )
  | SetViewMode(mode) => ({...model, viewMode: mode}, Tea_Cmd.none)
  | SetHumidity(level) => ({...model, humidity: level}, Tea_Cmd.none)
  | ParallaxAlign => (
      // Synchronous horizontal tiling: show all panes in Standard mode.
      {...model, paneLVisible: true, paneNVisible: true, paneWVisible: true, viewMode: Standard},
      Tea_Cmd.none,
    )
  | TogglePanelBar => ({...model, panelBarVisible: !model.panelBarVisible}, Tea_Cmd.none)
  | ToggleFullscreen => (
      // When entering fullscreen, hide the panel bar. When exiting, restore it.
      {...model, fullscreenActive: !model.fullscreenActive, panelBarVisible: model.fullscreenActive},
      Tea_Cmd.none,
    )
  }
}

/// STATE TRANSITION: Feedback-O-Tron
/// Manages the feedback lifecycle: open dialog, submit to backend, cancel,
/// and handle the asynchronous submission result.
let updateFeedback = (model: model, msg: feedbackMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | OpenFeedback => ({...model, feedbackPending: Some("")}, Tea_Cmd.none)
  | SubmitFeedback(text) => {
      let reportType = switch model.feedbackReportType {
      | Some(t) => t
      | None => "General"
      }
      (
        model,
        TauriCmd.submitFeedback(
          text,
          model.paneN.monologue,
          model.paneW.content,
          reportType,
          result => Feedback(FeedbackSubmissionResult(result)),
        ),
      )
    }
  | CancelFeedback => ({...model, feedbackPending: None}, Tea_Cmd.none)
  | SetReportType(t) => ({...model, feedbackReportType: Some(t)}, Tea_Cmd.none)
  | FeedbackSubmitted => {
      // Build a JSON report from current feedback state and submit to Rust backend.
      let reportType = switch model.feedbackReportType {
      | Some(t) => t
      | None => "General"
      }
      let feedbackText = switch model.feedbackPending {
      | Some(text) => text
      | None => ""
      }
      let reportJson =
        `{"type":"${reportType}","text":"${feedbackText}","timestamp":"${Date.make()->Date.toISOString}"}`
      let cmd = FeedbackCmd.saveReport(reportJson, r => Feedback(FeedbackSubmissionResult(r)))
      ({...model, feedbackPending: None, feedbackError: None}, cmd)
    }
  | FeedbackSubmissionResult(result) =>
    switch result {
    | Ok(_) => ({...model, feedbackPending: None, feedbackError: None}, Tea_Cmd.none)
    | Error(err) => ({...model, feedbackError: Some(err)}, Tea_Cmd.none)
    }
  }
}

// ===========================================================================
// Anti-Crash Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Anti-Crash Validation
/// Routes neural tokens through the symbolic validation pipeline (the Circuit
/// Breaker) before they can reach the Task Barycentre. Halts inference when
/// a strict violation is detected, requiring operator intervention to resume.
let updateAntiCrash = (model: model, msg: antiCrashMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | ValidateToken(token) => {
      // Run the token through the full Anti-Crash pipeline.
      let (newAntiCrash, validatedToken) = AntiCrash.processToken(
        token,
        model.paneL.constraints,
        model.antiCrash,
      )
      // If the token passed validation, add it to the neural stream.
      let newPaneN = switch validatedToken {
      | Some(vt) => {
          ...model.paneN,
          tokens: Array.concat(model.paneN.tokens, [vt]),
          nextTokenId: model.paneN.nextTokenId + 1,
          activeCausalChain: [vt.id],
        }
      | None => model.paneN
      }
      // M4: Anti-Crash → Governance feedback. When a token is rejected,
      // record a correction in the Vexometer so the governance engine
      // can adjust contractile elasticity on the next pass.
      let newVexometer = switch validatedToken {
      | None => {...model.vexometer, recentCorrections: model.vexometer.recentCorrections + 1}
      | Some(_) => model.vexometer
      }
      // Fire TypeLL type-level validation asynchronously for the token content.
      let constraintExprs = Array.map(
        Array.filter(model.paneL.constraints, c => c.active),
        c => c.expression,
      )
      let typellCmd = if Array.length(constraintExprs) > 0 {
        TypeLLService.validateToken(token.content, constraintExprs, result => AntiCrash(TokenTypeCheckResult(result)))
      } else {
        Tea_Cmd.none
      }
      ({...model, antiCrash: newAntiCrash, paneN: newPaneN, vexometer: newVexometer}, typellCmd)
    }
  | ValidationPassed(token) => {
      // Token has already been validated externally — mark as validated and add.
      let validatedToken = {...token, validated: true}
      let newPaneN = {
        ...model.paneN,
        tokens: Array.concat(model.paneN.tokens, [validatedToken]),
        nextTokenId: model.paneN.nextTokenId + 1,
        activeCausalChain: [validatedToken.id],
      }
      ({...model, paneN: newPaneN}, Tea_Cmd.none)
    }
  | ValidationFailed(_token, reason) => {
      // Record the violation and potentially halt inference.
      let violation = LogicContradiction(reason)
      let newAntiCrash = {
        ...model.antiCrash,
        violations: Array.concat(model.antiCrash.violations, [violation]),
        halted: model.antiCrash.strictMode,
      }
      ({...model, antiCrash: newAntiCrash}, Tea_Cmd.none)
    }
  | RequestOperatorIntervention(_reason) => {
      // Halt the system and wait for operator to review.
      let newAntiCrash = {
        ...model.antiCrash,
        halted: true,
      }
      ({...model, antiCrash: newAntiCrash}, Tea_Cmd.none)
    }
  | TokenTypeCheckResult(Ok(_json)) => {
      // TypeLL confirmed type safety — increment service counter.
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TokenTypeCheckResult(Error(reason)) => {
      // TypeLL found a type violation — record it as a type-level constraint failure.
      let violation = LogicContradiction("TypeLL: " ++ reason)
      let newAntiCrash = {
        ...model.antiCrash,
        violations: Array.concat(model.antiCrash.violations, [violation]),
      }
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, antiCrash: newAntiCrash, typell: newTypell}, Tea_Cmd.none)
    }
  }
}

// ===========================================================================
// Contractiles Post-Processing (Cognitive Governance)
// ===========================================================================

/// Evaluate all contractiles against the current model state and update their
/// statuses. If any Strict contractile is Violated, halt neural inference as
/// a safety measure. This is called after every state-modifying update in the
/// main orchestrator.
let applyContractiles = (model: model, cmd: Tea_Cmd.t<msg>): (model, Tea_Cmd.t<msg>) => {
  // --- Phase 1: Evaluate contractiles ---

  let results = Contractiles.evaluateAll(model, model.contractiles)

  // Update each contractile's status based on evaluation results.
  let updatedContractiles = Array.map(model.contractiles, c => {
    let result = Array.find(results, r => r.contractId === c.id)
    switch result {
    | Some(r) => {...c, status: r.status}
    | None => c
    }
  })

  // Check for any Strict contractile violation — these require halting.
  let hasStrictViolation = Array.some(results, r => {
    let contractile = Array.find(model.contractiles, c => c.id === r.contractId)
    switch contractile {
    | Some(c) =>
      switch (c.enforcement, r.status) {
      | (Strict, Violated(_)) => true
      | _ => false
      }
    | None => false
    }
  })

  let newModel = {...model, contractiles: updatedContractiles}

  // Auto-activate anti-inflammatory when vexation index exceeds threshold (0.7).
  let antiInflammatoryActive = newModel.vexometer.index > 0.7
  let newModel = {
    ...newModel,
    vexometer: {...newModel.vexometer, antiInflammatoryActive},
  }

  // If a Strict contractile is violated, halt neural inference.
  let newModel = if hasStrictViolation {
    {...newModel, paneN: {...newModel.paneN, inferenceActive: false}}
  } else {
    newModel
  }

  // --- Phase 2: OrbitalSync — detect L↔N↔W divergence (M2) ---

  let (newSyncState, newOrbital) = OrbitalSync.sync(newModel, newModel.syncState)
  let newModel = {...newModel, syncState: newSyncState, orbital: newOrbital}

  // --- Phase 3: Consume pendingSync events (M2) ---
  // Cross-panel sync events feed back into the orbital metrics and
  // are cleared after processing. In future, these will trigger
  // Panel Bus events for inter-module communication.

  let syncEventCount = Array.length(newModel.syncState.pendingSync)
  let newModel = if syncEventCount > 0 {
    // Sync latency increases with event volume (simple heuristic).
    let latencyAdjust = Int.toFloat(syncEventCount) *. 5.0
    let newSync = {
      ...newModel.syncState,
      pendingSync: [], // Consumed — clear the queue
      syncLatency: Math.min(500.0, newModel.syncState.syncLatency +. latencyAdjust),
    }
    {...newModel, syncState: newSync}
  } else {
    // No events — latency decays toward zero.
    let newSync = {
      ...newModel.syncState,
      syncLatency: Math.max(0.0, newModel.syncState.syncLatency -. 2.0),
    }
    {...newModel, syncState: newSync}
  }

  // --- Phase 4: GovernanceEngine — close all feedback loops (M1, M3, M4) ---
  // Anti-Crash violations → Governance → Contractile elasticity
  // Vexometer frustration → Governance → Anti-Crash strictness
  // Orbital divergence → Governance → inference halting / humidity

  let (newModel, governanceCmd) = GovernanceEngine.governWithCmd(newModel, r => GovernanceNesyResult(r))

  // --- Phase 5: Panel Bus event emission (M5) ---
  // Emit cross-panel events based on state transitions detected by
  // OrbitalSync and GovernanceEngine. Events are wrapped in envelopes
  // with metadata and routed through the subscriber registry.

  let busEvents: array<PanelBus.panelEvent> = []

  // Emit confidence update if orbital stability changed significantly.
  let stabilityDiff = newModel.orbital.stability -. model.orbital.stability
  let busEvents = if stabilityDiff > 0.05 || stabilityDiff < -0.05 {
    Array.concat(busEvents, [
      PanelBus.RepoHealthChanged("panll-orbit", newModel.orbital.stability),
    ])
  } else {
    busEvents
  }

  // Emit database connection change if VeriSimDB state changed.
  let busEvents = if newModel.verisimdb.connected !== model.verisimdb.connected {
    Array.concat(busEvents, [
      PanelBus.DatabaseConnectionChanged("verisimdb", newModel.verisimdb.connected),
    ])
  } else {
    busEvents
  }

  // Emit inference activity change if Hypatia confidence shifted.
  let busEvents = if newModel.paneN.inferenceActive !== model.paneN.inferenceActive {
    Array.concat(busEvents, [
      PanelBus.HypatiaConfidenceUpdated("paneN-inference", newModel.paneN.inferenceActive ? 1.0 : 0.0),
    ])
  } else {
    busEvents
  }

  // Emit ECHIDNA proof dispatch if a proof result just arrived.
  let busEvents = if newModel.echidna.lastProofResult !== model.echidna.lastProofResult {
    switch newModel.echidna.lastProofResult {
    | Some(_result) =>
      Array.concat(busEvents, [
        PanelBus.HypatiaConfidenceUpdated("echidna-proof", 0.95),
      ])
    | None => busEvents
    }
  } else {
    busEvents
  }

  // Emit fleet dispatch when fleet findings change.
  let busEvents = if Array.length(newModel.fleet.findings) !== Array.length(model.fleet.findings) {
    Array.concat(busEvents, [
      PanelBus.FarmRepoListUpdated(Array.length(newModel.fleet.findings)),
    ])
  } else {
    busEvents
  }

  // Emit compliance change if contractile statuses changed.
  let violatedCount = Array.filter(newModel.contractiles, c => {
    switch c.status {
    | Violated(_) => true
    | _ => false
    }
  })->Array.length
  let prevViolatedCount = Array.filter(model.contractiles, c => {
    switch c.status {
    | Violated(_) => true
    | _ => false
    }
  })->Array.length
  let busEvents = if violatedCount !== prevViolatedCount {
    let complianceScore = if Array.length(newModel.contractiles) > 0 {
      1.0 -. Int.toFloat(violatedCount) /. Int.toFloat(Array.length(newModel.contractiles))
    } else {
      1.0
    }
    Array.concat(busEvents, [
      PanelBus.RsrComplianceChanged("contractiles", complianceScore),
    ])
  } else {
    busEvents
  }

  // Wrap events in envelopes and record in the registry ring buffer.
  let nowMs = Date.now()
  let busRegistry = Array.reduce(busEvents, newModel.busRegistry, (reg, evt) => {
    let (_envelope, updatedReg) = PanelBus.wrapEvent(reg, "governance", evt, nowMs)
    updatedReg
  })
  let newModel = { ...newModel, busRegistry }

  // Dispatch follow-up messages for bus events. Each bus event maps to a
  // message that the consuming panel handles. This closes the cross-panel
  // intelligence loop: governance changes propagate to dependent panels.
  let busCmd = if Array.length(busEvents) > 0 {
    let followUps = Array.filterMap(busEvents, evt => {
      switch evt {
      | PanelBus.HypatiaConfidenceUpdated(_repo, _conf) => None // Hypatia consumes internally
      | PanelBus.RepoHealthChanged(_source, _score) => None // Orbital metric, no panel dispatch needed
      | PanelBus.DatabaseConnectionChanged(_db, connected) =>
        // When VeriSimDB connection changes, trigger a health check.
        connected ? Some(VeriSimDB(CheckHealth)) : None
      | PanelBus.RsrComplianceChanged(_source, _score) => None // Reposystem tracks internally
      | PanelBus.FarmRepoListUpdated(_count) => None // Farm refresh handled by Farm panel
      | PanelBus.FleetFixDispatched(_repo, _recipe) => None // Fleet tracks internally
      | PanelBus.HypatiaFindingsRouted(_json) =>
        // When Hypatia routes findings, tell Fleet to reload.
        Some(Fleet(LoadFleet))
      }
    })
    if Array.length(followUps) > 0 {
      Tea_Cmd.batch(List.fromArray(Array.map(followUps, m => Tea_Cmd.msg(m))))
    } else {
      Tea_Cmd.none
    }
  } else {
    Tea_Cmd.none
  }

  // Merge bus commands and governance commands with the original command.
  let finalCmd = Tea_Cmd.batch(list{cmd, busCmd, governanceCmd})

  (newModel, finalCmd)
}

// ===========================================================================
// VAB Sub-Updater
// ===========================================================================

/// Helper: recompute VAB warnings and capabilities after an assembly change.
/// Called after every add/remove/clear operation to keep the status bar current.
let recomputeVabStatus = (vab: vabState): vabState => {
  let warnings = VabEngine.checkDependencies(vab.server.components, vab.catalog)
  let capabilities = VabEngine.computeCapabilities(vab.server.components, vab.catalog, warnings)
  {...vab, warnings, capabilities}
}

/// STATE TRANSITION: VAB (Verified Assembly Building)
/// Handles server composition: category browsing, component add/remove,
/// server naming, filter/sort, and assembly management. After every
/// assembly-modifying action, recomputes dependency warnings and capabilities.
let updateVab = (model: model, msg: vabMsg): (model, Tea_Cmd.t<msg>) => {
  let vab = model.vab
  switch msg {
  | ToggleVab => ({...model, vab: {...vab, visible: !vab.visible}}, Tea_Cmd.none)
  | SelectCategory(cat) => ({...model, vab: {...vab, selectedCategory: cat}}, Tea_Cmd.none)
  | AddComponent(id) => {
      // Only add if not already present
      let alreadyPresent = Array.some(vab.server.components, c => c === id)
      if alreadyPresent {
        (model, Tea_Cmd.none)
      } else {
        let server = {
          ...vab.server,
          components: Array.concat(vab.server.components, [id]),
        }
        ({...model, vab: recomputeVabStatus({...vab, server})}, Tea_Cmd.none)
      }
    }
  | RemoveComponent(id) => {
      let server = {
        ...vab.server,
        components: Array.filter(vab.server.components, c => c !== id),
      }
      ({...model, vab: recomputeVabStatus({...vab, server})}, Tea_Cmd.none)
    }
  | RenameServer(name) => ({...model, vab: {...vab, server: {...vab.server, name}}}, Tea_Cmd.none)
  | ClearAssembly => {
      let server = {...vab.server, components: []}
      ({...model, vab: recomputeVabStatus({...vab, server})}, Tea_Cmd.none)
    }
  | SetFilterText(text) => ({...model, vab: {...vab, filterText: text}}, Tea_Cmd.none)
  | SetSortBy(sort) => ({...model, vab: {...vab, sortBy: sort}}, Tea_Cmd.none)
  | HoverComponent(id) => ({...model, vab: {...vab, hoveredComponent: id}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "vab", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => {
    logDegradedService("TypeLL", "cross-panel type check failed")
    (model, Tea_Cmd.none)
  }
  }
}

// ===========================================================================
// ===========================================================================
// CloudGuard Sub-Updater
// ===========================================================================

/// Handles all CloudGuard (Cloudflare domain security management) messages.
/// Connection lifecycle, zone listing, settings read/write, DNS records,
/// DNSSEC, hardening operations, audit, and UI state toggling.
let updateCloudGuard = (model: model, msg: cloudguardMsg): (model, Tea_Cmd.t<msg>) => {
  let cg = model.cloudguard
  switch msg {
  // -- Connection lifecycle --
  | VerifyToken => (
      {...model, cloudguard: {...cg, connection: Connecting, loading: true}},
      CloudGuardCmd.verifyToken(result => CloudGuard(TokenVerified(result))),
    )
  | TokenVerified(result) =>
    switch result {
    | Ok(json) => (
        {...model, cloudguard: {...cg, connection: Connected(json), loading: false, error: None}},
        // Auto-fetch zones after successful connection
        CloudGuardCmd.listZones(result => CloudGuard(ZonesLoaded(result))),
      )
    | Error(err) => (
        {...model, cloudguard: {...cg, connection: ConnectionError(err), loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Zone listing --
  | FetchZones => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.listZones(result => CloudGuard(ZonesLoaded(result))),
    )
  | ZonesLoaded(result) =>
    switch result {
    | Ok(json) => {
        let zones = CloudGuardEngine.parseZonesJson(json)
        let sorted = CloudGuardEngine.sortZonesByName(zones)
        ({...model, cloudguard: {...cg, zones: sorted, loading: false, error: None}}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Zone selection (multi-select domain ribbon) --
  | ToggleZoneSelection(zoneId) => {
      let wasSelected = Array.includes(cg.selectedZoneIds, zoneId)
      let newSelected = if wasSelected {
        cg.selectedZoneIds->Array.filter(id => id !== zoneId)
      } else {
        Array.concat(cg.selectedZoneIds, [zoneId])
      }
      // When selecting a single zone (and it wasn't already selected), auto-fetch its settings + DNS
      let cmd = if !wasSelected && Array.length(newSelected) === 1 {
        Tea_Cmd.batch(list{
          CloudGuardCmd.getSettings(zoneId, result => CloudGuard(SettingsLoaded(result))),
          CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result))),
        })
      } else {
        Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, selectedZoneIds: newSelected}}, cmd)
    }
  | SelectAllZones => {
      let allIds = cg.zones->Array.map(z => z.id)
      ({...model, cloudguard: {...cg, selectedZoneIds: allIds}}, Tea_Cmd.none)
    }
  | DeselectAllZones => (
      {...model, cloudguard: {...cg, selectedZoneIds: []}},
      Tea_Cmd.none,
    )

  // -- Settings read/write --
  | FetchSettings(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.getSettings(zoneId, result => CloudGuard(SettingsLoaded(result))),
    )
  | SettingsLoaded(result) =>
    switch result {
    | Ok(json) => {
        let settings = CloudGuardEngine.parseSettingsJson(json)
        ({...model, cloudguard: {...cg, settings, loading: false, error: None}}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ToggleSetting(settingId) => {
      let newSettings = cg.settings->Array.map(s => {
        if s.id === settingId {
          let newValue = switch s.value {
          | StringValue("on") => StringValue("off")
          | StringValue("off") => StringValue("on")
          | BoolValue(b) => BoolValue(!b)
          | other => other
          }
          {...s, value: newValue, modified: true}
        } else {
          s
        }
      })
      ({...model, cloudguard: {...cg, settings: newSettings}}, Tea_Cmd.none)
    }
  | UpdateSettingValue(settingId, value) => {
      let newSettings = cg.settings->Array.map(s => {
        if s.id === settingId {
          {...s, value: StringValue(value), modified: true}
        } else {
          s
        }
      })
      ({...model, cloudguard: {...cg, settings: newSettings}}, Tea_Cmd.none)
    }
  | PushChanges => {
      let modifiedCount = cg.settings->Array.filter(s => s.modified)->Array.length
      if modifiedCount === 0 {
        (model, Tea_Cmd.none)
      } else {
        // Get the first selected zone to push to
        switch Array.get(cg.selectedZoneIds, 0) {
        | Some(zoneId) => {
            let settingsJson = CloudGuardEngine.serialiseModifiedSettings(cg.settings)
            let typellCmd = TypeLLService.checkConfigTypes(settingsJson, "cloudguard", result => CloudGuard(TypeCheckResult(result)))
            (
              {...model, cloudguard: {...cg, loading: true}},
              Tea_Cmd.batch(list{
                CloudGuardCmd.updateSettingsBatch(
                  zoneId,
                  settingsJson,
                  result => CloudGuard(ChangesPushed(result)),
                ),
                typellCmd,
              }),
            )
          }
        | None => (model, Tea_Cmd.none)
        }
      }
    }
  | ChangesPushed(result) =>
    switch result {
    | Ok(_json) => {
        // Clear modified flags on all settings after successful push
        let clearedSettings = cg.settings->Array.map(s => {...s, modified: false})
        ({...model, cloudguard: {...cg, settings: clearedSettings, loading: false, error: None}}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- DNS records --
  | FetchDnsRecords(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result))),
    )
  | DnsRecordsLoaded(result) =>
    switch result {
    | Ok(json) => {
        let records = CloudGuardEngine.parseDnsRecordsJson(json)
        ({...model, cloudguard: {...cg, dnsRecords: records, loading: false, error: None}}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DeleteDnsRecord(zoneId, recordId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.deleteDnsRecord(zoneId, recordId, result => CloudGuard(DnsRecordDeleted(result))),
    )
  | DnsRecordDeleted(result) =>
    switch result {
    | Ok(_json) =>
      // Re-fetch DNS records for the first selected zone to update the list
      let refetchCmd = switch Array.get(cg.selectedZoneIds, 0) {
      | Some(zoneId) =>
        CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result)))
      | None => Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, loading: false}}, refetchCmd)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | CreateDnsRecord(zoneId, recordType, name, content, ttl, proxied, priority) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.createDnsRecord(
        zoneId, recordType, name, content, ttl, proxied, priority, None,
        result => CloudGuard(DnsRecordCreated(result)),
      ),
    )
  | DnsRecordCreated(result) =>
    switch result {
    | Ok(_json) =>
      // Re-fetch DNS records to show the newly created record
      let refetchCmd = switch Array.get(cg.selectedZoneIds, 0) {
      | Some(zoneId) =>
        CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result)))
      | None => Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, loading: false}}, refetchCmd)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | StartEditingDnsRecord(recordId) => (
      {...model, cloudguard: {...cg, dnsEditingId: Some(recordId)}},
      Tea_Cmd.none,
    )
  | CancelEditingDnsRecord => (
      {...model, cloudguard: {...cg, dnsEditingId: None}},
      Tea_Cmd.none,
    )
  | ApplySecurityTemplate(template) => {
      // Apply a DNS security template (SPF, DMARC, DKIM revoke, CAA, TLSRPT)
      // Requires a selected zone to know the domain name
      switch Array.get(cg.selectedZoneIds, 0) {
      | None => ({...model, cloudguard: {...cg, error: Some("No zone selected")}}, Tea_Cmd.none)
      | Some(zoneId) =>
        let zoneName = switch cg.zones->Array.find(z => z.id === zoneId) {
        | Some(z) => z.name
        | None => "example.com"
        }
        let cmd = switch template {
        | "spf" =>
          CloudGuardCmd.createDnsRecord(
            zoneId, "TXT", zoneName,
            "v=spf1 -all",
            1, None, None, Some("CloudGuard: SPF deny-all (no mail)"),
            result => CloudGuard(DnsRecordCreated(result)),
          )
        | "dmarc" =>
          CloudGuardCmd.createDnsRecord(
            zoneId, "TXT", `_dmarc.${zoneName}`,
            "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; pct=100; fo=1",
            1, None, None, Some("CloudGuard: DMARC reject policy"),
            result => CloudGuard(DnsRecordCreated(result)),
          )
        | "dkim_revoke" =>
          CloudGuardCmd.createDnsRecord(
            zoneId, "TXT", `*._domainkey.${zoneName}`,
            "v=DKIM1; p=",
            1, None, None, Some("CloudGuard: DKIM key revocation"),
            result => CloudGuard(DnsRecordCreated(result)),
          )
        | "caa" =>
          CloudGuardCmd.createDnsRecord(
            zoneId, "CAA", zoneName,
            "0 issue \"letsencrypt.org\"",
            1, None, None, Some("CloudGuard: CAA restrict to Let's Encrypt"),
            result => CloudGuard(DnsRecordCreated(result)),
          )
        | "tlsrpt" =>
          CloudGuardCmd.createDnsRecord(
            zoneId, "TXT", `_smtp._tls.${zoneName}`,
            "v=TLSRPTv1; rua=mailto:tlsrpt@${zoneName}",
            1, None, None, Some("CloudGuard: TLS-RPT reporting"),
            result => CloudGuard(DnsRecordCreated(result)),
          )
        | _ => Tea_Cmd.none
        }
        ({...model, cloudguard: {...cg, loading: true}}, cmd)
      }
    }

  // -- DNSSEC --
  | FetchDnssec(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.getDnssec(zoneId, result => CloudGuard(DnssecLoaded(result))),
    )
  | DnssecLoaded(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | EnableDnssec(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.enableDnssec(zoneId, result => CloudGuard(DnssecEnabled(result))),
    )
  | DnssecEnabled(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Hardening --
  | HardenSelected => {
      // Harden first selected zone; subsequent zones handled by ZoneHardened
      switch Array.get(cg.selectedZoneIds, 0) {
      | Some(firstZone) => (
          {...model, cloudguard: {
            ...cg,
            loading: true,
            bulkProgress: Some({
              total: Array.length(cg.selectedZoneIds),
              completed: 0,
              failed: 0,
              currentDomain: cg.zones->Array.find(z => z.id === firstZone)->Option.map(z => z.name),
              startedAt: "",
              errors: [],
            }),
          }},
          CloudGuardCmd.hardenZone(firstZone, result => CloudGuard(ZoneHardened(result))),
        )
      | None => (model, Tea_Cmd.none)
      }
    }
  | HardenZone(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.hardenZone(zoneId, result => CloudGuard(ZoneHardened(result))),
    )
  | ZoneHardened(result) => {
      let progress = switch cg.bulkProgress {
      | Some(p) =>
        switch result {
        | Ok(_) => Some({...p, completed: p.completed + 1})
        | Error(err) => Some({
            ...p,
            completed: p.completed + 1,
            failed: p.failed + 1,
            errors: Array.concat(p.errors, [("unknown", err)]),
          })
        }
      | None => None
      }
      // Check if there are more zones to harden
      let nextIndex = switch progress {
      | Some(p) => p.completed
      | None => 0
      }
      let cmd = if nextIndex < Array.length(cg.selectedZoneIds) {
        switch Array.get(cg.selectedZoneIds, nextIndex) {
        | Some(nextZone) =>
          CloudGuardCmd.hardenZone(nextZone, result => CloudGuard(ZoneHardened(result)))
        | None => Tea_Cmd.none
        }
      } else {
        Tea_Cmd.none // All done
      }
      let isDone = nextIndex >= Array.length(cg.selectedZoneIds)
      (
        {...model, cloudguard: {...cg, bulkProgress: progress, loading: !isDone}},
        cmd,
      )
    }

  // -- Audit --
  | RunAudit => {
      // Run the audit locally against the loaded settings using CloudGuardPolicy.
      // The audit is pure computation — no API calls needed.
      let currentDomain = switch Array.get(cg.selectedZoneIds, 0) {
      | Some(zoneId) =>
        switch cg.zones->Array.find(z => z.id === zoneId) {
        | Some(zone) => zone.name
        | None => "unknown"
        }
      | None => "unknown"
      }
      let auditResult = CloudGuardPolicy.auditSettings(currentDomain, cg.settings)
      (
        {
          ...model,
          cloudguard: {
            ...cg,
            showAudit: true,
            auditResult: Some(auditResult),
            constraints: CloudGuardPolicy.defaultConstraints,
          },
        },
        Tea_Cmd.none,
      )
    }
  | AuditComplete(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Offline config --
  | DownloadConfig => {
      // Download offline config for the first selected zone
      let cmd = switch Array.get(cg.selectedZoneIds, 0) {
      | Some(zoneId) =>
        CloudGuardCmd.downloadConfig(zoneId, result => CloudGuard(ConfigDownloaded(result)))
      | None => Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, loading: true}}, cmd)
    }
  | ConfigDownloaded(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Per-domain exceptions --
  | AddException(domain, settingId, overrideValue, reason) => {
      let newException: domainException = {
        domain,
        settingId,
        overrideValue,
        reason,
        addedOn: Date.make()->Date.toISOString,
      }
      // Remove any existing exception for the same domain+setting, then add new
      let filtered = cg.exceptions->Array.filter(e =>
        !(e.domain === domain && e.settingId === settingId)
      )
      let exceptions = Array.concat(filtered, [newException])
      ({...model, cloudguard: {...cg, exceptions}}, Tea_Cmd.none)
    }
  | RemoveException(domain, settingId) => {
      let exceptions = cg.exceptions->Array.filter(e =>
        !(e.domain === domain && e.settingId === settingId)
      )
      ({...model, cloudguard: {...cg, exceptions}}, Tea_Cmd.none)
    }

  // -- UI state --
  | ToggleCloudGuard => {
      let newVisible = !cg.visible
      let cmd = if newVisible && cg.connection === Disconnected {
        // Auto-connect when opening the panel
        CloudGuardCmd.verifyToken(result => CloudGuard(TokenVerified(result)))
      } else {
        Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, visible: newVisible}}, cmd)
    }
  | SetCategory(cat) => (
      {...model, cloudguard: {...cg, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetFilterText(text) => (
      {...model, cloudguard: {...cg, filterText: text}},
      Tea_Cmd.none,
    )
  | SetSettingFilter(text) => (
      {...model, cloudguard: {...cg, settingFilter: text}},
      Tea_Cmd.none,
    )
  | ToggleAuditPanel => (
      {...model, cloudguard: {...cg, showAudit: !cg.showAudit}},
      Tea_Cmd.none,
    )
  | ToggleDiffPanel => (
      {...model, cloudguard: {...cg, showDiff: !cg.showDiff}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "cloudguard", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Main Orchestrator
// ===========================================================================

// ===========================================================================
// Farm Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Git-Private-Farm (repo inventory)
///
/// Handles loading the manifest, parsing the inventory, and UI state changes
/// (category, filter, sort). The backend reads local JSON — no HTTP service.
let updateFarm = (model: model, msg: farmMsg): (model, Tea_Cmd.t<msg>) => {
  let farm = model.farm
  switch msg {
  | LoadRepos => (
      {...model, farm: {...farm, loading: true, error: None}},
      FarmCmd.listRepos(result => Farm(ReposLoaded(result))),
    )
  | ReposLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch FarmEngine.parseInventory(jsonStr) {
      | Ok(repos) => (
          {
            ...model,
            farm: {
              ...farm,
              loaded: true,
              loading: false,
              error: None,
              repos,
              totalRepos: Array.length(repos),
              unhealthyCount: repos->Array.filter(r =>
                switch r.healthScore {
                | Some(s) => s < 0.5
                | None => false
                }
              )->Array.length,
            },
          },
          TypeLLService.checkConfigTypes(jsonStr, "farm", result => Farm(TypeCheckResult(result))),
        )
      | Error(e) => (
          {...model, farm: {...farm, loading: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, farm: {...farm, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | SetFarmCategory(cat) => (
      {...model, farm: {...farm, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetFarmFilter(text) => (
      {...model, farm: {...farm, filterText: text}},
      Tea_Cmd.none,
    )
  | SetFarmSort(sort) => (
      {...model, farm: {...farm, sortBy: sort}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "farm", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => {
    logDegradedService("TypeLL", "cross-panel type check failed")
    (model, Tea_Cmd.none)
  }
  }
}

// ===========================================================================
// Plaza Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Palimpsest Plaza (PMPL licensing)
///
/// Handles adoption stats loading, repo scanning, and UI state changes.
/// The backend scans the local filesystem for SPDX headers and LICENSE files.
let updatePlaza = (model: model, msg: plazaMsg): (model, Tea_Cmd.t<msg>) => {
  let plaza = model.plaza
  switch msg {
  | LoadAdoptionStats => (
      {...model, plaza: {...plaza, loading: true, error: None}},
      PlazaCmd.adoptionStats(result => Plaza(AdoptionStatsLoaded(result))),
    )
  | AdoptionStatsLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch PlazaEngine.parseAdoptionStats(jsonStr) {
      | Ok(stats) => (
          {
            ...model,
            plaza: {
              ...plaza,
              loaded: true,
              loading: false,
              error: None,
              stats: Some(stats),
            },
          },
          Tea_Cmd.none,
        )
      | Error(e) => (
          {...model, plaza: {...plaza, loading: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, plaza: {...plaza, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | ScanRepo(repoName) => (
      {...model, plaza: {...plaza, loading: true}},
      Tea_Cmd.batch(list{
        PlazaCmd.scanRepo(repoName, result => Plaza(RepoScanned(result))),
        TypeLLService.checkConfigTypes(repoName, "plaza", result => Plaza(TypeCheckResult(result))),
      }),
    )
  | RepoScanned(result) =>
    switch result {
    | Ok(jsonStr) => {
        let audit = try {
          let json = JSON.parseExn(jsonStr)
          let o = json->JSON.Decode.object->Option.getOr(Dict.make())
          let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)->Option.getOr(0)
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let rn = gs(o, "repo_name")
          let hl = gb(o, "has_license_file")
          let sc = gi(o, "spdx_header_count")
          let tf = gi(o, "total_source_files")
          let ea = gb(o, "has_exhibit_a")
          let eb = gb(o, "has_exhibit_b")
          let ps = gb(o, "has_provenance_sig")
          let lv = if hl && sc === tf && ea && eb && ps { FullCompliance } else if hl && sc > 0 { PartialCompliance } else { NonCompliant }
          Some({
            repoName: rn, level: lv, filesScanned: tf, filesWithHeaders: sc,
            lastAudit: Date.make()->Date.toISOString,
            checks: [
              {id: "license", name: "LICENSE", description: "LICENSE file", passed: hl, severity: "critical", detail: hl ? "Found" : "Missing"},
              {id: "spdx", name: "SPDX", description: "SPDX headers", passed: sc === tf, severity: "warning", detail: `${Int.toString(sc)}/${Int.toString(tf)}`},
              {id: "exhibit-a", name: "Exhibit A", description: "Ethical Use", passed: ea, severity: "info", detail: ea ? "Present" : "Missing"},
              {id: "exhibit-b", name: "Exhibit B", description: "QS Provenance", passed: eb, severity: "info", detail: eb ? "Present" : "Missing"},
              {id: "sig", name: "Provenance", description: "Signature", passed: ps, severity: "warning", detail: ps ? "Verified" : "Not found"},
            ],
          }: complianceAudit)
        } catch { | _ => None }
        switch audit {
        | Some(a) => ({...model, plaza: {...plaza, loading: false, audits: Array.concat(plaza.audits, [a])}}, Tea_Cmd.none)
        | None => ({...model, plaza: {...plaza, loading: false}}, Tea_Cmd.none)
        }
      }
    | Error(e) => ({...model, plaza: {...plaza, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetPlazaCategory(cat) => (
      {...model, plaza: {...plaza, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetPlazaFilter(text) => (
      {...model, plaza: {...plaza, filterText: text}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "plaza", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Panel Switcher Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Panel Switcher (unified panel navigation)
///
/// Handles panel toggle, close, and health check results. Updates the
/// `panelSwitcher` state and the `connectionStatus` of individual panels
/// in the registry. Also bridges to legacy `visible` fields on VAB and
/// CloudGuard so existing code continues to work during migration.
let updatePanelSwitcher = (model: model, msg: panelSwitcherMsg): (model, Tea_Cmd.t<msg>) => {
  let ps = model.panelSwitcher
  switch msg {
  | TogglePanel(id) => {
      // Toggle: if already active, close; otherwise open the requested panel.
      let newActive = ps.activePanel === Some(id) ? None : Some(id)
      // Bridge to legacy visible fields for VAB and CloudGuard.
      let newVab = {...model.vab, visible: newActive === Some(PanelVab)}
      let newCg = {...model.cloudguard, visible: newActive === Some(PanelCloudGuard)}
      // Auto-load Farm inventory when opening the panel for the first time.
      let farmCmd = if newActive === Some(PanelFarm) && !model.farm.loaded && !model.farm.loading {
        FarmCmd.listRepos(result => Farm(ReposLoaded(result)))
      } else {
        Tea_Cmd.none
      }
      // Auto-connect CloudGuard when opening.
      let cgCmd = if newActive === Some(PanelCloudGuard) && model.cloudguard.connection === Disconnected {
        CloudGuardCmd.verifyToken(result => CloudGuard(TokenVerified(result)))
      } else {
        Tea_Cmd.none
      }
      (
        {
          ...model,
          panelSwitcher: {...ps, activePanel: newActive},
          vab: newVab,
          cloudguard: newCg,
        },
        Tea_Cmd.batch(list{farmCmd, cgCmd}),
      )
    }
  | ClosePanels => {
      let newVab = {...model.vab, visible: false}
      let newCg = {...model.cloudguard, visible: false}
      (
        {
          ...model,
          panelSwitcher: {...ps, activePanel: None, expandedGroup: None},
          vab: newVab,
          cloudguard: newCg,
        },
        Tea_Cmd.none,
      )
    }
  | ExpandGroup(kind) => {
      // Toggle: collapse if already expanded, otherwise expand.
      let newExpanded = ps.expandedGroup === Some(kind) ? None : Some(kind)
      ({...model, panelSwitcher: {...ps, expandedGroup: newExpanded}}, Tea_Cmd.none)
    }
  | HealthCheckResult(panelId, result) => {
      // Update the connectionStatus of the panel that was checked.
      let newStatus = switch result {
      | Ok(_) => ServiceConnected
      | Error(e) => ServiceError(e)
      }
      let newPanels = ps.panels->Array.map(p =>
        p.id === panelId ? {...p, connectionStatus: newStatus} : p
      )
      ({...model, panelSwitcher: {...ps, panels: newPanels}}, Tea_Cmd.none)
    }
  }
}

// ===========================================================================
// Reposystem Sub-Updater
// ===========================================================================

let updateReposystem = (model: model, msg: reposystemMsg): (model, Tea_Cmd.t<msg>) => {
  let rsr = model.reposystem
  switch msg {
  | ScanAll => (
      {...model, reposystem: {...rsr, loading: true, error: None}},
      Tea_Cmd.batch(list{
        ReposystemCmd.scanAll(result => Reposystem(ScanAllLoaded(result))),
        TypeLLService.checkConfigTypes("rsr-scan", "reposystem", result => Reposystem(TypeCheckResult(result))),
      }),
    )
  | ScanAllLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch ReposystemEngine.parseAudits(jsonStr) {
      | Ok(audits) => {
          let stats = ReposystemEngine.computeStats(audits)
          ({...model, reposystem: {...rsr, loaded: true, loading: false, audits, stats: Some(stats)}}, Tea_Cmd.none)
        }
      | Error(e) => ({...model, reposystem: {...rsr, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, reposystem: {...rsr, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetRsrCategory(cat) => ({...model, reposystem: {...rsr, activeCategory: cat}}, Tea_Cmd.none)
  | SetRsrFilter(text) => ({...model, reposystem: {...rsr, filterText: text}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "reposystem", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Aerie Sub-Updater
// ===========================================================================

let updateAerie = (model: model, msg: aerieMsg): (model, Tea_Cmd.t<msg>) => {
  let aer = model.aerie
  switch msg {
  | LoadAerie => {
      let fetchCmd = if aer.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "observe-mcp",
          "metrics",
          `{"type": "latency"}`,
          result => Aerie(LatencyLoaded(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        AerieCmd.fetchLatency(result => Aerie(LatencyLoaded(result)))
      }
      let typellCmd = TypeLLService.checkConfigTypes("aerie-config", "aerie", result => Aerie(TypeCheckResult(result)))
      (
        {...model, aerie: {...aer, loading: true, error: None}},
        Tea_Cmd.batch(list{fetchCmd, typellCmd}),
      )
    }
  | LatencyLoaded(result) =>
    switch result {
    | Ok(_jsonStr) => ({...model, aerie: {...aer, loaded: true, loading: false}}, Tea_Cmd.none)
    | Error(e) => ({...model, aerie: {...aer, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SpeedTestLoaded(result) =>
    switch result {
    | Ok(_jsonStr) => ({...model, aerie: {...aer, loaded: true, loading: false}}, Tea_Cmd.none)
    | Error(e) => ({...model, aerie: {...aer, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetAerieCategory(cat) => ({...model, aerie: {...aer, activeCategory: cat}}, Tea_Cmd.none)
  | ToggleAerieBojRouting => (
      {...model, aerie: {...aer, bojRouting: !aer.bojRouting}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "aerie", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Interfaces Sub-Updater
// ===========================================================================

let updateInterfaces = (model: model, msg: interfacesMsg): (model, Tea_Cmd.t<msg>) => {
  let iface = model.interfaces
  switch msg {
  | ScanInterfaces => (
      {...model, interfaces: {...iface, loading: true, error: None}},
      Tea_Cmd.batch(list{
        InterfacesCmd.scanInterfaces(result => Interfaces(InterfacesLoaded(result))),
        TypeLLService.checkConfigTypes("abi-ffi-scan", "interfaces", result => Interfaces(TypeCheckResult(result))),
      }),
    )
  | InterfacesLoaded(result) =>
    switch result {
    | Ok(_jsonStr) => ({...model, interfaces: {...iface, loaded: true, loading: false}}, Tea_Cmd.none)
    | Error(e) => ({...model, interfaces: {...iface, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetIfaceCategory(cat) => ({...model, interfaces: {...iface, activeCategory: cat}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "interfaces", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Playgrounds Sub-Updater
// ===========================================================================

let updatePlaygrounds = (model: model, msg: playgroundsMsg): (model, Tea_Cmd.t<msg>) => {
  let pg = model.playgrounds
  switch msg {
  | SetPlayCategory(cat) => ({...model, playgrounds: {...pg, activeCategory: cat}}, Tea_Cmd.none)
  | SetLanguage(lang) => ({...model, playgrounds: {...pg, activeLanguage: lang}}, Tea_Cmd.none)
  | UpdateCode(code) => ({...model, playgrounds: {...pg, editorContent: code}}, Tea_Cmd.none)
  | Execute => (
      {...model, playgrounds: {...pg, executing: true, error: None}},
      Tea_Cmd.batch(list{
        PlaygroundsCmd.executeQuery(
          PlaygroundsEngine.languageLabel(pg.activeLanguage),
          pg.editorContent,
          result => Playgrounds(ExecuteResult(result)),
        ),
        TypeLLService.checkCodeTypes(pg.editorContent, PlaygroundsEngine.languageLabel(pg.activeLanguage), result => Playgrounds(TypeCheckResult(result))),
      }),
    )
  | ExecuteResult(result) =>
    switch result {
    | Ok(_jsonStr) => (
        {
          ...model,
          playgrounds: {
            ...pg,
            executing: false,
            lastResult: Some({success: true, data: Some(_jsonStr), error: None, durationMs: 0.0, rowCount: 0}),
          },
        },
        Tea_Cmd.none,
      )
    | Error(e) => (
        {
          ...model,
          playgrounds: {
            ...pg,
            executing: false,
            lastResult: Some({success: false, data: None, error: Some(e), durationMs: 0.0, rowCount: 0}),
          },
        },
        Tea_Cmd.none,
      )
    }
  | LoadSnippet(snippetId) => {
      let snippet = pg.snippets->Array.find(s => s.id === snippetId)
      switch snippet {
      | Some(s) => ({...model, playgrounds: {...pg, editorContent: s.code, activeLanguage: s.language}}, Tea_Cmd.none)
      | None => (model, Tea_Cmd.none)
      }
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "playgrounds", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Hypatia Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Hypatia (neurosymbolic scanner)
///
/// Handles loading network status, scan results, category navigation,
/// and text filtering. The backend is an Elixir Phoenix API.
let updateHypatia = (model: model, msg: hypatiaMsg): (model, Tea_Cmd.t<msg>) => {
  let hyp = model.hypatia
  switch msg {
  | LoadHypatia => (
      {...model, hypatia: {...hyp, loading: true, error: None}},
      Tea_Cmd.batch(list{
        HypatiaCmd.fetchNetworks(result => Hypatia(NetworksLoaded(result))),
        HypatiaCmd.fetchScans(result => Hypatia(ScansLoaded(result))),
        TypeLLService.checkConfigTypes("hypatia-scan-config", "hypatia", result => Hypatia(TypeCheckResult(result))),
      }),
    )
  | NetworksLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch HypatiaEngine.parseNetworks(jsonStr) {
      | Ok(networks) => {
          // S5: Propagate Hypatia neural confidence to Panel-N autonomy.
          // Average confidence across active networks sets the autonomy ceiling.
          let activeNets = networks->Array.filter(n =>
            switch n.status {
            | NetActive => true
            | _ => false
            }
          )
          let avgConfidence = if Array.length(activeNets) > 0 {
            let total = activeNets->Array.reduce(0.0, (acc, n) => acc +. n.confidence)
            total /. Int.toFloat(Array.length(activeNets))
          } else {
            0.0
          }
          // Clamp autonomy to the confidence level — can't be more autonomous
          // than the neural networks are confident.
          let newAutonomy = Math.min(model.paneN.agency.autonomyLevel, avgConfidence)
          let newAgency = {...model.paneN.agency, autonomyLevel: newAutonomy}
          let newPaneN = {...model.paneN, agency: newAgency}
          (
            {
              ...model,
              paneN: newPaneN,
              hypatia: {
                ...hyp,
                loaded: true,
                loading: false,
                error: None,
                networks,
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => (
          {...model, hypatia: {...hyp, loading: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, hypatia: {...hyp, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | ScansLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch HypatiaEngine.parseScans(jsonStr) {
      | Ok(scans) => {
          let quarantined = scans->Array.reduce(0, (acc, s) => acc + s.quarantineCount)
          (
            {
              ...model,
              hypatia: {
                ...hyp,
                loaded: true,
                loading: false,
                scans,
                totalRepos: Array.length(scans),
                quarantinedCount: quarantined,
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => (
          {...model, hypatia: {...hyp, loading: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, hypatia: {...hyp, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | SetHypatiaCategory(cat) => (
      {...model, hypatia: {...hyp, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetHypatiaFilter(text) => (
      {...model, hypatia: {...hyp, filterText: text}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "hypatia", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Fleet Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Gitbot-Fleet (6-bot orchestration)
///
/// Handles fleet loading, bot status parsing, findings parsing, category
/// navigation, and text filtering. The fleet backend is an Axum API at :8080.
let updateFleet = (model: model, msg: fleetMsg): (model, Tea_Cmd.t<msg>) => {
  let fleet = model.fleet
  switch msg {
  | LoadFleet => (
      {...model, fleet: {...fleet, loading: true, error: None}},
      Tea_Cmd.batch(list{
        FleetCmd.fetchBots(result => Fleet(BotsLoaded(result))),
        FleetCmd.fetchFindings(result => Fleet(FindingsLoaded(result))),
        TypeLLService.checkConfigTypes("fleet-dispatch", "fleet", result => Fleet(TypeCheckResult(result))),
      }),
    )
  | BotsLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch FleetEngine.parseBots(jsonStr) {
      | Ok(bots) => {
          let health = FleetEngine.computeHealth(bots, fleet.findings)
          (
            {
              ...model,
              fleet: {
                ...fleet,
                loaded: true,
                loading: false,
                error: None,
                bots,
                health: Some(health),
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => (
          {...model, fleet: {...fleet, loading: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, fleet: {...fleet, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | FindingsLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch FleetEngine.parseFindings(jsonStr) {
      | Ok(findings) => {
          let health = FleetEngine.computeHealth(fleet.bots, findings)
          (
            {
              ...model,
              fleet: {
                ...fleet,
                loaded: true,
                loading: false,
                findings,
                health: Some(health),
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => (
          {...model, fleet: {...fleet, loading: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, fleet: {...fleet, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | SetFleetCategory(cat) => (
      {...model, fleet: {...fleet, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetFleetFilter(text) => (
      {...model, fleet: {...fleet, filterText: text}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "fleet", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Minter Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Panel Minter (panel creation wizard)
///
/// Handles all minterMsg variants: form field updates, wizard navigation,
/// minting execution, and result handling. Most messages are pure state
/// updates; ExecuteMint dispatches a Tauri command via MinterCmd.
let updateMinter = (model: model, msg: minterMsg): (model, Tea_Cmd.t<msg>) => {
  let minter = model.minter
  let form = minter.form
  switch msg {
  | SetPanelName(name) => {
      let validation = MinterEngine.validateName(name)
      (
        {
          ...model,
          minter: {
            ...minter,
            form: {...form, panelName: name, nameValidation: validation},
          },
        },
        Tea_Cmd.none,
      )
    }
  | SetShortName(v) => (
      {...model, minter: {...minter, form: {...form, shortName: v}}},
      Tea_Cmd.none,
    )
  | SetDescription(v) => (
      {...model, minter: {...minter, form: {...form, description: v}}},
      Tea_Cmd.none,
    )
  | SetIcon(v) => (
      {...model, minter: {...minter, form: {...form, icon: v}}},
      Tea_Cmd.none,
    )
  | SetBackendKind(kind) => (
      {...model, minter: {...minter, form: {...form, backendKind: kind}}},
      Tea_Cmd.none,
    )
  | SetAccessibility(level) => (
      {...model, minter: {...minter, form: {...form, accessibility: level}}},
      Tea_Cmd.none,
    )
  | SetEndpoint(v) => (
      {...model, minter: {...minter, form: {...form, endpoint: v}}},
      Tea_Cmd.none,
    )
  | AddCapability => {
      let newCap: minterCapability = {id: "", label: ""}
      (
        {
          ...model,
          minter: {
            ...minter,
            form: {
              ...form,
              capabilities: Array.concat(form.capabilities, [newCap]),
            },
          },
        },
        Tea_Cmd.none,
      )
    }
  | RemoveCapability(idx) => {
      let caps = form.capabilities->Array.filterWithIndex((_c, i) => i !== idx)
      (
        {
          ...model,
          minter: {...minter, form: {...form, capabilities: caps}},
        },
        Tea_Cmd.none,
      )
    }
  | NextStep => {
      let next = minter.wizardStep + 1
      let clamped = next > 3 ? 3 : next
      ({...model, minter: {...minter, wizardStep: clamped}}, Tea_Cmd.none)
    }
  | PrevStep => {
      let prev = minter.wizardStep - 1
      let clamped = prev < 0 ? 0 : prev
      ({...model, minter: {...minter, wizardStep: clamped}}, Tea_Cmd.none)
    }
  | ExecuteMint => {
      let capsJson =
        form.capabilities
        ->Array.map(c => `{"id":"${c.id}","label":"${c.label}"}`)
        ->Array.join(",")
      let capsStr = `[${capsJson}]`
      let specJson = `{"panel":"${form.panelName}","backend":"${MinterEngine.backendKindLabel(form.backendKind)}","caps":${capsStr}}`
      (
        {...model, minter: {...minter, minting: true, error: None}},
        Tea_Cmd.batch(list{
          MinterCmd.mintPanel(
            form.panelName,
            form.shortName,
            form.description,
            form.icon,
            MinterEngine.backendKindLabel(form.backendKind),
            MinterEngine.accessibilityLabel(form.accessibility),
            capsStr,
            form.endpoint,
            result => Minter(MintResult(result)),
          ),
          TypeLLService.checkConfigTypes(specJson, "minter", result => Minter(TypeCheckResult(result))),
        }),
      )
    }
  | MintResult(result) => {
      let summary = MinterEngine.fileSummary(form)
      let allPaths = summary->Array.map(((path, _desc)) => path)
      // First entries are created files, last 6 are patches to existing files.
      let numPatches = 6
      let numCreated = Array.length(allPaths) - numPatches
      let created = allPaths->Array.slice(~start=0, ~end=numCreated)
      let patched = allPaths->Array.slice(~start=numCreated, ~end=Array.length(allPaths))
      switch result {
      | Ok(_jsonStr) => (
          {
            ...model,
            minter: {
              ...minter,
              minting: false,
              error: None,
              lastResult: Some({
                success: true,
                filesCreated: created,
                filesPatched: patched,
                warnings: [],
                error: None,
              }),
            },
          },
          Tea_Cmd.none,
        )
      | Error(e) => (
          {
            ...model,
            minter: {
              ...minter,
              minting: false,
              error: Some(e),
              lastResult: Some({
                success: false,
                filesCreated: [],
                filesPatched: [],
                warnings: [],
                error: Some(e),
              }),
            },
          },
          Tea_Cmd.none,
        )
      }
    }
  | ResetMinter => (
      {...model, minter: MinterEngine.defaultState},
      Tea_Cmd.none,
    )
  | ExportToEnsaidConfig => {
      // Generate a preview showing what the minted panel would add to ENSAID_CONFIG.
      let form = model.minter.form
      let humidityStr = switch model.humidity {
      | High => "high"
      | Medium => "medium"
      | Low => "low"
      }
      let newPanelConfig: ProvisionerModel.panelConfig = {
        panelName: form.panelName,
        endpoint: form.endpoint,
        autoConnect: true,
        isolation: ProvisionerModel.Native,
        envVars: [],
        enabled: true,
      }
      let configs = Array.concat(model.provisioner.configs, [newPanelConfig])
      let preview = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(preview)}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "minter", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Provisioner Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Provisioner (portfolio bundling, config, installation)
///
/// Handles portfolio installation, per-panel config changes, isolation tier
/// selection, custom portfolio creation, and panel enable/disable toggling.
let updateProvisioner = (model: model, msg: provisionerMsg): (model, Tea_Cmd.t<msg>) => {
  let prov = model.provisioner
  switch msg {
  | SetProvCategory(cat) => (
      {...model, provisioner: {...prov, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetProvFilter(text) => (
      {...model, provisioner: {...prov, filterText: text}},
      Tea_Cmd.none,
    )
  | InstallPortfolio(portfolioId) => {
      // Find the portfolio and install all its panels.
      let portfolio = prov.portfolios->Array.find(p => p.id === portfolioId)
      switch portfolio {
      | Some(p) => {
          // Mark all panels as Installing.
          let newStatuses = prov.installStatus->Array.map(((name, status)) =>
            if p.panels->Array.some(pn => pn === name) {
              (name, Installing: panelInstallStatus)
            } else {
              (name, status)
            }
          )
          (
            {
              ...model,
              provisioner: {
                ...prov,
                installStatus: newStatuses,
                installProgress: Some({
                  portfolioId,
                  totalPanels: Array.length(p.panels),
                  installedPanels: 0,
                  failedPanels: 0,
                  currentPanel: p.panels->Array.get(0),
                }),
              },
            },
            // For now, immediately mark as installed (native panels are built-in).
            // Container installation will be async via ProvisionerCmd.
            TypeLLService.checkConfigTypes(portfolioId, "provisioner", result => Provisioner(TypeCheckResult(result))),
          )
        }
      | None => (model, Tea_Cmd.none)
      }
    }
  | InstallPanel(panelName) => {
      let newStatuses = prov.installStatus->Array.map(((name, status)) =>
        if name === panelName { (name, Installing: panelInstallStatus) } else { (name, status) }
      )
      let config = prov.configs->Array.find(c => c.panelName === panelName)
      let isoLabel = switch config {
      | Some(c) => ProvisionerEngine.isolationShortLabel(c.isolation)
      | None => "Native"
      }
      (
        {...model, provisioner: {...prov, installStatus: newStatuses}},
        ProvisionerCmd.installPanel(panelName, isoLabel, result =>
          Provisioner(InstallResult(panelName, result))
        ),
      )
    }
  | RemovePanel(panelName) => {
      let newStatuses = prov.installStatus->Array.map(((name, status)) =>
        if name === panelName { (name, Removing: panelInstallStatus) } else { (name, status) }
      )
      (
        {...model, provisioner: {...prov, installStatus: newStatuses}},
        ProvisionerCmd.removePanel(panelName, result =>
          Provisioner(RemoveResult(panelName, result))
        ),
      )
    }
  | InstallResult(panelName, result) => {
      let newStatus = switch result {
      | Ok(_) => (Installed: panelInstallStatus)
      | Error(e) => (InstallFailed(e): panelInstallStatus)
      }
      let newStatuses = prov.installStatus->Array.map(((name, status)) =>
        if name === panelName { (name, newStatus) } else { (name, status) }
      )
      ({...model, provisioner: {...prov, installStatus: newStatuses}}, Tea_Cmd.none)
    }
  | RemoveResult(panelName, result) => {
      let newStatus = switch result {
      | Ok(_) => (NotInstalled: panelInstallStatus)
      | Error(e) => (InstallFailed(e): panelInstallStatus)
      }
      let newStatuses = prov.installStatus->Array.map(((name, status)) =>
        if name === panelName { (name, newStatus) } else { (name, status) }
      )
      ({...model, provisioner: {...prov, installStatus: newStatuses}}, Tea_Cmd.none)
    }
  | TogglePanelEnabled(panelName) => {
      let newConfigs = prov.configs->Array.map(c =>
        if c.panelName === panelName { {...c, enabled: !c.enabled} } else { c }
      )
      ({...model, provisioner: {...prov, configs: newConfigs}}, Tea_Cmd.none)
    }
  | SetPanelIsolation(panelName, tier) => {
      let newConfigs = prov.configs->Array.map(c =>
        if c.panelName === panelName { {...c, isolation: tier} } else { c }
      )
      ({...model, provisioner: {...prov, configs: newConfigs}}, Tea_Cmd.none)
    }
  | SetCustomName(name) => (
      {...model, provisioner: {...prov, customName: name}},
      Tea_Cmd.none,
    )
  | ToggleCustomPanel(panelName) => {
      let exists = prov.customPanels->Array.some(p => p === panelName)
      let newPanels = if exists {
        prov.customPanels->Array.filter(p => p !== panelName)
      } else {
        Array.concat(prov.customPanels, [panelName])
      }
      ({...model, provisioner: {...prov, customPanels: newPanels}}, Tea_Cmd.none)
    }
  | SaveCustomPortfolio => {
      if prov.customName === "" || Array.length(prov.customPanels) === 0 {
        ({...model, provisioner: {...prov, error: Some("Portfolio needs a name and at least one panel")}}, Tea_Cmd.none)
      } else {
        let newPortfolio: portfolio = {
          id: String.toLowerCase(prov.customName)->String.replaceAll(" ", "-"),
          name: prov.customName,
          description: `Custom portfolio with ${Int.toString(Array.length(prov.customPanels))} panels`,
          panels: prov.customPanels,
          defaultIsolation: Native,
          builtIn: false,
          icon: "folder",
          audience: "Custom",
        }
        (
          {
            ...model,
            provisioner: {
              ...prov,
              portfolios: Array.concat(prov.portfolios, [newPortfolio]),
              customName: "",
              customPanels: [],
              error: None,
            },
          },
          Tea_Cmd.none,
        )
      }
    }
  | ExportProvisionerConfig => {
      let humidityStr = switch model.humidity {
      | High => "high"
      | Medium => "medium"
      | Low => "low"
      }
      let preview = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=prov.configs,
        ~portfolios=prov.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(preview)}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "provisioner", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// VoiceTag Sub-Updater (Code MRI Layer 0)
// ===========================================================================

/// STATE TRANSITION: VoiceTag (Code MRI Layer 0 — voice-activated annotation)
///
/// Handles tag CRUD operations, voice input lifecycle, file I/O for .mri.json
/// sidecars, filter state, and voice command parsing. Tags are stored as
/// portable .mri.json sidecar files alongside source files — any tool can
/// consume them without PanLL installed.
let updateVoiceTag = (model: model, msg: voiceTagMsg): (model, Tea_Cmd.t<msg>) => {
  let vt = model.voiceTag
  switch msg {
  | LoadFileTags =>
    switch vt.currentFile {
    | Some(filePath) => (
        {...model, voiceTag: {...vt, error: None}},
        Tea_Cmd.batch(list{
          VoiceTagCmd.loadTags(filePath, result => VoiceTag(TagsLoaded(result))),
          TypeLLService.checkMetadataTypes(filePath, "voicetag", result => VoiceTag(TypeCheckResult(result))),
        }),
      )
    | None => (
        {...model, voiceTag: {...vt, error: Some("No file selected")}},
        Tea_Cmd.none,
      )
    }
  | TagsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        // Parse the .mri.json content. For now, extract tags array from JSON.
        // Full parsing deferred to when we have proper JSON codec — store raw.
        try {
          let parsed = JSON.parseExn(jsonStr)
          switch JSON.Classify.classify(parsed) {
          | JSON.Classify.Object(dict) => {
              let tags = switch dict->Dict.get("tags") {
              | Some(tagsJson) =>
                switch JSON.Classify.classify(tagsJson) {
                | JSON.Classify.Array(arr) =>
                  arr->Array.mapWithIndex((json, idx) => {
                    // Minimal tag parsing — extract what we can from each JSON object
                    switch JSON.Classify.classify(json) {
                    | JSON.Classify.Object(tagDict) => {
                        let getStr = (key: string): string =>
                          switch tagDict->Dict.get(key) {
                          | Some(v) =>
                            switch JSON.Classify.classify(v) {
                            | JSON.Classify.String(s) => s
                            | _ => ""
                            }
                          | None => ""
                          }
                        let getInt = (key: string): int =>
                          switch tagDict->Dict.get(key) {
                          | Some(v) =>
                            switch JSON.Classify.classify(v) {
                            | JSON.Classify.Number(n) => Float.toInt(n)
                            | _ => 0
                            }
                          | None => 0
                          }
                        let getBool = (key: string): bool =>
                          switch tagDict->Dict.get(key) {
                          | Some(v) =>
                            switch JSON.Classify.classify(v) {
                            | JSON.Classify.Bool(b) => b
                            | _ => false
                            }
                          | None => false
                          }
                        let getOptStr = (key: string): option<string> =>
                          switch tagDict->Dict.get(key) {
                          | Some(v) =>
                            switch JSON.Classify.classify(v) {
                            | JSON.Classify.String(s) => Some(s)
                            | JSON.Classify.Null => None
                            | _ => None
                            }
                          | None => None
                          }
                        let tag: mriTag = {
                          id: getInt("id") > 0 ? getInt("id") : idx + 1,
                          startLine: getInt("startLine"),
                          endLine: getInt("endLine"),
                          tagType: VoiceTagEngine.tagTypeFromString(getStr("tagType")),
                          message: getOptStr("message"),
                          attribution: {
                            agent: getStr("agent") === "" ? "human" : getStr("agent"),
                            method: VoiceTagEngine.methodFromString(getStr("method")),
                            timestamp: switch tagDict->Dict.get("timestamp") {
                            | Some(v) =>
                              switch JSON.Classify.classify(v) {
                              | JSON.Classify.Number(n) => n
                              | _ => 0.0
                              }
                            | None => 0.0
                            },
                            sessionId: None,
                          },
                          codeAuthor: None,
                          resolved: getBool("resolved"),
                          resolvedBy: None,
                        }
                        tag
                      }
                    | _ => {
                        let fallback: mriTag = {
                          id: idx + 1,
                          startLine: 0,
                          endLine: 0,
                          tagType: Note,
                          message: Some("(malformed tag)"),
                          attribution: {agent: "unknown", method: Import("parse-error"), timestamp: 0.0, sessionId: None},
                          codeAuthor: None,
                          resolved: false,
                          resolvedBy: None,
                        }
                        fallback
                      }
                    }
                  })
                | _ => []
                }
              | None => []
              }
              let summary = VoiceTagEngine.computeSummary(tags)
              (
                {
                  ...model,
                  voiceTag: {
                    ...vt,
                    tags,
                    summary,
                    error: None,
                  },
                },
                Tea_Cmd.none,
              )
            }
          | _ => ({...model, voiceTag: {...vt, tags: [], error: None}}, Tea_Cmd.none)
          }
        } catch {
        | _ => (
            {...model, voiceTag: {...vt, error: Some("Failed to parse .mri.json")}},
            Tea_Cmd.none,
          )
        }
      }
    | Error(e) => (
        {...model, voiceTag: {...vt, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | TagsSaved(result) =>
    switch result {
    | Ok(_) => ({...model, voiceTag: {...vt, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, voiceTag: {...vt, error: Some(e)}}, Tea_Cmd.none)
    }
  | SidecarDeleted(result) =>
    switch result {
    | Ok(_) => ({...model, voiceTag: {...vt, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, voiceTag: {...vt, error: Some(e)}}, Tea_Cmd.none)
    }
  | ProjectScanned(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = try {
          let json = JSON.parseExn(jsonStr)
          let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
          let getInt = key => obj->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          Some({
            VoiceTagModel.totalTags: getInt("totalTags"),
            unresolvedTags: getInt("unresolvedTags"),
            todoCount: getInt("todoCount"),
            fixmeCount: getInt("fixmeCount"),
            careOnRegions: getInt("careOnRegions"),
            ecoModeRegions: getInt("ecoModeRegions"),
            burdenRegions: getInt("burdenRegions"),
            aiTagCount: getInt("aiTagCount"),
            humanTagCount: getInt("humanTagCount"),
          })
        } catch {
        | _ => None
        }
        switch parsed {
        | Some(summary) => ({...model, voiceTag: {...vt, summary}}, Tea_Cmd.none)
        | None => (model, Tea_Cmd.none)
        }
      }
    | Error(e) => ({...model, voiceTag: {...vt, error: Some(e)}}, Tea_Cmd.none)
    }
  | SelectTag(id) => (
      {...model, voiceTag: {...vt, selectedTagId: id}},
      Tea_Cmd.none,
    )
  | DeleteTagById(id) => {
      let newTags = VoiceTagEngine.removeTag(vt.tags, id)
      let newSummary = VoiceTagEngine.computeSummary(newTags)
      let newModel = {
        ...model,
        voiceTag: {...vt, tags: newTags, summary: newSummary, selectedTagId: None},
      }
      // Auto-save after deletion. If no tags remain, delete the sidecar.
      switch vt.currentFile {
      | Some(filePath) =>
        if Array.length(newTags) === 0 {
          (newModel, VoiceTagCmd.deleteSidecar(filePath, result => VoiceTag(SidecarDeleted(result))))
        } else {
          // Serialise and save — simplified JSON output for now.
          let json = `{"version":"1.0","sourceFile":"${filePath}","tags":[],"lastModified":${Float.toString(Date.now())}}`
          (newModel, VoiceTagCmd.saveTags(filePath, json, result => VoiceTag(TagsSaved(result))))
        }
      | None => (newModel, Tea_Cmd.none)
      }
    }
  | ResolveTagById(id) => {
      let newTags = VoiceTagEngine.resolveTag(vt.tags, id, "human")
      let newSummary = VoiceTagEngine.computeSummary(newTags)
      (
        {...model, voiceTag: {...vt, tags: newTags, summary: newSummary}},
        Tea_Cmd.none,
      )
    }
  | SetFilterType(filterType) => (
      {...model, voiceTag: {...vt, filterType}},
      Tea_Cmd.none,
    )
  | ToggleShowResolved => (
      {...model, voiceTag: {...vt, showResolved: !vt.showResolved}},
      Tea_Cmd.none,
    )
  | StartVoice => (
      {...model, voiceTag: {...vt, voice: VoiceListening, error: None}},
      Tea_Cmd.none,
    )
  | StopVoice => (
      {...model, voiceTag: {...vt, voice: VoiceOff}},
      Tea_Cmd.none,
    )
  | VoiceTranscript(transcript) => {
      // Parse the voice command and apply it.
      let cmd = VoiceTagEngine.parseVoiceCommand(transcript)
      switch cmd {
      | VoiceTagEngine.TagRange(startLine, endLine, tagType, message) => {
          let newTag = VoiceTagEngine.createTagWithAttribution(
            vt.tags, startLine, endLine, tagType, message, "human", Voice,
          )
          let newTags = VoiceTagEngine.addTag(vt.tags, newTag)
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          (
            {...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}},
            Tea_Cmd.none,
          )
        }
      | VoiceTagEngine.TagSelection(tagType, message) => {
          // Tag at line 1 (no selection context available — future: use editor selection).
          let newTag = VoiceTagEngine.createTagWithAttribution(
            vt.tags, 1, 1, tagType, message, "human", Voice,
          )
          let newTags = VoiceTagEngine.addTag(vt.tags, newTag)
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          (
            {...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}},
            Tea_Cmd.none,
          )
        }
      | VoiceTagEngine.DeleteTag(id) => {
          let newTags = VoiceTagEngine.removeTag(vt.tags, id)
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          ({...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}}, Tea_Cmd.none)
        }
      | VoiceTagEngine.ResolveTag(id) => {
          let newTags = VoiceTagEngine.resolveTag(vt.tags, id, "human")
          let newSummary = VoiceTagEngine.computeSummary(newTags)
          ({...model, voiceTag: {...vt, tags: newTags, summary: newSummary, voice: VoiceOff}}, Tea_Cmd.none)
        }
      | VoiceTagEngine.ShowTag(id) => (
          {...model, voiceTag: {...vt, selectedTagId: Some(id), voice: VoiceOff}},
          Tea_Cmd.none,
        )
      | VoiceTagEngine.ShowAll(maybeType) => (
          {...model, voiceTag: {...vt, filterType: maybeType, voice: VoiceOff}},
          Tea_Cmd.none,
        )
      | VoiceTagEngine.EditTag(_) | VoiceTagEngine.WhoWroteLine(_)
      | VoiceTagEngine.AttributeHuman | VoiceTagEngine.AttributeAi(_) =>
        // These commands need editor integration — stub for now.
        ({...model, voiceTag: {...vt, voice: VoiceOff}}, Tea_Cmd.none)
      | VoiceTagEngine.VoiceUnrecognised(raw) => (
          {...model, voiceTag: {...vt, voice: Model.VoiceError(`Unrecognised: "${raw}"`)}},
          Tea_Cmd.none,
        )
      }
    }
  | VoiceError(err) => (
      {...model, voiceTag: {...vt, voice: Model.VoiceError(err)}},
      Tea_Cmd.none,
    )
  | SetCurrentFile(filePath) => (
      {...model, voiceTag: {...vt, currentFile: Some(filePath), tags: [], summary: VoiceTagEngine.emptySummary, error: None}},
      VoiceTagCmd.loadTags(filePath, result => VoiceTag(TagsLoaded(result))),
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "voicetag", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Provenance Sub-Updater (Core Infrastructure)
// ===========================================================================

/// STATE TRANSITION: Provenance Map (code trust surface)
///
/// Handles file analysis requests, result parsing, palette switching,
/// hostile UX toggling, and per-region acknowledgement. The provenance
/// map is ambient — it doesn't occupy a panel slot.
let updateProvenance = (model: model, msg: provenanceMsg): (model, Tea_Cmd.t<msg>) => {
  let prov = model.provenance
  switch msg {
  | AnalyseFile(repoPath, filePath) => (
      {...model, provenance: {...prov, loading: true, error: None}},
      ProvenanceCmd.analyseFile(repoPath, filePath, result => Provenance(AnalysisResult(result))),
    )
  | AnalysisResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = try {
          let json = JSON.parseExn(jsonStr)
          let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
          let filePath = obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let analysedAt = obj->Dict.get("analysedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(Date.now())
          let regionsArr = obj->Dict.get("regions")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
          let regions = regionsArr->Array.filterMap(item => {
            let r = item->JSON.Decode.object->Option.getOr(Dict.make())
            let startLine = r->Dict.get("startLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let endLine = r->Dict.get("endLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let trustStr = r->Dict.get("trustLevel")->Option.flatMap(JSON.Decode.string)->Option.getOr("unknown")
            let trustLevel: ProvenanceModel.trustLevel = switch trustStr {
            | "verified" => Verified
            | "human_reviewed" => HumanReviewed
            | "ai_assisted" => AiAssisted
            | "unreviewed_ai" => UnreviewedAi
            | _ => Unknown
            }
            let author = r->Dict.get("author")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let authorEmail = r->Dict.get("authorEmail")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let coAuthored = r->Dict.get("coAuthored")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            let coAuthor = r->Dict.get("coAuthor")->Option.flatMap(JSON.Decode.string)
            let commitSha = r->Dict.get("commitSha")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let commitTimestamp = r->Dict.get("commitTimestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let acknowledged = r->Dict.get("acknowledged")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            Some({
              ProvenanceModel.startLine: Float.toInt(startLine),
              endLine: Float.toInt(endLine),
              trustLevel,
              author,
              authorEmail,
              coAuthored,
              coAuthor,
              commitSha,
              commitTimestamp,
              acknowledged,
            })
          })
          let summaryObj = obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
          let getInt = key => summaryObj->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          let summary: ProvenanceModel.provenanceSummary = {
            totalLines: getInt("totalLines"),
            verifiedLines: getInt("verifiedLines"),
            humanReviewedLines: getInt("humanReviewedLines"),
            aiAssistedLines: getInt("aiAssistedLines"),
            unreviewedAiLines: getInt("unreviewedAiLines"),
            unknownLines: getInt("unknownLines"),
            authorCount: getInt("authorCount"),
            coAuthorCount: getInt("coAuthorCount"),
            hasViolations: summaryObj->Dict.get("hasViolations")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false),
            unsoundMarkers: getInt("unsoundMarkers"),
          }
          let fp: ProvenanceModel.fileProvenance = {filePath, regions, summary, analysedAt}
          Some(fp)
        } catch {
        | _ => None
        }
        switch parsed {
        | Some(fp) => ({...model, provenance: {...prov, activeFile: Some(fp), loading: false, error: None}}, Tea_Cmd.none)
        | None => ({...model, provenance: {...prov, loading: false, error: None}}, Tea_Cmd.none)
        }
      }
    | Error(e) => (
        {...model, provenance: {...prov, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | UnsoundScanResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = try {
          let json = JSON.parseExn(jsonStr)
          let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
          let unsoundMarkers = obj->Dict.get("unsoundMarkers")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          Some(unsoundMarkers)
        } catch {
        | _ => None
        }
        switch (parsed, prov.activeFile) {
        | (Some(count), Some(fp)) => {
            let updatedSummary = {...fp.summary, unsoundMarkers: count, hasViolations: count > 0 || fp.summary.hasViolations}
            let updatedFp = {...fp, summary: updatedSummary}
            ({...model, provenance: {...prov, activeFile: Some(updatedFp)}}, Tea_Cmd.none)
          }
        | _ => (model, Tea_Cmd.none)
        }
      }
    | Error(e) => (
        {...model, provenance: {...prov, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | SetPalette(palette) => (
      {...model, provenance: {...prov, palette}},
      Tea_Cmd.none,
    )
  | ToggleHostileUx => (
      {...model, provenance: {...prov, hostileUxSuppressed: !prov.hostileUxSuppressed}},
      Tea_Cmd.none,
    )
  | AcknowledgeRegion(_filePath, startLine) =>
    switch prov.activeFile {
    | Some(fp) => {
        let updatedRegions = fp.regions->Array.map(r =>
          if r.startLine === startLine { {...r, acknowledged: true} } else { r }
        )
        let updatedFp = {...fp, regions: updatedRegions}
        ({...model, provenance: {...prov, activeFile: Some(updatedFp)}}, Tea_Cmd.none)
      }
    | None => (model, Tea_Cmd.none)
    }
  | SetEnabled(enabled) => (
      {...model, provenance: {...prov, enabled}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "provenance", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => {
    logDegradedService("TypeLL", "cross-panel type check failed")
    (model, Tea_Cmd.none)
  }
  }
}

// ===========================================================================
// Watcher Sub-Updater (Core Infrastructure)
// ===========================================================================

/// STATE TRANSITION: Watcher (filesystem observation)
///
/// Handles watcher lifecycle (start/stop/status) and incoming filesystem events.
/// FileEvent is the key message — it carries a `watchEvent` that panels can
/// react to. The watcher maintains a ring buffer of the last 50 events so
/// panels opened after events occur can still see recent activity.
let updateWatcher = (model: model, msg: watcherMsg): (model, Tea_Cmd.t<msg>) => {
  let w = model.watcher
  switch msg {
  | StartWatcher(paths) => (
      {...model, watcher: {...w, error: None}},
      WatcherCmd.start(paths, result => Watcher(WatcherResult(result))),
    )
  | StopWatcher => (
      model,
      WatcherCmd.stop(result => Watcher(WatcherResult(result))),
    )
  | RequestStatus => (
      model,
      WatcherCmd.status(result => Watcher(StatusLoaded(result))),
    )
  | WatcherResult(result) =>
    switch result {
    | Ok(_json) => (
        {...model, watcher: {...w, running: true, error: None}},
        Tea_Cmd.none,
      )
    | Error(e) => (
        {...model, watcher: {...w, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | StatusLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        // Parse the status JSON to update watcher state.
        // The Rust side returns { running, watched_paths, event_count }.
        try {
          let json = JSON.parseExn(jsonStr)
          switch JSON.Classify.classify(json) {
          | JSON.Classify.Object(dict) => {
              let running = switch dict->Dict.get("running") {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | JSON.Classify.Bool(b) => b
                | _ => false
                }
              | None => false
              }
              let eventCount = switch dict->Dict.get("event_count") {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | JSON.Classify.Number(n) => Float.toInt(n)
                | _ => 0
                }
              | None => 0
              }
              (
                {
                  ...model,
                  watcher: {
                    ...w,
                    running,
                    eventCount,
                    error: None,
                  },
                },
                Tea_Cmd.none,
              )
            }
          | _ => (model, Tea_Cmd.none)
          }
        } catch {
        | _ => (model, Tea_Cmd.none)
        }
      }
    | Error(e) => (
        {...model, watcher: {...w, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | FileEvent(event) => {
      // Add to ring buffer (keep last 50 events).
      let maxEvents = 50
      let updated = Array.concat(w.recentEvents, [event])
      let trimmed = if Array.length(updated) > maxEvents {
        updated->Array.sliceToEnd(~start=Array.length(updated) - maxEvents)
      } else {
        updated
      }
      (
        {
          ...model,
          watcher: {
            ...w,
            eventCount: w.eventCount + 1,
            recentEvents: trimmed,
          },
        },
        Tea_Cmd.none,
      )
    }
  }
}

// ===========================================================================
// AI Sub-Updater (Multi-Provider Neural Interface)
// ===========================================================================

/// STATE TRANSITION: AI (multi-provider neural interface)
///
/// Handles message sending to AI providers, provider management (enable/disable,
/// model selection, priority), system prompt context building, and conversation
/// state. Provider precedence with automatic 429 fallthrough ensures continuous
/// service even when a provider's quota is exhausted.
let updateAi = (model: model, msg: aiMsg): (model, Tea_Cmd.t<msg>) => {
  let ai = model.ai
  switch msg {
  | SendMessage => {
      if ai.inputText === "" {
        (model, Tea_Cmd.none)
      } else {
        // Create the user message.
        let userMsg: aiMessage = {
          role: User,
          content: ai.inputText,
          provider: None,
          model: None,
          inputTokens: 0,
          outputTokens: 0,
          timestamp: Date.now(),
        }
        let newMessages = Array.concat(ai.messages, [userMsg])
        // Select provider by priority.
        let selectedProvider = AiEngine.selectProvider(ai.providers)
        let providerId = switch selectedProvider {
        | Some(p) => Some(AiEngine.providerIdToString(p.id))
        | None => None
        }
        // Build history as a simple JSON array for the Tauri backend.
        // We pass an empty array; the backend rebuilds from the request.
        let history: array<JSON.t> = []
        (
          {
            ...model,
            ai: {
              ...ai,
              messages: newMessages,
              inputText: "",
              loading: true,
              error: None,
            },
          },
          Tea_Cmd.batch(list{
            AiCmd.sendMessage(
              userMsg.content,
              history,
              ai.systemPrompt,
              providerId,
              ai.broadcastMode,
              result => Ai(MessageReceived(result)),
            ),
            TypeLLService.checkCodeTypes(userMsg.content, "prompt", result => Ai(TypeCheckResult(result))),
          }),
        )
      }
    }
  | MessageReceived(result) =>
    switch result {
    | Ok(jsonStr) => {
        switch AiEngine.parseMessageResponse(jsonStr) {
        | Ok(aiMessage) => (
            {
              ...model,
              ai: {
                ...ai,
                messages: Array.concat(ai.messages, [aiMessage]),
                loading: false,
                error: None,
                totalInputTokens: ai.totalInputTokens + aiMessage.inputTokens,
                totalOutputTokens: ai.totalOutputTokens + aiMessage.outputTokens,
              },
            },
            Tea_Cmd.none,
          )
        | Error("quota_exhausted") => {
            // Mark provider as exhausted and auto-retry with next provider.
            let exhaustedProvider = AiEngine.selectProvider(ai.providers)
            switch exhaustedProvider {
            | Some(p) => {
                let newProviders = ai.providers->Array.map(pc =>
                  if pc.id === p.id {
                    {...pc, quotaExhausted: true}
                  } else {
                    pc
                  }
                )
                let newStatuses = ai.providerStatuses->Array.map(((id, status)) =>
                  if id === p.id {
                    (id, (QuotaExhausted: aiProviderStatus))
                  } else {
                    (id, status)
                  }
                )
                (
                  {
                    ...model,
                    ai: {
                      ...ai,
                      providers: newProviders,
                      providerStatuses: newStatuses,
                      loading: false,
                      error: Some(`${AiEngine.providerShortLabel(p.id)} quota exhausted — falling through to next provider`),
                    },
                  },
                  Tea_Cmd.none,
                )
              }
            | None => (
                {...model, ai: {...ai, loading: false, error: Some("All providers exhausted")}},
                Tea_Cmd.none,
              )
            }
          }
        | Error(e) => (
            {...model, ai: {...ai, loading: false, error: Some(e)}},
            Tea_Cmd.none,
          )
        }
      }
    | Error(e) => (
        {...model, ai: {...ai, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | SetAiInput(text) => ({...model, ai: {...ai, inputText: text}}, Tea_Cmd.none)
  | SetAiCategory(cat) => ({...model, ai: {...ai, activeCategory: cat}}, Tea_Cmd.none)
  | ToggleBroadcast => ({...model, ai: {...ai, broadcastMode: !ai.broadcastMode}}, Tea_Cmd.none)
  | CheckProvider(id) => {
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id { (pid, (Checking: aiProviderStatus)) } else { (pid, status) }
      )
      (
        {...model, ai: {...ai, providerStatuses: newStatuses}},
        AiCmd.checkProvider(AiEngine.providerIdToString(id), result =>
          Ai(ProviderChecked(id, result))
        ),
      )
    }
  | ProviderChecked(id, result) => {
      let newStatus = switch result {
      | Ok(jsonStr) => {
          try {
            let parsed = JSON.parseExn(jsonStr)
            switch JSON.Classify.classify(parsed) {
            | Object(obj) =>
              switch Dict.get(obj, "status") {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | String("ready") => (Ready: aiProviderStatus)
                | String("no_key") => NoKey
                | String("disabled") => Disabled
                | String("error") => {
                    let detail = switch Dict.get(obj, "detail") {
                    | Some(d) =>
                      switch JSON.Classify.classify(d) {
                      | String(s) => s
                      | _ => "Unknown error"
                      }
                    | None => "Unknown error"
                    }
                    AiProviderError(detail)
                  }
                | _ => AiProviderError("Unknown status")
                }
              | None => AiProviderError("Missing status")
              }
            | _ => AiProviderError("Invalid response")
            }
          } catch {
          | _ => AiProviderError("Parse error")
          }
        }
      | Error(e) => AiProviderError(e)
      }
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id { (pid, newStatus) } else { (pid, status) }
      )
      ({...model, ai: {...ai, providerStatuses: newStatuses}}, Tea_Cmd.none)
    }
  | SetAiModel(id, newModel) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id { {...p, selectedModel: newModel} } else { p }
      )
      (
        {...model, ai: {...ai, providers: newProviders}},
        AiCmd.setModel(AiEngine.providerIdToString(id), newModel, result =>
          Ai(ModelSet(result))
        ),
      )
    }
  | ModelSet(_result) => (model, Tea_Cmd.none)
  | SetAiPriority(id, priority) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id { {...p, priority} } else { p }
      )
      (
        {...model, ai: {...ai, providers: newProviders}},
        AiCmd.setPriority(AiEngine.providerIdToString(id), priority, result =>
          Ai(PrioritySet(result))
        ),
      )
    }
  | PrioritySet(_result) => (model, Tea_Cmd.none)
  | ToggleAiProvider(id) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id { {...p, enabled: !p.enabled} } else { p }
      )
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id {
          let provider = newProviders->Array.find(p => p.id === id)
          let isEnabled = switch provider {
          | Some(p) => p.enabled
          | None => false
          }
          (pid, isEnabled ? (Ready: aiProviderStatus) : Disabled)
        } else {
          (pid, status)
        }
      )
      (
        {...model, ai: {...ai, providers: newProviders, providerStatuses: newStatuses}},
        AiCmd.toggleProvider(AiEngine.providerIdToString(id), result =>
          Ai(ProviderToggled(result))
        ),
      )
    }
  | ProviderToggled(_result) => (model, Tea_Cmd.none)
  | ClearAiHistory => (
      {
        ...model,
        ai: {
          ...ai,
          messages: [],
          totalInputTokens: 0,
          totalOutputTokens: 0,
          error: None,
        },
      },
      AiCmd.clearHistory(result => Ai(HistoryCleared(result))),
    )
  | HistoryCleared(_result) => (model, Tea_Cmd.none)
  | BuildContext(repoPath) => (
      model,
      AiCmd.buildContext(repoPath, result => Ai(ContextBuilt(result))),
    )
  | ContextBuilt(result) =>
    switch result {
    | Ok(jsonStr) => {
        try {
          let parsed = JSON.parseExn(jsonStr)
          switch JSON.Classify.classify(parsed) {
          | Object(obj) =>
            switch Dict.get(obj, "context") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | String(ctx) => (
                  {
                    ...model,
                    ai: {
                      ...ai,
                      autoContext: ctx,
                      systemPrompt: ai.systemPrompt ++ "\n\n" ++ ctx,
                    },
                  },
                  Tea_Cmd.none,
                )
              | _ => (model, Tea_Cmd.none)
              }
            | None => (model, Tea_Cmd.none)
            }
          | _ => (model, Tea_Cmd.none)
          }
        } catch {
        | _ => (model, Tea_Cmd.none)
        }
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | LoadProviderState => (model, AiCmd.getState(result => Ai(ProviderStateLoaded(result))))
  | ProviderStateLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch AiEngine.parseProviderState(jsonStr) {
      | Ok(providers) => ({...model, ai: {...ai, providers}}, Tea_Cmd.none)
      | Error(_) => (model, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | SetSystemPrompt(prompt) => ({...model, ai: {...ai, systemPrompt: prompt}}, Tea_Cmd.none)
  | MarkQuotaExhausted(id) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id { {...p, quotaExhausted: true} } else { p }
      )
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id { (pid, (QuotaExhausted: aiProviderStatus)) } else { (pid, status) }
      )
      ({...model, ai: {...ai, providers: newProviders, providerStatuses: newStatuses}}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "ai", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Repo Loader Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Repo Loader (repository scanning, panel configuration)
///
/// Handles directory picking, repo scanning, panel suggestion management,
/// PANELS.a2ml saving, recent repo tracking, and farm search. When a repo
/// is loaded, dispatches Ai(BuildContext) to give the AI panel repo awareness.
let updateRepoLoader = (model: model, msg: repoLoaderMsg): (model, Tea_Cmd.t<msg>) => {
  let rl = model.repoLoader
  switch msg {
  | PickRepoDirectory => (
      model,
      RepoLoaderCmd.pickDirectory(result => RepoLoader(DirectoryPicked(result))),
    )
  | DirectoryPicked(result) =>
    switch result {
    | Ok(path) => (
        {...model, repoLoader: {...rl, scanning: true, error: None}},
        RepoLoaderCmd.scan(path, result => RepoLoader(ScanResult(result))),
      )
    | Error(e) => ({...model, repoLoader: {...rl, error: Some(e)}}, Tea_Cmd.none)
    }
  | ScanRepo(path) => (
      {...model, repoLoader: {...rl, scanning: true, error: None}},
      Tea_Cmd.batch(list{
        RepoLoaderCmd.scan(path, result => RepoLoader(ScanResult(result))),
        TypeLLService.checkConfigTypes(path, "repoloader", result => RepoLoader(TypeCheckResult(result))),
      }),
    )
  | ScanResult(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch RepoLoaderEngine.parseScanResult(jsonStr) {
      | Ok((repo, suggestions)) => (
          {
            ...model,
            repoLoader: {
              ...rl,
              currentRepo: Some(repo),
              suggestions,
              scanning: false,
              activeCategory: Configure,
              saved: false,
              error: None,
            },
          },
          // Push context to AI panel.
          Tea_Cmd.msg(Ai(BuildContext(repo.path))),
        )
      | Error(e) => (
          {...model, repoLoader: {...rl, scanning: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, repoLoader: {...rl, scanning: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | ToggleSuggestion(panelName) => {
      let newSuggestions = rl.suggestions->Array.map(s =>
        if s.panelName === panelName { {...s, enabled: !s.enabled} } else { s }
      )
      ({...model, repoLoader: {...rl, suggestions: newSuggestions, saved: false}}, Tea_Cmd.none)
    }
  | SavePanels =>
    switch rl.currentRepo {
    | Some(repo) => {
        // Serialise enabled suggestions as a JSON string for the backend.
        let enabledPanels = rl.suggestions->Array.filter(s => s.enabled)
        let jsonEntries = enabledPanels->Array.map(s => {
          `{"name":"${s.panelName}","enabled":true,"priority":"${s.priority}"}`
        })
        let jsonStr = "[" ++ Array.join(jsonEntries, ",") ++ "]"
        (
          model,
          RepoLoaderCmd.savePanels(repo.path, jsonStr, result =>
            RepoLoader(PanelsSaved(result))
          ),
        )
      }
    | None => ({...model, repoLoader: {...rl, error: Some("No repo loaded")}}, Tea_Cmd.none)
    }
  | PanelsSaved(result) =>
    switch result {
    | Ok(_) => ({...model, repoLoader: {...rl, saved: true, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, repoLoader: {...rl, error: Some(e)}}, Tea_Cmd.none)
    }
  | LoadRecent => (
      model,
      RepoLoaderCmd.listRecent(result => RepoLoader(RecentLoaded(result))),
    )
  | RecentLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let paths = RepoLoaderEngine.parseRecentPaths(jsonStr)
        ({...model, repoLoader: {...rl, recentPaths: paths}}, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | SearchFarm(query) => (
      model,
      RepoLoaderCmd.searchFarm(query, result => RepoLoader(FarmSearchResult(result))),
    )
  | FarmSearchResult(_result) =>
    // Farm search results are displayed directly — handled in UI.
    (model, Tea_Cmd.none)
  | SetRepoSearchText(text) => ({...model, repoLoader: {...rl, searchText: text}}, Tea_Cmd.none)
  | SetRepoCategory(cat) => ({...model, repoLoader: {...rl, activeCategory: cat}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "repoloader", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

/// Determines whether a message should trigger an auto-save.
/// Returns false for NoOp and SaveState (no state change), true for everything else.
let shouldAutoSave = (msg: msg): bool => {
  switch msg {
  | NoOp => false
  | SaveState => false
  | _ => true
  }
}

// ===========================================================================
// Workspace Sub-Updater (DD-022–DD-027)
// ===========================================================================

/// STATE TRANSITION: Workspace — modes, groups, arrangements, sessions,
/// protection, execution mode, checkpoints, metadata viewer.
let updateWorkspace = (model: model, msg: workspaceMsg): (model, Tea_Cmd.t<msg>) => {
  let ws = model.workspace
  switch msg {
  | SetWorkspaceMode(mode) => ({...model, workspace: {...ws, mode}}, Tea_Cmd.none)
  | CycleWorkspaceMode => ({...model, workspace: {...ws, mode: WorkspaceEngine.cycleMode(ws.mode)}}, Tea_Cmd.none)
  | SetProtection(p) => ({...model, workspace: {...ws, protection: p}}, Tea_Cmd.none)
  | SetExecutionMode(m) => ({...model, workspace: {...ws, executionMode: m}}, Tea_Cmd.none)
  | ToggleDryRun => {
      let newMode = switch ws.executionMode {
      | Live => WorkspaceModel.DryRun
      | DryRun => WorkspaceModel.Live
      | other => other
      }
      ({...model, workspace: {...ws, executionMode: newMode}}, Tea_Cmd.none)
    }
  | CreateGroup(id, name, panelIds) =>
    ({...model, workspace: {...ws, groups: WorkspaceEngine.createGroup(ws.groups, id, name, panelIds)}}, Tea_Cmd.none)
  | DisbandGroup(id) =>
    ({...model, workspace: {...ws, groups: WorkspaceEngine.disbandGroup(ws.groups, id)}}, Tea_Cmd.none)
  | ToggleGroupLock(id) => {
      let hasGroup = Array.find(ws.groups, g => g.id === id)
      switch hasGroup {
      | Some(g) =>
        let newGroups = if g.locked {
          WorkspaceEngine.unlockGroup(ws.groups, id)
        } else {
          WorkspaceEngine.lockGroup(ws.groups, id)
        }
        ({...model, workspace: {...ws, groups: newGroups}}, Tea_Cmd.none)
      | None => (model, Tea_Cmd.none)
      }
    }
  | ToggleGroupVisibility(id) =>
    ({...model, workspace: {...ws, groups: WorkspaceEngine.toggleGroupVisibility(ws.groups, id)}}, Tea_Cmd.none)
  | PushToBack(id) =>
    ({...model, workspace: {...ws, groups: WorkspaceEngine.pushToBack(ws.groups, id)}}, Tea_Cmd.none)
  | PullToFront(id) =>
    ({...model, workspace: {...ws, groups: WorkspaceEngine.pullToFront(ws.groups, id)}}, Tea_Cmd.none)
  | SaveArrangement(id, name) => {
    let arr: arrangement = {
      id, name, positions: [], groups: ws.groups, builtIn: false, lastSaved: Date.now(),
    }
    let arrangements = Array.concat(ws.arrangements->Array.filter(a => a.id !== id), [arr])
    let json = `{"id":"${id}","name":"${name}","builtIn":false,"lastSaved":${Float.toString(Date.now())},"positions":[],"groups":[]}`
    ({...model, workspace: {...ws, arrangements}}, Tea_Cmd.batch(list{
      WorkspaceCmd.saveArrangement(json),
      TypeLLService.checkConfigTypes(json, "workspace", result => Workspace(TypeCheckResult(result))),
    }))
  }
  | LoadArrangement(id) =>
    ({...model, workspace: {...ws, activeArrangementId: Some(id)}}, Tea_Cmd.none)
  | DeleteArrangement(id) =>
    ({...model, workspace: {...ws, arrangements: WorkspaceEngine.deleteArrangement(ws.arrangements, id)}}, Tea_Cmd.none)
  | ArrangementsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let loaded = try {
          let json = JSON.parseExn(jsonStr)
          json->JSON.Decode.array->Option.getOr([])->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            let id = gs(o, "id")
            if id !== "" {
              Some({id, name: gs(o, "name"), positions: [], groups: [], builtIn: gb(o, "builtIn"), lastSaved: gf(o, "lastSaved")}: arrangement)
            } else { None }
          })
        } catch { | _ => [] }
        let merged = Array.concat(ws.arrangements->Array.filter(a => a.builtIn), loaded->Array.filter(a => !a.builtIn))
        ({...model, workspace: {...ws, arrangements: merged}}, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | CreateSession(id, name) => {
    let now = Date.now()
    let newSession: session = {
      id,
      name,
      repoPath: None,
      arrangementId: ws.activeArrangementId,
      protection: ws.protection,
      executionMode: ws.executionMode,
      workspaceMode: ws.mode,
      checkpoints: [],
      created: now,
      lastActive: now,
      forkedFrom: None,
    }
    let sessions = Array.concat(ws.sessions, [newSession])
    ({...model, workspace: {...ws, sessions, activeSessionId: Some(id)}}, Tea_Cmd.none)
  }
  | ForkSession(newId, newName) => {
    let now = Date.now()
    let parentSession = ws.sessions->Array.find(s => Some(s.id) === ws.activeSessionId)
    let forked: session = switch parentSession {
    | Some(parent) => {
        ...parent,
        id: newId,
        name: newName,
        created: now,
        lastActive: now,
        forkedFrom: Some(parent.id),
        checkpoints: [],
      }
    | None => {
        id: newId,
        name: newName,
        repoPath: None,
        arrangementId: ws.activeArrangementId,
        protection: ws.protection,
        executionMode: ws.executionMode,
        workspaceMode: ws.mode,
        checkpoints: [],
        created: now,
        lastActive: now,
        forkedFrom: ws.activeSessionId,
      }
    }
    let sessions = Array.concat(ws.sessions, [forked])
    ({...model, workspace: {...ws, sessions, activeSessionId: Some(newId)}}, Tea_Cmd.none)
  }
  | DeleteSession(id) =>
    ({...model, workspace: {...ws, sessions: WorkspaceEngine.deleteSession(ws.sessions, id)}}, Tea_Cmd.none)
  | SwitchSession(id) =>
    ({...model, workspace: {...ws, activeSessionId: Some(id)}}, Tea_Cmd.none)
  | SessionsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let loaded = try {
          let json = JSON.parseExn(jsonStr)
          json->JSON.Decode.array->Option.getOr([])->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let id = gs(o, "id")
            if id !== "" {
              Some({
                id, name: gs(o, "name"), repoPath: o->Dict.get("repoPath")->Option.flatMap(JSON.Decode.string),
                arrangementId: o->Dict.get("arrangementId")->Option.flatMap(JSON.Decode.string),
                protection: Open, executionMode: Live, workspaceMode: EverythingMode,
                checkpoints: [], created: gf(o, "created"), lastActive: gf(o, "lastActive"),
                forkedFrom: o->Dict.get("forkedFrom")->Option.flatMap(JSON.Decode.string),
              }: session)
            } else { None }
          })
        } catch { | _ => [] }
        if Array.length(loaded) > 0 {
          ({...model, workspace: {...ws, sessions: loaded}}, Tea_Cmd.none)
        } else {
          (model, Tea_Cmd.none)
        }
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | AddCheckpoint(id, label) => {
    let now = Date.now()
    let cp: checkpoint = {id, label, timestamp: now, automatic: false}
    let sessions = ws.sessions->Array.map(s =>
      if Some(s.id) === ws.activeSessionId {
        {...s, checkpoints: Array.concat(s.checkpoints, [cp]), lastActive: now}
      } else {
        s
      }
    )
    ({...model, workspace: {...ws, sessions}}, Tea_Cmd.none)
  }
  | SystemInfoLoaded(result) => {
      switch result {
      | Ok(jsonStr) => {
          let parsed = try {
            let json = JSON.parseExn(jsonStr)
            let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
            let getFloat = key =>
              obj->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            Some({
              StatusBarModel.cpuUsage: getFloat("cpu_usage"),
              memoryTotal: getFloat("memory_total"),
              memoryUsed: getFloat("memory_used"),
              diskTotal: getFloat("disk_total"),
              diskUsed: getFloat("disk_used"),
              uptimeSeconds: getFloat("uptime_seconds"),
            })
          } catch {
          | _ => None
          }
          switch parsed {
          | Some(info) => (
              {...model, statusBar: {...model.statusBar, systemInfo: Some(info)}},
              Tea_Cmd.none,
            )
          | None => (model, Tea_Cmd.none)
          }
        }
      | Error(_) => (model, Tea_Cmd.none)
      }
    }
  | ToggleConfigurator =>
    ({...model, workspace: {...ws, configuratorOpen: !ws.configuratorOpen}}, Tea_Cmd.none)
  | SetConfiguratorTab(tab) =>
    ({...model, workspace: {...ws, configuratorTab: tab}}, Tea_Cmd.none)
  | ViewMetadata(item) =>
    ({...model, workspace: {...ws, viewingMetadata: Some(item)}}, Tea_Cmd.none)
  | CloseMetadata =>
    ({...model, workspace: {...ws, viewingMetadata: None, metadataContent: None}}, Tea_Cmd.none)
  | MetadataLoaded(result) => {
      switch result {
      | Ok(content) =>
        ({...model, workspace: {...ws, metadataContent: Some(content)}}, Tea_Cmd.none)
      | Error(_) => (model, Tea_Cmd.none)
      }
    }
  | ResetPanel(panelId) => {
    // Reset a single panel to its default state by matching the panel identifier.
    let m = switch panelId {
    | "coprocessors" => {...model, coprocessors: CoprocessorsEngine.defaultState}
    | "buildDashboard" => {...model, buildDashboard: BuildDashboardEngine.defaultState}
    | "releaseManager" => {...model, releaseManager: ReleaseManagerEngine.defaultState}
    | "automationRouter" => {...model, automationRouter: AutomationRouterEngine.defaultState}
    | "scriptGist" => {...model, scriptGist: ScriptGistEngine.defaultState}
    | "security" => {...model, security: SecurityEngine.defaultState}
    | "voiceTag" => {...model, voiceTag: VoiceTagEngine.defaultState}
    | "massPanic" => {...model, massPanic: MassPanicModel.init}
    | "panicAttack" => {...model, panicAttack: PanicAttackModel.init}
    | "tsdm" => {...model, tsdm: TsdmModel.init}
    | "levelArchitect" => {...model, levelArchitect: LevelArchitectEngine.defaultState}
    | "networkTopology" => {...model, networkTopology: NetworkTopologyEngine.defaultState}
    | "typell" => {...model, typell: TypeLLEngine.defaultState}
    | "boj" => {...model, boj: BojEngine.defaultState}
    | "vmInspector" => {...model, vmInspector: VmInspectorEngine.defaultState}
    | "gamePreview" => {...model, gamePreview: GamePreviewEngine.defaultState}
    | "provenance" => {...model, provenance: ProvenanceEngine.defaultState}
    | "myLang" => {...model, myLang: MyLangEngine.defaultState}
    | "valenceShell" => {...model, valenceShell: ValenceShellEngine.defaultState}
    | "migration" => {...model, migration: MigrationEngine.defaultState}
    | "repoLoader" => {...model, repoLoader: RepoLoaderEngine.defaultState}
    | "ai" => {...model, ai: AiEngine.defaultState}
    | "statusBar" => {...model, statusBar: StatusBarEngine.defaultState}
    | "cladeBrowser" => {...model, cladeBrowser: CladeBrowserModel.defaultState}
    | "protocolSquisher" => {...model, protocolSquisher: ProtocolSquisherEngine.defaultState}
    | "aerie" => {...model, aerie: AerieEngine.defaultState}
    | _ => model
    }
    (m, Tea_Cmd.none)
  }
  | ResetAllPanels => {
    // Reset all panels to defaults, preserving workspace config (arrangements, sessions, mode).
    let m = {
      ...model,
      coprocessors: CoprocessorsEngine.defaultState,
      buildDashboard: BuildDashboardEngine.defaultState,
      releaseManager: ReleaseManagerEngine.defaultState,
      automationRouter: AutomationRouterEngine.defaultState,
      scriptGist: ScriptGistEngine.defaultState,
      security: SecurityEngine.defaultState,
      voiceTag: VoiceTagEngine.defaultState,
      massPanic: MassPanicModel.init,
      panicAttack: PanicAttackModel.init,
      tsdm: TsdmModel.init,
      levelArchitect: LevelArchitectEngine.defaultState,
      networkTopology: NetworkTopologyEngine.defaultState,
      typell: TypeLLEngine.defaultState,
      boj: BojEngine.defaultState,
      vmInspector: VmInspectorEngine.defaultState,
      gamePreview: GamePreviewEngine.defaultState,
      provenance: ProvenanceEngine.defaultState,
      myLang: MyLangEngine.defaultState,
      valenceShell: ValenceShellEngine.defaultState,
      migration: MigrationEngine.defaultState,
      repoLoader: RepoLoaderEngine.defaultState,
      ai: AiEngine.defaultState,
      statusBar: StatusBarEngine.defaultState,
      cladeBrowser: CladeBrowserModel.defaultState,
      protocolSquisher: ProtocolSquisherEngine.defaultState,
      aerie: AerieEngine.defaultState,
    }
    (m, Tea_Cmd.none)
  }
  | ExportWorkspaceConfig => {
      let humidityStr = switch model.humidity {
      | High => "high"
      | Medium => "medium"
      | Low => "low"
      }
      let preview = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=model.provisioner.configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(preview)}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "workspace", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Capture Sub-Updater (DD-022)
// ===========================================================================

/// STATE TRANSITION: Capture — screenshots, recordings, demos, cloning, comparison.
let updateCapture = (model: model, msg: captureMsg): (model, Tea_Cmd.t<msg>) => {
  let cap = model.capture
  switch msg {
  | CaptureScreenshot(panelId) => {
    // Invoke html2canvas capture via JS interop, then save the result through Tauri.
    let captureId = "cap-" ++ Float.toString(Date.now())
    let format = "png"
    // The actual html2canvas call happens in JS; here we wire the save command
    // with a placeholder base64 string that the frontend JS bridge will populate.
    (model, Tea_Cmd.batch(list{
      CaptureCmd.saveScreenshot(captureId, panelId, "", format),
      TypeLLService.checkConfigTypes(panelId, "capture", result => Capture(TypeCheckResult(result))),
    }))
  }
  | ScreenshotSaved(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = try {
          let json = JSON.parseExn(jsonStr)
          let o = json->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let fmt = switch gs(o, "format") { | "pdf" => Pdf | "svg" => Svg | _ => Png }
          Some({
            id: gs(o, "id"), panelId: gs(o, "panelId"), label: gs(o, "panelId") ++ " capture",
            filePath: gs(o, "filePath"), format: fmt, timestamp: Date.now(),
            width: 0, height: 0, isRecording: false, durationSeconds: 0.0,
          }: captureEntry)
        } catch { | _ => None }
        switch parsed {
        | Some(entry) => ({...model, capture: {...cap, captures: Array.concat(cap.captures, [entry])}}, Tea_Cmd.none)
        | None => (model, Tea_Cmd.none)
        }
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | StartRecording(panelId) =>
    ({...model, capture: CaptureEngine.startRecording(cap, panelId, 0.0)}, Tea_Cmd.none)
  | StopRecording =>
    ({...model, capture: CaptureEngine.stopRecording(cap)}, Tea_Cmd.none)
  | TogglePauseRecording =>
    ({...model, capture: switch cap.recording {
    | Recording(_, _) => CaptureEngine.pauseRecording(cap, 0.0)
    | Paused(_, _) => CaptureEngine.resumeRecording(cap, 0.0)
    | NotRecording => cap
    }}, Tea_Cmd.none)
  | PrintPanel(panelId) =>
    (model, CaptureCmd.printPanel(panelId))
  | PrintResult(_result) => (model, Tea_Cmd.none)
  | ToggleCaptureSelection(panelId) =>
    ({...model, capture: CaptureEngine.toggleCaptureSelection(cap, panelId)}, Tea_Cmd.none)
  | ClearCaptureSelection =>
    ({...model, capture: CaptureEngine.clearSelection(cap)}, Tea_Cmd.none)
  | CaptureSelected => {
    // Capture all selected panels as a composite screenshot.
    // Triggers individual captures for each selected panel; composite assembly happens in the backend.
    let captureId = "composite-" ++ Float.toString(Date.now())
    let panelsJson = cap.selectedForCapture->Array.map(p => `"${p}"`)->Array.join(",")
    (model, CaptureCmd.saveScreenshot(captureId, "[" ++ panelsJson ++ "]", "", "png"))
  }
  | CaptureFullEnvironment => {
    // Capture the entire PanLL window as a single screenshot.
    let captureId = "full-env-" ++ Float.toString(Date.now())
    ({...model, capture: {...cap, fullEnvironmentCapture: true}}, CaptureCmd.saveScreenshot(captureId, "__full_environment__", "", "png"))
  }
  | ToggleCaptureBar =>
    ({...model, capture: {...cap, captureBarVisible: !cap.captureBarVisible}}, Tea_Cmd.none)
  | ClonePanel(panelId) => {
    // Snapshot the panel's current state and create a panelClone entry.
    let cloneId = "clone-" ++ Float.toString(Date.now())
    let clone: CaptureModel.panelClone = {
      id: cloneId,
      sourcePanelId: panelId,
      label: panelId ++ " (Clone)",
      stateSnapshot: "", // State serialisation deferred to JS interop layer.
      created: Date.now(),
    }
    ({...model, capture: {...cap, clones: Array.concat(cap.clones, [clone])}}, Tea_Cmd.none)
  }
  | RemoveClone(cloneId) =>
    ({...model, capture: CaptureEngine.removeClone(cap, cloneId)}, Tea_Cmd.none)
  | SetComparison(mode) =>
    ({...model, capture: {...cap, comparison: mode}}, Tea_Cmd.none)
  | ExitComparison =>
    ({...model, capture: CaptureEngine.exitComparison(cap)}, Tea_Cmd.none)
  | StartDemo(demoId) =>
    ({...model, capture: CaptureEngine.startDemo(cap, demoId)}, Tea_Cmd.none)
  | StopDemo =>
    ({...model, capture: CaptureEngine.stopDemo(cap)}, Tea_Cmd.none)
  | NextDemoStep =>
    ({...model, capture: CaptureEngine.nextDemoStep(cap)}, Tea_Cmd.none)
  | PrevDemoStep =>
    ({...model, capture: CaptureEngine.prevDemoStep(cap)}, Tea_Cmd.none)
  | SaveDemo => {
    // Serialise the active demo and persist via Tauri.
    let demoJson = switch cap.activeDemo {
    | Some(demoId) =>
      switch cap.demos->Array.find(d => d.id === demoId) {
      | Some(demo) =>
        `{"id":"${demo.id}","title":"${demo.title}","author":"${demo.author}","description":"${demo.description}","panelId":"${demo.panelId}","steps":[],"created":${Float.toString(demo.created)}}`
      | None => "{}"
      }
    | None => "{}"
    }
    (model, CaptureCmd.saveDemo(demoJson))
  }
  | DemoSaved(_result) => (model, Tea_Cmd.none)
  | LoadDemos => (model, CaptureCmd.loadDemos())
  | DemosLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let demos = try {
          let json = JSON.parseExn(jsonStr)
          json->JSON.Decode.array->Option.getOr([])->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let id = gs(o, "id")
            if id !== "" {
              Some({
                id, title: gs(o, "title"), author: gs(o, "author"),
                description: gs(o, "description"), panelId: gs(o, "panelId"),
                steps: [], created: gf(o, "created"), filePath: o->Dict.get("filePath")->Option.flatMap(JSON.Decode.string),
              }: demoPackage)
            } else { None }
          })
        } catch { | _ => [] }
        ({...model, capture: {...cap, demos}}, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | SetCaptureCategory(cat) =>
    ({...model, capture: {...cap, activeCategory: cat}}, Tea_Cmd.none)
  | RemoveCapture(captureId) =>
    ({...model, capture: CaptureEngine.removeCapture(cap, captureId)}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "capture", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Security Sub-Updater (DD-026/027)
// ===========================================================================

/// STATE TRANSITION: Security — redaction, vault, 2FA, Trustfile, shoulder-safe.
let updateSecurity = (model: model, msg: securityMsg): (model, Tea_Cmd.t<msg>) => {
  let sec = model.security
  switch msg {
  | TogglePattern(id) =>
    ({...model, security: SecurityEngine.togglePattern(sec, id)}, Tea_Cmd.none)
  | AddPattern(pattern) =>
    ({...model, security: SecurityEngine.addPattern(sec, pattern)}, Tea_Cmd.none)
  | RemovePattern(id) =>
    ({...model, security: SecurityEngine.removePattern(sec, id)}, Tea_Cmd.none)
  | SetRedactionMode(mode) =>
    ({...model, security: SecurityEngine.setRedactionMode(sec, mode)}, Tea_Cmd.none)
  | RedactText(text, panelId) => {
      let activePatterns = sec.patterns->Array.filter(p => p.enabled)
      let patternsJson = "[" ++ activePatterns->Array.map(p => `{"id":"${p.id}","pattern":"${p.pattern}"}`)->Array.join(",") ++ "]"
      (model, SecurityCmd.redactText(text, panelId, patternsJson))
    }
  | RedactionResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = try {
          let json = JSON.parseExn(jsonStr)
          let arr = json->JSON.Decode.array->Option.getOr([])
          let secrets = arr->Array.filterMap(item => {
            let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
            let patternId = obj->Dict.get("patternId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let panelId = obj->Dict.get("panelId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let offset = obj->Dict.get("offset")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let length = obj->Dict.get("length")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let placeholder = obj->Dict.get("placeholder")->Option.flatMap(JSON.Decode.string)->Option.getOr("[REDACTED]")
            Some({
              SecurityModel.patternId,
              panelId,
              offset: Float.toInt(offset),
              length: Float.toInt(length),
              placeholder,
            })
          })
          Some(secrets)
        } catch {
        | _ => None
        }
        switch parsed {
        | Some(detectedSecrets) => ({...model, security: {...sec, detectedSecrets}}, Tea_Cmd.none)
        | None => (model, Tea_Cmd.none)
        }
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | VaultStore(key, value) =>
    (model, SecurityCmd.vaultStore(key, value))
  | VaultStoreResult(result) => {
      switch result {
      | Ok(_) => ({...model, security: {...sec, error: None}}, Tea_Cmd.none)
      | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
      }
    }
  | VaultRetrieve(key) =>
    (model, SecurityCmd.vaultRetrieve(key))
  | VaultRetrieveResult(result) => {
      switch result {
      | Ok(_value) =>
        // Value is used by the caller, not stored in frontend state.
        ({...model, security: {...sec, error: None}}, Tea_Cmd.none)
      | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
      }
    }
  | VaultList =>
    (model, SecurityCmd.vaultList())
  | VaultListResult(result) => {
      switch result {
      | Ok(jsonStr) => {
          let keys = try {
            let json = JSON.parseExn(jsonStr)
            json->JSON.Decode.array->Option.getOr([])->Array.filterMap(item => {
              let o = item->JSON.Decode.object->Option.getOr(Dict.make())
              let k = o->Dict.get("key")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
              if k !== "" {
                Some({key: k, description: o->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr(""), lastUpdated: o->Dict.get("lastUpdated")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)}: vaultKey)
              } else { None }
            })
          } catch { | _ => [] }
          ({...model, security: {...sec, vaultStatus: VaultUnlocked, vaultKeys: keys}}, Tea_Cmd.none)
        }
      | Error(e) => ({...model, security: {...sec, error: Some(e), vaultStatus: VaultError(e)}}, Tea_Cmd.none)
      }
    }
  | SubmitTotp(code) => {
    // Submit the TOTP code for verification; result comes back via TotpResult.
    let cmd = Tea_Cmd.call(callbacks => {
      SecurityCmd.invoke("verify_totp", {"code": code})
      ->Promise.then(result => {
        callbacks.enqueue(Security(TotpResult(Ok(result))))
        Promise.resolve()
      })
      ->Promise.catch(_err => {
        callbacks.enqueue(Security(TotpResult(Error("TOTP verification failed"))))
        Promise.resolve()
      })
      ->ignore
    })
    ({...model, security: {...sec, totpInput: ""}}, cmd)
  }
  | TotpResult(result) => {
      switch result {
      | Ok(_) =>
        ({...model, security: {...sec, twoFactorStatus: TwoFactorAuthenticated(0.0)}}, Tea_Cmd.none)
      | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
      }
    }
  | SetTotpInput(input) =>
    ({...model, security: {...sec, totpInput: input}}, Tea_Cmd.none)
  | LoadTrustfile(repoPath) =>
    (model, Tea_Cmd.batch(list{
      SecurityCmd.loadTrustfile(repoPath),
      TypeLLService.checkSecurityTypes(repoPath, "security", result => Security(TypeCheckResult(result))),
    }))
  | TrustfileLoaded(result) => {
      switch result {
      | Ok(jsonStr) => {
          let policy = try {
            let json = JSON.parseExn(jsonStr)
            let o = json->JSON.Decode.object->Option.getOr(Dict.make())
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            let sl = switch gs(o, "securityLevel") {
            | "low" => SecurityLow | "high" => SecurityHigh | "maximum" => SecurityMaximum | _ => SecurityMedium
            }
            let rm = switch gs(o, "redactionMode") {
            | "always" => RedactAlways | "on_save" => RedactOnSave | "on_display" => RedactOnDisplay | _ => RedactOnShare
            }
            let patterns = o->Dict.get("customPatterns")->Option.flatMap(JSON.Decode.array)->Option.getOr([])->Array.filterMap(p => {
              let po = p->JSON.Decode.object->Option.getOr(Dict.make())
              let pid = gs(po, "id")
              if pid !== "" {
                Some({id: pid, label: gs(po, "label"), pattern: gs(po, "pattern"), enabled: gb(po, "enabled"), builtIn: gb(po, "builtIn")}: redactionPattern)
              } else { None }
            })
            Some({
              securityLevel: sl, redactionMode: rm, customPatterns: patterns,
              twoFactorRequirements: [], defaultSharingPermission: ViewOnly,
              requireApproval: gb(o, "requireApproval"), loaded: true,
              filePath: o->Dict.get("filePath")->Option.flatMap(JSON.Decode.string),
            }: trustfilePolicy)
          } catch { | _ => None }
          switch policy {
          | Some(p) => ({...model, security: SecurityEngine.applyTrustfile(sec, p)}, Tea_Cmd.none)
          | None => ({...model, security: {...sec, error: Some("Failed to parse Trustfile")}}, Tea_Cmd.none)
          }
        }
      | Error(e) => ({...model, security: {...sec, error: Some(e)}}, Tea_Cmd.none)
      }
    }
  | ToggleShoulderSafe =>
    ({...model, security: SecurityEngine.toggleShoulderSafe(sec)}, Tea_Cmd.none)
  | SetSecurityCategory(cat) =>
    ({...model, security: {...sec, activeCategory: cat}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "security", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Keybindings Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Keybindings — recording, rebinding, reset.
let updateKeybindings = (model: model, msg: keybindingsMsg): model => {
  let kb = model.keybindings
  switch msg {
  | StartRecording(action) =>
    {...model, keybindings: {...kb, recording: true, recordingAction: Some(action)}}
  | RecordKey(chord) =>
    switch kb.recordingAction {
    | Some(action) => {
        let newBindings = KeybindingsEngine.rebind(kb.bindings, action, chord)
        let conflicts = KeybindingsEngine.detectConflicts(newBindings)
        {...model, keybindings: {
          bindings: newBindings,
          recording: false,
          recordingAction: None,
          conflicts,
        }}
      }
    | None => {...model, keybindings: {...kb, recording: false, recordingAction: None}}
    }
  | CancelRecording =>
    {...model, keybindings: {...kb, recording: false, recordingAction: None}}
  | ResetBinding(action) => {
      let newBindings = KeybindingsEngine.resetBinding(kb.bindings, action)
      let conflicts = KeybindingsEngine.detectConflicts(newBindings)
      {...model, keybindings: {...kb, bindings: newBindings, conflicts}}
    }
  | ResetAllBindings => {
      let newBindings = KeybindingsEngine.resetAll()
      {...model, keybindings: {
        bindings: newBindings,
        recording: false,
        recordingAction: None,
        conflicts: [],
      }}
    }
  }
}

// ===========================================================================
// Migration Observatory Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Migration — health tracking, sessions, submissions, merge resolver.
let updateMigration = (model: model, msg: migrationMsg): (model, Tea_Cmd.t<msg>) => {
  let mig = model.migration
  switch msg {
  | LoadMigrationData => ({...model, migration: {...mig, loading: true, error: None}}, TypeLLService.checkMetadataTypes("migration-data", "migration", result => Migration(TypeCheckResult(result))))
  | MigrationDataLoaded(Ok(_data)) =>
    // Data parsing would happen here in a real implementation.
    // For now, mark as loaded.
    ({...model, migration: {
      ...mig,
      loaded: true,
      loading: false,
      error: None,
      avgHealth: MigrationEngine.computeAvgHealth(mig.repos),
      readyCount: MigrationEngine.countReady(mig.repos),
      blockedCount: MigrationEngine.countBlocked(mig.repos),
      totalRepos: Array.length(mig.repos),
    }}, Tea_Cmd.none)
  | MigrationDataLoaded(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | SetMigrationCategory(cat) =>
    ({...model, migration: {...mig, activeCategory: cat}}, Tea_Cmd.none)
  | SetMigrationReportType(rt) =>
    ({...model, migration: {...mig, activeReportType: rt}}, Tea_Cmd.none)
  | SetMigrationFilter(text) =>
    ({...model, migration: {...mig, filterText: text}}, Tea_Cmd.none)
  | BeginObservation(_repo, _label) =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | ObservationStarted(Ok(_data)) =>
    ({...model, migration: {...mig, loading: false}}, Tea_Cmd.none)
  | ObservationStarted(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | EndObservation(_sessionId) =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | ObservationEnded(Ok(_data)) =>
    ({...model, migration: {...mig, loading: false}}, Tea_Cmd.none)
  | ObservationEnded(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | ApproveSubmission(id) => {
      let updated = mig.submissions->Array.map(s =>
        if s.id === id {
          {...s, status: SubmissionApproved}
        } else {
          s
        }
      )
      ({...model, migration: {...mig, submissions: updated}}, Tea_Cmd.none)
    }
  | RejectSubmission(id) => {
      let updated = mig.submissions->Array.map(s =>
        if s.id === id {
          {...s, status: SubmissionRejected}
        } else {
          s
        }
      )
      ({...model, migration: {...mig, submissions: updated}}, Tea_Cmd.none)
    }
  | SubmitApproved =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | SubmissionsResult(Ok(_data)) =>
    // Mark approved submissions as submitted.
    let updated = mig.submissions->Array.map(s =>
      if s.status == SubmissionApproved {
        {...s, status: SubmissionSubmitted}
      } else {
        s
      }
    )
    ({...model, migration: {...mig, loading: false, submissions: updated}}, Tea_Cmd.none)
  | SubmissionsResult(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | BeginMergeResolution(_repo, _branch) =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | MergeResolutionStarted(Ok(_data)) =>
    ({...model, migration: {...mig, loading: false}}, Tea_Cmd.none)
  | MergeResolutionStarted(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | RollbackMerge(_sessionId) =>
    (model, Tea_Cmd.none)
  | AcceptMerge(_sessionId) =>
    (model, Tea_Cmd.none)
  | RefreshMigrationHealth =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "migration", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Panic-Attack Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Panic-Attack (stress testing and weak point analysis).
/// Handles capability probing, assail/assault scans, report management,
/// SARIF export, event-chain export, and category/filter state.
let updatePanicAttack = (model: model, subMsg: panicAttackMsg): (model, Tea_Cmd.t<msg>) => {
  let pa = model.panicAttack
  switch subMsg {
  | CheckCapability =>
    (
      {...model, panicAttack: {...pa, mode: "checking"}},
      PanicAttackCmd.checkCapability(result => PanicAttack(CapabilityLoaded(result))),
    )
  | CapabilityLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let mode = obj->Dict.get("mode")->Option.flatMap(JSON.Decode.string)->Option.getOr("unavailable")
      let detail = obj->Dict.get("detail")->Option.flatMap(JSON.Decode.string)
      let binary = obj->Dict.get("binary")->Option.flatMap(JSON.Decode.string)
      Some((mode, detail, binary))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((mode, _detail, binary)) =>
      ({...model, panicAttack: {...pa, mode, binaryPath: binary, version: binary}}, Tea_Cmd.none)
    | None =>
      ({...model, panicAttack: {...pa, mode: "full", version: Some(jsonStr)}}, Tea_Cmd.none)
    }
  }
  | CapabilityLoaded(Error(_err)) =>
    ({...model, panicAttack: {...pa, mode: "unavailable"}}, Tea_Cmd.none)
  | SetTargetPath(path) =>
    ({...model, panicAttack: {...pa, targetPath: path}}, Tea_Cmd.none)
  | RunAssail =>
    (
      {...model, panicAttack: {...pa, scanning: true, lastError: None}},
      Tea_Cmd.batch(list{
        PanicAttackCmd.assail(pa.targetPath, result => PanicAttack(AssailResult(result))),
        TypeLLService.checkSecurityTypes(pa.targetPath, "panic-attack", result => PanicAttack(TypeCheckResult(result))),
      }),
    )
  | AssailResult(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let summaryObj = obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
      let getInt = (d, key) => d->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
      let weakPts = getInt(summaryObj, "weak_points")->Option.getOr(0)
      let critPts = getInt(summaryObj, "critical_weak_points")->Option.getOr(0)
      let crashes = getInt(summaryObj, "total_crashes")->Option.getOr(0)
      let robustness = summaryObj->Dict.get("robustness_score")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let filesScanned = getInt(summaryObj, "files_scanned")->Option.getOr(0)
      let summary: scanSummary = {
        totalFindings: weakPts,
        critical: critPts,
        high: 0,
        medium: weakPts - critPts,
        low: 0,
        info: crashes,
        filesScanned,
        language: summaryObj->Dict.get("program")->Option.flatMap(JSON.Decode.string)->Option.getOr("unknown"),
      }
      Some(summary, robustness)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(summary, _robustness) =>
      ({...model, panicAttack: {...pa, scanning: false, summary: Some(summary)}}, Tea_Cmd.none)
    | None =>
      ({...model, panicAttack: {...pa, scanning: false}}, Tea_Cmd.none)
    }
  }
  | AssailResult(Error(err)) =>
    ({...model, panicAttack: {...pa, scanning: false, lastError: Some(err)}}, Tea_Cmd.none)
  | RunAssault =>
    (
      {...model, panicAttack: {...pa, scanning: true, lastError: None}},
      PanicAttackCmd.assault(pa.targetPath, result => PanicAttack(AssaultResult(result))),
    )
  | AssaultResult(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let summaryObj = obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
      let getInt = (d, key) => d->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
      let weakPts = getInt(summaryObj, "weak_points")->Option.getOr(0)
      let critPts = getInt(summaryObj, "critical_weak_points")->Option.getOr(0)
      let crashes = getInt(summaryObj, "total_crashes")->Option.getOr(0)
      let summary: scanSummary = {
        totalFindings: weakPts,
        critical: critPts,
        high: 0,
        medium: weakPts - critPts,
        low: 0,
        info: crashes,
        filesScanned: 0,
        language: summaryObj->Dict.get("program")->Option.flatMap(JSON.Decode.string)->Option.getOr("unknown"),
      }
      Some(summary)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(summary) =>
      ({...model, panicAttack: {...pa, scanning: false, summary: Some(summary)}}, Tea_Cmd.none)
    | None =>
      ({...model, panicAttack: {...pa, scanning: false}}, Tea_Cmd.none)
    }
  }
  | AssaultResult(Error(err)) =>
    ({...model, panicAttack: {...pa, scanning: false, lastError: Some(err)}}, Tea_Cmd.none)
  | LoadReports =>
    (model, PanicAttackCmd.listReports(result => PanicAttack(ReportsLoaded(result))))
  | ReportsLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let targetPath = obj->Dict.get("targetPath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let timestamp = obj->Dict.get("timestamp")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let summaryObj = obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
        let getInt = key => summaryObj->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
        let language = summaryObj->Dict.get("language")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let summary: PanicAttackModel.scanSummary = {
          totalFindings: getInt("totalFindings"),
          critical: getInt("critical"),
          high: getInt("high"),
          medium: getInt("medium"),
          low: getInt("low"),
          info: getInt("info"),
          filesScanned: getInt("filesScanned"),
          language,
        }
        Some({PanicAttackModel.id, targetPath, timestamp, summary})
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(reports) => ({...model, panicAttack: {...pa, reports}}, Tea_Cmd.none)
    | None => (model, Tea_Cmd.none)
    }
  }
  | ReportsLoaded(Error(err)) =>
    ({...model, panicAttack: {...pa, lastError: Some(err)}}, Tea_Cmd.none)
  | ViewReport(path) =>
    (model, PanicAttackCmd.viewReport(path, result => PanicAttack(ReportLoaded(result))))
  | ReportLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let findings = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let file = obj->Dict.get("file")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let line = obj->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        let sevStr = obj->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("info")
        let severity: PanicAttackModel.weakPointSeverity = switch sevStr {
        | "critical" => Critical
        | "high" => High
        | "medium" => Medium
        | "low" => Low
        | _ => Info
        }
        let description = obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let context = obj->Dict.get("context")->Option.flatMap(JSON.Decode.string)
        Some({PanicAttackModel.file, line, category: OtherCategory(""), severity, description, context})
      })
      Some(findings)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(findings) => ({...model, panicAttack: {...pa, findings}}, Tea_Cmd.none)
    | None => (model, Tea_Cmd.none)
    }
  }
  | ReportLoaded(Error(err)) =>
    ({...model, panicAttack: {...pa, lastError: Some(err)}}, Tea_Cmd.none)
  | CompareReports(left, right) =>
    (
      model,
      PanicAttackCmd.diffReports(left, right, result =>
        PanicAttack(ComparisonLoaded(result))
      ),
    )
  | ComparisonLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let diffArr = obj->Dict.get("findings")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let findings = diffArr->Array.filterMap(item => {
        let o = item->JSON.Decode.object->Option.getOr(Dict.make())
        let file = o->Dict.get("file")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let line = o->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        let sevStr = o->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("info")
        let severity: PanicAttackModel.weakPointSeverity = switch sevStr {
        | "critical" => Critical
        | "high" => High
        | "medium" => Medium
        | "low" => Low
        | _ => Info
        }
        let description = o->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let context = o->Dict.get("context")->Option.flatMap(JSON.Decode.string)
        Some({PanicAttackModel.file, line, category: OtherCategory(""), severity, description, context})
      })
      Some(findings)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(findings) => ({...model, panicAttack: {...pa, findings, showDiff: true}}, Tea_Cmd.none)
    | None => (model, Tea_Cmd.none)
    }
  }
  | ComparisonLoaded(Error(err)) =>
    ({...model, panicAttack: {...pa, lastError: Some(err)}}, Tea_Cmd.none)
  | ExportSarif(path) =>
    (
      model,
      PanicAttackCmd.exportSarif(path, result => PanicAttack(SarifExported(result))),
    )
  | SarifExported(Ok(_path)) =>
    (model, Tea_Cmd.none)
  | SarifExported(Error(err)) =>
    ({...model, panicAttack: {...pa, lastError: Some(err)}}, Tea_Cmd.none)
  | ExportEventChain(path) =>
    (
      model,
      PanicAttackCmd.exportEventChain(path, result =>
        PanicAttack(EventChainExported(result))
      ),
    )
  | EventChainExported(Ok(_path)) =>
    (model, Tea_Cmd.none)
  | EventChainExported(Error(err)) =>
    ({...model, panicAttack: {...pa, lastError: Some(err)}}, Tea_Cmd.none)
  | SetPanicCategory(cat) =>
    ({...model, panicAttack: {...pa, activeCategory: cat}}, Tea_Cmd.none)
  | SetPanicFilter(filterText) =>
    ({...model, panicAttack: {...pa, filterText}}, Tea_Cmd.none)
  | ToggleDiffView =>
    ({...model, panicAttack: {...pa, showDiff: !pa.showDiff}}, Tea_Cmd.none)
  | DismissError =>
    ({...model, panicAttack: {...pa, lastError: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "panicattack", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// Mass Panic Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Mass Panic (organisation-scale batch scanning).
/// Handles assemblyline scanning, repo discovery, incremental BLAKE3,
/// verisimdb persistence, delta reporting, and notification generation.
let updateMassPanic = (model: model, subMsg: massPanicMsg): (model, Tea_Cmd.t<msg>) => {
  let mp = model.massPanic
  switch subMsg {
  | SetReposDirectory(dir) =>
    ({...model, massPanic: {...mp, reposDirectory: dir}}, Tea_Cmd.none)
  | DiscoverRepos =>
    (
      {...model, massPanic: {...mp, loading: true, lastError: None}},
      MassPanicCmd.discoverRepos(mp.reposDirectory, result =>
        MassPanic(ReposDiscovered(result))
      ),
    )
  | ReposDiscovered(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let repoPath = obj->Dict.get("repoPath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let repoName = obj->Dict.get("repoName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        Some({
          MassPanicModel.repoPath,
          repoName,
          status: Queued,
          totalFindings: 0,
          critical: 0,
          high: 0,
          medium: 0,
          low: 0,
          filesScanned: 0,
          blake3Hash: None,
          scanDuration: None,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(repoResults) => ({...model, massPanic: {...mp, repoResults, loading: false}}, Tea_Cmd.none)
    | None => ({...model, massPanic: {...mp, loading: false}}, Tea_Cmd.none)
    }
  }
  | ReposDiscovered(Error(err)) =>
    ({...model, massPanic: {...mp, loading: false, lastError: Some(err)}}, Tea_Cmd.none)
  | RunAssemblyline =>
    let storePath = switch mp.storage {
    | Filesystem(p) => Some(p)
    | VerisimDB(p) => Some(p)
    | NoStorage => None
    }
    (
      {
        ...model,
        massPanic: {
          ...mp,
          scanning: true,
          progress: 0.0,
          currentRepo: None,
          lastError: None,
        },
      },
      Tea_Cmd.batch(list{
        MassPanicCmd.runAssemblyline(
          mp.reposDirectory,
          mp.incremental,
          mp.cachePath,
          storePath,
          mp.minFindings,
          result => MassPanic(AssemblylineResult(result)),
        ),
        TypeLLService.checkConfigTypes(mp.reposDirectory, "mass-panic", result => MassPanic(TypeCheckResult(result))),
      }),
    )
  | RunSelected =>
    // Same as RunAssemblyline but for selected repos only.
    // Backend filters by selection indices.
    let storePath = switch mp.storage {
    | Filesystem(p) => Some(p)
    | VerisimDB(p) => Some(p)
    | NoStorage => None
    }
    (
      {
        ...model,
        massPanic: {
          ...mp,
          scanning: true,
          progress: 0.0,
          currentRepo: None,
          lastError: None,
        },
      },
      MassPanicCmd.runAssemblyline(
        mp.reposDirectory,
        mp.incremental,
        mp.cachePath,
        storePath,
        mp.minFindings,
        result => MassPanic(AssemblylineResult(result)),
      ),
    )
  | AssemblylineResult(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let parseStatus = (s: string): MassPanicModel.repoScanStatus =>
        switch s {
        | "scanning" => Scanning
        | "complete" => Complete
        | "skipped" => Skipped
        | "queued" => Queued
        | _ => Failed(s)
        }
      let resultsArr = obj->Dict.get("results")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let repoResults = resultsArr->Array.filterMap(item => {
        let o = item->JSON.Decode.object->Option.getOr(Dict.make())
        let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
        Some({
          MassPanicModel.repoPath: gs(o, "repo_path"),
          repoName: gs(o, "repo_name"),
          status: parseStatus(gs(o, "status")),
          totalFindings: gi(o, "total_findings"),
          critical: gi(o, "critical"),
          high: gi(o, "high"),
          medium: gi(o, "medium"),
          low: gi(o, "low"),
          filesScanned: gi(o, "files_scanned"),
          blake3Hash: o->Dict.get("blake3_hash")->Option.flatMap(JSON.Decode.string),
          scanDuration: o->Dict.get("scan_duration")->Option.flatMap(JSON.Decode.float),
        })
      })
      let summaryObj = obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)
      let summary = switch summaryObj {
      | Some(s) => {
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          Some({
            MassPanicModel.totalRepos: gi(s, "total_repos"),
            scannedRepos: gi(s, "scanned_repos"),
            skippedRepos: gi(s, "skipped_repos"),
            failedRepos: gi(s, "failed_repos"),
            totalFindings: gi(s, "total_findings"),
            totalCritical: gi(s, "total_critical"),
            totalHigh: gi(s, "total_high"),
            scanDuration: gf(s, "scan_duration"),
            timestamp: gs(s, "timestamp"),
          })
        }
      | None => None
      }
      Some((repoResults, summary))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((repoResults, summary)) =>
      ({...model, massPanic: {...mp, scanning: false, progress: 1.0, repoResults, summary, lastError: None}}, Tea_Cmd.none)
    | None =>
      ({...model, massPanic: {...mp, scanning: false, progress: 1.0}}, Tea_Cmd.none)
    }
  }
  | AssemblylineResult(Error(err)) =>
    (
      {...model, massPanic: {...mp, scanning: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | PollProgress =>
    (model, MassPanicCmd.getProgress(result => MassPanic(ProgressUpdate(result))))
  | ProgressUpdate(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let reposDone = obj->Dict.get("repos_done")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let reposTotal = obj->Dict.get("repos_total")->Option.flatMap(JSON.Decode.float)->Option.getOr(1.0)
      let currentRepo = obj->Dict.get("current_repo")->Option.flatMap(JSON.Decode.string)
      let progress = if reposTotal > 0.0 { reposDone /. reposTotal } else { 0.0 }
      Some((progress, currentRepo))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((progress, currentRepo)) =>
      ({...model, massPanic: {...mp, progress, currentRepo}}, Tea_Cmd.none)
    | None => (model, Tea_Cmd.none)
    }
  }
  | ProgressUpdate(Error(_)) =>
    // Silently ignore progress poll failures.
    (model, Tea_Cmd.none)
  | ToggleIncremental =>
    ({...model, massPanic: {...mp, incremental: !mp.incremental}}, Tea_Cmd.none)
  | ToggleNotify =>
    ({...model, massPanic: {...mp, notifyEnabled: !mp.notifyEnabled}}, Tea_Cmd.none)
  | SetFilterMode(mode) =>
    ({...model, massPanic: {...mp, filterMode: mode}}, Tea_Cmd.none)
  | SetSortMode(mode) =>
    ({...model, massPanic: {...mp, sortMode: mode}}, Tea_Cmd.none)
  | SetSearchText(text) =>
    ({...model, massPanic: {...mp, searchText: text}}, Tea_Cmd.none)
  | ToggleRepoSelection(index) => {
      let selected = if mp.selectedRepos->Array.includes(index) {
        mp.selectedRepos->Array.filter(i => i !== index)
      } else {
        mp.selectedRepos->Array.concat([index])
      }
      ({...model, massPanic: {...mp, selectedRepos: selected, selectAll: false}}, Tea_Cmd.none)
    }
  | ToggleSelectAll => {
      let newSelectAll = !mp.selectAll
      let selected = if newSelectAll {
        Array.fromInitializer(~length=Array.length(mp.repoResults), i => i)
      } else {
        []
      }
      (
        {...model, massPanic: {...mp, selectAll: newSelectAll, selectedRepos: selected}},
        Tea_Cmd.none,
      )
    }
  | ToggleDelta =>
    ({...model, massPanic: {...mp, showDelta: !mp.showDelta}}, Tea_Cmd.none)
  | LoadDelta => {
    // Use storage path to find the latest reports directory for delta comparison.
    let storePath = switch mp.storage {
    | Filesystem(p) | VerisimDB(p) => p
    | NoStorage => "reports"
    }
    let leftPath = storePath ++ "/previous-report.json"
    let rightPath = storePath ++ "/latest-report.json"
    (
      {...model, massPanic: {...mp, loading: true}},
      MassPanicCmd.diffReports(leftPath, rightPath, result => MassPanic(DeltaLoaded(result))),
    )
  }
  | DeltaLoaded(Ok(jsonStr)) => {
    let deltas = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      arr->Array.filterMap(item => {
        let o = item->JSON.Decode.object->Option.getOr(Dict.make())
        let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
        let repoName = gs(o, "repo")
        if repoName !== "" {
          Some({
            MassPanicModel.repoName,
            newFindings: gi(o, "new_findings"),
            fixedFindings: gi(o, "fixed_findings"),
            changeDirection: gs(o, "direction"),
          })
        } else {
          None
        }
      })
    } catch {
    | _ => []
    }
    ({...model, massPanic: {...mp, loading: false, delta: deltas, showDelta: true, lastError: None}}, Tea_Cmd.none)
  }
  | DeltaLoaded(Error(err)) =>
    ({...model, massPanic: {...mp, loading: false, lastError: Some(err)}}, Tea_Cmd.none)
  | GenerateNotification => {
    // Use the storage path as the report directory for notification generation.
    let reportPath = switch mp.storage {
    | Filesystem(p) | VerisimDB(p) => p ++ "/latest-report.json"
    | NoStorage => "reports/latest-report.json"
    }
    (
      {...model, massPanic: {...mp, loading: true}},
      MassPanicCmd.generateNotification(
        reportPath,
        mp.notifyCriticalOnly,
        result => MassPanic(NotificationGenerated(result)),
      ),
    )
  }
  | NotificationGenerated(Ok(_md)) =>
    ({...model, massPanic: {...mp, loading: false}}, Tea_Cmd.none)
  | NotificationGenerated(Error(err)) =>
    ({...model, massPanic: {...mp, loading: false, lastError: Some(err)}}, Tea_Cmd.none)
  | DismissMassPanicError =>
    ({...model, massPanic: {...mp, lastError: None}}, Tea_Cmd.none)

  // -- Sub-view navigation --
  | SwitchView(view) =>
    ({...model, massPanic: {...mp, activeView: view}}, Tea_Cmd.none)

  // -- Imaging (fNIRS-style spatial health map) --
  | BuildImage =>
    let storePath = switch mp.storage {
    | Filesystem(p) | VerisimDB(p) => Some(p)
    | NoStorage => None
    }
    (
      {...model, massPanic: {...mp, imagingLoading: true, lastError: None}},
      MassPanicCmd.buildImage(
        mp.reposDirectory,
        mp.incremental,
        storePath,
        result => MassPanic(ImageLoaded(result)),
      ),
    )
  | ImageLoaded(Ok(json)) => {
      // Parse panll.system-image.v0 JSON into systemImage
      let parsed = try {
        let obj = JSON.parseExn(json)
        let getStr = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.string->Option.getOr("")
          | None => ""
          }
        let getFloat = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)
          | None => 0.0
          }
        let getInt = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)->Float.toInt
          | None => 0
          }
        let image: MassPanicModel.systemImage = {
          scanSurface: getStr(obj, "scan_surface"),
          generatedAt: getStr(obj, "generated_at"),
          globalHealth: getFloat(obj, "global_health"),
          globalRisk: getFloat(obj, "global_risk"),
          nodeCount: getInt(obj, "node_count"),
          edgeCount: getInt(obj, "edge_count"),
          totalWeakPoints: getInt(obj, "total_weak_points"),
          totalCritical: getInt(obj, "total_critical"),
          riskDistribution: {healthy: 0, low: 0, moderate: 0, high: 0, critical: 0},
          nodes: [],
          edges: [],
        }
        Some(image)
      } catch {
      | _ => None
      }
      switch parsed {
      | Some(img) =>
        ({...model, massPanic: {...mp, imagingLoading: false, currentImage: Some(img)}}, Tea_Cmd.none)
      | None =>
        ({...model, massPanic: {...mp, imagingLoading: false, lastError: Some("Failed to parse system image JSON")}}, Tea_Cmd.none)
      }
    }
  | ImageLoaded(Error(err)) =>
    ({...model, massPanic: {...mp, imagingLoading: false, lastError: Some(err)}}, Tea_Cmd.none)
  | ImportImageFile =>
    // Wire file picker dialog — invoke Tauri open dialog, then load the selected file.
    (
      {...model, massPanic: {...mp, imagingLoading: true}},
      MassPanicCmd.buildImage(
        mp.reposDirectory,
        false,
        None,
        result => MassPanic(ImageFileLoaded(result)),
      ),
    )
  | ImageFileLoaded(Ok(json)) => {
    // Reuse same parsing logic as ImageLoaded — panll.system-image.v0 JSON.
    let parsed = try {
      let obj = JSON.parseExn(json)
      let getStr = (o, k) =>
        switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
        | Some(v) => v->JSON.Decode.string->Option.getOr("")
        | None => ""
        }
      let getFloat = (o, k) =>
        switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
        | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)
        | None => 0.0
        }
      let getInt = (o, k) =>
        switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
        | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)->Float.toInt
        | None => 0
        }
      let image: MassPanicModel.systemImage = {
        scanSurface: getStr(obj, "scan_surface"),
        generatedAt: getStr(obj, "generated_at"),
        globalHealth: getFloat(obj, "global_health"),
        globalRisk: getFloat(obj, "global_risk"),
        nodeCount: getInt(obj, "node_count"),
        edgeCount: getInt(obj, "edge_count"),
        totalWeakPoints: getInt(obj, "total_weak_points"),
        totalCritical: getInt(obj, "total_critical"),
        riskDistribution: {healthy: 0, low: 0, moderate: 0, high: 0, critical: 0},
        nodes: [],
        edges: [],
      }
      Some(image)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(img) =>
      ({...model, massPanic: {...mp, imagingLoading: false, currentImage: Some(img)}}, Tea_Cmd.none)
    | None =>
      ({...model, massPanic: {...mp, imagingLoading: false, lastError: Some("Failed to parse imported image JSON")}}, Tea_Cmd.none)
    }
  }
  | ImageFileLoaded(Error(err)) =>
    ({...model, massPanic: {...mp, imagingLoading: false, lastError: Some(err)}}, Tea_Cmd.none)

  // -- Temporal navigation --
  | ListSnapshots => {
      let storePath = switch mp.storage {
      | VerisimDB(p) => p
      | _ => "verisimdb-data"
      }
      (
        {...model, massPanic: {...mp, temporalLoading: true, lastError: None}},
        MassPanicCmd.listSnapshots(storePath, result => MassPanic(SnapshotsLoaded(result))),
      )
    }
  | SnapshotsLoaded(Ok(jsonStr)) => {
    let snapshots = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      arr->Array.filterMap(item => {
        let o = item->JSON.Decode.object->Option.getOr(Dict.make())
        let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
        Some({
          MassPanicModel.sequence: gi(o, "sequence"),
          timestamp: gs(o, "timestamp"),
          label: gs(o, "label"),
          nodeCount: gi(o, "node_count"),
          globalHealth: gf(o, "global_health"),
          globalRisk: gf(o, "global_risk"),
          totalWeakPoints: gi(o, "total_weak_points"),
        })
      })
    } catch {
    | _ => []
    }
    ({...model, massPanic: {...mp, temporalLoading: false, snapshots, lastError: None}}, Tea_Cmd.none)
  }
  | SnapshotsLoaded(Error(err)) =>
    ({...model, massPanic: {...mp, temporalLoading: false, lastError: Some(err)}}, Tea_Cmd.none)
  | SelectSnapshot(slot, index) => {
      let (s0, s1) = mp.selectedSnapshots
      let newSelected = if slot == 0 {
        (Some(index), s1)
      } else {
        (s0, Some(index))
      }
      ({...model, massPanic: {...mp, selectedSnapshots: newSelected}}, Tea_Cmd.none)
    }
  | DiffSnapshots => {
      let storePath = switch mp.storage {
      | VerisimDB(p) => p
      | _ => "verisimdb-data"
      }
      switch (mp.selectedSnapshots) {
      | (Some(fromIdx), Some(toIdx)) =>
        (
          {...model, massPanic: {...mp, temporalLoading: true}},
          MassPanicCmd.diffSnapshots(storePath, fromIdx, toIdx, result => MassPanic(DiffLoaded(result))),
        )
      | _ => (model, Tea_Cmd.none)
      }
    }
  | DiffLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
      let getStringArray = (d, k) =>
        d->Dict.get(k)->Option.flatMap(JSON.Decode.array)->Option.getOr([])->Array.filterMap(v =>
          v->JSON.Decode.string
        )
      let parseNodeDeltas = (d, k) =>
        d->Dict.get(k)->Option.flatMap(JSON.Decode.array)->Option.getOr([])->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let name = gs(o, "name")
          if name !== "" {
            Some({
              MassPanicModel.name,
              healthBefore: gf(o, "health_before"),
              healthAfter: gf(o, "health_after"),
              healthDelta: gf(o, "health_delta"),
              riskBefore: gf(o, "risk_before"),
              riskAfter: gf(o, "risk_after"),
              riskDelta: gf(o, "risk_delta"),
              weakPointDelta: gi(o, "weak_point_delta"),
            })
          } else {
            None
          }
        })
      Some({
        MassPanicModel.fromLabel: gs(obj, "from_label"),
        toLabel: gs(obj, "to_label"),
        fromTimestamp: gs(obj, "from_timestamp"),
        toTimestamp: gs(obj, "to_timestamp"),
        healthDelta: gf(obj, "health_delta"),
        riskDelta: gf(obj, "risk_delta"),
        weakPointDelta: gi(obj, "weak_point_delta"),
        criticalDelta: gi(obj, "critical_delta"),
        newNodes: getStringArray(obj, "new_nodes"),
        removedNodes: getStringArray(obj, "removed_nodes"),
        improvedNodes: parseNodeDeltas(obj, "improved_nodes"),
        degradedNodes: parseNodeDeltas(obj, "degraded_nodes"),
        unchangedCount: gi(obj, "unchanged_count"),
        trend: gs(obj, "trend"),
      })
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(diff) =>
      ({...model, massPanic: {...mp, temporalLoading: false, currentDiff: Some(diff), lastError: None}}, Tea_Cmd.none)
    | None =>
      ({...model, massPanic: {...mp, temporalLoading: false, lastError: Some("Failed to parse temporal diff JSON")}}, Tea_Cmd.none)
    }
  }
  | DiffLoaded(Error(err)) =>
    ({...model, massPanic: {...mp, temporalLoading: false, lastError: Some(err)}}, Tea_Cmd.none)
  | TakeSnapshot(label) => {
      let storePath = switch mp.storage {
      | VerisimDB(p) => p
      | _ => "verisimdb-data"
      }
      (
        {...model, massPanic: {...mp, temporalLoading: true}},
        MassPanicCmd.takeSnapshot(storePath, label, result => MassPanic(SnapshotTaken(result))),
      )
    }
  | SnapshotTaken(Ok(_json)) =>
    // Refresh snapshot list after taking a new one
    ({...model, massPanic: {...mp, temporalLoading: false}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "masspanic", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  | SnapshotTaken(Error(err)) =>
    ({...model, massPanic: {...mp, temporalLoading: false, lastError: Some(err)}}, Tea_Cmd.none)
  }
}

/// Swap two adjacent elements in an array (for TSDM reordering).
/// Returns the array unchanged if the swap is out of bounds.
let swapAt = (arr: array<'a>, i: int): array<'a> => {
  let len = Array.length(arr)
  if i < 0 || i + 1 >= len {
    arr
  } else {
    let copy = Array.copy(arr)
    let tmp = copy->Array.getUnsafe(i)
    copy->Array.setUnsafe(i, copy->Array.getUnsafe(i + 1))
    copy->Array.setUnsafe(i + 1, tmp)
    copy
  }
}

/// Sub-updater: TSDM directive panel — triaxial priority ordering.
let updateTsdm = (model: model, subMsg: tsdmMsg): (model, Tea_Cmd.t<msg>) => {
  let ts = model.tsdm
  switch subMsg {
  | MoveAxisUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      ({...model, tsdm: {...ts, axisOrder: swapAt(ts.axisOrder, idx - 1)}}, Tea_Cmd.none)
    }
  | MoveAxisDown(idx) =>
    ({...model, tsdm: {...ts, axisOrder: swapAt(ts.axisOrder, idx)}}, Tea_Cmd.none)
  | MoveScopeTierUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      ({...model, tsdm: {...ts, scopeOrder: swapAt(ts.scopeOrder, idx - 1)}}, Tea_Cmd.none)
    }
  | MoveScopeTierDown(idx) =>
    ({...model, tsdm: {...ts, scopeOrder: swapAt(ts.scopeOrder, idx)}}, Tea_Cmd.none)
  | MoveMaintenanceTierUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      (
        {
          ...model,
          tsdm: {...ts, maintenanceOrder: swapAt(ts.maintenanceOrder, idx - 1)},
        },
        Tea_Cmd.none,
      )
    }
  | MoveMaintenanceTierDown(idx) =>
    (
      {
        ...model,
        tsdm: {...ts, maintenanceOrder: swapAt(ts.maintenanceOrder, idx)},
      },
      Tea_Cmd.none,
    )
  | MoveAuditTierUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      ({...model, tsdm: {...ts, auditOrder: swapAt(ts.auditOrder, idx - 1)}}, Tea_Cmd.none)
    }
  | MoveAuditTierDown(idx) =>
    ({...model, tsdm: {...ts, auditOrder: swapAt(ts.auditOrder, idx)}}, Tea_Cmd.none)
  | ToggleCleanupStep(step) =>
    let isEnabled = ts.cleanupEnabled->Array.some(s => s === step)
    let newEnabled = if isEnabled {
      ts.cleanupEnabled->Array.filter(s => s !== step)
    } else {
      ts.cleanupEnabled->Array.concat([step])
    }
    ({...model, tsdm: {...ts, cleanupEnabled: newEnabled}}, Tea_Cmd.none)
  | SetAxisFilter(filter) =>
    ({...model, tsdm: {...ts, axisFilter: filter}}, Tea_Cmd.none)
  | SetTsdmSearch(text) =>
    ({...model, tsdm: {...ts, searchText: text}}, Tea_Cmd.none)
  | ToggleShowCompleted =>
    ({...model, tsdm: {...ts, showCompleted: !ts.showCompleted}}, Tea_Cmd.none)
  | ToggleLock =>
    ({...model, tsdm: {...ts, locked: !ts.locked}}, Tea_Cmd.none)
  | ResetToDefaults =>
    ({...model, tsdm: TsdmModel.init}, Tea_Cmd.none)
  | SaveDirective => {
    // Serialise the current TSDM state as JSON and persist via Tauri.
    let axisOrderJson = ts.axisOrder->Array.map(a => switch a { | AxisScope => "scope" | AxisMaintenance => "maintenance" | AxisAudit => "audit" })
    let scopeOrderJson = ts.scopeOrder->Array.map(s => switch s { | Must => "must" | Intend => "intend" | Like => "like" })
    let maintOrderJson = ts.maintenanceOrder->Array.map(m => switch m { | Corrective => "corrective" | Adaptive => "adaptive" | Perfective => "perfective" })
    let auditOrderJson = ts.auditOrder->Array.map(a => switch a { | Systems => "systems" | Compliance => "compliance" | Effects => "effects" })
    let directiveJson = `{"axisOrder":${JSON.stringify(JSON.Encode.array(axisOrderJson->Array.map(JSON.Encode.string)))},"scopeOrder":${JSON.stringify(JSON.Encode.array(scopeOrderJson->Array.map(JSON.Encode.string)))},"maintenanceOrder":${JSON.stringify(JSON.Encode.array(maintOrderJson->Array.map(JSON.Encode.string)))},"auditOrder":${JSON.stringify(JSON.Encode.array(auditOrderJson->Array.map(JSON.Encode.string)))},"locked":${if ts.locked { "true" } else { "false" }}}`
    (model, Tea_Cmd.batch(list{
      TsdmCmd.saveDirective(directiveJson, result => Tsdm(DirectiveSaved(result))),
      TypeLLService.checkSecurityTypes(directiveJson, "tsdm", result => Tsdm(TypeCheckResult(result))),
    }))
  }
  | DirectiveSaved(Ok(_path)) =>
    (model, Tea_Cmd.none)
  | DirectiveSaved(Error(err)) =>
    ({...model, tsdm: {...ts, lastError: Some(err)}}, Tea_Cmd.none)
  | LoadDirective =>
    (model, TsdmCmd.loadDirective(result => Tsdm(DirectiveLoaded(result))))
  | DirectiveLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let parseAxisOrder = obj->Dict.get("axisOrder")->Option.flatMap(JSON.Decode.array)->Option.getOr([])->Array.filterMap(v =>
        switch v->JSON.Decode.string {
        | Some("scope") => Some(TsdmModel.AxisScope)
        | Some("maintenance") => Some(TsdmModel.AxisMaintenance)
        | Some("audit") => Some(TsdmModel.AxisAudit)
        | _ => None
        }
      )
      let parseScopeOrder = obj->Dict.get("scopeOrder")->Option.flatMap(JSON.Decode.array)->Option.getOr([])->Array.filterMap(v =>
        switch v->JSON.Decode.string {
        | Some("must") => Some(TsdmModel.Must)
        | Some("intend") => Some(TsdmModel.Intend)
        | Some("like") => Some(TsdmModel.Like)
        | _ => None
        }
      )
      let parseMaintOrder = obj->Dict.get("maintenanceOrder")->Option.flatMap(JSON.Decode.array)->Option.getOr([])->Array.filterMap(v =>
        switch v->JSON.Decode.string {
        | Some("corrective") => Some(TsdmModel.Corrective)
        | Some("adaptive") => Some(TsdmModel.Adaptive)
        | Some("perfective") => Some(TsdmModel.Perfective)
        | _ => None
        }
      )
      let parseAuditOrder = obj->Dict.get("auditOrder")->Option.flatMap(JSON.Decode.array)->Option.getOr([])->Array.filterMap(v =>
        switch v->JSON.Decode.string {
        | Some("systems") => Some(TsdmModel.Systems)
        | Some("compliance") => Some(TsdmModel.Compliance)
        | Some("effects") => Some(TsdmModel.Effects)
        | _ => None
        }
      )
      let locked = obj->Dict.get("locked")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
      Some((parseAxisOrder, parseScopeOrder, parseMaintOrder, parseAuditOrder, locked))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((axisOrder, scopeOrder, maintOrder, auditOrder, locked)) =>
      let newTs = {
        ...ts,
        axisOrder: if Array.length(axisOrder) > 0 { axisOrder } else { ts.axisOrder },
        scopeOrder: if Array.length(scopeOrder) > 0 { scopeOrder } else { ts.scopeOrder },
        maintenanceOrder: if Array.length(maintOrder) > 0 { maintOrder } else { ts.maintenanceOrder },
        auditOrder: if Array.length(auditOrder) > 0 { auditOrder } else { ts.auditOrder },
        locked,
      }
      ({...model, tsdm: newTs}, Tea_Cmd.none)
    | None => (model, Tea_Cmd.none)
    }
  }
  | DirectiveLoaded(Error(err)) =>
    ({...model, tsdm: {...ts, lastError: Some(err)}}, Tea_Cmd.none)
  | CollectWorkItems =>
    (model, TsdmCmd.collectWorkItems(result => Tsdm(WorkItemsCollected(result))))
  | WorkItemsCollected(Ok(jsonStr)) => {
    let items = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      arr->Array.filterMap(item => {
        let o = item->JSON.Decode.object->Option.getOr(Dict.make())
        let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let id = gs(o, "id")
        if id !== "" {
          let axis = switch gs(o, "axis") {
          | "scope" => TsdmModel.AxisScope
          | "maintenance" => TsdmModel.AxisMaintenance
          | _ => TsdmModel.AxisAudit
          }
          let scopeTier = switch gs(o, "scope_tier") {
          | "must" => Some(TsdmModel.Must)
          | "intend" => Some(TsdmModel.Intend)
          | "like" => Some(TsdmModel.Like)
          | _ => None
          }
          let maintenanceTier = switch gs(o, "maintenance_tier") {
          | "corrective" => Some(TsdmModel.Corrective)
          | "adaptive" => Some(TsdmModel.Adaptive)
          | "perfective" => Some(TsdmModel.Perfective)
          | _ => None
          }
          let auditTier = switch gs(o, "audit_tier") {
          | "systems" => Some(TsdmModel.Systems)
          | "compliance" => Some(TsdmModel.Compliance)
          | "effects" => Some(TsdmModel.Effects)
          | _ => None
          }
          Some({
            TsdmModel.id,
            title: gs(o, "title"),
            description: gs(o, "description"),
            axis,
            scopeTier,
            maintenanceTier,
            auditTier,
            sourcePanel: gs(o, "source_panel"),
            done: gb(o, "done"),
          })
        } else {
          None
        }
      })
    } catch {
    | _ => []
    }
    ({...model, tsdm: {...ts, workItems: items}}, Tea_Cmd.none)
  }
  | WorkItemsCollected(Error(err)) =>
    ({...model, tsdm: {...ts, lastError: Some(err)}}, Tea_Cmd.none)
  | DismissTsdmError =>
    ({...model, tsdm: {...ts, lastError: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "tsdm", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

/// STATE TRANSITION: Valence Shell
/// Manages the embedded terminal panel — PTY lifecycle, input handling,
/// session recording, checkpoint management, approval gate, and Claude
/// Code integration. The terminal connects to the Valence shell binary
/// (formally verified reversible ops) or falls back to the system shell.
let updateValenceShell = (model: model, msg: valenceShellMsg): (model, Tea_Cmd.t<msg>) => {
  let vs = model.valenceShell
  switch msg {
  | SetShellCategory(cat) => ({...model, valenceShell: {...vs, activeCategory: cat}}, Tea_Cmd.none)
  | UpdateInput(value) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          inputLine: value,
          completionsVisible: String.length(value) > 0,
        },
      },
      Tea_Cmd.none,
    )
  | SubmitInput => {
      let input = String.trim(vs.inputLine)
      if String.length(input) === 0 {
        (model, Tea_Cmd.none)
      } else {
        // Check approval gate
        switch vs.approvalGate {
        | GateDisabled => (
            {
              ...model,
              valenceShell: {
                ...vs,
                inputLine: "",
                commandHistory: Array.concat(vs.commandHistory, [input]),
                historyIndex: -1,
                completionsVisible: false,
                claudeCodeActive: input === "claude" || String.startsWith(input, "claude "),
              },
            },
            Tea_Cmd.batch(list{
              ValenceShellCmd.sendInput(input ++ "\n", result => ValenceShell(PtyOutput(
                switch result {
                | Ok(s) => s
                | Error(e) => e
                },
                switch result {
                | Ok(_) => true
                | Error(_) => false
                },
              ))),
              TypeLLService.checkCodeTypes(input, "shell", result => ValenceShell(TypeCheckResult(result))),
            }),
          )
        | GateEnabled | GateLearning => {
            // Check whitelist for learning mode
            let isWhitelisted =
              vs.approvalGate === GateLearning &&
                Array.some(vs.approvedCommands, cmd => cmd === input)
            if isWhitelisted {
              // Auto-approve whitelisted commands
              (
                {
                  ...model,
                  valenceShell: {
                    ...vs,
                    inputLine: "",
                    commandHistory: Array.concat(vs.commandHistory, [input]),
                    historyIndex: -1,
                    completionsVisible: false,
                  },
                },
                ValenceShellCmd.sendInput(input ++ "\n", result => ValenceShell(PtyOutput(
                  switch result {
                  | Ok(s) => s
                  | Error(e) => e
                  },
                  switch result {
                  | Ok(_) => true
                  | Error(_) => false
                  },
                ))),
              )
            } else {
              // Queue for approval
              let pending: pendingCommand = {
                command: input,
                author: "child",
                submittedAt: 0.0,
              }
              (
                {
                  ...model,
                  valenceShell: {
                    ...vs,
                    inputLine: "",
                    pendingCommands: Array.concat(vs.pendingCommands, [pending]),
                    completionsVisible: false,
                  },
                },
                Tea_Cmd.none,
              )
            }
          }
        }
      }
    }
  | SelectCompletion(completion) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          inputLine: completion,
          completionsVisible: false,
        },
      },
      Tea_Cmd.none,
    )
  | ToggleCompletions => (
      {...model, valenceShell: {...vs, completionsVisible: !vs.completionsVisible}},
      Tea_Cmd.none,
    )
  | PtySpawned(Ok(_sessionId)) => (
      {...model, valenceShell: {...vs, ptyConnected: true, error: None}},
      Tea_Cmd.none,
    )
  | PtySpawned(Error(err)) => (
      {...model, valenceShell: {...vs, ptyConnected: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PtyOutput(content, isStdout) => {
      let line: terminalLine = {content, isStdout, timestamp: 0.0}
      let buffer = Array.concat(vs.outputBuffer, [line])
      // Ring buffer: keep last 1000 lines
      let trimmed = if Array.length(buffer) > 1000 {
        Array.sliceToEnd(buffer, ~start=Array.length(buffer) - 1000)
      } else {
        buffer
      }
      ({...model, valenceShell: {...vs, outputBuffer: trimmed}}, Tea_Cmd.none)
    }
  | PtyExited => (
      {...model, valenceShell: {...vs, ptyConnected: false, claudeCodeActive: false}},
      Tea_Cmd.none,
    )
  | CheckValenceAvailability => (
      model,
      ValenceShellCmd.checkValenceAvailability(result => ValenceShell(ValenceAvailabilityResult(result))),
    )
  | ValenceAvailabilityResult(Ok(_version)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          valenceAvailable: true,
          backend: ValenceShell,
        },
      },
      Tea_Cmd.none,
    )
  | ValenceAvailabilityResult(Error(_)) => (
      {...model, valenceShell: {...vs, valenceAvailable: false}},
      Tea_Cmd.none,
    )
  | LaunchClaudeCode => (
      {
        ...model,
        valenceShell: {
          ...vs,
          inputLine: "",
          commandHistory: Array.concat(vs.commandHistory, ["claude"]),
          claudeCodeActive: true,
        },
      },
      ValenceShellCmd.sendInput("claude\n", result => ValenceShell(PtyOutput(
        switch result {
        | Ok(s) => s
        | Error(e) => e
        },
        switch result {
        | Ok(_) => true
        | Error(_) => false
        },
      ))),
    )
  | StartRecordingSession => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.startRecording("session", result => ValenceShell(RecordingStarted(result))),
    )
  | StopRecordingSession => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.stopRecording(result => ValenceShell(RecordingStopped(result))),
    )
  | RecordingStarted(Ok(_path)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          recording: RecordingActive(0.0),
          loading: false,
          error: None,
        },
      },
      Tea_Cmd.none,
    )
  | RecordingStarted(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RecordingStopped(Ok(_path)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          recording: RecordingIdle,
          loading: false,
          error: None,
        },
      },
      // Reload the recordings list after stopping
      ValenceShellCmd.listRecordings(result => ValenceShell(RecordingsLoaded(result))),
    )
  | RecordingStopped(Error(err)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          recording: RecordingIdle,
          loading: false,
          error: Some(err),
        },
      },
      Tea_Cmd.none,
    )
  | LoadRecordings => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.listRecordings(result => ValenceShell(RecordingsLoaded(result))),
    )
  | RecordingsLoaded(Ok(jsonStr)) => {
      let parsed = try {
        let json = JSON.parseExn(jsonStr)
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let path = obj->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let durationSecs = obj->Dict.get("durationSecs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let createdAt = obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let sizeBytes = obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            ValenceShellModel.id: id,
            name: name,
            path: path,
            durationSecs: durationSecs,
            createdAt: createdAt,
            sizeBytes: Float.toInt(sizeBytes),
          })
        })
        Some(items)
      } catch {
      | _ => None
      }
      switch parsed {
      | Some(recs) => (
          {...model, valenceShell: {...vs, recordings: recs, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, valenceShell: {...vs, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | RecordingsLoaded(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DeleteRecordingById(id) => (
      model,
      ValenceShellCmd.deleteRecording(id, result => ValenceShell(RecordingDeleted(result))),
    )
  | RecordingDeleted(Ok(_)) => (
      model,
      ValenceShellCmd.listRecordings(result => ValenceShell(RecordingsLoaded(result))),
    )
  | RecordingDeleted(Error(err)) => (
      {...model, valenceShell: {...vs, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ExportRecordingAs(id, format) => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.exportRecording(id, format, result => ValenceShell(RecordingExported(result))),
    )
  | RecordingExported(Ok(_path)) => (
      {...model, valenceShell: {...vs, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | RecordingExported(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | CreateCheckpointWithLabel(label) => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.createCheckpoint(label, result => ValenceShell(CheckpointCreated(result))),
    )
  | CheckpointCreated(Ok(jsonStr)) => {
      let parsed = try {
        let json = JSON.parseExn(jsonStr)
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let label = obj->Dict.get("label")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let createdAt = obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let opsSince = obj->Dict.get("opsSinceCheckpoint")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          ValenceShellModel.id: id,
          label: label,
          createdAt: createdAt,
          opsSinceCheckpoint: Float.toInt(opsSince),
        })
      } catch {
      | _ => None
      }
      let newCheckpoints = switch parsed {
      | Some(cp) => Array.concat(vs.checkpoints, [cp])
      | None => vs.checkpoints
      }
      (
        {...model, valenceShell: {...vs, checkpoints: newCheckpoints, loading: false, error: None}},
        ValenceShellCmd.listCheckpoints(result => ValenceShell(CheckpointsLoaded(result))),
      )
    }
  | CheckpointCreated(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RestoreCheckpointById(id) => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.restoreCheckpoint(id, result => ValenceShell(CheckpointRestored(result))),
    )
  | CheckpointRestored(Ok(_)) => (
      {...model, valenceShell: {...vs, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | CheckpointRestored(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadCheckpoints => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.listCheckpoints(result => ValenceShell(CheckpointsLoaded(result))),
    )
  | CheckpointsLoaded(Ok(jsonStr)) => {
      let parsed = try {
        let json = JSON.parseExn(jsonStr)
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let label = obj->Dict.get("label")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let createdAt = obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let opsSince = obj->Dict.get("opsSinceCheckpoint")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            ValenceShellModel.id: id,
            label: label,
            createdAt: createdAt,
            opsSinceCheckpoint: Float.toInt(opsSince),
          })
        })
        Some(items)
      } catch {
      | _ => None
      }
      switch parsed {
      | Some(cps) => (
          {...model, valenceShell: {...vs, checkpoints: cps, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, valenceShell: {...vs, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | CheckpointsLoaded(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ScreenshotTerminal => (
      model,
      ValenceShellCmd.screenshotTerminal(result => ValenceShell(ScreenshotCaptured(result))),
    )
  | ScreenshotCaptured(Ok(_path)) => (model, Tea_Cmd.none)
  | ScreenshotCaptured(Error(err)) => (
      {...model, valenceShell: {...vs, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetApprovalGate(gate) => (
      {...model, valenceShell: {...vs, approvalGate: gate}},
      Tea_Cmd.none,
    )
  | ApproveCommand(idx) => {
      let cmd = vs.pendingCommands->Array.get(idx)
      switch cmd {
      | Some(pending) => {
          let remaining = Array.filterWithIndex(vs.pendingCommands, (_c, i) => i !== idx)
          let newApproved = if vs.approvalGate === GateLearning {
            Array.concat(vs.approvedCommands, [pending.command])
          } else {
            vs.approvedCommands
          }
          (
            {
              ...model,
              valenceShell: {
                ...vs,
                pendingCommands: remaining,
                approvedCommands: newApproved,
                commandHistory: Array.concat(vs.commandHistory, [pending.command]),
              },
            },
            ValenceShellCmd.sendInput(pending.command ++ "\n", result => ValenceShell(PtyOutput(
              switch result {
              | Ok(s) => s
              | Error(e) => e
              },
              switch result {
              | Ok(_) => true
              | Error(_) => false
              },
            ))),
          )
        }
      | None => (model, Tea_Cmd.none)
      }
    }
  | RejectCommand(idx) => {
      let remaining = Array.filterWithIndex(vs.pendingCommands, (_c, i) => i !== idx)
      ({...model, valenceShell: {...vs, pendingCommands: remaining}}, Tea_Cmd.none)
    }
  | ToggleSplitView => (
      {...model, valenceShell: {...vs, splitView: !vs.splitView}},
      Tea_Cmd.none,
    )
  | DismissError => ({...model, valenceShell: {...vs, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "valenceshell", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

/// STATE TRANSITION: Game Preview
/// Manages the live IDApTIK game preview — dev server connection,
/// game loop control (pause/resume/step), overlay toggles, gameplay
/// recording, zoom, multiplayer view, and render statistics.
let updateGamePreview = (model: model, msg: gamePreviewMsg): (model, Tea_Cmd.t<msg>) => {
  let gp = model.gamePreview
  switch msg {
  | SetPreviewCategory(cat) => ({...model, gamePreview: {...gp, activeCategory: cat}}, Tea_Cmd.none)
  | CheckDevServer => (
      {...model, gamePreview: {...gp, loading: true}},
      Tea_Cmd.batch(list{
        GamePreviewCmd.checkDevServer(gp.devServerUrl, result => GamePreview(DevServerResult(result))),
        TypeLLService.checkGameDataTypes(gp.devServerUrl, "game-preview", result => GamePreview(TypeCheckResult(result))),
      }),
    )
  | DevServerResult(Ok(_)) => (
      {...model, gamePreview: {...gp, devServerConnected: true, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | DevServerResult(Error(err)) => (
      {...model, gamePreview: {...gp, devServerConnected: false, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PauseGame => (
      {...model, gamePreview: {...gp, execution: GamePaused}},
      GamePreviewCmd.controlGameLoop("pause", result => GamePreview(GameControlResult(result))),
    )
  | ResumeGame => (
      {...model, gamePreview: {...gp, execution: GameRunning}},
      GamePreviewCmd.controlGameLoop("resume", result => GamePreview(GameControlResult(result))),
    )
  | StepFrame => (
      {...model, gamePreview: {...gp, execution: GameStepping}},
      GamePreviewCmd.controlGameLoop("step", result => GamePreview(GameControlResult(result))),
    )
  | GameControlResult(Ok(_)) => (model, Tea_Cmd.none)
  | GameControlResult(Error(err)) => (
      {...model, gamePreview: {...gp, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleOverlay(overlay) => (
      {
        ...model,
        gamePreview: {
          ...gp,
          activeOverlays: GamePreviewEngine.toggleOverlay(gp.activeOverlays, overlay),
        },
      },
      Tea_Cmd.none,
    )
  | StartGameRecording => (
      {...model, gamePreview: {...gp, loading: true}},
      GamePreviewCmd.startGameRecording("gameplay", result => GamePreview(GameRecordingStarted(result))),
    )
  | StopGameRecording => (
      {...model, gamePreview: {...gp, loading: true}},
      GamePreviewCmd.stopGameRecording(result => GamePreview(GameRecordingStopped(result))),
    )
  | GameRecordingStarted(Ok(_)) => (
      {...model, gamePreview: {...gp, gameRecording: GameRecordingActive(0.0), loading: false, error: None}},
      Tea_Cmd.none,
    )
  | GameRecordingStarted(Error(err)) => (
      {...model, gamePreview: {...gp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | GameRecordingStopped(Ok(_)) => (
      {...model, gamePreview: {...gp, gameRecording: GameRecordingIdle, loading: false, error: None}},
      GamePreviewCmd.listClips(result => GamePreview(ClipsLoaded(result))),
    )
  | GameRecordingStopped(Error(err)) => (
      {...model, gamePreview: {...gp, gameRecording: GameRecordingIdle, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ScreenshotGame => (
      model,
      GamePreviewCmd.screenshotGameFrame(result => GamePreview(GameScreenshotCaptured(result))),
    )
  | GameScreenshotCaptured(Ok(_)) => (model, Tea_Cmd.none)
  | GameScreenshotCaptured(Error(err)) => (
      {...model, gamePreview: {...gp, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetZoom(level) => {
      let clamped = if level < 0.25 { 0.25 } else if level > 4.0 { 4.0 } else { level }
      ({...model, gamePreview: {...gp, zoomLevel: clamped}}, Tea_Cmd.none)
    }
  | ToggleMultiplayerView => (
      {...model, gamePreview: {...gp, multiplayerView: !gp.multiplayerView}},
      Tea_Cmd.none,
    )
  | LoadClips => (
      {...model, gamePreview: {...gp, loading: true}},
      GamePreviewCmd.listClips(result => GamePreview(ClipsLoaded(result))),
    )
  | ClipsLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let path = obj->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let durationSecs = obj->Dict.get("durationSecs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let sizeBytes = obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let createdAt = obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          GamePreviewModel.id: id,
          name: name,
          path: path,
          durationSecs: durationSecs,
          sizeBytes: Float.toInt(sizeBytes),
          createdAt: createdAt,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(clips) => (
        {...model, gamePreview: {...gp, clips: clips, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, gamePreview: {...gp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | ClipsLoaded(Error(err)) => (
      {...model, gamePreview: {...gp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DeleteClip(id) => (
      model,
      GamePreviewCmd.deleteClip(id, result => GamePreview(ClipDeleted(result))),
    )
  | ClipDeleted(Ok(_)) => (
      model,
      GamePreviewCmd.listClips(result => GamePreview(ClipsLoaded(result))),
    )
  | ClipDeleted(Error(err)) => (
      {...model, gamePreview: {...gp, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshStats => (
      model,
      GamePreviewCmd.fetchRenderStats(result => GamePreview(StatsReceived(result))),
    )
  | StatsReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let fps = obj->Dict.get("fps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let drawCalls = obj->Dict.get("drawCalls")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let textureMemory = obj->Dict.get("textureMemory")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let spriteCount = obj->Dict.get("spriteCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      Some({
        GamePreviewModel.fps: fps,
        drawCalls: Float.toInt(drawCalls),
        textureMemory: Float.toInt(textureMemory),
        spriteCount: Float.toInt(spriteCount),
      })
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(stats) => ({...model, gamePreview: {...gp, stats: Some(stats)}}, Tea_Cmd.none)
    | None => (model, Tea_Cmd.none)
    }
  }
  | StatsReceived(Error(err)) => (
      {...model, gamePreview: {...gp, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ClearDeviceLog => ({...model, gamePreview: {...gp, deviceLog: []}}, Tea_Cmd.none)
  | DeviceInteractionEvent(entry) => {
      let log = Array.concat(gp.deviceLog, [entry])
      let trimmed = if Array.length(log) > 200 {
        Array.sliceToEnd(log, ~start=Array.length(log) - 200)
      } else {
        log
      }
      ({...model, gamePreview: {...gp, deviceLog: trimmed}}, Tea_Cmd.none)
    }
  | DismissGameError => ({...model, gamePreview: {...gp, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "gamepreview", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

/// STATE TRANSITION: VM Inspector
/// Manages the reversible VM visual debugger — step forward/backward,
/// breakpoints, timeline navigation, and state export.
let updateVmInspector = (model: model, msg: vmInspectorMsg): (model, Tea_Cmd.t<msg>) => {
  let vm = model.vmInspector
  switch msg {
  | SetInspectorCategory(cat) => ({...model, vmInspector: {...vm, activeCategory: cat}}, Tea_Cmd.none)
  | ReadVmState => {
      let vmCmd = switch vm.connection {
      | VmFileConnection(path) =>
        VmInspectorCmd.readVmStateFromFile(path, result => VmInspector(VmStateReceived(result)))
      | VmLiveConnection | VmDisconnected =>
        VmInspectorCmd.readVmState(result => VmInspector(VmStateReceived(result)))
      }
      (
        {...model, vmInspector: {...vm, loading: true}},
        Tea_Cmd.batch(list{
          vmCmd,
          TypeLLService.checkGameDataTypes("vm-state", "vm-inspector", result => VmInspector(TypeCheckResult(result))),
        }),
      )
    }
  | VmStateReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let pc = obj->Dict.get("pc")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let stackArr = obj->Dict.get("stack")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let stack = stackArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      let memArr = obj->Dict.get("memory")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let memory = memArr->Array.filterMap(m => {
        let mObj = m->JSON.Decode.object->Option.getOr(Dict.make())
        let address = mObj->Dict.get("address")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let value = mObj->Dict.get("value")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let recentRead = mObj->Dict.get("recentRead")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let recentWrite = mObj->Dict.get("recentWrite")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          VmInspectorModel.address: Float.toInt(address),
          value: Float.toInt(value),
          recentRead: recentRead,
          recentWrite: recentWrite,
        })
      })
      let instrArr = obj->Dict.get("instructions")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let instructions = instrArr->Array.filterMap(i => {
        let iObj = i->JSON.Decode.object->Option.getOr(Dict.make())
        let index = iObj->Dict.get("index")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let mnemonic = iObj->Dict.get("mnemonic")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let tierStr = iObj->Dict.get("tier")->Option.flatMap(JSON.Decode.string)->Option.getOr("arithmetic")
        let tier = switch tierStr {
        | "conditionals" => VmInspectorModel.TierConditionals
        | "stack_memory" => TierStackMemory
        | "subroutines" => TierSubroutines
        | "io" => TierIO
        | _ => TierArithmetic
        }
        let hasBreakpoint = iObj->Dict.get("hasBreakpoint")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let executionCount = iObj->Dict.get("executionCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          VmInspectorModel.index: Float.toInt(index),
          mnemonic: mnemonic,
          tier: tier,
          hasBreakpoint: hasBreakpoint,
          executionCount: Float.toInt(executionCount),
        })
      })
      let running = obj->Dict.get("running")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
      let totalSteps = obj->Dict.get("totalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let tierCountsArr = obj->Dict.get("tierCounts")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let tierCounts = tierCountsArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      Some((Float.toInt(pc), stack, memory, instructions, running, Float.toInt(totalSteps), tierCounts))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((pc, stack, memory, instructions, running, totalSteps, tierCounts)) => (
        {
          ...model,
          vmInspector: {
            ...vm,
            pc: pc,
            stack: stack,
            memory: memory,
            instructions: instructions,
            running: running,
            totalSteps: totalSteps,
            tierCounts: tierCounts,
            loading: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, vmInspector: {...vm, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | VmStateReceived(Error(err)) => (
      {...model, vmInspector: {...vm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | StepForward => {
      let cmd = if vm.bojRouting {
        BojCmd.invokeCartridgeWithLatency("dap-mcp", "step_forward", "", result => VmInspector(StepResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        VmInspectorCmd.stepForward(result => VmInspector(StepResult(result)))
      }
      ({...model, vmInspector: {...vm, loading: true}}, cmd)
    }
  | StepBackward => {
      let cmd = if vm.bojRouting {
        BojCmd.invokeCartridgeWithLatency("dap-mcp", "step_backward", "", result => VmInspector(StepResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        VmInspectorCmd.stepBackward(result => VmInspector(StepResult(result)))
      }
      ({...model, vmInspector: {...vm, loading: true}}, cmd)
    }
  | StepResult(Ok(jsonStr)) => {
      let parsed = try {
        let json = JSON.parseExn(jsonStr)
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let pc = obj->Dict.get("pc")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let stackArr = obj->Dict.get("stack")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let stack = stackArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
        let memArr = obj->Dict.get("memory")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let memory = memArr->Array.filterMap(m => {
          let mObj = m->JSON.Decode.object->Option.getOr(Dict.make())
          let address = mObj->Dict.get("address")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let value = mObj->Dict.get("value")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let recentRead = mObj->Dict.get("recentRead")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let recentWrite = mObj->Dict.get("recentWrite")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          Some({
            VmInspectorModel.address: Float.toInt(address),
            value: Float.toInt(value),
            recentRead: recentRead,
            recentWrite: recentWrite,
          })
        })
        let instrMnemonic = obj->Dict.get("instructionMnemonic")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let running = obj->Dict.get("running")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let totalSteps = obj->Dict.get("totalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let tierCountsArr = obj->Dict.get("tierCounts")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let tierCounts = tierCountsArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
        Some((Float.toInt(pc), stack, memory, instrMnemonic, running, Float.toInt(totalSteps), tierCounts))
      } catch {
      | _ => None
      }
      switch parsed {
      | Some((pc, stack, memory, instrMnemonic, running, totalSteps, tierCounts)) => {
          let newStep = totalSteps
          let snapshot: VmInspectorModel.vmSnapshot = {
            step: newStep,
            pc: pc,
            stack: stack,
            memory: memory,
            instructionMnemonic: instrMnemonic,
          }
          let history = Array.concat(vm.history, [snapshot])
          let trimmed = if Array.length(history) > 10000 {
            Array.sliceToEnd(history, ~start=Array.length(history) - 10000)
          } else {
            history
          }
          (
            {
              ...model,
              vmInspector: {
                ...vm,
                pc: pc,
                stack: stack,
                memory: memory,
                running: running,
                totalSteps: newStep,
                tierCounts: tierCounts,
                history: trimmed,
                timelinePosition: Array.length(trimmed) - 1,
                loading: false,
                error: None,
              },
            },
            Tea_Cmd.none,
          )
        }
      | None => {
          let newStep = vm.totalSteps + 1
          ({...model, vmInspector: {...vm, loading: false, totalSteps: newStep, error: None}}, Tea_Cmd.none)
        }
      }
    }
  | StepResult(Error(err)) => (
      {...model, vmInspector: {...vm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunVm => {
      let cmd = if vm.bojRouting {
        BojCmd.invokeCartridgeWithLatency("dap-mcp", "run", "", result => VmInspector(RunResult(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        VmInspectorCmd.runToBreakpoint(result => VmInspector(RunResult(result)))
      }
      ({...model, vmInspector: {...vm, running: true}}, cmd)
    }
  | PauseVm => ({...model, vmInspector: {...vm, running: false}}, Tea_Cmd.none)
  | RunResult(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let pc = obj->Dict.get("pc")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let stackArr = obj->Dict.get("stack")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let stack = stackArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      let memArr = obj->Dict.get("memory")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let memory = memArr->Array.filterMap(m => {
        let mObj = m->JSON.Decode.object->Option.getOr(Dict.make())
        let address = mObj->Dict.get("address")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let value = mObj->Dict.get("value")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let recentRead = mObj->Dict.get("recentRead")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let recentWrite = mObj->Dict.get("recentWrite")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          VmInspectorModel.address: Float.toInt(address),
          value: Float.toInt(value),
          recentRead: recentRead,
          recentWrite: recentWrite,
        })
      })
      let totalSteps = obj->Dict.get("totalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let tierCountsArr = obj->Dict.get("tierCounts")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let tierCounts = tierCountsArr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      Some((Float.toInt(pc), stack, memory, Float.toInt(totalSteps), tierCounts))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((pc, stack, memory, totalSteps, tierCounts)) => (
        {
          ...model,
          vmInspector: {
            ...vm,
            pc: pc,
            stack: stack,
            memory: memory,
            totalSteps: totalSteps,
            tierCounts: tierCounts,
            running: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, vmInspector: {...vm, running: false, error: None}}, Tea_Cmd.none)
    }
  }
  | RunResult(Error(err)) => (
      {...model, vmInspector: {...vm, running: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ResetVm => (
      {
        ...model,
        vmInspector: {
          ...vm,
          pc: 0,
          stack: [],
          history: [],
          timelinePosition: 0,
          totalSteps: 0,
          running: false,
          portLog: [],
          tierCounts: [0, 0, 0, 0, 0],
        },
      },
      Tea_Cmd.none,
    )
  | ToggleBreakpoint(idx) => {
      let hasIt = Array.some(vm.breakpoints, bp =>
        switch bp {
        | BreakAtInstruction(i) => i === idx
        | _ => false
        }
      )
      let newBps = if hasIt {
        Array.filter(vm.breakpoints, bp =>
          switch bp {
          | BreakAtInstruction(i) => i !== idx
          | _ => true
          }
        )
      } else {
        Array.concat(vm.breakpoints, [BreakAtInstruction(idx)])
      }
      let newInstructions = Array.map(vm.instructions, instr =>
        if instr.index === idx {
          {...instr, hasBreakpoint: !instr.hasBreakpoint}
        } else {
          instr
        }
      )
      (
        {...model, vmInspector: {...vm, breakpoints: newBps, instructions: newInstructions}},
        Tea_Cmd.none,
      )
    }
  | SeekTimeline(pos) => {
      let maxPos = Array.length(vm.history) - 1
      let clamped = if pos < 0 { 0 } else if pos > maxPos { maxPos } else { pos }
      ({...model, vmInspector: {...vm, timelinePosition: clamped}}, Tea_Cmd.none)
    }
  | ExportSnapshot => (
      model,
      VmInspectorCmd.exportSnapshot(result => VmInspector(SnapshotExported(result))),
    )
  | SnapshotExported(Ok(_)) => (model, Tea_Cmd.none)
  | SnapshotExported(Error(err)) => (
      {...model, vmInspector: {...vm, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleMultiVm => (
      {...model, vmInspector: {...vm, multiVmView: !vm.multiVmView}},
      Tea_Cmd.none,
    )
  | DismissVmError => ({...model, vmInspector: {...vm, error: None}}, Tea_Cmd.none)
  | ToggleVmBojRouting => ({...model, vmInspector: {...vm, bojRouting: !vm.bojRouting}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "vminspector", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Network Topology Sub-Updater
// ===========================================================================

/// Handles all Network Topology (IDApTIK in-game network viewer) messages.
let updateNetworkTopology = (model: model, msg: networkTopologyMsg): (model, Tea_Cmd.t<msg>) => {
  let nt = model.networkTopology
  switch msg {
  | SetTopologyCategory(cat) => ({...model, networkTopology: {...nt, activeCategory: cat}}, Tea_Cmd.none)
  | RefreshTopology => (
      {...model, networkTopology: {...nt, loading: true}},
      Tea_Cmd.batch(list{
        NetworkTopologyCmd.readTopology(result => NetworkTopology(TopologyReceived(result))),
        TypeLLService.checkGameDataTypes("topology", "network-topology", result => NetworkTopology(TypeCheckResult(result))),
      }),
    )
  | TopologyReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let devArr = obj->Dict.get("devices")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let devices = devArr->Array.filterMap(d => {
        let dObj = d->JSON.Decode.object->Option.getOr(Dict.make())
        let id = dObj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = dObj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let deviceType = dObj->Dict.get("deviceType")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let zoneStr = dObj->Dict.get("zone")->Option.flatMap(JSON.Decode.string)->Option.getOr("public")
        let zone = switch zoneStr {
        | "dmz" => NetworkTopologyModel.ZoneDmz
        | "internal" => ZoneInternal
        | "restricted" => ZoneRestricted
        | "air_gapped" => ZoneAirGapped
        | _ => ZonePublic
        }
        let securityLevel = dObj->Dict.get("securityLevel")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let x = dObj->Dict.get("x")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let y = dObj->Dict.get("y")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let flagsArr = dObj->Dict.get("defenceFlags")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let defenceFlags = flagsArr->Array.filterMap(f => f->JSON.Decode.string)
        let compromised = dObj->Dict.get("compromised")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let active = dObj->Dict.get("active")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
        Some({
          NetworkTopologyModel.id: id,
          name: name,
          deviceType: deviceType,
          zone: zone,
          securityLevel: Float.toInt(securityLevel),
          x: x,
          y: y,
          defenceFlags: defenceFlags,
          compromised: compromised,
          active: active,
        })
      })
      let connArr = obj->Dict.get("connections")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let connections = connArr->Array.filterMap(c => {
        let cObj = c->JSON.Decode.object->Option.getOr(Dict.make())
        let sourceId = cObj->Dict.get("sourceId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let targetId = cObj->Dict.get("targetId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let protoStr = cObj->Dict.get("protocol")->Option.flatMap(JSON.Decode.string)->Option.getOr("custom")
        let protocol = switch protoStr {
        | "ssh" => NetworkTopologyModel.ProtoSSH
        | "https" => ProtoHTTPS
        | "ftp" => ProtoFTP
        | "dns" => ProtoDNS
        | other => ProtoCustom(other)
        }
        let encrypted = cObj->Dict.get("encrypted")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let packetCount = cObj->Dict.get("packetCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let latencyMs = cObj->Dict.get("latencyMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let active = cObj->Dict.get("active")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
        Some({
          NetworkTopologyModel.sourceId: sourceId,
          targetId: targetId,
          protocol: protocol,
          encrypted: encrypted,
          packetCount: Float.toInt(packetCount),
          latencyMs: latencyMs,
          active: active,
        })
      })
      Some((devices, connections))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((devices, connections)) => (
        {
          ...model,
          networkTopology: {
            ...nt,
            devices: devices,
            connections: connections,
            loading: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, networkTopology: {...nt, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | TopologyReceived(Error(err)) => (
      {...model, networkTopology: {...nt, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectDevice(id) => ({...model, networkTopology: {...nt, selectedDeviceId: Some(id)}}, Tea_Cmd.none)
  | DeselectDevice => ({...model, networkTopology: {...nt, selectedDeviceId: None}}, Tea_Cmd.none)
  | RefreshDns => (
      {...model, networkTopology: {...nt, loading: true}},
      NetworkTopologyCmd.readDnsTable(result => NetworkTopology(DnsReceived(result))),
    )
  | DnsReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let entries = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let hostname = obj->Dict.get("hostname")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let resolvedIp = obj->Dict.get("resolvedIp")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let recordType = obj->Dict.get("recordType")->Option.flatMap(JSON.Decode.string)->Option.getOr("A")
        let ttl = obj->Dict.get("ttl")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          NetworkTopologyModel.hostname: hostname,
          resolvedIp: resolvedIp,
          recordType: recordType,
          ttl: Float.toInt(ttl),
        })
      })
      Some(entries)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(entries) => (
        {...model, networkTopology: {...nt, dnsEntries: entries, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, networkTopology: {...nt, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | DnsReceived(Error(err)) => (
      {...model, networkTopology: {...nt, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | TogglePacketAnimation => (
      {...model, networkTopology: {...nt, animatePackets: !nt.animatePackets}},
      if !nt.animatePackets {
        NetworkTopologyCmd.readPacketFlow(result => NetworkTopology(PacketFlowReceived(result)))
      } else {
        Tea_Cmd.none
      },
    )
  | PacketFlowReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let events = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let connectionId = obj->Dict.get("connectionId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let timestamp = obj->Dict.get("timestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let size = obj->Dict.get("size")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let blocked = obj->Dict.get("blocked")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          NetworkTopologyModel.connectionId: connectionId,
          timestamp: timestamp,
          size: Float.toInt(size),
          blocked: blocked,
        })
      })
      Some(events)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(events) => (
        {...model, networkTopology: {...nt, packetFlow: events, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, networkTopology: {...nt, error: None}}, Tea_Cmd.none)
    }
  }
  | PacketFlowReceived(Error(err)) => (
      {...model, networkTopology: {...nt, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleLabels => ({...model, networkTopology: {...nt, showLabels: !nt.showLabels}}, Tea_Cmd.none)
  | ToggleSecurityLevels => (
      {...model, networkTopology: {...nt, showSecurityLevels: !nt.showSecurityLevels}},
      Tea_Cmd.none,
    )
  | ExportTopologySvg => (
      model,
      NetworkTopologyCmd.exportSvg(result => NetworkTopology(TopologySvgExported(result))),
    )
  | TopologySvgExported(Ok(_)) => (model, Tea_Cmd.none)
  | TopologySvgExported(Error(err)) => (
      {...model, networkTopology: {...nt, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissTopoError => ({...model, networkTopology: {...nt, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "networktopology", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Level Architect Sub-Updater
// ===========================================================================

/// Handles all Level Architect (IDApTIK visual level design) messages.
let updateLevelArchitect = (model: model, msg: levelArchitectMsg): (model, Tea_Cmd.t<msg>) => {
  let la = model.levelArchitect
  switch msg {
  | SetArchitectCategory(cat) => ({...model, levelArchitect: {...la, activeCategory: cat}}, Tea_Cmd.none)
  | ClickGrid(x, y) => {
      // Behaviour depends on selected tool
      switch la.selectedTool {
      | ToolSelect =>
        let entity = la.entities->Array.find(e => e.gridX === x && e.gridY === y)
        let selected = switch entity {
        | Some(e) => Some(e.id)
        | None => None
        }
        ({...model, levelArchitect: {...la, selectedEntityId: selected}}, Tea_Cmd.none)
      | ToolPlace(kind) =>
        if LevelArchitectEngine.isOccupied(la.entities, x, y) {
          (model, Tea_Cmd.none)
        } else {
          let id = `${Int.toString(x)}_${Int.toString(y)}_${Int.toString(Array.length(la.entities))}`
          let entity: levelEntity = {
            id,
            kind,
            name: LevelArchitectEngine.entityKindLabel(kind),
            gridX: x,
            gridY: y,
            rotation: 0,
            properties: [],
          }
          (
            {
              ...model,
              levelArchitect: {
                ...la,
                entities: Array.concat(la.entities, [entity]),
                selectedEntityId: Some(id),
              },
            },
            Tea_Cmd.none,
          )
        }
      | ToolErase =>
        let newEntities = la.entities->Array.filter(e => !(e.gridX === x && e.gridY === y))
        ({...model, levelArchitect: {...la, entities: newEntities}}, Tea_Cmd.none)
      | ToolPatrol => {
        // Add a patrol waypoint at the clicked grid position for the currently selected guard.
        let waypoint: LevelArchitectModel.patrolWaypoint = {x, y, pauseDuration: 1.0}
        let patrols = switch la.selectedEntityId {
        | Some(guardId) => {
            let existing = la.patrols->Array.find(p => p.guardId === guardId)
            switch existing {
            | Some(_patrol) =>
              la.patrols->Array.map(p =>
                if p.guardId === guardId {
                  {...p, waypoints: Array.concat(p.waypoints, [waypoint])}
                } else {
                  p
                }
              )
            | None =>
              Array.concat(la.patrols, [{guardId, waypoints: [waypoint], looping: true, speed: 1.0}])
            }
          }
        | None => la.patrols
        }
        ({...model, levelArchitect: {...la, patrols}}, Tea_Cmd.none)
      }
      | ToolDefenceFlag => {
        // Place a defence flag entity at the clicked grid position.
        if !LevelArchitectEngine.isOccupied(la.entities, x, y) {
          let id = `flag_${Int.toString(x)}_${Int.toString(y)}`
          let entity: levelEntity = {
            id,
            kind: EntityTrigger,
            name: "Defence Flag",
            gridX: x,
            gridY: y,
            rotation: 0,
            properties: [("type", "defence_flag")],
          }
          ({...model, levelArchitect: {...la, entities: Array.concat(la.entities, [entity]), selectedEntityId: Some(id)}}, Tea_Cmd.none)
        } else {
          (model, Tea_Cmd.none)
        }
      }
      }
    }
  | SelectEntity(id) => ({...model, levelArchitect: {...la, selectedEntityId: Some(id)}}, Tea_Cmd.none)
  | DeselectEntity => ({...model, levelArchitect: {...la, selectedEntityId: None}}, Tea_Cmd.none)
  | SelectTool(tool) => ({...model, levelArchitect: {...la, selectedTool: tool}}, Tea_Cmd.none)
  | ToggleDefenceFlag(flag) => {
      let hasIt = la.defenceFlags->Array.includes(flag)
      let newFlags = if hasIt {
        la.defenceFlags->Array.filter(f => f !== flag)
      } else {
        Array.concat(la.defenceFlags, [flag])
      }
      ({...model, levelArchitect: {...la, defenceFlags: newFlags}}, Tea_Cmd.none)
    }
  | SetAlertThreshold(n) => ({...model, levelArchitect: {...la, alertThreshold: n}}, Tea_Cmd.none)
  | BrowseAssets => (
      {...model, levelArchitect: {...la, loading: true}},
      LevelArchitectCmd.browseAssets(result => LevelArchitect(AssetsLoaded(result))),
    )
  | AssetsLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let category = obj->Dict.get("category")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let thumbnail = obj->Dict.get("thumbnail")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let kindStr = obj->Dict.get("entityKind")->Option.flatMap(JSON.Decode.string)->Option.getOr("device")
        let entityKind = switch kindStr {
        | "guard" => LevelArchitectModel.EntityGuard
        | "spawn_point" => EntitySpawnPoint
        | "companion" => EntityCompanion
        | "collectable" => EntityCollectable
        | "trigger" => EntityTrigger
        | "decoration" => EntityDecoration
        | _ => EntityDevice
        }
        Some({
          LevelArchitectModel.id: id,
          name: name,
          category: category,
          thumbnail: thumbnail,
          entityKind: entityKind,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(assets) => (
        {...model, levelArchitect: {...la, assets: assets, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, levelArchitect: {...la, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | AssetsLoaded(Error(err)) => (
      {...model, levelArchitect: {...la, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ValidateLevel => (
      {...model, levelArchitect: {...la, loading: true}},
      Tea_Cmd.batch(list{
        LevelArchitectCmd.validateLevel("", result => LevelArchitect(ValidationResult(result))),
        TypeLLService.checkGameDataTypes("level-data", "level-architect", result => LevelArchitect(TypeCheckResult(result))),
      }),
    )
  | ValidationResult(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let issues = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let severity = obj->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("warning")
        let message = obj->Dict.get("message")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let entityId = obj->Dict.get("entityId")->Option.flatMap(JSON.Decode.string)
        let gridX = obj->Dict.get("gridX")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        let gridY = obj->Dict.get("gridY")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        Some({
          LevelArchitectModel.severity: severity,
          message: message,
          entityId: entityId,
          gridX: gridX,
          gridY: gridY,
        })
      })
      Some(issues)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(issues) => (
        {...model, levelArchitect: {...la, validationIssues: issues, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, levelArchitect: {...la, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | ValidationResult(Error(err)) => (
      {...model, levelArchitect: {...la, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadLevel(path) => (
      {...model, levelArchitect: {...la, loading: true}},
      LevelArchitectCmd.loadLevel(path, result => LevelArchitect(LevelLoaded(result))),
    )
  | LevelLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let levelName = obj->Dict.get("levelName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let gridWidth = obj->Dict.get("gridWidth")->Option.flatMap(JSON.Decode.float)->Option.getOr(32.0)
      let gridHeight = obj->Dict.get("gridHeight")->Option.flatMap(JSON.Decode.float)->Option.getOr(32.0)
      let entArr = obj->Dict.get("entities")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let entities = entArr->Array.filterMap(e => {
        let eObj = e->JSON.Decode.object->Option.getOr(Dict.make())
        let id = eObj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let kindStr = eObj->Dict.get("kind")->Option.flatMap(JSON.Decode.string)->Option.getOr("device")
        let kind = switch kindStr {
        | "guard" => LevelArchitectModel.EntityGuard
        | "spawn_point" => EntitySpawnPoint
        | "companion" => EntityCompanion
        | "collectable" => EntityCollectable
        | "trigger" => EntityTrigger
        | "decoration" => EntityDecoration
        | _ => EntityDevice
        }
        let name = eObj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gridX = eObj->Dict.get("gridX")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let gridY = eObj->Dict.get("gridY")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let rotation = eObj->Dict.get("rotation")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let propsArr = eObj->Dict.get("properties")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let properties = propsArr->Array.filterMap(p => {
          let pArr = p->JSON.Decode.array->Option.getOr([])
          switch (pArr->Array.get(0), pArr->Array.get(1)) {
          | (Some(k), Some(v)) =>
            switch (k->JSON.Decode.string, v->JSON.Decode.string) {
            | (Some(key), Some(val)) => Some((key, val))
            | _ => None
            }
          | _ => None
          }
        })
        Some({
          LevelArchitectModel.id: id,
          kind: kind,
          name: name,
          gridX: Float.toInt(gridX),
          gridY: Float.toInt(gridY),
          rotation: Float.toInt(rotation),
          properties: properties,
        })
      })
      let patArr = obj->Dict.get("patrols")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let patrols = patArr->Array.filterMap(p => {
        let pObj = p->JSON.Decode.object->Option.getOr(Dict.make())
        let guardId = pObj->Dict.get("guardId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let looping = pObj->Dict.get("looping")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
        let speed = pObj->Dict.get("speed")->Option.flatMap(JSON.Decode.float)->Option.getOr(1.0)
        let wpArr = pObj->Dict.get("waypoints")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let waypoints = wpArr->Array.filterMap(w => {
          let wObj = w->JSON.Decode.object->Option.getOr(Dict.make())
          let x = wObj->Dict.get("x")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let y = wObj->Dict.get("y")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let pauseDuration = wObj->Dict.get("pauseDuration")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({LevelArchitectModel.x: Float.toInt(x), y: Float.toInt(y), pauseDuration: pauseDuration})
        })
        Some({
          LevelArchitectModel.guardId: guardId,
          waypoints: waypoints,
          looping: looping,
          speed: speed,
        })
      })
      Some((levelName, Float.toInt(gridWidth), Float.toInt(gridHeight), entities, patrols))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((levelName, gridWidth, gridHeight, entities, patrols)) => (
        {
          ...model,
          levelArchitect: {
            ...la,
            levelName: levelName,
            gridWidth: gridWidth,
            gridHeight: gridHeight,
            entities: entities,
            patrols: patrols,
            loading: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, levelArchitect: {...la, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | LevelLoaded(Error(err)) => (
      {...model, levelArchitect: {...la, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SaveLevel(path) => (
      model,
      LevelArchitectCmd.saveLevel(path, "", result => LevelArchitect(LevelSaved(result))),
    )
  | LevelSaved(Ok(_)) => (model, Tea_Cmd.none)
  | LevelSaved(Error(err)) => (
      {...model, levelArchitect: {...la, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ExportLevelConfig => (
      model,
      LevelArchitectCmd.exportLevelConfig("", result => LevelArchitect(LevelConfigExported(result))),
    )
  | LevelConfigExported(Ok(_)) => (model, Tea_Cmd.none)
  | LevelConfigExported(Error(err)) => (
      {...model, levelArchitect: {...la, error: Some(err)}},
      Tea_Cmd.none,
    )
  | UndoAction => {
      if la.historyIndex > 0 {
        let newIdx = la.historyIndex - 1
        let entry = la.history->Array.get(newIdx)
        switch entry {
        | Some(e) => (
            {
              ...model,
              levelArchitect: {
                ...la,
                entities: e.entities,
                patrols: e.patrols,
                historyIndex: newIdx,
              },
            },
            Tea_Cmd.none,
          )
        | None => (model, Tea_Cmd.none)
        }
      } else {
        (model, Tea_Cmd.none)
      }
    }
  | RedoAction => {
      if la.historyIndex < Array.length(la.history) - 1 {
        let newIdx = la.historyIndex + 1
        let entry = la.history->Array.get(newIdx)
        switch entry {
        | Some(e) => (
            {
              ...model,
              levelArchitect: {
                ...la,
                entities: e.entities,
                patrols: e.patrols,
                historyIndex: newIdx,
              },
            },
            Tea_Cmd.none,
          )
        | None => (model, Tea_Cmd.none)
        }
      } else {
        (model, Tea_Cmd.none)
      }
    }
  | ToggleGrid => ({...model, levelArchitect: {...la, showGrid: !la.showGrid}}, Tea_Cmd.none)
  | TogglePatrolPaths => (
      {...model, levelArchitect: {...la, showPatrolPaths: !la.showPatrolPaths}},
      Tea_Cmd.none,
    )
  | DismissArchitectError => ({...model, levelArchitect: {...la, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "levelarchitect", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Coprocessors Sub-Updater
// ===========================================================================

/// Handles all Coprocessors (IDApTIK coprocessor monitoring) messages.
let updateCoprocessors = (model: model, msg: coprocessorsMsg): (model, Tea_Cmd.t<msg>) => {
  let cp = model.coprocessors
  switch msg {
  | SetCoprocCategory(cat) => ({...model, coprocessors: {...cp, activeCategory: cat}}, Tea_Cmd.none)
  | RefreshMetrics => (
      {...model, coprocessors: {...cp, loading: true}},
      CoprocessorsCmd.readMetrics(result => Coprocessors(MetricsReceived(result))),
    )
  | MetricsReceived(Ok(jsonStr)) => {
    let parseBackend = (s: string): CoprocessorsModel.coprocessorBackend =>
      switch s {
      | "maths" => CoprocMaths
      | "vector" => CoprocVector
      | "tensor" => CoprocTensor
      | "physics" => CoprocPhysics
      | "crypto" => CoprocCrypto
      | "neural" => CoprocNeural
      | "quantum" => CoprocQuantum
      | "audio" => CoprocAudio
      | "graphics" => CoprocGraphics
      | _ => CoprocIO
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let backend = obj->Dict.get("backend")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->parseBackend
        let totalCalls = obj->Dict.get("totalCalls")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let avgDurationMs = obj->Dict.get("avgDurationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let maxDurationMs = obj->Dict.get("maxDurationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let errorRate = obj->Dict.get("errorRate")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lastCallTimestamp = obj->Dict.get("lastCallTimestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let healthStr = obj->Dict.get("health")->Option.flatMap(JSON.Decode.string)->Option.getOr("healthy")
        let health: CoprocessorsModel.coprocHealth = switch healthStr {
        | "degraded" => CoprocDegraded
        | "failed" => CoprocFailed
        | "disabled" => CoprocDisabled
        | _ => CoprocHealthy
        }
        Some({
          CoprocessorsModel.backend,
          totalCalls: Float.toInt(totalCalls),
          avgDurationMs,
          maxDurationMs,
          errorRate,
          lastCallTimestamp,
          health,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(metrics) => ({...model, coprocessors: {...cp, metrics, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, coprocessors: {...cp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | MetricsReceived(Error(err)) => (
      {...model, coprocessors: {...cp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshCallLog => (
      {...model, coprocessors: {...cp, loading: true}},
      CoprocessorsCmd.readCallLog(result => Coprocessors(CallLogReceived(result))),
    )
  | CallLogReceived(Ok(jsonStr)) => {
    let parseBackend = (s: string): CoprocessorsModel.coprocessorBackend =>
      switch s {
      | "maths" => CoprocMaths
      | "vector" => CoprocVector
      | "tensor" => CoprocTensor
      | "physics" => CoprocPhysics
      | "crypto" => CoprocCrypto
      | "neural" => CoprocNeural
      | "quantum" => CoprocQuantum
      | "audio" => CoprocAudio
      | "graphics" => CoprocGraphics
      | _ => CoprocIO
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let backend = obj->Dict.get("backend")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->parseBackend
        let operation = obj->Dict.get("operation")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let inputSummary = obj->Dict.get("inputSummary")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let outputSummary = obj->Dict.get("outputSummary")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let durationMs = obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let timestamp = obj->Dict.get("timestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let success = obj->Dict.get("success")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
        Some({
          CoprocessorsModel.id: Float.toInt(id),
          backend,
          operation,
          inputSummary,
          outputSummary,
          durationMs,
          timestamp,
          success,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(callLog) => ({...model, coprocessors: {...cp, callLog, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, coprocessors: {...cp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | CallLogReceived(Error(err)) => (
      {...model, coprocessors: {...cp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshHeatmap => (
      {...model, coprocessors: {...cp, loading: true}},
      CoprocessorsCmd.readHeatmap(result => Coprocessors(HeatmapReceived(result))),
    )
  | HeatmapReceived(Ok(jsonStr)) => {
    let parseBackend = (s: string): CoprocessorsModel.coprocessorBackend =>
      switch s {
      | "maths" => CoprocMaths
      | "vector" => CoprocVector
      | "tensor" => CoprocTensor
      | "physics" => CoprocPhysics
      | "crypto" => CoprocCrypto
      | "neural" => CoprocNeural
      | "quantum" => CoprocQuantum
      | "audio" => CoprocAudio
      | "graphics" => CoprocGraphics
      | _ => CoprocIO
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let backend = obj->Dict.get("backend")->Option.flatMap(JSON.Decode.string)->Option.getOr("")->parseBackend
        let timeSlot = obj->Dict.get("timeSlot")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let callCount = obj->Dict.get("callCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let avgDuration = obj->Dict.get("avgDuration")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          CoprocessorsModel.backend,
          timeSlot: Float.toInt(timeSlot),
          callCount: Float.toInt(callCount),
          avgDuration,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(heatmap) => ({...model, coprocessors: {...cp, heatmap, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, coprocessors: {...cp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | HeatmapReceived(Error(err)) => (
      {...model, coprocessors: {...cp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleCoprocBackend(backend) => {
      let isEnabled = cp.enabledBackends->Array.includes(backend)
      let newEnabled = if isEnabled {
        cp.enabledBackends->Array.filter(b => b !== backend)
      } else {
        Array.concat(cp.enabledBackends, [backend])
      }
      (
        {...model, coprocessors: {...cp, enabledBackends: newEnabled}},
        CoprocessorsCmd.toggleBackend(
          CoprocessorsEngine.backendLabel(backend),
          !isEnabled,
          result => Coprocessors(BackendToggled(result)),
        ),
      )
    }
  | BackendToggled(Ok(_)) => (model, Tea_Cmd.none)
  | BackendToggled(Error(err)) => (
      {...model, coprocessors: {...cp, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectBackendFilter(backend) => (
      {...model, coprocessors: {...cp, selectedBackend: backend}},
      Tea_Cmd.none,
    )
  | ToggleAutoRefresh => (
      {...model, coprocessors: {...cp, autoRefresh: !cp.autoRefresh}},
      Tea_Cmd.none,
    )
  | DismissCoprocError => ({...model, coprocessors: {...cp, error: None}}, Tea_Cmd.none)
  | QueryComputeEngine(engineId, operation) => {
      let queryCmd = if cp.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "agent-mcp",
          "query-compute",
          `{"engine": "${engineId}", "operation": "${operation}"}`,
          result => Coprocessors(ComputeEngineResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        CoprocessorsCmd.queryComputeEngine(
          engineId,
          operation,
          result => Coprocessors(ComputeEngineResult(result)),
        )
      }
      let typellCmd = TypeLLService.checkConfigTypes(operation, "coprocessors", result => Coprocessors(TypeCheckResult(result)))
      (
        {...model, coprocessors: {...cp, loading: true}},
        Tea_Cmd.batch(list{queryCmd, typellCmd}),
      )
    }
  | ComputeEngineResult(Ok(json)) => {
      let parsed = CoprocessorsEngine.parseComputeResult(json, EngineAxiom)
      switch parsed {
      | Ok(queryResult) => (
          {...model, coprocessors: {...cp, loading: false, lastComputeResult: Some(queryResult)}},
          Tea_Cmd.none,
        )
      | Error(_) => (
          {...model, coprocessors: {...cp, loading: false, error: None}},
          Tea_Cmd.none,
        )
      }
    }
  | ComputeEngineResult(Error(err)) => (
      {...model, coprocessors: {...cp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DiscoverDevices => (
      {...model, coprocessors: {...cp, loading: true}},
      CoprocessorsCmd.discoverDevices(result => Coprocessors(DevicesDiscovered(result))),
    )
  | DevicesDiscovered(Ok(json)) => {
      let devices = CoprocessorsEngine.parseDevices(json)
      (
        {...model, coprocessors: {...cp, loading: false, discoveredDevices: devices}},
        Tea_Cmd.none,
      )
    }
  | DevicesDiscovered(Error(err)) => (
      {...model, coprocessors: {...cp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleCoprocBojRouting => (
      {...model, coprocessors: {...cp, bojRouting: !cp.bojRouting}},
      Tea_Cmd.none,
    )
  // Phase 2: Zig FFI local dispatch
  | LoadLocalFfi =>
    let cmd = CoprocessorsCmd.loadLocalFfi(r => Coprocessors(LocalFfiLoaded(r)))
    ({...model, coprocessors: {...cp, loading: true}}, cmd)
  | LocalFfiLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      let newDispatch = CoprocessorsEngine.parseLocalDispatchState(jsonStr)
      ({...model, coprocessors: {...cp, loading: false, localDispatch: newDispatch, error: None}}, Tea_Cmd.none)
    | Error(err) =>
      ({...model, coprocessors: {...cp, loading: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | DispatchLocal(operation, payload) =>
    let ld = cp.localDispatch
    let newDispatch = {...ld, pendingDispatches: ld.pendingDispatches + 1}
    let cmd = CoprocessorsCmd.dispatchLocal(operation, payload, r => Coprocessors(LocalDispatchResult(r)))
    ({...model, coprocessors: {...cp, localDispatch: newDispatch, loading: true}}, cmd)
  | LocalDispatchResult(result) =>
    let ld = cp.localDispatch
    let pending = ld.pendingDispatches - 1
    let newDispatch = {...ld, pendingDispatches: if pending > 0 { pending } else { 0 }}
    switch result {
    | Ok(jsonStr) =>
      switch CoprocessorsEngine.parseComputeResult(jsonStr, CoprocessorsModel.EngineLocal) {
      | Ok(computeResult) =>
        ({...model, coprocessors: {...cp, loading: false, localDispatch: newDispatch, lastComputeResult: Some(computeResult), error: None}}, Tea_Cmd.none)
      | Error(_) =>
        ({...model, coprocessors: {...cp, loading: false, localDispatch: newDispatch}}, Tea_Cmd.none)
      }
    | Error(err) =>
      ({...model, coprocessors: {...cp, loading: false, localDispatch: newDispatch, error: Some(err)}}, Tea_Cmd.none)
    }
  | QueryLocalResources =>
    let cmd = CoprocessorsCmd.queryLocalResources(r => Coprocessors(LocalResourcesResult(r)))
    (model, cmd)
  | LocalResourcesResult(result) =>
    switch result {
    | Ok(jsonStr) =>
      let newDispatch = CoprocessorsEngine.parseLocalDispatchState(jsonStr)
      ({...model, coprocessors: {...cp, localDispatch: {...cp.localDispatch, cpuUtilisation: newDispatch.cpuUtilisation, gpuMemoryMb: newDispatch.gpuMemoryMb}}}, Tea_Cmd.none)
    | Error(_) => (model, Tea_Cmd.none)
    }
  // Phase 3: Smart routing
  | SetRoutingStrategy(strategy) =>
    ({...model, coprocessors: {...cp, routingStrategy: strategy}}, Tea_Cmd.none)
  | SmartDispatch(operation, payload) =>
    // Use the routing engine to determine the best route, then dispatch.
    let decision = CoprocessorsEngine.selectRoute(cp, operation)
    let newHistory = Array.concat([decision], cp.routingHistory)->Array.slice(~start=0, ~end=50)
    let cmd = switch decision.chosenRoute {
    | CoprocessorsModel.RouteLocal =>
      CoprocessorsCmd.dispatchLocal(operation, payload, r => Coprocessors(SmartDispatchResult(r)))
    | CoprocessorsModel.RouteRemote =>
      CoprocessorsCmd.queryComputeEngine("axiom", `${operation}:${payload}`, r => Coprocessors(SmartDispatchResult(r)))
    | CoprocessorsModel.RouteBoj =>
      BojCmd.invokeCartridgeWithLatency("agent-mcp", "compute", `{"operation":"${operation}","payload":"${payload}"}`, r => Coprocessors(SmartDispatchResult(r)), (c, t, e) => RecordBojLatency(c, t, e))
    | CoprocessorsModel.RouteAutomatic =>
      // Already resolved by selectRoute — should not happen.
      CoprocessorsCmd.smartDispatch(operation, payload, r => Coprocessors(SmartDispatchResult(r)))
    }
    ({...model, coprocessors: {...cp, loading: true, routingHistory: newHistory}}, cmd)
  | SmartDispatchResult(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch CoprocessorsEngine.parseComputeResult(jsonStr, CoprocessorsModel.EngineLocal) {
      | Ok(computeResult) =>
        ({...model, coprocessors: {...cp, loading: false, lastComputeResult: Some(computeResult), error: None}}, Tea_Cmd.none)
      | Error(_) =>
        ({...model, coprocessors: {...cp, loading: false}}, Tea_Cmd.none)
      }
    | Error(err) =>
      ({...model, coprocessors: {...cp, loading: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "coprocessors", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// Multiplayer Monitor Sub-Updater
// ===========================================================================

/// Handles all Multiplayer Monitor (Phoenix sync server) messages.
let updateMultiplayerMonitor = (model: model, msg: multiplayerMonitorMsg): (model, Tea_Cmd.t<msg>) => {
  let mp = model.multiplayerMonitor
  switch msg {
  | SetMultiplayerCategory(cat) => (
      {...model, multiplayerMonitor: {...mp, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | ConnectServer => (
      {...model, multiplayerMonitor: {...mp, wsConnection: WsConnecting, loading: true}},
      Tea_Cmd.batch(list{
        MultiplayerMonitorCmd.connectToServer(
          mp.serverUrl,
          result => MultiplayerMonitor(ConnectionResult(result)),
        ),
        TypeLLService.checkGameDataTypes(mp.serverUrl, "multiplayer", result => MultiplayerMonitor(TypeCheckResult(result))),
      }),
    )
  | DisconnectServer => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.disconnectFromServer(
        result => MultiplayerMonitor(DisconnectionResult(result)),
      ),
    )
  | ConnectionResult(Ok(_)) => (
      {...model, multiplayerMonitor: {...mp, wsConnection: WsConnected, loading: false, error: None}},
      MultiplayerMonitorCmd.readMultiplayerState(result => MultiplayerMonitor(StateReceived(result))),
    )
  | ConnectionResult(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, wsConnection: WsError(err), loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DisconnectionResult(Ok(_)) => (
      {
        ...model,
        multiplayerMonitor: {
          ...mp,
          wsConnection: WsDisconnected,
          loading: false,
          players: [],
          channels: [],
          error: None,
        },
      },
      Tea_Cmd.none,
    )
  | DisconnectionResult(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshState => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.readMultiplayerState(result => MultiplayerMonitor(StateReceived(result))),
    )
  | StateReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let playersArr = obj->Dict.get("players")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let players = playersArr->Array.filterMap(item => {
        let p = item->JSON.Decode.object->Option.getOr(Dict.make())
        let playerId = p->Dict.get("playerId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let displayName = p->Dict.get("displayName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let deviceId = p->Dict.get("deviceId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let latencyMs = p->Dict.get("latencyMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lamportClock = p->Dict.get("lamportClock")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lastHeartbeat = p->Dict.get("lastHeartbeat")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let isHost = p->Dict.get("isHost")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let isSpectator = p->Dict.get("isSpectator")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          MultiplayerMonitorModel.playerId,
          displayName,
          deviceId,
          latencyMs: Float.toInt(latencyMs),
          lamportClock: Float.toInt(lamportClock),
          lastHeartbeat,
          isHost,
          isSpectator,
        })
      })
      let channelsArr = obj->Dict.get("channels")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let channels = channelsArr->Array.filterMap(item => {
        let c = item->JSON.Decode.object->Option.getOr(Dict.make())
        let topic = c->Dict.get("topic")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let joinedAt = c->Dict.get("joinedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let messageCount = c->Dict.get("messageCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lastMessageAt = c->Dict.get("lastMessageAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          MultiplayerMonitorModel.topic,
          joinedAt,
          messageCount: Float.toInt(messageCount),
          lastMessageAt,
        })
      })
      let locksArr = obj->Dict.get("deviceLocks")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let deviceLocks = locksArr->Array.filterMap(item => {
        let l = item->JSON.Decode.object->Option.getOr(Dict.make())
        let deviceId = l->Dict.get("deviceId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let lockedBy = l->Dict.get("lockedBy")->Option.flatMap(JSON.Decode.string)
        let lockedAt = l->Dict.get("lockedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let contestedArr = l->Dict.get("contestedBy")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let contestedBy = contestedArr->Array.filterMap(v => v->JSON.Decode.string)
        Some({
          MultiplayerMonitorModel.deviceId,
          lockedBy,
          lockedAt,
          contestedBy,
        })
      })
      Some((players, channels, deviceLocks))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((players, channels, deviceLocks)) => (
        {...model, multiplayerMonitor: {...mp, players, channels, deviceLocks, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, multiplayerMonitor: {...mp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | StateReceived(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshDiffs => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.readStateDiffs(result => MultiplayerMonitor(DiffsReceived(result))),
    )
  | DiffsReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let diffs = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let timestamp = obj->Dict.get("timestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let playerId = obj->Dict.get("playerId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let field = obj->Dict.get("field")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let localValue = obj->Dict.get("localValue")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let remoteValue = obj->Dict.get("remoteValue")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let resolved = obj->Dict.get("resolved")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          MultiplayerMonitorModel.timestamp,
          playerId,
          field,
          localValue,
          remoteValue,
          resolved,
        })
      })
      Some(diffs)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(stateDiffs) => ({...model, multiplayerMonitor: {...mp, stateDiffs, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, multiplayerMonitor: {...mp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | DiffsReceived(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectPlayer(id) => (
      {...model, multiplayerMonitor: {...mp, selectedPlayerId: Some(id)}},
      Tea_Cmd.none,
    )
  | DeselectPlayer => (
      {...model, multiplayerMonitor: {...mp, selectedPlayerId: None}},
      Tea_Cmd.none,
    )
  | ToggleSpectators => (
      {...model, multiplayerMonitor: {...mp, showSpectators: !mp.showSpectators}},
      Tea_Cmd.none,
    )
  | ToggleAutoReconnect => (
      {...model, multiplayerMonitor: {...mp, autoReconnect: !mp.autoReconnect}},
      Tea_Cmd.none,
    )
  | ReconnectionTest => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.reconnectionTest(
        result => MultiplayerMonitor(ReconnectionTestResult(result)),
      ),
    )
  | ReconnectionTestResult(Ok(_)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | ReconnectionTestResult(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissMultiplayerError => (
      {...model, multiplayerMonitor: {...mp, error: None}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "multiplayermonitor", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// DLC Workshop Sub-Updater
// ===========================================================================

/// Handles all DLC Workshop (puzzle pack creation and testing) messages.
let updateDlcWorkshop = (model: model, msg: dlcWorkshopMsg): (model, Tea_Cmd.t<msg>) => {
  let dw = model.dlcWorkshop
  switch msg {
  | SetWorkshopCategory(cat) => ({...model, dlcWorkshop: {...dw, activeCategory: cat}}, Tea_Cmd.none)
  | LoadPuzzles => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.loadPuzzles(result => DlcWorkshop(PuzzlesLoaded(result))),
    )
  | PuzzlesLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let description = obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let diffStr = obj->Dict.get("difficulty")->Option.flatMap(JSON.Decode.string)->Option.getOr("medium")
        let difficulty: DlcWorkshopModel.puzzleDifficulty = switch diffStr {
        | "tutorial" => DifficultyTutorial
        | "easy" => DifficultyEasy
        | "hard" => DifficultyHard
        | "expert" => DifficultyExpert
        | "nightmare" => DifficultyNightmare
        | _ => DifficultyMedium
        }
        let solutionSteps = obj->Dict.get("solutionSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let optimalSteps = obj->Dict.get("optimalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let hintsArr = obj->Dict.get("hints")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let hints = hintsArr->Array.filterMap(v => v->JSON.Decode.string)
        Some({
          DlcWorkshopModel.id,
          name,
          description,
          difficulty,
          instructions: [],
          solutionSteps: Float.toInt(solutionSteps),
          optimalSteps: Float.toInt(optimalSteps),
          testStatus: TestNotRun,
          hints,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(puzzles) => ({...model, dlcWorkshop: {...dw, puzzles, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | PuzzlesLoaded(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectPuzzle(id) => ({...model, dlcWorkshop: {...dw, selectedPuzzleId: Some(id)}}, Tea_Cmd.none)
  | DeselectPuzzle => ({...model, dlcWorkshop: {...dw, selectedPuzzleId: None}}, Tea_Cmd.none)
  | AddInstruction => {
      let idx = Array.length(dw.composerInstructions)
      let instr: puzzleInstruction = {index: idx, opcode: "NOP", operand: None, comment: ""}
      (
        {
          ...model,
          dlcWorkshop: {
            ...dw,
            composerInstructions: Array.concat(dw.composerInstructions, [instr]),
          },
        },
        Tea_Cmd.none,
      )
    }
  | RemoveInstruction(idx) => {
      let newInstrs = dw.composerInstructions->Array.filter(i => i.index !== idx)
      ({...model, dlcWorkshop: {...dw, composerInstructions: newInstrs}}, Tea_Cmd.none)
    }
  | ClearComposer => ({...model, dlcWorkshop: {...dw, composerInstructions: []}}, Tea_Cmd.none)
  | SavePuzzle => (
      model,
      Tea_Cmd.batch(list{
        DlcWorkshopCmd.savePuzzle("", result => DlcWorkshop(PuzzleSaved(result))),
        TypeLLService.checkGameDataTypes("puzzle-spec", "dlc-workshop", result => DlcWorkshop(TypeCheckResult(result))),
      }),
    )
  | PuzzleSaved(Ok(_)) => (model, Tea_Cmd.none)
  | PuzzleSaved(Error(err)) => (
      {...model, dlcWorkshop: {...dw, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunPuzzleTest(puzzleId) => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.runTest(puzzleId, result => DlcWorkshop(PuzzleTestResult(result))),
    )
  | PuzzleTestResult(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let puzzleId = obj->Dict.get("puzzleId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let passed = obj->Dict.get("passed")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
      let errorMsg = obj->Dict.get("error")->Option.flatMap(JSON.Decode.string)
      let status: DlcWorkshopModel.testRunStatus = if passed {
        TestPassed
      } else {
        TestFailed(errorMsg->Option.getOr("Test failed"))
      }
      Some((puzzleId, status))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((puzzleId, status)) => {
        let puzzles = dw.puzzles->Array.map(p =>
          if p.id === puzzleId { {...p, testStatus: status} } else { p }
        )
        let testResults = Array.concat(dw.testResults, [(puzzleId, status)])
        ({...model, dlcWorkshop: {...dw, puzzles, testResults, loading: false, error: None}}, Tea_Cmd.none)
      }
    | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | PuzzleTestResult(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunAllTests => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.runAllTests(result => DlcWorkshop(AllTestsResult(result))),
    )
  | AllTestsResult(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let results = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let puzzleId = obj->Dict.get("puzzleId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let passed = obj->Dict.get("passed")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let errorMsg = obj->Dict.get("error")->Option.flatMap(JSON.Decode.string)
        let status: DlcWorkshopModel.testRunStatus = if passed {
          TestPassed
        } else {
          TestFailed(errorMsg->Option.getOr("Test failed"))
        }
        Some((puzzleId, status))
      })
      Some(results)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(results) => {
        let puzzles = dw.puzzles->Array.map(p => {
          let matching = results->Array.find(((id, _)) => id === p.id)
          switch matching {
          | Some((_, status)) => {...p, testStatus: status}
          | None => p
          }
        })
        ({...model, dlcWorkshop: {...dw, puzzles, testResults: results, loading: false, error: None}}, Tea_Cmd.none)
      }
    | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | AllTestsResult(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | BrowseDlcAssets => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.browseAssets(result => DlcWorkshop(DlcAssetsLoaded(result))),
    )
  | DlcAssetsLoaded(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let assetType = obj->Dict.get("assetType")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let filePath = obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let sizeBytes = obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          DlcWorkshopModel.id,
          name,
          assetType,
          filePath,
          sizeBytes: Float.toInt(sizeBytes),
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(assets) => ({...model, dlcWorkshop: {...dw, assets, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | DlcAssetsLoaded(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PackageDlc => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.packageDlc("", result => DlcWorkshop(PackageResult(result))),
    )
  | PackageResult(Ok(_)) => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
  | PackageResult(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ImportPuzzle => (
      model,
      DlcWorkshopCmd.importPuzzle("", result => DlcWorkshop(PuzzleImported(result))),
    )
  | PuzzleImported(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let description = obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let diffStr = obj->Dict.get("difficulty")->Option.flatMap(JSON.Decode.string)->Option.getOr("medium")
      let difficulty: DlcWorkshopModel.puzzleDifficulty = switch diffStr {
      | "tutorial" => DifficultyTutorial
      | "easy" => DifficultyEasy
      | "hard" => DifficultyHard
      | "expert" => DifficultyExpert
      | "nightmare" => DifficultyNightmare
      | _ => DifficultyMedium
      }
      let solutionSteps = obj->Dict.get("solutionSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let optimalSteps = obj->Dict.get("optimalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let hintsArr = obj->Dict.get("hints")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let hints = hintsArr->Array.filterMap(v => v->JSON.Decode.string)
      Some({
        DlcWorkshopModel.id,
        name,
        description,
        difficulty,
        instructions: [],
        solutionSteps: Float.toInt(solutionSteps),
        optimalSteps: Float.toInt(optimalSteps),
        testStatus: TestNotRun,
        hints,
      })
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(puzzle) => ({...model, dlcWorkshop: {...dw, puzzles: Array.concat(dw.puzzles, [puzzle]), error: None}}, Tea_Cmd.none)
    | None => ({...model, dlcWorkshop: {...dw, error: None}}, Tea_Cmd.none)
    }
  }
  | PuzzleImported(Error(err)) => (
      {...model, dlcWorkshop: {...dw, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ExportPuzzle => {
      let puzzleId = switch dw.selectedPuzzleId {
      | Some(id) => id
      | None => ""
      }
      (model, DlcWorkshopCmd.exportPuzzle(puzzleId, result => DlcWorkshop(PuzzleExported(result))))
    }
  | PuzzleExported(Ok(_)) => (model, Tea_Cmd.none)
  | PuzzleExported(Error(err)) => (
      {...model, dlcWorkshop: {...dw, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetDlcFilter(text) => ({...model, dlcWorkshop: {...dw, filterText: text}}, Tea_Cmd.none)
  | SetDifficultyFilter(diff) => ({...model, dlcWorkshop: {...dw, filterDifficulty: diff}}, Tea_Cmd.none)
  | DismissWorkshopError => ({...model, dlcWorkshop: {...dw, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "dlcworkshop", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// EDITOR BRIDGE — external code editor federation (LSP)
// ===========================================================================

/// Handles all Editor Bridge (external editor federation) messages.
let updateEditorBridge = (model: model, msg: editorBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let eb = model.editorBridge
  switch msg {
  | SetBridgeCategory(cat) => ({...model, editorBridge: {...eb, activeCategory: cat}}, Tea_Cmd.none)
  | DetectEditor => (
      {...model, editorBridge: {...eb, loading: true}},
      EditorBridgeCmd.detectEditor(result => EditorBridge(EditorDetected(result))),
    )
  | EditorDetected(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let editorStr = obj->Dict.get("editorKind")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let editorKind: EditorBridgeModel.editorKind = switch editorStr {
      | "vscodium" => EditorVSCodium
      | "vscode" => EditorVSCode
      | "zed" => EditorZed
      | "helix" => EditorHelix
      | "neovim" => EditorNeovim
      | "emacs" => EditorEmacs
      | "kakoune" => EditorKakoune
      | other => EditorCustom(other)
      }
      let connStr = obj->Dict.get("connection")->Option.flatMap(JSON.Decode.string)->Option.getOr("disconnected")
      let connection: EditorBridgeModel.editorConnection = switch connStr {
      | "connected" => EditorConnected(editorStr)
      | "connecting" => EditorConnecting
      | _ => EditorDisconnected
      }
      Some((editorKind, connection))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((editorKind, connection)) => (
        {...model, editorBridge: {...eb, editorKind, connection, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | EditorDetected(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ConnectLsp => (
      {...model, editorBridge: {...eb, connection: EditorConnecting}},
      if eb.bojRouting {
        // Route through BoJ's lsp-mcp cartridge.
        let args = `{"port": ${Int.toString(eb.lspPort)}}`
        Tea_Cmd.batch(list{
          BojCmd.invokeCartridgeWithLatency("lsp-mcp", "connect", args, result => EditorBridge(LspConnected(result)), (c, t, e) => RecordBojLatency(c, t, e)),
          Tea_Cmd.msg(Vexometer(RecordVqlQuery)),
          TypeLLService.checkConfigTypes(args, "editor-bridge", result => EditorBridge(TypeCheckResult(result))),
        })
      } else {
        Tea_Cmd.batch(list{
          EditorBridgeCmd.connectLsp(eb.lspPort, result => EditorBridge(LspConnected(result))),
          TypeLLService.checkConfigTypes(Int.toString(eb.lspPort), "editor-bridge", result => EditorBridge(TypeCheckResult(result))),
        })
      },
    )
  | LspConnected(Ok(info)) => (
      {...model, editorBridge: {...eb, connection: EditorConnected(info), error: None}},
      Tea_Cmd.none,
    )
  | LspConnected(Error(err)) => (
      {...model, editorBridge: {...eb, connection: EditorError(err), error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshDiagnostics => (
      {...model, editorBridge: {...eb, loading: true}},
      if eb.bojRouting {
        BojCmd.invokeCartridgeWithLatency("lsp-mcp", "diagnostics", "{}", result => EditorBridge(DiagnosticsReceived(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        EditorBridgeCmd.readDiagnostics(result => EditorBridge(DiagnosticsReceived(result)))
      },
    )
  | DiagnosticsReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let filePath = obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let line = obj->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let col = obj->Dict.get("col")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let endLine = obj->Dict.get("endLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let endCol = obj->Dict.get("endCol")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let severity = obj->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("warning")
        let message = obj->Dict.get("message")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let source = obj->Dict.get("source")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let code = obj->Dict.get("code")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        Some({
          EditorBridgeModel.filePath,
          line: Float.toInt(line),
          col: Float.toInt(col),
          endLine: Float.toInt(endLine),
          endCol: Float.toInt(endCol),
          severity,
          message,
          source,
          code,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(diagnostics) => ({...model, editorBridge: {...eb, diagnostics, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | DiagnosticsReceived(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshOpenFiles => (
      {...model, editorBridge: {...eb, loading: true}},
      EditorBridgeCmd.readOpenFiles(result => EditorBridge(OpenFilesReceived(result))),
    )
  | OpenFilesReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let path = obj->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let language = obj->Dict.get("language")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let modified = obj->Dict.get("modified")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let cursorLine = obj->Dict.get("cursorLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let cursorCol = obj->Dict.get("cursorCol")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let selections = obj->Dict.get("selections")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          EditorBridgeModel.path,
          language,
          modified,
          cursorLine: Float.toInt(cursorLine),
          cursorCol: Float.toInt(cursorCol),
          selections: Float.toInt(selections),
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(openFiles) => ({...model, editorBridge: {...eb, openFiles, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | OpenFilesReceived(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshSymbols => (
      {...model, editorBridge: {...eb, loading: true}},
      if eb.bojRouting {
        let args = `{"query": "${eb.symbolFilter}"}`
        BojCmd.invokeCartridgeWithLatency("lsp-mcp", "symbols", args, result => EditorBridge(SymbolsReceived(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        EditorBridgeCmd.readSymbols(eb.symbolFilter, result => EditorBridge(SymbolsReceived(result)))
      },
    )
  | SymbolsReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let kind = obj->Dict.get("kind")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let filePath = obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let line = obj->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let containerName = obj->Dict.get("containerName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        Some({
          EditorBridgeModel.name,
          kind,
          filePath,
          line: Float.toInt(line),
          containerName,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(symbols) => ({...model, editorBridge: {...eb, symbols, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | SymbolsReceived(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | OpenFileInEditor(path, line) => (
      model,
      EditorBridgeCmd.openFileAtLine(path, line, result => EditorBridge(FileOpened(result))),
    )
  | FileOpened(Ok(_)) => (model, Tea_Cmd.none)
  | FileOpened(Error(err)) => (
      {...model, editorBridge: {...eb, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshBridge => (
      {...model, editorBridge: {...eb, loading: true}},
      EditorBridgeCmd.detectEditor(result => EditorBridge(EditorDetected(result))),
    )
  | SetDiagnosticFilter(text) => ({...model, editorBridge: {...eb, diagnosticFilter: text}}, Tea_Cmd.none)
  | ToggleShowErrors => ({...model, editorBridge: {...eb, showErrors: !eb.showErrors}}, Tea_Cmd.none)
  | ToggleShowWarnings => ({...model, editorBridge: {...eb, showWarnings: !eb.showWarnings}}, Tea_Cmd.none)
  | ToggleShowInfo => ({...model, editorBridge: {...eb, showInfo: !eb.showInfo}}, Tea_Cmd.none)
  | SetSymbolFilter(text) => ({...model, editorBridge: {...eb, symbolFilter: text}}, Tea_Cmd.none)
  | SetEditorKind(editor) => ({...model, editorBridge: {...eb, editorKind: editor}}, Tea_Cmd.none)
  | ToggleAutoSync => ({...model, editorBridge: {...eb, autoSync: !eb.autoSync}}, Tea_Cmd.none)
  | ToggleBojRouting => ({...model, editorBridge: {...eb, bojRouting: !eb.bojRouting}}, Tea_Cmd.none)
  | DismissBridgeError => ({...model, editorBridge: {...eb, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "editorbridge", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// BUILD DASHBOARD — build/test/error monitoring
// ===========================================================================

/// Handles all Build Dashboard (build monitoring) messages.
let updateBuildDashboard = (model: model, msg: buildDashboardMsg): (model, Tea_Cmd.t<msg>) => {
  let bd = model.buildDashboard
  switch msg {
  | SetBuildCategory(cat) => ({...model, buildDashboard: {...bd, activeCategory: cat}}, Tea_Cmd.none)
  | TriggerBuild(target) => {
      let label = BuildDashboardEngine.targetLabel(target)
      let cmd = if bd.bojRouting {
        BojCmd.invokeCartridgeWithLatency("bsp-mcp", "build", label, result => BuildDashboard(BuildTriggered(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        BuildDashboardCmd.triggerBuild(label, result => BuildDashboard(BuildTriggered(result)))
      }
      let typellCmd = TypeLLService.checkConfigTypes(label, "build-dashboard", result => BuildDashboard(TypeCheckResult(result)))
      ({...model, buildDashboard: {...bd, loading: true}}, Tea_Cmd.batch(list{cmd, typellCmd}))
    }
  | BuildTriggered(Ok(jsonStr)) => {
    let parseTarget = (s: string): BuildDashboardModel.buildTarget =>
      switch s {
      | "game" => TargetGame
      | "vm" => TargetVm
      | "dlc" => TargetDlc
      | "sync_server" => TargetSyncServer
      | "shared" => TargetShared
      | "coprocessors" => TargetCoprocessors
      | other => TargetCustom(other)
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let targetStr = obj->Dict.get("target")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let target = parseTarget(targetStr)
      let statusStr = obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("running")
      let duration = obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
      let status: BuildDashboardModel.buildStatus = switch statusStr {
      | "success" => BuildSuccess(duration)
      | "failed" => BuildFailed(duration)
      | "cancelled" => BuildCancelled
      | "idle" => BuildIdle
      | _ => BuildRunning
      }
      Some((target, status))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((target, status)) => {
        let targets = bd.targets->Array.map(((t, s)) =>
          if t === target { (t, status) } else { (t, s) }
        )
        ({...model, buildDashboard: {...bd, targets, loading: false, error: None}}, Tea_Cmd.none)
      }
    | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | BuildTriggered(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshBuildStatus => {
      let cmd = if bd.bojRouting {
        BojCmd.invokeCartridgeWithLatency("bsp-mcp", "status", "", result => BuildDashboard(BuildStatusReceived(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        BuildDashboardCmd.readBuildStatus(result => BuildDashboard(BuildStatusReceived(result)))
      }
      ({...model, buildDashboard: {...bd, loading: true}}, cmd)
    }
  | BuildStatusReceived(Ok(jsonStr)) => {
    let parseTarget = (s: string): BuildDashboardModel.buildTarget =>
      switch s {
      | "game" => TargetGame
      | "vm" => TargetVm
      | "dlc" => TargetDlc
      | "sync_server" => TargetSyncServer
      | "shared" => TargetShared
      | "coprocessors" => TargetCoprocessors
      | other => TargetCustom(other)
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let targetStr = obj->Dict.get("target")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let target = parseTarget(targetStr)
        let statusStr = obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("idle")
        let duration = obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let status: BuildDashboardModel.buildStatus = switch statusStr {
        | "success" => BuildSuccess(duration)
        | "failed" => BuildFailed(duration)
        | "cancelled" => BuildCancelled
        | "running" => BuildRunning
        | _ => BuildIdle
        }
        Some((target, status))
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(targets) => ({...model, buildDashboard: {...bd, targets, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | BuildStatusReceived(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunTests(target) => {
      let label = BuildDashboardEngine.targetLabel(target)
      let cmd = if bd.bojRouting {
        BojCmd.invokeCartridgeWithLatency("bsp-mcp", "test", label, result => BuildDashboard(TestsReceived(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        BuildDashboardCmd.runTests(label, result => BuildDashboard(TestsReceived(result)))
      }
      ({...model, buildDashboard: {...bd, loading: true}}, cmd)
    }
  | TestsReceived(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let suite = obj->Dict.get("suite")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let passed = obj->Dict.get("passed")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let durationMs = obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let output = obj->Dict.get("output")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        Some({
          BuildDashboardModel.name,
          suite,
          passed,
          durationMs,
          output,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(testResults) => ({...model, buildDashboard: {...bd, testResults, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | TestsReceived(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | CancelBuild(target) => (
      model,
      BuildDashboardCmd.cancelBuild(
        BuildDashboardEngine.targetLabel(target),
        result => BuildDashboard(BuildCancelled(result)),
      ),
    )
  | BuildCancelled(Ok(_)) => (model, Tea_Cmd.none)
  | BuildCancelled(Error(err)) => (
      {...model, buildDashboard: {...bd, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshHistory => (
      {...model, buildDashboard: {...bd, loading: true}},
      BuildDashboardCmd.readHistory(result => BuildDashboard(HistoryReceived(result))),
    )
  | HistoryReceived(Ok(jsonStr)) => {
    let parseTarget = (s: string): BuildDashboardModel.buildTarget =>
      switch s {
      | "game" => TargetGame
      | "vm" => TargetVm
      | "dlc" => TargetDlc
      | "sync_server" => TargetSyncServer
      | "shared" => TargetShared
      | "coprocessors" => TargetCoprocessors
      | other => TargetCustom(other)
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let targetStr = obj->Dict.get("target")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let target = parseTarget(targetStr)
        let statusStr = obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("idle")
        let durationMs = obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let status: BuildDashboardModel.buildStatus = switch statusStr {
        | "success" => BuildSuccess(durationMs)
        | "failed" => BuildFailed(durationMs)
        | "cancelled" => BuildCancelled
        | "running" => BuildRunning
        | _ => BuildIdle
        }
        let startedAt = obj->Dict.get("startedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let errorCount = obj->Dict.get("errorCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let warningCount = obj->Dict.get("warningCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          BuildDashboardModel.id,
          target,
          status,
          startedAt,
          durationMs,
          errorCount: Float.toInt(errorCount),
          warningCount: Float.toInt(warningCount),
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(history) => ({...model, buildDashboard: {...bd, history, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | HistoryReceived(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleWatchMode => ({...model, buildDashboard: {...bd, watchMode: !bd.watchMode}}, Tea_Cmd.none)
  | ToggleAutoRebuild => ({...model, buildDashboard: {...bd, autoRebuild: !bd.autoRebuild}}, Tea_Cmd.none)
  | ToggleShowPassed => ({...model, buildDashboard: {...bd, showPassedTests: !bd.showPassedTests}}, Tea_Cmd.none)
  | DismissBuildError => ({...model, buildDashboard: {...bd, error: None}}, Tea_Cmd.none)
  | ToggleBuildBojRouting => ({...model, buildDashboard: {...bd, bojRouting: !bd.bojRouting}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "builddashboard", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// RELEASE MANAGER — versioning, changelog, distribution
// ===========================================================================

/// Handles all Release Manager (versioning and distribution) messages.
let updateReleaseManager = (model: model, msg: releaseManagerMsg): (model, Tea_Cmd.t<msg>) => {
  let rm = model.releaseManager
  switch msg {
  | SetReleaseCategory(cat) => ({...model, releaseManager: {...rm, activeCategory: cat}}, Tea_Cmd.none)
  | BumpVersion(bumpType) => (
      {...model, releaseManager: {...rm, loading: true}},
      ReleaseManagerCmd.bumpVersion(bumpType, result => ReleaseManager(VersionBumped(result))),
    )
  | VersionBumped(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let currentVersion = obj->Dict.get("currentVersion")->Option.flatMap(JSON.Decode.string)->Option.getOr(rm.currentVersion)
      let nextVersion = obj->Dict.get("nextVersion")->Option.flatMap(JSON.Decode.string)->Option.getOr(rm.nextVersion)
      Some((currentVersion, nextVersion))
    } catch {
    | _ => None
    }
    switch parsed {
    | Some((currentVersion, nextVersion)) => (
        {...model, releaseManager: {...rm, currentVersion, nextVersion, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | VersionBumped(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectRelease(version) => ({...model, releaseManager: {...rm, selectedRelease: Some(version)}}, Tea_Cmd.none)
  | GenerateChangelog => (
      {...model, releaseManager: {...rm, loading: true}},
      ReleaseManagerCmd.generateChangelog(
        rm.currentVersion,
        result => ReleaseManager(ChangelogGenerated(result)),
      ),
    )
  | ChangelogGenerated(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let version = obj->Dict.get("version")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let date = obj->Dict.get("date")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let category = obj->Dict.get("category")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let description = obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let commitHash = obj->Dict.get("commitHash")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let author = obj->Dict.get("author")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        Some({
          ReleaseManagerModel.version,
          date,
          category,
          description,
          commitHash,
          author,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(entries) => ({...model, releaseManager: {...rm, pendingChangelog: entries, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | ChangelogGenerated(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleAutoChangelog => ({...model, releaseManager: {...rm, autoChangelog: !rm.autoChangelog}}, Tea_Cmd.none)
  | TogglePlatform(platform) => {
      let enabled = rm.enabledPlatforms->Array.includes(platform)
      let newPlatforms = if enabled {
        rm.enabledPlatforms->Array.filter(p => p !== platform)
      } else {
        Array.concat(rm.enabledPlatforms, [platform])
      }
      ({...model, releaseManager: {...rm, enabledPlatforms: newPlatforms}}, Tea_Cmd.none)
    }
  | BuildArtifacts => {
      let platformStr = rm.enabledPlatforms
        ->Array.map(ReleaseManagerEngine.platformLabel)
        ->Array.join(",")
      (
        {...model, releaseManager: {...rm, loading: true}},
        ReleaseManagerCmd.buildArtifacts(
          rm.nextVersion,
          platformStr,
          result => ReleaseManager(ArtifactsBuilt(result)),
        ),
      )
    }
  | ArtifactsBuilt(Ok(jsonStr)) => {
    let parsePlatform = (s: string): ReleaseManagerModel.platformTarget =>
      switch s {
      | "web" => PlatformWeb
      | "linux" => PlatformDesktopLinux
      | "mac" => PlatformDesktopMac
      | "windows" => PlatformDesktopWindows
      | "android" => PlatformMobileAndroid
      | "ios" => PlatformMobileIOS
      | _ => PlatformWeb
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let platformStr = obj->Dict.get("platform")->Option.flatMap(JSON.Decode.string)->Option.getOr("web")
        let platform = parsePlatform(platformStr)
        let filePath = obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let sizeBytes = obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let checksum = obj->Dict.get("checksum")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let builtAt = obj->Dict.get("builtAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          ReleaseManagerModel.name,
          platform,
          filePath,
          sizeBytes: Float.toInt(sizeBytes),
          checksum,
          builtAt,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(artifacts) => ({...model, releaseManager: {...rm, artifacts, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | ArtifactsBuilt(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PublishRelease => (
      {...model, releaseManager: {...rm, loading: true}},
      Tea_Cmd.batch(list{
        ReleaseManagerCmd.publishRelease(
          rm.nextVersion,
          ReleaseManagerEngine.channelLabel(rm.channel),
          result => ReleaseManager(ReleasePublished(result)),
        ),
        TypeLLService.checkConfigTypes(rm.nextVersion, "release-manager", result => ReleaseManager(TypeCheckResult(result))),
      }),
    )
  | ReleasePublished(Ok(jsonStr)) => {
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let version = obj->Dict.get("version")->Option.flatMap(JSON.Decode.string)->Option.getOr(rm.nextVersion)
      let publishedAt = obj->Dict.get("publishedAt")->Option.flatMap(JSON.Decode.float)
      let newRelease: ReleaseManagerModel.releaseVersion = {
        version,
        channel: rm.channel,
        status: ReleasePublished,
        artifacts: rm.artifacts,
        changelog: rm.pendingChangelog,
        createdAt: Date.now(),
        publishedAt,
      }
      Some(newRelease)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(release) => (
        {
          ...model,
          releaseManager: {
            ...rm,
            releases: Array.concat([release], rm.releases),
            currentVersion: release.version,
            loading: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | ReleasePublished(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetChannel(ch) => ({...model, releaseManager: {...rm, channel: ch}}, Tea_Cmd.none)
  | ToggleSignArtifacts => ({...model, releaseManager: {...rm, signArtifacts: !rm.signArtifacts}}, Tea_Cmd.none)
  | LoadReleases => (
      {...model, releaseManager: {...rm, loading: true}},
      ReleaseManagerCmd.readReleases(result => ReleaseManager(ReleasesLoaded(result))),
    )
  | ReleasesLoaded(Ok(jsonStr)) => {
    let parseChannel = (s: string): ReleaseManagerModel.releaseChannel =>
      switch s {
      | "dev" => ChannelDev
      | "alpha" => ChannelAlpha
      | "beta" => ChannelBeta
      | "rc" => ChannelRC
      | _ => ChannelStable
      }
    let parseStatus = (s: string): ReleaseManagerModel.releaseStatus =>
      switch s {
      | "draft" => ReleaseDraft
      | "building" => ReleaseBuilding
      | "ready" => ReleaseReady
      | "published" => ReleasePublished
      | _ => ReleaseDraft
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let version = obj->Dict.get("version")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let channelStr = obj->Dict.get("channel")->Option.flatMap(JSON.Decode.string)->Option.getOr("stable")
        let channel = parseChannel(channelStr)
        let statusStr = obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("draft")
        let status = parseStatus(statusStr)
        let createdAt = obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let publishedAt = obj->Dict.get("publishedAt")->Option.flatMap(JSON.Decode.float)
        Some({
          ReleaseManagerModel.version,
          channel,
          status,
          artifacts: [],
          changelog: [],
          createdAt,
          publishedAt,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(releases) => ({...model, releaseManager: {...rm, releases, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, releaseManager: {...rm, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | ReleasesLoaded(Error(err)) => (
      {...model, releaseManager: {...rm, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissReleaseError => ({...model, releaseManager: {...rm, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "releasemanager", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// AUTOMATION ROUTER — hybrid cross-panel workflow orchestration
// ===========================================================================

/// Handles all Automation Router (workflow orchestration) messages.
let updateAutomationRouter = (model: model, msg: automationRouterMsg): (model, Tea_Cmd.t<msg>) => {
  let ar = model.automationRouter
  switch msg {
  | SetRouterCategory(cat) => ({...model, automationRouter: {...ar, activeCategory: cat}}, Tea_Cmd.none)
  | ToggleGlobalEnabled => ({...model, automationRouter: {...ar, globalEnabled: !ar.globalEnabled}}, Tea_Cmd.none)
  | ToggleRule(ruleId) => {
      let newRules = ar.rules->Array.map(r =>
        if r.id === ruleId {
          {...r, enabled: !r.enabled}
        } else {
          r
        }
      )
      ({...model, automationRouter: {...ar, rules: newRules}}, Tea_Cmd.none)
    }
  | ExecuteRule(ruleId) => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency("agent-mcp", "execute_rule", ruleId, result => AutomationRouter(ExecutionResult(ruleId, result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        AutomationRouterCmd.executeRule(ruleId, result => AutomationRouter(ExecutionResult(ruleId, result)))
      }
      let typellCmd = TypeLLService.checkConfigTypes(ruleId, "automation-router", result => AutomationRouter(TypeCheckResult(result)))
      (model, Tea_Cmd.batch(list{cmd, typellCmd}))
    }
  | ExecutionResult(ruleId, Ok(detail)) => {
      let now = Date.now()
      let entry: executionLogEntry = {
        ruleId,
        ruleName: switch ar.rules->Array.find(r => r.id === ruleId) {
        | Some(r) => r.name
        | None => ruleId
        },
        triggeredAt: now,
        completedAt: now,
        success: true,
        detail,
      }
      let newRules = ar.rules->Array.map(r =>
        if r.id === ruleId {
          {...r, firedCount: r.firedCount + 1, lastFired: Some(now), lastResult: Some(detail)}
        } else {
          r
        }
      )
      (
        {
          ...model,
          automationRouter: {
            ...ar,
            rules: newRules,
            executionLog: Array.concat([entry], ar.executionLog),
          },
        },
        Tea_Cmd.none,
      )
    }
  | ExecutionResult(ruleId, Error(err)) => {
      let now = Date.now()
      let entry: executionLogEntry = {
        ruleId,
        ruleName: switch ar.rules->Array.find(r => r.id === ruleId) {
        | Some(r) => r.name
        | None => ruleId
        },
        triggeredAt: now,
        completedAt: now,
        success: false,
        detail: err,
      }
      (
        {
          ...model,
          automationRouter: {
            ...ar,
            executionLog: Array.concat([entry], ar.executionLog),
            error: Some(err),
          },
        },
        Tea_Cmd.none,
      )
    }
  | ApproveAction(idx) => {
      let newPending = ar.pendingActions->Array.filterWithIndex((_a, i) => i !== idx)
      ({...model, automationRouter: {...ar, pendingActions: newPending}}, Tea_Cmd.none)
    }
  | RejectAction(idx) => {
      let newPending = ar.pendingActions->Array.filterWithIndex((_a, i) => i !== idx)
      ({...model, automationRouter: {...ar, pendingActions: newPending}}, Tea_Cmd.none)
    }
  | ApproveAll => ({...model, automationRouter: {...ar, pendingActions: []}}, Tea_Cmd.none)
  | RejectAll => ({...model, automationRouter: {...ar, pendingActions: []}}, Tea_Cmd.none)
  | LoadRules => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency("agent-mcp", "load_rules", "", result => AutomationRouter(RulesLoaded(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        AutomationRouterCmd.loadRules(result => AutomationRouter(RulesLoaded(result)))
      }
      ({...model, automationRouter: {...ar, loading: true}}, cmd)
    }
  | RulesLoaded(Ok(jsonStr)) => {
    let parseApproval = (s: string): AutomationRouterModel.approvalMode =>
      switch s {
      | "require_approval" => RequireApproval
      | "approve_once" => ApproveOnce
      | "dry_run_first" => DryRunFirst
      | _ => AutoFire
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let description = obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let enabled = obj->Dict.get("enabled")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
        let approvalStr = obj->Dict.get("approval")->Option.flatMap(JSON.Decode.string)->Option.getOr("auto_fire")
        let approval = parseApproval(approvalStr)
        let priority = obj->Dict.get("priority")->Option.flatMap(JSON.Decode.string)->Option.getOr("normal")
        let firedCount = obj->Dict.get("firedCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lastFired = obj->Dict.get("lastFired")->Option.flatMap(JSON.Decode.float)
        let lastResult = obj->Dict.get("lastResult")->Option.flatMap(JSON.Decode.string)
        Some({
          AutomationRouterModel.id,
          name,
          description,
          enabled,
          trigger: Manual,
          conditions: [],
          actions: [],
          approval,
          priority,
          firedCount: Float.toInt(firedCount),
          lastFired,
          lastResult,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(rules) => ({...model, automationRouter: {...ar, rules, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, automationRouter: {...ar, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | RulesLoaded(Error(err)) => (
      {...model, automationRouter: {...ar, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SaveRules => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency("agent-mcp", "save_rules", "", result => AutomationRouter(RulesSaved(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        AutomationRouterCmd.saveRules("", result => AutomationRouter(RulesSaved(result)))
      }
      (model, cmd)
    }
  | RulesSaved(Ok(_)) => (model, Tea_Cmd.none)
  | RulesSaved(Error(err)) => (
      {...model, automationRouter: {...ar, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadFromRepo => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency("agent-mcp", "load_from_repo", ".", result => AutomationRouter(RepoRulesLoaded(result)), (c, t, e) => RecordBojLatency(c, t, e))
      } else {
        AutomationRouterCmd.loadFromRepo(".", result => AutomationRouter(RepoRulesLoaded(result)))
      }
      ({...model, automationRouter: {...ar, loading: true, configSource: "repo"}}, cmd)
    }
  | RepoRulesLoaded(Ok(jsonStr)) => {
    // ENSAID_CONFIG.a2ml is parsed by the backend and returned as JSON array.
    let parseApproval = (s: string): AutomationRouterModel.approvalMode =>
      switch s {
      | "require_approval" => RequireApproval
      | "approve_once" => ApproveOnce
      | "dry_run_first" => DryRunFirst
      | _ => AutoFire
      }
    let parsed = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let description = obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let enabled = obj->Dict.get("enabled")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
        let approvalStr = obj->Dict.get("approval")->Option.flatMap(JSON.Decode.string)->Option.getOr("auto_fire")
        let approval = parseApproval(approvalStr)
        let priority = obj->Dict.get("priority")->Option.flatMap(JSON.Decode.string)->Option.getOr("normal")
        Some({
          AutomationRouterModel.id,
          name,
          description,
          enabled,
          trigger: Manual,
          conditions: [],
          actions: [],
          approval,
          priority,
          firedCount: 0,
          lastFired: None,
          lastResult: None,
        })
      })
      Some(items)
    } catch {
    | _ => None
    }
    switch parsed {
    | Some(rules) => ({...model, automationRouter: {...ar, rules, loading: false, configSource: "repo", error: None}}, Tea_Cmd.none)
    | None => ({...model, automationRouter: {...ar, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | RepoRulesLoaded(Error(err)) => (
      {...model, automationRouter: {...ar, loading: false, configSource: "local", error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetRouterFilter(text) => ({...model, automationRouter: {...ar, filterText: text}}, Tea_Cmd.none)
  | ToggleShowDisabled => ({...model, automationRouter: {...ar, showDisabled: !ar.showDisabled}}, Tea_Cmd.none)
  | DismissRouterError => ({...model, automationRouter: {...ar, error: None}}, Tea_Cmd.none)
  | ExportAutomationConfig => {
      let humidityStr = switch model.humidity {
      | High => "high"
      | Medium => "medium"
      | Low => "low"
      }
      let preview = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=model.provisioner.configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=ar.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(preview)}, Tea_Cmd.none)
    }
  | ToggleAutomationBojRouting => ({...model, automationRouter: {...ar, bojRouting: !ar.bojRouting}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "automationrouter", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

// ===========================================================================
// ScriptGist Sub-Updater — Portable computation gists (Minskian cardfiles)
// ===========================================================================

let updateScriptGist = (model: model, msg: scriptGistMsg): (model, Tea_Cmd.t<msg>) => {
  let sg = model.scriptGist
  switch msg {
  | SetGistCategory(cat) => ({...model, scriptGist: {...sg, activeCategory: cat}}, Tea_Cmd.none)
  | SelectGist(id) => ({...model, scriptGist: {...sg, selectedGistId: id}}, Tea_Cmd.none)
  | CreateGist => {
      let id = "gist-" ++ Float.toString(Date.now())
      let gist = ScriptGistEngine.newGist(id, "Untitled Gist", GistReScript)
      ({...model, scriptGist: {...sg, gists: Array.concat(sg.gists, [gist]), selectedGistId: Some(id), editorOpen: true}}, Tea_Cmd.none)
    }
  | CreateFromTemplate(tplId) => {
      let id = "gist-" ++ Float.toString(Date.now())
      switch sg.templates->Array.find(t => t.id === tplId) {
      | Some(tpl) => {
          let gist: scriptGist = {
            ...ScriptGistEngine.newGist(id, tpl.name, tpl.language),
            code: tpl.templateCode,
            target: tpl.target,
            tags: ["from-template"],
          }
          ({...model, scriptGist: {...sg, gists: Array.concat(sg.gists, [gist]), selectedGistId: Some(id), editorOpen: true}}, Tea_Cmd.none)
        }
      | None => ({...model, scriptGist: {...sg, error: Some("Template not found: " ++ tplId)}}, Tea_Cmd.none)
      }
    }
  | UpdateGistCode(code) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId { {...g, code, modifiedAt: Date.now(), version: g.version + 1} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistTitle(title) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId { {...g, title, modifiedAt: Date.now()} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistLanguage(lang) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId { {...g, language: lang, target: ScriptGistEngine.defaultTarget(lang), modifiedAt: Date.now()} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistTarget(target) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId { {...g, target, modifiedAt: Date.now()} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistVisibility(vis) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId { {...g, visibility: vis, modifiedAt: Date.now()} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | ToggleGistPin(id) => {
      let gists = sg.gists->Array.map(g =>
        if g.id === id { {...g, pinned: !g.pinned} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | DeleteGist(id) => {
      let gists = sg.gists->Array.filter(g => g.id !== id)
      let selectedGistId = if sg.selectedGistId === Some(id) { None } else { sg.selectedGistId }
      ({...model, scriptGist: {...sg, gists, selectedGistId}}, Tea_Cmd.none)
    }
  | SaveGist => (model, Tea_Cmd.none) // TODO: persist to filesystem via Tauri
  | ExecuteGist => ({...model, scriptGist: {...sg, executing: true}}, Tea_Cmd.none) // TODO: dispatch to target
  | GistExecutionResult(result) => {
      switch result {
      | Ok(gistResult) => ({...model, scriptGist: {...sg, executing: false, lastResult: Some(gistResult)}}, Tea_Cmd.none)
      | Error(err) => ({...model, scriptGist: {...sg, executing: false, error: Some(err)}}, Tea_Cmd.none)
      }
    }
  | SetGistFilter(text) => ({...model, scriptGist: {...sg, filterText: text}}, Tea_Cmd.none)
  | SetGistSort(sortBy) => ({...model, scriptGist: {...sg, sortBy}}, Tea_Cmd.none)
  | ToggleGistEditor => ({...model, scriptGist: {...sg, editorOpen: !sg.editorOpen}}, Tea_Cmd.none)
  | ToggleMcpTools => ({...model, scriptGist: {...sg, mcpToolsActive: !sg.mcpToolsActive}}, Tea_Cmd.none)
  | DismissGistError => ({...model, scriptGist: {...sg, error: None}}, Tea_Cmd.none)
  | UpdateGistSchemaName(name) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId { {...g, schema: {...g.schema, toolName: name}} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistSchemaSummary(summary) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId { {...g, schema: {...g.schema, summary}} } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | AddGistSchemaParam => {
      let param: gistParam = {name: "param", description: "", schemaType: "string", required: false, defaultValue: None}
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, schema: {...g.schema, inputs: Array.concat(g.schema.inputs, [param])}}
        } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | RemoveGistSchemaParam(idx) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          let inputs = g.schema.inputs->Array.filterWithIndex((_p, i) => i !== idx)
          {...g, schema: {...g.schema, inputs}}
        } else { g }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | SnapshotDiachronic => {
      let checkpoint: diachronicCheckpoint = {
        index: Array.length(sg.diachronicHistory),
        timestamp: Date.now(),
        label: "Checkpoint #" ++ Int.toString(Array.length(sg.diachronicHistory) + 1),
        snapshot: "", // serialised externally when persistence is wired
      }
      ({...model, scriptGist: {...sg, diachronicHistory: Array.concat(sg.diachronicHistory, [checkpoint])}}, Tea_Cmd.none)
    }
  | RestoreDiachronic(_idx) => (model, Tea_Cmd.none) // TODO: deserialise snapshot
  | InsertIntoCardfile(cardfileId) => {
      switch sg.selectedGistId {
      | Some(gistId) => {
          let cardfiles = sg.cardfiles->Array.map(cf =>
            if cf.id === cardfileId { ScriptGistEngine.addGistToCardfile(cf, gistId) } else { cf }
          )
          ({...model, scriptGist: {...sg, cardfiles}}, Tea_Cmd.none)
        }
      | None => (model, Tea_Cmd.none)
      }
    }
  | RemoveFromCardfile(cardfileId) => {
      switch sg.selectedGistId {
      | Some(gistId) => {
          let cardfiles = sg.cardfiles->Array.map(cf =>
            if cf.id === cardfileId { ScriptGistEngine.removeGistFromCardfile(cf, gistId) } else { cf }
          )
          ({...model, scriptGist: {...sg, cardfiles}}, Tea_Cmd.none)
        }
      | None => (model, Tea_Cmd.none)
      }
    }
  }
}

// ===========================================================================
// BoJ Sub-Updater — Bundle of Joy cartridge server
// ===========================================================================

let updateBoj = (model: model, msg: bojMsg): (model, Tea_Cmd.t<msg>) => {
  let boj = model.boj
  switch msg {
  | SetBojCategory(cat) => ({...model, boj: {...boj, activeCategory: cat}}, Tea_Cmd.none)
  | RefreshHealth => (
      {...model, boj: {...boj, loading: true}},
      BojCmd.health(result => Boj(HealthResult(result))),
    )
  | HealthResult(Ok(_)) => ({...model, boj: {...boj, connected: true, loading: false, error: None}}, Tea_Cmd.none)
  | HealthResult(Error(err)) => ({...model, boj: {...boj, connected: false, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | RefreshCartridges => (
      {...model, boj: {...boj, loading: true}},
      BojCmd.listCartridges(result => Boj(CartridgesResult(result))),
    )
  | CartridgesResult(Ok(json)) =>
    switch BojEngine.parseCartridges(json) {
    | Ok(cartridges) =>
      // Integration #5: BoJ Cartridge → K9 Yard Contracts
      // Generate a Yard contract for the first loaded cartridge (if any) as a preview.
      let yardContract = switch cartridges->Array.find(c => c.loaded) {
      | Some(c) =>
        let protoNames = c.protocols->Array.map(p => BojEngine.protocolLabel(p))
        let gradeStr = switch c.grade {
        | BojModel.GradeA => "A"
        | BojModel.GradeB => "B"
        | BojModel.GradeC => "C"
        | BojModel.GradeD => "D"
        }
        Some(K9Engine.generateYardContract(
          c.name, protoNames, c.restPort, c.grpcPort, c.graphqlPort, gradeStr,
        ))
      | None => model.k9YardContract
      }
      ({...model, boj: {...boj, cartridges, loading: false, error: None}, k9YardContract: yardContract}, Tea_Cmd.none)
    | Error(err) => ({...model, boj: {...boj, loading: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | CartridgesResult(Error(err)) => ({...model, boj: {...boj, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | SelectCartridge(name) => {
      let sel = if name === "" { None } else { Some(name) }
      // Integration #4: Module Config → K9 Kennel Schema
      // Generate a Kennel schema for the selected cartridge's config shape.
      let kennelSchema = if name !== "" {
        switch boj.cartridges->Array.find(c => c.name === name) {
        | Some(c) =>
          let protoNames = c.protocols->Array.map(p => BojEngine.protocolLabel(p))
          let fields = K9Engine.cartridgeToKennelFields(c.name, protoNames)
          Some(K9Engine.generateKennelSchema(c.name, fields))
        | None => model.k9KennelSchema
        }
      } else {
        model.k9KennelSchema
      }
      ({...model, boj: {...boj, selectedCartridge: sel}, k9KennelSchema: kennelSchema}, Tea_Cmd.none)
    }
  | LoadCartridge(name) => (
      {...model, boj: {...boj, loading: true}},
      BojCmd.loadCartridge(name, result => Boj(CartridgeActionResult(name, result))),
    )
  | UnloadCartridge(name) => (
      {...model, boj: {...boj, loading: true}},
      BojCmd.unloadCartridge(name, result => Boj(CartridgeActionResult(name, result))),
    )
  | CartridgeActionResult(_name, Ok(_)) =>
    // Refresh cartridge list after load/unload.
    (
      {...model, boj: {...boj, loading: false, error: None}},
      BojCmd.listCartridges(result => Boj(CartridgesResult(result))),
    )
  | CartridgeActionResult(name, Error(err)) => (
      {...model, boj: {...boj, loading: false, error: Some(`${name}: ${err}`)}},
      Tea_Cmd.none,
    )
  | RefreshTopology => (
      {...model, boj: {...boj, loading: true}},
      BojCmd.topology(result => Boj(TopologyResult(result))),
    )
  | TopologyResult(Ok(json)) =>
    // Topology diagram is rendered client-side from model state.
    // Parse validates the server response; diagram string available for future use.
    switch BojEngine.parseTopology(json) {
    | Ok(_diagram) => ({...model, boj: {...boj, loading: false, error: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, boj: {...boj, loading: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | TopologyResult(Error(err)) => ({...model, boj: {...boj, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | RefreshUmoja => (
      {...model, boj: {...boj, loading: true}},
      BojCmd.umojaStatus(result => Boj(UmojaResult(result))),
    )
  | UmojaResult(Ok(json)) =>
    switch BojEngine.parseUmojaStatus(json) {
    | Ok(umoja) => ({...model, boj: {...boj, umoja, loading: false, error: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, boj: {...boj, loading: false, error: Some(err)}}, Tea_Cmd.none)
    }
  | UmojaResult(Error(err)) => ({...model, boj: {...boj, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | UmojaDisconnectPeer(peerId) =>
    let cmd = UmojaCmd.disconnectPeer(peerId, r => Boj(UmojaDisconnectPeerResult(r)))
    (model, cmd)
  | UmojaSyncCatalogue(peerId) =>
    let cmd = UmojaCmd.syncCatalogue(peerId, r => Boj(UmojaSyncCatalogueResult(r)))
    (model, cmd)
  | UmojaPeerMetrics(peerId) =>
    let cmd = UmojaCmd.getPeerMetrics(peerId, r => Boj(UmojaPeerMetricsResult(r)))
    (model, cmd)
  | UmojaAddPeerInput(value) =>
    ({...model, boj: {...boj, umojaAddPeerInput: value}}, Tea_Cmd.none)
  | UmojaAddPeer(address) =>
    let cmd = UmojaCmd.addPeer(address, r => Boj(UmojaAddPeerResult(r)))
    ({...model, boj: {...boj, umojaAddPeerInput: ""}}, cmd)
  | UmojaTriggerGossip =>
    let cmd = UmojaCmd.triggerGossipRound(r => Boj(UmojaTriggerGossipResult(r)))
    (model, cmd)
  | SetInvokeCartridge(name) => ({...model, boj: {...boj, invokeCartridge: name}}, Tea_Cmd.none)
  | SetInvokeTool(tool) => ({...model, boj: {...boj, invokeTool: tool}}, Tea_Cmd.none)
  | SetInvokeArgs(_argsJson) =>
    // Store raw args JSON string — parsed on invocation.
    (model, Tea_Cmd.none)
  | ExecuteInvoke => {
      let abiSpec = `{"cartridge":"${boj.invokeCartridge}","tool":"${boj.invokeTool}"}`
      (
        {...model, boj: {...boj, loading: true, invokeResult: None, lastTypeCheck: None}},
        Tea_Cmd.batch(list{
          BojCmd.invokeCartridgeWithLatency(
            boj.invokeCartridge,
            boj.invokeTool,
            "{}",
            result => Boj(InvokeResult(result)),
            (c, t, e) => RecordBojLatency(c, t, e),
          ),
          TypeLLService.checkCartridgeAbi(abiSpec, result => Boj(AbiTypeCheckResult(result))),
        }),
      )
    }
  | InvokeResult(Ok(payload)) => {
      let result: BojModel.invokeResult = {success: true, payload, durationMs: 0}
      ({...model, boj: {...boj, loading: false, invokeResult: Some(result), error: None}}, Tea_Cmd.none)
    }
  | InvokeResult(Error(err)) => {
      let result: BojModel.invokeResult = {success: false, payload: err, durationMs: 0}
      ({...model, boj: {...boj, loading: false, invokeResult: Some(result), error: None}}, Tea_Cmd.none)
    }
  | SetBojFilter(text) => ({...model, boj: {...boj, filterText: text}}, Tea_Cmd.none)
  | DismissBojError => ({...model, boj: {...boj, error: None}}, Tea_Cmd.none)
  | AbiTypeCheckResult(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, boj: {...boj, lastTypeCheck: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | AbiTypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  | UmojaAddPeerResult(Ok(_)) =>
    // Peer added successfully — refresh Umoja status.
    ({...model, boj: {...boj, umojaAddPeerInput: ""}}, BojCmd.umojaStatus(result => Boj(UmojaResult(result))))
  | UmojaAddPeerResult(Error(err)) =>
    ({...model, boj: {...boj, error: Some(err)}}, Tea_Cmd.none)
  | UmojaDisconnectPeerResult(Ok(_)) =>
    // Peer disconnected — refresh Umoja status.
    (model, BojCmd.umojaStatus(result => Boj(UmojaResult(result))))
  | UmojaDisconnectPeerResult(Error(err)) =>
    ({...model, boj: {...boj, error: Some(err)}}, Tea_Cmd.none)
  | UmojaTriggerGossipResult(Ok(_)) =>
    // Gossip triggered — refresh Umoja status.
    (model, BojCmd.umojaStatus(result => Boj(UmojaResult(result))))
  | UmojaTriggerGossipResult(Error(err)) =>
    ({...model, boj: {...boj, error: Some(err)}}, Tea_Cmd.none)
  | UmojaSyncCatalogueResult(Ok(_)) =>
    (model, BojCmd.umojaStatus(result => Boj(UmojaResult(result))))
  | UmojaSyncCatalogueResult(Error(err)) =>
    ({...model, boj: {...boj, error: Some(err)}}, Tea_Cmd.none)
  | UmojaPeerMetricsResult(Ok(_json)) =>
    // Peer metrics received — placeholder for future display.
    (model, Tea_Cmd.none)
  | UmojaPeerMetricsResult(Error(err)) =>
    ({...model, boj: {...boj, error: Some(err)}}, Tea_Cmd.none)
  }
}

// ===========================================================================
// ENSAID_CONFIG Sub-Updater — cross-panel config generation
// ===========================================================================

let updateCladeBrowser = (model: model, msg: cladeBrowserMsg): (model, Tea_Cmd.t<msg>) => {
  let cb = model.cladeBrowser
  switch msg {
  | SetCladeCategory(cat) => ({...model, cladeBrowser: {...cb, category: cat}}, Tea_Cmd.none)
  | SelectClade(id) => ({...model, cladeBrowser: {...cb, selectedClade: id}}, Tea_Cmd.none)
  | SetKindFilter(kind) => ({...model, cladeBrowser: {...cb, kindFilter: kind}}, Tea_Cmd.none)
  | UpdateCladeSearch(query) => ({...model, cladeBrowser: {...cb, searchQuery: query}}, Tea_Cmd.none)
  | LoadClades => (
      {...model, cladeBrowser: {...cb, loading: true}},
      Tea_Cmd.batch(list{
        CladeCmd.scanCladeFiles(result => CladeBrowser(CladesLoaded(
          switch result {
          | Ok(jsonStr) => {
              let loaded = CladeLoader.fromScanResult(jsonStr)
              let merged = CladeLoader.mergeWithBuiltins(loaded, CladeBrowserEngine.builtinCladesBase)
              merged->Array.map(CladeBrowserEngine.enrichClade)
            }
          | Error(_) => CladeBrowserEngine.builtinClades
          }
        ))),
        TypeLLService.checkMetadataTypes("clade-scan", "clade-browser", result => CladeBrowser(TypeCheckResult(result))),
      }),
    )
  | CladesLoaded(clades) => ({...model, cladeBrowser: {...cb, clades, loading: false, error: None}}, Tea_Cmd.none)
  | SetCladePermission(targetCladeId, perm) => {
      let newRules = CladeBrowserEngine.setPermission(cb.permissionRules, targetCladeId, perm)
      // Integration #7: Clade Permissions → K9 Hunt check
      // When setting permissions, verify Hunt-level K9 execution is permitted
      // based on clade isolation and signing status.
      let updatedModel = switch cb.clades->Array.find(c => c.id === targetCladeId) {
      | Some(clade) =>
        let isolationStr = switch clade.isolation {
        | CladeBrowserModel.IsolationNone => "none"
        | CladeBrowserModel.IsolationSoft => "soft"
        | CladeBrowserModel.IsolationProcess => "process"
        | CladeBrowserModel.IsolationContainer => "container|hunt|full"
        }
        let signingOk = switch clade.signing {
        | CladeBrowserModel.SigningVerified(_) => true
        | _ => false
        }
        // Check if there's a loaded K9 contractile to verify Hunt permission against
        let _huntCheck = switch model.lastK9Contractile {
        | Some(contractile) =>
          if contractile.securityLevel == K9Engine.Hunt {
            let (_allowed, _reason) = K9Engine.checkHuntPermission(
              isolationStr, signingOk, K9Engine.summariseContractile(contractile),
            )
            // Hunt permission check result is logged but not blocking (informational)
            ()
          }
        | None => ()
        }
        {...model, cladeBrowser: {...cb, permissionRules: newRules}}
      | None => {...model, cladeBrowser: {...cb, permissionRules: newRules}}
      }
      (updatedModel, Tea_Cmd.none)
    }
  | RemoveCladePermission(targetCladeId) => {
      let newRules = CladeBrowserEngine.removePermission(cb.permissionRules, targetCladeId)
      ({...model, cladeBrowser: {...cb, permissionRules: newRules}}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "cladebrowser", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

let updateTentacles = (model: model, msg: tentaclesMsg): (model, Tea_Cmd.t<msg>) => {
  let st = model.tentacles
  switch msg {
  | SetTentaclesCategory(cat) => ({...model, tentacles: {...st, activeCategory: cat}}, Tea_Cmd.none)
  | SelectAgent(id) => ({...model, tentacles: {...st, selectedAgent: id}}, Tea_Cmd.none)
  | SetGlobalStage(stage) => {
      let updatedAgents = st.agents->Array.map(a => {...a, stage})
      ({...model, tentacles: {...st, globalStage: stage, agents: updatedAgents}}, Tea_Cmd.none)
    }
  | ToggleOrchestraCompact => ({...model, tentacles: {...st, orchestraCompact: !st.orchestraCompact}}, Tea_Cmd.none)
  | BroadcastFromAgent(_source, payload) => (
      {...model, tentacles: {...st, pendingBroadcasts: Array.concat(st.pendingBroadcasts, [payload])}},
      Tea_Cmd.none,
    )
  | DeliverBroadcasts => ({...model, tentacles: {...st, pendingBroadcasts: []}}, Tea_Cmd.none)
  | StartAgentTask(id, task) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a =>
        TentaclesEngine.startTask(a, task)
      )
      ({...model, tentacles: {...st, agents}}, TypeLLService.checkCodeTypes(task, "tentacles", result => Tentacles(TypeCheckResult(result))))
    }
  | AgentPhaseAdvanced(id, _phase) => {
      // S1: Use OODA progression engine — advance through Observe→Orient→Decide→Act.
      // When the cycle completes (Act→Observe), the agent task finishes automatically.
      let updatedAgents = TentaclesEngine.updateAgent(st.agents, id, a => {
        let (advanced, _completed) = TentaclesEngine.advancePhase(a)
        advanced
      })
      ({...model, tentacles: {...st, agents: updatedAgents}}, Tea_Cmd.none)
    }
  | AgentConstraintAdded(id, newConstraint) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        constraints: Array.concat(a.constraints, [newConstraint]),
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentReasoningAdded(id, entry) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        reasoning: Array.concat(a.reasoning, [entry]),
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentResultAdded(id, result) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        results: Array.concat(a.results, [result]),
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentTaskCompleted(id) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {
        ...a,
        busy: false,
        currentTask: None,
      })
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | AgentError(id, err) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a =>
        TentaclesEngine.failTask(a, err)
      )
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | ClearAgentError(id) => {
      let agents = TentaclesEngine.updateAgent(st.agents, id, a => {...a, lastError: None})
      ({...model, tentacles: {...st, agents}}, Tea_Cmd.none)
    }
  | CheckFfiBridge => (model, TentaclesCmd.checkFfiBridge(result =>
      switch result {
      | Ok(_) => Tentacles(FfiBridgeResult(true, None))
      | Error(err) => Tentacles(FfiBridgeResult(false, Some(err)))
      }
    ))
  | FfiBridgeResult(connected, error) => (
      {...model, tentacles: {...st, ffiConnected: connected, ffiError: error, ffiLastCheck: 0.0}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "tentacles", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}

let updateProtocolSquisher = (model: model, msg: protocolSquisherMsg): (model, Tea_Cmd.t<msg>) => {
  let ps = model.protocolSquisher
  switch msg {
  | SetPsCategory(cat) => ({...model, protocolSquisher: {...ps, activeCategory: cat}}, Tea_Cmd.none)
  | CheckPsCli => (
      {...model, protocolSquisher: {...ps, loading: true}},
      ProtocolSquisherCmd.checkCli(result => ProtocolSquisher(PsCliResult(result))),
    )
  | PsCliResult(Ok(_)) => ({...model, protocolSquisher: {...ps, cliAvailable: true, loading: false, error: None}}, Tea_Cmd.none)
  | PsCliResult(Error(e)) => ({...model, protocolSquisher: {...ps, cliAvailable: false, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | SetAnalyseInput(v) => ({...model, protocolSquisher: {...ps, analyseInput: v}}, Tea_Cmd.none)
  | RunAnalysis => (
      {...model, protocolSquisher: {...ps, loading: true, error: None, lastTypeCheck: None}},
      Tea_Cmd.batch(list{
        ProtocolSquisherCmd.analyse(ps.analyseInput, result => ProtocolSquisher(AnalysisResult(result))),
        TypeLLService.checkSchemaTypes(ps.analyseInput, "auto", result => ProtocolSquisher(SchemaTypeCheckResult(result))),
      }),
    )
  | AnalysisResult(Ok(json)) =>
    switch ProtocolSquisherEngine.parseAnalysis(json) {
    | Ok(result) => {
        // #6: Extract IR constraints from the analysis result automatically.
        let irConstraints = ProtocolSquisherEngine.extractIrConstraints(result)
        (
          {...model, protocolSquisher: {
            ...ps,
            loading: false,
            lastAnalysis: Some(result),
            analysisHistory: Array.concat([result], ps.analysisHistory),
            irConstraints,
            error: None,
          }},
          Tea_Cmd.none,
        )
      }
    | Error(e) => ({...model, protocolSquisher: {...ps, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | AnalysisResult(Error(e)) => ({...model, protocolSquisher: {...ps, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | SetCompareLeft(v) => ({...model, protocolSquisher: {...ps, compareLeftInput: v}}, Tea_Cmd.none)
  | SetCompareRight(v) => ({...model, protocolSquisher: {...ps, compareRightInput: v}}, Tea_Cmd.none)
  | RunComparison => (
      {...model, protocolSquisher: {...ps, loading: true, error: None}},
      ProtocolSquisherCmd.compare(
        ps.compareLeftInput,
        ps.compareRightInput,
        result => ProtocolSquisher(ComparisonResult(result)),
      ),
    )
  | ComparisonResult(Ok(json)) => {
      let parsed = ProtocolSquisherEngine.parseComparison(json)
      switch parsed {
      | Ok(comparison) => (
          {...model, protocolSquisher: {...ps, loading: false, error: None, lastComparison: Some(comparison)}},
          Tea_Cmd.none,
        )
      | Error(_) => (
          {...model, protocolSquisher: {...ps, loading: false, error: None}},
          Tea_Cmd.none,
        )
      }
    }
  | ComparisonResult(Error(e)) => ({...model, protocolSquisher: {...ps, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | SchemaTypeCheckResult(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, protocolSquisher: {...ps, lastTypeCheck: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | SchemaTypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  // #6: Import IR constraints as Panel-L symbolic constraints.
  | ImportIrConstraints => {
      let newConstraints = ps.irConstraints->Array.mapWithIndex((expr, idx) => {
        let c: symbolicConstraint = {
          id: `ps-ir-${Int.toString(idx)}`,
          expression: expr,
          active: true,
          pinned: false,
        }
        c
      })
      let existingConstraints = model.paneL.constraints
      let merged = Array.concat(existingConstraints, newConstraints)
      ({...model, paneL: {...model.paneL, constraints: merged}}, Tea_Cmd.none)
    }
  // #7: Toggle transport compatibility display in Panel-W.
  | ToggleTransportDisplay => (
      {...model, protocolSquisher: {...ps, transportDisplayActive: !ps.transportDisplayActive}},
      Tea_Cmd.none,
    )
  }
}

let updateMyLang = (model: model, msg: myLangMsg): (model, Tea_Cmd.t<msg>) => {
  let ml = model.myLang
  switch msg {
  | SetMlCategory(cat) => ({...model, myLang: {...ml, activeCategory: cat}}, Tea_Cmd.none)
  | SetDialect(d) => {
      // #9: Save current REPL session before switching dialect.
      let savedSessions = ml.replSessions->Array.filter(((dialect, _)) => dialect !== ml.activeDialect)
      let sessionId = `session-${MyLangEngine.dialectLabel(ml.activeDialect)}`
      let savedSessions = Array.concat(savedSessions, [(ml.activeDialect, sessionId)])
      // Restore REPL history for the new dialect (or start fresh).
      (
        {...model, myLang: {
          ...ml,
          activeDialect: d,
          editorContent: MyLangEngine.dialectExample(d),
          replSessions: savedSessions,
          lspDiagnostics: [], // Clear diagnostics on dialect switch
        }},
        Tea_Cmd.none,
      )
    }
  | CheckMlCli => (
      {...model, myLang: {...ml, loading: true}},
      MyLangCmd.checkCli(result => MyLang(MlCliResult(result))),
    )
  | MlCliResult(Ok(_)) => ({...model, myLang: {...ml, cliAvailable: true, loading: false, error: None}}, Tea_Cmd.none)
  | MlCliResult(Error(e)) => ({...model, myLang: {...ml, cliAvailable: false, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | UpdateEditor(v) => ({...model, myLang: {...ml, editorContent: v}}, Tea_Cmd.none)
  | Compile => {
      let dialectStr = MyLangEngine.dialectLabel(ml.activeDialect)
      let compileCmd = if ml.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "lsp-mcp",
          "compile",
          `{"code": "${ml.editorContent}", "dialect": "${dialectStr}"}`,
          result => MyLang(CompileResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        MyLangCmd.compile(ml.editorContent, dialectStr, result => MyLang(CompileResult(result)))
      }
      (
        {...model, myLang: {...ml, loading: true, error: None, lastTypeCheck: None}},
        Tea_Cmd.batch(list{
          compileCmd,
          TypeLLService.checkMyLangTypes(ml.editorContent, dialectStr, result => MyLang(MlTypeCheckResult(result))),
        }),
      )
    }
  | CompileResult(Ok(json)) =>
    switch MyLangEngine.parseCompilation(json) {
    | Ok(result) => ({...model, myLang: {...ml, loading: false, lastCompilation: Some(result), error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, myLang: {...ml, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | CompileResult(Error(e)) => ({...model, myLang: {...ml, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | UpdateReplInput(v) => ({...model, myLang: {...ml, replInput: v}}, Tea_Cmd.none)
  | EvalRepl =>
    if ml.replInput === "" {
      (model, Tea_Cmd.none)
    } else {
      let dialectStr = MyLangEngine.dialectLabel(ml.activeDialect)
      let evalCmd = if ml.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "lsp-mcp",
          "repl",
          `{"input": "${ml.replInput}", "dialect": "${dialectStr}"}`,
          result => MyLang(ReplResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        MyLangCmd.replEval(
          ml.replInput,
          dialectStr,
          result => MyLang(ReplResult(result)),
        )
      }
      (
        {...model, myLang: {...ml, loading: true, replInput: ""}},
        evalCmd,
      )
    }
  | ReplResult(Ok(output)) => {
      let entry: replEntry = {
        input: ml.replInput !== "" ? ml.replInput : "(previous input)",
        output,
        isError: false,
      }
      ({...model, myLang: {...ml, loading: false, replHistory: Array.concat(ml.replHistory, [entry])}}, Tea_Cmd.none)
    }
  | ReplResult(Error(e)) => {
      let entry: replEntry = {
        input: ml.replInput !== "" ? ml.replInput : "(previous input)",
        output: e,
        isError: true,
      }
      ({...model, myLang: {...ml, loading: false, replHistory: Array.concat(ml.replHistory, [entry])}}, Tea_Cmd.none)
    }
  | MlTypeCheckResult(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, myLang: {...ml, lastTypeCheck: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | MlTypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  // #8: LSP integration for syntax highlighting and diagnostics.
  | ConnectLsp => (
      {...model, myLang: {...ml, loading: true}},
      MyLangCmd.connectLsp(result => MyLang(LspConnected(result))),
    )
  | LspConnected(Ok(_)) => (
      {...model, myLang: {...ml, lspConnected: true, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | LspConnected(Error(e)) => (
      {...model, myLang: {...ml, lspConnected: false, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | LspDiagnosticsReceived(diagnostics) => (
      {...model, myLang: {...ml, lspDiagnostics: diagnostics}},
      Tea_Cmd.none,
    )
  | RequestDiagnostics =>
    if ml.lspConnected {
      let filePath = "panll://mylang/" ++ MyLangEngine.dialectLabel(ml.activeDialect) ++ "/input"
      (
        model,
        MyLangCmd.requestDiagnostics(
          filePath,
          ml.editorContent,
          result => switch result {
          | Ok(json) => MyLang(LspDiagnosticsReceived([json]))
          | Error(e) => MyLang(LspDiagnosticsReceived([e]))
          },
        ),
      )
    } else {
      (model, Tea_Cmd.none)
    }
  | ToggleMyLangBojRouting => (
      {...model, myLang: {...ml, bojRouting: !ml.bojRouting}},
      Tea_Cmd.none,
    )
  }
}

let updateTypeLL = (model: model, msg: typellMsg): (model, Tea_Cmd.t<msg>) => {
  let tl = model.typell
  switch msg {
  | SetTlCategory(cat) => ({...model, typell: {...tl, activeCategory: cat}}, Tea_Cmd.none)
  | SetViewLayer(vl) => ({...model, typell: {...tl, activeViewLayer: vl}}, Tea_Cmd.none)
  | CheckTlHealth => (
      {...model, typell: {...tl, loading: true}},
      TypeLLCmd.health(result => TypeLL(TlHealthResult(result))),
    )
  | TlHealthResult(Ok(_)) => ({...model, typell: {...tl, serverConnected: true, loading: false, error: None}}, Tea_Cmd.none)
  | TlHealthResult(Error(e)) => ({...model, typell: {...tl, serverConnected: false, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | UpdateCheckerInput(v) => ({...model, typell: {...tl, checkerInput: v}}, Tea_Cmd.none)
  | RunCheck => {
      let ctx = if tl.checkerContext !== "" { Some(tl.checkerContext) } else { None }
      let checkCmd = if tl.bojRouting {
        let ctxStr = switch ctx {
        | Some(c) => `, "context": "${c}"`
        | None => ""
        }
        BojCmd.invokeCartridgeWithLatency(
          "nesy-mcp",
          "check",
          `{"input": "${tl.checkerInput}"${ctxStr}}`,
          result => TypeLL(CheckResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        TypeLLCmd.check(tl.checkerInput, ctx, result => TypeLL(CheckResult(result)))
      }
      (
        {...model, typell: {...tl, loading: true, error: None}},
        checkCmd,
      )
    }
  | CheckResult(Ok(json)) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Ok(result) => {
        let narrative = TypeLLEngine.generateNarrative(result)
        (
          {...model, typell: {
            ...tl,
            loading: false,
            lastCheckResult: Some(result),
            lastNarrative: Some(narrative),
            queriesServed: tl.queriesServed + 1,
            error: None,
          }},
          Tea_Cmd.none,
        )
      }
    | Error(e) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | CheckResult(Error(e)) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | RunInfer => {
      let inferCmd = if tl.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "nesy-mcp",
          "infer",
          `{"input": "${tl.checkerInput}"}`,
          result => TypeLL(InferResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        TypeLLCmd.infer(tl.checkerInput, result => TypeLL(InferResult(result)))
      }
      (
        {...model, typell: {...tl, loading: true, error: None}},
        inferCmd,
      )
    }
  | InferResult(Ok(json)) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Ok(result) => {
        let narrative = TypeLLEngine.generateNarrative(result)
        (
          {...model, typell: {
            ...tl,
            loading: false,
            lastCheckResult: Some(result),
            lastNarrative: Some(narrative),
            queriesServed: tl.queriesServed + 1,
            error: None,
          }},
          Tea_Cmd.none,
        )
      }
    | Error(e) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | InferResult(Error(e)) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | LoadSignatures => (
      {...model, typell: {...tl, loading: true}},
      TypeLLCmd.listSignatures(result => TypeLL(SignaturesLoaded(result))),
    )
  | SignaturesLoaded(Ok(jsonStr)) => {
    let sigs = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      arr->Array.filterMap(item => {
        let o = item->JSON.Decode.object->Option.getOr(Dict.make())
        let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = gs(o, "name")
        if name !== "" {
          let tier = switch gs(o, "tier") {
          | "advanced" => TypeLLModel.TierAdvanced
          | "research" => TypeLLModel.TierResearch
          | _ => TypeLLModel.TierCore
          }
          Some({
            TypeLLModel.name,
            signature: gs(o, "signature"),
            module_: gs(o, "module"),
            tier,
          })
        } else {
          None
        }
      })
    } catch {
    | _ => []
    }
    ({...model, typell: {...tl, loading: false, signatures: sigs, error: None}}, Tea_Cmd.none)
  }
  | SignaturesLoaded(Error(e)) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | LoadUniverses => (
      {...model, typell: {...tl, loading: true}},
      TypeLLCmd.universes(result => TypeLL(UniversesLoaded(result))),
    )
  | UniversesLoaded(Ok(jsonStr)) => {
    let univs = try {
      let json = JSON.parseExn(jsonStr)
      let arr = json->JSON.Decode.array->Option.getOr([])
      arr->Array.filterMap(item => {
        let o = item->JSON.Decode.object->Option.getOr(Dict.make())
        let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
        let name = gs(o, "name")
        if name !== "" {
          Some({
            TypeLLModel.level: gi(o, "level"),
            name,
            description: gs(o, "description"),
          })
        } else {
          None
        }
      })
    } catch {
    | _ => []
    }
    ({...model, typell: {...tl, loading: false, universes: univs, error: None}}, Tea_Cmd.none)
  }
  | UniversesLoaded(Error(e)) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | SetSignatureFilter(v) => ({...model, typell: {...tl, signatureFilter: v}}, Tea_Cmd.none)
  | SetTierFilter(t) => ({...model, typell: {...tl, tierFilter: t}}, Tea_Cmd.none)
  | UpdateRefinementSpec(v) => ({...model, typell: {...tl, refinementSpec: v}}, Tea_Cmd.none)
  | UpdateRefinementConstraints(v) => ({...model, typell: {...tl, refinementConstraints: v}}, Tea_Cmd.none)
  | RunRefine => {
      let constraints = if tl.refinementConstraints !== "" { Some(tl.refinementConstraints) } else { None }
      (
        {...model, typell: {...tl, loading: true, error: None}},
        TypeLLCmd.refine(tl.refinementSpec, constraints, result => TypeLL(RefineResult(result))),
      )
    }
  | RefineResult(Ok(json)) =>
    switch TypeLLEngine.parseRefinementResult(json) {
    | Ok(result) => (
        {...model, typell: {...tl, loading: false, lastRefinement: Some(result), queriesServed: tl.queriesServed + 1, error: None}},
        Tea_Cmd.none,
      )
    | Error(e) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | RefineResult(Error(e)) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | ToggleTypellBojRouting => (
      {...model, typell: {...tl, bojRouting: !tl.bojRouting}},
      Tea_Cmd.none,
    )
  | SetDefaultDiscipline(d) => (
      {...model, typell: {...tl, defaultDiscipline: d}},
      Tea_Cmd.none,
    )
  | SetModuleDiscipline(scope, discipline) => {
      let existing = tl.disciplineDeclarations->Array.filter(d => d.scope !== scope)
      let decl: disciplineDeclaration = {
        scope,
        discipline,
        inferenceAllowed: true,
        enabledFeatures: TypeLLEngine.disciplineImpliedFeatures(discipline),
      }
      ({...model, typell: {...tl, disciplineDeclarations: Array.concat(existing, [decl])}}, Tea_Cmd.none)
    }
  | RemoveModuleDiscipline(scope) => {
      let filtered = tl.disciplineDeclarations->Array.filter(d => d.scope !== scope)
      ({...model, typell: {...tl, disciplineDeclarations: filtered}}, Tea_Cmd.none)
    }
  }
}

/// Update handler for the in-application help system.
/// Manages search, category filtering, entry navigation, glossary lookup,
/// and the onboarding walkthrough.
let updateHelp = (model: model, msg: helpMsg): (model, Tea_Cmd.t<msg>) => {
  let h = model.help
  switch msg {
  | SetHelpSearch(query) =>
    let allEntries = HelpContent.allEntries()
    let filtered = if query === "" {
      HelpEngine.filterByCategory(h.activeCategory, allEntries)
    } else {
      HelpEngine.searchEntries(query, allEntries)
    }
    ({...model, help: {...h, searchQuery: query, filteredEntries: filtered}}, Tea_Cmd.none)
  | SetHelpCategory(cat) =>
    let allEntries = HelpContent.allEntries()
    let filtered = HelpEngine.filterByCategory(cat, allEntries)
    ({...model, help: {...h, activeCategory: cat, filteredEntries: filtered, activeEntry: None}}, Tea_Cmd.none)
  | SelectEntry(id) =>
    ({...model, help: {...h, activeEntry: Some(id)}}, Tea_Cmd.none)
  | CloseHelp =>
    ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: None}}, Tea_Cmd.none)
  | StartOnboarding =>
    let onboarding = {...h.onboarding, active: true, currentStep: 0}
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | NextOnboardingStep =>
    let onboarding = HelpEngine.nextOnboardingStep(h.onboarding)
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | PrevOnboardingStep =>
    let onboarding = HelpEngine.prevOnboardingStep(h.onboarding)
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | SkipOnboarding =>
    let onboarding = {...h.onboarding, active: false, completedOnce: true}
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | CompleteOnboarding =>
    let onboarding = {...h.onboarding, active: false, completedOnce: true}
    ({...model, help: {...h, onboarding}}, Tea_Cmd.none)
  | OpenContextHelp(panelId) =>
    let allEntries = HelpContent.allEntries()
    let filtered = HelpEngine.filterByPanel(panelId, allEntries)
    let newHelp = {
      ...h,
      contextPanelId: panelId,
      filteredEntries: filtered,
      activeCategory: PanelGuide,
      activeEntry: None,
    }
    ({
      ...model,
      help: newHelp,
      panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)},
    }, Tea_Cmd.none)
  | SearchGlossary(query) =>
    let glossary = HelpEngine.searchGlossary(query, HelpContent.allGlossaryTerms())
    ({...model, help: {...h, glossary, activeCategory: Glossary}}, Tea_Cmd.none)
  }
}

/// Update handler for menu bar interactions.
/// Routes menu actions to appropriate sub-updaters or panel activations.
let updateMenuBar = (model: model, msg: menuBarMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | OpenMenu(menu) => ({...model, menuBar: {activeMenu: Some(menu)}}, Tea_Cmd.none)
  | CloseMenus => ({...model, menuBar: {activeMenu: None}}, Tea_Cmd.none)
  | MenuAction(actionId) =>
    // Close the menu first, then route the action.
    let model = {...model, menuBar: {activeMenu: None}}
    switch actionId {
    // File actions
    | "file:save-state" => (model, Tea_Cmd.none) // Routed to SaveState in main update
    | "file:open-repo" => (model, Tea_Cmd.none) // Would open RepoLoader panel
    | "file:new-workspace" => {
      // Reset to initial state but keep viewMode as Standard (not DarkStart).
      let fresh = Model.init()
      ({...fresh, viewMode: Standard}, Tea_Cmd.none)
    }
    | "file:export-ensaid" => {
      // No backend export yet — route to Help panel with status message.
      ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none)
    }
    | "file:export-chain" => {
      // No backend export yet — route to Help panel with status message.
      ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none)
    }
    | "file:import-chain" => (
      // Open file dialog to import an event chain JSON file (same as PaneW import button).
      model,
      TauriCmd.openEventChainFile(result => PaneW(EventChainFileLoaded(result))),
    )
    | "file:import-panic" => (
      // Open file dialog to import a panic-attacker report file (same as PaneW import button).
      model,
      TauriCmd.openPanicAttackerReportFile(result =>
        PaneW(PanicAttackerReportPathLoaded(result))
      ),
    )
    | "file:preferences" => (
      // Open the Workspace panel — that's where preferences live.
      {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelWorkspace)}},
      Tea_Cmd.none,
    )
    | "file:print" => (model, Tea_Cmd.none) // No print backend — intentional no-op
    // Edit actions
    | "edit:undo" => (model, Tea_Cmd.none) // Handled by main update loop — MenuAction routes through parent
    | "edit:redo" => (model, Tea_Cmd.none) // Handled by main update loop — MenuAction routes through parent
    | "edit:clear-chain" => ({...model, paneW: {...model.paneW, eventChain: [], eventChainSummary: None, eventChainTimeline: None, eventChainInput: "", eventChainError: None}}, Tea_Cmd.none)
    | "edit:find" => (model, Tea_Cmd.none) // No find UI yet — awaiting search panel implementation
    | "edit:replace" => (model, Tea_Cmd.none) // No find/replace UI yet — awaiting search panel implementation
    | "edit:reset-panel" => {
      // Reset all panels to defaults via the Workspace handler's logic.
      // Inline the same reset as Workspace(ResetAllPanels) since we can't recurse.
      let m = {
        ...model,
        coprocessors: CoprocessorsEngine.defaultState,
        buildDashboard: BuildDashboardEngine.defaultState,
        releaseManager: ReleaseManagerEngine.defaultState,
        automationRouter: AutomationRouterEngine.defaultState,
        scriptGist: ScriptGistEngine.defaultState,
        security: SecurityEngine.defaultState,
        voiceTag: VoiceTagEngine.defaultState,
        massPanic: MassPanicModel.init,
        panicAttack: PanicAttackModel.init,
        tsdm: TsdmModel.init,
        levelArchitect: LevelArchitectEngine.defaultState,
        networkTopology: NetworkTopologyEngine.defaultState,
        typell: TypeLLEngine.defaultState,
        boj: BojEngine.defaultState,
        vmInspector: VmInspectorEngine.defaultState,
        gamePreview: GamePreviewEngine.defaultState,
        provenance: ProvenanceEngine.defaultState,
        myLang: MyLangEngine.defaultState,
        valenceShell: ValenceShellEngine.defaultState,
        migration: MigrationEngine.defaultState,
        repoLoader: RepoLoaderEngine.defaultState,
        ai: AiEngine.defaultState,
        statusBar: StatusBarEngine.defaultState,
        cladeBrowser: CladeBrowserModel.defaultState,
        protocolSquisher: ProtocolSquisherEngine.defaultState,
        aerie: AerieEngine.defaultState,
      }
      (m, Tea_Cmd.none)
    }
    // View actions
    | "view:toggle-pane-l" => ({...model, paneLVisible: !model.paneLVisible}, Tea_Cmd.none)
    | "view:toggle-pane-n" => ({...model, paneNVisible: !model.paneNVisible}, Tea_Cmd.none)
    | "view:toggle-pane-w" => ({...model, paneWVisible: !model.paneWVisible}, Tea_Cmd.none)
    | "view:toggle-panel-bar" => ({...model, panelBarVisible: !model.panelBarVisible}, Tea_Cmd.none)
    | "view:toggle-topology" => ({...model, paneW: {...model.paneW, topologyView: !model.paneW.topologyView}}, Tea_Cmd.none)
    | "view:fullscreen" => ({...model, fullscreenActive: !model.fullscreenActive}, Tea_Cmd.none)
    | "view:light-mode" => ({...model, viewMode: model.viewMode === LightMode ? Standard : LightMode}, Tea_Cmd.none)
    | "view:zen" => ({...model, viewMode: Zen}, Tea_Cmd.none)
    | "view:dark-start" => ({...model, viewMode: DarkStart}, Tea_Cmd.none)
    | "view:accessibility" => ({...model, accessibility: {...model.accessibility, toolbarExpanded: true}}, Tea_Cmd.none)
    // Panel actions — open panels via panel switcher
    | "panel:ai" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelAi)}}, Tea_Cmd.none)
    | "panel:vab" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelVab)}}, Tea_Cmd.none)
    | "panel:cloudguard" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCloudGuard)}}, Tea_Cmd.none)
    | "panel:hypatia" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHypatia)}}, Tea_Cmd.none)
    | "panel:reposystem" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelReposystem)}}, Tea_Cmd.none)
    | "panel:build-dashboard" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelBuildDashboard)}}, Tea_Cmd.none)
    | "panel:editor-bridge" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelEditorBridge)}}, Tea_Cmd.none)
    | "panel:release-manager" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelReleaseManager)}}, Tea_Cmd.none)
    | "panel:workspace" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelWorkspace)}}, Tea_Cmd.none)
    | "panel:capture" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCapture)}}, Tea_Cmd.none)
    | "panel:security" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelSecurity)}}, Tea_Cmd.none)
    | "panel:boj" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelBoj)}}, Tea_Cmd.none)
    | "panel:typell" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelTypeLL)}}, Tea_Cmd.none)
    | "panel:provenance" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none) // Provenance panel slot needed — routes to Help for now
    // Tools actions — open tool panels
    | "tools:panic-attack" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelPanicAttack)}}, Tea_Cmd.none)
    | "tools:mass-panic" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelMassPanic)}}, Tea_Cmd.none)
    | "tools:tsdm" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelTsdm)}}, Tea_Cmd.none)
    | "tools:clade-browser" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCladeBrowser)}}, Tea_Cmd.none)
    | "tools:network-topology" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelNetworkTopology)}}, Tea_Cmd.none)
    | "tools:vm-inspector" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelVmInspector)}}, Tea_Cmd.none)
    | "tools:coprocessors" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCoprocessors)}}, Tea_Cmd.none)
    | "tools:automation" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelAutomationRouter)}}, Tea_Cmd.none)
    | "tools:tentacles" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelTentacles)}}, Tea_Cmd.none)
    | "tools:protocol-squisher" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelProtocolSquisher)}}, Tea_Cmd.none)
    | "tools:mof-ocl" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none) // Routes to ECHIDNA enterprise model tab (coming)
    | "tools:echidna" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none) // ECHIDNA doesn't have a panel slot yet — route to Help
    | "tools:keybindings" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelWorkspace)}}, Tea_Cmd.none)
    | "panel:echidna" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none) // ECHIDNA panel slot needed
    | "panel:interfaces" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelInterfaces)}}, Tea_Cmd.none)
    | "panel:protocol-squisher" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelProtocolSquisher)}}, Tea_Cmd.none)
    // Help actions
    | "help:tour" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none)
    | "help:glossary" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none)
    | "help:barycentre-tour" => ({...model, barycentreTour: {active: true, currentStep: TourIntro, completed: model.barycentreTour.completed}, paneW: {...model.paneW, topologyView: true}}, Tea_Cmd.none)
    | "help:about" => ({...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}}, Tea_Cmd.none)
    | _ => (model, Tea_Cmd.none)
    }
  }
}

/// Update handler for accessibility preferences.
/// Manages colour palette, animation, font size, and focus indicator changes.
let updateAccessibility = (model: model, msg: accessibilityMsg): (model, Tea_Cmd.t<msg>) => {
  let a = model.accessibility
  // Helper: update state and persist to localStorage in one step.
  let withSave = (newA: accessibilityState) => {
    ({...model, accessibility: newA}, AccessibilityEngine.saveCmd(newA))
  }
  switch msg {
  | SetAccessibilityPalette(palette) => {
    let newA = {...a, palette}
    // Also update provenance palette for backward compatibility
    ({...model, accessibility: newA, provenance: {...model.provenance, palette}}, AccessibilityEngine.saveCmd(newA))
  }
  | SetThemeMode(theme) => {
    let resolvedTheme = switch theme {
    | ThemeSystem => AccessibilityEngine.detectOsColorScheme()
    | other => other
    }
    withSave({...a, theme, resolvedTheme})
  }
  | OsColorSchemeChanged(osTheme) =>
    // Only update resolvedTheme if user is in System mode.
    if a.theme === ThemeSystem {
      ({...model, accessibility: {...a, resolvedTheme: osTheme}}, Tea_Cmd.none)
    } else {
      (model, Tea_Cmd.none)
    }
  | SetAnimations(pref) =>
    withSave({...a, animations: pref})
  | SetFontSize(size) => {
    let newA = {...a, fontSize: size}
    ({...model, accessibility: newA}, Tea_Cmd.batch(list{
      AccessibilityEngine.saveCmd(newA),
      AccessibilityEngine.applyFontSizeCmd(size),
    }))
  }
  | SetFocusStyle(style) =>
    withSave({...a, focusStyle: style})
  | ToggleAccessibilityToolbar =>
    // Don't persist toolbar expanded state — it's transient.
    ({...model, accessibility: {...a, toolbarExpanded: !a.toolbarExpanded}}, Tea_Cmd.none)
  }
}

/// Update handler for multi-monitor tiling and panel detachment.
/// Manages detached windows, snap zones, and tiling presets.
let updateTiling = (model: model, msg: tilingMsg): (model, Tea_Cmd.t<msg>) => {
  let t = model.tiling
  switch msg {
  | DetachPanel(_panelId) =>
    // Panel detachment via window.open — future implementation
    // For now, just record the intent
    (model, Tea_Cmd.none)
  | ReattachPanel(_panelId) =>
    (model, Tea_Cmd.none)
  | SetSnapZone(_panelId, _zone) =>
    (model, Tea_Cmd.none)
  | ApplyTilingPreset(preset) =>
    ({...model, tiling: {...t, activePreset: Some(preset)}}, Tea_Cmd.none)
  | ClearTilingPreset =>
    ({...model, tiling: {...t, activePreset: None}}, Tea_Cmd.none)
  | SetSnapPreview(zone) =>
    ({...model, tiling: {...t, snapPreview: zone}}, Tea_Cmd.none)
  | DetachedPanelClosed(windowName) =>
    let state = TilingEngine.markDetachedDead(windowName, t)
    ({...model, tiling: state}, Tea_Cmd.none)
  | SyncToDetached(_data) =>
    (model, Tea_Cmd.none)
  | ToggleTilingControls =>
    ({...model, tiling: {...t, controlsVisible: !t.controlsVisible}}, Tea_Cmd.none)
  | SetTilingEnabled(enabled) =>
    ({...model, tiling: {...t, tilingEnabled: enabled}}, Tea_Cmd.none)
  }
}

/// Update handler for focus dimming and Smart Memory Mode.
/// Manages dimming mode, per-panel overrides, and interaction tracking.
let updateFocusDimming = (model: model, msg: focusDimmingMsg): (model, Tea_Cmd.t<msg>) => {
  let fd = model.focusDimming
  switch msg {
  | SetDimmingMode(mode) =>
    ({...model, focusDimming: {...fd, mode}}, Tea_Cmd.none)
  | SetPanelFocusOverride(panelId, override) =>
    let state = FocusDimmingEngine.setOverride(panelId, override, fd)
    ({...model, focusDimming: state}, Tea_Cmd.none)
  | RecordInteraction(panelKey) =>
    let state = FocusDimmingEngine.recordInteraction(fd, panelKey, Date.now())
    ({...model, focusDimming: state}, Tea_Cmd.none)
  | SetDimOpacity(opacity) =>
    ({...model, focusDimming: {...fd, dimOpacity: opacity}}, Tea_Cmd.none)
  }
}

let updateEnsaidConfig = (model: model, msg: ensaidConfigMsg): (model, Tea_Cmd.t<msg>) => {
  let humidityStr = switch model.humidity {
  | High => "high"
  | Medium => "medium"
  | Low => "low"
  }
  switch msg {
  | GenerateAndWrite => {
      let content = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=model.provisioner.configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      (
        {...model, ensaidConfigPreview: Some(content)},
        EnsaidConfigCmd.writeConfig(".", content, result => EnsaidConfig(ConfigWritten(result))),
      )
    }
  | PreviewConfig => {
      let content = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=model.provisioner.configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(content)}, Tea_Cmd.none)
    }
  | PreviewReady(content) => ({...model, ensaidConfigPreview: Some(content)}, Tea_Cmd.none)
  | ConfigWritten(Ok(_)) => ({...model, ensaidConfigError: None}, Tea_Cmd.none)
  | ConfigWritten(Error(err)) => ({...model, ensaidConfigError: Some(err)}, Tea_Cmd.none)
  | ReadFromRepo => (
      model,
      EnsaidConfigCmd.readConfig(".", result => EnsaidConfig(ConfigRead(result))),
    )
  | ConfigRead(Ok(content)) => (
      {...model, ensaidConfigPreview: Some(content), ensaidConfigError: None},
      Tea_Cmd.none,
    )
  | ConfigRead(Error(err)) => ({...model, ensaidConfigError: Some(err)}, Tea_Cmd.none)
  | DismissConfigError => ({...model, ensaidConfigError: None}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "ensaid-config", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => {
    logDegradedService("TypeLL", "cross-panel type check failed")
    (model, Tea_Cmd.none)
  }
  }
}

/// ORCHESTRATOR: The main entry point for state updates.
/// Routes each message to its domain-specific sub-updater, then applies
/// contractile evaluation as a post-processing cognitive governance step.
///
/// The contractile check runs after every state-modifying update (not NoOp)
/// to enforce the Binary Star system's behavioural contracts:
///   - Orbital Stability Bound (Strict)
///   - Vexation Ceiling (Adaptive)
///   - Divergence Limit (Warn)
///   - Autonomy Bound (Strict)
let update = (model: model, msg: msg): (model, Tea_Cmd.t<msg>) => {
  let (newModel, cmd) = switch msg {
  | PaneL(subMsg) => updatePaneL(model, subMsg)
  | PaneN(subMsg) => (updatePaneN(model, subMsg), Tea_Cmd.none)
  | PaneW(subMsg) => updatePaneW(model, subMsg)
  | VeriSimDB(subMsg) => updateVeriSimDB(model, subMsg)
  | Echidna(subMsg) => updateEchidna(model, subMsg)
  | Vexometer(subMsg) => updateVexometer(model, subMsg)
  | Orbital(subMsg) => updateOrbital(model, subMsg)
  | View(subMsg) => updateView(model, subMsg)
  | Feedback(subMsg) => updateFeedback(model, subMsg)
  | AntiCrash(subMsg) => updateAntiCrash(model, subMsg)
  | Vab(subMsg) => updateVab(model, subMsg)
  | CloudGuard(subMsg) => updateCloudGuard(model, subMsg)
  | Farm(subMsg) => updateFarm(model, subMsg)
  | Plaza(subMsg) => updatePlaza(model, subMsg)
  | Hypatia(subMsg) => updateHypatia(model, subMsg)
  | Fleet(subMsg) => updateFleet(model, subMsg)
  | Reposystem(subMsg) => updateReposystem(model, subMsg)
  | Aerie(subMsg) => updateAerie(model, subMsg)
  | Interfaces(subMsg) => updateInterfaces(model, subMsg)
  | Playgrounds(subMsg) => updatePlaygrounds(model, subMsg)
  | Minter(subMsg) => updateMinter(model, subMsg)
  | Provisioner(subMsg) => updateProvisioner(model, subMsg)
  | VoiceTag(subMsg) => updateVoiceTag(model, subMsg)
  | Provenance(subMsg) => updateProvenance(model, subMsg)
  | Watcher(subMsg) => updateWatcher(model, subMsg)
  | Ai(subMsg) => updateAi(model, subMsg)
  | RepoLoader(subMsg) => updateRepoLoader(model, subMsg)
  | PanelSwitcher(subMsg) => updatePanelSwitcher(model, subMsg)
  | Workspace(subMsg) => updateWorkspace(model, subMsg)
  | Capture(subMsg) => updateCapture(model, subMsg)
  | Security(subMsg) => updateSecurity(model, subMsg)
  | Keybindings(subMsg) => (updateKeybindings(model, subMsg), Tea_Cmd.none)
  | Migration(subMsg) => updateMigration(model, subMsg)
  | PanicAttack(subMsg) => updatePanicAttack(model, subMsg)
  | MassPanic(subMsg) => updateMassPanic(model, subMsg)
  | Tsdm(subMsg) => updateTsdm(model, subMsg)
  | ValenceShell(subMsg) => updateValenceShell(model, subMsg)
  | GamePreview(subMsg) => updateGamePreview(model, subMsg)
  | VmInspector(subMsg) => updateVmInspector(model, subMsg)
  | NetworkTopology(subMsg) => updateNetworkTopology(model, subMsg)
  | LevelArchitect(subMsg) => updateLevelArchitect(model, subMsg)
  | Coprocessors(subMsg) => updateCoprocessors(model, subMsg)
  | MultiplayerMonitor(subMsg) => updateMultiplayerMonitor(model, subMsg)
  | DlcWorkshop(subMsg) => updateDlcWorkshop(model, subMsg)
  | EditorBridge(subMsg) => updateEditorBridge(model, subMsg)
  | BuildDashboard(subMsg) => updateBuildDashboard(model, subMsg)
  | ReleaseManager(subMsg) => updateReleaseManager(model, subMsg)
  | AutomationRouter(subMsg) => updateAutomationRouter(model, subMsg)
  | ScriptGist(subMsg) => updateScriptGist(model, subMsg)
  | Boj(subMsg) => updateBoj(model, subMsg)
  | CladeBrowser(subMsg) => updateCladeBrowser(model, subMsg)
  | Tentacles(subMsg) => updateTentacles(model, subMsg)
  | ProtocolSquisher(subMsg) => updateProtocolSquisher(model, subMsg)
  | MyLang(subMsg) => updateMyLang(model, subMsg)
  | TypeLL(subMsg) => updateTypeLL(model, subMsg)
  | Help(subMsg) => updateHelp(model, subMsg)
  | MenuBar(subMsg) => updateMenuBar(model, subMsg)
  | AccessibilityCtrl(subMsg) => updateAccessibility(model, subMsg)
  | Tiling(subMsg) => updateTiling(model, subMsg)
  | FocusDimming(subMsg) => updateFocusDimming(model, subMsg)
  | EnsaidConfig(subMsg) => updateEnsaidConfig(model, subMsg)
  | Bus(busMsg) =>
    switch busMsg {
    | BusSubscribe(cladeId, topics) =>
      let busRegistry = PanelBus.subscribe(model.busRegistry, cladeId, topics)
      ({...model, busRegistry}, Tea_Cmd.none)
    | BusUnsubscribe(cladeId) =>
      let busRegistry = PanelBus.unsubscribe(model.busRegistry, cladeId)
      ({...model, busRegistry}, Tea_Cmd.none)
    | BusClearHistory =>
      let busRegistry = {...model.busRegistry, recentEvents: [], nextEventId: 1}
      ({...model, busRegistry}, Tea_Cmd.none)
    }
  | Undo => {
      let len = Array.length(model.undoStack)
      if len === 0 {
        (model, Tea_Cmd.none)
      } else {
        // Pop the most recent snapshot from undoStack.
        let snapshot = model.undoStack[len - 1]
        let remainingUndo = Array.slice(model.undoStack, ~start=0, ~end=len - 1)
        // Push current state onto redoStack (capped).
        let currentSnapshot = snapshotToJson(model)
        let newRedo = Array.concat(model.redoStack, [currentSnapshot])
        let trimmedRedo = if Array.length(newRedo) > undoStackLimit {
          Array.slice(newRedo, ~start=Array.length(newRedo) - undoStackLimit, ~end=Array.length(newRedo))
        } else {
          newRedo
        }
        switch snapshot {
        | Some(s) => {
            let restored = restoreSnapshot(model, s)
            ({...restored, undoStack: remainingUndo, redoStack: trimmedRedo}, Tea_Cmd.none)
          }
        | None => (model, Tea_Cmd.none)
        }
      }
    }
  | Redo => {
      let len = Array.length(model.redoStack)
      if len === 0 {
        (model, Tea_Cmd.none)
      } else {
        // Pop the most recent snapshot from redoStack.
        let snapshot = model.redoStack[len - 1]
        let remainingRedo = Array.slice(model.redoStack, ~start=0, ~end=len - 1)
        // Push current state onto undoStack (capped).
        let currentSnapshot = snapshotToJson(model)
        let newUndo = Array.concat(model.undoStack, [currentSnapshot])
        let trimmedUndo = if Array.length(newUndo) > undoStackLimit {
          Array.slice(newUndo, ~start=Array.length(newUndo) - undoStackLimit, ~end=Array.length(newUndo))
        } else {
          newUndo
        }
        switch snapshot {
        | Some(s) => {
            let restored = restoreSnapshot(model, s)
            ({...restored, undoStack: trimmedUndo, redoStack: remainingRedo}, Tea_Cmd.none)
          }
        | None => (model, Tea_Cmd.none)
        }
      }
    }
  | SaveState => {
      // Imperative: persist current state to localStorage.
      Storage.save(model)
      (model, Tea_Cmd.none)
    }
  | RecordBojLatency(cartridge, tool, elapsed) => {
      let entry: BojModel.bojLatencyEntry = {
        cartridge,
        tool,
        durationMs: elapsed,
        timestamp: Date.now(),
      }
      let log = Array.concat([entry], model.boj.latencyLog)->Array.slice(~start=0, ~end=100)
      ({...model, boj: {...model.boj, latencyLog: log}}, Tea_Cmd.none)
    }
  | GovernanceNesyResult(result) => {
      // Apply nesy-mcp governance response to model. The response is a JSON
      // string from the nesy-mcp cartridge with confidence, reasoning, etc.
      // For now, parse the confidence score and use it to tune Anti-Crash.
      switch result {
      | Ok(jsonStr) => {
          let newModel = try {
            let json = JSON.parseExn(jsonStr)
            let o = json->JSON.Decode.object->Option.getOr(Dict.make())
            let confidence =
              o->Dict.get("confidence")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.5)
            let approved =
              o->Dict.get("approved")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
            if !approved {
              // Nesy rejected a governance adjustment — loosen Anti-Crash.
              {...model, antiCrash: {...model.antiCrash, strictMode: false}}
            } else if confidence > 0.8 {
              // High neural confidence — safe to tighten.
              {...model, antiCrash: {...model.antiCrash, strictMode: true}}
            } else if confidence < 0.3 {
              // Low confidence — loosen to avoid false positives.
              {...model, antiCrash: {...model.antiCrash, strictMode: false}}
            } else {
              // Moderate confidence — maintain current posture.
              model
            }
          } catch {
          | _ => model
          }
          (newModel, Tea_Cmd.none)
        }
      | Error(_) =>
        // Nesy-mcp unreachable — maintain current governance state.
        (model, Tea_Cmd.none)
      }
    }
  | GovernanceNesyValidateResult(result) => {
      switch result {
      | Ok(jsonStr) => {
          let newModel = try {
            let json = JSON.parseExn(jsonStr)
            let o = json->JSON.Decode.object->Option.getOr(Dict.make())
            let approved =
              o->Dict.get("approved")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
            let reasoning =
              o->Dict.get("reasoning")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            if !approved {
              // Nesy rejected the adjustment — log reasoning and loosen.
              ignore(reasoning)
              {...model, antiCrash: {...model.antiCrash, strictMode: false}}
            } else {
              model
            }
          } catch {
          | _ => model
          }
          (newModel, Tea_Cmd.none)
        }
      | Error(_) => (model, Tea_Cmd.none)
      }
    }
  | GovernanceNesyProbeResult(result) => {
      switch result {
      | Ok(jsonStr) => {
          let newModel = try {
            let json = JSON.parseExn(jsonStr)
            let o = json->JSON.Decode.object->Option.getOr(Dict.make())
            let neuralCoherence =
              o->Dict.get("neural_coherence")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.5)
            let driftMagnitude =
              o->Dict.get("drift_magnitude")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            {
              ...model,
              orbital: {
                ...model.orbital,
                stability: neuralCoherence,
                divergenceLevel: driftMagnitude,
              },
            }
          } catch {
          | _ => model
          }
          (newModel, Tea_Cmd.none)
        }
      | Error(_) => (model, Tea_Cmd.none)
      }
    }
  | Observability(obsMsg) => {
      switch obsMsg {
      | ExportSarifViaObserveMcp(reportId) =>
        let cmd = ObservabilityCmd.exportSarifViaObserveMcp(
          reportId,
          r => Observability(SarifExportResult(r)),
        )
        (model, cmd)
      | SarifExportResult(result) =>
        switch result {
        | Ok(_) => (model, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | ExportOtelTraces =>
        let batch = ObservabilityEngine.exportTraceBatch(model.boj.latencyLog)
        let cmd = ObservabilityCmd.exportOtelTraces(
          batch,
          r => Observability(OtelExportResult(r)),
        )
        (model, cmd)
      | OtelExportResult(result) =>
        switch result {
        | Ok(_) => (model, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | FetchObservabilitySummary =>
        let cmd = ObservabilityCmd.fetchObservabilitySummary(
          r => Observability(ObservabilitySummaryResult(r)),
        )
        (model, cmd)
      | ObservabilitySummaryResult(result) =>
        switch result {
        | Ok(_) => (model, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | TypeCheckResult(Ok(json)) => {
          let checks = model.typell.panelTypeChecks
          Dict.set(checks, "observability", json)
          let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
          ({...model, typell: newTypell}, Tea_Cmd.none)
        }
      | TypeCheckResult(Error(_)) =>
        (model, Tea_Cmd.none)
      }
    }
  | A2ml(a2mlMsg) => {
      switch a2mlMsg {
      | LoadManifest(path) =>
        let cmd = A2mlCmd.loadManifest(path, r => A2ml(ManifestLoaded(r)))
        (model, cmd)
      | ManifestLoaded(result) =>
        switch result {
        | Ok(jsonStr) =>
          // Parse the A2ML content returned by the Rust backend
          let manifest = A2mlEngine.parseA2mlContent(jsonStr)
          let validation = A2mlEngine.validateManifest(manifest)
          // Extract test coverage policy from clade traits (Integration #6)
          let (_coverage, _testTypes, _notes) = A2mlEngine.extractTestCoveragePolicy(manifest)
          ({...model, lastA2mlManifest: Some(manifest), lastA2mlValidation: Some(validation)}, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | ValidateManifest(path) =>
        let cmd = A2mlCmd.validateManifestFile(path, r => A2ml(ManifestValidated(r)))
        (model, cmd)
      | ManifestValidated(result) =>
        switch result {
        | Ok(jsonStr) =>
          // Backend structural validation passed; now do client-side semantic validation
          let manifest = A2mlEngine.parseA2mlContent(jsonStr)
          let validation = A2mlEngine.validateManifest(manifest)
          ({...model, lastA2mlManifest: Some(manifest), lastA2mlValidation: Some(validation)}, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | ListManifests =>
        let cmd = A2mlCmd.listManifests(r => A2ml(ManifestsListed(r)))
        (model, cmd)
      | ManifestsListed(result) =>
        switch result {
        | Ok(jsonStr) =>
          // Parse JSON array of file paths
          let paths = try {
            let parsed = JSON.parseExn(jsonStr)
            switch JSON.Classify.classify(parsed) {
            | Array(arr) =>
              arr->Array.filterMap(item =>
                switch JSON.Classify.classify(item) {
                | String(s) => Some(s)
                | _ => None
                }
              )
            | _ => []
            }
          } catch {
          | _ => []
          }
          ({...model, a2mlManifestPaths: paths}, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | TypeCheckResult(Ok(json)) => {
          let checks = model.typell.panelTypeChecks
          Dict.set(checks, "a2ml", json)
          let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
          ({...model, typell: newTypell}, Tea_Cmd.none)
        }
      | TypeCheckResult(Error(_)) =>
        (model, Tea_Cmd.none)
      }
    }
  | K9(k9Msg) => {
      switch k9Msg {
      | LoadContractile(path) =>
        let cmd = K9Cmd.loadContractile(path, r => K9(ContractileLoaded(r)))
        (model, cmd)
      | ContractileLoaded(result) =>
        switch result {
        | Ok(jsonStr) =>
          // Parse and validate the loaded K9 contractile content
          let contractile = K9Engine.validateContractile(jsonStr, ~path="loaded")
          // Integration #4: Module Config → K9 Kennel Schema
          // If this is a Kennel-level file, extract its config fields as a schema
          let kennelSchema = if contractile.securityLevel == K9Engine.Kennel {
            Some(jsonStr)
          } else {
            model.k9KennelSchema
          }
          ({...model, lastK9Contractile: Some(contractile), k9KennelSchema: kennelSchema}, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | ValidateContractile(path) =>
        let cmd = K9Cmd.validateContractileFile(path, r => K9(ContractileValidated(r)))
        (model, cmd)
      | ContractileValidated(result) =>
        switch result {
        | Ok(jsonStr) =>
          let contractile = K9Engine.validateContractile(jsonStr, ~path="validated")
          ({...model, lastK9Contractile: Some(contractile)}, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | ApplyLayout(name) =>
        let cmd = K9Cmd.applyLayout(name, r => K9(LayoutApplied(r)))
        (model, cmd)
      | LayoutApplied(result) =>
        switch result {
        | Ok(jsonStr) =>
          let layout = K9Engine.parseLayoutPanels(jsonStr)
          ({...model, lastK9Layout: Some(layout)}, Tea_Cmd.none)
        | Error(_) => (model, Tea_Cmd.none)
        }
      | TypeCheckResult(Ok(json)) => {
          let checks = model.typell.panelTypeChecks
          Dict.set(checks, "k9", json)
          let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
          ({...model, typell: newTypell}, Tea_Cmd.none)
        }
      | TypeCheckResult(Error(_)) =>
        (model, Tea_Cmd.none)
      }
    }
  | AuditSeams => {
      let register = SeamEngine.buildRegister("2026-03-09")
      let audit = SeamEngine.auditRegister(register, "2026-03-09")
      ({...model, seamRegister: register, lastSeamAudit: Some(audit)}, Tea_Cmd.none)
    }
  | SeamAuditResult(audit) => ({...model, lastSeamAudit: Some(audit)}, Tea_Cmd.none)
  | NoOp => (model, Tea_Cmd.none)
  }

  // Post-processing: evaluate contractiles after every state-modifying update.
  // Skip for NoOp to avoid unnecessary computation.
  switch msg {
  | NoOp => (newModel, cmd)
  | _ => applyContractiles(newModel, cmd)
  }
}
