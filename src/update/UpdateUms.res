// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateUms.res — UMS (User Mod System) sub-updater extracted from Update.res

open Model
open Msg

let updateUms = (model: model, msg: umsMsg): (model, Tea_Cmd.t<msg>) => {
  let u = model.ums
  switch msg {
  | SetUmsCategory(cat) => ({...model, ums: {...u, activeCategory: cat}}, Tea_Cmd.none)
  | LoadProjects => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.loadProjects(result => Ums(ProjectsLoaded(result))),
    )
  | ProjectsLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let author = obj->Dict.get("author")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let version =
            obj->Dict.get("version")->Option.flatMap(JSON.Decode.string)->Option.getOr("0.1.0")
          let createdAt =
            obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let lastModified =
            obj->Dict.get("lastModified")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let levelCount =
            obj
            ->Dict.get("levelCount")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
            ->Float.toInt
          let puzzleCount =
            obj
            ->Dict.get("puzzleCount")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
            ->Float.toInt
          let assetCount =
            obj
            ->Dict.get("assetCount")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
            ->Float.toInt
          let validated =
            obj->Dict.get("validated")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let projectPath =
            obj->Dict.get("projectPath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          if id !== "" {
            Some({
              UmsModel.id,
              name,
              description,
              author,
              version,
              createdAt,
              lastModified,
              levelCount,
              puzzleCount,
              assetCount,
              validated,
              projectPath,
            })
          } else {
            None
          }
        })

      | None => []
      }
      ({...model, ums: {...u, projects: parsed, loading: false, error: None}}, Tea_Cmd.none)
    }
  | ProjectsLoaded(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | CreateProject(name) => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.createProject(name, "", result => Ums(ProjectCreated(result))),
    )
  | ProjectCreated(Ok(_)) => (model, UmsCmd.loadProjects(result => Ums(ProjectsLoaded(result))))
  | ProjectCreated(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectProject(id) => ({...model, ums: {...u, selectedProjectId: Some(id)}}, Tea_Cmd.none)
  | DeselectProject => ({...model, ums: {...u, selectedProjectId: None}}, Tea_Cmd.none)
  | OpenProject(id) => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.openProject(id, result => Ums(ProjectOpened(result))),
    )
  | ProjectOpened(Ok(_jsonStr)) => ({...model, ums: {...u, loading: false}}, Tea_Cmd.none)
  | ProjectOpened(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DeleteProject(id) => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.deleteProject(id, result => Ums(ProjectDeleted(result))),
    )
  | ProjectDeleted(Ok(_)) => (model, UmsCmd.loadProjects(result => Ums(ProjectsLoaded(result))))
  | ProjectDeleted(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ValidateLevel(levelId) => {
      // Route through BoJ database-mcp when bojRouting is enabled, otherwise Tauri direct.
      let validateCmd = if u.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "database-mcp",
          "ums_validate_level",
          levelId,
          result => Ums(ValidationResult(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        UmsCmd.validateLevel(levelId, result => Ums(ValidationResult(result)))
      }
      // Fire TypeLL ABI type check in parallel — validates level data against
      // the 14 Idris2 ABI module interface (dependent types, quantitative erasure).
      let typellCmd = TypeLLService.checkUmsAbi(levelId, result => Ums(AbiTypeCheckResult(result)))
      ({...model, ums: {...u, loading: true}}, Tea_Cmd.batch(list{validateCmd, typellCmd}))
    }
  | ValidationResult(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let levelId = obj->Dict.get("levelId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let guardsInZones =
          obj->Dict.get("guardsInZones")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let defenceTargetsValid =
          obj
          ->Dict.get("defenceTargetsValid")
          ->Option.flatMap(JSON.Decode.bool)
          ->Option.getOr(false)
        let zonesOrdered =
          obj->Dict.get("zonesOrdered")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let pbxConsistent =
          obj->Dict.get("pbxConsistent")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let devicesExist =
          obj->Dict.get("devicesExist")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let allPassed =
          guardsInZones && defenceTargetsValid && zonesOrdered && pbxConsistent && devicesExist
        let validatedAt =
          obj->Dict.get("validatedAt")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let errors =
          obj
          ->Dict.get("errors")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(e => e->JSON.Decode.string)
        Some({
          UmsModel.levelId,
          guardsInZones,
          defenceTargetsValid,
          zonesOrdered,
          pbxConsistent,
          devicesExist,
          allPassed,
          validatedAt,
          errors,
        })

      | None => None
      }
      let results = switch parsed {
      | Some(r) => Array.concat(u.validationResults, [r])
      | None => u.validationResults
      }
      (
        {...model, ums: {...u, validationResults: results, loading: false, error: None}},
        Tea_Cmd.none,
      )
    }
  | ValidationResult(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadTemplates => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.loadTemplates(result => Ums(TemplatesLoaded(result))),
    )
  | TemplatesLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let categoryStr =
            obj->Dict.get("category")->Option.flatMap(JSON.Decode.string)->Option.getOr("level")
          let category: templateCategory = switch categoryStr {
          | "puzzle" => TemplatePuzzle
          | "campaign" => TemplateCampaign
          | "asset_pack" => TemplateAssetPack
          | _ => TemplateLevel
          }
          let difficulty =
            obj->Dict.get("difficulty")->Option.flatMap(JSON.Decode.string)->Option.getOr("medium")
          let previewImagePath =
            obj->Dict.get("previewImagePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          if id !== "" {
            Some({UmsModel.id, name, description, category, difficulty, previewImagePath})
          } else {
            None
          }
        })

      | None => []
      }
      ({...model, ums: {...u, templates: parsed, loading: false, error: None}}, Tea_Cmd.none)
    }
  | TemplatesLoaded(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | InstantiateTemplate(templateId) => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.instantiateTemplate(templateId, "", result => Ums(TemplateInstantiated(result))),
    )
  | TemplateInstantiated(Ok(_)) => (
      model,
      UmsCmd.loadProjects(result => Ums(ProjectsLoaded(result))),
    )
  | TemplateInstantiated(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadAssets => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.loadAssets(u.selectedProjectId->Option.getOr(""), result => Ums(AssetsLoaded(result))),
    )
  | AssetsLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let assetTypeStr =
            obj->Dict.get("assetType")->Option.flatMap(JSON.Decode.string)->Option.getOr("sprite")
          let assetType: modAssetType = switch assetTypeStr {
          | "sound" => AssetSound
          | "map" => AssetMap
          | "tileset" => AssetTileset
          | "animation" => AssetAnimation
          | "script" => AssetScript
          | _ => AssetSprite
          }
          let filePath =
            obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let sizeBytes =
            obj
            ->Dict.get("sizeBytes")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
            ->Float.toInt
          let usedIn =
            obj
            ->Dict.get("usedIn")
            ->Option.flatMap(JSON.Decode.array)
            ->Option.getOr([])
            ->Array.filterMap(e => e->JSON.Decode.string)
          if id !== "" {
            Some({UmsModel.id, name, assetType, filePath, sizeBytes, usedIn})
          } else {
            None
          }
        })

      | None => []
      }
      ({...model, ums: {...u, assets: parsed, loading: false, error: None}}, Tea_Cmd.none)
    }
  | AssetsLoaded(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ImportAsset(path) => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.importAsset(u.selectedProjectId->Option.getOr(""), path, result => Ums(
        AssetImported(result),
      )),
    )
  | AssetImported(Ok(_)) => (
      model,
      UmsCmd.loadAssets(u.selectedProjectId->Option.getOr(""), result => Ums(AssetsLoaded(result))),
    )
  | AssetImported(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PublishMod => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.publishMod(u.selectedProjectId->Option.getOr(""), "", result => Ums(
        PublishResult(result),
      )),
    )
  | PublishResult(Ok(_jsonStr)) => ({...model, ums: {...u, loading: false}}, Tea_Cmd.none)
  | PublishResult(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadApiReference => (
      {...model, ums: {...u, loading: true}},
      UmsCmd.loadApiReference(result => Ums(ApiReferenceLoaded(result))),
    )
  | ApiReferenceLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let category =
            obj->Dict.get("category")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let signature =
            obj->Dict.get("signature")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let example =
            obj->Dict.get("example")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let since = obj->Dict.get("since")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          if name !== "" {
            Some({UmsModel.name, category, signature, description, example, since})
          } else {
            None
          }
        })

      | None => []
      }
      ({...model, ums: {...u, apiEntries: parsed, loading: false, error: None}}, Tea_Cmd.none)
    }
  | ApiReferenceLoaded(Error(err)) => (
      {...model, ums: {...u, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetUmsFilter(text) => ({...model, ums: {...u, filterText: text}}, Tea_Cmd.none)
  | DismissUmsError => ({...model, ums: {...u, error: None}}, Tea_Cmd.none)
  | ToggleUmsBojRouting => ({...model, ums: {...u, bojRouting: !u.bojRouting}}, Tea_Cmd.none)
  | AbiTypeCheckResult(Ok(_typeInfo)) => {
      // TypeLL verified the level data types against the Idris2 ABI.
      // Increment TypeLL queries served counter for cross-panel telemetry.
      let tl = model.typell
      ({...model, typell: {...tl, queriesServed: tl.queriesServed + 1}}, Tea_Cmd.none)
    }
  | AbiTypeCheckResult(Error(_)) => (model, Tea_Cmd.none) // TypeLL errors don't block UMS workflow
  | NavigateToPanel(targetPanel) => {
      // Cross-panel navigation — switch to a related eNSAID panel from UMS.
      let ps = model.panelSwitcher
      ({...model, panelSwitcher: {...ps, activePanel: Some(targetPanel)}}, Tea_Cmd.none)
    }
  | _ => (model, Tea_Cmd.none) // Stub: unhandled UMS messages
  }
}
