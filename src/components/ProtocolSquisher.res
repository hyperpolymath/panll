// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Protocol-Squisher Component — format analysis and compatibility panel.
///
/// Analyse serialisation schemas across 13 formats, compare compatibility,
/// and view transport class classifications (Concorde/Business/Economy/Wheelbarrow).

open Model
open Msg
open Tea.Html

/// Render a transport class badge.
let renderTransportBadge = (tc: transportClass): Tea_Vdom.t<msg> => {
  let label = ProtocolSquisherEngine.transportClassLabel(tc)
  let colour = ProtocolSquisherEngine.transportClassColour(tc)
  span(list{Attrs.class_(`px-2 py-0.5 text-xs font-medium rounded ${colour}`)}, list{text(label)})
}

/// Render an analysis result card.
let renderAnalysisCard = (result: analysisResult): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 space-y-2")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(
            list{Attrs.class_("text-sm font-mono text-gray-300 truncate")},
            list{text(result.filePath)},
          ),
          renderTransportBadge(result.transportClass),
        },
      ),
      div(
        list{Attrs.class_("flex gap-4 text-xs text-gray-500")},
        list{
          span(list{}, list{text(ProtocolSquisherEngine.formatLabel(result.format))}),
          span(list{}, list{text(`${Int.toString(result.fieldCount)} fields`)}),
          span(list{}, list{text(`${Float.toFixed(result.overheadRatio, ~digits=2)}x overhead`)}),
          if result.hasRecursion {
            span(list{Attrs.class_("text-amber-500")}, list{text("recursive")})
          } else {
            noNode
          },
        },
      ),
      div(list{Attrs.class_("text-sm text-gray-400")}, list{text(result.summary)}),
    },
  )
}

/// Render category tabs.
let renderTabs = (active: protocolSquisherCategory): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    ProtocolSquisherEngine.allCategories
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-cyan-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(ProtocolSquisher(SetPsCategory(tab))),
        },
        list{text(ProtocolSquisherEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Render TypeLL cross-panel type intelligence result (if available).
/// Parses the raw JSON via TypeLLEngine.parseCheckResult and displays an
/// evangeliser-style narrative with proof obligations and linearity notes.
let viewTypeCheckResult = (lastTypeCheck: option<string>): Tea_Vdom.t<msg> => {
  switch lastTypeCheck {
  | None => noNode
  | Some(json) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Error(_) => noNode
    | Ok(result) =>
      let narrative = TypeLLEngine.generateNarrative(result)
      let borderColour = if result.valid {
        "border-green-700 bg-green-900/20"
      } else {
        "border-red-700 bg-red-900/20"
      }
      let labelColour = if result.valid {
        "text-green-400"
      } else {
        "text-red-400"
      }
      let statusText = if result.valid {
        "Type-safe"
      } else {
        "Type issues detected"
      }
      div(
        list{Attrs.class_("mt-4 p-3 rounded-lg border " ++ borderColour)},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-2")},
            list{
              span(
                list{Attrs.class_("text-xs font-bold uppercase tracking-wider " ++ labelColour)},
                list{text("TypeLL")},
              ),
              span(list{Attrs.class_("text-xs text-gray-400")}, list{text(statusText)}),
            },
          ),
          div(
            list{Attrs.class_("text-sm text-gray-300 font-mono mb-1")},
            list{text(result.typeSignature)},
          ),
          div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text(narrative.celebrate)}),
          if Array.length(result.proofObligations) > 0 {
            div(
              list{Attrs.class_("text-xs text-yellow-400 mt-1")},
              list{text("Proof obligations: " ++ Array.join(result.proofObligations, ", "))},
            )
          } else {
            noNode
          },
          if Array.length(result.linearityIssues) > 0 {
            div(
              list{Attrs.class_("text-xs text-orange-400 mt-1")},
              list{text("Linearity: " ++ Array.join(result.linearityIssues, ", "))},
            )
          } else {
            noNode
          },
        },
      )
    }
  }
}

