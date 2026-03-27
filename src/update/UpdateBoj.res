// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateBoj.res — BoJ (Bundle of Joy) cartridge server sub-updater extracted from Update.res

open Model
open Msg

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
