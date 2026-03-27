// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// Update handler for multi-monitor tiling and panel detachment.
/// Manages detached windows, snap zones, and tiling presets.
let updateTiling = (model: model, msg: tilingMsg): (model, Tea_Cmd.t<msg>) => {
  let t = model.tiling
  switch msg {
  | DetachPanel(panelId) => {
      let name = PanelRegistry.panelName(panelId)
      let windowName = `panll-detach-${name}`
      // Open a new browser window for this panel
      let _windowRef = WindowBridge.openWindow(
        `detached.html`,
        windowName,
        "width=800,height=600,menubar=no,toolbar=no,status=no",
      )
      // Track the detached panel in tiling state
      let newTiling = TilingEngine.addDetachedPanel(panelId, windowName, t)
      // Create a BroadcastChannel and send initial sync
      let cmd = Tea_Cmd.call(callbacks => {
        let channel = WindowBridge.createChannel(windowName)
        // Send current panel state identifier to the new window
        WindowBridge.postMessage(channel, `{"panel":"${name}","action":"init"}`)
        // Listen for close events from the detached window
        let _cleanup = WindowBridge.onMessage(channel, msg => {
          if msg === "close" {
            callbacks.enqueue(Tiling(DetachedPanelClosed(windowName)))
          }
        })
      })
      ({...model, tiling: newTiling}, cmd)
    }
  | ReattachPanel(panelId) => {
      // Find the detached panel entry
      let entry = t.detachedPanels->Array.find(dp => dp.panelId === panelId)
      switch entry {
      | Some(dp) => {
          // Close the BroadcastChannel for this window
          let channel = WindowBridge.createChannel(dp.windowName)
          WindowBridge.postMessage(channel, `{"action":"reattach"}`)
          WindowBridge.closeChannel(channel)
          // Remove from detached panels
          let newTiling = TilingEngine.removeDetachedPanel(dp.windowName, t)
          ({...model, tiling: newTiling}, Tea_Cmd.none)
        }
      | None => (model, Tea_Cmd.none)
      }
    }
  | SetSnapZone(_panelId, _zone) =>
    (model, Tea_Cmd.none)
  | ApplyTilingPreset(preset) =>
    ({...model, tiling: {...t, activePreset: Some(preset)}}, Tea_Cmd.none)
  | ClearTilingPreset =>
    ({...model, tiling: {...t, activePreset: None}}, Tea_Cmd.none)
  | SetSnapPreview(zone) =>
    ({...model, tiling: {...t, snapPreview: zone}}, Tea_Cmd.none)
  | DetachedPanelClosed(windowName) =>
    let state = TilingEngine.markDetachedDead(windowName, t)
    ({...model, tiling: state}, Tea_Cmd.none)
  | SyncToDetached(windowName) => {
      // Send model state sync to a specific detached window
      let cmd = Tea_Cmd.call(_callbacks => {
        let channel = WindowBridge.createChannel(windowName)
        WindowBridge.postMessage(channel, `{"action":"sync","timestamp":${Float.toString(Date.now())}}`)
        WindowBridge.closeChannel(channel)
      })
      (model, cmd)
    }
  | ToggleTilingControls =>
    ({...model, tiling: {...t, controlsVisible: !t.controlsVisible}}, Tea_Cmd.none)
  | SetTilingEnabled(enabled) =>
    ({...model, tiling: {...t, tilingEnabled: enabled}}, Tea_Cmd.none)
  }
}
