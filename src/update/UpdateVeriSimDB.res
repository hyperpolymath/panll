// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for VeriSimDB (Database Backend).
/// Manages the VeriSimDB connection state, VCL query lifecycle, entity browsing,
/// drift detection status, normalisation, entity detail, telemetry, orchestration
/// status, proof obligations, inference suggestions, and BoJ routing toggles.

open Model
open Msg

// ===========================================================================
// VeriSimDB Parsers
// ===========================================================================

/// Parse proof obligations from a VCL-total JSON response.
/// VCL-total queries return a `proof_certificate` object with an array of proofs.
/// Each proof has type, contract, verified status, and hash fields.
/// Tea_Json decoder for a single proof obligation.
let proofObligationDecoder: Tea_Json.decoder<proofObligation> = Tea_Json.map4(
  (proofType, contractName, verifiedStr, proofHash) => {
    let status = if verifiedStr == "true" {
      "verified"
    } else {
      "pending"
    }
    {proofType, contractName, status, proofHash}
  },
  Decoders.stringField("type"),
  Decoders.stringField("contract"),
  Decoders.stringField("verified"),
  Decoders.stringField("hash"),
)

let parseProofObligations = (json: string): array<proofObligation> =>
  Decoders.decodeWithDefault(
    Tea_Json.at(["proof_certificate", "proofs"], Decoders.lenientArray(proofObligationDecoder)),
    [],
    json,
  )

/// Parse drift scores from a drift status JSON response.
/// Returns structured drift scores for all 8 octad modalities.
/// Tea_Json decoder for drift scores across all 8 octad modalities.
let driftScoresDecoder: Tea_Json.decoder<driftScores> = Decoders.map8(
  (graph, vector, tensor, semantic, document, temporal, provenance, spatial) => {
    graph,
    vector,
    tensor,
    semantic,
    document,
    temporal,
    provenance,
    spatial,
  },
  Decoders.floatField("graph"),
  Decoders.floatField("vector"),
  Decoders.floatField("tensor"),
  Decoders.floatField("semantic"),
  Decoders.floatField("document"),
  Decoders.floatField("temporal"),
  Decoders.floatField("provenance"),
  Decoders.floatField("spatial"),
)

let parseDriftScores = (json: string): option<driftScores> =>
  Decoders.decodeOption(driftScoresDecoder, json)

/// Parse a telemetry snapshot from the VeriSimDB reporter JSON response.
/// Extracts aggregate-only product development metrics — no PII or query content.
let parseTelemetrySnapshot = (json: string): option<telemetrySnapshot> => {
  switch Decoders.decodeOption(Tea_Json.value, json) {
  | Some(parsedValue) =>
    let parsed = parsedValue
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
            | Object(pcts) => Dict.keysToArray(pcts)->Array.map(key => (key, getFloat(pcts, key)))
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
            | Object(types) => Dict.keysToArray(types)->Array.map(key => (key, getInt(types, key)))
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
            | Object(types) => Dict.keysToArray(types)->Array.map(key => (key, getInt(types, key)))
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
  | None => None
  }
}

// ===========================================================================
// VeriSimDB Sub-Updater
// ===========================================================================

