// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for the Level Architect panel.
/// Manages the IDApTIK level editor — grid interaction, entity placement/erasure,
/// patrol waypoints, defence flags, asset browsing, level validation, load/save,
/// undo/redo, and visual toggles.

open Model
open Msg

let updateLevelArchitect = (model: model, msg: levelArchitectMsg): (model, Tea_Cmd.t<msg>) => {
  let la = model.levelArchitect
  switch msg {
  | SetArchitectCategory(cat) => ({...model, levelArchitect: {...la, activeCategory: cat}}, Tea_Cmd.none)
  | ClickGrid(x, y) => {
      // Behaviour depends on selected tool
      switch la.selectedTool {
      | ToolSelect =>
        let entity = la.entities->Array.find(e => e.gridX === x && e.gridY === y)
        let selected = switch entity {
        | Some(e) => Some(e.id)
        | None => None
        }
        ({...model, levelArchitect: {...la, selectedEntityId: selected}}, Tea_Cmd.none)
      | ToolPlace(kind) =>
        if LevelArchitectEngine.isOccupied(la.entities, x, y) {
          (model, Tea_Cmd.none)
        } else {
          let id = `${Int.toString(x)}_${Int.toString(y)}_${Int.toString(Array.length(la.entities))}`
          let entity: levelEntity = {
            id,
            kind,
            name: LevelArchitectEngine.entityKindLabel(kind),
            gridX: x,
            gridY: y,
            rotation: 0,
            properties: [],
          }
          (
            {
              ...model,
              levelArchitect: {
                ...la,
                entities: Array.concat(la.entities, [entity]),
                selectedEntityId: Some(id),
              },
            },
            Tea_Cmd.none,
          )
        }
      | ToolErase =>
        let newEntities = la.entities->Array.filter(e => !(e.gridX === x && e.gridY === y))
        ({...model, levelArchitect: {...la, entities: newEntities}}, Tea_Cmd.none)
      | ToolPatrol => {
        // Add a patrol waypoint at the clicked grid position for the currently selected guard.
        let waypoint: LevelArchitectModel.patrolWaypoint = {x, y, pauseDuration: 1.0}
        let patrols = switch la.selectedEntityId {
        | Some(guardId) => {
            let existing = la.patrols->Array.find(p => p.guardId === guardId)
            switch existing {
            | Some(_patrol) =>
              la.patrols->Array.map(p =>
                if p.guardId === guardId {
                  {...p, waypoints: Array.concat(p.waypoints, [waypoint])}
                } else {
                  p
                }
              )
            | None =>
              Array.concat(la.patrols, [{guardId, waypoints: [waypoint], looping: true, speed: 1.0}])
            }
          }
        | None => la.patrols
        }
        ({...model, levelArchitect: {...la, patrols}}, Tea_Cmd.none)
      }
      | ToolDefenceFlag => {
        // Place a defence flag entity at the clicked grid position.
        if !LevelArchitectEngine.isOccupied(la.entities, x, y) {
          let id = `flag_${Int.toString(x)}_${Int.toString(y)}`
          let entity: levelEntity = {
            id,
            kind: EntityTrigger,
            name: "Defence Flag",
            gridX: x,
            gridY: y,
            rotation: 0,
            properties: [("type", "defence_flag")],
          }
          ({...model, levelArchitect: {...la, entities: Array.concat(la.entities, [entity]), selectedEntityId: Some(id)}}, Tea_Cmd.none)
        } else {
          (model, Tea_Cmd.none)
        }
      }
      }
    }
  | SelectEntity(id) => ({...model, levelArchitect: {...la, selectedEntityId: Some(id)}}, Tea_Cmd.none)
  | DeselectEntity => ({...model, levelArchitect: {...la, selectedEntityId: None}}, Tea_Cmd.none)
  | SelectTool(tool) => ({...model, levelArchitect: {...la, selectedTool: tool}}, Tea_Cmd.none)
  | ToggleDefenceFlag(flag) => {
      let hasIt = la.defenceFlags->Array.includes(flag)
      let newFlags = if hasIt {
        la.defenceFlags->Array.filter(f => f !== flag)
      } else {
        Array.concat(la.defenceFlags, [flag])
      }
      ({...model, levelArchitect: {...la, defenceFlags: newFlags}}, Tea_Cmd.none)
    }
  | SetAlertThreshold(n) => ({...model, levelArchitect: {...la, alertThreshold: n}}, Tea_Cmd.none)
  | BrowseAssets => (
      {...model, levelArchitect: {...la, loading: true}},
      LevelArchitectCmd.browseAssets(result => LevelArchitect(AssetsLoaded(result))),
    )
  | AssetsLoaded(Ok(jsonStr)) => {
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

      let arr = json->JSON.Decode.array->Option.getOr([])
      let items = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let category = obj->Dict.get("category")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let thumbnail = obj->Dict.get("thumbnail")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let kindStr = obj->Dict.get("entityKind")->Option.flatMap(JSON.Decode.string)->Option.getOr("device")
        let entityKind = switch kindStr {
        | "guard" => LevelArchitectModel.EntityGuard
        | "spawn_point" => EntitySpawnPoint
        | "companion" => EntityCompanion
        | "collectable" => EntityCollectable
        | "trigger" => EntityTrigger
        | "decoration" => EntityDecoration
        | _ => EntityDevice
        }
        Some({
          LevelArchitectModel.id: id,
          name: name,
          category: category,
          thumbnail: thumbnail,
          entityKind: entityKind,
        })
      })
      Some(items)

    | None => None
    }
    switch parsed {
    | Some(assets) => (
        {...model, levelArchitect: {...la, assets: assets, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, levelArchitect: {...la, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | AssetsLoaded(Error(err)) => (
      {...model, levelArchitect: {...la, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ValidateLevel => (
      {...model, levelArchitect: {...la, loading: true}},
      Tea_Cmd.batch(list{
        LevelArchitectCmd.validateLevel("", result => LevelArchitect(ValidationResult(result))),
        TypeLLService.checkGameDataTypes("level-data", "level-architect", result => LevelArchitect(TypeCheckResult(result))),
      }),
    )
  | ValidationResult(Ok(jsonStr)) => {
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

      let arr = json->JSON.Decode.array->Option.getOr([])
      let issues = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let severity = obj->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("warning")
        let message = obj->Dict.get("message")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let entityId = obj->Dict.get("entityId")->Option.flatMap(JSON.Decode.string)
        let gridX = obj->Dict.get("gridX")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        let gridY = obj->Dict.get("gridY")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        Some({
          LevelArchitectModel.severity: severity,
          message: message,
          entityId: entityId,
          gridX: gridX,
          gridY: gridY,
        })
      })
      Some(issues)

    | None => None
    }
    switch parsed {
    | Some(issues) => (
        {...model, levelArchitect: {...la, validationIssues: issues, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, levelArchitect: {...la, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | ValidationResult(Error(err)) => (
      {...model, levelArchitect: {...la, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadLevel(path) => (
      {...model, levelArchitect: {...la, loading: true}},
      LevelArchitectCmd.loadLevel(path, result => LevelArchitect(LevelLoaded(result))),
    )
  | LevelLoaded(Ok(jsonStr)) => {
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let levelName = obj->Dict.get("levelName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let gridWidth = obj->Dict.get("gridWidth")->Option.flatMap(JSON.Decode.float)->Option.getOr(32.0)
      let gridHeight = obj->Dict.get("gridHeight")->Option.flatMap(JSON.Decode.float)->Option.getOr(32.0)
      let entArr = obj->Dict.get("entities")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let entities = entArr->Array.filterMap(e => {
        let eObj = e->JSON.Decode.object->Option.getOr(Dict.make())
        let id = eObj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let kindStr = eObj->Dict.get("kind")->Option.flatMap(JSON.Decode.string)->Option.getOr("device")
        let kind = switch kindStr {
        | "guard" => LevelArchitectModel.EntityGuard
        | "spawn_point" => EntitySpawnPoint
        | "companion" => EntityCompanion
        | "collectable" => EntityCollectable
        | "trigger" => EntityTrigger
        | "decoration" => EntityDecoration
        | _ => EntityDevice
        }
        let name = eObj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gridX = eObj->Dict.get("gridX")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let gridY = eObj->Dict.get("gridY")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let rotation = eObj->Dict.get("rotation")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let propsArr = eObj->Dict.get("properties")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let properties = propsArr->Array.filterMap(p => {
          let pArr = p->JSON.Decode.array->Option.getOr([])
          switch (pArr->Array.get(0), pArr->Array.get(1)) {
          | (Some(k), Some(v)) =>
            switch (k->JSON.Decode.string, v->JSON.Decode.string) {
            | (Some(key), Some(val)) => Some((key, val))
            | _ => None
            }
          | _ => None
          }
        })
        Some({
          LevelArchitectModel.id: id,
          kind: kind,
          name: name,
          gridX: Float.toInt(gridX),
          gridY: Float.toInt(gridY),
          rotation: Float.toInt(rotation),
          properties: properties,
        })
      })
      let patArr = obj->Dict.get("patrols")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let patrols = patArr->Array.filterMap(p => {
        let pObj = p->JSON.Decode.object->Option.getOr(Dict.make())
        let guardId = pObj->Dict.get("guardId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let looping = pObj->Dict.get("looping")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
        let speed = pObj->Dict.get("speed")->Option.flatMap(JSON.Decode.float)->Option.getOr(1.0)
        let wpArr = pObj->Dict.get("waypoints")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let waypoints = wpArr->Array.filterMap(w => {
          let wObj = w->JSON.Decode.object->Option.getOr(Dict.make())
          let x = wObj->Dict.get("x")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let y = wObj->Dict.get("y")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let pauseDuration = wObj->Dict.get("pauseDuration")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({LevelArchitectModel.x: Float.toInt(x), y: Float.toInt(y), pauseDuration: pauseDuration})
        })
        Some({
          LevelArchitectModel.guardId: guardId,
          waypoints: waypoints,
          looping: looping,
          speed: speed,
        })
      })
      Some((levelName, Float.toInt(gridWidth), Float.toInt(gridHeight), entities, patrols))

    | None => None
    }
    switch parsed {
    | Some((levelName, gridWidth, gridHeight, entities, patrols)) => (
        {
          ...model,
          levelArchitect: {
            ...la,
            levelName: levelName,
            gridWidth: gridWidth,
            gridHeight: gridHeight,
            entities: entities,
            patrols: patrols,
            loading: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | None => ({...model, levelArchitect: {...la, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | LevelLoaded(Error(err)) => (
      {...model, levelArchitect: {...la, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SaveLevel(path) => (
      model,
      LevelArchitectCmd.saveLevel(path, "", result => LevelArchitect(LevelSaved(result))),
    )
  | LevelSaved(Ok(_)) => (model, Tea_Cmd.none)
  | LevelSaved(Error(err)) => (
      {...model, levelArchitect: {...la, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ExportLevelConfig => (
      model,
      LevelArchitectCmd.exportLevelConfig("", result => LevelArchitect(LevelConfigExported(result))),
    )
  | LevelConfigExported(Ok(_)) => (model, Tea_Cmd.none)
  | LevelConfigExported(Error(err)) => (
      {...model, levelArchitect: {...la, error: Some(err)}},
      Tea_Cmd.none,
    )
  | UndoAction => {
      if la.historyIndex > 0 {
        let newIdx = la.historyIndex - 1
        let entry = la.history->Array.get(newIdx)
        switch entry {
        | Some(e) => (
            {
              ...model,
              levelArchitect: {
                ...la,
                entities: e.entities,
                patrols: e.patrols,
                historyIndex: newIdx,
              },
            },
            Tea_Cmd.none,
          )
        | None => (model, Tea_Cmd.none)
        }
      } else {
        (model, Tea_Cmd.none)
      }
    }
  | RedoAction => {
      if la.historyIndex < Array.length(la.history) - 1 {
        let newIdx = la.historyIndex + 1
        let entry = la.history->Array.get(newIdx)
        switch entry {
        | Some(e) => (
            {
              ...model,
              levelArchitect: {
                ...la,
                entities: e.entities,
                patrols: e.patrols,
                historyIndex: newIdx,
              },
            },
            Tea_Cmd.none,
          )
        | None => (model, Tea_Cmd.none)
        }
      } else {
        (model, Tea_Cmd.none)
      }
    }
  | ToggleGrid => ({...model, levelArchitect: {...la, showGrid: !la.showGrid}}, Tea_Cmd.none)
  | TogglePatrolPaths => (
      {...model, levelArchitect: {...la, showPatrolPaths: !la.showPatrolPaths}},
      Tea_Cmd.none,
    )
  | DismissArchitectError => ({...model, levelArchitect: {...la, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "levelarchitect", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  | _ => (model, Tea_Cmd.none) // Stub: unhandled level architect messages
  }
}
