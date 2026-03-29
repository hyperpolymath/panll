// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for TSDM (Triaxial Software Development Methodology).
/// Manages axis ordering, scope/maintenance/audit tier reordering, cleanup toggles,
/// directive persistence, work item collection, and TypeLL integration.

open Model
open Msg

/// Swap adjacent elements at index `i` and `i+1` in an array.
/// Returns a new array with the swap applied. No-op if index is out of bounds.
let swapAt = (arr: array<'a>, i: int): array<'a> => {
  if i < 0 || i >= Array.length(arr) - 1 {
    arr
  } else {
    let copy = Array.copy(arr)
    let tmp = copy[i]
    switch (tmp, copy[i + 1]) {
    | (Some(a), Some(b)) =>
      ignore(Array.setUnsafe(copy, i, b))
      ignore(Array.setUnsafe(copy, i + 1, a))
      copy
    | _ => arr
    }
  }
}

let updateTsdm = (model: model, subMsg: tsdmMsg): (model, Tea_Cmd.t<msg>) => {
  let ts = model.tsdm
  switch subMsg {
  | MoveAxisUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      ({...model, tsdm: {...ts, axisOrder: swapAt(ts.axisOrder, idx - 1)}}, Tea_Cmd.none)
    }
  | MoveAxisDown(idx) => (
      {...model, tsdm: {...ts, axisOrder: swapAt(ts.axisOrder, idx)}},
      Tea_Cmd.none,
    )
  | MoveScopeTierUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      ({...model, tsdm: {...ts, scopeOrder: swapAt(ts.scopeOrder, idx - 1)}}, Tea_Cmd.none)
    }
  | MoveScopeTierDown(idx) => (
      {...model, tsdm: {...ts, scopeOrder: swapAt(ts.scopeOrder, idx)}},
      Tea_Cmd.none,
    )
  | MoveMaintenanceTierUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      (
        {
          ...model,
          tsdm: {...ts, maintenanceOrder: swapAt(ts.maintenanceOrder, idx - 1)},
        },
        Tea_Cmd.none,
      )
    }
  | MoveMaintenanceTierDown(idx) => (
      {
        ...model,
        tsdm: {...ts, maintenanceOrder: swapAt(ts.maintenanceOrder, idx)},
      },
      Tea_Cmd.none,
    )
  | MoveAuditTierUp(idx) =>
    if idx <= 0 {
      (model, Tea_Cmd.none)
    } else {
      ({...model, tsdm: {...ts, auditOrder: swapAt(ts.auditOrder, idx - 1)}}, Tea_Cmd.none)
    }
  | MoveAuditTierDown(idx) => (
      {...model, tsdm: {...ts, auditOrder: swapAt(ts.auditOrder, idx)}},
      Tea_Cmd.none,
    )
  | ToggleCleanupStep(step) =>
    let isEnabled = ts.cleanupEnabled->Array.some(s => s === step)
    let newEnabled = if isEnabled {
      ts.cleanupEnabled->Array.filter(s => s !== step)
    } else {
      ts.cleanupEnabled->Array.concat([step])
    }
    ({...model, tsdm: {...ts, cleanupEnabled: newEnabled}}, Tea_Cmd.none)
  | SetAxisFilter(filter) => ({...model, tsdm: {...ts, axisFilter: filter}}, Tea_Cmd.none)
  | SetTsdmSearch(text) => ({...model, tsdm: {...ts, searchText: text}}, Tea_Cmd.none)
  | ToggleShowCompleted => (
      {...model, tsdm: {...ts, showCompleted: !ts.showCompleted}},
      Tea_Cmd.none,
    )
  | ToggleLock => ({...model, tsdm: {...ts, locked: !ts.locked}}, Tea_Cmd.none)
  | ResetToDefaults => ({...model, tsdm: TsdmModel.init}, Tea_Cmd.none)
  | SaveDirective => {
      // Serialise the current TSDM state as JSON and persist via Gossamer.
      let axisOrderJson = ts.axisOrder->Array.map(a =>
        switch a {
        | AxisScope => "scope"
        | AxisMaintenance => "maintenance"
        | AxisAudit => "audit"
        }
      )
      let scopeOrderJson = ts.scopeOrder->Array.map(s =>
        switch s {
        | Must => "must"
        | Intend => "intend"
        | Like => "like"
        }
      )
      let maintOrderJson = ts.maintenanceOrder->Array.map(m =>
        switch m {
        | Corrective => "corrective"
        | Adaptive => "adaptive"
        | Perfective => "perfective"
        }
      )
      let auditOrderJson = ts.auditOrder->Array.map(a =>
        switch a {
        | Systems => "systems"
        | Compliance => "compliance"
        | Effects => "effects"
        }
      )
      let directiveJson = `{"axisOrder":${JSON.stringify(
          JSON.Encode.array(axisOrderJson->Array.map(JSON.Encode.string)),
        )},"scopeOrder":${JSON.stringify(
          JSON.Encode.array(scopeOrderJson->Array.map(JSON.Encode.string)),
        )},"maintenanceOrder":${JSON.stringify(
          JSON.Encode.array(maintOrderJson->Array.map(JSON.Encode.string)),
        )},"auditOrder":${JSON.stringify(
          JSON.Encode.array(auditOrderJson->Array.map(JSON.Encode.string)),
        )},"locked":${if ts.locked {
          "true"
        } else {
          "false"
        }}}`
      (
        model,
        Tea_Cmd.batch(list{
          TsdmCmd.saveDirective(directiveJson, result => Tsdm(DirectiveSaved(result))),
          TypeLLService.checkSecurityTypes(directiveJson, "tsdm", result => Tsdm(
            TypeCheckResult(result),
          )),
        }),
      )
    }
  | DirectiveSaved(Ok(_path)) => (model, Tea_Cmd.none)
  | DirectiveSaved(Error(err)) => ({...model, tsdm: {...ts, lastError: Some(err)}}, Tea_Cmd.none)
  | LoadDirective => (model, TsdmCmd.loadDirective(result => Tsdm(DirectiveLoaded(result))))
  | DirectiveLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let parseAxisOrder =
          obj
          ->Dict.get("axisOrder")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(v =>
            switch v->JSON.Decode.string {
            | Some("scope") => Some(TsdmModel.AxisScope)
            | Some("maintenance") => Some(TsdmModel.AxisMaintenance)
            | Some("audit") => Some(TsdmModel.AxisAudit)
            | _ => None
            }
          )
        let parseScopeOrder =
          obj
          ->Dict.get("scopeOrder")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(v =>
            switch v->JSON.Decode.string {
            | Some("must") => Some(TsdmModel.Must)
            | Some("intend") => Some(TsdmModel.Intend)
            | Some("like") => Some(TsdmModel.Like)
            | _ => None
            }
          )
        let parseMaintOrder =
          obj
          ->Dict.get("maintenanceOrder")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(v =>
            switch v->JSON.Decode.string {
            | Some("corrective") => Some(TsdmModel.Corrective)
            | Some("adaptive") => Some(TsdmModel.Adaptive)
            | Some("perfective") => Some(TsdmModel.Perfective)
            | _ => None
            }
          )
        let parseAuditOrder =
          obj
          ->Dict.get("auditOrder")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(v =>
            switch v->JSON.Decode.string {
            | Some("systems") => Some(TsdmModel.Systems)
            | Some("compliance") => Some(TsdmModel.Compliance)
            | Some("effects") => Some(TsdmModel.Effects)
            | _ => None
            }
          )
        let locked = obj->Dict.get("locked")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some((parseAxisOrder, parseScopeOrder, parseMaintOrder, parseAuditOrder, locked))

      | None => None
      }
      switch parsed {
      | Some((axisOrder, scopeOrder, maintOrder, auditOrder, locked)) =>
        let newTs = {
          ...ts,
          axisOrder: if Array.length(axisOrder) > 0 {
            axisOrder
          } else {
            ts.axisOrder
          },
          scopeOrder: if Array.length(scopeOrder) > 0 {
            scopeOrder
          } else {
            ts.scopeOrder
          },
          maintenanceOrder: if Array.length(maintOrder) > 0 {
            maintOrder
          } else {
            ts.maintenanceOrder
          },
          auditOrder: if Array.length(auditOrder) > 0 {
            auditOrder
          } else {
            ts.auditOrder
          },
          locked,
        }
        ({...model, tsdm: newTs}, Tea_Cmd.none)
      | None => (model, Tea_Cmd.none)
      }
    }
  | DirectiveLoaded(Error(err)) => ({...model, tsdm: {...ts, lastError: Some(err)}}, Tea_Cmd.none)
  | CollectWorkItems => (
      model,
      TsdmCmd.collectWorkItems(result => Tsdm(WorkItemsCollected(result))),
    )
  | WorkItemsCollected(Ok(jsonStr)) => {
      let items = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let id = gs(o, "id")
          if id !== "" {
            let axis = switch gs(o, "axis") {
            | "scope" => TsdmModel.AxisScope
            | "maintenance" => TsdmModel.AxisMaintenance
            | _ => TsdmModel.AxisAudit
            }
            let scopeTier = switch gs(o, "scope_tier") {
            | "must" => Some(TsdmModel.Must)
            | "intend" => Some(TsdmModel.Intend)
            | "like" => Some(TsdmModel.Like)
            | _ => None
            }
            let maintenanceTier = switch gs(o, "maintenance_tier") {
            | "corrective" => Some(TsdmModel.Corrective)
            | "adaptive" => Some(TsdmModel.Adaptive)
            | "perfective" => Some(TsdmModel.Perfective)
            | _ => None
            }
            let auditTier = switch gs(o, "audit_tier") {
            | "systems" => Some(TsdmModel.Systems)
            | "compliance" => Some(TsdmModel.Compliance)
            | "effects" => Some(TsdmModel.Effects)
            | _ => None
            }
            Some({
              TsdmModel.id,
              title: gs(o, "title"),
              description: gs(o, "description"),
              axis,
              scopeTier,
              maintenanceTier,
              auditTier,
              sourcePanel: gs(o, "source_panel"),
              done: gb(o, "done"),
            })
          } else {
            None
          }
        })

      | None => []
      }
      ({...model, tsdm: {...ts, workItems: items}}, Tea_Cmd.none)
    }
  | WorkItemsCollected(Error(err)) => (
      {...model, tsdm: {...ts, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissTsdmError => ({...model, tsdm: {...ts, lastError: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "tsdm", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
