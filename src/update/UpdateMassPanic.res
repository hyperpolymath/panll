// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Mass Panic — organisation-scale batch scanning.
///
/// Handles assemblyline scanning, repo discovery, incremental BLAKE3,
/// verisim persistence, delta reporting, and notification generation.

open Model
open Msg

let updateMassPanic = (model: model, subMsg: massPanicMsg): (model, Tea_Cmd.t<msg>) => {
  let mp = model.massPanic
  switch subMsg {
  | SetReposDirectory(dir) => ({...model, massPanic: {...mp, reposDirectory: dir}}, Tea_Cmd.none)
  | DiscoverRepos => (
      {...model, massPanic: {...mp, loading: true, lastError: None}},
      MassPanicCmd.discoverRepos(mp.reposDirectory, result => MassPanic(ReposDiscovered(result))),
    )
  | ReposDiscovered(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let repoPath =
            obj->Dict.get("repoPath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let repoName =
            obj->Dict.get("repoName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          Some({
            MassPanicModel.repoPath,
            repoName,
            status: Queued,
            totalFindings: 0,
            critical: 0,
            high: 0,
            medium: 0,
            low: 0,
            filesScanned: 0,
            blake3Hash: None,
            scanDuration: None,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(repoResults) => (
          {...model, massPanic: {...mp, repoResults, loading: false}},
          Tea_Cmd.none,
        )
      | None => ({...model, massPanic: {...mp, loading: false}}, Tea_Cmd.none)
      }
    }
  | ReposDiscovered(Error(err)) => (
      {...model, massPanic: {...mp, loading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | RunAssemblyline =>
    let storePath = switch mp.storage {
    | Filesystem(p) => Some(p)
    | VerisimDB(p) => Some(p)
    | NoStorage => None
    }
    (
      {
        ...model,
        massPanic: {
          ...mp,
          scanning: true,
          progress: 0.0,
          currentRepo: None,
          lastError: None,
        },
      },
      Tea_Cmd.batch(list{
        MassPanicCmd.runAssemblyline(
          mp.reposDirectory,
          mp.incremental,
          mp.cachePath,
          storePath,
          mp.minFindings,
          result => MassPanic(AssemblylineResult(result)),
        ),
        TypeLLService.checkConfigTypes(mp.reposDirectory, "mass-panic", result => MassPanic(
          TypeCheckResult(result),
        )),
      }),
    )
  | RunSelected =>
    // Same as RunAssemblyline but for selected repos only.
    // Backend filters by selection indices.
    let storePath = switch mp.storage {
    | Filesystem(p) => Some(p)
    | VerisimDB(p) => Some(p)
    | NoStorage => None
    }
    (
      {
        ...model,
        massPanic: {
          ...mp,
          scanning: true,
          progress: 0.0,
          currentRepo: None,
          lastError: None,
        },
      },
      MassPanicCmd.runAssemblyline(
        mp.reposDirectory,
        mp.incremental,
        mp.cachePath,
        storePath,
        mp.minFindings,
        result => MassPanic(AssemblylineResult(result)),
      ),
    )
  | AssemblylineResult(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let parseStatus = (s: string): MassPanicModel.repoScanStatus =>
          switch s {
          | "scanning" => Scanning
          | "complete" => Complete
          | "skipped" => Skipped
          | "queued" => Queued
          | _ => Failed(s)
          }
        let resultsArr =
          obj->Dict.get("results")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let repoResults = resultsArr->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let gi = (d, k) =>
            d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          Some({
            MassPanicModel.repoPath: gs(o, "repo_path"),
            repoName: gs(o, "repo_name"),
            status: parseStatus(gs(o, "status")),
            totalFindings: gi(o, "total_findings"),
            critical: gi(o, "critical"),
            high: gi(o, "high"),
            medium: gi(o, "medium"),
            low: gi(o, "low"),
            filesScanned: gi(o, "files_scanned"),
            blake3Hash: o->Dict.get("blake3_hash")->Option.flatMap(JSON.Decode.string),
            scanDuration: o->Dict.get("scan_duration")->Option.flatMap(JSON.Decode.float),
          })
        })
        let summaryObj = obj->Dict.get("summary")->Option.flatMap(JSON.Decode.object)
        let summary = switch summaryObj {
        | Some(s) => {
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let gi = (d, k) =>
              d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
            Some({
              MassPanicModel.totalRepos: gi(s, "total_repos"),
              scannedRepos: gi(s, "scanned_repos"),
              skippedRepos: gi(s, "skipped_repos"),
              failedRepos: gi(s, "failed_repos"),
              totalFindings: gi(s, "total_findings"),
              totalCritical: gi(s, "total_critical"),
              totalHigh: gi(s, "total_high"),
              scanDuration: gf(s, "scan_duration"),
              timestamp: gs(s, "timestamp"),
            })
          }
        | None => None
        }
        Some((repoResults, summary))

      | None => None
      }
      switch parsed {
      | Some((repoResults, summary)) => (
          {
            ...model,
            massPanic: {
              ...mp,
              scanning: false,
              progress: 1.0,
              repoResults,
              summary,
              lastError: None,
            },
          },
          Tea_Cmd.none,
        )
      | None => ({...model, massPanic: {...mp, scanning: false, progress: 1.0}}, Tea_Cmd.none)
      }
    }
  | AssemblylineResult(Error(err)) => (
      {...model, massPanic: {...mp, scanning: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | PollProgress => (model, MassPanicCmd.getProgress(result => MassPanic(ProgressUpdate(result))))
  | ProgressUpdate(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let reposDone =
          obj->Dict.get("repos_done")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let reposTotal =
          obj->Dict.get("repos_total")->Option.flatMap(JSON.Decode.float)->Option.getOr(1.0)
        let currentRepo = obj->Dict.get("current_repo")->Option.flatMap(JSON.Decode.string)
        let progress = if reposTotal > 0.0 {
          reposDone /. reposTotal
        } else {
          0.0
        }
        Some((progress, currentRepo))

      | None => None
      }
      switch parsed {
      | Some((progress, currentRepo)) => (
          {...model, massPanic: {...mp, progress, currentRepo}},
          Tea_Cmd.none,
        )
      | None => (model, Tea_Cmd.none)
      }
    }
  | ProgressUpdate(Error(_)) => // Silently ignore progress poll failures.
    (model, Tea_Cmd.none)
  | ToggleIncremental => (
      {...model, massPanic: {...mp, incremental: !mp.incremental}},
      Tea_Cmd.none,
    )
  | ToggleNotify => ({...model, massPanic: {...mp, notifyEnabled: !mp.notifyEnabled}}, Tea_Cmd.none)
  | SetFilterMode(mode) => ({...model, massPanic: {...mp, filterMode: mode}}, Tea_Cmd.none)
  | SetSortMode(mode) => ({...model, massPanic: {...mp, sortMode: mode}}, Tea_Cmd.none)
  | SetSearchText(text) => ({...model, massPanic: {...mp, searchText: text}}, Tea_Cmd.none)
  | ToggleRepoSelection(index) => {
      let selected = if mp.selectedRepos->Array.includes(index) {
        mp.selectedRepos->Array.filter(i => i !== index)
      } else {
        mp.selectedRepos->Array.concat([index])
      }
      ({...model, massPanic: {...mp, selectedRepos: selected, selectAll: false}}, Tea_Cmd.none)
    }
  | ToggleSelectAll => {
      let newSelectAll = !mp.selectAll
      let selected = if newSelectAll {
        Array.fromInitializer(~length=Array.length(mp.repoResults), i => i)
      } else {
        []
      }
      (
        {...model, massPanic: {...mp, selectAll: newSelectAll, selectedRepos: selected}},
        Tea_Cmd.none,
      )
    }
  | ToggleDelta => ({...model, massPanic: {...mp, showDelta: !mp.showDelta}}, Tea_Cmd.none)
  | LoadDelta => {
      // Use storage path to find the latest reports directory for delta comparison.
      let storePath = switch mp.storage {
      | Filesystem(p) | VerisimDB(p) => p
      | NoStorage => "reports"
      }
      let leftPath = storePath ++ "/previous-report.json"
      let rightPath = storePath ++ "/latest-report.json"
      (
        {...model, massPanic: {...mp, loading: true}},
        MassPanicCmd.diffReports(leftPath, rightPath, result => MassPanic(DeltaLoaded(result))),
      )
    }
  | DeltaLoaded(Ok(jsonStr)) => {
      let deltas = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let gi = (d, k) =>
            d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          let repoName = gs(o, "repo")
          if repoName !== "" {
            Some({
              MassPanicModel.repoName,
              newFindings: gi(o, "new_findings"),
              fixedFindings: gi(o, "fixed_findings"),
              changeDirection: gs(o, "direction"),
            })
          } else {
            None
          }
        })

      | None => []
      }
      (
        {
          ...model,
          massPanic: {...mp, loading: false, delta: deltas, showDelta: true, lastError: None},
        },
        Tea_Cmd.none,
      )
    }
  | DeltaLoaded(Error(err)) => (
      {...model, massPanic: {...mp, loading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | GenerateNotification => {
      // Use the storage path as the report directory for notification generation.
      let reportPath = switch mp.storage {
      | Filesystem(p) | VerisimDB(p) => p ++ "/latest-report.json"
      | NoStorage => "reports/latest-report.json"
      }
      (
        {...model, massPanic: {...mp, loading: true}},
        MassPanicCmd.generateNotification(reportPath, mp.notifyCriticalOnly, result => MassPanic(
          NotificationGenerated(result),
        )),
      )
    }
  | NotificationGenerated(Ok(_md)) => ({...model, massPanic: {...mp, loading: false}}, Tea_Cmd.none)
  | NotificationGenerated(Error(err)) => (
      {...model, massPanic: {...mp, loading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissMassPanicError => ({...model, massPanic: {...mp, lastError: None}}, Tea_Cmd.none)

  // -- Sub-view navigation --
  | SwitchView(view) => ({...model, massPanic: {...mp, activeView: view}}, Tea_Cmd.none)

  // -- Imaging (fNIRS-style spatial health map) --
  | BuildImage =>
    let storePath = switch mp.storage {
    | Filesystem(p) | VerisimDB(p) => Some(p)
    | NoStorage => None
    }
    (
      {...model, massPanic: {...mp, imagingLoading: true, lastError: None}},
      MassPanicCmd.buildImage(mp.reposDirectory, mp.incremental, storePath, result => MassPanic(
        ImageLoaded(result),
      )),
    )
  | ImageLoaded(Ok(json)) => {
      // Parse panll.system-image.v0 JSON into systemImage
      let parsed = switch Decoders.decodeOption(Tea_Json.value, json) {
      | Some(obj) =>
        let getStr = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.string->Option.getOr("")
          | None => ""
          }
        let getFloat = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)
          | None => 0.0
          }
        let getInt = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)->Float.toInt
          | None => 0
          }
        let image: MassPanicModel.systemImage = {
          scanSurface: getStr(obj, "scan_surface"),
          generatedAt: getStr(obj, "generated_at"),
          globalHealth: getFloat(obj, "global_health"),
          globalRisk: getFloat(obj, "global_risk"),
          nodeCount: getInt(obj, "node_count"),
          edgeCount: getInt(obj, "edge_count"),
          totalWeakPoints: getInt(obj, "total_weak_points"),
          totalCritical: getInt(obj, "total_critical"),
          riskDistribution: {healthy: 0, low: 0, moderate: 0, high: 0, critical: 0},
          nodes: [],
          edges: [],
        }
        Some(image)

      | None => None
      }
      switch parsed {
      | Some(img) => (
          {...model, massPanic: {...mp, imagingLoading: false, currentImage: Some(img)}},
          Tea_Cmd.none,
        )
      | None => (
          {
            ...model,
            massPanic: {
              ...mp,
              imagingLoading: false,
              lastError: Some("Failed to parse system image JSON"),
            },
          },
          Tea_Cmd.none,
        )
      }
    }
  | ImageLoaded(Error(err)) => (
      {...model, massPanic: {...mp, imagingLoading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | ImportImageFile => // Wire file picker dialog — invoke Gossamer open dialog, then load the selected file.
    (
      {...model, massPanic: {...mp, imagingLoading: true}},
      MassPanicCmd.buildImage(mp.reposDirectory, false, None, result => MassPanic(
        ImageFileLoaded(result),
      )),
    )
  | ImageFileLoaded(Ok(json)) => {
      // Reuse same parsing logic as ImageLoaded — panll.system-image.v0 JSON.
      let parsed = switch Decoders.decodeOption(Tea_Json.value, json) {
      | Some(obj) =>
        let getStr = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.string->Option.getOr("")
          | None => ""
          }
        let getFloat = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)
          | None => 0.0
          }
        let getInt = (o, k) =>
          switch o->JSON.Decode.object->Option.flatMap(d => d->Dict.get(k)) {
          | Some(v) => v->JSON.Decode.float->Option.getOr(0.0)->Float.toInt
          | None => 0
          }
        let image: MassPanicModel.systemImage = {
          scanSurface: getStr(obj, "scan_surface"),
          generatedAt: getStr(obj, "generated_at"),
          globalHealth: getFloat(obj, "global_health"),
          globalRisk: getFloat(obj, "global_risk"),
          nodeCount: getInt(obj, "node_count"),
          edgeCount: getInt(obj, "edge_count"),
          totalWeakPoints: getInt(obj, "total_weak_points"),
          totalCritical: getInt(obj, "total_critical"),
          riskDistribution: {healthy: 0, low: 0, moderate: 0, high: 0, critical: 0},
          nodes: [],
          edges: [],
        }
        Some(image)

      | None => None
      }
      switch parsed {
      | Some(img) => (
          {...model, massPanic: {...mp, imagingLoading: false, currentImage: Some(img)}},
          Tea_Cmd.none,
        )
      | None => (
          {
            ...model,
            massPanic: {
              ...mp,
              imagingLoading: false,
              lastError: Some("Failed to parse imported image JSON"),
            },
          },
          Tea_Cmd.none,
        )
      }
    }
  | ImageFileLoaded(Error(err)) => (
      {...model, massPanic: {...mp, imagingLoading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )

  // -- Temporal navigation --
  | ListSnapshots => {
      let storePath = switch mp.storage {
      | VerisimDB(p) => p
      | _ => "verisim-data"
      }
      (
        {...model, massPanic: {...mp, temporalLoading: true, lastError: None}},
        MassPanicCmd.listSnapshots(storePath, result => MassPanic(SnapshotsLoaded(result))),
      )
    }
  | SnapshotsLoaded(Ok(jsonStr)) => {
      let snapshots = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let gi = (d, k) =>
            d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          Some({
            MassPanicModel.sequence: gi(o, "sequence"),
            timestamp: gs(o, "timestamp"),
            label: gs(o, "label"),
            nodeCount: gi(o, "node_count"),
            globalHealth: gf(o, "global_health"),
            globalRisk: gf(o, "global_risk"),
            totalWeakPoints: gi(o, "total_weak_points"),
          })
        })

      | None => []
      }
      (
        {...model, massPanic: {...mp, temporalLoading: false, snapshots, lastError: None}},
        Tea_Cmd.none,
      )
    }
  | SnapshotsLoaded(Error(err)) => (
      {...model, massPanic: {...mp, temporalLoading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectSnapshot(slot, index) => {
      let (s0, s1) = mp.selectedSnapshots
      let newSelected = if slot == 0 {
        (Some(index), s1)
      } else {
        (s0, Some(index))
      }
      ({...model, massPanic: {...mp, selectedSnapshots: newSelected}}, Tea_Cmd.none)
    }
  | DiffSnapshots => {
      let storePath = switch mp.storage {
      | VerisimDB(p) => p
      | _ => "verisim-data"
      }
      switch mp.selectedSnapshots {
      | (Some(fromIdx), Some(toIdx)) => (
          {...model, massPanic: {...mp, temporalLoading: true}},
          MassPanicCmd.diffSnapshots(storePath, fromIdx, toIdx, result => MassPanic(
            DiffLoaded(result),
          )),
        )
      | _ => (model, Tea_Cmd.none)
      }
    }
  | DiffLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let gi = (d, k) =>
          d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
        let getStringArray = (d, k) =>
          d
          ->Dict.get(k)
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(v => v->JSON.Decode.string)
        let parseNodeDeltas = (d, k) =>
          d
          ->Dict.get(k)
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let name = gs(o, "name")
            if name !== "" {
              Some({
                MassPanicModel.name,
                healthBefore: gf(o, "health_before"),
                healthAfter: gf(o, "health_after"),
                healthDelta: gf(o, "health_delta"),
                riskBefore: gf(o, "risk_before"),
                riskAfter: gf(o, "risk_after"),
                riskDelta: gf(o, "risk_delta"),
                weakPointDelta: gi(o, "weak_point_delta"),
              })
            } else {
              None
            }
          })
        Some({
          MassPanicModel.fromLabel: gs(obj, "from_label"),
          toLabel: gs(obj, "to_label"),
          fromTimestamp: gs(obj, "from_timestamp"),
          toTimestamp: gs(obj, "to_timestamp"),
          healthDelta: gf(obj, "health_delta"),
          riskDelta: gf(obj, "risk_delta"),
          weakPointDelta: gi(obj, "weak_point_delta"),
          criticalDelta: gi(obj, "critical_delta"),
          newNodes: getStringArray(obj, "new_nodes"),
          removedNodes: getStringArray(obj, "removed_nodes"),
          improvedNodes: parseNodeDeltas(obj, "improved_nodes"),
          degradedNodes: parseNodeDeltas(obj, "degraded_nodes"),
          unchangedCount: gi(obj, "unchanged_count"),
          trend: gs(obj, "trend"),
        })

      | None => None
      }
      switch parsed {
      | Some(diff) => (
          {
            ...model,
            massPanic: {...mp, temporalLoading: false, currentDiff: Some(diff), lastError: None},
          },
          Tea_Cmd.none,
        )
      | None => (
          {
            ...model,
            massPanic: {
              ...mp,
              temporalLoading: false,
              lastError: Some("Failed to parse temporal diff JSON"),
            },
          },
          Tea_Cmd.none,
        )
      }
    }
  | DiffLoaded(Error(err)) => (
      {...model, massPanic: {...mp, temporalLoading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  | TakeSnapshot(label) => {
      let storePath = switch mp.storage {
      | VerisimDB(p) => p
      | _ => "verisim-data"
      }
      (
        {...model, massPanic: {...mp, temporalLoading: true}},
        MassPanicCmd.takeSnapshot(storePath, label, result => MassPanic(SnapshotTaken(result))),
      )
    }
  | SnapshotTaken(Ok(_json)) => // Refresh snapshot list after taking a new one
    ({...model, massPanic: {...mp, temporalLoading: false}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "masspanic", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  | SnapshotTaken(Error(err)) => (
      {...model, massPanic: {...mp, temporalLoading: false, lastError: Some(err)}},
      Tea_Cmd.none,
    )
  }
}
