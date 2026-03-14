// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Panel Switcher Component — grouped slide-out panel navigator.
///
/// Renders a vertical sidebar on the right edge with **group headers**
/// (one per clade kind: AI, Bridge, Builder, etc.). Clicking a group
/// slides out a panel list showing all panels in that kind with their
/// full names, descriptions, and connection status. Clicking a panel
/// opens it as a full-screen overlay.
///
/// Design reference: Visual Paradigm's grouped selection panel — compact
/// category strip with contextual slide-out for discovery.

open Model
open Msg
open Tea.Html

/// Panel-to-kind mapping. Returns the kind string for a panel based on
/// its cladeId in the builtin clade data. Panels without a clade default
/// to "meta".
let panelKind = (panel: panelMeta): string => {
  let clades = CladeBrowserEngine.builtinClades
  switch panel.cladeId {
  | None => "meta"
  | Some(cid) =>
    switch clades->Array.find(c => c.id == cid) {
    | Some(clade) => clade.kind
    | None => "meta"
    }
  }
}

/// The ordered list of groups to show in the sidebar.
/// Each group has a kind key, display label, and accent colour.
type groupDef = {
  kind: string,
  label: string,
  colour: string,
  icon: string,
}

let groups: array<groupDef> = [
  { kind: "ai", label: "AI", colour: "#a78bfa", icon: "ai" },
  { kind: "bridge", label: "Bridge", colour: "#60a5fa", icon: "link" },
  { kind: "builder", label: "Build", colour: "#f59e0b", icon: "hammer" },
  { kind: "database", label: "Data", colour: "#34d399", icon: "db" },
  { kind: "directive", label: "Direct", colour: "#f87171", icon: "flag" },
  { kind: "loader", label: "Load", colour: "#818cf8", icon: "folder" },
  { kind: "meta", label: "Meta", colour: "#9ca3af", icon: "cog" },
  { kind: "network", label: "Net", colour: "#2dd4bf", icon: "wifi" },
  { kind: "scanner", label: "Scan", colour: "#fb923c", icon: "shield" },
  { kind: "terminal", label: "Term", colour: "#a3e635", icon: "term" },
  { kind: "viewer", label: "View", colour: "#c084fc", icon: "eye" },
]

/// Render the connection status indicator dot.
let renderStatusDot = (status: connectionStatus): Tea_Vdom.t<msg> => {
  let colour = switch status {
  | ServiceConnected => "bg-emerald-400"
  | ServiceDisconnected => "bg-gray-600"
  | ServiceChecking => "bg-amber-400 animate-pulse"
  | ServiceError(_) => "bg-red-400"
  }
  div(
    list{Attrs.class_(`w-2 h-2 rounded-full ${colour} flex-shrink-0`)},
    list{},
  )
}

/// Render a single panel entry in the expanded group.
let renderPanelEntry = (panel: panelMeta, isActive: bool): Tea_Vdom.t<msg> => {
  let activeBg = isActive ? "bg-gray-700/80" : "hover:bg-gray-800/60"
  let activeText = isActive ? "text-white" : "text-gray-300"

  div(
    list{
      Attrs.class_(
        `flex items-center gap-1 w-full px-1.5 py-1 rounded-lg ${activeBg} transition-colors group`,
      ),
    },
    list{
      // Main panel button (opens/closes panel)
      button(
        list{
          Attrs.class_(`flex items-center gap-2 flex-1 px-1.5 py-1 rounded text-left ${activeText} transition-colors`),
          Attrs.title(panel.description),
          Attrs.ariaLabel(`Open ${panel.name} panel`),
          Events.onClick(PanelSwitcher(TogglePanel(panel.id))),
        },
        list{
          // Connection dot
          if panel.hasBackend {
            renderStatusDot(panel.connectionStatus)
          } else {
            noNode
          },
          // Panel name
          span(
            list{Attrs.class_("text-sm truncate flex-1")},
            list{text(panel.name)},
          ),
          // Short name badge
          span(
            list{Attrs.class_("text-xs text-gray-500 font-mono opacity-60")},
            list{text(panel.shortName)},
          ),
        },
      ),
      // Detach button (pop-out into separate window)
      button(
        list{
          Attrs.class_("px-1 py-1 text-gray-600 hover:text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity rounded hover:bg-gray-600/50"),
          Attrs.title(`Detach ${panel.name} into separate window`),
          Attrs.ariaLabel(`Detach ${panel.name}`),
          Events.onClick(Tiling(DetachPanel(panel.id))),
        },
        list{
          // Pop-out icon (Unicode box with arrow)
          span(list{Attrs.class_("text-xs")}, list{text("\xe2\x86\x97")}),
        },
      ),
    },
  )
}

