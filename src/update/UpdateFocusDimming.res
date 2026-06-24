// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

/// Update handler for focus dimming and Smart Memory Mode.
/// Manages dimming mode, per-panel overrides, and interaction tracking.
let updateFocusDimming = (model: model, msg: focusDimmingMsg): (model, Tea_Cmd.t<msg>) => {
  let fd = model.focusDimming
  switch msg {
  | SetDimmingMode(mode) => ({...model, focusDimming: {...fd, mode}}, Tea_Cmd.none)
  | SetPanelFocusOverride(panelId, override) =>
    let state = FocusDimmingEngine.setOverride(panelId, override, fd)
    ({...model, focusDimming: state}, Tea_Cmd.none)
  | RecordInteraction(panelKey) =>
    let state = FocusDimmingEngine.recordInteraction(fd, panelKey, Date.now())
    ({...model, focusDimming: state}, Tea_Cmd.none)
  | SetDimOpacity(opacity) => ({...model, focusDimming: {...fd, dimOpacity: opacity}}, Tea_Cmd.none)
  }
}
