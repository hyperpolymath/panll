// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CompatibilityMatrix — browser/device cross-testing matrix with
/// pass/fail/untested cell colouring and failure detail drill-down.
///
/// Four tabs: Matrix (grid layout with coloured cells), Failures (detail view
/// of failing cells), Screenshots (captured evidence), and Targets (browser
/// and device configuration).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for compatibilityTab variants.
let tabLabel = (tab: compatibilityTab): string =>
  switch tab {
  | TabMatrix => "Matrix"
  | TabFailures => "Failures"
  | TabScreenshots => "Screenshots"
  | TabTargets => "Targets"
  }

/// Render the tab bar.
let renderTabs = (active: compatibilityTab): Tea_Vdom.t<msg> => {
  let tabs: array<compatibilityTab> = [TabMatrix, TabFailures, TabScreenshots, TabTargets]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(CompatibilityMatrix(SetCmTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Cell background colour based on compatibility result.
let cellColour = (result: compatResult): string =>
  switch result {
  | CompatPassing => "bg-emerald-700"
  | CompatFailing(_) => "bg-red-700"
  | CompatWarning(_) => "bg-amber-700"
  | CompatUntested => "bg-gray-700"
  | CompatSkipped(_) => "bg-gray-600"
  }

/// Cell short label for the matrix grid.
let cellLabel = (result: compatResult): string =>
  switch result {
  | CompatPassing => "OK"
  | CompatFailing(_) => "FAIL"
  | CompatWarning(_) => "WARN"
  | CompatUntested => "--"
  | CompatSkipped(_) => "SKIP"
  }

// =========================================================================
// Tab content views
// =========================================================================

/// Matrix tab: grid of browsers (columns) x devices (rows) with coloured cells.
let renderMatrixTab = (state: compatibilityMatrixState): Tea_Vdom.t<msg> => {
  let browserCount = Array.length(state.browsers)
  let deviceCount = Array.length(state.devices)
  let passing =
    state.cells
    ->Array.filter(c =>
      switch c.result {
      | CompatPassing => true
      | _ => false
      }
    )
    ->Array.length
  let failing =
    state.cells
    ->Array.filter(c =>
      switch c.result {
      | CompatFailing(_) => true
      | _ => false
      }
    )
    ->Array.length
  let totalCells = Array.length(state.cells)

  div(
    list{Attrs.class_("flex flex-col gap-3 p-4")},
    list{
      // Summary
      div(
        list{Attrs.class_("flex gap-4 text-sm")},
        list{
          span(
            list{Attrs.class_("text-gray-400")},
            list{
              text(
                `${Int.toString(browserCount)} browser(s) x ${Int.toString(deviceCount)} device(s) = ${Int.toString(totalCells)} cell(s)`,
              ),
            },
          ),
          span(list{Attrs.class_("text-emerald-400")}, list{text(`${Int.toString(passing)} pass`)}),
          span(list{Attrs.class_("text-red-400")}, list{text(`${Int.toString(failing)} fail`)}),
        },
      ),
      // Matrix header row (browser names)
      div(
        list{Attrs.class_("overflow-x-auto")},
        list{
          div(
            list{Attrs.class_("inline-flex flex-col gap-1 min-w-max")},
            list{
              // Header row
              div(
                list{Attrs.class_("flex gap-1")},
                list{
                  // Empty corner cell
                  div(list{Attrs.class_("w-28 h-8 flex-shrink-0")}, list{}),
                  // Browser column headers
                  fragment(
                    state.browsers
                    ->Array.map(browser => {
                      div(
                        list{
                          Attrs.class_(
                            "w-16 h-8 flex items-center justify-center text-xs text-gray-400 font-mono",
                          ),
                        },
                        list{text(browser.name)},
                      )
                    })
                    ->List.fromArray,
                  ),
                },
              ),
              // Device rows with cells
              fragment(
                state.devices
                ->Array.map(device => {
                  div(
                    list{Attrs.class_("flex gap-1")},
                    list{
                      // Device label
                      div(
                        list{
                          Attrs.class_(
                            "w-28 h-8 flex items-center text-xs text-gray-400 font-mono flex-shrink-0 truncate",
                          ),
                        },
                        list{text(device.name)},
                      ),
                      // Matrix cells for this device
                      fragment(
                        state.browsers
                        ->Array.map(browser => {
                          let cell =
                            state.cells->Array.find(c =>
                              c.browser.name === browser.name && c.device.name === device.name
                            )
                          let result = switch cell {
                          | Some(c) => c.result
                          | None => CompatUntested
                          }
                          div(
                            list{
                              Attrs.class_(
                                `w-16 h-8 flex items-center justify-center rounded text-xs text-white font-mono cursor-pointer hover:opacity-80 ${cellColour(result)}`,
                              ),
                              Events.onClick(
                                CompatibilityMatrix(SelectCell(browser.name, device.name)),
                              ),
                            },
                            list{text(cellLabel(result))},
                          )
                        })
                        ->List.fromArray,
                      ),
                    },
                  )
                })
                ->List.fromArray,
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Failures tab: detail view of failing cells with error messages.
let renderFailuresTab = (state: compatibilityMatrixState): Tea_Vdom.t<msg> => {
  let failures =
    state.cells->Array.filter(c =>
      switch c.result {
      | CompatFailing(_) => true
      | _ => false
      }
    )
  if Array.length(failures) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No failures detected. All tested cells are passing.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
      failures
      ->Array.map(cell => {
        let errMsg = switch cell.result {
        | CompatFailing(msg) => msg
        | _ => ""
        }
        div(
          list{Attrs.class_("bg-gray-800 rounded p-3 border border-red-800")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-2")},
              list{
                span(
                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                  list{text(`${cell.browser.name} / ${cell.device.name}`)},
                ),
                span(
                  list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-red-600 text-white font-mono")},
                  list{text("FAIL")},
                ),
              },
            ),
            div(
              list{Attrs.class_("text-xs text-red-300 font-mono whitespace-pre-wrap")},
              list{text(errMsg)},
            ),
            if cell.notes !== "" {
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-2")},
                list{text(`Notes: ${cell.notes}`)},
              )
            } else {
              noNode
            },
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Screenshots tab: grid of captured evidence images.
let renderScreenshotsTab = (state: compatibilityMatrixState): Tea_Vdom.t<msg> => {
  let withScreenshots = state.cells->Array.filter(c => Option.isSome(c.screenshotPath))
  if Array.length(withScreenshots) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No screenshots captured yet. Run tests to generate evidence.")},
    )
  } else {
    div(
      list{Attrs.class_("grid grid-cols-3 gap-3 p-4 max-h-96 overflow-y-auto")},
      withScreenshots
      ->Array.map(cell => {
        div(
          list{Attrs.class_("bg-gray-800 rounded p-2 border border-gray-700")},
          list{
            div(
              list{Attrs.class_("bg-gray-900 rounded h-24 flex items-center justify-center mb-2")},
              list{
                span(list{Attrs.class_("text-gray-600 text-xs")}, list{text("[screenshot]")}),
              },
            ),
            div(
              list{Attrs.class_("text-xs text-gray-400 text-center")},
              list{text(`${cell.browser.name} / ${cell.device.name}`)},
            ),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Targets tab: browser and device configuration lists.
let renderTargetsTab = (state: compatibilityMatrixState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      // Browsers
      div(
        list{Attrs.class_("flex flex-col gap-2")},
        list{
          h3(
            list{Attrs.class_("text-sm font-medium text-gray-300")},
            list{text(`Browsers (${Int.toString(Array.length(state.browsers))})`)},
          ),
          div(
            list{Attrs.class_("flex flex-col gap-1")},
            state.browsers
            ->Array.map(browser => {
              div(
                list{Attrs.class_("flex items-center gap-3 px-3 py-2 bg-gray-800 rounded text-xs")},
                list{
                  span(
                    list{Attrs.class_("text-gray-300 font-medium")},
                    list{text(browser.name)},
                  ),
                  span(list{Attrs.class_("text-gray-500")}, list{text(`v${browser.version}`)}),
                  span(list{Attrs.class_("text-gray-600")}, list{text(browser.engine)}),
                },
              )
            })
            ->List.fromArray,
          ),
        },
      ),
      // Devices
      div(
        list{Attrs.class_("flex flex-col gap-2")},
        list{
          h3(
            list{Attrs.class_("text-sm font-medium text-gray-300")},
            list{text(`Devices (${Int.toString(Array.length(state.devices))})`)},
          ),
          div(
            list{Attrs.class_("flex flex-col gap-1")},
            state.devices
            ->Array.map(device => {
              let (w, h) = device.resolution
              div(
                list{Attrs.class_("flex items-center gap-3 px-3 py-2 bg-gray-800 rounded text-xs")},
                list{
                  span(
                    list{Attrs.class_("text-gray-300 font-medium")},
                    list{text(device.name)},
                  ),
                  span(list{Attrs.class_("text-gray-500")}, list{text(device.category)}),
                  span(
                    list{Attrs.class_("text-gray-600 font-mono")},
                    list{text(`${Int.toString(w)}x${Int.toString(h)} @${Float.toFixed(device.pixelRatio, ~digits=0)}x`)},
                  ),
                },
              )
            })
            ->List.fromArray,
          ),
        },
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: compatibilityMatrixState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabMatrix => renderMatrixTab(state)
  | TabFailures => renderFailuresTab(state)
  | TabScreenshots => renderScreenshotsTab(state)
  | TabTargets => renderTargetsTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header with Run All
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Compatibility Matrix")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
              ),
              Events.onClick(CompatibilityMatrix(RunAll)),
            },
            list{text("Run All")},
          ),
        },
      ),
      // Running indicator
      if state.running {
        div(
          list{Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700")},
          list{
            div(list{Attrs.class_("w-3 h-3 bg-amber-400 rounded-full animate-pulse")}, list{}),
            span(
              list{Attrs.class_("text-sm text-amber-300")},
              list{text("Running compatibility tests...")},
            ),
          },
        )
      } else {
        noNode
      },
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800")},
          list{text(err)},
        )
      | None => noNode
      },
      // Tab bar
      renderTabs(state.activeTab),
      // Content
      div(list{Attrs.class_("flex-1 overflow-y-auto")}, list{content}),
    },
  )
}
