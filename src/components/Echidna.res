// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ECHIDNA Component — multi-solver theorem prover dispatch panel.
///
/// Two tabs:
///   - Proof Workbench: interactive proof sessions, tactic suggestions, dispatch
///   - Enterprise Model: MOF/OCL/ArchiMate model constraint checking

open Model
open Msg
open Tea.Html

/// Render a trust level badge.
let trustBadge = (level: echidnaTrustLevel): Tea_Vdom.t<msg> => {
  let (color, label) = switch level {
  | TrustLevel1 => ("text-red-400", "L1")
  | TrustLevel2 => ("text-yellow-400", "L2")
  | TrustLevel3 => ("text-blue-400", "L3")
  | TrustLevel4 => ("text-green-400", "L4")
  | TrustLevel5 => ("text-green-300 font-bold", "L5")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Main view function for the ECHIDNA panel.
let view = (state: echidnaState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("ECHIDNA — Multi-Solver Theorem Prover"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-bold text-purple-300")}, list{text("ECHIDNA")}),
              span(
                list{Attrs.class_("text-xs " ++ if state.connected { "text-green-400" } else { "text-red-400" })},
                list{text(if state.connected { "Connected" } else { "Disconnected" })},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded " ++
                    if state.activeTab == EchidnaProofTab { "bg-purple-700 text-white" } else { "bg-gray-800 text-gray-400" },
                  ),
                  Events.onClick(Echidna(SelectEchidnaTab(EchidnaProofTab))),
                },
                list{text("Proof Workbench")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded " ++
                    if state.activeTab == EchidnaEnterpriseTab { "bg-purple-700 text-white" } else { "bg-gray-800 text-gray-400" },
                  ),
                  Events.onClick(Echidna(SelectEchidnaTab(EchidnaEnterpriseTab))),
                },
                list{text("Enterprise Model")},
              ),
            },
          ),
        },
      ),
      // Prover catalog summary
      div(
        list{Attrs.class_("flex gap-4 px-4 py-2 text-xs text-gray-400 border-b border-gray-800")},
        list{
          span(list{}, list{text("Provers: " ++ Int.toString(Array.length(state.provers)))}),
          switch state.version {
          | Some(v) => span(list{}, list{text("Version: " ++ v)})
          | None => Tea_Html.noNode
          },
          switch state.lastProofResult {
          | Some(r) =>
            span(list{Attrs.class_("flex items-center gap-1")}, list{
              text("Last: "),
              trustBadge(r.trustLevel),
              text(if r.verified { " verified" } else { " unverified" }),
            })
          | None => span(list{}, list{text("No proofs yet")})
          },
        },
      ),
      // Error banner
      switch state.proofError {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200")},
          list{text(err)},
        )
      | None => Tea_Html.noNode
      },
      // Content placeholder
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-4")},
        list{
          switch state.activeTab {
          | EchidnaProofTab =>
            div(
              list{},
              list{
                // Proof input area
                div(
                  list{Attrs.class_("mb-4")},
                  list{
                    label(list{Attrs.class_("text-xs text-gray-400 block mb-1")}, list{text("Proof Obligation")}),
                    textarea(
                      list{
                        Attrs.class_("w-full h-40 bg-gray-900 border border-gray-700 rounded p-2 text-sm text-gray-200 font-mono"),
                        Attrs.value(state.proofInput),
                        Attrs.placeholder("Enter proof obligation..."),
                      },
                      list{},
                    ),
                  },
                ),
                // Tactic suggestions
                if Array.length(state.tacticSuggestions) > 0 {
                  div(
                    list{Attrs.class_("mb-4")},
                    list{
                      h3(list{Attrs.class_("text-sm text-gray-300 mb-2")}, list{text("Tactic Suggestions")}),
                      div(
                        list{Attrs.class_("flex flex-wrap gap-2")},
                        state.tacticSuggestions
                        ->Array.map(s =>
                          span(
                            list{Attrs.class_("px-2 py-1 text-xs bg-purple-900/50 border border-purple-700 rounded cursor-pointer hover:bg-purple-800")},
                            list{text(s.tactic ++ " (" ++ Float.toFixed(s.confidence *. 100.0, ~digits=0) ++ "%)")},
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
          | EchidnaEnterpriseTab =>
            div(
              list{Attrs.class_("text-center text-gray-500 py-8")},
              list{text("MOF/OCL enterprise model checking — load XMI models and verify OCL constraints.")},
            )
          },
        },
      ),
    },
  )
}
