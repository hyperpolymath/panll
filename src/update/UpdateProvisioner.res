// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// STATE TRANSITION: Provisioner (portfolio bundling, config, installation)
///
/// Handles portfolio installation, per-panel config changes, isolation tier
/// selection, custom portfolio creation, and panel enable/disable toggling.
let updateProvisioner = (model: model, msg: provisionerMsg): (model, Tea_Cmd.t<msg>) => {
  let prov = model.provisioner
  switch msg {
  | SetProvCategory(cat) => ({...model, provisioner: {...prov, activeCategory: cat}}, Tea_Cmd.none)
  | SetProvFilter(text) => ({...model, provisioner: {...prov, filterText: text}}, Tea_Cmd.none)
  | InstallPortfolio(portfolioId) => {
      // Find the portfolio and install all its panels.
      let portfolio = prov.portfolios->Array.find(p => p.id === portfolioId)
      switch portfolio {
      | Some(p) => {
          // Mark all panels as Installing.
          let newStatuses = prov.panelInstallStatus->Array.map(((name, status)) =>
            if p.panels->Array.some(pn => pn === name) {
              (name, (Installing: panelInstallStatus))
            } else {
              (name, status)
            }
          )
          (
            {
              ...model,
              provisioner: {
                ...prov,
                panelInstallStatus: newStatuses,
                installProgress: Some({
                  portfolioId,
                  totalPanels: Array.length(p.panels),
                  installedPanels: 0,
                  failedPanels: 0,
                  currentPanel: p.panels->Array.get(0),
                }),
              },
            },
            // For now, immediately mark as installed (native panels are built-in).
            // Container installation will be async via ProvisionerCmd.
            TypeLLService.checkConfigTypes(portfolioId, "provisioner", result => Provisioner(
              TypeCheckResult(result),
            )),
          )
        }
      | None => (model, Tea_Cmd.none)
      }
    }
  | InstallPanel(panelName) => {
      let newStatuses = prov.panelInstallStatus->Array.map(((name, status)) =>
        if name === panelName {
          (name, (Installing: panelInstallStatus))
        } else {
          (name, status)
        }
      )
      let config = prov.panelConfigs->Array.find(c => c.panelName === panelName)
      let isoLabel = switch config {
      | Some(c) => ProvisionerEngine.isolationShortLabel(c.isolation)
      | None => "Native"
      }
      (
        {...model, provisioner: {...prov, panelInstallStatus: newStatuses}},
        ProvisionerCmd.installPanel(panelName, isoLabel, result => Provisioner(
          InstallResult(panelName, result),
        )),
      )
    }
  | RemovePanel(panelName) => {
      let newStatuses = prov.panelInstallStatus->Array.map(((name, status)) =>
        if name === panelName {
          (name, (Removing: panelInstallStatus))
        } else {
          (name, status)
        }
      )
      (
        {...model, provisioner: {...prov, panelInstallStatus: newStatuses}},
        ProvisionerCmd.removePanel(panelName, result => Provisioner(
          RemoveResult(panelName, result),
        )),
      )
    }
  | InstallResult(panelName, result) => {
      let newStatus = switch result {
      | Ok(_) => (Installed: panelInstallStatus)
      | Error(e) => (InstallFailed(e): panelInstallStatus)
      }
      let newStatuses = prov.panelInstallStatus->Array.map(((name, status)) =>
        if name === panelName {
          (name, newStatus)
        } else {
          (name, status)
        }
      )
      ({...model, provisioner: {...prov, panelInstallStatus: newStatuses}}, Tea_Cmd.none)
    }
  | RemoveResult(panelName, result) => {
      let newStatus = switch result {
      | Ok(_) => (NotInstalled: panelInstallStatus)
      | Error(e) => (InstallFailed(e): panelInstallStatus)
      }
      let newStatuses = prov.panelInstallStatus->Array.map(((name, status)) =>
        if name === panelName {
          (name, newStatus)
        } else {
          (name, status)
        }
      )
      ({...model, provisioner: {...prov, panelInstallStatus: newStatuses}}, Tea_Cmd.none)
    }
  | TogglePanelEnabled(panelName) => {
      let newConfigs = prov.panelConfigs->Array.map(c =>
        if c.panelName === panelName {
          {...c, enabled: !c.enabled}
        } else {
          c
        }
      )
      ({...model, provisioner: {...prov, panelConfigs: newConfigs}}, Tea_Cmd.none)
    }
  | SetPanelIsolation(panelName, tier) => {
      let newConfigs = prov.panelConfigs->Array.map(c =>
        if c.panelName === panelName {
          {...c, isolation: tier}
        } else {
          c
        }
      )
      ({...model, provisioner: {...prov, panelConfigs: newConfigs}}, Tea_Cmd.none)
    }
  | SetCustomName(name) =>({...model, provisioner: {...prov, customName: name}}, Tea_Cmd.none)
  | ToggleCustomPanel(panelName) => {
      let exists = prov.customPanels->Array.some(p => p === panelName)
      let newPanels = if exists {
        prov.customPanels->Array.filter(p => p !== panelName)
      } else {
        Array.concat(prov.customPanels, [panelName])
      }
      ({...model, provisioner: {...prov, customPanels: newPanels}}, Tea_Cmd.none)
    }
  | SaveCustomPortfolio => if prov.customName === "" || Array.length(prov.customPanels) === 0 {
      (
        {
          ...model,
          provisioner: {...prov, error: Some("Portfolio needs a name and at least one panel")},
        },
        Tea_Cmd.none,
      )
    } else {
      let newPortfolio: portfolio = {
        id: String.toLowerCase(prov.customName)->String.replaceAll(" ", "-"),
        name: prov.customName,
        description: `Custom portfolio with ${Int.toString(
            Array.length(prov.customPanels),
          )} panels`,
        panels: prov.customPanels,
        defaultIsolation: Native,
        builtIn: false,
        icon: "folder",
        audience: "Custom",
      }
      (
        {
          ...model,
          provisioner: {
            ...prov,
            portfolios: Array.concat(prov.portfolios, [newPortfolio]),
            customName: "",
            customPanels: [],
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    }
  | ExportProvisionerConfig => {
      let humidityStr = switch model.humidity {
      | High => "high"
      | Medium => "medium"
      | Low => "low"
      }
      let preview = EnsaidConfigEngine.generate(
        ~repoName="(current repo)",
        ~workspace=model.workspace,
        ~humidity=humidityStr,
        ~panelConfigs=prov.panelConfigs,
        ~portfolios=prov.portfolios,
        ~automationRules=model.automationRouter.rules,
        (),
      )
      ({...model, ensaidConfigPreview: Some(preview)}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "provisioner", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  | SaveCustomPluginBundle
  | TogglePlugin(_, _)
  | InstallPluginBundle(_)
  | InstallPlugin(_)
  | RemovePlugin(_)
  | PluginInstallResult(_, _)
  | PluginRemoveResult(_, _)
  | SetCustomPluginBundleName(_)
  | ToggleCustomPluginBundle(_)
  | CreateDeploymentBundle(_) =>
    // Plugin bundle variants — not yet implemented
    (model, Tea_Cmd.none)
  }
}
