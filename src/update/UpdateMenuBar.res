// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

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
    | "file:export-ensaid" => // No backend export yet — route to Help panel with status message.
      (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}},
        Tea_Cmd.none,
      )
    | "file:export-chain" => // No backend export yet — route to Help panel with status message.
      (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}},
        Tea_Cmd.none,
      )
    | "file:import-chain" => (
        // Open file dialog to import an event chain JSON file (same as PaneW import button).
        model,
        GossamerCmd.openEventChainFile(result => PaneW(EventChainFileLoaded(result))),
      )
    | "file:import-panic" => (
        // Open file dialog to import a panic-attacker report file (same as PaneW import button).
        model,
        GossamerCmd.openPanicAttackerReportFile(result => PaneW(
          PanicAttackerReportPathLoaded(result),
        )),
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
    | "edit:clear-chain" => (
        {
          ...model,
          paneW: {
            ...model.paneW,
            eventChain: [],
            eventChainSummary: None,
            eventChainTimeline: None,
            eventChainInput: "",
            eventChainError: None,
          },
        },
        Tea_Cmd.none,
      )
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
    | "view:toggle-topology" => (
        {...model, paneW: {...model.paneW, topologyView: !model.paneW.topologyView}},
        Tea_Cmd.none,
      )
    | "view:fullscreen" => ({...model, fullscreenActive: !model.fullscreenActive}, Tea_Cmd.none)
    | "view:light-mode" => (
        {...model, viewMode: model.viewMode === LightMode ? Standard : LightMode},
        Tea_Cmd.none,
      )
    | "view:zen" => ({...model, viewMode: Zen}, Tea_Cmd.none)
    | "view:dark-start" => ({...model, viewMode: DarkStart}, Tea_Cmd.none)
    | "view:accessibility" => (
        {...model, accessibility: {...model.accessibility, toolbarExpanded: true}},
        Tea_Cmd.none,
      )
    // Panel actions — open panels via panel switcher
    | "panel:ai" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelAi)}},
        Tea_Cmd.none,
      )
    | "panel:vab" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelVab)}},
        Tea_Cmd.none,
      )
    | "panel:cloudguard" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCloudGuard)}},
        Tea_Cmd.none,
      )
    | "panel:hypatia" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHypatia)}},
        Tea_Cmd.none,
      )
    | "panel:reposystem" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelReposystem)}},
        Tea_Cmd.none,
      )
    | "panel:build-dashboard" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelBuildDashboard)}},
        Tea_Cmd.none,
      )
    | "panel:editor-bridge" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelEditorBridge)}},
        Tea_Cmd.none,
      )
    | "panel:release-manager" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelReleaseManager)}},
        Tea_Cmd.none,
      )
    | "panel:workspace" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelWorkspace)}},
        Tea_Cmd.none,
      )
    | "panel:capture" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCapture)}},
        Tea_Cmd.none,
      )
    | "panel:security" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelSecurity)}},
        Tea_Cmd.none,
      )
    | "panel:boj" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelBoj)}},
        Tea_Cmd.none,
      )
    | "panel:typell" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelTypeLL)}},
        Tea_Cmd.none,
      )
    | "panel:provenance" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}},
        Tea_Cmd.none,
      ) // Provenance panel slot needed — routes to Help for now
    // Tools actions — open tool panels
    | "tools:panic-attack" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelPanicAttack)}},
        Tea_Cmd.none,
      )
    | "tools:mass-panic" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelMassPanic)}},
        Tea_Cmd.none,
      )
    | "tools:tsdm" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelTsdm)}},
        Tea_Cmd.none,
      )
    | "tools:clade-browser" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCladeBrowser)}},
        Tea_Cmd.none,
      )
    | "tools:network-topology" => (
        {
          ...model,
          panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelNetworkTopology)},
        },
        Tea_Cmd.none,
      )
    | "tools:vm-inspector" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelVmInspector)}},
        Tea_Cmd.none,
      )
    | "tools:coprocessors" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelCoprocessors)}},
        Tea_Cmd.none,
      )
    | "tools:automation" => (
        {
          ...model,
          panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelAutomationRouter)},
        },
        Tea_Cmd.none,
      )
    | "tools:tentacles" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelTentacles)}},
        Tea_Cmd.none,
      )
    | "tools:protocol-squisher" => (
        {
          ...model,
          panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelProtocolSquisher)},
        },
        Tea_Cmd.none,
      )
    | "tools:mof-ocl" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelEchidna)}},
        Tea_Cmd.none,
      )
    | "tools:echidna" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelEchidna)}},
        Tea_Cmd.none,
      )
    | "tools:keybindings" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelWorkspace)}},
        Tea_Cmd.none,
      )
    | "panel:echidna" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelEchidna)}},
        Tea_Cmd.none,
      )
    | "panel:observatory" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelObservatory)}},
        Tea_Cmd.none,
      )
    | "panel:ambientops" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelAmbientOps)}},
        Tea_Cmd.none,
      )
    | "panel:interfaces" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelInterfaces)}},
        Tea_Cmd.none,
      )
    | "panel:protocol-squisher" => (
        {
          ...model,
          panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelProtocolSquisher)},
        },
        Tea_Cmd.none,
      )
    // Help actions
    | "help:tour" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}},
        Tea_Cmd.none,
      )
    | "help:glossary" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}},
        Tea_Cmd.none,
      )
    | "help:barycentre-tour" => (
        {
          ...model,
          barycentreTour: {
            active: true,
            currentStep: TourIntro,
            completed: model.barycentreTour.completed,
          },
          paneW: {...model.paneW, topologyView: true},
        },
        Tea_Cmd.none,
      )
    | "help:about" => (
        {...model, panelSwitcher: {...model.panelSwitcher, activePanel: Some(PanelHelp)}},
        Tea_Cmd.none,
      )
    | _ => (model, Tea_Cmd.none)
    }
  }
}
