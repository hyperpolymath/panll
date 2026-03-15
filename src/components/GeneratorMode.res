// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Generator Mode Component — parametric procedural world builder.
/// Displays district list builder, slider controls for global parameters,
/// preview area, and export button.

open Model
open Msg
open Tea.Html

/// Render a district type label.
let districtTypeLabel = (dt: districtType): string => {
  switch dt {
  | Residential => "Residential"
  | Commercial => "Commercial"
  | Military => "Military"
  | Industrial => "Industrial"
  | Government => "Government"
  | Transport => "Transport"
  | Historic => "Historic"
  }
}

/// Render a weather condition label.
let weatherLabel = (w: weatherCondition): string => {
  switch w {
  | Clear => "Clear"
  | Rain => "Rain"
  | Snow => "Snow"
  | Fog => "Fog"
  | Storm => "Storm"
  | NightRain => "Night Rain"
  }
}

/// Render a time-of-day label.
let timeLabel = (t: timeOfDay): string => {
  switch t {
  | Dawn => "Dawn"
  | Morning => "Morning"
  | Afternoon => "Afternoon"
  | Evening => "Evening"
  | Night => "Night"
  | Midnight => "Midnight"
  }
}

/// Render a slider-style read-only parameter display.
let paramRow = (label: string, value: float, maxVal: float): Tea_Vdom.t<msg> => {
  let pct = value /. maxVal *. 100.0
  div(
    list{Attrs.class_("flex items-center gap-3 py-1")},
    list{
      span(list{Attrs.class_("text-xs text-gray-400 w-28")}, list{text(label)}),
      div(
        list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_("h-full bg-indigo-500 transition-all"),
              Attrs.style("width", Float.toFixed(pct, ~digits=1) ++ "%"),
            },
            list{},
          ),
        },
      ),
      span(list{Attrs.class_("text-xs text-gray-500 w-12 text-right font-mono")}, list{text(Float.toFixed(value, ~digits=2))}),
    },
  )
}

