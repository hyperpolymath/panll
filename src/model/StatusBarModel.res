// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Status Bar Model — types for configurable status bar widgets (DD-025).
///
/// The status bar system renders a VS Code-style bar at the bottom of the window
/// (and optionally per-panel bars on panel edges). Widgets are configurable:
/// users drag-and-drop them into position via the Workspace panel's configurator.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Position of a widget within the status bar.
type widgetPosition =
  | Left
  | Center
  | Right

/// Built-in widget types that the status bar can display.
type widgetKind =
  | ActiveAgents
  | TaskProgress
  | CpuUsage
  | MemoryUsage
  | DiskUsage
  | RepoInfo
  | ProviderStatus
  | WatcherRate
  | SessionUptime
  | ActivePanel
  | WorkspaceMode
  | SessionProtection
  | ExecutionMode
  | UndoRedoStatus
  | CustomWidget(string)

/// A single status bar widget configuration.
type statusWidget = {
  /// Unique identifier for this widget instance.
  id: string,
  /// Display label (shown in the bar).
  label: string,
  /// Widget kind determines what data is displayed.
  kind: widgetKind,
  /// Position in the status bar (Left, Center, Right).
  position: widgetPosition,
  /// Whether this widget is currently visible.
  visible: bool,
  /// Refresh rate in milliseconds (0 = event-driven only).
  refreshRate: int,
  /// Order within the position group (lower = further left).
  order: int,
}

/// System information snapshot received from the Rust backend.
type systemInfo = {
  /// CPU usage as a percentage (0.0–100.0).
  cpuUsage: float,
  /// Total physical memory in bytes.
  memoryTotal: float,
  /// Used physical memory in bytes.
  memoryUsed: float,
  /// Total disk space in bytes.
  diskTotal: float,
  /// Used disk space in bytes.
  diskUsed: float,
  /// System uptime in seconds.
  uptimeSeconds: float,
}

/// Root state for the status bar system.
type statusBarState = {
  /// Configured widgets for the global status bar.
  widgets: array<statusWidget>,
  /// Whether the global status bar is visible.
  visible: bool,
  /// Latest system info snapshot from the backend.
  systemInfo: option<systemInfo>,
  /// Whether per-panel status bars are enabled.
  perPanelBars: bool,
  /// The widget currently being dragged (for reordering).
  draggingWidget: option<string>,
}
