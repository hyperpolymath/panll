// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Automation Router Component — view for cross-panel workflow
/// orchestration with event-driven rules and hybrid approval gates.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: automationRouterCategory,
  active: automationRouterCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(AutomationRouter(SetRouterCategory(cat)))},
    list{text(label)},
  )
}

/// Render dashboard — stats cards, global toggle, recent executions.
let renderDashboard = (state: automationRouterState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Stats row
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-cyan-400")},
                list{text(Int.toString(AutomationRouterEngine.enabledCount(state.rules)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Active Rules")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-amber-400")},
                list{text(Int.toString(AutomationRouterEngine.pendingCount(state.pendingActions)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Pending Approval")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-emerald-400")},
                list{text(AutomationRouterEngine.formatSuccessRate(AutomationRouterEngine.successRate(state.executionLog)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Success Rate")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-300")},
                list{text(Int.toString(Array.length(state.executionLog)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Executions")}),
            },
          ),
        },
      ),
      // Global toggle
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                if state.globalEnabled {
                  "px-4 py-2 text-sm bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer"
                } else {
                  "px-4 py-2 text-sm bg-red-800 text-red-200 rounded hover:bg-red-700 cursor-pointer"
                },
              ),
              Events.onClick(AutomationRouter(ToggleGlobalEnabled)),
            },
            list{text(if state.globalEnabled { "Automation: ON" } else { "Automation: OFF" })},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`${Int.toString(Array.length(state.rules))} rules configured`)},
          ),
        },
      ),
      // Recent executions
      if Array.length(state.executionLog) > 0 {
        div(
          list{Attrs.class_("space-y-1")},
          list{
            div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text("Recent Executions")}),
            ...state.executionLog
            ->Array.slice(~start=0, ~end=5)
            ->Array.map(entry =>
              div(
                list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded text-xs")},
                list{
                  span(
                    list{Attrs.class_(if entry.success { "text-emerald-400" } else { "text-red-400" })},
                    list{text(if entry.success { "OK" } else { "FAIL" })},
                  ),
                  span(list{Attrs.class_("text-gray-200 flex-1")}, list{text(entry.ruleName)}),
                  span(list{Attrs.class_("text-gray-500")}, list{text(entry.detail)}),
                },
              )
            )
            ->List.fromArray,
          },
        )
      } else {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No executions yet — rules will appear here when they fire")},
        )
      },
    },
  )
}

