// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Update Engine — The state transition kernel.
///
/// This module implements the "Update" function of The Elm Architecture (TEA).
/// It is responsible for taking the current `model` and an incoming `msg`,
/// and producing a new version of the model along with any required
/// side-effect commands (`Tea_Cmd`).
///
/// Architecture:
///   1. Domain sub-updaters live in `src/update/Update*.res` modules
///   2. The main `update()` orchestrator routes messages to sub-updaters
///   3. Contractiles post-processing evaluates cognitive governance contracts
///      after every state-modifying update
///
/// DESIGN: Sub-updaters are pure — commands represent deferred side effects.
/// The only imperative call is `Storage.save()` in the SaveState handler.

open Model
open Msg

// ===========================================================================
// Import all domain sub-updaters from src/update/
// ===========================================================================

// Shared helpers (undo/redo, logging)
open UpdateHelpers

// Core panes
open UpdatePaneL
open UpdatePaneN
open UpdatePaneW

// Major subsystems
open UpdateVeriSimDB
open UpdateEchidna
open UpdateGovernance
open UpdateVab
open UpdateCloudGuard
open UpdateFarm
open UpdatePlaza
open UpdatePanelSwitcher
open UpdateReposystem
open UpdateAerie
open UpdateInterfaces
open UpdatePlaygrounds
open UpdateHypatia
open UpdateFleet
open UpdateMinter
open UpdateProvisioner
open UpdateVoiceTag
open UpdateProvenance
open UpdateWatcher
open UpdateAi
open UpdateRepoLoader
open UpdateWorkspace
open UpdateCapture
open UpdateSecurity
open UpdateKeybindings
open UpdateMigration
open UpdatePanicAttack
open UpdateMassPanic
open UpdateTsdm
open UpdateValenceShell
open UpdateGamePreview
open UpdateVmInspector
open UpdateNetworkTopology
open UpdateLevelArchitect
open UpdateCoprocessors
open UpdateMultiplayerMonitor
open UpdateDlcWorkshop
open UpdateUms
open UpdateEditorBridge
open UpdateBuildDashboard
open UpdateReleaseManager
open UpdateAutomationRouter
open UpdateScriptGist
open UpdateDatabases
open UpdateBoj
open UpdateCladeBrowser
open UpdateTentacles
open UpdateProtocolSquisher
open UpdateMyLang
open UpdateTypeLL
open UpdateHelp
open UpdateMenuBar
open UpdateAccessibility
open UpdateTiling
open UpdateFocusDimming
open UpdateEnsaidConfig
open UpdateTimeline
open UpdateStapeln
open UpdateEvangeliser
open UpdateLanguageForge
open UpdateTangleViz

// Grouped small updaters
open UpdateGameDevTesting
open UpdateGameDevBridges
open UpdateGameDevSpecific
open UpdateTeamCollab
open UpdateWiringInspector
open UpdateFloorRaise

// ===========================================================================
// Main Dispatcher
// ===========================================================================

