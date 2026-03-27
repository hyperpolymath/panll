// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for ECHIDNA (Theorem Prover Backend).
/// Manages the ECHIDNA connection state, prover catalog, proof submission lifecycle,
/// theorem search, interactive proof sessions, tactic suggestions, UI toggles,
/// enterprise model checking (MOF/OCL), and BoJ routing.

open Model
open Msg

// ===========================================================================
// ECHIDNA Parsers
// ===========================================================================

/// Parse the ECHIDNA version string from a health check JSON response.
/// Expected shape: `{ "status": "ok", "version": "0.4.2" }`.
let parseEchidnaVersion = (json: string): option<string> =>
  Decoders.decodeOption(Tea_Json.field("version", Tea_Json.string), json)

/// Parse the ECHIDNA prover catalog from a list provers JSON response.
/// Expected shape: `[{ "name": "z3", "tier": "SMT", "complexity": "NP" }, ...]`
/// or `{ "provers": [...] }` wrapper.
let parseEchidnaProvers = (json: string): array<echidnaProver> => {
  switch Decoders.decodeOption(Tea_Json.value, json) {
  | Some(parsed) =>
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
  | None => []
  }
}

/// Parse an ECHIDNA dispatch result from a proof/verify JSON response.
/// Maps trust_level integers (1-5) to the echidnaTrustLevel variant,
/// parses the axiom report, and extracts prover telemetry.
let parseEchidnaDispatchResult = (json: string): option<echidnaDispatchResult> => {
  switch Decoders.decodeOption(Tea_Json.value, json) {
  | Some(parsed) =>
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
                  let dangerLevel: axiomDangerLevel = switch aGetStr("danger_level") {
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
  | None => None
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
  switch Decoders.decodeOption(Tea_Json.value, json) {
  | Some(parsed) =>
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
  | None => None
  }
}

/// Parse a TacticResponse JSON into (success, updated session state).
/// Expected shape: `{ "success": true, "proof_state": { ...ProofResponse... } }`
let parseTacticResponse = (json: string): option<(bool, echidnaSessionState)> => {
  switch Decoders.decodeOption(Tea_Json.value, json) {
  | Some(parsed) =>
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
  | None => None
  }
}

/// Parse tactic suggestions JSON into an array of echidnaTacticSuggestion.
/// Expected shape: `[{ "name": "intro", "args": ["x"], "description": "...",
///   "confidence": 0.85 }, ...]`
let parseTacticSuggestions = (json: string): array<echidnaTacticSuggestion> => {
  switch Decoders.decodeOption(Tea_Json.value, json) {
  | Some(parsed) =>
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
  | None => []
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
      GossamerCmd.checkEchidnaHealth(result =>
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
      GossamerCmd.listEchidnaProvers(result => Echidna(ProversLoaded(result))),
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
        GossamerCmd.echidnaProve(ec.proofInput, ec.selectedProver, result =>
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
      GossamerCmd.echidnaVerify(ec.proofInput, result => Echidna(VerifyResult(result))),
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
      GossamerCmd.echidnaSearchTheorems(query, result => Echidna(SearchResult(result))),
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
        GossamerCmd.createEchidnaSession(ec.proofInput, prover, result =>
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
          GossamerCmd.suggestEchidnaTactics(s.sessionId, 5, result =>
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
        GossamerCmd.applyEchidnaTactic(s.sessionId, name, args, result =>
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
            GossamerCmd.suggestEchidnaTactics(updatedSession.sessionId, 5, result =>
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
        GossamerCmd.getEchidnaSession(s.sessionId, result =>
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
        GossamerCmd.suggestEchidnaTactics(s.sessionId, 5, result =>
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
    UpdateHelpers.logDegradedService("TypeLL", "proof obligation generation failed")
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
    UpdateHelpers.logDegradedService("ECHIDNA", "XMI model import failed")
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
      UpdateHelpers.logDegradedService("ECHIDNA", "OCL constraint check failed")
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
