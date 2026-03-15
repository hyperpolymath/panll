// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Guard AI Tuner Component — guard patrol, alert threshold, and spawn
/// rate tuning. Displays guard profile cards with patrol patterns, slider
/// controls, patrol route editor, and presets dropdown.

open Model
open Msg
open Tea.Html

/// Render a slider-style parameter row for guard profiles.
let guardParamRow = (label: string, value: float, maxVal: float, unit: string): Tea_Vdom.t<msg> => {
  let pct = Math.min(value /. maxVal *. 100.0, 100.0)
  div(
    list{Attrs.class_("flex items-center gap-3 py-1")},
    list{
      span(list{Attrs.class_("text-xs text-gray-400 w-28")}, list{text(label)}),
      div(
        list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_("h-full bg-orange-500 transition-all"),
              Attrs.style("width", Float.toFixed(pct, ~digits=1) ++ "%"),
            },
            list{},
          ),
        },
      ),
      span(
        list{Attrs.class_("text-xs text-gray-500 w-16 text-right font-mono")},
        list{text(Float.toFixed(value, ~digits=2) ++ unit)},
      ),
    },
  )
}

/// Main view function for the Guard AI Tuner panel.
let view = (state: guardAiTunerState): Tea_Vdom.t<msg> => {
  let guardCount = Array.length(state.guards)
  let routeCount = Array.length(state.routes)
  let presetCount = Array.length(state.presets)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Guard AI Tuner — Patrol and Alert Threshold Tuning"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-bold text-orange-300")}, list{text("Guard AI Tuner")}),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(Int.toString(guardCount) ++ " guards, " ++ Int.toString(routeCount) ++ " routes")},
              ),
              if state.editing {
                span(list{Attrs.class_("text-xs text-yellow-400")}, list{text("Editing...")})
              } else {
                Tea_Html.noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-orange-800 hover:bg-orange-700 text-white rounded"),
              Events.onClick(GuardAiTuner(GatStarted)),
            },
            list{text("Apply Tuning")},
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Profiles { "bg-orange-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GuardAiTuner(SetGatCategory(Profiles))),
            },
            list{text("Profiles")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == PatrolEditor { "bg-orange-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GuardAiTuner(SetGatCategory(PatrolEditor))),
            },
            list{text("Patrol Editor")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Thresholds { "bg-orange-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GuardAiTuner(SetGatCategory(Thresholds))),
            },
            list{text("Thresholds")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Presets { "bg-orange-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GuardAiTuner(SetGatCategory(Presets))),
            },
            list{text("Presets (" ++ Int.toString(presetCount) ++ ")")},
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center")},
          list{
            text(err),
            button(
              list{Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"), Events.onClick(GuardAiTuner(DismissGatError))},
              list{text("Dismiss")},
            ),
          },
        )
      | None => Tea_Html.noNode
      },
      // Content area
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-4")},
        list{
          switch state.activeTab {
          | Profiles =>
            div(
              list{Attrs.class_("space-y-3")},
              state.guards
              ->Array.map(g => {
                let isSelected = state.selectedGuard == Some(g.id)
                div(
                  list{
                    Attrs.class_(
                      "px-3 py-2 border rounded " ++
                      if isSelected { "bg-orange-900/20 border-orange-700" } else { "bg-gray-900 border-gray-800" },
                    ),
                  },
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between mb-2")},
                      list{
                        span(list{Attrs.class_("text-sm font-bold text-orange-300")}, list{text(g.name)}),
                        span(
                          list{Attrs.class_("px-2 py-0.5 text-xs bg-gray-800 text-gray-300 rounded font-mono")},
                          list{text(g.patrolPattern)},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-gray-400")},
                      list{
                        span(list{}, list{text("Alert: " ++ Float.toFixed(g.alertThreshold, ~digits=2))}),
                        span(list{}, list{text("Spawn: " ++ Float.toFixed(g.spawnRate, ~digits=1) ++ "x")}),
                        span(list{}, list{text("Speed: " ++ Float.toFixed(g.speed, ~digits=1) ++ " u/s")}),
                        span(list{}, list{text("Detection: " ++ Float.toFixed(g.detectionRange, ~digits=0) ++ " u")}),
                        span(list{}, list{text("Response: " ++ Float.toFixed(g.responseTime, ~digits=1) ++ "s")}),
                      },
                    ),
                  },
                )
              })
              ->List.fromArray,
            )
          | PatrolEditor =>
            div(
              list{Attrs.class_("space-y-3")},
              state.routes
              ->Array.map(route =>
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between mb-2")},
                      list{
                        span(list{Attrs.class_("text-sm text-gray-200 font-mono")}, list{text("Route: " ++ route.id)}),
                        span(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(if route.looping { "Looping" } else { "Ping-pong" })},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("space-y-1")},
                      route.points
                      ->Array.mapWithIndex((pt, idx) =>
                        div(
                          list{Attrs.class_("flex items-center gap-2 text-xs text-gray-400")},
                          list{
                            span(list{Attrs.class_("w-6 text-gray-600")}, list{text(Int.toString(idx + 1))}),
                            span(
                              list{Attrs.class_("font-mono")},
                              list{text("(" ++ Float.toFixed(pt.x, ~digits=0) ++ ", " ++ Float.toFixed(pt.y, ~digits=0) ++ ")")},
                            ),
                            span(list{Attrs.class_("text-gray-600")}, list{text("wait " ++ Float.toFixed(pt.waitTime, ~digits=1) ++ "s")}),
                          },
                        )
                      )
                      ->List.fromArray,
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          | Thresholds =>
            switch state.selectedGuard {
            | Some(gid) =>
              switch state.guards->Array.find(g => g.id == gid) {
              | Some(g) =>
                div(
                  list{Attrs.class_("space-y-2")},
                  list{
                    div(list{Attrs.class_("text-sm text-orange-300 font-bold mb-3")}, list{text(g.name ++ " — Thresholds")}),
                    guardParamRow("Alert Threshold", g.alertThreshold, 1.0, ""),
                    guardParamRow("Spawn Rate", g.spawnRate, 5.0, "x"),
                    guardParamRow("Speed", g.speed, 20.0, " u/s"),
                    guardParamRow("Detection", g.detectionRange, 100.0, " u"),
                    guardParamRow("Response Time", g.responseTime, 10.0, "s"),
                  },
                )
              | None =>
                div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Guard not found.")})
              }
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("Select a guard profile to tune thresholds.")},
              )
            }
          | Presets =>
            div(
              list{Attrs.class_("space-y-2")},
              state.presets
              ->Array.map(p =>
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(list{Attrs.class_("text-sm font-bold text-gray-200")}, list{text(p.name)}),
                    div(list{Attrs.class_("text-xs text-gray-500 mt-1")}, list{text(p.description)}),
                    div(
                      list{Attrs.class_("flex gap-2 mt-2")},
                      p.profiles
                      ->Array.map(prof =>
                        span(
                          list{Attrs.class_("px-2 py-0.5 text-xs bg-orange-900/30 text-orange-300 rounded")},
                          list{text(prof.name)},
                        )
                      )
                      ->List.fromArray,
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          },
        },
      ),
    },
  )
}
