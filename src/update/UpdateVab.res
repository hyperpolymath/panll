// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

let recomputeVabStatus = (vab: vabState): vabState => {
  let warnings = VabEngine.checkDependencies(vab.server.components, vab.catalog)
  let capabilities = VabEngine.computeCapabilities(vab.server.components, vab.catalog, warnings)
  {...vab, warnings, capabilities}
}

/// STATE TRANSITION: VAB (Verified Assembly Building)
/// Handles server composition: category browsing, component add/remove,
/// server naming, filter/sort, and assembly management. After every
/// assembly-modifying action, recomputes dependency warnings and capabilities.
let updateVab = (model: model, msg: vabMsg): (model, Tea_Cmd.t<msg>) => {
  let vab = model.vab
  switch msg {
  | ToggleVab => ({...model, vab: {...vab, visible: !vab.visible}}, Tea_Cmd.none)
  | SelectCategory(cat) => ({...model, vab: {...vab, selectedCategory: cat}}, Tea_Cmd.none)
  | AddComponent(id) => {
      // Only add if not already present
      let alreadyPresent = Array.some(vab.server.components, c => c === id)
      if alreadyPresent {
        (model, Tea_Cmd.none)
      } else {
        let server = {
          ...vab.server,
          components: Array.concat(vab.server.components, [id]),
        }
        ({...model, vab: recomputeVabStatus({...vab, server})}, Tea_Cmd.none)
      }
    }
  | RemoveComponent(id) => {
      let server = {
        ...vab.server,
        components: Array.filter(vab.server.components, c => c !== id),
      }
      ({...model, vab: recomputeVabStatus({...vab, server})}, Tea_Cmd.none)
    }
  | RenameServer(name) => ({...model, vab: {...vab, server: {...vab.server, name}}}, Tea_Cmd.none)
  | ClearAssembly => {
      let server = {...vab.server, components: []}
      ({...model, vab: recomputeVabStatus({...vab, server})}, Tea_Cmd.none)
    }
  | SetFilterText(text) => ({...model, vab: {...vab, filterText: text}}, Tea_Cmd.none)
  | SetSortBy(sort) => ({...model, vab: {...vab, sortBy: sort}}, Tea_Cmd.none)
  | HoverComponent(id) => ({...model, vab: {...vab, hoveredComponent: id}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "vab", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => {
      UpdateHelpers.logDegradedService("TypeLL", "cross-panel type check failed")
      (model, Tea_Cmd.none)
    }
  }
}
