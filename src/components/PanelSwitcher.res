// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Panel Switcher Component — sidebar panel bar for navigating modules.
///
/// Renders a vertical icon bar on the right edge of the screen. Each icon
/// represents a panel module. Clicking an icon opens that panel as a
/// full-screen overlay; clicking the active icon closes it (returns to
/// the core three-pane view).
///
/// Connection status is shown as a coloured dot on each icon:
///   - Green: connected/available
///   - Grey: disconnected (no backend or not running)
///   - Yellow: checking
///   - Red: error

open Model
open Msg
open Tea.Html

/// Render the connection status indicator dot.
let renderStatusDot = (status: connectionStatus): Tea_Vdom.t<msg> => {
  let colour = switch status {
  | ServiceConnected => "bg-emerald-400"
  | ServiceDisconnected => "bg-gray-600"
  | ServiceChecking => "bg-amber-400 animate-pulse"
  | ServiceError(_) => "bg-red-400"
  }
  div(
    list{Attrs.class_(`absolute -top-0.5 -right-0.5 w-2 h-2 rounded-full ${colour}`)},
    list{},
  )
}

/// Render a single panel icon button.
let renderPanelButton = (panel: panelMeta, isActive: bool): Tea_Vdom.t<msg> => {
  let activeBg = isActive ? "bg-gray-700" : "bg-transparent hover:bg-gray-800"
  let activeText = isActive ? "text-white" : "text-gray-400 hover:text-gray-200"

  button(
    list{
      Attrs.class_(`relative flex items-center justify-center w-10 h-10 rounded-lg ${activeBg} ${activeText} transition-colors`),
      Attrs.title(panel.name ++ " — " ++ panel.description),
      Attrs.ariaLabel(`Open ${panel.name} panel`),
      Events.onClick(PanelSwitcher(TogglePanel(panel.id))),
    },
    list{
      span(
        list{Attrs.class_("text-xs font-bold select-none")},
        list{text(panel.shortName)},
      ),
      if panel.hasBackend {
        renderStatusDot(panel.connectionStatus)
      } else {
        noNode
      },
    },
  )
}

/// Render the full panel bar — vertical strip on the right edge.
let view = (switcher: panelSwitcherState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed right-0 top-0 bottom-0 w-12 bg-gray-900/90 border-l border-gray-800 flex flex-col items-center py-2 gap-1 z-50"),
      Attrs.ariaLabel("Panel switcher"),
    },
    list{
      // Panel icons
      div(
        list{Attrs.class_("flex flex-col gap-1")},
        switcher.panels->Array.map(panel => {
          let isActive = switcher.activePanel === Some(panel.id)
          renderPanelButton(panel, isActive)
        })->List.fromArray,
      ),
    },
  )
}
