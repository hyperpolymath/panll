// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL TSDM Panel — Triaxial Software Development Methodology directive.
///
/// A directive panel: users reorder axes, tier priorities, and cleanup steps.
/// Other panels read the active directive when presenting and sequencing work.
/// Displays aggregated work items classified by TSDM axes and tiers.
///
/// Two columns: Axis/tier ordering (left), Work items (right).

open Msg
open TsdmModel
open Tea.Html

/// Display label for an axis.
let axisLabel = (axis: axisId): string =>
  switch axis {
  | AxisScope => "Scope"
  | AxisMaintenance => "Maintenance"
  | AxisAudit => "Audit"
  }

/// Colour class for an axis.
let axisColour = (axis: axisId): string =>
  switch axis {
  | AxisScope => "text-emerald-400"
  | AxisMaintenance => "text-amber-400"
  | AxisAudit => "text-cyan-400"
  }

/// Display label for a scope tier.
let scopeTierLabel = (tier: scopeTier): string =>
  switch tier {
  | Must => "Must"
  | Intend => "Intend"
  | Like => "Like"
  }

/// Display label for a maintenance tier.
let maintenanceTierLabel = (tier: maintenanceTier): string =>
  switch tier {
  | Corrective => "Corrective"
  | Adaptive => "Adaptive"
  | Perfective => "Perfective"
  }

/// Display label for an audit tier.
let auditTierLabel = (tier: auditTier): string =>
  switch tier {
  | Systems => "Systems"
  | Compliance => "Compliance"
  | Effects => "Effects"
  }

/// Display label for a cleanup step.
let cleanupStepLabel = (step: cleanupStep): string =>
  switch step {
  | RootCleanup => "Root Cleanup"
  | StaleWorkCull => "Stale Work Cull"
  | DocsSyncHumanMachine => "Docs Sync (Human + Machine)"
  | ComplianceAudit => "Compliance Audit"
  | EffectsAudit => "Effects Audit"
  | ReleaseSummary => "Release Summary"
  | NextActions => "Next Actions"
  }

/// Render a numbered, reorderable list item with up/down arrows.
let orderItem = (
  index: int,
  lbl: string,
  colour: string,
  total: int,
  upMsg: msg,
  downMsg: msg,
): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2 py-1.5 px-3 bg-gray-800/50 rounded mb-1")},
    list{
      span(
        list{Attrs.class_("text-xs text-gray-500 font-mono w-5")},
        list{text(Int.toString(index + 1))},
      ),
      span(list{Attrs.class_(`flex-1 text-sm font-mono ${colour}`)}, list{text(lbl)}),
      button(
        list{
          Attrs.class_("text-xs text-gray-500 hover:text-gray-200 disabled:opacity-30 px-1"),
          Attrs.disabled(index == 0),
          Events.onClick(upMsg),
        },
        list{text("^")},
      ),
      button(
        list{
          Attrs.class_("text-xs text-gray-500 hover:text-gray-200 disabled:opacity-30 px-1"),
          Attrs.disabled(index == total - 1),
          Events.onClick(downMsg),
        },
        list{text("v")},
      ),
    },
  )
}

/// Render a toggleable cleanup step.
let cleanupItem = (step: cleanupStep, enabled: bool): Tea_Vdom.t<msg> => {
  label(
    list{
      Attrs.class_("flex items-center gap-2 py-1 px-3 cursor-pointer hover:bg-gray-800/30 rounded"),
    },
    list{
      input(
        list{
          Attrs.type_("checkbox"),
          Attrs.checked(enabled),
          Attrs.class_("w-3.5 h-3.5 accent-cyan-500"),
          Events.onClick(Tsdm(ToggleCleanupStep(step))),
        },
        list{},
      ),
      span(
        list{
          Attrs.class_(
            `text-sm font-mono ${enabled ? "text-gray-200" : "text-gray-500 line-through"}`,
          ),
        },
        list{text(cleanupStepLabel(step))},
      ),
    },
  )
}

/// Render a work item row.
let workItemRow = (item: tsdmWorkItem): Tea_Vdom.t<msg> => {
  let axisColourClass = axisColour(item.axis)
  let doneClass = item.done ? "opacity-40" : ""
  div(
    list{Attrs.class_(`flex items-center gap-3 py-1.5 px-3 border-b border-gray-700 ${doneClass}`)},
    list{
      span(
        list{Attrs.class_(`text-xs font-mono font-bold ${axisColourClass} min-w-[50px]`)},
        list{text(axisLabel(item.axis))},
      ),
      span(
        list{Attrs.class_("text-xs text-gray-500 font-mono min-w-[70px]")},
        list{
          text(
            switch (item.scopeTier, item.maintenanceTier, item.auditTier) {
            | (Some(t), _, _) => scopeTierLabel(t)
            | (_, Some(t), _) => maintenanceTierLabel(t)
            | (_, _, Some(t)) => auditTierLabel(t)
            | (None, None, None) => "-"
            },
          ),
        },
      ),
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{div(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(item.title)})},
      ),
      span(list{Attrs.class_("text-xs text-gray-600 font-mono")}, list{text(item.sourcePanel)}),
    },
  )
}

