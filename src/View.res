// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL View - The render layer for the eNSAID environment.
///
/// This module implements the TEA view function, rendering the
/// three-pane parallel architecture with ambient substrate.

open Model
open Msg
open Tea.Html

/// Render the Orbital Drift Aura background
let renderDriftAura = (orbital: orbitalState, humidity: humidityLevel): Tea_Vdom.t<msg> => {
  let opacityClass = switch humidity {
  | High => "opacity-30"
  | Medium => "opacity-20"
  | Low => "opacity-10"
  }
  let colourClass = orbital.driftAuraColour === "indigo"
    ? "bg-indigo-900"
    : "bg-amber-900"

  div(
    list{
      Attrs.class_(`fixed inset-0 ${colourClass} ${opacityClass} transition-all duration-1000 pointer-events-none`),
    },
    list{},
  )
}

/// Render Pane-L (Symbolic Mass) - using full component.
/// Receives proof obligations from VeriSimDB VQL-DT queries to display
/// as symbolic constraints alongside the constraint editor.
let renderPaneL = (paneL: paneLState, proofs: array<proofObligation>, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneL.view(paneL, proofs)},
    )
  }
}

/// Render Pane-N (Neural Stream) with ECHIDNA theorem prover panel - using full component
let renderPaneN = (paneN: paneNState, echidna: echidnaState, ~inferenceStream: array<string>=[], visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneN.view(paneN, echidna, ~inferenceStream)},
    )
  }
}

/// Render Pane-W (World/Barycentre) - using full component
/// This pane draws the central security panel, event chain importer, and
/// panic-attacker toolset, ensuring the time/space study is visible when dialogs open.
/// Render Pane-W (World/Barycentre) with VeriSimDB database tools.
let renderPaneW = (paneW: paneWState, orbital: orbitalState, db: verisimdbState, contractiles: array<contractile>, tour: tourState, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneW.view(paneW, orbital, db, ~contractiles, ~tour)},
    )
  }
}

/// Render the Dark Start architecture manifold
/// Render a quick-access panel card for the DarkStart grid.
let renderQuickPanel = (panel: panelMeta): Tea_Vdom.t<msg> => {
  let statusDot = switch panel.connectionStatus {
  | ServiceConnected => "bg-green-400"
  | ServiceDisconnected => "bg-gray-600"
  | ServiceChecking => "bg-amber-400 animate-pulse"
  | ServiceError(_) => "bg-red-400"
  }
  button(
    list{
      Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-3 hover:bg-gray-800/80 hover:border-gray-700 transition-all text-left group"),
      Events.onClick(PanelSwitcher(TogglePanel(panel.id))),
      Attrs.title(panel.description),
    },
    list{
      div(list{Attrs.class_("flex items-center gap-2 mb-1")}, list{
        div(list{Attrs.class_(`w-1.5 h-1.5 rounded-full ${statusDot}`)}, list{}),
        span(list{Attrs.class_("text-sm text-gray-300 group-hover:text-white transition-colors")}, list{text(panel.name)}),
      }),
      div(list{Attrs.class_("text-[10px] text-gray-600 truncate")}, list{text(panel.description)}),
    },
  )
}

