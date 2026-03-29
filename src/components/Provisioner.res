// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Provisioner Component — Portfolio provisioning, panel configuration,
/// and installation management.
///
/// Three modes in one panel:
///   Portfolios   — browse curated bundles, one-click install
///   Configurator — per-panel settings (endpoints, isolation tier, env vars)
///   Installed    — view what's running and at what isolation level
///   Custom       — build your own portfolio from available panels

open Model
open Msg
open Tea.Html

/// Render the category tabs.
let renderTabs = (active: provisionerCategory): Tea_Vdom.t<msg> => {
  let tabs: array<provisionerCategory> = [Portfolios, Configurator, Installed, CustomPortfolio]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-indigo-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Provisioner(SetProvCategory(tab))),
        },
        list{text(ProvisionerEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Render a portfolio card — shows name, description, panel list, and install button.
let renderPortfolioCard = (
  portfolio: portfolio,
  installStatuses: array<(string, panelInstallStatus)>,
): Tea_Vdom.t<msg> => {
  let allInstalled =
    portfolio.panels->Array.every(p =>
      ProvisionerEngine.getInstallStatus(installStatuses, p) === Installed
    )
  let installedCount =
    portfolio.panels
    ->Array.filter(p => ProvisionerEngine.getInstallStatus(installStatuses, p) === Installed)
    ->Array.length

  div(
    list{
      Attrs.class_(
        `bg-gray-900 border rounded-lg p-4 ${allInstalled
            ? "border-green-800"
            : "border-gray-700 hover:border-gray-500"}`,
      ),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-lg text-gray-200 font-medium")},
                list{text(portfolio.name)},
              ),
              if portfolio.builtIn {
                span(
                  list{
                    Attrs.class_("text-xs bg-indigo-900/50 text-indigo-400 px-1.5 py-0.5 rounded"),
                  },
                  list{text("Built-in")},
                )
              } else {
                noNode
              },
            },
          ),
          if allInstalled {
            span(list{Attrs.class_("text-xs text-green-400")}, list{text("All installed")})
          } else {
            button(
              list{
                Attrs.class_(
                  "px-3 py-1 text-xs bg-indigo-600 text-white rounded hover:bg-indigo-500 transition-colors",
                ),
                Events.onClick(Provisioner(InstallPortfolio(portfolio.id))),
              },
              list{text("Install")},
            )
          },
        },
      ),
      // Description
      div(list{Attrs.class_("text-sm text-gray-400 mb-3")}, list{text(portfolio.description)}),
      // Panel chips
      div(
        list{Attrs.class_("flex flex-wrap gap-1.5 mb-2")},
        portfolio.panels
        ->Array.map(panelName => {
          let status = ProvisionerEngine.getInstallStatus(installStatuses, panelName)
          let colour = ProvisionerEngine.installStatusColour(status)
          span(
            list{Attrs.class_(`text-xs px-2 py-0.5 rounded bg-gray-800 ${colour}`)},
            list{text(panelName)},
          )
        })
        ->List.fromArray,
      ),
      // Footer
      div(
        list{Attrs.class_("flex items-center justify-between text-xs text-gray-600")},
        list{
          span(
            list{},
            list{
              text(
                `${Int.toString(installedCount)}/${Int.toString(
                    Array.length(portfolio.panels),
                  )} panels`,
              ),
            },
          ),
          span(list{}, list{text(portfolio.audience)}),
        },
      ),
    },
  )
}