/// Render rules list.
let renderRules = (state: automationRouterState): Tea_Vdom.t<msg> => {
  let filtered = AutomationRouterEngine.filterRules(state.rules, state.filterText, state.showDisabled)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Filter
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_("flex-1 px-3 py-1.5 text-xs bg-gray-800 text-gray-200 rounded border border-gray-700"),
              Attrs.placeholder("Filter rules..."),
              Attrs.value(state.filterText),
              Events.onInput(text => AutomationRouter(SetRouterFilter(text))),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_(
                if state.showDisabled {
                  "px-2 py-1 text-xs bg-gray-600 text-white rounded"
                } else {
                  "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(AutomationRouter(ToggleShowDisabled)),
            },
            list{text("Show Disabled")},
          ),
        },
      ),
      // Rule cards
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No rules configured — load from .machine_readable/ENSAID_CONFIG.a2ml or create manually")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          filtered
          ->Array.map(rule => {
            let triggerCls = AutomationRouterEngine.triggerColour(rule.trigger)
            let approvalCls = AutomationRouterEngine.approvalColour(rule.approval)
            div(
              list{
                Attrs.class_(
                  `p-3 bg-gray-800 rounded border ${if rule.enabled {
                      "border-gray-700"
                    } else {
                      "border-gray-800 opacity-50"
                    }}`,
                ),
              },
              list{
                div(
                  list{Attrs.class_("flex items-center gap-2 mb-2")},
                  list{
                    span(list{Attrs.class_("text-sm text-gray-100 font-medium flex-1")}, list{text(rule.name)}),
                    span(list{Attrs.class_(`text-xs ${triggerCls} font-mono`)}, list{text(AutomationRouterEngine.triggerKindLabel(rule.trigger))}),
                    span(list{Attrs.class_(`text-xs ${approvalCls}`)}, list{text(AutomationRouterEngine.approvalLabel(rule.approval))}),
                  },
                ),
                div(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{text(rule.description)}),
                div(
                  list{Attrs.class_("flex items-center gap-2")},
                  list{
                    span(list{Attrs.class_("text-xs text-gray-500")}, list{text(`Trigger: ${AutomationRouterEngine.triggerLabel(rule.trigger)}`)}),
                    span(list{Attrs.class_("text-xs text-gray-600")}, list{text(`Fired: ${Int.toString(rule.firedCount)}x`)}),
                    button(
                      list{
                        Attrs.class_(
                          if rule.enabled {
                            "ml-auto px-2 py-1 text-xs bg-emerald-800 text-emerald-200 rounded cursor-pointer"
                          } else {
                            "ml-auto px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                          },
                        ),
                        Events.onClick(AutomationRouter(ToggleRule(rule.id))),
                      },
                      list{text(if rule.enabled { "Enabled" } else { "Disabled" })},
                    ),
                    button(
                      list{
                        Attrs.class_("px-2 py-1 text-xs bg-cyan-800 text-cyan-200 rounded hover:bg-cyan-700 cursor-pointer"),
                        Events.onClick(AutomationRouter(ExecuteRule(rule.id))),
                      },
                      list{text("Run")},
                    ),
                  },
                ),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render pending approval actions.
let renderPending = (state: automationRouterState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      if Array.length(state.pendingActions) > 0 {
        div(
          list{Attrs.class_("flex items-center gap-2 mb-2")},
          list{
            button(
              list{
                Attrs.class_("px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer"),
                Events.onClick(AutomationRouter(ApproveAll)),
              },
              list{text("Approve All")},
            ),
            button(
              list{
                Attrs.class_("px-3 py-1.5 text-xs bg-red-800 text-red-200 rounded hover:bg-red-700 cursor-pointer"),
                Events.onClick(AutomationRouter(RejectAll)),
              },
              list{text("Reject All")},
            ),
          },
        )
      } else {
        noNode
      },
      if Array.length(state.pendingActions) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No pending actions — rules with approval gates will queue here")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          state.pendingActions
          ->Array.mapWithIndex((action, idx) =>
            div(
              list{Attrs.class_("p-3 bg-gray-800 rounded border border-amber-800/50")},
              list{
                div(
                  list{Attrs.class_("flex items-center gap-2 mb-2")},
                  list{
                    span(list{Attrs.class_("text-sm text-amber-300 font-medium")}, list{text(action.ruleName)}),
                    span(list{Attrs.class_("text-xs text-gray-500 ml-auto")}, list{text(action.triggerDetail)}),
                  },
                ),
                div(
                  list{Attrs.class_("space-y-1 mb-2")},
                  action.actions
                  ->Array.map(a =>
                    div(
                      list{Attrs.class_("text-xs text-gray-400 font-mono")},
                      list{text(`${a.panelId} -> ${a.message}`)},
                    )
                  )
                  ->List.fromArray,
                ),
                div(
                  list{Attrs.class_("flex items-center gap-2")},
                  list{
                    button(
                      list{
                        Attrs.class_("px-3 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer"),
                        Events.onClick(AutomationRouter(ApproveAction(idx))),
                      },
                      list{text("Approve")},
                    ),
                    button(
                      list{
                        Attrs.class_("px-3 py-1 text-xs bg-red-800 text-red-200 rounded hover:bg-red-700 cursor-pointer"),
                        Events.onClick(AutomationRouter(RejectAction(idx))),
                      },
                      list{text("Reject")},
                    ),
                  },
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

/// Render execution history.
let renderHistory = (state: automationRouterState): Tea_Vdom.t<msg> => {
  if Array.length(state.executionLog) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No execution history")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
      state.executionLog
      ->Array.map(entry =>
        div(
          list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded text-xs")},
          list{
            span(
              list{Attrs.class_(if entry.success { "text-emerald-400 w-8" } else { "text-red-400 w-8" })},
              list{text(if entry.success { "OK" } else { "FAIL" })},
            ),
            span(list{Attrs.class_("text-gray-200 flex-1")}, list{text(entry.ruleName)}),
            span(list{Attrs.class_("text-gray-500")}, list{text(entry.detail)}),
            span(
              list{Attrs.class_("text-gray-600 font-mono")},
              list{text(AutomationRouterEngine.formatRelativeTime(entry.triggeredAt))},
            ),
          },
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render settings view.
let renderSettings = (state: automationRouterState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Config source
      div(
        list{Attrs.class_("p-4 bg-gray-800 rounded border border-gray-700")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 mb-3")}, list{text("Configuration Source")}),
          div(
            list{Attrs.class_("text-xs text-gray-400 mb-3")},
            list{text("Rules can be loaded from the repo's .machine_readable/ENSAID_CONFIG.a2ml or stored locally in PanLL.")},
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    if state.configSource === "repo" {
                      "px-3 py-1.5 text-xs bg-cyan-700 text-white rounded"
                    } else {
                      "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded cursor-pointer hover:bg-gray-600"
                    },
                  ),
                  Events.onClick(AutomationRouter(LoadFromRepo)),
                },
                list{text("Load from Repo")},
              ),
              button(
                list{
                  Attrs.class_("px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
                  Events.onClick(AutomationRouter(SaveRules)),
                },
                list{text("Save Rules")},
              ),
            },
          ),
        },
      ),
      // Show disabled toggle
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                if state.showDisabled {
                  "px-3 py-1.5 text-xs bg-gray-600 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(AutomationRouter(ToggleShowDisabled)),
            },
            list{text("Show Disabled Rules")},
          ),
        },
      ),
    },
  )
}

/// Main view function.
let view = (state: automationRouterState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Automation Router panel"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(list{Attrs.class_("text-lg font-semibold text-gray-100")}, list{text("Automation Router")}),
              if state.globalEnabled {
                span(list{Attrs.class_("text-xs text-emerald-400")}, list{text("ACTIVE")})
              } else {
                span(list{Attrs.class_("text-xs text-red-400")}, list{text("PAUSED")})
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
              Events.onClick(AutomationRouter(LoadRules)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Dashboard", RouterDashboard, state.activeCategory),
          renderTab("Rules", RouterRules, state.activeCategory),
          renderTab("Pending", RouterPending, state.activeCategory),
          renderTab("History", RouterHistory, state.activeCategory),
          renderTab("Settings", RouterSettings, state.activeCategory),
        },
      ),
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300")},
          list{text(err)},
        )
      | None => noNode
      },
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | RouterDashboard => renderDashboard(state)
          | RouterRules => renderRules(state)
          | RouterPending => renderPending(state)
          | RouterHistory => renderHistory(state)
          | RouterSettings => renderSettings(state)
          },
        },
      ),
    },
  )
}
