// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Vexometer Friction Component — irritation surface measurements across tools.
///
/// Two-column layout: left sidebar with tool list (sorted by friction),
/// right content with ISA dimension detail view and trend indicators.

open Model
open Msg
open Tea.Html

/// Render a friction trend indicator.
let trendIndicator = (trend: frictionTrend): Tea_Vdom.t<msg> => {
  let (color, arrow) = switch trend {
  | Improving => ("text-green-400", "v")
  | Stable => ("text-gray-400", "-")
  | Worsening => ("text-red-400", "^")
  | NoData => ("text-gray-600", "?")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(arrow)})
}

/// Render a tool row in the sidebar.
let toolRow = (tool: toolFrictionProfile, selected: bool): Tea_Vdom.t<msg> => {
  let scoreColor = if tool.overallScore < 3.0 {
    "text-green-400"
  } else if tool.overallScore < 6.0 {
    "text-amber-400"
  } else {
    "text-red-400"
  }
  button(
    list{
      Attrs.class_(
        "w-full text-left px-3 py-2 border-b border-gray-800 hover:bg-gray-800/60 transition-colors " ++ if (
          selected
        ) {
          "bg-gray-800/80 border-l-2 border-l-blue-500"
        } else {
          ""
        },
      ),
      Events.onClick(VexometerFriction(SelectTool(tool.toolName))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(tool.toolName)}),
          div(
            list{Attrs.class_("flex items-center gap-1")},
            list{
              span(
                list{Attrs.class_("text-xs font-mono " ++ scoreColor)},
                list{text(Float.toFixed(tool.overallScore, ~digits=1))},
              ),
              trendIndicator(tool.trend),
            },
          ),
        },
      ),
    },
  )
}

/// Render an ISA dimension bar.
let dimensionBar = (dim: isaDimension): Tea_Vdom.t<msg> => {
  let barColor = if dim.score < 3.0 {
    "bg-green-500"
  } else if dim.score < 6.0 {
    "bg-amber-500"
  } else {
    "bg-red-500"
  }
  let pctWidth = Float.toFixed(dim.score *. 10.0, ~digits=1)
  div(
    list{Attrs.class_("flex items-center gap-2 py-1")},
    list{
      span(list{Attrs.class_("text-xs text-gray-400 w-28 shrink-0")}, list{text(dim.name)}),
      div(
        list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-2")},
        list{
          div(
            list{
              Attrs.class_(`${barColor} h-2 rounded-full transition-all duration-300`),
              Attrs.style("width", `${pctWidth}%`),
            },
            list{},
          ),
        },
      ),
      span(
        list{Attrs.class_("text-xs text-gray-500 w-8 text-right")},
        list{text(Float.toFixed(dim.score, ~digits=1))},
      ),
      span(
        list{Attrs.class_("text-xs text-gray-600 w-10 text-right")},
        list{text(`(${Int.toString(dim.sampleCount)})`)},
      ),
    },
  )
}

/// Render a tab button.
let tabBtn = (
  current: vexometerFrictionTab,
  target: vexometerFrictionTab,
  label: string,
): Tea_Vdom.t<msg> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++ if active {
          "bg-blue-600 text-white"
        } else {
          "bg-gray-800 text-gray-400 hover:bg-gray-700"
        },
      ),
      Events.onClick(VexometerFriction(SetTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the Vexometer Friction panel.
let view = (state: vexometerFrictionState): Tea_Vdom.t<msg> => {
  let avgFriction = VexometerFrictionEngine.averageFriction(state.tools)
  let total = Array.length(state.tools)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Vexometer Friction — Irritation Surface Measurements"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-orange-300")},
                list{text("Vexometer Friction")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    `Avg: ${Float.toFixed(avgFriction, ~digits=1)}/10.0 | ${Int.toString(
                        total,
                      )} tools`,
                  ),
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600"),
              Events.onClick(VexometerFriction(MeasureAll)),
            },
            list{
              text(
                if state.measuring {
                  "Measuring..."
                } else {
                  "Measure All"
                },
              ),
            },
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        VexometerFrictionEngine.allTabs
        ->Array.map(t => tabBtn(state.activeTab, t, VexometerFrictionEngine.tabLabel(t)))
        ->List.fromArray,
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200",
            ),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Two-column layout
      div(
        list{Attrs.class_("flex flex-1 overflow-hidden")},
        list{
          // Left sidebar — tool list sorted by friction
          div(
            list{Attrs.class_("w-64 border-r border-gray-800 overflow-y-auto")},
            VexometerFrictionEngine.sortByFriction(state.tools)
            ->Array.map(t => toolRow(t, state.selectedTool == Some(t.toolName)))
            ->List.fromArray,
          ),
          // Right content — ISA dimension detail
          div(
            list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
            list{
              switch state.selectedTool {
              | None =>
                div(
                  list{Attrs.class_("flex items-center justify-center h-full text-gray-600")},
                  list{text("Select a tool to view friction dimensions")},
                )
              | Some(name) =>
                switch state.tools->Array.find(t => t.toolName == name) {
                | None => div(list{}, list{text("Tool not found")})
                | Some(tool) =>
                  div(
                    list{},
                    list{
                      div(
                        list{Attrs.class_("flex items-center justify-between mb-3")},
                        list{
                          h3(
                            list{Attrs.class_("text-md font-semibold text-gray-200")},
                            list{text(tool.toolName)},
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-sm font-mono text-gray-300")},
                                list{text(`${Float.toFixed(tool.overallScore, ~digits=1)}/10.0`)},
                              ),
                              trendIndicator(tool.trend),
                              span(
                                list{Attrs.class_("text-xs text-gray-500")},
                                list{text(VexometerFrictionEngine.trendLabel(tool.trend))},
                              ),
                            },
                          ),
                        },
                      ),
                      div(
                        list{Attrs.class_("space-y-1")},
                        tool.dimensions->Array.map(d => dimensionBar(d))->List.fromArray,
                      ),
                      div(
                        list{Attrs.class_("mt-3 text-xs text-gray-600")},
                        list{text(`Last measured: ${tool.lastMeasured}`)},
                      ),
                    },
                  )
                }
              },
            },
          ),
        },
      ),
      // Footer
      div(
        list{Attrs.class_("px-4 py-2 border-t border-gray-800 text-xs text-gray-500")},
        list{
          text(
            `${Int.toString(
                state.tools->Array.filter(t => t.trend == Worsening)->Array.length,
              )} tools worsening`,
          ),
        },
      ),
    },
  )
}
