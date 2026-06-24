// SPDX-License-Identifier: MPL-2.0

/// PanLL Typing Bridge Component — TypeLL type constraints for IDApTIK game
/// state. Displays constraint lists, inference results, a typed configuration
/// editor, and diagnostic messages.

open Model
open Msg
open Tea.Html

/// Render a severity badge for a type constraint.
let severityBadge = (sev: constraintSeverity): Tea_Vdom.t<msg> => {
  let (color, label) = switch sev {
  | ConstraintError => ("bg-red-700 text-red-100", "Error")
  | ConstraintWarning => ("bg-yellow-700 text-yellow-100", "Warn")
  | ConstraintInfo => ("bg-blue-700 text-blue-100", "Info")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Render an inference status indicator.
let inferenceStatusBadge = (status: inferenceStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | InferenceSuccess => ("text-green-400", "OK")
  | InferencePartial => ("text-yellow-400", "Partial")
  | InferenceFailed => ("text-red-400", "Failed")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Main view function for the Typing Bridge panel.
let view = (state: typingBridgeState): Tea_Vdom.t<msg> => {
  let satisfiedCount = state.constraints->Array.filter(c => c.satisfied)->Array.length
  let totalCount = Array.length(state.constraints)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Typing Bridge — TypeLL Type Constraints"),
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
                list{Attrs.class_("text-lg font-bold text-cyan-300")},
                list{text("Typing Bridge")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(satisfiedCount) ++ "/" ++ Int.toString(totalCount) ++ " satisfied",
                  ),
                },
              ),
              if state.running {
                span(
                  list{Attrs.class_("text-xs text-yellow-400 animate-pulse")},
                  list{text("Checking...")},
                )
              } else {
                Tea_Html.noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-cyan-800 hover:bg-cyan-700 text-white rounded"),
              Events.onClick(TypingBridge(TbStarted)),
              KeyboardNav.onActivate(TypingBridge(TbStarted)),
            },
            list{text("Run Type Check")},
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
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Constraints {
                  "bg-cyan-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(TypingBridge(SetTbTab(Constraints))),
            },
            list{text("Constraints")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Inference {
                  "bg-cyan-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(TypingBridge(SetTbTab(Inference))),
            },
            list{text("Inference")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Editor {
                  "bg-cyan-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(TypingBridge(SetTbTab(Editor))),
            },
            list{text("Editor")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Diagnostics {
                  "bg-cyan-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(TypingBridge(SetTbTab(Diagnostics))),
            },
            list{text("Diagnostics")},
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center",
            ),
          },
          list{
            text(err),
            button(
              list{
                Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"),
                Events.onClick(TypingBridge(DismissTbError)),
                KeyboardNav.onActivate(TypingBridge(DismissTbError)),
              },
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
          | Constraints =>
            div(
              list{},
              state.constraints
              ->Array.map(c =>
                div(
                  list{Attrs.class_("flex items-center gap-3 py-2 border-b border-gray-800/50")},
                  list{
                    span(
                      list{
                        Attrs.class_(
                          "w-3 h-3 rounded-full " ++ if c.satisfied {
                            "bg-green-500"
                          } else {
                            "bg-red-500"
                          },
                        ),
                      },
                      list{},
                    ),
                    div(
                      list{Attrs.class_("flex-1 min-w-0")},
                      list{
                        div(
                          list{Attrs.class_("text-sm font-mono text-gray-200")},
                          list{text(c.name)},
                        ),
                        div(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(c.targetPath ++ " : " ++ c.typeExpression)},
                        ),
                      },
                    ),
                    severityBadge(c.severity),
                  },
                )
              )
              ->List.fromArray,
            )
          | Inference =>
            div(
              list{},
              state.inferenceResults
              ->Array.map(r =>
                div(
                  list{Attrs.class_("py-2 border-b border-gray-800/50")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        span(
                          list{Attrs.class_("text-sm font-mono text-gray-200")},
                          list{text(r.targetPath)},
                        ),
                        inferenceStatusBadge(r.status),
                        span(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(Float.toFixed(r.inferenceTimeMs, ~digits=1) ++ "ms")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("text-xs text-cyan-400 font-mono mt-1")},
                      list{text(r.inferredType)},
                    ),
                    if Array.length(r.suggestions) > 0 {
                      div(
                        list{Attrs.class_("flex flex-wrap gap-1 mt-1")},
                        r.suggestions
                        ->Array.map(s =>
                          span(
                            list{
                              Attrs.class_("px-2 py-0.5 text-xs bg-gray-800 text-gray-400 rounded"),
                            },
                            list{text(s)},
                          )
                        )
                        ->List.fromArray,
                      )
                    } else {
                      Tea_Html.noNode
                    },
                  },
                )
              )
              ->List.fromArray,
            )
          | Editor =>
            div(
              list{},
              state.configFields
              ->Array.map(f =>
                div(
                  list{Attrs.class_("flex items-center gap-3 py-2 border-b border-gray-800/50")},
                  list{
                    span(
                      list{
                        Attrs.class_(
                          "w-2 h-2 rounded-full " ++ if f.valid {
                            "bg-green-500"
                          } else {
                            "bg-red-500"
                          },
                        ),
                      },
                      list{},
                    ),
                    div(
                      list{Attrs.class_("flex-1 min-w-0")},
                      list{
                        div(
                          list{Attrs.class_("text-sm font-mono text-gray-300")},
                          list{text(f.path)},
                        ),
                        div(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text("Expected: " ++ f.expectedType)},
                        ),
                      },
                    ),
                    span(
                      list{Attrs.class_("text-sm font-mono text-cyan-300")},
                      list{text(f.currentValue)},
                    ),
                    switch f.validationMessage {
                    | Some(msg_text) =>
                      span(list{Attrs.class_("text-xs text-red-400")}, list{text(msg_text)})
                    | None => Tea_Html.noNode
                    },
                  },
                )
              )
              ->List.fromArray,
            )
          | Diagnostics =>
            div(
              list{},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-3")},
                  list{
                    text(
                      Int.toString(totalCount) ++
                      " constraints, " ++
                      Int.toString(satisfiedCount) ++
                      " satisfied, " ++
                      Int.toString(totalCount - satisfiedCount) ++ " violations",
                    ),
                  },
                ),
                div(
                  list{},
                  state.constraints
                  ->Array.filter(c => !c.satisfied)
                  ->Array.map(c =>
                    div(
                      list{
                        Attrs.class_(
                          "px-3 py-2 mb-2 bg-red-900/30 border border-red-800/50 rounded",
                        ),
                      },
                      list{
                        div(
                          list{Attrs.class_("flex items-center gap-2")},
                          list{
                            severityBadge(c.severity),
                            span(
                              list{Attrs.class_("text-sm text-red-200 font-mono")},
                              list{text(c.name)},
                            ),
                          },
                        ),
                        div(
                          list{Attrs.class_("text-xs text-gray-400 mt-1")},
                          list{text(c.description)},
                        ),
                        div(
                          list{Attrs.class_("text-xs text-gray-500 mt-1")},
                          list{text(c.targetPath ++ " : " ++ c.typeExpression)},
                        ),
                      },
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          },
        },
      ),
    },
  )
}
