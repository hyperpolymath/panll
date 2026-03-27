// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

let updateEnsaidConfig = (model: model, msg: ensaidConfigMsg): (model, Tea_Cmd.t<msg>) => {
  let humidityStr = switch model.humidity {
  | High => "high"
  | Medium => "medium"
  | Low => "low"
  }
  switch msg {
  | GenerateAndWrite => {
      let content = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=model.provisioner.configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      (
        {...model, ensaidConfigPreview: Some(content)},
        EnsaidConfigCmd.writeConfig(".", content, result => EnsaidConfig(ConfigWritten(result))),
      )
    }
  | PreviewConfig => {
      let content = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=model.provisioner.configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(content)}, Tea_Cmd.none)
    }
  | PreviewReady(content) => ({...model, ensaidConfigPreview: Some(content)}, Tea_Cmd.none)
  | ConfigWritten(Ok(_)) => ({...model, ensaidConfigError: None}, Tea_Cmd.none)
  | ConfigWritten(Error(err)) => ({...model, ensaidConfigError: Some(err)}, Tea_Cmd.none)
  | ReadFromRepo => (
      model,
      EnsaidConfigCmd.readConfig(".", result => EnsaidConfig(ConfigRead(result))),
    )
  | ConfigRead(Ok(content)) => (
      {...model, ensaidConfigPreview: Some(content), ensaidConfigError: None},
      Tea_Cmd.none,
    )
  | ConfigRead(Error(err)) => ({...model, ensaidConfigError: Some(err)}, Tea_Cmd.none)
  | DismissConfigError => ({...model, ensaidConfigError: None}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "ensaid-config", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => {
    UpdateHelpers.logDegradedService("TypeLL", "cross-panel type check failed")
    (model, Tea_Cmd.none)
  }
  }
}
