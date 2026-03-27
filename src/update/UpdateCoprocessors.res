// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for the Coprocessors panel.
/// Manages coprocessor metrics, call log, heatmap, backend toggling, compute engine
/// queries, device discovery, BoJ routing, Zig FFI local dispatch, and smart routing.

open Model
open Msg

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
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

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

    | None => None
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
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

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

    | None => None
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
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

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

    | None => None
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
    // Phase 3: Use SmartRouter for per-operation intelligent dispatch.
    let (decision, newHistory) = CoprocessorsEngine.smartRouteAndRecord(cp, operation)
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
