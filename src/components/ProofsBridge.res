// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Proofs Bridge Component — proven repo formal verification integration.
/// Displays proven module list with proof coverage bars, verification result
/// badges, and overall coverage percentage.

open Model
open Msg
open Tea.Html

/// Render a module verification status badge.
let moduleStatusBadge = (status: moduleVerificationStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | FullyProven => ("bg-green-700 text-green-100", "Fully Proven")
  | PartiallyProven => ("bg-yellow-700 text-yellow-100", "Partial")
  | Unverified => ("bg-gray-700 text-gray-300", "Unverified")
  | Stale => ("bg-orange-700 text-orange-100", "Stale")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Render a verification result kind badge.
let verificationKindBadge = (kind: verificationResultKind): Tea_Vdom.t<msg> => {
  let (color, label) = switch kind {
  | VerificationProved => ("text-green-400", "Proved")
  | VerificationCounterexample => ("text-red-400", "Counterexample")
  | VerificationTimeout => ("text-yellow-400", "Timeout")
  | VerificationError => ("text-red-500", "Error")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Main view function for the Proofs Bridge panel.
let view = (state: proofsBridgeState): Tea_Vdom.t<msg> => {
  let totalModules = Array.length(state.provenModules)
  let fullyProvenCount =
    state.provenModules->Array.filter(m => m.status == FullyProven)->Array.length

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Proofs Bridge — Proven Repo Formal Verification"),
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
                list{Attrs.class_("text-lg font-bold text-lime-300")},
                list{text("Proofs Bridge")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(fullyProvenCount) ++
                    "/" ++
                    Int.toString(totalModules) ++ " fully proven",
                  ),
                },
              ),
              // Overall coverage percentage
              span(
                list{
                  Attrs.class_(
                    "text-xs font-bold " ++ if state.coveragePercent >= 80.0 {
                      "text-green-400"
                    } else if state.coveragePercent >= 50.0 {
                      "text-yellow-400"
                    } else {
                      "text-red-400"
                    },
                  ),
                },
                list{text(Float.toFixed(state.coveragePercent, ~digits=1) ++ "% coverage")},
              ),
              if state.verifying {
                span(
                  list{Attrs.class_("text-xs text-yellow-400 animate-pulse")},
                  list{text("Verifying...")},
                )
              } else {
                Tea_Html.noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-lime-800 hover:bg-lime-700 text-white rounded"),
              Events.onClick(ProofsBridge(PrBStarted)),
            },
            list{text("Verify All")},
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
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Modules {
                  "bg-lime-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProofsBridge(SetPrBTab(Modules))),
            },
            list{text("Modules")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Proofs {
                  "bg-lime-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProofsBridge(SetPrBTab(Proofs))),
            },
            list{text("Proofs")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Coverage {
                  "bg-lime-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProofsBridge(SetPrBTab(Coverage))),
            },
            list{text("Coverage")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Verification {
                  "bg-lime-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProofsBridge(SetPrBTab(Verification))),
            },
            list{text("Verification")},
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
                Events.onClick(ProofsBridge(DismissPrBError)),
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
          | Modules =>
            div(
              list{Attrs.class_("space-y-2")},
              state.provenModules
              ->Array.map(m => {
                let coveragePct = if m.functionCount > 0 {
                  Int.toFloat(m.provedCount) /. Int.toFloat(m.functionCount) *. 100.0
                } else {
                  0.0
                }
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between mb-1")},
                      list{
                        div(
                          list{Attrs.class_("flex items-center gap-2")},
                          list{
                            span(
                              list{Attrs.class_("text-sm font-bold text-lime-300")},
                              list{text(m.name)},
                            ),
                            moduleStatusBadge(m.status),
                          },
                        ),
                        span(
                          list{Attrs.class_("text-xs text-gray-400")},
                          list{
                            text(
                              Int.toString(m.provedCount) ++
                              "/" ++
                              Int.toString(m.functionCount) ++ " proved",
                            ),
                          },
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mb-2")},
                      list{text(m.description)},
                    ),
                    // Proof coverage bar (green fill)
                    div(
                      list{Attrs.class_("w-full h-2 bg-gray-800 rounded overflow-hidden")},
                      list{
                        div(
                          list{
                            Attrs.class_("h-full bg-green-500 transition-all"),
                            Attrs.style("width", Float.toFixed(coveragePct, ~digits=1) ++ "%"),
                          },
                          list{},
                        ),
                      },
                    ),
                  },
                )
              })
              ->List.fromArray,
            )
          | Proofs =>
            div(
              list{Attrs.class_("space-y-1")},
              state.verificationResults
              ->Array.map(r =>
                div(
                  list{Attrs.class_("py-2 border-b border-gray-800/50")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        verificationKindBadge(r.kind),
                        span(
                          list{Attrs.class_("text-sm text-gray-200 font-mono")},
                          list{text(r.moduleName ++ "." ++ r.functionName)},
                        ),
                        span(list{Attrs.class_("text-xs text-gray-500")}, list{text(r.proverUsed)}),
                        span(
                          list{Attrs.class_("text-xs text-gray-600")},
                          list{text(Float.toFixed(r.durationMs, ~digits=0) ++ "ms")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-400 font-mono mt-1")},
                      list{text(r.specification)},
                    ),
                    switch r.counterexample {
                    | Some(ce) =>
                      div(
                        list{Attrs.class_("text-xs text-red-400 mt-1")},
                        list{text("Counterexample: " ++ ce)},
                      )
                    | None => Tea_Html.noNode
                    },
                    switch r.errorMessage {
                    | Some(e) =>
                      div(
                        list{Attrs.class_("text-xs text-red-400 mt-1")},
                        list{text("Error: " ++ e)},
                      )
                    | None => Tea_Html.noNode
                    },
                  },
                )
              )
              ->List.fromArray,
            )
          | Coverage =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                // Overall coverage display
                div(
                  list{Attrs.class_("text-center py-4")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          "text-4xl font-bold " ++ if state.coveragePercent >= 80.0 {
                            "text-green-400"
                          } else if state.coveragePercent >= 50.0 {
                            "text-yellow-400"
                          } else {
                            "text-red-400"
                          },
                        ),
                      },
                      list{text(Float.toFixed(state.coveragePercent, ~digits=1) ++ "%")},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mt-1")},
                      list{text("Overall proof coverage")},
                    ),
                  },
                ),
                // Per-module coverage bars
                div(
                  list{Attrs.class_("space-y-2")},
                  state.provenModules
                  ->Array.map(m => {
                    let pct = if m.functionCount > 0 {
                      Int.toFloat(m.provedCount) /. Int.toFloat(m.functionCount) *. 100.0
                    } else {
                      0.0
                    }
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        span(
                          list{Attrs.class_("text-xs text-gray-300 w-24 truncate")},
                          list{text(m.name)},
                        ),
                        div(
                          list{Attrs.class_("flex-1 h-3 bg-gray-800 rounded overflow-hidden")},
                          list{
                            div(
                              list{
                                Attrs.class_("h-full bg-green-500"),
                                Attrs.style("width", Float.toFixed(pct, ~digits=1) ++ "%"),
                              },
                              list{},
                            ),
                          },
                        ),
                        span(
                          list{Attrs.class_("text-xs text-gray-500 w-12 text-right")},
                          list{text(Float.toFixed(pct, ~digits=0) ++ "%")},
                        ),
                      },
                    )
                  })
                  ->List.fromArray,
                ),
              },
            )
          | Verification =>
            div(
              list{Attrs.class_("space-y-3")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-400 mb-2")},
                  list{
                    text(
                      Int.toString(
                        Array.length(state.verificationResults),
                      ) ++ " verification results",
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("space-y-1")},
                  state.verificationResults
                  ->Array.filter(r => r.kind != VerificationProved)
                  ->Array.map(r =>
                    div(
                      list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                      list{
                        div(
                          list{Attrs.class_("flex items-center gap-2")},
                          list{
                            verificationKindBadge(r.kind),
                            span(
                              list{Attrs.class_("text-sm text-gray-200 font-mono")},
                              list{text(r.moduleName ++ "." ++ r.functionName)},
                            ),
                          },
                        ),
                        div(
                          list{Attrs.class_("text-xs text-gray-500 mt-1")},
                          list{text(r.specification)},
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
