// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// STATE TRANSITION: Palimpsest Plaza (PMPL licensing)
///
/// Handles adoption stats loading, repo scanning, and UI state changes.
/// The backend scans the local filesystem for SPDX headers and LICENSE files.
let updatePlaza = (model: model, msg: plazaMsg): (model, Tea_Cmd.t<msg>) => {
  let plaza = model.plaza
  switch msg {
  | LoadAdoptionStats => (
      {...model, plaza: {...plaza, loading: true, error: None}},
      PlazaCmd.adoptionStats(result => Plaza(AdoptionStatsLoaded(result))),
    )
  | AdoptionStatsLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch PlazaEngine.parseAdoptionStats(jsonStr) {
      | Ok(stats) => (
          {
            ...model,
            plaza: {
              ...plaza,
              loaded: true,
              loading: false,
              error: None,
              stats: Some(stats),
            },
          },
          Tea_Cmd.none,
        )
      | Error(e) => (
          {...model, plaza: {...plaza, loading: false, error: Some(e)}},
          Tea_Cmd.none,
        )
      }
    | Error(e) => (
        {...model, plaza: {...plaza, loading: false, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | ScanRepo(repoName) => (
      {...model, plaza: {...plaza, loading: true}},
      Tea_Cmd.batch(list{
        PlazaCmd.scanRepo(repoName, result => Plaza(RepoScanned(result))),
        TypeLLService.checkConfigTypes(repoName, "plaza", result => Plaza(TypeCheckResult(result))),
      }),
    )
  | RepoScanned(result) =>
    switch result {
    | Ok(jsonStr) => {
        let audit = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>

          let o = json->JSON.Decode.object->Option.getOr(Dict.make())
          let gb = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let gi = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)->Option.getOr(0)
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let rn = gs(o, "repo_name")
          let hl = gb(o, "has_license_file")
          let sc = gi(o, "spdx_header_count")
          let tf = gi(o, "total_source_files")
          let ea = gb(o, "has_exhibit_a")
          let eb = gb(o, "has_exhibit_b")
          let ps = gb(o, "has_provenance_sig")
          let lv = if hl && sc === tf && ea && eb && ps { FullCompliance } else if hl && sc > 0 { PartialCompliance } else { NonCompliant }
          Some({
            repoName: rn, level: lv, filesScanned: tf, filesWithHeaders: sc,
            lastAudit: Date.make()->Date.toISOString,
            checks: [
              {id: "license", name: "LICENSE", description: "LICENSE file", passed: hl, severity: "critical", detail: hl ? "Found" : "Missing"},
              {id: "spdx", name: "SPDX", description: "SPDX headers", passed: sc === tf, severity: "warning", detail: `${Int.toString(sc)}/${Int.toString(tf)}`},
              {id: "exhibit-a", name: "Exhibit A", description: "Ethical Use", passed: ea, severity: "info", detail: ea ? "Present" : "Missing"},
              {id: "exhibit-b", name: "Exhibit B", description: "QS Provenance", passed: eb, severity: "info", detail: eb ? "Present" : "Missing"},
              {id: "sig", name: "Provenance", description: "Signature", passed: ps, severity: "warning", detail: ps ? "Verified" : "Not found"},
            ],
          }: complianceAudit)

        | None => None
        }
        switch audit {
        | Some(a) => ({...model, plaza: {...plaza, loading: false, audits: Array.concat(plaza.audits, [a])}}, Tea_Cmd.none)
        | None => ({...model, plaza: {...plaza, loading: false}}, Tea_Cmd.none)
        }
      }
    | Error(e) => ({...model, plaza: {...plaza, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetPlazaCategory(cat) => (
      {...model, plaza: {...plaza, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | SetPlazaFilter(text) => (
      {...model, plaza: {...plaza, filterText: text}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "plaza", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
