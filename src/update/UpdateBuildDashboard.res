// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateBuildDashboard.res — Build Dashboard (build monitoring) sub-updater extracted from Update.res

open Model
open Msg

/// Handles all Build Dashboard (build monitoring) messages.
let updateBuildDashboard = (model: model, msg: buildDashboardMsg): (model, Tea_Cmd.t<msg>) => {
  let bd = model.buildDashboard
  switch msg {
  | SetBuildCategory(cat) => (
      {...model, buildDashboard: {...bd, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | TriggerBuild(target) => {
      let label = BuildDashboardEngine.targetLabel(target)
      let cmd = if bd.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "bsp-mcp",
          "build",
          label,
          result => BuildDashboard(BuildTriggered(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        BuildDashboardCmd.triggerBuild(label, result => BuildDashboard(BuildTriggered(result)))
      }
      let typellCmd = TypeLLService.checkConfigTypes(
        label,
        "build-dashboard",
        result => BuildDashboard(TypeCheckResult(result)),
      )
      ({...model, buildDashboard: {...bd, loading: true}}, Tea_Cmd.batch(list{cmd, typellCmd}))
    }
  | BuildTriggered(Ok(jsonStr)) => {
      let parseTarget = (s: string): BuildDashboardModel.buildTarget =>
        switch s {
        | "game" => TargetGame
        | "vm" => TargetVm
        | "dlc" => TargetDlc
        | "sync_server" => TargetSyncServer
        | "shared" => TargetShared
        | "coprocessors" => TargetCoprocessors
        | other => TargetCustom(other)
        }
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let targetStr =
          obj->Dict.get("target")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let target = parseTarget(targetStr)
        let statusStr =
          obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("running")
        let duration =
          obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let status: BuildDashboardModel.buildStatus = switch statusStr {
        | "success" => BuildSuccess(duration)
        | "failed" => BuildFailed(duration)
        | "cancelled" => BuildCancelled
        | "idle" => BuildIdle
        | _ => BuildRunning
        }
        Some((target, status))

      | None => None
      }
      switch parsed {
      | Some((target, status)) => {
          let targets = bd.targets->Array.map(((t, s)) =>
            if t === target {
              (t, status)
            } else {
              (t, s)
            }
          )
          ({...model, buildDashboard: {...bd, targets, loading: false, error: None}}, Tea_Cmd.none)
        }
      | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | BuildTriggered(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshBuildStatus => {
      let cmd = if bd.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "bsp-mcp",
          "status",
          "",
          result => BuildDashboard(BuildStatusReceived(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        BuildDashboardCmd.readBuildStatus(result => BuildDashboard(BuildStatusReceived(result)))
      }
      ({...model, buildDashboard: {...bd, loading: true}}, cmd)
    }
  | BuildStatusReceived(Ok(jsonStr)) => {
      let parseTarget = (s: string): BuildDashboardModel.buildTarget =>
        switch s {
        | "game" => TargetGame
        | "vm" => TargetVm
        | "dlc" => TargetDlc
        | "sync_server" => TargetSyncServer
        | "shared" => TargetShared
        | "coprocessors" => TargetCoprocessors
        | other => TargetCustom(other)
        }
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let targetStr =
            obj->Dict.get("target")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let target = parseTarget(targetStr)
          let statusStr =
            obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("idle")
          let duration =
            obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let status: BuildDashboardModel.buildStatus = switch statusStr {
          | "success" => BuildSuccess(duration)
          | "failed" => BuildFailed(duration)
          | "cancelled" => BuildCancelled
          | "running" => BuildRunning
          | _ => BuildIdle
          }
          Some((target, status))
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(targets) => (
          {...model, buildDashboard: {...bd, targets, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | BuildStatusReceived(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunTests(target) => {
      let label = BuildDashboardEngine.targetLabel(target)
      let cmd = if bd.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "bsp-mcp",
          "test",
          label,
          result => BuildDashboard(TestsReceived(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        BuildDashboardCmd.runTests(label, result => BuildDashboard(TestsReceived(result)))
      }
      ({...model, buildDashboard: {...bd, loading: true}}, cmd)
    }
  | TestsReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let suite = obj->Dict.get("suite")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let passed =
            obj->Dict.get("passed")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let durationMs =
            obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let output = obj->Dict.get("output")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          Some({
            BuildDashboardModel.name,
            suite,
            passed,
            durationMs,
            output,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(testResults) => (
          {...model, buildDashboard: {...bd, testResults, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | TestsReceived(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | CancelBuild(target) => (
      model,
      BuildDashboardCmd.cancelBuild(
        BuildDashboardEngine.targetLabel(target),
        result => BuildDashboard(BuildCancelled(result)),
      ),
    )
  | BuildCancelled(Ok(_)) => (model, Tea_Cmd.none)
  | BuildCancelled(Error(err)) => (
      {...model, buildDashboard: {...bd, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshHistory => (
      {...model, buildDashboard: {...bd, loading: true}},
      BuildDashboardCmd.readHistory(result => BuildDashboard(HistoryReceived(result))),
    )
  | HistoryReceived(Ok(jsonStr)) => {
      let parseTarget = (s: string): BuildDashboardModel.buildTarget =>
        switch s {
        | "game" => TargetGame
        | "vm" => TargetVm
        | "dlc" => TargetDlc
        | "sync_server" => TargetSyncServer
        | "shared" => TargetShared
        | "coprocessors" => TargetCoprocessors
        | other => TargetCustom(other)
        }
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let targetStr =
            obj->Dict.get("target")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let target = parseTarget(targetStr)
          let statusStr =
            obj->Dict.get("status")->Option.flatMap(JSON.Decode.string)->Option.getOr("idle")
          let durationMs =
            obj->Dict.get("durationMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let status: BuildDashboardModel.buildStatus = switch statusStr {
          | "success" => BuildSuccess(durationMs)
          | "failed" => BuildFailed(durationMs)
          | "cancelled" => BuildCancelled
          | "running" => BuildRunning
          | _ => BuildIdle
          }
          let startedAt =
            obj->Dict.get("startedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let errorCount =
            obj->Dict.get("errorCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let warningCount =
            obj->Dict.get("warningCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            BuildDashboardModel.id,
            target,
            status,
            startedAt,
            durationMs,
            errorCount: Float.toInt(errorCount),
            warningCount: Float.toInt(warningCount),
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(history) => (
          {...model, buildDashboard: {...bd, history, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, buildDashboard: {...bd, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | HistoryReceived(Error(err)) => (
      {...model, buildDashboard: {...bd, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleWatchMode => ({...model, buildDashboard: {...bd, watchMode: !bd.watchMode}}, Tea_Cmd.none)
  | ToggleAutoRebuild => (
      {...model, buildDashboard: {...bd, autoRebuild: !bd.autoRebuild}},
      Tea_Cmd.none,
    )
  | ToggleShowPassed => (
      {...model, buildDashboard: {...bd, showPassedTests: !bd.showPassedTests}},
      Tea_Cmd.none,
    )
  | DismissBuildError => ({...model, buildDashboard: {...bd, error: None}}, Tea_Cmd.none)
  | ToggleBuildBojRouting => (
      {...model, buildDashboard: {...bd, bojRouting: !bd.bojRouting}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "builddashboard", json)
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
