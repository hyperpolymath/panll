// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// STATE TRANSITION: Panel Switcher (unified panel navigation)
///
/// Handles panel toggle, close, and health check results. Updates the
/// `panelSwitcher` state and the `connectionStatus` of individual panels
/// in the registry. Also bridges to legacy `visible` fields on VAB and
/// CloudGuard so existing code continues to work during migration.
let updatePanelSwitcher = (model: model, msg: panelSwitcherMsg): (model, Tea_Cmd.t<msg>) => {
  let ps = model.panelSwitcher
  switch msg {
  | TogglePanel(id) => {
      // Toggle: if already active, close; otherwise open the requested panel.
      let newActive = ps.activePanel === Some(id) ? None : Some(id)
      // Bridge to legacy visible fields for VAB and CloudGuard.
      let newVab = {...model.vab, visible: newActive === Some(PanelVab)}
      let newCg = {...model.cloudguard, visible: newActive === Some(PanelCloudGuard)}
      // Auto-load Farm inventory when opening the panel for the first time.
      let farmCmd = if newActive === Some(PanelFarm) && !model.farm.loaded && !model.farm.loading {
        FarmCmd.listRepos(result => Farm(ReposLoaded(result)))
      } else {
        Tea_Cmd.none
      }
      // Auto-connect CloudGuard when opening.
      let cgCmd = if (
        newActive === Some(PanelCloudGuard) && model.cloudguard.connection === Disconnected
      ) {
        CloudGuardCmd.verifyToken(result => CloudGuard(TokenVerified(result)))
      } else {
        Tea_Cmd.none
      }
      (
        {
          ...model,
          panelSwitcher: {...ps, activePanel: newActive},
          vab: newVab,
          cloudguard: newCg,
        },
        Tea_Cmd.batch(list{farmCmd, cgCmd}),
      )
    }
  | ClosePanels => {
      let newVab = {...model.vab, visible: false}
      let newCg = {...model.cloudguard, visible: false}
      (
        {
          ...model,
          panelSwitcher: {...ps, activePanel: None, expandedGroup: None},
          vab: newVab,
          cloudguard: newCg,
        },
        Tea_Cmd.none,
      )
    }
  | ExpandGroup(kind) => {
      // Toggle: collapse if already expanded, otherwise expand.
      let newExpanded = ps.expandedGroup === Some(kind) ? None : Some(kind)
      ({...model, panelSwitcher: {...ps, expandedGroup: newExpanded}}, Tea_Cmd.none)
    }
  | HealthCheckResult(panelId, result) => {
      // Update the connectionStatus of the panel that was checked.
      let newStatus = switch result {
      | Ok(_) => ServiceConnected
      | Error(e) => ServiceError(e)
      }
      let newPanels =
        ps.panels->Array.map(p => p.id === panelId ? {...p, connectionStatus: newStatus} : p)
      ({...model, panelSwitcher: {...ps, panels: newPanels}}, Tea_Cmd.none)
    }
  }
}