/// Render a panel config row in the Configurator tab.
let renderConfigRow = (config: panelConfig): Tea_Vdom.t<msg> => {
  let tierColour = ProvisionerEngine.isolationColour(config.isolation)

  div(
    list{
      Attrs.class_("flex items-center gap-3 px-3 py-2 bg-gray-900 border border-gray-800 rounded"),
    },
    list{
      // Panel name
      span(
        list{Attrs.class_("text-sm text-gray-200 w-28 font-medium")},
        list{text(config.panelName)},
      ),
      // Isolation tier
      span(
        list{Attrs.class_(`text-xs ${tierColour} w-20`)},
        list{text(ProvisionerEngine.isolationShortLabel(config.isolation))},
      ),
      // Endpoint
      span(
        list{Attrs.class_("text-xs text-gray-500 flex-1 truncate")},
        list{text(config.endpoint === "" ? "No endpoint" : config.endpoint)},
      ),
      // Auto-connect indicator
      span(
        list{Attrs.class_(`text-xs ${config.autoConnect ? "text-green-400" : "text-gray-600"}`)},
        list{text(config.autoConnect ? "Auto" : "Manual")},
      ),
      // Enabled toggle
      button(
        list{
          Attrs.class_(
            `px-2 py-0.5 text-xs rounded ${config.enabled
                ? "bg-green-900/50 text-green-400"
                : "bg-gray-800 text-gray-600"}`,
          ),
          Events.onClick(Provisioner(TogglePanelEnabled(config.panelName))),
        },
        list{text(config.enabled ? "On" : "Off")},
      ),
      // Isolation tier selector buttons
      div(
        list{Attrs.class_("flex gap-1")},
        list{
          button(
            list{
              Attrs.class_(
                `px-1.5 py-0.5 text-xs rounded ${config.isolation === Native
                    ? "bg-green-900 text-green-400"
                    : "bg-gray-800 text-gray-500"}`,
              ),
              Events.onClick(Provisioner(SetPanelIsolation(config.panelName, Native))),
            },
            list{text("N")},
          ),
          button(
            list{
              Attrs.class_(
                `px-1.5 py-0.5 text-xs rounded ${config.isolation === StandardPod
                    ? "bg-blue-900 text-blue-400"
                    : "bg-gray-800 text-gray-500"}`,
              ),
              Events.onClick(Provisioner(SetPanelIsolation(config.panelName, StandardPod))),
            },
            list{text("S")},
          ),
          button(
            list{
              Attrs.class_(
                `px-1.5 py-0.5 text-xs rounded ${config.isolation === HardenedPod
                    ? "bg-purple-900 text-purple-400"
                    : "bg-gray-800 text-gray-500"}`,
              ),
              Events.onClick(Provisioner(SetPanelIsolation(config.panelName, HardenedPod))),
            },
            list{text("H")},
          ),
        },
      ),
    },
  )
}

/// Render the isolation tier summary bar.
let renderIsolationSummary = (configs: array<panelConfig>): Tea_Vdom.t<msg> => {
  let native = ProvisionerEngine.countByIsolation(configs, Native)
  let standard = ProvisionerEngine.countByIsolation(configs, StandardPod)
  let hardened = ProvisionerEngine.countByIsolation(configs, HardenedPod)
  div(
    list{Attrs.class_("flex gap-4 px-3 py-2 bg-gray-900/60 border border-gray-800 rounded mb-3")},
    list{
      span(
        list{Attrs.class_("text-xs text-green-400")},
        list{text(`Native: ${Int.toString(native)}`)},
      ),
      span(
        list{Attrs.class_("text-xs text-blue-400")},
        list{text(`Standard Pod: ${Int.toString(standard)}`)},
      ),
      span(
        list{Attrs.class_("text-xs text-purple-400")},
        list{text(`Hardened Pod: ${Int.toString(hardened)}`)},
      ),
      span(
        list{Attrs.class_("text-xs text-gray-500 ml-auto")},
        list{text(`${Int.toString(native + standard + hardened)} total`)},
      ),
    },
  )
}

