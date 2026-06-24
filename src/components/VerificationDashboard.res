// SPDX-License-Identifier: MPL-2.0

/// PanLL VerificationDashboard Component — proof/test/benchmark status panel.
///
/// Five tabs: Summary, By Language, Proofs, Benchmarks, Fuzzing.
/// Shows aggregated and per-language verification status across all
/// nextgen-languages repos.

open Model
open Msg
open Tea.Html

// ============================================================================
// Shared sub-views
// ============================================================================

/// Render category tabs.
let renderTabs = (active: verificationDashboardCategory): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    VerificationDashboardEngine.allCategories
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-violet-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(VerificationDashboard(SetVdCategory(tab))),
        },
        list{text(VerificationDashboardEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Render a summary stat card.
let renderStatCard = (label: string, value: string, colour: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 text-center")},
    list{
      div(list{Attrs.class_(`text-2xl font-mono ${colour}`)}, list{text(value)}),
      div(list{Attrs.class_("text-[10px] text-gray-500")}, list{text(label)}),
    },
  )
}

/// Render a proof system badge.
let renderProofBadge = (ps: VerificationDashboardModel.proofSystem): Tea_Vdom.t<msg> => {
  span(
    list{
      Attrs.class_(
        `px-1.5 py-0.5 text-[10px] rounded ${VerificationDashboardEngine.proofSystemColour(ps)}`,
      ),
    },
    list{text(VerificationDashboardEngine.proofSystemCode(ps))},
  )
}

/// Render a language verification row.
let renderLanguageRow = (status: VerificationDashboardModel.languageVerificationStatus): Tea_Vdom.t<
  msg,
> => {
  let rate = VerificationDashboardEngine.passRate(status)
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 p-2 border-b border-gray-800 hover:bg-gray-900/50 text-xs",
      ),
      Events.onClick(VerificationDashboard(SelectVdLanguage(Some(status.name)))),
    },
    list{
      div(list{Attrs.class_("w-28 text-gray-200 font-medium")}, list{text(status.name)}),
      div(
        list{Attrs.class_("w-16 text-right text-gray-300 font-mono")},
        list{text(Int.toString(status.totalTests))},
      ),
      div(
        list{Attrs.class_("w-16 text-right text-emerald-400 font-mono")},
        list{text(Int.toString(status.passingTests))},
      ),
      div(
        list{Attrs.class_("w-16 text-right text-red-400 font-mono")},
        list{text(Int.toString(status.failingTests))},
      ),
      div(
        list{
          Attrs.class_(
            `w-14 text-right font-mono ${VerificationDashboardEngine.passRateColour(rate)}`,
          ),
        },
        list{text(Int.toString(rate) ++ "%")},
      ),
      div(
        list{
          Attrs.class_(
            `w-14 text-right font-mono ${VerificationDashboardEngine.admittedColour(
                status.admittedCount,
              )}`,
          ),
        },
        list{text(Int.toString(status.admittedCount))},
      ),
      div(
        list{Attrs.class_("w-14 text-right text-violet-400 font-mono")},
        list{text(Int.toString(status.provedCount))},
      ),
      div(
        list{Attrs.class_("w-20 flex gap-0.5")},
        status.proofSystems->Array.map(renderProofBadge)->List.fromArray,
      ),
      div(
        list{
          Attrs.class_(
            `w-16 text-center ${VerificationDashboardEngine.conformanceColour(status.conformance)}`,
          ),
        },
        list{text(VerificationDashboardEngine.conformanceLabel(status.conformance))},
      ),
      div(
        list{Attrs.class_("w-10 text-center text-gray-500")},
        list{
          text(
            if status.fuzzing !== None {
              "Yes"
            } else {
              "-"
            },
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Main view for the VerificationDashboard panel.
let view = (vd: verificationDashboardState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("VerificationDashboard panel"),
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
                list{text("Verification Dashboard")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Proof / Test / Benchmark Status")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              input(
                list{
                  Attrs.class_(
                    "bg-gray-900 border border-gray-700 rounded px-3 py-1 text-sm text-gray-200 placeholder-gray-600 w-48",
                  ),
                  Attrs.placeholder("Filter languages..."),
                  Attrs.value(vd.filterText),
                  Events.onInput(v => VerificationDashboard(SetVdFilter(v))),
                },
                list{},
              ),
              button(
                list{
                  Attrs.class_(
                    `px-3 py-1 text-xs rounded ${vd.showDebtOnly
                        ? "bg-amber-600 text-white"
                        : "bg-gray-800 text-gray-400"}`,
                  ),
                  Events.onClick(VerificationDashboard(ToggleDebtOnly)),
                  KeyboardNav.onActivate(VerificationDashboard(ToggleDebtOnly)),
                },
                list{text("Debt Only")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700",
                  ),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                  KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          renderTabs(vd.activeCategory),
          {
            let data = VerificationDashboardEngine.allLanguageStatuses
            let filtered = {
              let searched = VerificationDashboardEngine.filterBySearch(data, vd.filterText)
              if vd.showDebtOnly {
                VerificationDashboardEngine.filterDebtOnly(searched)
              } else {
                searched
              }
            }
            let sorted = VerificationDashboardEngine.sortLanguages(filtered, vd.sortBy)
            switch vd.activeCategory {
            // ── Summary Tab ──
            | VdSummary => {
                let summary = VerificationDashboardEngine.computeSummary(data)
                div(
                  list{Attrs.class_("space-y-6")},
                  list{
                    // Stats grid
                    div(
                      list{Attrs.class_("grid grid-cols-4 gap-3")},
                      list{
                        renderStatCard(
                          "Languages",
                          Int.toString(summary.totalLanguages),
                          "text-teal-400",
                        ),
                        renderStatCard(
                          "Total Tests",
                          Int.toString(summary.totalTests),
                          "text-cyan-400",
                        ),
                        renderStatCard(
                          "Passing",
                          Int.toString(summary.totalPassing),
                          "text-emerald-400",
                        ),
                        renderStatCard(
                          "Failing",
                          Int.toString(summary.totalFailing),
                          if summary.totalFailing > 0 {
                            "text-red-400"
                          } else {
                            "text-emerald-400"
                          },
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-4 gap-3")},
                      list{
                        renderStatCard(
                          "Avg Pass Rate",
                          Int.toString(summary.avgPassRate) ++ "%",
                          VerificationDashboardEngine.passRateColour(summary.avgPassRate),
                        ),
                        renderStatCard(
                          "Proved",
                          Int.toString(summary.totalProved),
                          "text-violet-400",
                        ),
                        renderStatCard(
                          "Admitted/Sorry",
                          Int.toString(summary.totalAdmitted),
                          VerificationDashboardEngine.admittedColour(summary.totalAdmitted),
                        ),
                        renderStatCard(
                          "Full Conformance",
                          Int.toString(summary.languagesFullConformance) ++
                          "/" ++
                          Int.toString(summary.totalLanguages),
                          "text-emerald-400",
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-2 gap-3")},
                      list{
                        renderStatCard(
                          "With Fuzzing",
                          Int.toString(summary.languagesWithFuzzing),
                          "text-amber-400",
                        ),
                        renderStatCard(
                          "Formal Proofs",
                          Int.toString(summary.totalProved) ++
                          " proved, " ++
                          Int.toString(summary.totalAdmitted) ++ " admitted",
                          "text-violet-400",
                        ),
                      },
                    ),
                  },
                )
              }
            // ── By Language Tab ──
            | VdByLanguage =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  // Sort controls
                  div(
                    list{Attrs.class_("flex gap-2 items-center mb-2")},
                    list{
                      span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Sort by:")}),
                      button(
                        list{
                          Attrs.class_(
                            `px-2 py-1 text-xs rounded ${vd.sortBy === VdSortByName
                                ? "bg-violet-600 text-white"
                                : "bg-gray-800 text-gray-400"}`,
                          ),
                          Events.onClick(VerificationDashboard(SetVdSort(VdSortByName))),
                        },
                        list{text("Name")},
                      ),
                      button(
                        list{
                          Attrs.class_(
                            `px-2 py-1 text-xs rounded ${vd.sortBy === VdSortByTests
                                ? "bg-violet-600 text-white"
                                : "bg-gray-800 text-gray-400"}`,
                          ),
                          Events.onClick(VerificationDashboard(SetVdSort(VdSortByTests))),
                        },
                        list{text("Tests")},
                      ),
                      button(
                        list{
                          Attrs.class_(
                            `px-2 py-1 text-xs rounded ${vd.sortBy === VdSortByPassRate
                                ? "bg-violet-600 text-white"
                                : "bg-gray-800 text-gray-400"}`,
                          ),
                          Events.onClick(VerificationDashboard(SetVdSort(VdSortByPassRate))),
                        },
                        list{text("Pass Rate")},
                      ),
                      button(
                        list{
                          Attrs.class_(
                            `px-2 py-1 text-xs rounded ${vd.sortBy === VdSortByAdmitted
                                ? "bg-violet-600 text-white"
                                : "bg-gray-800 text-gray-400"}`,
                          ),
                          Events.onClick(VerificationDashboard(SetVdSort(VdSortByAdmitted))),
                        },
                        list{text("Admitted")},
                      ),
                    },
                  ),
                  // Table
                  div(
                    list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                    list{
                      // Header
                      div(
                        list{
                          Attrs.class_(
                            "flex items-center gap-3 p-2 bg-gray-800/50 border-b border-gray-700 text-[10px] text-gray-500 uppercase tracking-wide",
                          ),
                        },
                        list{
                          div(list{Attrs.class_("w-28")}, list{text("Language")}),
                          div(list{Attrs.class_("w-16 text-right")}, list{text("Total")}),
                          div(list{Attrs.class_("w-16 text-right")}, list{text("Pass")}),
                          div(list{Attrs.class_("w-16 text-right")}, list{text("Fail")}),
                          div(list{Attrs.class_("w-14 text-right")}, list{text("Rate")}),
                          div(list{Attrs.class_("w-14 text-right")}, list{text("Admit")}),
                          div(list{Attrs.class_("w-14 text-right")}, list{text("Proved")}),
                          div(list{Attrs.class_("w-20")}, list{text("Provers")}),
                          div(list{Attrs.class_("w-16 text-center")}, list{text("Conf")}),
                          div(list{Attrs.class_("w-10 text-center")}, list{text("Fuzz")}),
                        },
                      ),
                      div(
                        list{Attrs.class_("max-h-96 overflow-y-auto")},
                        sorted->Array.map(renderLanguageRow)->List.fromArray,
                      ),
                    },
                  ),
                },
              )
            // ── Proofs Tab ──
            | VdProofs => {
                let withProofs = data->Array.filter(s => s.provedCount > 0 || s.admittedCount > 0)
                div(
                  list{Attrs.class_("space-y-4")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-400 mb-2")},
                      list{
                        text(
                          "Formal verification status — proofs discharged vs admitted/sorry across all languages.",
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                      list{
                        div(
                          list{
                            Attrs.class_(
                              "flex items-center gap-3 p-2 bg-gray-800/50 border-b border-gray-700 text-[10px] text-gray-500 uppercase tracking-wide",
                            ),
                          },
                          list{
                            div(list{Attrs.class_("w-28")}, list{text("Language")}),
                            div(list{Attrs.class_("w-20 text-right")}, list{text("Proved")}),
                            div(list{Attrs.class_("w-20 text-right")}, list{text("Admitted")}),
                            div(list{Attrs.class_("w-24")}, list{text("Systems")}),
                            div(list{Attrs.class_("flex-1")}, list{text("Status")}),
                          },
                        ),
                        div(
                          list{Attrs.class_("max-h-96 overflow-y-auto")},
                          withProofs
                          ->Array.map(s => {
                            let status = if s.admittedCount === 0 {
                              "Clean — all proofs discharged"
                            } else {
                              Int.toString(
                                s.admittedCount,
                              ) ++ " admitted — formal verification debt"
                            }
                            div(
                              list{
                                Attrs.class_(
                                  "flex items-center gap-3 p-2 border-b border-gray-800 text-xs",
                                ),
                              },
                              list{
                                div(
                                  list{Attrs.class_("w-28 text-gray-200 font-medium")},
                                  list{text(s.name)},
                                ),
                                div(
                                  list{Attrs.class_("w-20 text-right text-violet-400 font-mono")},
                                  list{text(Int.toString(s.provedCount))},
                                ),
                                div(
                                  list{
                                    Attrs.class_(
                                      `w-20 text-right font-mono ${VerificationDashboardEngine.admittedColour(
                                          s.admittedCount,
                                        )}`,
                                    ),
                                  },
                                  list{text(Int.toString(s.admittedCount))},
                                ),
                                div(
                                  list{Attrs.class_("w-24 flex gap-0.5")},
                                  s.proofSystems->Array.map(renderProofBadge)->List.fromArray,
                                ),
                                div(
                                  list{
                                    Attrs.class_(
                                      `flex-1 ${if s.admittedCount === 0 {
                                          "text-emerald-400"
                                        } else {
                                          "text-amber-400"
                                        }}`,
                                    ),
                                  },
                                  list{text(status)},
                                ),
                              },
                            )
                          })
                          ->List.fromArray,
                        ),
                      },
                    ),
                    if Array.length(withProofs) === 0 {
                      div(
                        list{Attrs.class_("text-center text-gray-500 mt-8")},
                        list{text("No languages have formal proofs yet.")},
                      )
                    } else {
                      noNode
                    },
                  },
                )
              }
            // ── Benchmarks Tab ──
            | VdBenchmarks => {
                let benchmarks = VerificationDashboardEngine.allBenchmarks()
                div(
                  list{Attrs.class_("space-y-4")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-400 mb-2")},
                      list{
                        text("Performance benchmark results across all language implementations."),
                      },
                    ),
                    if Array.length(benchmarks) === 0 {
                      div(
                        list{Attrs.class_("text-center text-gray-500 mt-8")},
                        list{text("No benchmark results available.")},
                      )
                    } else {
                      div(
                        list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                        list{
                          div(
                            list{
                              Attrs.class_(
                                "flex items-center gap-3 p-2 bg-gray-800/50 border-b border-gray-700 text-[10px] text-gray-500 uppercase tracking-wide",
                              ),
                            },
                            list{
                              div(list{Attrs.class_("w-28")}, list{text("Language")}),
                              div(list{Attrs.class_("w-40")}, list{text("Benchmark")}),
                              div(list{Attrs.class_("w-24 text-right")}, list{text("Mean (ms)")}),
                              div(list{Attrs.class_("w-24 text-right")}, list{text("StdDev")}),
                              div(list{Attrs.class_("w-20 text-right")}, list{text("Iters")}),
                              div(list{Attrs.class_("w-16 text-center")}, list{text("Regr?")}),
                            },
                          ),
                          div(
                            list{Attrs.class_("max-h-96 overflow-y-auto")},
                            benchmarks
                            ->Array.map(b =>
                              div(
                                list{
                                  Attrs.class_(
                                    "flex items-center gap-3 p-2 border-b border-gray-800 text-xs",
                                  ),
                                },
                                list{
                                  div(
                                    list{Attrs.class_("w-28 text-gray-200 font-medium")},
                                    list{text(b.language)},
                                  ),
                                  div(
                                    list{Attrs.class_("w-40 text-gray-300 font-mono")},
                                    list{text(b.name)},
                                  ),
                                  div(
                                    list{Attrs.class_("w-24 text-right text-cyan-400 font-mono")},
                                    list{text(Float.toFixed(b.meanMs, ~digits=1))},
                                  ),
                                  div(
                                    list{Attrs.class_("w-24 text-right text-gray-500 font-mono")},
                                    list{text(Float.toFixed(b.stddevMs, ~digits=1))},
                                  ),
                                  div(
                                    list{Attrs.class_("w-20 text-right text-gray-400 font-mono")},
                                    list{text(Int.toString(b.iterations))},
                                  ),
                                  div(
                                    list{
                                      Attrs.class_(
                                        `w-16 text-center ${if b.regression {
                                            "text-red-400"
                                          } else {
                                            "text-gray-600"
                                          }}`,
                                      ),
                                    },
                                    list{
                                      text(
                                        if b.regression {
                                          "Yes"
                                        } else {
                                          "-"
                                        },
                                      ),
                                    },
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
                )
              }
            // ── Fuzzing Tab ──
            | VdFuzzing => {
                let fuzzData = VerificationDashboardEngine.allFuzzingCoverage()
                div(
                  list{Attrs.class_("space-y-4")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-400 mb-2")},
                      list{
                        text(
                          "Fuzzing coverage across language implementations. Only languages with active fuzz targets are shown.",
                        ),
                      },
                    ),
                    if Array.length(fuzzData) === 0 {
                      div(
                        list{Attrs.class_("text-center text-gray-500 mt-8")},
                        list{text("No fuzzing coverage data available.")},
                      )
                    } else {
                      div(
                        list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                        list{
                          div(
                            list{
                              Attrs.class_(
                                "flex items-center gap-3 p-2 bg-gray-800/50 border-b border-gray-700 text-[10px] text-gray-500 uppercase tracking-wide",
                              ),
                            },
                            list{
                              div(list{Attrs.class_("w-28")}, list{text("Language")}),
                              div(list{Attrs.class_("w-16 text-right")}, list{text("Targets")}),
                              div(
                                list{Attrs.class_("w-24 text-right")},
                                list{text("Lines Covered")},
                              ),
                              div(list{Attrs.class_("w-24 text-right")}, list{text("Total Lines")}),
                              div(list{Attrs.class_("w-16 text-right")}, list{text("Cover%")}),
                              div(list{Attrs.class_("w-16 text-right")}, list{text("Crashes")}),
                              div(list{Attrs.class_("w-20 text-right")}, list{text("Hours")}),
                            },
                          ),
                          div(
                            list{Attrs.class_("max-h-96 overflow-y-auto")},
                            fuzzData
                            ->Array.map(f => {
                              let coverPct = if f.totalLines > 0 {
                                f.linesCovered * 100 / f.totalLines
                              } else {
                                0
                              }
                              div(
                                list{
                                  Attrs.class_(
                                    "flex items-center gap-3 p-2 border-b border-gray-800 text-xs",
                                  ),
                                },
                                list{
                                  div(
                                    list{Attrs.class_("w-28 text-gray-200 font-medium")},
                                    list{text(f.language)},
                                  ),
                                  div(
                                    list{Attrs.class_("w-16 text-right text-gray-300 font-mono")},
                                    list{text(Int.toString(f.targets))},
                                  ),
                                  div(
                                    list{
                                      Attrs.class_("w-24 text-right text-emerald-400 font-mono"),
                                    },
                                    list{text(Int.toString(f.linesCovered))},
                                  ),
                                  div(
                                    list{Attrs.class_("w-24 text-right text-gray-400 font-mono")},
                                    list{text(Int.toString(f.totalLines))},
                                  ),
                                  div(
                                    list{
                                      Attrs.class_(
                                        `w-16 text-right font-mono ${VerificationDashboardEngine.passRateColour(
                                            coverPct,
                                          )}`,
                                      ),
                                    },
                                    list{text(Int.toString(coverPct) ++ "%")},
                                  ),
                                  div(
                                    list{
                                      Attrs.class_(
                                        `w-16 text-right font-mono ${if f.crashesFound > 0 {
                                            "text-red-400"
                                          } else {
                                            "text-emerald-400"
                                          }}`,
                                      ),
                                    },
                                    list{text(Int.toString(f.crashesFound))},
                                  ),
                                  div(
                                    list{Attrs.class_("w-20 text-right text-gray-400 font-mono")},
                                    list{text(Float.toFixed(f.fuzzHours, ~digits=1))},
                                  ),
                                },
                              )
                            })
                            ->List.fromArray,
                          ),
                        },
                      )
                    },
                  },
                )
              }
            }
          },
          // Error display
          switch vd.error {
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
