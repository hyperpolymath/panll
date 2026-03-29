// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Workspace Panel — the configurator for panel arrangements, groups,
/// sessions, modes, keybindings, and protection levels (DD-024, DD-025).
///
/// This is the "ribbon designer" for PanLL — like Directory Opus's toolbar
/// editor or Word's ribbon customiser, but for the entire workspace layout.

open Model
open Msg
open Tea.Html

/// Render a mode badge showing the current workspace mode.
let renderModeBadge = (mode: workspaceMode): Tea_Vdom.t<msg> => {
  let (label, colour) = switch mode {
  | RhodiumMode => ("Rhodium", "bg-yellow-700")
  | EverythingMode => ("Everything", "bg-purple-700")
  | CodeMode => ("Code", "bg-blue-700")
  | BespokeMode => ("Bespoke", "bg-teal-700")
  }
  button(
    list{
      Attrs.class_(
        `px-3 py-1 rounded text-xs font-medium ${colour} text-white hover:opacity-80 transition-opacity`,
      ),
      Attrs.title("Click to cycle workspace mode: Rhodium > Everything > Code > Bespoke"),
      Events.onClick(Workspace(CycleWorkspaceMode)),
      KeyboardNav.onActivate(Workspace(CycleWorkspaceMode)),
    },
    list{text(label)},
  )
}

/// Render the protection level indicator.
let renderProtectionBadge = (protection: sessionProtection): Tea_Vdom.t<msg> => {
  let (label, colour) = switch protection {
  | Open => ("Open", "bg-green-700")
  | ReadOnly => ("Read-Only", "bg-red-700")
  | Sandboxed => ("Sandboxed", "bg-orange-700")
  | LanguageLocked(_) => ("Lang-Locked", "bg-amber-700")
  | TranspilationGuarded => ("Transpile-Guard", "bg-indigo-700")
  | ProductionGated => ("Prod-Gated", "bg-rose-700")
  }
  div(
    list{
      Attrs.class_(`px-2 py-0.5 rounded text-xs ${colour} text-white`),
      Attrs.title("Session protection level — controls what mutations are allowed"),
    },
    list{text(label)},
  )
}

/// Render the execution mode indicator.
let renderExecutionBadge = (mode: executionMode): Tea_Vdom.t<msg> => {
  let (label, colour) = switch mode {
  | Live => ("Live", "bg-green-600")
  | DryRun => ("Dry Run", "bg-yellow-600")
  | Simulation => ("Simulation", "bg-cyan-600")
  | Emulation => ("Emulation", "bg-violet-600")
  }
  div(
    list{
      Attrs.class_(`px-2 py-0.5 rounded text-xs ${colour} text-white`),
      Attrs.title(
        "Execution mode — Live applies changes, Dry Run previews them, Simulation uses mock data",
      ),
    },
    list{text(label)},
  )
}

/// Render a configurator section with title and items.
let renderConfigSection = (
  title: string,
  tooltip: string,
  items: list<Tea_Vdom.t<msg>>,
): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("mb-6")},
    list{
      div(
        list{
          Attrs.class_("text-sm font-medium text-gray-400 mb-2 border-b border-gray-800 pb-1"),
          Attrs.title(tooltip),
        },
        list{text(title)},
      ),
      div(list{Attrs.class_("space-y-2")}, items),
    },
  )
}

/// Render a selectable option button — highlights when active.
let renderOption = (label: string, description: string, isActive: bool, onClick: msg): Tea_Vdom.t<
  msg,
> => {
  let activeClass = if isActive {
    "border-indigo-500 bg-indigo-950/50 text-indigo-300"
  } else {
    "border-gray-800 bg-gray-900/50 text-gray-400 hover:border-gray-600"
  }
  button(
    list{
      Attrs.class_(`w-full text-left p-3 rounded border ${activeClass} transition-colors`),
      Attrs.title(description),
      Attrs.ariaLabel(`${label}: ${description}`),
      Events.onClick(onClick),
    },
    list{
      div(list{Attrs.class_("text-xs font-medium")}, list{text(label)}),
      div(list{Attrs.class_("text-xs text-gray-600 mt-0.5")}, list{text(description)}),
    },
  )
}

