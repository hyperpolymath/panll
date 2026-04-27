// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateAutomationRouter.res — Automation Router (workflow orchestration) sub-updater extracted from Update.res

open Model
open Msg

/// Handles all Automation Router (workflow orchestration) messages.
let updateAutomationRouter = (model: model, msg: automationRouterMsg): (model, Tea_Cmd.t<msg>) => {
  let ar = model.automationRouter
  switch msg {
  | SetRouterCategory(cat) => (
      {...model, automationRouter: {...ar, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | ToggleGlobalEnabled => (
      {...model, automationRouter: {...ar, globalEnabled: !ar.globalEnabled}},
      Tea_Cmd.none,
    )
  | ToggleRule(ruleId) => {
      let newRules = ar.rules->Array.map(r =>
        if r.id === ruleId {
          {...r, enabled: !r.enabled}
        } else {
          r
        }
      )
      ({...model, automationRouter: {...ar, rules: newRules}}, Tea_Cmd.none)
    }
  | ExecuteRule(ruleId) => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "agent-mcp",
          "execute_rule",
          ruleId,
          result => AutomationRouter(ExecutionResult(ruleId, result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        AutomationRouterCmd.executeRule(ruleId, result => AutomationRouter(
          ExecutionResult(ruleId, result),
        ))
      }
      let typellCmd = TypeLLService.checkConfigTypes(
        ruleId,
        "automation-router",
        result => AutomationRouter(TypeCheckResult(result)),
      )
      (model, Tea_Cmd.batch(list{cmd, typellCmd}))
    }
  | ExecutionResult(ruleId, Ok(detail)) => {
      let now = Date.now()
      let entry: executionLogEntry = {
        ruleId,
        ruleName: switch ar.rules->Array.find(r => r.id === ruleId) {
        | Some(r) => r.name
        | None => ruleId
        },
        triggeredAt: now,
        completedAt: now,
        success: true,
        detail,
      }
      let newRules = ar.rules->Array.map(r =>
        if r.id === ruleId {
          {...r, firedCount: r.firedCount + 1, lastFired: Some(now), lastResult: Some(detail)}
        } else {
          r
        }
      )
      (
        {
          ...model,
          automationRouter: {
            ...ar,
            rules: newRules,
            executionLog: Array.concat([entry], ar.executionLog),
          },
        },
        Tea_Cmd.none,
      )
    }
  | ExecutionResult(ruleId, Error(err)) => {
      let now = Date.now()
      let entry: executionLogEntry = {
        ruleId,
        ruleName: switch ar.rules->Array.find(r => r.id === ruleId) {
        | Some(r) => r.name
        | None => ruleId
        },
        triggeredAt: now,
        completedAt: now,
        success: false,
        detail: err,
      }
      (
        {
          ...model,
          automationRouter: {
            ...ar,
            executionLog: Array.concat([entry], ar.executionLog),
            error: Some(err),
          },
        },
        Tea_Cmd.none,
      )
    }
  | ApproveAction(idx) => {
      let newPending = ar.pendingActions->Array.filterWithIndex((_a, i) => i !== idx)
      ({...model, automationRouter: {...ar, pendingActions: newPending}}, Tea_Cmd.none)
    }
  | RejectAction(idx) => {
      let newPending = ar.pendingActions->Array.filterWithIndex((_a, i) => i !== idx)
      ({...model, automationRouter: {...ar, pendingActions: newPending}}, Tea_Cmd.none)
    }
  | ApproveAll => ({...model, automationRouter: {...ar, pendingActions: []}}, Tea_Cmd.none)
  | RejectAll => ({...model, automationRouter: {...ar, pendingActions: []}}, Tea_Cmd.none)
  | LoadRules => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "agent-mcp",
          "load_rules",
          "",
          result => AutomationRouter(RulesLoaded(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        AutomationRouterCmd.loadRules(result => AutomationRouter(RulesLoaded(result)))
      }
      ({...model, automationRouter: {...ar, loading: true}}, cmd)
    }
  | RulesLoaded(Ok(jsonStr)) => {
      let parseApproval = (s: string): AutomationRouterModel.approvalMode =>
        switch s {
        | "require_approval" => RequireApproval
        | "approve_once" => ApproveOnce
        | "dry_run_first" => DryRunFirst
        | _ => AutoFire
        }
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let enabled =
            obj->Dict.get("enabled")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
          let approvalStr =
            obj->Dict.get("approval")->Option.flatMap(JSON.Decode.string)->Option.getOr("auto_fire")
          let approval = parseApproval(approvalStr)
          let priority =
            obj->Dict.get("priority")->Option.flatMap(JSON.Decode.string)->Option.getOr("normal")
          let firedCount =
            obj->Dict.get("firedCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let lastFired = obj->Dict.get("lastFired")->Option.flatMap(JSON.Decode.float)
          let lastResult = obj->Dict.get("lastResult")->Option.flatMap(JSON.Decode.string)
          Some({
            AutomationRouterModel.id,
            name,
            description,
            enabled,
            trigger: Manual,
            conditions: [],
            actions: [],
            approval,
            priority,
            firedCount: Float.toInt(firedCount),
            lastFired,
            lastResult,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(rules) => (
          {...model, automationRouter: {...ar, rules, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, automationRouter: {...ar, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | RulesLoaded(Error(err)) => (
      {...model, automationRouter: {...ar, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SaveRules => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "agent-mcp",
          "save_rules",
          "",
          result => AutomationRouter(RulesSaved(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        AutomationRouterCmd.saveRules("", result => AutomationRouter(RulesSaved(result)))
      }
      (model, cmd)
    }
  | RulesSaved(Ok(_)) => (model, Tea_Cmd.none)
  | RulesSaved(Error(err)) => (
      {...model, automationRouter: {...ar, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadFromRepo => {
      let cmd = if ar.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "agent-mcp",
          "load_from_repo",
          ".",
          result => AutomationRouter(RepoRulesLoaded(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        AutomationRouterCmd.loadFromRepo(".", result => AutomationRouter(RepoRulesLoaded(result)))
      }
      ({...model, automationRouter: {...ar, loading: true, configSource: "repo"}}, cmd)
    }
  | RepoRulesLoaded(Ok(jsonStr)) => {
      // ENSAID_CONFIG.a2ml is parsed by the backend and returned as JSON array.
      let parseApproval = (s: string): AutomationRouterModel.approvalMode =>
        switch s {
        | "require_approval" => RequireApproval
        | "approve_once" => ApproveOnce
        | "dry_run_first" => DryRunFirst
        | _ => AutoFire
        }
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let enabled =
            obj->Dict.get("enabled")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
          let approvalStr =
            obj->Dict.get("approval")->Option.flatMap(JSON.Decode.string)->Option.getOr("auto_fire")
          let approval = parseApproval(approvalStr)
          let priority =
            obj->Dict.get("priority")->Option.flatMap(JSON.Decode.string)->Option.getOr("normal")
          Some({
            AutomationRouterModel.id,
            name,
            description,
            enabled,
            trigger: Manual,
            conditions: [],
            actions: [],
            approval,
            priority,
            firedCount: 0,
            lastFired: None,
            lastResult: None,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(rules) => (
          {
            ...model,
            automationRouter: {...ar, rules, loading: false, configSource: "repo", error: None},
          },
          Tea_Cmd.none,
        )
      | None => ({...model, automationRouter: {...ar, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | RepoRulesLoaded(Error(err)) => (
      {
        ...model,
        automationRouter: {...ar, loading: false, configSource: "local", error: Some(err)},
      },
      Tea_Cmd.none,
    )
  | SetRouterFilter(text) => ({...model, automationRouter: {...ar, filterText: text}}, Tea_Cmd.none)
  | ToggleShowDisabled => (
      {...model, automationRouter: {...ar, showDisabled: !ar.showDisabled}},
      Tea_Cmd.none,
    )
  | DismissRouterError => ({...model, automationRouter: {...ar, error: None}}, Tea_Cmd.none)
  | ExportAutomationConfig => {
      let humidityStr = switch model.humidity {
      | High => "high"
      | Medium => "medium"
      | Low => "low"
      }
      let preview = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=model.provisioner.panelConfigs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=ar.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(preview)}, Tea_Cmd.none)
    }
  | ToggleAutomationBojRouting => (
      {...model, automationRouter: {...ar, bojRouting: !ar.bojRouting}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "automationrouter", json)
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