/// The main TEA update function. Routes each message variant to its domain
/// sub-updater, then applies contractile post-processing.
let update = (model: model, msg: msg): (model, Tea_Cmd.t<msg>) => {
  let (newModel, cmd) = switch msg {
  // Core panes
  | PaneL(subMsg) => updatePaneL(model, subMsg)
  | PaneN(subMsg) => (updatePaneN(model, subMsg), Tea_Cmd.none)
  | PaneW(subMsg) => updatePaneW(model, subMsg)
  // Major subsystems
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
  | Oo7Toolchain(subMsg) => updateOo7Toolchain(model, subMsg)
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
  | Ums(subMsg) => updateUms(model, subMsg)
  | EditorBridge(subMsg) => updateEditorBridge(model, subMsg)
  | BuildDashboard(subMsg) => updateBuildDashboard(model, subMsg)
  | ReleaseManager(subMsg) => updateReleaseManager(model, subMsg)
  | AutomationRouter(subMsg) => updateAutomationRouter(model, subMsg)
  | ScriptGist(subMsg) => updateScriptGist(model, subMsg)
  | Databases(subMsg) => updateDatabases(model, subMsg)
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
  | Stapeln(subMsg) => updateStapeln(model, subMsg)
  | Evangeliser(subMsg) => updateEvangeliser(model, subMsg)
  | LanguageForge(subMsg) => updateLanguageForge(model, subMsg)
  | TangleViz(subMsg) => updateTangleViz(model, subMsg)
  | EnsaidConfig(subMsg) => updateEnsaidConfig(model, subMsg)
  | Timeline(subMsg) => updateTimeline(model, subMsg)
  // Game Dev panels — testing
  | UnitTestRunner(subMsg) => updateUnitTestRunner(model, subMsg)
  | FunctionalTester(subMsg) => updateFunctionalTester(model, subMsg)
  | RegressionGuard(subMsg) => updateRegressionGuard(model, subMsg)
  | PerformanceProfiler(subMsg) => updatePerformanceProfiler(model, subMsg)
  | LoadTester(subMsg) => updateLoadTester(model, subMsg)
  | SoakMonitor(subMsg) => updateSoakMonitor(model, subMsg)
  | CompatibilityMatrix(subMsg) => updateCompatibilityMatrix(model, subMsg)
  | ExploratoryWorkbench(subMsg) => updateExploratoryWorkbench(model, subMsg)
  | BetaFeedbackHub(subMsg) => updateBetaFeedbackHub(model, subMsg)
  | BalanceAnalyser(subMsg) => updateBalanceAnalyser(model, subMsg)
  // Game Dev panels — bridges
  | TypingBridge(subMsg) => updateTypingBridge(model, subMsg)
  | NeurosymBridge(subMsg) => updateNeurosymBridge(model, subMsg)
  | AgenticBridge(subMsg) => updateAgenticBridge(model, subMsg)
  | AutomationBridge(subMsg) => updateAutomationBridge(model, subMsg)
  | DatabaseBridge(subMsg) => updateDatabaseBridge(model, subMsg)
  | ProtocolBridge(subMsg) => updateProtocolBridge(model, subMsg)
  | ProofsBridge(subMsg) => updateProofsBridge(model, subMsg)
  | ScriptingBridge(subMsg) => updateScriptingBridge(model, subMsg)
  // Game Dev panels — game-specific
  | GeneratorMode(subMsg) => updateGeneratorMode(model, subMsg)
  | ArchitectMode(subMsg) => updateArchitectMode(model, subMsg)
  | GuardAiTuner(subMsg) => updateGuardAiTuner(model, subMsg)
  | DeviceNetworkDesigner(subMsg) => updateDeviceNetworkDesigner(model, subMsg)
  | AssetManager(subMsg) => updateAssetManager(model, subMsg)
  | PlaytestRecorder(subMsg) => updatePlaytestRecorder(model, subMsg)
  // Team / collaboration panels
  | CodeReview(subMsg) => updateCodeReview(model, subMsg)
  | MergeCoordinator(subMsg) => updateMergeCoordinator(model, subMsg)
  | TeamDashboard(subMsg) => updateTeamDashboard(model, subMsg)
  | DebuggingWorkbench(subMsg) => updateDebuggingWorkbench(model, subMsg)
  // Infrastructure panels
  | WiringInspector(subMsg) => updateWiringInspector(model, subMsg)
  // Floor Raise campaign panels
  | FloorRaise(subMsg) => updateFloorRaise(model, subMsg)
  | ProvenAdoption(subMsg) => updateProvenAdoption(model, subMsg)
  | ContractileCompleteness(subMsg) => updateContractileCompleteness(model, subMsg)
  | ManifestCoverage(subMsg) => updateManifestCoverage(model, subMsg)
  | VerisimdbFeeds(subMsg) => updateVerisimdbFeeds(model, subMsg)
  | FeedbackRouting(subMsg) => updateFeedbackRouting(model, subMsg)
  | VexometerFriction(subMsg) => updateVexometerFriction(model, subMsg)
  // SpecBrowser — language specification browsing
  | SpecBrowser(subMsg) =>
    switch subMsg {
    | SetSpecCategory(cat) => ({...model, specBrowser: {...model.specBrowser, activeCategory: cat}}, Tea_Cmd.none)
    | SelectSpecLanguage(name) => ({...model, specBrowser: {...model.specBrowser, selectedLanguage: name}}, Tea_Cmd.none)
    | SetComparisonSide(side, name) =>
      switch side {
      | LeftSide => ({...model, specBrowser: {...model.specBrowser, comparisonLeft: Some(name)}}, Tea_Cmd.none)
      | RightSide => ({...model, specBrowser: {...model.specBrowser, comparisonRight: Some(name)}}, Tea_Cmd.none)
      }
    | SetSpecFilter(txt) => ({...model, specBrowser: {...model.specBrowser, filterText: txt}}, Tea_Cmd.none)
    | ToggleIncompleteOnly => ({...model, specBrowser: {...model.specBrowser, showIncompleteOnly: !model.specBrowser.showIncompleteOnly}}, Tea_Cmd.none)
    | DismissSpecError => ({...model, specBrowser: {...model.specBrowser, error: None}}, Tea_Cmd.none)
    }
  // VerificationDashboard — proof/test/benchmark status
  | VerificationDashboard(subMsg) =>
    switch subMsg {
    | SetVdCategory(cat) => ({...model, verificationDashboard: {...model.verificationDashboard, activeCategory: cat}}, Tea_Cmd.none)
    | SelectVdLanguage(name) => ({...model, verificationDashboard: {...model.verificationDashboard, selectedLanguage: name}}, Tea_Cmd.none)
    | SetVdFilter(txt) => ({...model, verificationDashboard: {...model.verificationDashboard, filterText: txt}}, Tea_Cmd.none)
    | SetVdSort(sortBy) => ({...model, verificationDashboard: {...model.verificationDashboard, sortBy}}, Tea_Cmd.none)
    | ToggleDebtOnly => ({...model, verificationDashboard: {...model.verificationDashboard, showDebtOnly: !model.verificationDashboard.showDebtOnly}}, Tea_Cmd.none)
    | DismissVdError => ({...model, verificationDashboard: {...model.verificationDashboard, error: None}}, Tea_Cmd.none)
    }
  // Panel Bus — cross-panel messaging
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
  // Undo/Redo
  | Undo => {
      let len = Array.length(model.undoStack)
      if len === 0 {
        (model, Tea_Cmd.none)
      } else {
        let snapshot = model.undoStack[len - 1]
        let remainingUndo = Array.slice(model.undoStack, ~start=0, ~end=len - 1)
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
        let snapshot = model.redoStack[len - 1]
        let remainingRedo = Array.slice(model.redoStack, ~start=0, ~end=len - 1)
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
  // State persistence
  | SaveState => {
      Storage.save(model)
      (model, Tea_Cmd.none)
    }
  // BoJ latency recording
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
  // Governance NeSy results
  | GovernanceNesyResult(result) => {
      switch result {
      | Ok(jsonStr) => {
          let newModel = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
          | Some(json) =>

            let o = json->JSON.Decode.object->Option.getOr(Dict.make())
            let confidence =
              o->Dict.get("confidence")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.5)
            let approved =
              o->Dict.get("approved")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
            if !approved {
              {...model, antiCrash: {...model.antiCrash, strictMode: false}}
            } else if confidence > 0.8 {
              {...model, antiCrash: {...model.antiCrash, strictMode: true}}
            } else if confidence < 0.3 {
              {...model, antiCrash: {...model.antiCrash, strictMode: false}}
            } else {
              model
            }

          | None => model
          }
          (newModel, Tea_Cmd.none)
        }
      | Error(_) => (model, Tea_Cmd.none)
      }
    }
  | GovernanceNesyValidateResult(result) => {
      switch result {
      | Ok(jsonStr) => {
          let newModel = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
          | Some(json) =>

            let o = json->JSON.Decode.object->Option.getOr(Dict.make())
            let approved =
              o->Dict.get("approved")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
            let reasoning =
              o->Dict.get("reasoning")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            if !approved {
              ignore(reasoning)
              {...model, antiCrash: {...model.antiCrash, strictMode: false}}
            } else {
              model
            }

          | None => model
          }
          (newModel, Tea_Cmd.none)
        }
      | Error(_) => (model, Tea_Cmd.none)
      }
    }
  | GovernanceNesyProbeResult(result) => {
      switch result {
      | Ok(jsonStr) => {
          let newModel = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
          | Some(json) =>

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

          | None => model
          }
          (newModel, Tea_Cmd.none)
        }
      | Error(_) => (model, Tea_Cmd.none)
      }
    }
  // Observability
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
  // A2ML manifest management
  | A2ml(a2mlMsg) => {
      switch a2mlMsg {
      | LoadManifest(path) =>
        let cmd = A2mlCmd.loadManifest(path, r => A2ml(ManifestLoaded(r)))
        (model, cmd)
      | ManifestLoaded(result) =>
        switch result {
        | Ok(jsonStr) =>
          let manifest = A2mlEngine.parseA2mlContent(jsonStr)
          let validation = A2mlEngine.validateManifest(manifest)
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
          let paths = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
          | Some(parsed) =>

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

          | None => []
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
  // K9 contractile management
  | K9(k9Msg) => {
      switch k9Msg {
      | LoadContractile(path) =>
        let cmd = K9Cmd.loadContractile(path, r => K9(ContractileLoaded(r)))
        (model, cmd)
      | ContractileLoaded(result) =>
        switch result {
        | Ok(jsonStr) =>
          let contractile = K9Engine.validateContractile(jsonStr, ~path="loaded")
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
  // Seam auditing
  | AuditSeams => {
      let register = SeamEngine.buildRegister("2026-03-09")
      let audit = SeamEngine.auditRegister(register, "2026-03-09")
      ({...model, seamRegister: register, lastSeamAudit: Some(audit)}, Tea_Cmd.none)
    }
  | SeamAuditResult(audit) => ({...model, lastSeamAudit: Some(audit)}, Tea_Cmd.none)
  // Observatory — integrative dashboard
  | Observatory(subMsg) =>
    switch subMsg {
    | SetObsTab(tab) => ({...model, observatory: {...model.observatory, activeTab: tab}}, Tea_Cmd.none)
    | RunHealthCheck => ({...model, observatory: {...model.observatory, checking: true}}, Tea_Cmd.none)
    | HealthCheckComplete(result) =>
      switch result {
      | Ok(snapshots) => ({...model, observatory: {...model.observatory, snapshots, checking: false, error: None}}, Tea_Cmd.none)
      | Error(err) => ({...model, observatory: {...model.observatory, checking: false, error: Some(err)}}, Tea_Cmd.none)
      }
    | DismissObsError => ({...model, observatory: {...model.observatory, error: None}}, Tea_Cmd.none)
    }
  // AmbientOps — hospital-model sysadmin
  | AmbientOps(subMsg) =>
    switch subMsg {
    | SetOpsTab(tab) => ({...model, ambientOps: {...model.ambientOps, activeTab: tab}}, Tea_Cmd.none)
    | RunDiagnostics => ({...model, ambientOps: {...model.ambientOps, scanning: true}}, Tea_Cmd.none)
    | DiagnosticsComplete(result) =>
      switch result {
      | Ok(findings) => ({...model, ambientOps: {...model.ambientOps, findings, scanning: false, error: None}}, Tea_Cmd.none)
      | Error(err) => ({...model, ambientOps: {...model.ambientOps, scanning: false, error: Some(err)}}, Tea_Cmd.none)
      }
    | DismissOpsError => ({...model, ambientOps: {...model.ambientOps, error: None}}, Tea_Cmd.none)
    }
  // Burble — groove-aware voice huddle integration
  | Burble(subMsg) => ({...model, burble: BurbleEngine.update(model.burble, subMsg)}, Tea_Cmd.none)
  | NoOp => (model, Tea_Cmd.none)
  }

  // Post-processing: evaluate contractiles after every state-modifying update.
  // Skip for NoOp to avoid unnecessary computation.
  switch msg {
  | NoOp => (newModel, cmd)
  | _ => applyContractiles(newModel, cmd)
  }
}
