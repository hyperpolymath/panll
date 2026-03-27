// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Panic-Attack — stress testing and weak point analysis.
///
/// Handles capability probing, assail/assault scans, report management,
/// SARIF export, event-chain export, and category/filter state.

open Model
open Msg

let updatePanicAttack = (model: model, subMsg: panicAttackMsg): (model, Tea_Cmd.t<msg>) => {
  let pa = model.panicAttack
  switch subMsg {
  | CheckCapability => (
      {...model, panicAttack: {...pa, mode: "checking"}},
      PanicAttackCmd.checkCapability(result => PanicAttack(CapabilityLoaded(result))),
    )
  | CapabilityLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let mode =
          obj->Dict.get("mode")->Option.flatMap(JSON.Decode.string)->Option.getOr("unavailable")
        let detail = obj->Dict.get("detail")->Option.flatMap(JSON.Decode.string)
        let binary = obj->Dict.get("binary")->Option.flatMap(JSON.Decode.string)
        Some((mode, detail, binary))

      | None => None
      }
      switch parsed {
      | Some((mode, _detail, binary)) => (
          {...model, panicAttack: {...pa, mode, binaryPath: binary, version: binary}},
          Tea_Cmd.none,
        )
      | None => (
          {...model, panicAttack: {...pa, mode: "full", version: Some(jsonStr)}},
          Tea_Cmd.none,
        )
      }
    }
  | CapabilityLoaded(Error(_err)) => (
      {...model, panicAttack: {...pa, mode: "unavailable"}},
      Tea_Cmd.none,
    )
  | SetTargetPath(path) => ({...model, panicAttack: {...pa, targetPath: path}}, Tea_Cmd.none)
  | RunAssail => (
      {...model, panicAttack: {...pa, scanning: true, lastError: None}},
      Tea_Cmd.batch(list{
        PanicAttackCmd.assail(pa.targetPath, result => PanicAttack(AssailResult(result))),
        TypeLLService.checkSecurityTypes(pa.targetPath, "panic-attack", result => PanicAttack(
          TypeCheckResult(result),
        )),
      }),
    )
  | AssailResult(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let summaryObj =
          obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
        let getInt = (d, key) =>
          d->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        let weakPts = getInt(summaryObj, "weak_points")->Option.getOr(0)
        let critPts = getInt(summaryObj, "critical_weak_points")->Option.getOr(0)
        let crashes = getInt(summaryObj, "total_crashes")->Option.getOr(0)
        let robustness =
          summaryObj
          ->Dict.get("robustness_score")
          ->Option.flatMap(JSON.Decode.float)
          ->Option.getOr(0.0)
        let filesScanned = getInt(summaryObj, "files_scanned")->Option.getOr(0)
        let summary: scanSummary = {
          totalFindings: weakPts,
          critical: critPts,
          high: 0,
          medium: weakPts - critPts,
          low: 0,
          info: crashes,
          filesScanned,
          language: summaryObj
          ->Dict.get("program")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr("unknown"),
        }
        Some(summary, robustness)

      | None => None
      }
      switch parsed {
      | Some(summary, _robustness) => (
          {...model, panicAttack: {...pa, scanning: false, summary: Some(summary)}},
          Tea_Cmd.none,
        )
      | None => ({...model, panicAttack: {...pa, scanning: false}}, Tea_Cmd.none)
      }
    }
  | AssailResult(Error(err)) => (
      {...model, panicAttack: {...pa, scanning: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | RunAssault => (
      {...model, panicAttack: {...pa, scanning: true, lastError: None}},
      PanicAttackCmd.assault(pa.targetPath, result => PanicAttack(AssaultResult(result))),
    )
  | AssaultResult(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let summaryObj =
          obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
        let getInt = (d, key) =>
          d->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
        let weakPts = getInt(summaryObj, "weak_points")->Option.getOr(0)
        let critPts = getInt(summaryObj, "critical_weak_points")->Option.getOr(0)
        let crashes = getInt(summaryObj, "total_crashes")->Option.getOr(0)
        let summary: scanSummary = {
          totalFindings: weakPts,
          critical: critPts,
          high: 0,
          medium: weakPts - critPts,
          low: 0,
          info: crashes,
          filesScanned: 0,
          language: summaryObj
          ->Dict.get("program")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr("unknown"),
        }
        Some(summary)

      | None => None
      }
      switch parsed {
      | Some(summary) => (
          {...model, panicAttack: {...pa, scanning: false, summary: Some(summary)}},
          Tea_Cmd.none,
        )
      | None => ({...model, panicAttack: {...pa, scanning: false}}, Tea_Cmd.none)
      }
    }
  | AssaultResult(Error(err)) => (
      {...model, panicAttack: {...pa, scanning: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadReports => (model, PanicAttackCmd.listReports(result => PanicAttack(ReportsLoaded(result))))
  | ReportsLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let targetPath =
            obj->Dict.get("targetPath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let timestamp =
            obj->Dict.get("timestamp")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let summaryObj =
            obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
          let getInt = key =>
            summaryObj
            ->Dict.get(key)
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
            ->Float.toInt
          let language =
            summaryObj->Dict.get("language")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let summary: PanicAttackModel.scanSummary = {
            totalFindings: getInt("totalFindings"),
            critical: getInt("critical"),
            high: getInt("high"),
            medium: getInt("medium"),
            low: getInt("low"),
            info: getInt("info"),
            filesScanned: getInt("filesScanned"),
            language,
          }
          Some({PanicAttackModel.id, targetPath, timestamp, summary})
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(reports) => ({...model, panicAttack: {...pa, reports}}, Tea_Cmd.none)
      | None => (model, Tea_Cmd.none)
      }
    }
  | ReportsLoaded(Error(err)) => (
      {...model, panicAttack: {...pa, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | ViewReport(path) => (
      model,
      PanicAttackCmd.viewReport(path, result => PanicAttack(ReportLoaded(result))),
    )
  | ReportLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let findings = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let file = obj->Dict.get("file")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let line =
            obj->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
          let sevStr =
            obj->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("info")
          let severity: PanicAttackModel.weakPointSeverity = switch sevStr {
          | "critical" => Critical
          | "high" => High
          | "medium" => Medium
          | "low" => Low
          | _ => Info
          }
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let context = obj->Dict.get("context")->Option.flatMap(JSON.Decode.string)
          Some({
            PanicAttackModel.file,
            line,
            category: OtherCategory(""),
            severity,
            description,
            context,
          })
        })
        Some(findings)

      | None => None
      }
      switch parsed {
      | Some(findings) => ({...model, panicAttack: {...pa, findings}}, Tea_Cmd.none)
      | None => (model, Tea_Cmd.none)
      }
    }
  | ReportLoaded(Error(err)) => (
      {...model, panicAttack: {...pa, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | CompareReports(left, right) => (
      model,
      PanicAttackCmd.diffReports(left, right, result => PanicAttack(ComparisonLoaded(result))),
    )
  | ComparisonLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let diffArr = obj->Dict.get("findings")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let findings = diffArr->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let file = o->Dict.get("file")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let line = o->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)
          let sevStr =
            o->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("info")
          let severity: PanicAttackModel.weakPointSeverity = switch sevStr {
          | "critical" => Critical
          | "high" => High
          | "medium" => Medium
          | "low" => Low
          | _ => Info
          }
          let description =
            o->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let context = o->Dict.get("context")->Option.flatMap(JSON.Decode.string)
          Some({
            PanicAttackModel.file,
            line,
            category: OtherCategory(""),
            severity,
            description,
            context,
          })
        })
        Some(findings)

      | None => None
      }
      switch parsed {
      | Some(findings) => ({...model, panicAttack: {...pa, findings, showDiff: true}}, Tea_Cmd.none)
      | None => (model, Tea_Cmd.none)
      }
    }
  | ComparisonLoaded(Error(err)) => (
      {...model, panicAttack: {...pa, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | ExportSarif(path) => (
      model,
      PanicAttackCmd.exportSarif(path, result => PanicAttack(SarifExported(result))),
    )
  | SarifExported(Ok(_path)) => (model, Tea_Cmd.none)
  | SarifExported(Error(err)) => (
      {...model, panicAttack: {...pa, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | ExportEventChain(path) => (
      model,
      PanicAttackCmd.exportEventChain(path, result => PanicAttack(EventChainExported(result))),
    )
  | EventChainExported(Ok(_path)) => (model, Tea_Cmd.none)
  | EventChainExported(Error(err)) => (
      {...model, panicAttack: {...pa, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | SetPanicCategory(cat) => ({...model, panicAttack: {...pa, activeCategory: cat}}, Tea_Cmd.none)
  | SetPanicFilter(filterText) => ({...model, panicAttack: {...pa, filterText}}, Tea_Cmd.none)
  | ToggleDiffView => ({...model, panicAttack: {...pa, showDiff: !pa.showDiff}}, Tea_Cmd.none)
  | DismissError => ({...model, panicAttack: {...pa, lastError: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "panicattack", json)
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