/// Render an arrangement card — shows name, active state, load/delete buttons.
let renderArrangementCard = (arr: arrangement, isActive: bool): Tea_Vdom.t<msg> => {
  let activeClass = if isActive {
    "border-indigo-500 bg-indigo-950/50"
  } else {
    "border-gray-800 bg-gray-900/50 hover:border-gray-600"
  }
  div(
    list{
      Attrs.class_(
        `p-3 rounded border ${activeClass} transition-colors flex items-center justify-between`,
      ),
      Attrs.ariaLabel(`Arrangement: ${arr.name}`),
    },
    list{
      div(
        list{Attrs.class_("flex-1")},
        list{
          div(list{Attrs.class_("text-xs font-medium text-gray-300")}, list{text(arr.name)}),
          div(
            list{Attrs.class_("text-xs text-gray-600 mt-0.5")},
            list{
              text(
                `${Int.toString(Array.length(arr.positions))} panels` ++ if arr.builtIn {
                  " (built-in)"
                } else {
                  ""
                },
              ),
            },
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-1")},
        list{
          if !isActive {
            button(
              list{
                Attrs.class_(
                  "px-2 py-0.5 text-xs bg-gray-800 text-gray-400 rounded hover:bg-gray-700",
                ),
                Attrs.ariaLabel(`Load ${arr.name} arrangement`),
                Events.onClick(Workspace(LoadArrangement(arr.id))),
              },
              list{text("Load")},
            )
          } else {
            div(
              list{Attrs.class_("px-2 py-0.5 text-xs bg-indigo-800 text-indigo-300 rounded")},
              list{text("Active")},
            )
          },
          if !arr.builtIn {
            button(
              list{
                Attrs.class_(
                  "px-2 py-0.5 text-xs bg-red-900/50 text-red-400 rounded hover:bg-red-800/50",
                ),
                Attrs.ariaLabel(`Delete ${arr.name} arrangement`),
                Events.onClick(Workspace(DeleteArrangement(arr.id))),
              },
              list{text("Del")},
            )
          } else {
            Tea.Html.noNode
          },
        },
      ),
    },
  )
}

/// Render a panel group card with lock/visibility/z-order controls.
let renderGroupCard = (group: panelGroup): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "p-3 rounded border border-gray-800 bg-gray-900/50 flex items-center justify-between",
      ),
      Attrs.ariaLabel(`Group: ${group.name}`),
    },
    list{
      div(
        list{Attrs.class_("flex-1")},
        list{
          div(list{Attrs.class_("text-xs font-medium text-gray-300")}, list{text(group.name)}),
          div(
            list{Attrs.class_("text-xs text-gray-600 mt-0.5")},
            list{text(`${Int.toString(Array.length(group.panelIds))} panels`)},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-1")},
        list{
          button(
            list{
              Attrs.class_(
                `px-2 py-0.5 text-xs rounded ${if group.locked {
                    "bg-amber-900/50 text-amber-400"
                  } else {
                    "bg-gray-800 text-gray-400 hover:bg-gray-700"
                  }}`,
              ),
              Attrs.ariaLabel(
                if group.locked {
                  "Unlock group"
                } else {
                  "Lock group"
                },
              ),
              Events.onClick(Workspace(ToggleGroupLock(group.id))),
            },
            list{
              text(
                if group.locked {
                  "Locked"
                } else {
                  "Lock"
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                `px-2 py-0.5 text-xs rounded ${if group.visible {
                    "bg-gray-800 text-gray-400 hover:bg-gray-700"
                  } else {
                    "bg-gray-800 text-gray-600"
                  }}`,
              ),
              Attrs.ariaLabel(
                if group.visible {
                  "Hide group"
                } else {
                  "Show group"
                },
              ),
              Events.onClick(Workspace(ToggleGroupVisibility(group.id))),
            },
            list{
              text(
                if group.visible {
                  "Visible"
                } else {
                  "Hidden"
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs bg-red-900/50 text-red-400 rounded hover:bg-red-800/50",
              ),
              Attrs.ariaLabel(`Disband ${group.name} group`),
              Events.onClick(Workspace(DisbandGroup(group.id))),
            },
            list{text("Disband")},
          ),
        },
      ),
    },
  )
}

/// Render a metadata viewer link.
let renderMetadataLink = (item: repoMetadataItem, label: string, description: string): Tea_Vdom.t<
  msg,
> => {
  button(
    list{
      Attrs.class_(
        "w-full text-left p-3 rounded border border-gray-800 bg-gray-900/50 hover:border-gray-600 transition-colors",
      ),
      Attrs.title(description),
      Attrs.ariaLabel(`View ${label}`),
      Events.onClick(Workspace(ViewMetadata(item))),
    },
    list{
      div(list{Attrs.class_("text-xs font-medium text-gray-400")}, list{text(label)}),
      div(list{Attrs.class_("text-xs text-gray-600 mt-0.5")}, list{text(description)}),
    },
  )
}

/// Full Workspace panel view.
let view = (workspace: workspaceState, keybindings: keybindingsState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 overflow-auto"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Workspace configurator"),
    },
    list{
      // Header
      div(
        list{
          Attrs.class_(
            "sticky top-0 bg-gray-950 border-b border-gray-800 p-4 flex items-center justify-between z-10",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-4")},
            list{
              div(list{Attrs.class_("text-lg font-light text-gray-300")}, list{text("Workspace")}),
              renderModeBadge(workspace.mode),
              renderProtectionBadge(workspace.protection),
              renderExecutionBadge(workspace.executionMode),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 bg-indigo-800 text-indigo-200 rounded hover:bg-indigo-700 transition-colors text-sm",
                  ),
                  Attrs.ariaLabel("Export workspace configuration to ENSAID_CONFIG.a2ml"),
                  Events.onClick(Workspace(ExportWorkspaceConfig)),
                  KeyboardNav.onActivate(Workspace(ExportWorkspaceConfig)),
                },
                list{text("Export Config")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 bg-gray-800 text-gray-400 rounded hover:bg-gray-700 transition-colors text-sm",
                  ),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                  KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Body: two-column layout
      div(
        list{Attrs.class_("p-6 grid grid-cols-2 gap-8 max-w-6xl mx-auto")},
        list{
          // Left column: Arrangements & Groups
          div(
            list{Attrs.class_("space-y-6")},
            list{
              renderConfigSection(
                "Arrangements",
                "Named layout presets — save and restore panel positions, sizes, and groups",
                {
                  let cards =
                    workspace.arrangements
                    ->Array.map(arr => {
                      let isActive = workspace.activeArrangementId == Some(arr.id)
                      renderArrangementCard(arr, isActive)
                    })
                    ->List.fromArray
                  List.concat(
                    cards,
                    list{
                      button(
                        list{
                          Attrs.class_(
                            "w-full p-3 rounded border border-dashed border-gray-700 bg-gray-900/30 text-gray-500 hover:border-indigo-600 hover:text-indigo-400 transition-colors text-xs",
                          ),
                          Attrs.ariaLabel("Save the current panel layout as a new arrangement"),
                          Events.onClick(
                            Workspace(
                              SaveArrangement(
                                "custom-" ++ Float.toString(Date.now()),
                                "Custom Layout",
                              ),
                            ),
                          ),
                        },
                        list{text("+ Save Current Layout")},
                      ),
                    },
                  )
                },
              ),
              renderConfigSection(
                "Panel Groups",
                "Group panels to move, resize, show, and hide them together",
                if Array.length(workspace.groups) > 0 {
                  let groupCards = workspace.groups->Array.map(renderGroupCard)->List.fromArray
                  groupCards
                } else {
                  list{
                    div(
                      list{Attrs.class_("p-3 text-xs text-gray-600 italic")},
                      list{
                        text("No groups defined. Groups let you move and resize panels together."),
                      },
                    ),
                  }
                },
              ),
            },
          ),
          // Right column: Sessions, Protection, Modes, Metadata
          div(
            list{Attrs.class_("space-y-6")},
            list{
              renderConfigSection(
                "Sessions",
                "Save, load, fork, and manage working sessions",
                {
                  let sessionCards = if Array.length(workspace.sessions) > 0 {
                    workspace.sessions
                    ->Array.map(session => {
                      let isActive = workspace.activeSessionId == Some(session.id)
                      let activeClass = if isActive {
                        "border-indigo-500 bg-indigo-950/50"
                      } else {
                        "border-gray-800 bg-gray-900/50 hover:border-gray-600"
                      }
                      div(
                        list{
                          Attrs.class_(
                            `p-3 rounded border ${activeClass} transition-colors flex items-center justify-between`,
                          ),
                          Attrs.ariaLabel(`Session: ${session.name}`),
                        },
                        list{
                          div(
                            list{Attrs.class_("flex-1")},
                            list{
                              div(
                                list{Attrs.class_("text-xs font-medium text-gray-300")},
                                list{text(session.name)},
                              ),
                              div(
                                list{Attrs.class_("text-xs text-gray-600 mt-0.5")},
                                list{
                                  text(
                                    `${Int.toString(
                                        Array.length(session.checkpoints),
                                      )} checkpoints`,
                                  ),
                                },
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-1")},
                            list{
                              if !isActive {
                                button(
                                  list{
                                    Attrs.class_(
                                      "px-2 py-0.5 text-xs bg-gray-800 text-gray-400 rounded hover:bg-gray-700",
                                    ),
                                    Events.onClick(Workspace(SwitchSession(session.id))),
                                  },
                                  list{text("Switch")},
                                )
                              } else {
                                div(
                                  list{
                                    Attrs.class_(
                                      "px-2 py-0.5 text-xs bg-indigo-800 text-indigo-300 rounded",
                                    ),
                                  },
                                  list{text("Active")},
                                )
                              },
                              button(
                                list{
                                  Attrs.class_(
                                    "px-2 py-0.5 text-xs bg-teal-900/50 text-teal-400 rounded hover:bg-teal-800/50",
                                  ),
                                  Events.onClick(
                                    Workspace(
                                      ForkSession(
                                        "fork-" ++ Float.toString(Date.now()),
                                        session.name ++ " (fork)",
                                      ),
                                    ),
                                  ),
                                },
                                list{text("Fork")},
                              ),
                              button(
                                list{
                                  Attrs.class_(
                                    "px-2 py-0.5 text-xs bg-red-900/50 text-red-400 rounded hover:bg-red-800/50",
                                  ),
                                  Events.onClick(Workspace(DeleteSession(session.id))),
                                },
                                list{text("Del")},
                              ),
                            },
                          ),
                        },
                      )
                    })
                    ->List.fromArray
                  } else {
                    list{
                      div(
                        list{Attrs.class_("p-3 text-xs text-gray-600 italic")},
                        list{
                          text(
                            "No sessions saved. Sessions capture your workspace state for later recall.",
                          ),
                        },
                      ),
                    }
                  }
                  List.concat(
                    sessionCards,
                    list{
                      button(
                        list{
                          Attrs.class_(
                            "w-full p-3 rounded border border-dashed border-gray-700 bg-gray-900/30 text-gray-500 hover:border-teal-600 hover:text-teal-400 transition-colors text-xs",
                          ),
                          Attrs.ariaLabel("Create a new session from current state"),
                          Events.onClick(
                            Workspace(
                              CreateSession(
                                "session-" ++ Float.toString(Date.now()),
                                "New Session",
                              ),
                            ),
                          ),
                        },
                        list{text("+ New Session")},
                      ),
                    },
                  )
                },
              ),
              renderConfigSection(
                "Workspace Modes",
                "Switch between Rhodium (full RSR), Everything, Code (dev-only), or Bespoke",
                list{
                  renderOption(
                    "Rhodium Mode",
                    "Full RSR standard — SCM files, contractiles, AI manifests, governance panels",
                    workspace.mode == RhodiumMode,
                    Workspace(SetWorkspaceMode(RhodiumMode)),
                  ),
                  renderOption(
                    "Everything Mode",
                    "All panels, all tools, all metadata visible",
                    workspace.mode == EverythingMode,
                    Workspace(SetWorkspaceMode(EverythingMode)),
                  ),
                  renderOption(
                    "Code Mode",
                    "Pure dev — hides RSR governance, shows code-focused panels only",
                    workspace.mode == CodeMode,
                    Workspace(SetWorkspaceMode(CodeMode)),
                  ),
                  renderOption(
                    "Bespoke Mode",
                    "Per-repo customisation loaded from PANELS.a2ml",
                    workspace.mode == BespokeMode,
                    Workspace(SetWorkspaceMode(BespokeMode)),
                  ),
                },
              ),
              renderConfigSection(
                "Session Protection",
                "Control what mutations are allowed in this session",
                list{
                  renderOption(
                    "Open",
                    "Normal operation, no restrictions",
                    workspace.protection == Open,
                    Workspace(SetProtection(Open)),
                  ),
                  renderOption(
                    "Read-Only",
                    "Browse everything, edit nothing",
                    workspace.protection == ReadOnly,
                    Workspace(SetProtection(ReadOnly)),
                  ),
                  renderOption(
                    "Sandboxed",
                    "All changes reset when the session ends",
                    workspace.protection == Sandboxed,
                    Workspace(SetProtection(Sandboxed)),
                  ),
                  renderOption(
                    "Language-Locked",
                    "Specific file types are immutable (e.g., .idr files)",
                    switch workspace.protection {
                    | LanguageLocked(_) => true
                    | _ => false
                    },
                    Workspace(SetProtection(LanguageLocked([".idr", ".lean"]))),
                  ),
                  renderOption(
                    "Transpilation-Guarded",
                    "Saves require equivalence proof before committing",
                    workspace.protection == TranspilationGuarded,
                    Workspace(SetProtection(TranspilationGuarded)),
                  ),
                  renderOption(
                    "Production-Gated",
                    "Changes staged, require sign-off before taking effect",
                    workspace.protection == ProductionGated,
                    Workspace(SetProtection(ProductionGated)),
                  ),
                },
              ),
              renderConfigSection(
                "Execution Mode",
                "Control how changes are applied",
                list{
                  renderOption(
                    "Live",
                    "Real execution against real data",
                    workspace.executionMode == Live,
                    Workspace(SetExecutionMode(Live)),
                  ),
                  renderOption(
                    "Dry Run",
                    "Preview changes without applying — shows diffs, no mutations",
                    workspace.executionMode == DryRun,
                    Workspace(SetExecutionMode(DryRun)),
                  ),
                  renderOption(
                    "Simulation",
                    "Run scenarios with mock data in a simulated environment",
                    workspace.executionMode == Simulation,
                    Workspace(SetExecutionMode(Simulation)),
                  ),
                  renderOption(
                    "Emulation",
                    "Full emulation of the target environment locally",
                    workspace.executionMode == Emulation,
                    Workspace(SetExecutionMode(Emulation)),
                  ),
                },
              ),
              renderConfigSection(
                "Keybindings",
                "Remap keyboard shortcuts — click to rebind, Escape to cancel",
                list{
                  div(
                    list{Attrs.class_("p-3 rounded border border-gray-800 bg-gray-900/50")},
                    list{
                      div(
                        list{Attrs.class_("text-xs text-gray-400")},
                        list{
                          text(
                            `${Int.toString(
                                Array.length(keybindings.bindings),
                              )} bindings configured`,
                          ),
                        },
                      ),
                      div(
                        list{Attrs.class_("mt-2 max-h-40 overflow-auto space-y-1")},
                        keybindings.bindings
                        ->Array.map(binding => {
                          let modStr =
                            binding.chord.modifiers
                            ->Array.map(m =>
                              switch m {
                              | Ctrl => "Ctrl"
                              | Shift => "Shift"
                              | Alt => "Alt"
                              | Meta => "Meta"
                              }
                            )
                            ->Array.join("+")
                          let chordStr = if modStr == "" {
                            binding.chord.key
                          } else {
                            modStr ++ "+" ++ binding.chord.key
                          }
                          let actionStr = switch binding.action {
                          | ActionUndo => "Undo"
                          | ActionRedo => "Redo"
                          | ActionSave => "Save"
                          | ActionPrint => "Print"
                          | ActionResetPanel => "Reset Panel"
                          | ActionResetAll => "Reset All"
                          | ActionTogglePaneL => "Toggle Panel-L"
                          | ActionTogglePaneN => "Toggle Panel-N"
                          | ActionTogglePaneW => "Toggle Panel-W"
                          | ActionToggleVab => "Toggle VAB"
                          | ActionTogglePanelBar => "Toggle Panel Bar"
                          | ActionFullscreen => "Fullscreen"
                          | ActionCloseOverlay => "Close Overlay"
                          | ActionToggleCapture => "Toggle Capture"
                          | ActionToggleWorkspace => "Toggle Workspace"
                          | ActionToggleSecurity => "Toggle Security"
                          | ActionCycleWorkspaceMode => "Cycle Mode"
                          | ActionToggleDryRun => "Toggle Dry Run"
                          }
                          div(
                            list{Attrs.class_("flex items-center justify-between text-xs")},
                            list{
                              span(list{Attrs.class_("text-gray-500")}, list{text(actionStr)}),
                              span(
                                list{
                                  Attrs.class_(
                                    "text-gray-400 font-mono bg-gray-800 px-1.5 py-0.5 rounded",
                                  ),
                                },
                                list{text(chordStr)},
                              ),
                            },
                          )
                        })
                        ->List.fromArray,
                      ),
                    },
                  ),
                },
              ),
              renderConfigSection(
                "Repo Metadata",
                "Quick access to SCM files, contractiles, AI manifests, directory structure",
                list{
                  renderMetadataLink(
                    MetaStateSCM,
                    "STATE.scm",
                    "Current project state — tasks, progress, blockers",
                  ),
                  renderMetadataLink(
                    MetaMetaSCM,
                    "META.scm",
                    "Architecture decisions, governance, principles",
                  ),
                  renderMetadataLink(
                    MetaEcosystemSCM,
                    "ECOSYSTEM.scm",
                    "Project ecosystem position, dependencies",
                  ),
                  renderMetadataLink(
                    MetaContractiles,
                    "Contractiles",
                    "Elastic state contracts — orbital stability, vexation ceiling",
                  ),
                  renderMetadataLink(
                    MetaAIManifest,
                    "AI Manifest",
                    "0-AI-MANIFEST.a2ml — entry point for AI agents",
                  ),
                  renderMetadataLink(
                    MetaTrustfile,
                    "Trustfile",
                    "Security policy from Trustfile.a2ml",
                  ),
                  renderMetadataLink(
                    MetaDirectoryTree,
                    "Directory Tree",
                    "Repository file structure overview",
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Metadata viewer overlay
      switch workspace.viewingMetadata {
      | Some(_item) =>
        div(
          list{Attrs.class_("fixed inset-0 bg-black/60 z-50 flex items-center justify-center")},
          list{
            div(
              list{
                Attrs.class_(
                  "bg-gray-950 border border-gray-700 rounded-lg w-[600px] max-h-[80vh] flex flex-col",
                ),
              },
              list{
                div(
                  list{
                    Attrs.class_("p-4 border-b border-gray-800 flex items-center justify-between"),
                  },
                  list{
                    div(
                      list{Attrs.class_("text-sm font-medium text-gray-300")},
                      list{text("Metadata Viewer")},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          "px-2 py-1 text-xs bg-gray-800 text-gray-400 rounded hover:bg-gray-700",
                        ),
                        Events.onClick(Workspace(CloseMetadata)),
                        KeyboardNav.onActivate(Workspace(CloseMetadata)),
                      },
                      list{text("Close")},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("flex-1 overflow-auto p-4")},
                  list{
                    switch workspace.metadataContent {
                    | Some(content) =>
                      pre(
                        list{Attrs.class_("text-xs text-gray-400 font-mono whitespace-pre-wrap")},
                        list{text(content)},
                      )
                    | None =>
                      div(
                        list{Attrs.class_("text-xs text-gray-600 italic")},
                        list{text("Loading...")},
                      )
                    },
                  },
                ),
              },
            ),
          },
        )
      | None => Tea.Html.noNode
      },
    },
  )
}
