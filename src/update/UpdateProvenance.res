// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Provenance Map — code trust surface.
///
/// Handles file analysis requests, result parsing, palette switching,
/// hostile UX toggling, and per-region acknowledgement. The provenance
/// map is ambient — it doesn't occupy a panel slot.

open Model
open Msg

let updateProvenance = (model: model, msg: provenanceMsg): (model, Tea_Cmd.t<msg>) => {
  let prov = model.provenance
  switch msg {
  | AnalyseFile(repoPath, filePath) => (
      {...model, provenance: {...prov, loading: true, error: None}},
      ProvenanceCmd.analyseFile(repoPath, filePath, result => Provenance(AnalysisResult(result))),
    )
  | AnalysisResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
          let filePath =
            obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let analysedAt =
            obj->Dict.get("analysedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(Date.now())
          let regionsArr =
            obj->Dict.get("regions")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
          let regions = regionsArr->Array.filterMap(item => {
            let r = item->JSON.Decode.object->Option.getOr(Dict.make())
            let startLine =
              r->Dict.get("startLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let endLine =
              r->Dict.get("endLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let trustStr =
              r->Dict.get("trustLevel")->Option.flatMap(JSON.Decode.string)->Option.getOr("unknown")
            let trustLevel: ProvenanceModel.trustLevel = switch trustStr {
            | "verified" => Verified
            | "human_reviewed" => HumanReviewed
            | "ai_assisted" => AiAssisted
            | "unreviewed_ai" => UnreviewedAi
            | _ => Unknown
            }
            let author = r->Dict.get("author")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let authorEmail =
              r->Dict.get("authorEmail")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let coAuthored =
              r->Dict.get("coAuthored")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            let coAuthor = r->Dict.get("coAuthor")->Option.flatMap(JSON.Decode.string)
            let commitSha =
              r->Dict.get("commitSha")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let commitTimestamp =
              r->Dict.get("commitTimestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let acknowledged =
              r->Dict.get("acknowledged")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            Some({
              ProvenanceModel.startLine: Float.toInt(startLine),
              endLine: Float.toInt(endLine),
              trustLevel,
              author,
              authorEmail,
              coAuthored,
              coAuthor,
              commitSha,
              commitTimestamp,
              acknowledged,
            })
          })
          let summaryObj =
            obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
          let getInt = key =>
            summaryObj
            ->Dict.get(key)
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
            ->Float.toInt
          let summary: ProvenanceModel.provenanceSummary = {
            totalLines: getInt("totalLines"),
            verifiedLines: getInt("verifiedLines"),
            humanReviewedLines: getInt("humanReviewedLines"),
            aiAssistedLines: getInt("aiAssistedLines"),
            unreviewedAiLines: getInt("unreviewedAiLines"),
            unknownLines: getInt("unknownLines"),
            authorCount: getInt("authorCount"),
            coAuthorCount: getInt("coAuthorCount"),
            hasViolations: summaryObj
            ->Dict.get("hasViolations")
            ->Option.flatMap(JSON.Decode.bool)
            ->Option.getOr(false),
            unsoundMarkers: getInt("unsoundMarkers"),
          }
          let fp: ProvenanceModel.fileProvenance = {filePath, regions, summary, analysedAt}
          Some(fp)

        | None => None
        }
        switch parsed {
        | Some(fp) => (
            {...model, provenance: {...prov, activeFile: Some(fp), loading: false, error: None}},
            Tea_Cmd.none,
          )
        | None => ({...model, provenance: {...prov, loading: false, error: None}}, Tea_Cmd.none)
        }
      }
    | Error(e) => ({...model, provenance: {...prov, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | UnsoundScanResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
          let unsoundMarkers =
            obj
            ->Dict.get("unsoundMarkers")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
            ->Float.toInt
          Some(unsoundMarkers)

        | None => None
        }
        switch (parsed, prov.activeFile) {
        | (Some(count), Some(fp)) => {
            let updatedSummary = {
              ...fp.summary,
              unsoundMarkers: count,
              hasViolations: count > 0 || fp.summary.hasViolations,
            }
            let updatedFp = {...fp, summary: updatedSummary}
            ({...model, provenance: {...prov, activeFile: Some(updatedFp)}}, Tea_Cmd.none)
          }
        | _ => (model, Tea_Cmd.none)
        }
      }
    | Error(e) => ({...model, provenance: {...prov, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetPalette(palette) => ({...model, provenance: {...prov, palette}}, Tea_Cmd.none)
  | ToggleHostileUx => (
      {...model, provenance: {...prov, hostileUxSuppressed: !prov.hostileUxSuppressed}},
      Tea_Cmd.none,
    )
  | AcknowledgeRegion(_filePath, startLine) =>
    switch prov.activeFile {
    | Some(fp) => {
        let updatedRegions = fp.regions->Array.map(r =>
          if r.startLine === startLine {
            {...r, acknowledged: true}
          } else {
            r
          }
        )
        let updatedFp = {...fp, regions: updatedRegions}
        ({...model, provenance: {...prov, activeFile: Some(updatedFp)}}, Tea_Cmd.none)
      }
    | None => (model, Tea_Cmd.none)
    }
  | SetEnabled(enabled) => ({...model, provenance: {...prov, enabled}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "provenance", json)
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
