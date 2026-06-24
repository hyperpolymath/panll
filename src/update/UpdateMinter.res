// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

/// STATE TRANSITION: Panel Minter (panel creation wizard)
///
/// Handles all minterMsg variants: form field updates, wizard navigation,
/// minting execution, and result handling. Most messages are pure state
/// updates; ExecuteMint dispatches a Gossamer command via MinterCmd.
let updateMinter = (model: model, msg: minterMsg): (model, Tea_Cmd.t<msg>) => {
  let minter = model.minter
  let form = minter.form
  switch msg {
  | SetPanelName(name) => {
      let validation = MinterEngine.validateName(name)
      (
        {
          ...model,
          minter: {
            ...minter,
            form: {...form, panelName: name, nameValidation: validation},
          },
        },
        Tea_Cmd.none,
      )
    }
  | SetShortName(v) => (
      {...model, minter: {...minter, form: {...form, shortName: v}}},
      Tea_Cmd.none,
    )
  | SetDescription(v) => (
      {...model, minter: {...minter, form: {...form, description: v}}},
      Tea_Cmd.none,
    )
  | SetIcon(v) => ({...model, minter: {...minter, form: {...form, icon: v}}}, Tea_Cmd.none)
  | SetBackendKind(kind) => (
      {...model, minter: {...minter, form: {...form, backendKind: kind}}},
      Tea_Cmd.none,
    )
  | SetAccessibility(level) => (
      {...model, minter: {...minter, form: {...form, accessibility: level}}},
      Tea_Cmd.none,
    )
  | SetEndpoint(v) => ({...model, minter: {...minter, form: {...form, endpoint: v}}}, Tea_Cmd.none)
  | AddCapability => {
      let newCap: minterCapability = {id: "", label: ""}
      (
        {
          ...model,
          minter: {
            ...minter,
            form: {
              ...form,
              capabilities: Array.concat(form.capabilities, [newCap]),
            },
          },
        },
        Tea_Cmd.none,
      )
    }
  | RemoveCapability(idx) => {
      let caps = form.capabilities->Array.filterWithIndex((_c, i) => i !== idx)
      (
        {
          ...model,
          minter: {...minter, form: {...form, capabilities: caps}},
        },
        Tea_Cmd.none,
      )
    }
  | NextStep => {
      let next = minter.wizardStep + 1
      let clamped = next > 3 ? 3 : next
      ({...model, minter: {...minter, wizardStep: clamped}}, Tea_Cmd.none)
    }
  | PrevStep => {
      let prev = minter.wizardStep - 1
      let clamped = prev < 0 ? 0 : prev
      ({...model, minter: {...minter, wizardStep: clamped}}, Tea_Cmd.none)
    }
  | ExecuteMint => {
      let capsJson =
        form.capabilities
        ->Array.map(c => `{"id":"${c.id}","label":"${c.label}"}`)
        ->Array.join(",")
      let capsStr = `[${capsJson}]`
      let specJson = `{"panel":"${form.panelName}","backend":"${MinterEngine.backendKindLabel(
          form.backendKind,
        )}","caps":${capsStr}}`
      (
        {...model, minter: {...minter, minting: true, error: None}},
        Tea_Cmd.batch(list{
          MinterCmd.mintPanel(
            form.panelName,
            form.shortName,
            form.description,
            form.icon,
            MinterEngine.backendKindLabel(form.backendKind),
            MinterEngine.accessibilityLabel(form.accessibility),
            capsStr,
            form.endpoint,
            result => Minter(MintResult(result)),
          ),
          TypeLLService.checkConfigTypes(specJson, "minter", result => Minter(
            TypeCheckResult(result),
          )),
        }),
      )
    }
  | MintResult(result) => {
      let summary = MinterEngine.fileSummary(form)
      let allPaths = summary->Array.map(((path, _desc)) => path)
      // First entries are created files, last 6 are patches to existing files.
      let numPatches = 6
      let numCreated = Array.length(allPaths) - numPatches
      let created = allPaths->Array.slice(~start=0, ~end=numCreated)
      let patched = allPaths->Array.slice(~start=numCreated, ~end=Array.length(allPaths))
      switch result {
      | Ok(_jsonStr) => (
          {
            ...model,
            minter: {
              ...minter,
              minting: false,
              error: None,
              lastResult: Some({
                success: true,
                filesCreated: created,
                filesPatched: patched,
                warnings: [],
                error: None,
              }),
            },
          },
          Tea_Cmd.none,
        )
      | Error(e) => (
          {
            ...model,
            minter: {
              ...minter,
              minting: false,
              error: Some(e),
              lastResult: Some({
                success: false,
                filesCreated: [],
                filesPatched: [],
                warnings: [],
                error: Some(e),
              }),
            },
          },
          Tea_Cmd.none,
        )
      }
    }
  | ResetMinter => ({...model, minter: MinterEngine.defaultState}, Tea_Cmd.none)
  | ExportToEnsaidConfig => {
      // Generate a preview showing what the minted panel would add to ENSAID_CONFIG.
      let form = model.minter.form
      let humidityStr = switch model.humidity {
      | High => "high"
      | Medium => "medium"
      | Low => "low"
      }
      let newPanelConfig: ProvisionerModel.panelConfig = {
        panelName: form.panelName,
        endpoint: form.endpoint,
        autoConnect: true,
        isolation: ProvisionerModel.Native,
        envVars: [],
        enabled: true,
      }
      let configs = Array.concat(model.provisioner.panelConfigs, [newPanelConfig])
      let preview = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=configs,
        ~portfolios=model.provisioner.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(preview)}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "minter", json)
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