/// Main view function for the Generator Mode panel.
let view = (state: generatorModeState): Tea_Vdom.t<msg> => {
  let districtCount = switch state.currentSpec {
  | Some(spec) => Array.length(spec.districts)
  | None => 0
  }

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Generator Mode — Parametric World Builder"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-bold text-indigo-300")}, list{text("Generator Mode")}),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(Int.toString(districtCount) ++ " districts")},
              ),
              if state.generating {
                span(list{Attrs.class_("text-xs text-yellow-400 animate-pulse")}, list{text("Generating...")})
              } else {
                Tea_Html.noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-indigo-800 hover:bg-indigo-700 text-white rounded"),
              Events.onClick(GeneratorMode(GenStarted)),
            },
            list{text("Generate")},
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
                if state.activeTab == Design { "bg-indigo-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GeneratorMode(SetGenCategory(Design))),
            },
            list{text("Design")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Parameters { "bg-indigo-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GeneratorMode(SetGenCategory(Parameters))),
            },
            list{text("Parameters")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Preview { "bg-indigo-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GeneratorMode(SetGenCategory(Preview))),
            },
            list{text("Preview")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Export { "bg-indigo-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(GeneratorMode(SetGenCategory(Export))),
            },
            list{text("Export")},
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
              list{Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"), Events.onClick(GeneratorMode(DismissGenError))},
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
          | Design =>
            switch state.currentSpec {
            | Some(spec) =>
              div(
                list{Attrs.class_("space-y-3")},
                list{
                  div(list{Attrs.class_("text-sm text-indigo-300 font-bold mb-2")}, list{text(spec.name)}),
                  div(
                    list{},
                    spec.districts
                    ->Array.map(d =>
                      div(
                        list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded mb-2")},
                        list{
                          div(
                            list{Attrs.class_("flex items-center justify-between mb-1")},
                            list{
                              span(list{Attrs.class_("text-sm text-gray-200")}, list{text(districtTypeLabel(d.districtType))}),
                              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Size: " ++ d.sizeHint)}),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex flex-wrap gap-1")},
                            d.facilities
                            ->Array.map(f =>
                              span(
                                list{Attrs.class_("px-2 py-0.5 text-xs bg-gray-800 text-gray-300 rounded")},
                                list{text(f.facilityType ++ " x" ++ Int.toString(f.count))},
                              )
                            )
                            ->List.fromArray,
                          ),
                        },
                      )
                    )
                    ->List.fromArray,
                  ),
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("No world specification loaded. Create a new design to begin.")},
              )
            }
          | Parameters =>
            div(
              list{Attrs.class_("space-y-2")},
              list{
                h3(list{Attrs.class_("text-sm text-indigo-300 mb-2")}, list{text("Global Parameters")}),
                paramRow("Security", state.params.securityLevel, 1.0),
                paramRow("Tech Level", state.params.techLevel, 1.0),
                paramRow("Trap Density", state.params.trapDensity, 1.0),
                paramRow("Difficulty", state.params.difficultyTarget, 1.0),
                div(
                  list{Attrs.class_("flex gap-4 pt-2 text-xs text-gray-400")},
                  list{
                    span(list{}, list{text("Weather: " ++ weatherLabel(state.params.weatherCondition))}),
                    span(list{}, list{text("Time: " ++ timeLabel(state.params.timeOfDay))}),
                    span(list{}, list{text("Civilians: " ++ Int.toString(state.params.civilianPopulation))}),
                  },
                ),
              },
            )
          | Preview =>
            switch state.previewResult {
            | Some(result) =>
              div(
                list{Attrs.class_("space-y-3")},
                list{
                  div(
                    list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
                    list{
                      span(list{}, list{text("Entities: " ++ Int.toString(result.entityCount))}),
                      span(
                        list{Attrs.class_(if result.validationPassed { "text-green-400" } else { "text-red-400" })},
                        list{text(if result.validationPassed { "Validation passed" } else { "Validation failed" })},
                      ),
                      span(list{}, list{text("Generated: " ++ result.generatedAt)}),
                    },
                  ),
                  div(
                    list{Attrs.class_("bg-gray-900 border border-gray-800 rounded p-3 min-h-[200px]")},
                    list{
                      pre(
                        list{Attrs.class_("text-xs text-gray-300 font-mono whitespace-pre-wrap overflow-auto max-h-96")},
                        list{text(result.levelConfigJson)},
                      ),
                    },
                  ),
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("Generate a world to see the preview.")},
              )
            }
          | Export =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-400")},
                  list{text("Export the generated LevelConfig JSON for use in IDApTIK.")},
                ),
                switch state.previewResult {
                | Some(result) =>
                  div(
                    list{Attrs.class_("space-y-2")},
                    list{
                      div(
                        list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
                        list{
                          span(list{}, list{text("Entities: " ++ Int.toString(result.entityCount))}),
                          span(list{}, list{text("World: " ++ result.worldSpec.name)}),
                        },
                      ),
                      button(
                        list{Attrs.class_("px-4 py-2 bg-indigo-700 hover:bg-indigo-600 text-white rounded text-sm")},
                        list{text("Export LevelConfig JSON")},
                      ),
                    },
                  )
                | None =>
                  div(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{text("No generation result to export. Run the generator first.")},
                  )
                },
                // Saved templates
                if Array.length(state.templates) > 0 {
                  div(
                    list{Attrs.class_("pt-4 border-t border-gray-800")},
                    list{
                      h3(list{Attrs.class_("text-sm text-gray-300 mb-2")}, list{text("Saved Templates")}),
                      div(
                        list{Attrs.class_("space-y-1")},
                        state.templates
                        ->Array.map(t =>
                          div(
                            list{Attrs.class_("flex items-center gap-3 py-1 text-xs")},
                            list{
                              span(list{Attrs.class_("text-gray-300")}, list{text(t.name)}),
                              span(list{Attrs.class_("text-gray-500")}, list{text(Int.toString(Array.length(t.districts)) ++ " districts")}),
                            },
                          )
                        )
                        ->List.fromArray,
                      ),
                    },
                  )
                } else {
                  Tea_Html.noNode
                },
              },
            )
          },
        },
      ),
    },
  )
}
