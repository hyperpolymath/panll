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
      Attrs.class_(`px-3 py-1 rounded text-xs font-medium ${colour} text-white hover:opacity-80 transition-opacity`),
      Attrs.title("Click to cycle workspace mode: Rhodium > Everything > Code > Bespoke"),
      Events.onClick(Workspace(CycleWorkspaceMode)),
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
      Attrs.title("Execution mode — Live applies changes, Dry Run previews them, Simulation uses mock data"),
    },
    list{text(label)},
  )
}

/// Render a configurator section placeholder with tooltip describing future content.
let renderConfigSection = (title: string, tooltip: string, items: list<Tea_Vdom.t<msg>>): Tea_Vdom.t<msg> => {
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

/// Render a placeholder item that shows what will go there on hover.
let renderPlaceholder = (label: string, description: string): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("p-3 bg-gray-900/50 rounded border border-gray-800 hover:border-gray-600 transition-colors cursor-help"),
      Attrs.title(description),
    },
    list{
      div(list{Attrs.class_("text-xs text-gray-500")}, list{text(label)}),
      div(list{Attrs.class_("text-xs text-gray-700 mt-1 italic")}, list{text(description)}),
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
        list{Attrs.class_("sticky top-0 bg-gray-950 border-b border-gray-800 p-4 flex items-center justify-between z-10")},
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
          button(
            list{
              Attrs.class_("px-3 py-1 bg-gray-800 text-gray-400 rounded hover:bg-gray-700 transition-colors text-sm"),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
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
                list{
                  renderPlaceholder("Default 3-Panel", "Standard three-pane layout (L/N/W equal width)"),
                  renderPlaceholder("AI Focus", "Wide neural pane, narrow symbolic and world panes"),
                  renderPlaceholder("Debug Layout", "Top: L+N side-by-side, Bottom: full-width W pane"),
                  renderPlaceholder("Teaching Mode", "50/50 split with demo comparison area"),
                  renderPlaceholder("+ Save Current", "Save the current panel layout as a new named arrangement"),
                },
              ),
              renderConfigSection(
                "Panel Groups",
                "Group panels to move, resize, show, and hide them together",
                list{
                  renderPlaceholder("Create Group", "Select panels → name the group → panels move together"),
                  renderPlaceholder("Lock/Unlock", "Prevent accidental rearrangement of grouped panels"),
                  renderPlaceholder("Z-Order", "Push to back / pull to front for overlapping panels"),
                },
              ),
            },
          ),

          // Right column: Sessions, Protection, Modes
          div(
            list{Attrs.class_("space-y-6")},
            list{
              renderConfigSection(
                "Sessions",
                "Save, load, fork, and manage working sessions",
                list{
                  renderPlaceholder("Active Session", "Current session context — repo, arrangement, protection"),
                  renderPlaceholder("Checkpoints", "Named snapshots within the session for reset-to-checkpoint"),
                  renderPlaceholder("Fork Session", "Create an independent copy of the current session"),
                },
              ),
              renderConfigSection(
                "Workspace Modes",
                "Switch between Rhodium (full RSR), Everything, Code (dev-only), or Bespoke",
                list{
                  renderPlaceholder("Rhodium Mode", "Full RSR standard — SCM files, contractiles, AI manifests, governance panels"),
                  renderPlaceholder("Everything Mode", "All panels, all tools, all metadata visible"),
                  renderPlaceholder("Code Mode", "Pure dev — hides RSR governance, shows code-focused panels only"),
                  renderPlaceholder("Bespoke Mode", "Per-repo customisation loaded from PANELS.a2ml"),
                },
              ),
              renderConfigSection(
                "Session Protection",
                "Control what mutations are allowed in this session",
                list{
                  renderPlaceholder("Open", "Normal operation, no restrictions"),
                  renderPlaceholder("Read-Only", "Browse everything, edit nothing"),
                  renderPlaceholder("Sandboxed", "All changes reset when the session ends"),
                  renderPlaceholder("Language-Locked", "Specific file types are immutable (e.g., .idr files)"),
                  renderPlaceholder("Transpilation-Guarded", "Saves require equivalence proof before committing"),
                  renderPlaceholder("Production-Gated", "Changes staged, require sign-off before taking effect"),
                },
              ),
              renderConfigSection(
                "Execution Mode",
                "Control how changes are applied",
                list{
                  renderPlaceholder("Live", "Real execution against real data"),
                  renderPlaceholder("Dry Run", "Preview changes without applying — shows diffs, no mutations"),
                  renderPlaceholder("Simulation", "Run scenarios with mock data in a simulated environment"),
                  renderPlaceholder("Emulation", "Full emulation of the target environment locally"),
                },
              ),
              renderConfigSection(
                "Keybindings",
                "Remap keyboard shortcuts — click to rebind, Escape to cancel",
                list{
                  renderPlaceholder(
                    `${Int.toString(Array.length(keybindings.bindings))} bindings configured`,
                    "Click to open the keybinding editor — record new shortcuts, detect conflicts",
                  ),
                },
              ),
              renderConfigSection(
                "Repo Metadata",
                "Quick access to SCM files, contractiles, AI manifests, directory structure",
                list{
                  renderPlaceholder("STATE.scm", "Current project state — tasks, progress, blockers"),
                  renderPlaceholder("META.scm", "Architecture decisions, governance, principles"),
                  renderPlaceholder("ECOSYSTEM.scm", "Project ecosystem position, dependencies"),
                  renderPlaceholder("Contractiles", "Elastic state contracts — orbital stability, vexation ceiling"),
                  renderPlaceholder("AI Manifest", "0-AI-MANIFEST.a2ml — entry point for AI agents"),
                  renderPlaceholder("Trustfile", "Security policy from Trustfile.a2ml"),
                  renderPlaceholder("Directory Tree", "Repository file structure overview"),
                },
              ),
            },
          ),
        },
      ),
    },
  )
}