/// Render the slide-out panel list for an expanded group.
let renderGroupPanels = (
  group: groupDef,
  panels: array<panelMeta>,
  activePanel: option<panelId>,
): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "absolute right-full top-0 mr-1 w-56 bg-gray-900/95 border border-gray-700 rounded-lg shadow-xl py-1.5 px-1.5 z-50 backdrop-blur-sm",
      ),
      Attrs.style("border-left-color", group.colour),
      Attrs.style("border-left-width", "2px"),
    },
    list{
      // Group header inside the flyout
      div(
        list{Attrs.class_("px-2 py-1 text-xs font-semibold tracking-wider uppercase mb-1")},
        list{
          span(
            list{Attrs.style("color", group.colour)},
            list{text(group.label)},
          ),
          span(
            list{Attrs.class_("text-gray-600 ml-1")},
            list{text(`(${Int.toString(Array.length(panels))})`)},
          ),
        },
      ),
      // Panel entries
      div(
        list{Attrs.class_("flex flex-col gap-0.5 max-h-80 overflow-y-auto")},
        panels->Array.map(panel => {
          let isActive = activePanel === Some(panel.id)
          renderPanelEntry(panel, isActive)
        })->List.fromArray,
      ),
    },
  )
}

/// Render a single group header button in the sidebar strip.
let renderGroupButton = (
  group: groupDef,
  isExpanded: bool,
  panelCount: int,
  hasActivePanel: bool,
): Tea_Vdom.t<msg> => {
  let bgClass = if isExpanded {
    "bg-gray-700"
  } else if hasActivePanel {
    "bg-gray-800"
  } else {
    "bg-transparent hover:bg-gray-800"
  }

  button(
    list{
      Attrs.class_(
        `relative flex flex-col items-center justify-center w-11 py-1.5 rounded-lg ${bgClass} transition-colors cursor-pointer group`,
      ),
      Attrs.title(`${group.label} — ${Int.toString(panelCount)} panels`),
      Attrs.ariaLabel(`${group.label} panel group — ${Int.toString(panelCount)} panels`),
      Attrs.ariaExpanded(isExpanded),
      Events.onClick(PanelSwitcher(ExpandGroup(group.kind))),
    },
    list{
      // Colour accent bar at top
      div(
        list{
          Attrs.class_("w-5 h-0.5 rounded-full mb-0.5"),
          Attrs.style("background-color", group.colour),
        },
        list{},
      ),
      // Label
      span(
        list{
          Attrs.class_("text-[10px] font-medium leading-tight select-none"),
          Attrs.style("color", if isExpanded { group.colour } else { "#9ca3af" }),
        },
        list{text(group.label)},
      ),
      // Panel count badge
      span(
        list{Attrs.class_("text-[8px] text-gray-600 leading-none")},
        list{text(Int.toString(panelCount))},
      ),
      // Active indicator
      if hasActivePanel {
        div(
          list{
            Attrs.class_("absolute left-0.5 top-1/2 -translate-y-1/2 w-1 h-3 rounded-full"),
            Attrs.style("background-color", group.colour),
          },
          list{},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the full panel bar — vertical strip on the right edge with
/// grouped categories and slide-out panel lists.
let view = (switcher: panelSwitcherState): Tea_Vdom.t<msg> => {
  // Build a map of kind → panels
  let panelsByKind = groups->Array.map(group => {
    let panels = switcher.panels->Array.filter(p => panelKind(p) == group.kind)
    (group, panels)
  })

  div(
    list{
      Attrs.class_(
        "fixed right-0 top-0 bottom-0 w-12 bg-gray-900/90 border-l border-gray-800 flex flex-col items-center py-2 gap-0.5 z-50",
      ),
      Attrs.ariaLabel("Panel switcher — grouped by category"),
      Attrs.role("navigation"),
    },
    list{
      // Group buttons with optional slide-out
      div(
        list{Attrs.class_("flex flex-col gap-0.5 w-full px-0.5")},
        panelsByKind->Array.map(((group, panels)) => {
          let isExpanded = switcher.expandedGroup === Some(group.kind)
          let hasActivePanel = panels->Array.some(p => switcher.activePanel === Some(p.id))
          let panelCount = Array.length(panels)

          // Skip groups with no panels
          if panelCount === 0 {
            noNode
          } else {
            div(
              list{Attrs.class_("relative")},
              list{
                renderGroupButton(group, isExpanded, panelCount, hasActivePanel),
                // Slide-out panel list
                if isExpanded {
                  renderGroupPanels(group, panels, switcher.activePanel)
                } else {
                  noNode
                },
              },
            )
          }
        })->List.fromArray,
      ),
    },
  )
}