/// Sort work items according to current TSDM directive.
let sortByDirective = (
  items: array<tsdmWorkItem>,
  axisOrder: array<axisId>,
  showCompleted: bool,
): array<tsdmWorkItem> => {
  items
  ->Array.filter(item => showCompleted || !item.done)
  ->Array.toSorted((a, b) => {
    // Primary sort: axis position in axisOrder
    let posA = axisOrder->Array.findIndex(ax => ax == a.axis)->Int.toFloat
    let posB = axisOrder->Array.findIndex(ax => ax == b.axis)->Int.toFloat
    posA -. posB
  })
}

/// Render an axis filter button.
let axisFilterBtn = (
  lbl: string,
  filterVal: option<axisId>,
  activeFilter: option<axisId>,
): Tea_Vdom.t<msg> => {
  let active = activeFilter == filterVal
  button(
    list{
      Attrs.class_(
        `px-2 py-0.5 rounded font-mono text-xs ${active
            ? "bg-indigo-600 text-white"
            : "bg-gray-700 text-gray-400 hover:bg-gray-600"}`,
      ),
      Events.onClick(Tsdm(SetAxisFilter(filterVal))),
    },
    list{text(lbl)},
  )
}

/// Main panel view.
let view = (state: tsdmState): Tea_Vdom.t<msg> => {
  let sorted = sortByDirective(state.workItems, state.axisOrder, state.showCompleted)

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100 overflow-hidden")},
    list{
      // Header
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-4 py-3 bg-gray-800 border-b border-gray-700",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(list{Attrs.class_("text-lg font-bold text-indigo-400")}, list{text("TSDM")}),
              span(
                list{
                  Attrs.class_("text-xs text-gray-500 font-mono px-2 py-0.5 rounded bg-gray-700"),
                },
                list{text("directive")},
              ),
              if state.locked {
                span(
                  list{
                    Attrs.class_(
                      "text-xs text-amber-400 font-mono px-2 py-0.5 rounded bg-gray-700",
                    ),
                  },
                  list{text("LOCKED")},
                )
              } else {
                noNode
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    `px-3 py-1 text-xs rounded font-mono ${state.locked
                        ? "bg-amber-700 hover:bg-amber-600 text-white"
                        : "bg-gray-700 hover:bg-gray-600 text-gray-300"}`,
                  ),
                  Events.onClick(Tsdm(ToggleLock)),
                  KeyboardNav.onActivate(Tsdm(ToggleLock)),
                },
                list{text(state.locked ? "unlock" : "lock")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded bg-indigo-700 hover:bg-indigo-600 text-white font-mono",
                  ),
                  Events.onClick(Tsdm(ResetToDefaults)),
                  KeyboardNav.onActivate(Tsdm(ResetToDefaults)),
                },
                list{text("reset")},
              ),
            },
          ),
        },
      ),
      // Two-column layout
      div(
        list{Attrs.class_("flex flex-1 overflow-hidden")},
        list{
          // Left column: Axis ordering
          div(
            list{Attrs.class_("w-64 border-r border-gray-700 overflow-y-auto p-3")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 font-bold mb-2 uppercase")},
                list{text("Axis Execution Order")},
              ),
              div(
                list{},
                state.axisOrder
                ->Array.mapWithIndex((axis, i) =>
                  orderItem(
                    i,
                    axisLabel(axis),
                    axisColour(axis),
                    Array.length(state.axisOrder),
                    Tsdm(MoveAxisUp(i)),
                    Tsdm(MoveAxisDown(i)),
                  )
                )
                ->List.fromArray,
              ),
              // Scope tiers
              div(
                list{Attrs.class_("text-xs text-gray-500 font-bold mt-4 mb-2 uppercase")},
                list{text("Scope Tiers")},
              ),
              div(
                list{},
                state.scopeOrder
                ->Array.mapWithIndex((tier, i) =>
                  orderItem(
                    i,
                    scopeTierLabel(tier),
                    "text-emerald-300",
                    Array.length(state.scopeOrder),
                    Tsdm(MoveScopeTierUp(i)),
                    Tsdm(MoveScopeTierDown(i)),
                  )
                )
                ->List.fromArray,
              ),
              // Maintenance tiers
              div(
                list{Attrs.class_("text-xs text-gray-500 font-bold mt-4 mb-2 uppercase")},
                list{text("Maintenance Tiers")},
              ),
              div(
                list{},
                state.maintenanceOrder
                ->Array.mapWithIndex((tier, i) =>
                  orderItem(
                    i,
                    maintenanceTierLabel(tier),
                    "text-amber-300",
                    Array.length(state.maintenanceOrder),
                    Tsdm(MoveMaintenanceTierUp(i)),
                    Tsdm(MoveMaintenanceTierDown(i)),
                  )
                )
                ->List.fromArray,
              ),
              // Audit tiers
              div(
                list{Attrs.class_("text-xs text-gray-500 font-bold mt-4 mb-2 uppercase")},
                list{text("Audit Tiers")},
              ),
              div(
                list{},
                state.auditOrder
                ->Array.mapWithIndex((tier, i) =>
                  orderItem(
                    i,
                    auditTierLabel(tier),
                    "text-cyan-300",
                    Array.length(state.auditOrder),
                    Tsdm(MoveAuditTierUp(i)),
                    Tsdm(MoveAuditTierDown(i)),
                  )
                )
                ->List.fromArray,
              ),
              // Cleanup steps
              div(
                list{Attrs.class_("text-xs text-gray-500 font-bold mt-4 mb-2 uppercase")},
                list{text("Cleanup Steps")},
              ),
              div(
                list{},
                state.cleanupSteps
                ->Array.map(step => {
                  let enabled = state.cleanupEnabled->Array.includes(step)
                  cleanupItem(step, enabled)
                })
                ->List.fromArray,
              ),
              // Tooling
              div(
                list{Attrs.class_("text-xs text-gray-500 font-bold mt-4 mb-2 uppercase")},
                list{text("Tooling")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-400 px-3 py-1")},
                list{
                  div(list{}, list{text(`Compliance: ${state.auditTooling.complianceTool}`)}),
                  div(list{}, list{text(`Effects: ${state.auditTooling.effectsTool}`)}),
                },
              ),
            },
          ),
          // Right column: Work items
          div(
            list{Attrs.class_("flex-1 flex flex-col overflow-hidden")},
            list{
              // Filter bar
              div(
                list{
                  Attrs.class_(
                    "flex items-center gap-2 px-3 py-2 border-b border-gray-700 text-xs",
                  ),
                },
                list{
                  // Axis filter buttons
                  axisFilterBtn("All", None, state.axisFilter),
                  div(
                    list{Attrs.class_("flex gap-1")},
                    state.axisOrder
                    ->Array.map(axis =>
                      axisFilterBtn(axisLabel(axis), Some(axis), state.axisFilter)
                    )
                    ->List.fromArray,
                  ),
                  label(
                    list{Attrs.class_("flex items-center gap-1 text-gray-400 cursor-pointer ml-2")},
                    list{
                      input(
                        list{
                          Attrs.type_("checkbox"),
                          Attrs.checked(state.showCompleted),
                          Attrs.class_("w-3 h-3 accent-indigo-500"),
                          Events.onClick(Tsdm(ToggleShowCompleted)),
                          KeyboardNav.onActivate(Tsdm(ToggleShowCompleted)),
                        },
                        list{},
                      ),
                      text("Done"),
                    },
                  ),
                  input(
                    list{
                      Attrs.type_("text"),
                      Attrs.class_(
                        "ml-auto w-40 bg-gray-800 text-sm text-gray-200 px-2 py-0.5 rounded border border-gray-600 font-mono",
                      ),
                      Attrs.placeholder("Search..."),
                      Attrs.value(state.searchText),
                      Events.onInput(v => Tsdm(SetTsdmSearch(v))),
                    },
                    list{},
                  ),
                },
              ),
              // Work items list
              div(
                list{Attrs.class_("flex-1 overflow-y-auto")},
                {
                  let filtered = switch state.axisFilter {
                  | None => sorted
                  | Some(axis) => sorted->Array.filter(item => item.axis == axis)
                  }
                  let searched =
                    state.searchText == ""
                      ? filtered
                      : filtered->Array.filter(item =>
                          String.includes(
                            String.toLowerCase(item.title),
                            String.toLowerCase(state.searchText),
                          )
                        )
                  if Array.length(searched) == 0 {
                    list{
                      div(
                        list{
                          Attrs.class_(
                            "flex items-center justify-center h-32 text-gray-500 text-sm",
                          ),
                        },
                        list{
                          text(
                            if Array.length(state.workItems) == 0 {
                              "No work items. Consumer panels will populate items as they run."
                            } else {
                              "No items match the current filter."
                            },
                          ),
                        },
                      ),
                    }
                  } else {
                    searched->Array.map(workItemRow)->List.fromArray
                  }
                },
              ),
              // Footer
              div(
                list{
                  Attrs.class_(
                    "flex items-center justify-between px-3 py-2 bg-gray-800 border-t border-gray-700 text-xs text-gray-500",
                  ),
                },
                list{
                  span(
                    list{},
                    list{
                      text(
                        `${Int.toString(Array.length(state.workItems))} items (${Int.toString(
                            state.workItems->Array.filter(i => i.done)->Array.length,
                          )} done)`,
                      ),
                    },
                  ),
                  span(list{}, list{text("TSDM 1.0 — Scope > Maintenance > Audit")}),
                },
              ),
            },
          ),
        },
      ),
      // Error display
      switch state.lastError {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 border-t border-red-700 text-red-300 text-sm"),
          },
          list{text(err)},
        )
      | None => noNode
      },
    },
  )
}
