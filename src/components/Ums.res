// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Universal Modding Studio Component — view for the unified hub
/// orchestrating IDApTIK game content creation. Project browser, ABI
/// validator, template gallery, asset pipeline, distribution manager,
/// and modding API reference.

open Model
open Msg
open Tea.Html

/// Render a category tab button for the UMS panel.
let renderTab = (label: string, cat: umsCategory, active: umsCategory): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(list{Attrs.class_(cls), Events.onClick(Ums(SetUmsCategory(cat)))}, list{text(label)})
}

/// Render a project card with name, stats, and validation badge.
let renderProjectCard = (project: modProject, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderCls = if isSelected {
    "border-cyan-400"
  } else {
    "border-gray-700"
  }
  let validBadge = if project.validated {
    "text-emerald-400"
  } else {
    "text-gray-500"
  }
  div(
    list{
      Attrs.class_(
        `p-3 bg-gray-800 rounded border ${borderCls} cursor-pointer hover:border-gray-500`,
      ),
      Events.onClick(Ums(SelectProject(project.id))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-100")}, list{text(project.name)}),
          span(
            list{Attrs.class_(`text-xs ${validBadge}`)},
            list{
              text(
                if project.validated {
                  "Validated"
                } else {
                  "Unvalidated"
                },
              ),
            },
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-400 mb-2 line-clamp-2")},
        list{text(project.description)},
      ),
      div(
        list{Attrs.class_("flex items-center gap-3 text-xs")},
        list{
          span(list{Attrs.class_("text-gray-500")}, list{text(`v${project.version}`)}),
          span(
            list{Attrs.class_("text-gray-500")},
            list{text(`${Int.toString(project.levelCount)} levels`)},
          ),
          span(
            list{Attrs.class_("text-gray-500")},
            list{text(`${Int.toString(project.puzzleCount)} puzzles`)},
          ),
          span(
            list{Attrs.class_("text-gray-500")},
            list{text(`${Int.toString(project.assetCount)} assets`)},
          ),
        },
      ),
    },
  )
}

/// Render the projects list view with filter, stats, and project grid.
let renderProjects = (state: umsState): Tea_Vdom.t<msg> => {
  let filtered = UmsEngine.filterProjects(state.projects, state.filterText)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Filter bar
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 bg-gray-800 border border-gray-700 rounded text-sm text-gray-200 placeholder-gray-500",
              ),
              Attrs.placeholder("Filter projects..."),
              Attrs.value(state.filterText),
              Events.onInput(text => Ums(SetUmsFilter(text))),
            },
            list{},
          ),
        },
      ),
      // Stats
      div(
        list{Attrs.class_("flex items-center gap-4 text-xs text-gray-400")},
        list{
          span(list{}, list{text(`${Int.toString(Array.length(filtered))} projects`)}),
          span(
            list{},
            list{
              text(`${Int.toString(UmsEngine.validatedProjectCount(state.projects))} validated`),
            },
          ),
        },
      ),
      // Project cards
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{
            text("No projects found. "),
            button(
              list{
                Attrs.class_("text-cyan-400 hover:text-cyan-300 underline cursor-pointer"),
                Events.onClick(Ums(CreateProject(""))),
              },
              list{text("Create a new project")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-3")},
          filtered
          ->Array.map(p => renderProjectCard(p, state.selectedProjectId === Some(p.id)))
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render a single ABI validation result row.
let renderValidationRow = (result: abiValidationResult): Tea_Vdom.t<msg> => {
  let statusCls = UmsEngine.validationStatusColour(result)
  let proofItem = (label: string, passed: bool) => {
    let cls = if passed {
      "text-emerald-400"
    } else {
      "text-red-400"
    }
    span(list{Attrs.class_(`text-xs ${cls}`)}, list{text(label)})
  }
  div(
    list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200")}, list{text(`Level: ${result.levelId}`)}),
          span(
            list{Attrs.class_(`text-xs ${statusCls}`)},
            list{text(UmsEngine.validationStatusLabel(result))},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex flex-wrap gap-3")},
        list{
          proofItem("Guards-in-Zones", result.guardsInZones),
          proofItem("Defence-Targets", result.defenceTargetsValid),
          proofItem("Zones-Ordered", result.zonesOrdered),
          proofItem("PBX-Consistent", result.pbxConsistent),
          proofItem("Devices-Exist", result.devicesExist),
        },
      ),
      if Array.length(result.errors) > 0 {
        div(
          list{Attrs.class_("mt-2 space-y-1")},
          result.errors
          ->Array.map(err => div(list{Attrs.class_("text-xs text-red-300")}, list{text(err)}))
          ->List.fromArray,
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the ABI validator view with results and "Validate All" button.
let renderAbiValidator = (state: umsState): Tea_Vdom.t<msg> => {
  let passedCount = state.validationResults->Array.filter(r => r.allPassed)->Array.length
  let totalCount = Array.length(state.validationResults)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
              ),
              Events.onClick(Ums(ValidateAll)),
            },
            list{text("Validate All Levels")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{
              text(
                `${Int.toString(passedCount)}/${Int.toString(totalCount)} levels pass all proofs`,
              ),
            },
          ),
        },
      ),
      // Validation results
      if totalCount === 0 {
        div(
          list{
            Attrs.class_(
              "text-center text-gray-500 text-sm py-8 border border-dashed border-gray-700 rounded",
            ),
          },
          list{text("No validation results — click 'Validate All Levels' to run ABI proofs")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          state.validationResults
          ->Array.map(renderValidationRow)
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render a template card in the template gallery.
let renderTemplateCard = (tmpl: modTemplate): Tea_Vdom.t<msg> => {
  let catCls = UmsEngine.templateCategoryColour(tmpl.category)
  div(
    list{
      Attrs.class_(
        "p-3 bg-gray-800 rounded border border-gray-700 hover:border-gray-500 cursor-pointer",
      ),
      Events.onClick(Ums(InstantiateTemplate(tmpl.id))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-100")}, list{text(tmpl.name)}),
          span(
            list{Attrs.class_(`text-xs ${catCls}`)},
            list{text(UmsEngine.templateCategoryLabel(tmpl.category))},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-400 mb-2 line-clamp-2")},
        list{text(tmpl.description)},
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500")},
        list{text(`Difficulty: ${tmpl.difficulty}`)},
      ),
    },
  )
}

/// Render the templates browser with category filter.
let renderTemplates = (state: umsState): Tea_Vdom.t<msg> => {
  let filtered = UmsEngine.filterTemplates(state.templates, state.filterText)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Filter bar
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 bg-gray-800 border border-gray-700 rounded text-sm text-gray-200 placeholder-gray-500",
              ),
              Attrs.placeholder("Filter templates..."),
              Attrs.value(state.filterText),
              Events.onInput(text => Ums(SetUmsFilter(text))),
            },
            list{},
          ),
        },
      ),
      // Stats
      div(
        list{Attrs.class_("text-xs text-gray-400")},
        list{text(`${Int.toString(Array.length(filtered))} templates available`)},
      ),
      // Template cards
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{
            text("No templates found. "),
            button(
              list{
                Attrs.class_("text-cyan-400 hover:text-cyan-300 underline cursor-pointer"),
                Events.onClick(Ums(LoadTemplates)),
              },
              list{text("Load templates")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-3")},
          filtered->Array.map(renderTemplateCard)->List.fromArray,
        )
      },
    },
  )
}

/// Render the asset grid with type filter and size stats.
let renderAssets = (state: umsState): Tea_Vdom.t<msg> => {
  let filtered = UmsEngine.filterAssets(state.assets, state.filterText)
  let totalSize = filtered->Array.reduce(0, (acc, a) => acc + a.sizeBytes)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Filter bar and import button
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 bg-gray-800 border border-gray-700 rounded text-sm text-gray-200 placeholder-gray-500",
              ),
              Attrs.placeholder("Filter assets..."),
              Attrs.value(state.filterText),
              Events.onInput(text => Ums(SetUmsFilter(text))),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
              ),
              Events.onClick(Ums(ImportAsset(""))),
            },
            list{text("Import Asset")},
          ),
        },
      ),
      // Stats with type counts
      div(
        list{Attrs.class_("flex items-center gap-4 text-xs text-gray-400")},
        list{
          span(list{}, list{text(`${Int.toString(Array.length(filtered))} assets`)}),
          span(list{}, list{text(`${Int.toString(totalSize / 1024)}KB total`)}),
          ...UmsEngine.allAssetTypes
          ->Array.map(at => {
            let count = UmsEngine.countByAssetType(state.assets, at)
            if count > 0 {
              span(
                list{Attrs.class_(UmsEngine.assetTypeColour(at))},
                list{text(`${Int.toString(count)} ${UmsEngine.assetTypeLabel(at)}`)},
              )
            } else {
              noNode
            }
          })
          ->List.fromArray,
        },
      ),
      // Asset grid
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{
            text("No assets loaded. "),
            button(
              list{
                Attrs.class_("text-cyan-400 hover:text-cyan-300 underline cursor-pointer"),
                Events.onClick(Ums(LoadAssets)),
              },
              list{text("Load assets")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("grid grid-cols-3 lg:grid-cols-4 gap-2")},
          filtered
          ->Array.map(asset => {
            let typeCls = UmsEngine.assetTypeColour(asset.assetType)
            div(
              list{Attrs.class_("p-2 bg-gray-800 rounded border border-gray-700")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-100 font-medium truncate")},
                  list{text(asset.name)},
                ),
                div(
                  list{Attrs.class_(`text-xs ${typeCls}`)},
                  list{text(UmsEngine.assetTypeLabel(asset.assetType))},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{text(`${Int.toString(asset.sizeBytes / 1024)}KB`)},
                ),
                if Array.length(asset.usedIn) > 0 {
                  div(
                    list{Attrs.class_("text-xs text-gray-500 mt-1")},
                    list{text(`Used in ${Int.toString(Array.length(asset.usedIn))} places`)},
                  )
                } else {
                  noNode
                },
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render a distribution target row.
let renderDistributionTarget = (target: distributionTarget): Tea_Vdom.t<msg> => {
  let platCls = UmsEngine.platformColour(target.platform)
  div(
    list{Attrs.class_("flex items-center gap-3 p-3 bg-gray-800 rounded border border-gray-700")},
    list{
      span(
        list{Attrs.class_(`text-sm font-medium ${platCls}`)},
        list{text(UmsEngine.platformLabel(target.platform))},
      ),
      span(list{Attrs.class_("text-xs text-gray-400 flex-1 truncate")}, list{text(target.url)}),
      span(list{Attrs.class_("text-xs text-gray-500")}, list{text(`v${target.version}`)}),
      if target.lastPublished !== "" {
        span(list{Attrs.class_("text-xs text-gray-600")}, list{text(target.lastPublished)})
      } else {
        span(list{Attrs.class_("text-xs text-gray-600")}, list{text("Never published")})
      },
      button(
        list{
          Attrs.class_(
            "px-2 py-1 text-xs bg-purple-700 text-white rounded hover:bg-purple-600 cursor-pointer",
          ),
          Events.onClick(Ums(PublishMod)),
        },
        list{text("Publish")},
      ),
    },
  )
}

/// Render the distribution view with publish targets and version.
let renderDistribution = (state: umsState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Header with selected project info
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200")}, list{text("Distribution Targets")}),
          switch state.selectedProjectId {
          | Some(id) =>
            span(list{Attrs.class_("text-xs text-gray-500")}, list{text(`Project: ${id}`)})
          | None =>
            span(list{Attrs.class_("text-xs text-gray-500")}, list{text("No project selected")})
          },
        },
      ),
      // Targets
      if Array.length(state.distributionTargets) === 0 {
        div(
          list{
            Attrs.class_(
              "text-center text-gray-500 text-sm py-8 border border-dashed border-gray-700 rounded",
            ),
          },
          list{text("No distribution targets configured")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          state.distributionTargets->Array.map(renderDistributionTarget)->List.fromArray,
        )
      },
    },
  )
}

/// Render the searchable API reference documentation.
let renderApiReference = (state: umsState): Tea_Vdom.t<msg> => {
  let filtered = if state.filterText === "" {
    state.apiEntries
  } else {
    let lower = String.toLowerCase(state.filterText)
    state.apiEntries->Array.filter(e =>
      String.includes(String.toLowerCase(e.name), lower) ||
      String.includes(String.toLowerCase(e.description), lower) ||
      String.includes(String.toLowerCase(e.category), lower)
    )
  }
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Search bar
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 bg-gray-800 border border-gray-700 rounded text-sm text-gray-200 placeholder-gray-500",
              ),
              Attrs.placeholder("Search API reference..."),
              Attrs.value(state.filterText),
              Events.onInput(text => Ums(SetUmsFilter(text))),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
              ),
              Events.onClick(Ums(LoadApiReference)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      // Stats
      div(
        list{Attrs.class_("text-xs text-gray-400")},
        list{text(`${Int.toString(Array.length(filtered))} API entries`)},
      ),
      // API entries
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{
            text("No API entries found. "),
            button(
              list{
                Attrs.class_("text-cyan-400 hover:text-cyan-300 underline cursor-pointer"),
                Events.onClick(Ums(LoadApiReference)),
              },
              list{text("Load API reference")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          filtered
          ->Array.map(entry =>
            div(
              list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
              list{
                div(
                  list{Attrs.class_("flex items-center justify-between mb-1")},
                  list{
                    span(
                      list{Attrs.class_("text-sm font-medium text-cyan-400 font-mono")},
                      list{text(entry.name)},
                    ),
                    span(list{Attrs.class_("text-xs text-gray-500")}, list{text(entry.category)}),
                  },
                ),
                div(
                  list{Attrs.class_("text-xs text-amber-400 font-mono mb-1")},
                  list{text(entry.signature)},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-400 mb-2")},
                  list{text(entry.description)},
                ),
                if entry.example !== "" {
                  div(
                    list{Attrs.class_("p-2 bg-gray-900 rounded text-xs text-gray-300 font-mono")},
                    list{text(entry.example)},
                  )
                } else {
                  noNode
                },
                div(
                  list{Attrs.class_("text-xs text-gray-600 mt-1")},
                  list{text(`Since: ${entry.since}`)},
                ),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Main view function for the Universal Modding Studio panel.
/// Render a Level Architect summary card showing entity count and validation status.
let renderLevelArchitectSummary = (la: levelArchitectState): Tea_Vdom.t<msg> => {
  let entityCount = Array.length(la.entities)
  let validationBadge = switch la.umsValidation {
  | Some(v) if v.allPassed =>
    span(list{Attrs.class_("text-xs text-emerald-400")}, list{text("ABI: ALL PASSED")})
  | Some(_) => span(list{Attrs.class_("text-xs text-red-400")}, list{text("ABI: HAS FAILURES")})
  | None => span(list{Attrs.class_("text-xs text-gray-500")}, list{text("ABI: Not validated")})
  }
  div(
    list{Attrs.class_("p-3 bg-gray-800/50 rounded border border-gray-700/50")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(
            list{Attrs.class_("text-xs font-medium text-gray-300")},
            list{text("Level Architect")},
          ),
          button(
            list{
              Attrs.class_("text-xs text-cyan-400 hover:text-cyan-300 cursor-pointer"),
              Events.onClick(Ums(NavigateToPanel(PanelLevelArchitect))),
            },
            list{text("Open")},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-3 text-xs")},
        list{
          span(
            list{Attrs.class_("text-gray-400")},
            list{text(`${Int.toString(entityCount)} entities`)},
          ),
          span(list{Attrs.class_("text-gray-400")}, list{text(`${la.levelName}`)}),
          validationBadge,
        },
      ),
    },
  )
}

/// Main view function for the Universal Modding Studio panel.
/// Accepts both UMS state and Level Architect state for cross-panel data display.
let view = (state: umsState, ~levelArchitect: levelArchitectState): Tea_Vdom.t<msg> => {
  /// Selected project name for the header subtitle.
  let projectName = switch state.selectedProjectId {
  | Some(id) =>
    state.projects
    ->Array.find(p => p.id === id)
    ->Option.map(p => p.name)
    ->Option.getOr("Unknown Project")
  | None => "No Project Selected"
  }
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Universal Modding Studio panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-lg font-semibold text-gray-100")},
                list{text("Universal Modding Studio")},
              ),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text(projectName)}),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
                  ),
                  Events.onClick(Ums(CreateProject(""))),
                },
                list{text("New Project")},
              ),
              button(
                list{
                  Attrs.class_(
                    if state.bojRouting {
                      "px-2 py-1 text-xs bg-cyan-700 text-white rounded hover:bg-cyan-600 cursor-pointer"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
                    },
                  ),
                  Events.onClick(Ums(ToggleUmsBojRouting)),
                },
                list{text("BoJ Routing")},
              ),
            },
          ),
        },
      ),
      // Category tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Projects", UmsProjects, state.activeCategory),
          renderTab("ABI Validator", UmsAbiValidator, state.activeCategory),
          renderTab("Templates", UmsTemplates, state.activeCategory),
          renderTab("Assets", UmsAssets, state.activeCategory),
          renderTab("Distribution", UmsDistribution, state.activeCategory),
          renderTab("API Reference", UmsApiReference, state.activeCategory),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300",
            ),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                text(err),
                button(
                  list{
                    Attrs.class_("text-red-400 hover:text-red-200 cursor-pointer"),
                    Events.onClick(Ums(DismissUmsError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Loading
      if state.loading {
        div(
          list{Attrs.class_("px-4 py-2 text-xs text-cyan-400 animate-pulse")},
          list{text("Loading UMS data...")},
        )
      } else {
        noNode
      },
      // Level Architect cross-panel summary
      div(
        list{Attrs.class_("px-4 py-2 border-b border-gray-800/50")},
        list{renderLevelArchitectSummary(levelArchitect)},
      ),
      // Cross-panel navigation — quick-launch related eNSAID panels
      div(
        list{Attrs.class_("flex items-center gap-2 px-4 py-2 border-b border-gray-800/50")},
        list{
          span(list{Attrs.class_("text-xs text-gray-500 mr-1")}, list{text("Open:")}),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs bg-gray-800 text-cyan-400 rounded hover:bg-gray-700 cursor-pointer",
              ),
              Events.onClick(Ums(NavigateToPanel(PanelLevelArchitect))),
            },
            list{text("Level Architect")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs bg-gray-800 text-cyan-400 rounded hover:bg-gray-700 cursor-pointer",
              ),
              Events.onClick(Ums(NavigateToPanel(PanelDlcWorkshop))),
            },
            list{text("DLC Workshop")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs bg-gray-800 text-cyan-400 rounded hover:bg-gray-700 cursor-pointer",
              ),
              Events.onClick(Ums(NavigateToPanel(PanelGamePreview))),
            },
            list{text("Game Preview")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs bg-gray-800 text-cyan-400 rounded hover:bg-gray-700 cursor-pointer",
              ),
              Events.onClick(Ums(NavigateToPanel(PanelVmInspector))),
            },
            list{text("VM Inspector")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs bg-gray-800 text-cyan-400 rounded hover:bg-gray-700 cursor-pointer",
              ),
              Events.onClick(Ums(NavigateToPanel(PanelBuildDashboard))),
            },
            list{text("Build Dashboard")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs bg-gray-800 text-cyan-400 rounded hover:bg-gray-700 cursor-pointer",
              ),
              Events.onClick(Ums(NavigateToPanel(PanelReleaseManager))),
            },
            list{text("Release Manager")},
          ),
        },
      ),
      // Main content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | UmsProjects => renderProjects(state)
          | UmsAbiValidator => renderAbiValidator(state)
          | UmsTemplates => renderTemplates(state)
          | UmsAssets => renderAssets(state)
          | UmsDistribution => renderDistribution(state)
          | UmsApiReference => renderApiReference(state)
          },
        },
      ),
    },
  )
}
