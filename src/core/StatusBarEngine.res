// SPDX-License-Identifier: MPL-2.0

/// PanLL Status Bar Engine — widget registry, layout, and default configuration.
///
/// Pure functions for managing the status bar widget system. The status bar
/// is a configurable, VS Code-style bar at the bottom of the window. Users
/// can drag widgets to reorder, toggle visibility, and customise refresh rates
/// via the Workspace panel's configurator.

open StatusBarModel

// ============================================================================
// Default Widget Configuration
// ============================================================================

/// Default set of status bar widgets. These ship with PanLL and can be
/// customised by the user. Order determines initial layout.
let defaultWidgets: array<statusWidget> = [
  {
    id: "active-panel",
    label: "Panel",
    kind: ActivePanel,
    position: Left,
    visible: true,
    refreshRate: 0,
    order: 1,
  },
  {
    id: "workspace-mode",
    label: "Mode",
    kind: WorkspaceMode,
    position: Left,
    visible: true,
    refreshRate: 0,
    order: 2,
  },
  {
    id: "execution-mode",
    label: "Exec",
    kind: ExecutionMode,
    position: Left,
    visible: true,
    refreshRate: 0,
    order: 3,
  },
  {
    id: "session-protection",
    label: "Protection",
    kind: SessionProtection,
    position: Left,
    visible: true,
    refreshRate: 0,
    order: 4,
  },
  {
    id: "repo-info",
    label: "Repo",
    kind: RepoInfo,
    position: Center,
    visible: true,
    refreshRate: 0,
    order: 1,
  },
  {
    id: "provider-status",
    label: "AI",
    kind: ProviderStatus,
    position: Center,
    visible: true,
    refreshRate: 0,
    order: 2,
  },
  {
    id: "task-progress",
    label: "Tasks",
    kind: TaskProgress,
    position: Center,
    visible: true,
    refreshRate: 0,
    order: 3,
  },
  {
    id: "undo-redo",
    label: "Undo",
    kind: UndoRedoStatus,
    position: Center,
    visible: false,
    refreshRate: 0,
    order: 4,
  },
  {
    id: "cpu-usage",
    label: "CPU",
    kind: CpuUsage,
    position: Right,
    visible: true,
    refreshRate: 2000,
    order: 1,
  },
  {
    id: "memory-usage",
    label: "Mem",
    kind: MemoryUsage,
    position: Right,
    visible: true,
    refreshRate: 5000,
    order: 2,
  },
  {
    id: "disk-usage",
    label: "Disk",
    kind: DiskUsage,
    position: Right,
    visible: false,
    refreshRate: 10000,
    order: 3,
  },
  {
    id: "watcher-rate",
    label: "Watch",
    kind: WatcherRate,
    position: Right,
    visible: false,
    refreshRate: 1000,
    order: 4,
  },
  {
    id: "session-uptime",
    label: "Up",
    kind: SessionUptime,
    position: Right,
    visible: true,
    refreshRate: 60000,
    order: 5,
  },
]

// ============================================================================
// Widget Operations
// ============================================================================

/// Toggle a widget's visibility.
let toggleWidget = (state: statusBarState, widgetId: string): statusBarState => {
  {
    ...state,
    widgets: Array.map(state.widgets, w =>
      if w.id === widgetId {
        {...w, visible: !w.visible}
      } else {
        w
      }
    ),
  }
}

/// Move a widget to a new position (Left, Center, Right).
let moveWidget = (
  state: statusBarState,
  widgetId: string,
  newPosition: widgetPosition,
): statusBarState => {
  {
    ...state,
    widgets: Array.map(state.widgets, w =>
      if w.id === widgetId {
        {...w, position: newPosition}
      } else {
        w
      }
    ),
  }
}

/// Reorder a widget within its position group.
let reorderWidget = (state: statusBarState, widgetId: string, newOrder: int): statusBarState => {
  {
    ...state,
    widgets: Array.map(state.widgets, w =>
      if w.id === widgetId {
        {...w, order: newOrder}
      } else {
        w
      }
    ),
  }
}

/// Update the system info snapshot.
let updateSystemInfo = (state: statusBarState, info: systemInfo): statusBarState => {
  {...state, systemInfo: Some(info)}
}

/// Get widgets for a specific position, sorted by order.
let widgetsForPosition = (widgets: array<statusWidget>, position: widgetPosition): array<
  statusWidget,
> => {
  let filtered = Array.filter(widgets, w => w.position === position && w.visible)
  Array.toSorted(filtered, (a, b) => Float.fromInt(a.order) -. Float.fromInt(b.order))
}

/// Format bytes as a human-readable string (KB, MB, GB).
let formatBytes = (bytes: float): string => {
  if bytes >= 1073741824.0 {
    let gb = bytes /. 1073741824.0
    Float.toFixed(gb, ~digits=1) ++ " GB"
  } else if bytes >= 1048576.0 {
    let mb = bytes /. 1048576.0
    Float.toFixed(mb, ~digits=0) ++ " MB"
  } else if bytes >= 1024.0 {
    let kb = bytes /. 1024.0
    Float.toFixed(kb, ~digits=0) ++ " KB"
  } else {
    Float.toFixed(bytes, ~digits=0) ++ " B"
  }
}

/// Format uptime seconds as a human-readable string (Xh Ym).
let formatUptime = (seconds: float): string => {
  let hours = Float.toInt(seconds /. 3600.0)
  let remainder = seconds -. Float.fromInt(hours) *. 3600.0
  let minutes = Float.toInt(remainder /. 60.0)
  if hours > 0 {
    Int.toString(hours) ++ "h " ++ Int.toString(minutes) ++ "m"
  } else {
    Int.toString(minutes) ++ "m"
  }
}

// ============================================================================
// Default State
// ============================================================================

/// Initial status bar state.
let defaultState: statusBarState = {
  widgets: defaultWidgets,
  visible: true,
  systemInfo: None,
  perPanelBars: false,
  draggingWidget: None,
}
