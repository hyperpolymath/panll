// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Status Bar — configurable bottom bar with system info widgets (DD-025).
///
/// Renders a VS Code-style status bar at the bottom of the window. Widgets
/// are configurable via the Workspace panel's configurator. Each widget
/// shows a label + value and can be toggled, repositioned, and reordered.

open Model
open Msg
open Tea.Html

/// Render a single status bar widget.
let renderWidget = (widget: statusWidget, model: model): Tea_Vdom.t<msg> => {
  let value = switch widget.kind {
  | ActivePanel =>
    switch model.panelSwitcher.activePanel {
    | Some(id) => PanelRegistry.panelName(id)
    | None => "Core Panes"
    }
  | WorkspaceMode =>
    switch model.workspace.mode {
    | RhodiumMode => "Rhodium"
    | EverythingMode => "Everything"
    | CodeMode => "Code"
    | BespokeMode => "Bespoke"
    }
  | SessionProtection =>
    switch model.workspace.protection {
    | Open => "Open"
    | ReadOnly => "RO"
    | Sandboxed => "Sand"
    | LanguageLocked(_) => "LangLock"
    | TranspilationGuarded => "TGuard"
    | ProductionGated => "ProdGate"
    }
  | ExecutionMode =>
    switch model.workspace.executionMode {
    | Live => "Live"
    | DryRun => "DryRun"
    | Simulation => "Sim"
    | Emulation => "Emu"
    }
  | CpuUsage =>
    switch model.statusBar.systemInfo {
    | Some(info) => Float.toFixed(info.cpuUsage, ~digits=0) ++ "%"
    | None => "--"
    }
  | MemoryUsage =>
    switch model.statusBar.systemInfo {
    | Some(info) => StatusBarEngine.formatBytes(info.memoryUsed)
    | None => "--"
    }
  | DiskUsage =>
    switch model.statusBar.systemInfo {
    | Some(info) => StatusBarEngine.formatBytes(info.diskUsed)
    | None => "--"
    }
  | RepoInfo =>
    switch model.repoLoader.currentRepo {
    | Some(repo) => repo.name
    | None => "No repo"
    }
  | ProviderStatus =>
    if model.ai.loading {
      "AI..."
    } else if model.ai.broadcastMode {
      "Broadcast"
    } else {
      Int.toString(Array.length(model.ai.providers)) ++ " providers"
    }
  | TaskProgress => "0/0"
  | WatcherRate => Int.toString(model.watcher.eventCount) ++ " events"
  | SessionUptime =>
    switch model.statusBar.systemInfo {
    | Some(info) => StatusBarEngine.formatUptime(info.uptimeSeconds)
    | None => "--"
    }
  | ActiveAgents => "0 agents"
  | UndoRedoStatus =>
    Int.toString(Array.length(model.undoStack)) ++
    "/" ++
    Int.toString(Array.length(model.redoStack))
  | CustomWidget(label) => label
  }

  div(
    list{
      Attrs.class_(
        "flex items-center gap-1 px-2 py-0.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800/50 rounded cursor-default transition-colors",
      ),
      Attrs.title(widget.label ++ ": " ++ value),
    },
    list{
      div(list{Attrs.class_("text-gray-600")}, list{text(widget.label)}),
      div(list{Attrs.class_("text-gray-300")}, list{text(value)}),
    },
  )
}

/// Render the full status bar.
let view = (model: model): Tea_Vdom.t<msg> => {
  if !model.statusBar.visible {
    noNode
  } else {
    let leftWidgets = StatusBarEngine.widgetsForPosition(model.statusBar.widgets, Left)
    let centerWidgets = StatusBarEngine.widgetsForPosition(model.statusBar.widgets, Center)
    let rightWidgets = StatusBarEngine.widgetsForPosition(model.statusBar.widgets, Right)

    div(
      list{
        Attrs.class_(
          "h-6 bg-gray-900 border-t border-gray-800 flex items-center justify-between px-2 relative z-20 shrink-0",
        ),
        Attrs.role("status"),
        Attrs.ariaLabel("PanLL status bar"),
      },
      list{
        // Left section
        div(
          list{Attrs.class_("flex items-center gap-1")},
          Array.map(leftWidgets, w => renderWidget(w, model))->List.fromArray,
        ),
        // Center section
        div(
          list{Attrs.class_("flex items-center gap-1")},
          Array.map(centerWidgets, w => renderWidget(w, model))->List.fromArray,
        ),
        // Right section
        div(
          list{Attrs.class_("flex items-center gap-1")},
          Array.map(rightWidgets, w => renderWidget(w, model))->List.fromArray,
        ),
      },
    )
  }
}