/// Main provisioner view.
let view = (prov: provisionerState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Panel Provisioner — portfolios, configuration, and installation"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-medium text-gray-200")},
                list{text("Provisioner")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    `${Int.toString(
                        ProvisionerEngine.countInstalled(prov.installStatus),
                      )} panels installed`,
                  ),
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"),
              Events.onClick(PanelSwitcher(ClosePanels)),
              KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          renderTabs(prov.activeCategory),
          switch prov.activeCategory {
          | Portfolios => {
              let filtered = ProvisionerEngine.filterPortfolios(prov.portfolios, prov.filterText)
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  // Search
                  input(
                    list{
                      Attrs.class_(
                        "w-full bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 mb-4",
                      ),
                      Attrs.placeholder("Search portfolios..."),
                      Attrs.ariaLabel("Search portfolios"),
                      Attrs.value(prov.filterText),
                      Events.onInput(v => Provisioner(SetProvFilter(v))),
                    },
                    list{},
                  ),
                  div(
                    list{Attrs.class_("grid gap-4 grid-cols-1 lg:grid-cols-2")},
                    filtered
                    ->Array.map(p => renderPortfolioCard(p, prov.installStatus))
                    ->List.fromArray,
                  ),
                },
              )
            }
          | Configurator =>
            div(
              list{Attrs.class_("space-y-2")},
              list{
                renderIsolationSummary(prov.configs),
                // Column headers
                div(
                  list{Attrs.class_("flex items-center gap-3 px-3 py-1 text-xs text-gray-600")},
                  list{
                    span(list{Attrs.class_("w-28")}, list{text("Panel")}),
                    span(list{Attrs.class_("w-20")}, list{text("Tier")}),
                    span(list{Attrs.class_("flex-1")}, list{text("Endpoint")}),
                    span(list{}, list{text("Connect")}),
                    span(list{}, list{text("Status")}),
                    span(list{}, list{text("Isolation")}),
                  },
                ),
                div(
                  list{Attrs.class_("space-y-1")},
                  prov.configs->Array.map(c => renderConfigRow(c))->List.fromArray,
                ),
              },
            )
          | Installed => {
              let installed = prov.installStatus->Array.filter(((_, s)) => s === Installed)
              div(
                list{Attrs.class_("space-y-2")},
                list{
                  renderIsolationSummary(prov.configs),
                  div(
                    list{Attrs.class_("space-y-1")},
                    installed
                    ->Array.map(((name, _status)) => {
                      let config = prov.configs->Array.find(c => c.panelName === name)
                      let tierColour = switch config {
                      | Some(c) => ProvisionerEngine.isolationColour(c.isolation)
                      | None => "text-gray-500"
                      }
                      let tierLabel = switch config {
                      | Some(c) => ProvisionerEngine.isolationLabel(c.isolation)
                      | None => "Unknown"
                      }
                      div(
                        list{
                          Attrs.class_(
                            "flex items-center gap-3 px-3 py-2 bg-gray-900 border border-gray-800 rounded",
                          ),
                        },
                        list{
                          span(
                            list{Attrs.class_("text-sm text-gray-200 w-28 font-medium")},
                            list{text(name)},
                          ),
                          span(list{Attrs.class_(`text-xs ${tierColour}`)}, list{text(tierLabel)}),
                          span(
                            list{Attrs.class_("text-xs text-green-400 ml-auto")},
                            list{text("Running")},
                          ),
                          button(
                            list{
                              Attrs.class_(
                                "px-2 py-0.5 text-xs bg-red-900/50 text-red-400 rounded hover:bg-red-900",
                              ),
                              Events.onClick(Provisioner(RemovePanel(name))),
                            },
                            list{text("Remove")},
                          ),
                        },
                      )
                    })
                    ->List.fromArray,
                  ),
                },
              )
            }
          | CustomPortfolio =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-400 mb-2")},
                  list{text("Build a custom portfolio by selecting panels:")},
                ),
                input(
                  list{
                    Attrs.class_(
                      "w-full bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200",
                    ),
                    Attrs.placeholder("Portfolio name..."),
                    Attrs.ariaLabel("Custom portfolio name"),
                    Attrs.value(prov.customName),
                    Events.onInput(v => Provisioner(SetCustomName(v))),
                  },
                  list{},
                ),
                // Available panels as toggleable chips
                div(
                  list{Attrs.class_("flex flex-wrap gap-2 mt-3")},
                  prov.configs
                  ->Array.map(c => {
                    let selected = prov.customPanels->Array.some(p => p === c.panelName)
                    button(
                      list{
                        Attrs.class_(
                          `px-3 py-1.5 text-sm rounded transition-colors ${selected
                              ? "bg-indigo-600 text-white"
                              : "bg-gray-800 text-gray-400 hover:bg-gray-700"}`,
                        ),
                        Events.onClick(Provisioner(ToggleCustomPanel(c.panelName))),
                      },
                      list{text(c.panelName)},
                    )
                  })
                  ->List.fromArray,
                ),
                if Array.length(prov.customPanels) > 0 {
                  div(
                    list{Attrs.class_("mt-4")},
                    list{
                      button(
                        list{
                          Attrs.class_(
                            "px-4 py-2 text-sm bg-indigo-600 text-white rounded hover:bg-indigo-500",
                          ),
                          Events.onClick(Provisioner(SaveCustomPortfolio)),
                          KeyboardNav.onActivate(Provisioner(SaveCustomPortfolio)),
                        },
                        list{
                          text(
                            `Save Portfolio (${Int.toString(
                                Array.length(prov.customPanels),
                              )} panels)`,
                          ),
                        },
                      ),
                    },
                  )
                } else {
                  noNode
                },
              },
            )
          },
          // Error display
          switch prov.error {
          | Some(e) =>
            div(
              list{
                Attrs.class_(
                  "mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300",
                ),
                Attrs.role("alert"),
              },
              list{text(e)},
            )
          | None => noNode
          },
        },
      ),
    },
  )
}