/// Main view for the Protocol-Squisher panel.
let view = (ps: protocolSquisherState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Protocol-Squisher format analysis panel"),
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
                list{text("Protocol-Squisher")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("13-format schema analysis")},
              ),
              if ps.cliAvailable {
                span(list{Attrs.class_("text-xs text-emerald-500")}, list{text("CLI ready")})
              } else {
                span(list{Attrs.class_("text-xs text-amber-500")}, list{text("CLI not found")})
              },
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
          renderTabs(ps.activeCategory),
          switch ps.activeCategory {
          | PsAnalyse =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-400 mb-2")},
                  list{text("Enter a schema file path to analyse:")},
                ),
                div(
                  list{Attrs.class_("flex gap-2")},
                  list{
                    input(
                      list{
                        Attrs.class_(
                          "flex-1 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600 font-mono",
                        ),
                        Attrs.placeholder("/path/to/schema.proto"),
                        Attrs.value(ps.analyseInput),
                        Events.onInput(v => ProtocolSquisher(SetAnalyseInput(v))),
                      },
                      list{},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          "px-4 py-2 text-sm bg-cyan-600 text-white rounded hover:bg-cyan-500 disabled:opacity-50",
                        ),
                        Events.onClick(ProtocolSquisher(RunAnalysis)),
                        KeyboardNav.onActivate(ProtocolSquisher(RunAnalysis)),
                      },
                      list{text("Analyse")},
                    ),
                  },
                ),
                switch ps.lastAnalysis {
                | Some(result) => renderAnalysisCard(result)
                | None => noNode
                },
                viewTypeCheckResult(ps.lastTypeCheck),
              },
            )
          | PsCompare =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-400 mb-2")},
                  list{text("Compare two schema files for compatibility:")},
                ),
                div(
                  list{Attrs.class_("flex gap-2")},
                  list{
                    input(
                      list{
                        Attrs.class_(
                          "flex-1 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600 font-mono",
                        ),
                        Attrs.placeholder("Left schema path"),
                        Attrs.value(ps.compareLeftInput),
                        Events.onInput(v => ProtocolSquisher(SetCompareLeft(v))),
                      },
                      list{},
                    ),
                    input(
                      list{
                        Attrs.class_(
                          "flex-1 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600 font-mono",
                        ),
                        Attrs.placeholder("Right schema path"),
                        Attrs.value(ps.compareRightInput),
                        Events.onInput(v => ProtocolSquisher(SetCompareRight(v))),
                      },
                      list{},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          "px-4 py-2 text-sm bg-cyan-600 text-white rounded hover:bg-cyan-500",
                        ),
                        Events.onClick(ProtocolSquisher(RunComparison)),
                        KeyboardNav.onActivate(ProtocolSquisher(RunComparison)),
                      },
                      list{text("Compare")},
                    ),
                  },
                ),
                switch ps.lastComparison {
                | Some(cmp) =>
                  div(
                    list{
                      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 space-y-2"),
                    },
                    list{
                      div(
                        list{Attrs.class_("flex items-center gap-2")},
                        list{
                          span(
                            list{
                              Attrs.class_(
                                if cmp.compatible {
                                  "text-emerald-400 text-sm"
                                } else {
                                  "text-red-400 text-sm"
                                },
                              ),
                            },
                            list{
                              text(
                                if cmp.compatible {
                                  "Compatible"
                                } else {
                                  "Incompatible"
                                },
                              ),
                            },
                          ),
                          span(
                            list{Attrs.class_("text-xs text-gray-500")},
                            list{text(`Adapter cost: ${Int.toString(cmp.adapterCost)}/10`)},
                          ),
                        },
                      ),
                      div(list{Attrs.class_("text-sm text-gray-400")}, list{text(cmp.notes)}),
                    },
                  )
                | None => noNode
                },
              },
            )
          | PsResults =>
            if ps.analysisHistory->Array.length === 0 {
              div(
                list{Attrs.class_("text-center text-gray-500 mt-8")},
                list{text("No analysis results yet. Run an analysis first.")},
              )
            } else {
              div(
                list{Attrs.class_("space-y-3")},
                ps.analysisHistory->Array.map(r => renderAnalysisCard(r))->List.fromArray,
              )
            }
          | PsGuide =>
            div(
              list{Attrs.class_("space-y-4 text-sm text-gray-400 max-w-2xl")},
              list{
                h3(
                  list{Attrs.class_("text-base font-medium text-gray-200")},
                  list{text("Transport Class Guide")},
                ),
                div(
                  list{Attrs.class_("space-y-3")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        renderTransportBadge(Concorde),
                        text("Zero-copy, fixed-size fields, no allocation. Best wire efficiency."),
                      },
                    ),
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        renderTransportBadge(Business),
                        text("Binary format, schema-driven, minimal overhead."),
                      },
                    ),
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        renderTransportBadge(Economy),
                        text("Text-based or self-describing. Readable but slower."),
                      },
                    ),
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        renderTransportBadge(Wheelbarrow),
                        text("Format requires full runtime, significant overhead."),
                      },
                    ),
                  },
                ),
                h3(
                  list{Attrs.class_("text-base font-medium text-gray-200 mt-6")},
                  list{text("Supported Formats")},
                ),
                div(
                  list{Attrs.class_("grid grid-cols-3 gap-2")},
                  ProtocolSquisherEngine.allFormats
                  ->Array.map(fmt =>
                    span(
                      list{Attrs.class_("text-gray-300")},
                      list{text(ProtocolSquisherEngine.formatLabel(fmt))},
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          },
          switch ps.error {
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