/// Render the DarkStart front page — system overview, quick access, health.
let renderDarkStart = (model: model): Tea_Vdom.t<msg> => {
  // Gather health metrics
  let totalPanels = Array.length(model.panelSwitcher.panels)
  let connectedPanels = model.panelSwitcher.panels->Array.filter(p =>
    p.connectionStatus === ServiceConnected
  )->Array.length
  let hypatiaConfidence = HypatiaEngine.avgConfidence(model.hypatia.networks)
  let sessionCount = Array.length(model.workspace.sessions)
  let bojCartridges = Array.length(model.boj.cartridges)
  let bojLoaded = model.boj.cartridges->Array.filter(c => c.loaded)->Array.length

  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950 overflow-auto"),
      Attrs.role("main"),
      Attrs.ariaLabel("PanLL DarkStart — system overview"),
    },
    list{
      // Top section: branding + enter button
      div(
        list{Attrs.class_("max-w-5xl mx-auto px-8 pt-12 pb-6")},
        list{
          div(list{Attrs.class_("flex items-end justify-between mb-8")}, list{
            div(list{}, list{
              div(list{Attrs.class_("text-3xl font-light text-gray-400")}, list{text("PanLL")}),
              div(list{Attrs.class_("text-xs text-gray-600 mt-1")}, list{text("eNSAID Neurosymbolic Development Environment")}),
            }),
            button(
              list{
                Attrs.class_("px-6 py-2.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-500 transition-colors text-sm font-medium"),
                Events.onClick(View(SetViewMode(Standard))),
                KeyboardUtil.onEnterOrSpace(View(SetViewMode(Standard))),
              },
              list{text("Enter Environment")},
            ),
          }),

          // Binary Star diagram (compact)
          div(list{Attrs.class_("flex items-center justify-center gap-8 mb-10")}, list{
            div(
              list{Attrs.class_("w-16 h-16 rounded-full bg-indigo-600/30 border border-indigo-500/50 flex items-center justify-center")},
              list{div(list{Attrs.class_("text-indigo-400 text-[10px] font-medium")}, list{text("L")})},
            ),
            div(list{Attrs.class_("w-8 border-t border-dashed border-gray-700")}, list{}),
            div(
              list{Attrs.class_("w-16 h-16 rounded-full bg-emerald-600/30 border border-emerald-500/50 flex items-center justify-center")},
              list{div(list{Attrs.class_("text-emerald-400 text-[10px] font-medium")}, list{text("N")})},
            ),
            div(list{Attrs.class_("w-8 border-t border-dashed border-gray-700")}, list{}),
            div(
              list{Attrs.class_("w-16 h-16 rounded-full bg-amber-600/30 border border-amber-500/50 flex items-center justify-center")},
              list{div(list{Attrs.class_("text-amber-400 text-[10px] font-medium")}, list{text("W")})},
            ),
          }),

          // System health cards
          div(list{Attrs.class_("grid grid-cols-4 gap-3 mb-8")}, list{
            // Panels
            div(list{Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-4")}, list{
              div(list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")}, list{text("Panels")}),
              div(list{Attrs.class_("text-2xl font-light text-gray-200")}, list{text(Int.toString(totalPanels))}),
              div(list{Attrs.class_("text-xs text-green-500 mt-1")}, list{text(`${Int.toString(connectedPanels)} connected`)}),
            }),
            // Hypatia
            div(list{Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-4")}, list{
              div(list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")}, list{text("Hypatia")}),
              div(
                list{Attrs.class_(`text-2xl font-light ${if hypatiaConfidence > 0.8 { "text-green-400" } else if hypatiaConfidence > 0.5 { "text-amber-400" } else { "text-gray-500" }}`)},
                list{text(if hypatiaConfidence > 0.0 { `${Float.toFixed(hypatiaConfidence *. 100.0, ~digits=0)}%` } else { "---" })},
              ),
              div(list{Attrs.class_("text-xs text-gray-600 mt-1")}, list{text("ensemble confidence")}),
            }),
            // BoJ
            div(list{Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-4")}, list{
              div(list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")}, list{text("BoJ Server")}),
              div(list{Attrs.class_("text-2xl font-light text-gray-200")}, list{text(Int.toString(bojCartridges))}),
              div(list{Attrs.class_("text-xs text-green-500 mt-1")}, list{text(`${Int.toString(bojLoaded)} loaded`)}),
            }),
            // Sessions
            div(list{Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-4")}, list{
              div(list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")}, list{text("Sessions")}),
              div(list{Attrs.class_("text-2xl font-light text-gray-200")}, list{text(Int.toString(sessionCount))}),
              div(list{Attrs.class_("text-xs text-gray-600 mt-1")}, list{text("workspace sessions")}),
            }),
          }),

          // Quick-access panel grid (top 12 panels)
          div(list{Attrs.class_("mb-8")}, list{
            div(list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-3")}, list{text("Quick Access")}),
            div(list{Attrs.class_("grid grid-cols-4 gap-2")},
              model.panelSwitcher.panels
              ->Array.slice(~start=0, ~end=12)
              ->Array.map(p => renderQuickPanel(p))
              ->List.fromArray,
            ),
          }),

          // Recent sessions
          if Array.length(model.workspace.sessions) > 0 {
            div(list{Attrs.class_("mb-8")}, list{
              div(list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-3")}, list{text("Recent Sessions")}),
              div(list{Attrs.class_("space-y-1")},
                model.workspace.sessions
                ->Array.slice(~start=0, ~end=5)
                ->Array.map(session =>
                  div(list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-900/40 rounded hover:bg-gray-800/60 transition-colors")}, list{
                    div(list{Attrs.class_("w-1.5 h-1.5 rounded-full bg-gray-600")}, list{}),
                    span(list{Attrs.class_("text-sm text-gray-400 flex-1")}, list{text(session.name)}),
                    span(list{Attrs.class_("text-xs text-gray-600")}, list{
                      text(Date.make()->Date.toLocaleDateString),
                    }),
                  })
                )->List.fromArray,
              ),
            })
          } else {
            noNode
          },

          // Footer
          div(list{Attrs.class_("text-center py-6 border-t border-gray-900")}, list{
            div(list{Attrs.class_("text-xs text-gray-700")}, list{
              text("Press Enter or click \"Enter Environment\" to begin"),
            }),
          }),
        },
      ),
    },
  )
}

/// Render cross-panel circuit lines — SVG overlay showing data flow connections
/// between Panel-L (Symbolic), Panel-N (Neural), and Panel-W (World).
/// Lines animate based on orbital sync health: green = healthy, amber = drifting,
/// red = diverged. The circuit only renders when all three panels are visible.
let renderCircuitLines = (orbital: orbitalState, paneLVisible: bool, paneNVisible: bool, paneWVisible: bool): Tea_Vdom.t<msg> => {
  if !(paneLVisible && paneNVisible && paneWVisible) {
    noNode
  } else {
    let healthClass = if orbital.syncHealth > 0.7 {
      "stroke-emerald-500/40"
    } else if orbital.syncHealth > 0.4 {
      "stroke-amber-500/40"
    } else {
      "stroke-red-500/40"
    }
    let pulseClass = if orbital.syncHealth > 0.7 { "" } else { "animate-pulse" }

    // SVG overlay positioned absolutely over the three-panel layout
    Tea_Svg.svg(
      list{
        Tea_Svg.Attrs.class_(`absolute inset-0 w-full h-full pointer-events-none z-20 ${pulseClass}`),
        Tea_Svg.Attrs.viewBox("0 0 1200 800"),
        Attrs.prop("preserveAspectRatio", "none"),
      },
      list{
        // L→N connection (symbolic feeds neural)
        Tea_Svg.line(
          list{
            Tea_Svg.Attrs.class_(healthClass),
            Tea_Svg.Attrs.x1("400"),
            Tea_Svg.Attrs.y1("400"),
            Tea_Svg.Attrs.x2("800"),
            Tea_Svg.Attrs.y2("400"),
            Tea_Svg.Attrs.strokeWidth("2"),
            Tea_Svg.Attrs.strokeDasharray("8 4"),
          },
          list{},
        ),
        // N→W connection (neural feeds world)
        Tea_Svg.line(
          list{
            Tea_Svg.Attrs.class_(healthClass),
            Tea_Svg.Attrs.x1("800"),
            Tea_Svg.Attrs.y1("400"),
            Tea_Svg.Attrs.x2("1100"),
            Tea_Svg.Attrs.y2("200"),
            Tea_Svg.Attrs.strokeWidth("2"),
            Tea_Svg.Attrs.strokeDasharray("8 4"),
          },
          list{},
        ),
        // W→L feedback loop (world constrains symbolic)
        Tea_Svg.line(
          list{
            Tea_Svg.Attrs.class_(healthClass),
            Tea_Svg.Attrs.x1("1100"),
            Tea_Svg.Attrs.y1("600"),
            Tea_Svg.Attrs.x2("100"),
            Tea_Svg.Attrs.y2("600"),
            Tea_Svg.Attrs.strokeWidth("1"),
            Tea_Svg.Attrs.strokeDasharray("4 8"),
          },
          list{},
        ),
        // Barycentre indicator dot
        Tea_Svg.circle(
          list{
            Tea_Svg.Attrs.class_("fill-indigo-500/60"),
            Tea_Svg.Attrs.cx(Float.toString(400.0 +. orbital.barycentrePosition *. 400.0)),
            Tea_Svg.Attrs.cy("400"),
            Tea_Svg.Attrs.r("6"),
          },
          list{},
        ),
      },
    )
  }
}

/// Render the active panel overlay based on the panel switcher state.
/// Each panel module renders as a full-screen overlay on top of the core
/// three-panel layout. Panels not yet implemented show a placeholder.
let renderActivePanel = (model: model): Tea_Vdom.t<msg> => {
  switch model.panelSwitcher.activePanel {
  | None => noNode
  | Some(PanelVab) => Vab.view(model.vab)
  | Some(PanelCloudGuard) => CloudGuard.view(model.cloudguard)
  | Some(PanelFarm) => Farm.view(model.farm)
  | Some(PanelPlaza) => Plaza.view(model.plaza)
  | Some(PanelHypatia) => Hypatia.view(model.hypatia)
  | Some(PanelFleet) => Fleet.view(model.fleet)
  | Some(PanelReposystem) => Reposystem.view(model.reposystem)
  | Some(PanelDatabases) => Databases.view(model.databases)
  | Some(PanelAerie) => Aerie.view(model.aerie)
  | Some(PanelInterfaces) => Interfaces.view(model.interfaces)
  | Some(PanelPlaygrounds) => Playgrounds.view(model.playgrounds)
  | Some(PanelMinter) => Minter.view(model.minter)
  | Some(PanelProvisioner) => Provisioner.view(model.provisioner)
  | Some(PanelVoiceTag) => VoiceTag.view(model.voiceTag)
  | Some(PanelAi) => Ai.view(model.ai)
  | Some(PanelRepoLoader) => RepoLoader.view(model.repoLoader)
  | Some(PanelWorkspace) => Workspace.view(model.workspace, model.keybindings)
  | Some(PanelCapture) => Capture.view(model.capture)
  | Some(PanelSecurity) => Security.view(model.security)
  | Some(PanelMigration) => Migration.view(model.migration)
  | Some(PanelPanicAttack) => PanicAttack.view(model.panicAttack)
  | Some(PanelMassPanic) => MassPanic.view(model.massPanic)
  | Some(PanelTsdm) => Tsdm.view(model.tsdm)
  | Some(PanelValenceShell) => ValenceShell.view(model.valenceShell)
  | Some(PanelGamePreview) => GamePreview.view(model.gamePreview)
  | Some(PanelVmInspector) => VmInspector.view(model.vmInspector)
  | Some(PanelNetworkTopology) => NetworkTopology.view(model.networkTopology)
  | Some(PanelLevelArchitect) => LevelArchitect.view(model.levelArchitect)
  | Some(PanelCoprocessors) => Coprocessors.view(model.coprocessors)
  | Some(PanelMultiplayerMonitor) => MultiplayerMonitor.view(model.multiplayerMonitor)
  | Some(PanelDlcWorkshop) => DlcWorkshop.view(model.dlcWorkshop)
  | Some(PanelUms) => Ums.view(model.ums, ~levelArchitect=model.levelArchitect)
  | Some(PanelEditorBridge) => EditorBridge.view(model.editorBridge)
  | Some(PanelBuildDashboard) => BuildDashboard.view(model.buildDashboard)
  | Some(PanelReleaseManager) => ReleaseManager.view(model.releaseManager)
  | Some(PanelAutomationRouter) => AutomationRouter.view(model.automationRouter)
  | Some(PanelScriptGist) => ScriptGist.view(model.scriptGist)
  | Some(PanelBoj) => Boj.view(model.boj)
  | Some(PanelCladeBrowser) => CladeBrowser.view(model.cladeBrowser)
  | Some(PanelTentacles) => Tentacles.view(model.tentacles)
  | Some(PanelProtocolSquisher) => ProtocolSquisher.view(model.protocolSquisher)
  | Some(PanelMyLang) => MyLang.view(model.myLang)
  | Some(PanelTypeLL) => TypeLL.view(model.typell)
  | Some(PanelEvangeliser) => Evangeliser.view(model.evangeliser)
  | Some(PanelHelp) => Help.view(model.help)
  | Some(PanelLanguageForge) => LanguageForge.view(model.languageForge)
  | Some(PanelTangleViz) => TangleViz.view(model.tangleViz)
  | Some(PanelSpecBrowser) => SpecBrowser.view(model.specBrowser)
  | Some(PanelVerificationDashboard) => VerificationDashboard.view(model.verificationDashboard)
  | Some(PanelEchidna) => Echidna.view(model.echidna)
  | Some(PanelObservatory) => Observatory.view(model.observatory)
  | Some(PanelAmbientOps) => AmbientOps.view(model.ambientOps)
  // Game Dev panels — testing
  | Some(PanelUnitTestRunner) => UnitTestRunner.view(model.unitTestRunner)
  | Some(PanelFunctionalTester) => FunctionalTester.view(model.functionalTester)
  | Some(PanelRegressionGuard) => RegressionGuard.view(model.regressionGuard)
  | Some(PanelPerformanceProfiler) => PerformanceProfiler.view(model.performanceProfiler)
  | Some(PanelLoadTester) => LoadTester.view(model.loadTester)
  | Some(PanelSoakMonitor) => SoakMonitor.view(model.soakMonitor)
  | Some(PanelCompatibilityMatrix) => CompatibilityMatrix.view(model.compatibilityMatrix)
  | Some(PanelExploratoryWorkbench) => ExploratoryWorkbench.view(model.exploratoryWorkbench)
  | Some(PanelBetaFeedbackHub) => BetaFeedbackHub.view(model.betaFeedbackHub)
  | Some(PanelBalanceAnalyser) => BalanceAnalyser.view(model.balanceAnalyser)
  // Game Dev panels — bridges
  | Some(PanelTypingBridge) => TypingBridge.view(model.typingBridge)
  | Some(PanelNeurosymBridge) => NeurosymBridge.view(model.neurosymBridge)
  | Some(PanelAgenticBridge) => AgenticBridge.view(model.agenticBridge)
  | Some(PanelAutomationBridge) => AutomationBridge.view(model.automationBridge)
  | Some(PanelDatabaseBridge) => DatabaseBridge.view(model.databaseBridge)
  | Some(PanelProtocolBridge) => ProtocolBridge.view(model.protocolBridge)
  | Some(PanelProofsBridge) => ProofsBridge.view(model.proofsBridge)
  | Some(PanelScriptingBridge) => ScriptingBridge.view(model.scriptingBridge)
  // Game Dev panels — game-specific
  | Some(PanelGeneratorMode) => GeneratorMode.view(model.generatorMode)
  | Some(PanelArchitectMode) => ArchitectMode.view(model.architectMode)
  | Some(PanelGuardAiTuner) => GuardAiTuner.view(model.guardAiTuner)
  | Some(PanelDeviceNetworkDesigner) => DeviceNetworkDesigner.view(model.deviceNetworkDesigner)
  | Some(PanelAssetManager) => AssetManager.view(model.assetManager)
  | Some(PanelPlaytestRecorder) => PlaytestRecorder.view(model.playtestRecorder)
  // Team / collaboration panels
  | Some(PanelCodeReview) => CodeReview.view(model.codeReview)
  | Some(PanelMergeCoordinator) => MergeCoordinator.view(model.mergeCoordinator)
  | Some(PanelTeamDashboard) => TeamDashboard.view(model.teamDashboard)
  | Some(PanelDebuggingWorkbench) => DebuggingWorkbench.view(model.debuggingWorkbench)
  // Infrastructure panels
  | Some(PanelWiringInspector) => WiringInspector.view(model.wiringInspector)
  }
}

/// Get the root colour classes based on view mode. Light mode uses lighter backgrounds
/// with dark text for better contrast in high-ambient-light environments.
let rootColourClasses = (viewMode: viewMode): string => {
  switch viewMode {
  | DarkStart | Standard => "bg-gray-950 text-gray-100"
  | LightMode => "bg-gray-50 text-gray-900"
  | Ambient | Zen => "bg-gray-950 text-gray-100"
  }
}

/// Main view function
let view = (model: model): Tea_Vdom.t<msg> => {
  // Dark Start mode - show architecture manifold
  if model.viewMode === DarkStart {
    renderDarkStart(model)
  } else {
    div(
      list{Attrs.class_(`h-screen ${rootColourClasses(model.viewMode)} flex flex-col ${AccessibilityEngine.rootClasses(model.accessibility)}`)},
      list{
        // Ambient substrate - Orbital Drift Aura
        renderDriftAura(model.orbital, model.humidity),

        // Code Provenance Map — Qubes-style trust surface (hidden in fullscreen)
        if !model.fullscreenActive { Provenance.view(model.provenance) } else { noNode },

        // Application menu bar — File / Edit / View / Panel / Tools / Help
        if !model.fullscreenActive { MenuBar.view(model.menuBar) } else { noNode },

        // Main three-pane layout (padded right for the panel bar when visible)
        div(
          list{Attrs.class_(`flex-1 flex overflow-hidden relative z-10 ${if model.panelBarVisible { "pr-12" } else { "" }}`)},
          list{
            // Cross-panel circuit lines showing data flow
            renderCircuitLines(model.orbital, model.paneLVisible, model.paneNVisible, model.paneWVisible),
            // Pane-L with capture bar and focus dimming
            div(
              list{
                Attrs.class_(`flex-1 overflow-auto relative transition-opacity duration-500 ${FocusDimmingEngine.panelOpacityClass(model.focusDimming, "paneL")}`),
                Events.onClick(FocusDimming(RecordInteraction("paneL"))),
              },
              list{
                renderPaneL(model.paneL, if model.verisimdb.proofDisplayActive { model.verisimdb.proofObligations } else { [] }, model.paneLVisible),
                CaptureBar.view("paneL", false, model.capture.captureBarVisible && model.paneLVisible),
              },
            ),
            // Pane-N with capture bar and focus dimming
            div(
              list{
                Attrs.class_(`flex-1 overflow-auto relative transition-opacity duration-500 ${FocusDimmingEngine.panelOpacityClass(model.focusDimming, "paneN")}`),
                Events.onClick(FocusDimming(RecordInteraction("paneN"))),
              },
              list{
                renderPaneN(model.paneN, model.echidna, ~inferenceStream=model.verisimdb.inferenceStream, model.paneNVisible),
                CaptureBar.view("paneN", false, model.capture.captureBarVisible && model.paneNVisible),
              },
            ),
            // Pane-W with capture bar and focus dimming
            div(
              list{
                Attrs.class_(`flex-1 overflow-auto relative transition-opacity duration-500 ${FocusDimmingEngine.panelOpacityClass(model.focusDimming, "paneW")}`),
                Events.onClick(FocusDimming(RecordInteraction("paneW"))),
              },
              list{
                renderPaneW(model.paneW, model.orbital, model.verisimdb, model.contractiles, model.barycentreTour, model.paneWVisible),
                CaptureBar.view("paneW", false, model.capture.captureBarVisible && model.paneWVisible),
              },
            ),
          },
        ),

        // Vexometer - hidden in fullscreen
        if !model.fullscreenActive { Vexometer.view(model.vexometer, false) } else { noNode },

        // Feedback-O-Tron - hidden in fullscreen
        if !model.fullscreenActive {
          FeedbackOTron.view(
            model.feedbackPending,
            model.feedbackError,
            model.feedbackReportType,
            model.boj,
          )
        } else { noNode },

        // Active panel overlay — replaces ad-hoc visible checks on VAB/CloudGuard.
        // The panel switcher routes to the correct module's view or a placeholder.
        renderActivePanel(model),

        // Panel switcher bar — controlled by panelBarVisible toggle
        if model.panelBarVisible { PanelSwitcher.view(model.panelSwitcher) } else { noNode },

        // Status bar — hidden in fullscreen
        if !model.fullscreenActive { StatusBar.view(model) } else { noNode },

        // Home button — fixed top-left, visible when any panel overlay is open.
        // Provides a constant escape hatch back to the main three-panel view.
        if model.panelSwitcher.activePanel !== None {
          button(
            list{
              Attrs.class_(
                "fixed top-3 left-3 z-[9998] w-10 h-10 rounded-full bg-gray-800 hover:bg-gray-700 text-gray-300 hover:text-white shadow-lg flex items-center justify-center transition-all hover:scale-110 focus:outline-none focus:ring-2 focus:ring-indigo-400 border border-gray-700",
              ),
              Attrs.title("Return to main view"),
              Attrs.ariaLabel("Return to main view"),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{
              span(
                list{Attrs.class_("text-sm font-bold")},
                list{text("\xe2\x86\x90")},
              ),
            },
          )
        } else {
          noNode
        },

        // Floating accessibility widget (FAB + panel) — always rendered last
        // so it overlays all content via fixed positioning.
        AccessibilityToolbar.view(model.accessibility),
      },
    )
  }
}
