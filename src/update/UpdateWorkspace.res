// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Workspace — modes, groups, arrangements, sessions,
/// protection, execution mode, checkpoints, metadata viewer.

open Model
open Msg

let updateWorkspace = (model: model, msg: workspaceMsg): (model, Tea_Cmd.t<msg>) => {
  let ws = model.workspace
  switch msg {
  | SetWorkspaceMode(mode) => ({...model, workspace: {...ws, mode}}, Tea_Cmd.none)
  | CycleWorkspaceMode => (
      {...model, workspace: {...ws, mode: WorkspaceEngine.cycleMode(ws.mode)}},
      Tea_Cmd.none,
    )
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
  | CreateGroup(id, name, panelIds) => (
      {
        ...model,
        workspace: {...ws, groups: WorkspaceEngine.createGroup(ws.groups, id, name, panelIds)},
      },
      Tea_Cmd.none,
    )
  | DisbandGroup(id) => (
      {...model, workspace: {...ws, groups: WorkspaceEngine.disbandGroup(ws.groups, id)}},
      Tea_Cmd.none,
    )
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
  | ToggleGroupVisibility(id) => (
      {...model, workspace: {...ws, groups: WorkspaceEngine.toggleGroupVisibility(ws.groups, id)}},
      Tea_Cmd.none,
    )
  | PushToBack(id) => (
      {...model, workspace: {...ws, groups: WorkspaceEngine.pushToBack(ws.groups, id)}},
      Tea_Cmd.none,
    )
  | PullToFront(id) => (
      {...model, workspace: {...ws, groups: WorkspaceEngine.pullToFront(ws.groups, id)}},
      Tea_Cmd.none,
    )
  | SaveArrangement(id, name) => {
      let arr: arrangement = {
        id,
        name,
        positions: [],
        groups: ws.groups,
        builtIn: false,
        lastSaved: Date.now(),
      }
      let arrangements = Array.concat(ws.arrangements->Array.filter(a => a.id !== id), [arr])
      let json = `{"id":"${id}","name":"${name}","builtIn":false,"lastSaved":${Float.toString(
          Date.now(),
        )},"positions":[],"groups":[]}`
      (
        {...model, workspace: {...ws, arrangements}},
        Tea_Cmd.batch(list{
          WorkspaceCmd.saveArrangement(json),
          TypeLLService.checkConfigTypes(json, "workspace", result => Workspace(
            TypeCheckResult(result),
          )),
        }),
      )
    }
  | LoadArrangement(id) => (
      {...model, workspace: {...ws, activeArrangementId: Some(id)}},
      Tea_Cmd.none,
    )
  | DeleteArrangement(id) => (
      {
        ...model,
        workspace: {...ws, arrangements: WorkspaceEngine.deleteArrangement(ws.arrangements, id)},
      },
      Tea_Cmd.none,
    )
  | ArrangementsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let loaded = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          json
          ->JSON.Decode.array
          ->Option.getOr([])
          ->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            let id = gs(o, "id")
            if id !== "" {
              Some(
                (
                  {
                    id,
                    name: gs(o, "name"),
                    positions: [],
                    groups: [],
                    builtIn: gb(o, "builtIn"),
                    lastSaved: gf(o, "lastSaved"),
                  }: arrangement
                ),
              )
            } else {
              None
            }
          })

        | None => []
        }
        let merged = Array.concat(
          ws.arrangements->Array.filter(a => a.builtIn),
          loaded->Array.filter(a => !a.builtIn),
        )
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
  | DeleteSession(id) => (
      {...model, workspace: {...ws, sessions: WorkspaceEngine.deleteSession(ws.sessions, id)}},
      Tea_Cmd.none,
    )
  | SwitchSession(id) => ({...model, workspace: {...ws, activeSessionId: Some(id)}}, Tea_Cmd.none)
  | SessionsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let loaded = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          json
          ->JSON.Decode.array
          ->Option.getOr([])
          ->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let id = gs(o, "id")
            if id !== "" {
              Some(
                (
                  {
                    id,
                    name: gs(o, "name"),
                    repoPath: o->Dict.get("repoPath")->Option.flatMap(JSON.Decode.string),
                    arrangementId: o->Dict.get("arrangementId")->Option.flatMap(JSON.Decode.string),
                    protection: Open,
                    executionMode: Live,
                    workspaceMode: EverythingMode,
                    checkpoints: [],
                    created: gf(o, "created"),
                    lastActive: gf(o, "lastActive"),
                    forkedFrom: o->Dict.get("forkedFrom")->Option.flatMap(JSON.Decode.string),
                  }: session
                ),
              )
            } else {
              None
            }
          })

        | None => []
        }
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
  | SystemInfoLoaded(result) => switch result {
    | Ok(jsonStr) => {
        let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
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

        | None => None
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
  | ToggleConfigurator => (
      {...model, workspace: {...ws, configuratorOpen: !ws.configuratorOpen}},
      Tea_Cmd.none,
    )
  | SetConfiguratorTab(tab) => ({...model, workspace: {...ws, configuratorTab: tab}}, Tea_Cmd.none)
  | ViewMetadata(item) => (
      {...model, workspace: {...ws, viewingMetadata: Some(item)}},
      Tea_Cmd.none,
    )
  | CloseMetadata => (
      {...model, workspace: {...ws, viewingMetadata: None, metadataContent: None}},
      Tea_Cmd.none,
    )
  | MetadataLoaded(result) => switch result {
    | Ok(content) => ({...model, workspace: {...ws, metadataContent: Some(content)}}, Tea_Cmd.none)
    | Error(_) => (model, Tea_Cmd.none)
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
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