/// STATE TRANSITION: VeriSimDB (Database Backend)
/// Manages the VeriSimDB connection state, VCL query lifecycle, entity browsing,
/// drift detection status, normalisation, and entity detail. Each message either
/// triggers a Gossamer command (side effect) or updates model state from a command
/// result.
let updateVeriSimDB = (model: model, msg: verisimdbMsg): (model, Tea_Cmd.t<msg>) => {
  let db = model.verisim
  switch msg {
  | CheckHealth => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "database-mcp",
          "health",
          "",
          result => VeriSimDB(HealthResult(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        GossamerCmd.checkVeriSimDBHealth(result => VeriSimDB(HealthResult(result)))
      }
      (model, cmd)
    }
  | HealthResult(result) =>
    switch result {
    | Ok(_json) => ({...model, verisim: {...db, connected: true, queryError: None}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, verisim: {...db, connected: false, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | SubmitQuery(query) => {
      // #4: Optionally validate VCL through Anti-Crash before execution.
      let antiCrashCmd = if db.antiCrashValidation {
        let tokenId = "t-" ++ Int.toString(model.paneN.nextTokenId)
        let token: neuralToken = {
          id: tokenId,
          content: query,
          timestamp: 0.0,
          confidence: 0.5,
          validated: false,
          source: VeriSimInference,
          category: Observation,
          emittedDuring: model.paneN.agency.phase,
          causedBy: model.paneN.activeCausalChain,
          proofHash: None,
        }
        Tea_Cmd.msg(AntiCrash(ValidateToken(token)))
      } else {
        Tea_Cmd.none
      }
      // #5: Track VCL query count for Vexometer cognitive load.
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
        BojCmd.invokeCartridgeWithLatency(
          "database-mcp",
          "query",
          query,
          result => VeriSimDB(QueryResult(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        GossamerCmd.queryVeriSimDB(query, result => VeriSimDB(QueryResult(result)))
      }
      (
        {...model, verisim: newDb},
        Tea_Cmd.batch(list{
          queryCmd,
          TypeLLService.checkVclTypes(query, result => VeriSimDB(VclTypeCheckResult(result))),
          antiCrashCmd,
          Tea_Cmd.msg(Vexometer(RecordVclQuery)),
        }),
      )
    }
  | UpdateQueryInput(text) => ({...model, verisim: {...db, lastQuery: text}}, Tea_Cmd.none)
  | QueryResult(result) =>
    switch result {
    | Ok(json) =>
      // Parse proof obligations from VCL-total responses
      let proofs = parseProofObligations(json)
      (
        {
          ...model,
          verisim: {...db, queryResult: Some(json), queryError: None, proofObligations: proofs},
        },
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, verisim: {...db, queryResult: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ListEntities => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "database-mcp",
          "list_entities",
          "{\"limit\":50,\"offset\":0}",
          result => VeriSimDB(EntitiesLoaded(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        GossamerCmd.listOctads(50, 0, result => VeriSimDB(EntitiesLoaded(result)))
      }
      (model, cmd)
    }
  | EntitiesLoaded(result) =>
    switch result {
    | Ok(_json) => ({...model, verisim: {...db, queryError: None}}, Tea_Cmd.none)
    | Error(err) => ({...model, verisim: {...db, queryError: Some(err)}}, Tea_Cmd.none)
    }
  | SelectEntity(entityId) => {
      let (driftCmd, detailCmd) = if db.bojRouting {
        (
          BojCmd.invokeCartridgeWithLatency(
            "database-mcp",
            "drift",
            entityId,
            result => VeriSimDB(DriftLoaded(result)),
            (c, t, e) => RecordBojLatency(c, t, e),
          ),
          BojCmd.invokeCartridgeWithLatency(
            "database-mcp",
            "entity_detail",
            entityId,
            result => VeriSimDB(EntityDetailLoaded(result)),
            (c, t, e) => RecordBojLatency(c, t, e),
          ),
        )
      } else {
        (
          GossamerCmd.getDrift(entityId, result => VeriSimDB(DriftLoaded(result))),
          GossamerCmd.getEntityDetail(entityId, result => VeriSimDB(EntityDetailLoaded(result))),
        )
      }
      (
        {...model, verisim: {...db, selectedEntity: Some(entityId), entityDetail: None}},
        Tea_Cmd.batch(list{driftCmd, detailCmd}),
      )
    }
  | DriftLoaded(result) =>
    switch result {
    | Ok(json) =>
      let scores = parseDriftScores(json)
      (
        {
          ...model,
          verisim: {...db, driftStatus: Some(json), driftScores: scores, queryError: None},
        },
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, verisim: {...db, driftStatus: None, driftScores: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ToggleDbMenu => (
      {...model, verisim: {...db, dbMenuExpanded: !db.dbMenuExpanded}},
      Tea_Cmd.none,
    )
  | ClearQueryResult => (
      {
        ...model,
        verisim: {
          ...db,
          queryResult: None,
          queryError: None,
          proofObligations: [],
          lastTypeCheck: None,
        },
      },
      Tea_Cmd.none,
    )
  | TriggerNormalise(entityId) => (
      {...model, verisim: {...db, normalisingEntity: Some(entityId)}},
      GossamerCmd.triggerNormalise(entityId, result => VeriSimDB(NormaliseResult(result))),
    )
  | NormaliseResult(result) =>
    switch result {
    | Ok(_json) => (
        {...model, verisim: {...db, normalisingEntity: None, queryError: None}},
        // Refresh drift status after normalisation
        switch db.selectedEntity {
        | Some(entityId) => GossamerCmd.getDrift(entityId, result => VeriSimDB(DriftLoaded(result)))
        | None => Tea_Cmd.none
        },
      )
    | Error(err) => (
        {...model, verisim: {...db, normalisingEntity: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | LoadEntityDetail(entityId) => (
      model,
      GossamerCmd.getEntityDetail(entityId, result => VeriSimDB(EntityDetailLoaded(result))),
    )
  | EntityDetailLoaded(result) =>
    switch result {
    | Ok(json) => (
        {...model, verisim: {...db, entityDetail: Some(json), queryError: None}},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, verisim: {...db, entityDetail: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | FetchTelemetry => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "database-mcp",
          "telemetry",
          "",
          result => VeriSimDB(TelemetryLoaded(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        GossamerCmd.getTelemetry(result => VeriSimDB(TelemetryLoaded(result)))
      }
      (model, cmd)
    }
  | TelemetryLoaded(result) =>
    switch result {
    | Ok(json) =>
      let snapshot = parseTelemetrySnapshot(json)
      ({...model, verisim: {...db, telemetry: snapshot, queryError: None}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, verisim: {...db, telemetry: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ToggleTelemetryPanel => (
      {...model, verisim: {...db, telemetryVisible: !db.telemetryVisible}},
      Tea_Cmd.none,
    )
  | FetchOrchStatus => {
      let cmd = if db.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "database-mcp",
          "orch_status",
          "",
          result => VeriSimDB(OrchStatusLoaded(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        GossamerCmd.getOrchStatus(result => VeriSimDB(OrchStatusLoaded(result)))
      }
      (model, cmd)
    }
  | OrchStatusLoaded(result) =>
    switch result {
    | Ok(json) => (
        {...model, verisim: {...db, orchStatus: Some(json), queryError: None}},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, verisim: {...db, orchStatus: None, queryError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | VclTypeCheckResult(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, verisim: {...db, lastTypeCheck: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | VclTypeCheckResult(Error(_)) => {
      UpdateHelpers.logDegradedService(
        "TypeLL",
        "VCL type check failed — VCL workflow continues unblocked",
      )
      (model, Tea_Cmd.none)
    }
  // #2: Toggle proof obligation display in Panel-L.
  | ToggleProofDisplay => (
      {...model, verisim: {...db, proofDisplayActive: !db.proofDisplayActive}},
      Tea_Cmd.none,
    )
  // #3: Neural advisor inference suggestion for VCL.
  | InferenceSuggestion(suggestion) => (
      {
        ...model,
        verisim: {...db, inferenceStream: Array.concat(db.inferenceStream, [suggestion])},
      },
      Tea_Cmd.none,
    )
  | ClearInferenceSuggestions => ({...model, verisim: {...db, inferenceStream: []}}, Tea_Cmd.none)
  // #4: Toggle Anti-Crash validation of VCL queries.
  | ToggleAntiCrashValidation => (
      {...model, verisim: {...db, antiCrashValidation: !db.antiCrashValidation}},
      Tea_Cmd.none,
    )
  | ToggleVeriSimBojRouting => (
      {...model, verisim: {...db, bojRouting: !db.bojRouting}},
      Tea_Cmd.none,
    )
  }
}
