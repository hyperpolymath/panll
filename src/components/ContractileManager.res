// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// PanLL Contractile Manager Component — cognitive governance dashboard.
///
/// Displays all 11 built-in contractiles from the Cognitive Governance Stack
/// (DD-007) with colour-coded status badges, elasticity levels, and the
/// current vexation index. Contractiles are the elastic, adaptive state-shapes
/// between the Operator and the Machine.
///
/// Status colours: green=Satisfied, red=Violated, yellow=Pending, grey=Suspended.

open Model
open Msg
open Tea.Html

/// Render a contractile status badge with colour coding.
let statusBadge = (status: contractStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | Satisfied => ("bg-green-700 text-green-100", "Satisfied")
  | Violated(_) => ("bg-red-700 text-red-100", "Violated")
  | Pending => ("bg-yellow-700 text-yellow-100", "Pending")
  | Suspended => ("bg-gray-700 text-gray-300", "Suspended")
  }
  span(
    list{
      Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color),
      Attrs.ariaLabel("Status: " ++ label),
    },
    list{text(label)},
  )
}

/// Render an enforcement level indicator.
let enforcementLabel = (level: enforcementLevel): Tea_Vdom.t<msg> => {
  let (color, label) = switch level {
  | Strict => ("text-red-400", "Strict")
  | Adaptive => ("text-amber-400", "Adaptive")
  | Warn => ("text-blue-400", "Warn")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render an elasticity bar — visual indicator of how flexible the contractile is.
/// 0.0 = rigid (no give), 1.0 = fully elastic (maximum flexibility).
let elasticityBar = (elasticity: float): Tea_Vdom.t<msg> => {
  let pct = Float.toFixed(elasticity *. 100.0, ~digits=0)
  let barColor = if elasticity == 0.0 {
    "bg-red-500"
  } else if elasticity < 0.3 {
    "bg-amber-500"
  } else {
    "bg-green-500"
  }
  div(
    list{Attrs.class_("flex items-center gap-2"), Attrs.ariaLabel("Elasticity: " ++ pct ++ "%")},
    list{
      div(
        list{Attrs.class_("w-16 h-2 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_("h-full rounded-full transition-all " ++ barColor),
              Attrs.prop("style", "width: " ++ pct ++ "%"),
            },
            list{},
          ),
        },
      ),
      span(list{Attrs.class_("text-xs text-gray-500 w-8")}, list{text(pct ++ "%")}),
    },
  )
}

/// Render a single contractile row.
let renderContractile = (c: contractile): Tea_Vdom.t<msg> => {
  let violationDetail = switch c.status {
  | Violated(reason) =>
    div(
      list{Attrs.class_("text-xs text-red-300 mt-1 pl-2 border-l-2 border-red-800")},
      list{text(reason)},
    )
  | _ => Tea_Html.noNode
  }

  div(
    list{
      Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded"),
      Attrs.role("listitem"),
      Attrs.ariaLabel(c.name ++ " contractile"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          statusBadge(c.status),
          div(
            list{Attrs.class_("flex-1")},
            list{
              div(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(c.name)}),
              div(list{Attrs.class_("text-xs text-gray-500 mt-0.5")}, list{text(c.description)}),
            },
          ),
          enforcementLabel(c.enforcement),
          elasticityBar(c.elasticity),
        },
      ),
      violationDetail,
    },
  )
}

/// Render the vexation index indicator — shows current operator friction level.
let vexationIndicator = (vexometer: vexometerState): Tea_Vdom.t<msg> => {
  let pct = Float.toFixed(vexometer.index *. 100.0, ~digits=0)
  let color = if vexometer.index > 0.7 {
    "text-red-400"
  } else if vexometer.index > 0.4 {
    "text-amber-400"
  } else {
    "text-green-400"
  }
  div(
    list{
      Attrs.class_("flex items-center gap-3 px-4 py-2 bg-gray-900 border border-gray-800 rounded"),
      Attrs.role("status"),
      Attrs.ariaLabel("Vexation index: " ++ pct ++ "%"),
    },
    list{
      span(list{Attrs.class_("text-sm text-gray-400")}, list{text("Vexation Index")}),
      span(list{Attrs.class_("text-lg font-bold font-mono " ++ color)}, list{text(pct ++ "%")}),
      div(
        list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(
                "h-full rounded-full transition-all " ++ if vexometer.index > 0.7 {
                  "bg-red-500"
                } else if vexometer.index > 0.4 {
                  "bg-amber-500"
                } else {
                  "bg-green-500"
                },
              ),
              Attrs.prop("style", "width: " ++ pct ++ "%"),
            },
            list{},
          ),
        },
      ),
    },
  )
}

/// Main view function for the Contractile Manager panel.
let view = (contractiles: array<contractile>, vexometer: vexometerState): Tea_Vdom.t<msg> => {
  let totalCount = Array.length(contractiles)
  let satisfiedCount = contractiles->Array.filter(c => c.status == Satisfied)->Array.length
  let violatedCount =
    contractiles
    ->Array.filter(c =>
      switch c.status {
      | Violated(_) => true
      | _ => false
      }
    )
    ->Array.length

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Contractile Manager — Cognitive Governance Dashboard"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-purple-300")},
                list{text("Contractile Manager")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(satisfiedCount) ++
                    "/" ++
                    Int.toString(totalCount) ++
                    " satisfied" ++ if violatedCount > 0 {
                      ", " ++ Int.toString(violatedCount) ++ " violated"
                    } else {
                      ""
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Vexation indicator
      div(list{Attrs.class_("px-4 pt-3")}, list{vexationIndicator(vexometer)}),
      // Contractile list
      div(
        list{
          Attrs.class_("flex-1 overflow-y-auto px-4 py-3 space-y-2"),
          Attrs.role("list"),
          Attrs.ariaLabel("Contractile governance stack"),
        },
        contractiles->Array.map(c => renderContractile(c))->List.fromArray,
      ),
    },
  )
}
