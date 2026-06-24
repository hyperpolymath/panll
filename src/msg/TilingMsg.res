// SPDX-License-Identifier: MPL-2.0

/// Tiling and multi-monitor messages -- detach panels, snap zones, presets.

open Model

type tilingMsg =
  /// Detach a panel into its own browser window.
  | DetachPanel(panelId)
  /// Reattach a previously detached panel back to the main window.
  | ReattachPanel(panelId)
  /// Snap a panel to a specific screen zone.
  | SetSnapZone(panelId, snapZone)
  /// Apply a predefined tiling preset layout.
  | ApplyTilingPreset(tilingPreset)
  /// Clear the active tiling preset and return to freeform.
  | ClearTilingPreset
  /// Show/hide the snap zone preview overlay while dragging.
  | SetSnapPreview(option<snapZone>)
  /// A detached panel window has been closed by the user.
  | DetachedPanelClosed(string)
  /// Sync model state to a detached window via BroadcastChannel.
  | SyncToDetached(string)
  /// Toggle the tiling controls UI visibility.
  | ToggleTilingControls
  /// Enable or disable the tiling system entirely.
  | SetTilingEnabled(bool)
