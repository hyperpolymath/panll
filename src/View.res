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
let renderPaneN = (paneN: paneNState, echidna: echidnaState, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneN.view(paneN, echidna)},
    )
  }
}

/// Render Pane-W (World/Barycentre) - using full component
/// This pane draws the central security panel, event chain importer, and
/// panic-attacker toolset, ensuring the time/space study is visible when dialogs open.
/// Render Pane-W (World/Barycentre) with VeriSimDB database tools.
let renderPaneW = (paneW: paneWState, orbital: orbitalState, db: verisimdbState, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneW.view(paneW, orbital, db)},
    )
  }
}

/// Render the Dark Start architecture manifold
let renderDarkStart = (): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950 flex items-center justify-center cursor-pointer"),
      Attrs.role("button"),
      Attrs.ariaLabel("Enter eNSAID environment"),
      Events.onClick(View(SetViewMode(Standard))),
      KeyboardUtil.onEnterOrSpace(View(SetViewMode(Standard))),
    },
    list{
      div(
        list{Attrs.class_("text-center")},
        list{
          div(
            list{Attrs.class_("text-4xl font-light text-gray-600 mb-8")},
            list{text("PanLL")},
          ),
          div(
            list{Attrs.class_("flex items-center justify-center gap-16")},
            list{
              // Symbolic star
              div(
                list{Attrs.class_("w-24 h-24 rounded-full bg-indigo-600/50 border-2 border-indigo-400 flex items-center justify-center")},
                list{
                  div(
                    list{Attrs.class_("text-indigo-300 text-xs")},
                    list{text("SYMBOLIC")},
                  ),
                },
              ),
              // Orbital path indicator
              div(
                list{Attrs.class_("w-16 border-t-2 border-dashed border-gray-600")},
                list{},
              ),
              // Neural star
              div(
                list{Attrs.class_("w-24 h-24 rounded-full bg-emerald-600/50 border-2 border-emerald-400 flex items-center justify-center")},
                list{
                  div(
                    list{Attrs.class_("text-emerald-300 text-xs")},
                    list{text("NEURAL")},
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("mt-12 text-gray-600 text-sm")},
            list{text("eNSAID Environment")},
          ),
          div(
            list{Attrs.class_("mt-6 text-gray-700 text-xs animate-pulse")},
            list{text("Click anywhere to enter")},
          ),
        },
      ),
    },
  )
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
  | Some(PanelDatabases) => Vab.view(model.vab) // Databases extends VeriSimDB — full panel coming
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
  | Some(PanelEditorBridge) => EditorBridge.view(model.editorBridge)
  | Some(PanelBuildDashboard) => BuildDashboard.view(model.buildDashboard)
  | Some(PanelReleaseManager) => ReleaseManager.view(model.releaseManager)
  | Some(PanelAutomationRouter) => AutomationRouter.view(model.automationRouter)
  | Some(PanelBoj) => Boj.view(model.boj)
  | Some(PanelCladeBrowser) => CladeBrowser.view(model.cladeBrowser)
  | Some(PanelTentacles) => Tentacles.view(model.tentacles)
  | Some(PanelProtocolSquisher) => ProtocolSquisher.view(model.protocolSquisher)
  | Some(PanelMyLang) => MyLang.view(model.myLang)
  | Some(PanelTypeLL) => TypeLL.view(model.typell)
  }
}

/// Main view function
let view = (model: model): Tea_Vdom.t<msg> => {
  // Dark Start mode - show architecture manifold
  if model.viewMode === DarkStart {
    renderDarkStart()
  } else {
    div(
      list{Attrs.class_("h-screen bg-gray-950 text-gray-100 flex flex-col")},
      list{
        // Ambient substrate - Orbital Drift Aura
        renderDriftAura(model.orbital, model.humidity),

        // Code Provenance Map — Qubes-style trust surface (always visible)
        Provenance.view(model.provenance),

        // Main three-pane layout (padded right for the panel bar)
        div(
          list{Attrs.class_("flex-1 flex overflow-hidden relative z-10 pr-12")},
          list{
            // Pane-L with capture bar
            div(
              list{Attrs.class_("flex-1 overflow-auto relative")},
              list{
                renderPaneL(model.paneL, model.verisimdb.proofObligations, model.paneLVisible),
                CaptureBar.view("paneL", false, model.capture.captureBarVisible && model.paneLVisible),
              },
            ),
            // Pane-N with capture bar
            div(
              list{Attrs.class_("flex-1 overflow-auto relative")},
              list{
                renderPaneN(model.paneN, model.echidna, model.paneNVisible),
                CaptureBar.view("paneN", false, model.capture.captureBarVisible && model.paneNVisible),
              },
            ),
            // Pane-W with capture bar
            div(
              list{Attrs.class_("flex-1 overflow-auto relative")},
              list{
                renderPaneW(model.paneW, model.orbital, model.verisimdb, model.paneWVisible),
                CaptureBar.view("paneW", false, model.capture.captureBarVisible && model.paneWVisible),
              },
            ),
          },
        ),

        // Vexometer - using full component with compact view by default
        Vexometer.view(model.vexometer, false),

        // Feedback-O-Tron - using full component
        FeedbackOTron.view(
          model.feedbackPending,
          model.feedbackError,
          model.feedbackReportType,
        ),

        // Active panel overlay — replaces ad-hoc visible checks on VAB/CloudGuard.
        // The panel switcher routes to the correct module's view or a placeholder.
        renderActivePanel(model),

        // Panel switcher bar — vertical icon strip on right edge (z-50 over overlays)
        PanelSwitcher.view(model.panelSwitcher),

        // Status bar — configurable bottom bar with system info widgets (DD-025)
        StatusBar.view(model),
      },
    )
  }
}
