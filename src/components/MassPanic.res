// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Mass Panic Panel — organisation-scale batch scanning GUI.
///
/// Provides a visual interface for panic-attack's mass-panic deployment mode:
/// repo discovery, select-all/checkbox batch controls, assemblyline scanning
/// with progress tracking, incremental BLAKE3 delta, verisimdb persistence,
/// result sorting/filtering, delta comparison, and notification generation.
///
/// Replaces the complex CLI orchestration of:
///   panic-attack assemblyline /path --incremental --store ./data --cache ...

open Msg
open MassPanicModel
open Tea.Html

/// Status badge for a repo scan result.
let statusBadge = (status: repoScanStatus): Tea_Vdom.t<msg> => {
  let (colour, lbl) = switch status {
  | Queued => ("bg-gray-600 text-gray-200", "QUEUED")
  | Scanning => ("bg-amber-500 text-white animate-pulse", "SCANNING")
  | Complete => ("bg-emerald-600 text-white", "DONE")
  | Skipped => ("bg-blue-600 text-white", "SKIPPED")
  | Failed(_) => ("bg-red-600 text-white", "FAILED")
  }
  span(list{Attrs.class_(`px-1.5 py-0.5 text-xs rounded font-mono ${colour}`)}, list{text(lbl)})
}

/// Severity count pills for a repo row.
let severityPills = (repo: repoResult): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-1")},
    list{
      if repo.critical > 0 {
        span(
          list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-red-600 text-white font-mono")},
          list{text(`${Int.toString(repo.critical)}C`)},
        )
      } else {
        noNode
      },
      if repo.high > 0 {
        span(
          list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-orange-500 text-white font-mono")},
          list{text(`${Int.toString(repo.high)}H`)},
        )
      } else {
        noNode
      },
      if repo.medium > 0 {
        span(
          list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-amber-400 text-gray-900 font-mono")},
          list{text(`${Int.toString(repo.medium)}M`)},
        )
      } else {
        noNode
      },
      if repo.low > 0 {
        span(
          list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-blue-400 text-white font-mono")},
          list{text(`${Int.toString(repo.low)}L`)},
        )
      } else {
        noNode
      },
    },
  )
}

/// Progress bar (thin horizontal bar showing scan completion).
let progressBar = (progress: float, scanning: bool): Tea_Vdom.t<msg> => {
  if !scanning {
    noNode
  } else {
    let pct = Int.toString(Int.fromFloat(progress *. 100.0))
    div(
      list{Attrs.class_("w-full h-1.5 bg-gray-700 rounded overflow-hidden")},
      list{
        div(
          list{Attrs.class_(`h-full bg-amber-500 transition-all duration-300 w-[${pct}%]`)},
          list{},
        ),
      },
    )
  }
}

/// Aggregate summary bar.
let summaryView = (summary: option<assemblylineSummary>): Tea_Vdom.t<msg> => {
  switch summary {
  | None =>
    div(
      list{Attrs.class_("text-gray-500 text-sm italic py-2")},
      list{text("No scan results. Set a repos directory and run assemblyline.")},
    )
  | Some(s) =>
    div(
      list{Attrs.class_("flex flex-wrap gap-4 items-center py-2 text-sm")},
      list{
        span(
          list{Attrs.class_("text-gray-300 font-mono")},
          list{text(`${Int.toString(s.scannedRepos)}/${Int.toString(s.totalRepos)} repos scanned`)},
        ),
        if s.skippedRepos > 0 {
          span(
            list{Attrs.class_("text-blue-400 font-mono")},
            list{text(`${Int.toString(s.skippedRepos)} skipped (unchanged)`)},
          )
        } else {
          noNode
        },
        span(
          list{Attrs.class_("text-gray-400 font-mono")},
          list{text(`${Int.toString(s.totalFindings)} findings`)},
        ),
        if s.totalCritical > 0 {
          span(
            list{Attrs.class_("text-red-400 font-mono font-bold")},
            list{text(`${Int.toString(s.totalCritical)} critical`)},
          )
        } else {
          noNode
        },
        if s.totalHigh > 0 {
          span(
            list{Attrs.class_("text-orange-400 font-mono")},
            list{text(`${Int.toString(s.totalHigh)} high`)},
          )
        } else {
          noNode
        },
        span(
          list{Attrs.class_("text-gray-500 font-mono")},
          list{text(`${Float.toString(s.scanDuration)}s`)},
        ),
      },
    )
  }
}

/// Filter and sort repo results.
let filterAndSort = (
  repos: array<repoResult>,
  filterMode: repoFilterMode,
  sortMode: repoSortMode,
  searchText: string,
): array<repoResult> => {
  repos
  ->Array.filter(r => {
    let filterMatch = switch filterMode {
    | AllRepos => true
    | FindingsOnly => r.totalFindings > 0
    | CriticalOnly => r.critical > 0
    | FailedOnly =>
      switch r.status {
      | Failed(_) => true
      | _ => false
      }
    }
    let textMatch =
      searchText == "" ||
      String.includes(String.toLowerCase(r.repoName), String.toLowerCase(searchText)) ||
      String.includes(String.toLowerCase(r.repoPath), String.toLowerCase(searchText))
    filterMatch && textMatch
  })
  ->Array.toSorted((a, b) =>
    switch sortMode {
    | ByRisk =>
      Float.fromInt(b.critical * 100 + b.high * 10 + b.totalFindings) -.
      Float.fromInt(a.critical * 100 + a.high * 10 + a.totalFindings)
    | ByName => String.localeCompare(a.repoName, b.repoName)
    | ByFindings => Float.fromInt(b.totalFindings - a.totalFindings)
    | ByDuration =>
      switch (b.scanDuration, a.scanDuration) {
      | (Some(bd), Some(ad)) => bd -. ad
      | (Some(_), None) => 1.0
      | (None, Some(_)) => -1.0
      | (None, None) => 0.0
      }
    }
  )
}

/// Single repo row in the results table.
let repoRow = (repo: repoResult, index: int, isSelected: bool): Tea_Vdom.t<msg> => {
  let selectedClass = isSelected ? "bg-gray-800/30" : ""
  div(
    list{
      Attrs.class_(
        `flex items-center gap-3 py-2 px-3 border-b border-gray-700 hover:bg-gray-800/50 ${selectedClass}`,
      ),
    },
    list{
      // Checkbox
      input(
        list{
          Attrs.type_("checkbox"),
          Attrs.checked(isSelected),
          Attrs.class_("w-4 h-4 accent-amber-500"),
          Events.onClick(MassPanic(ToggleRepoSelection(index))),
        },
        list{},
      ),
      // Status badge
      statusBadge(repo.status),
      // Repo name
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-200 font-mono truncate")},
            list{text(repo.repoName)},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500 font-mono truncate")},
            list{text(repo.repoPath)},
          ),
        },
      ),
      // Findings count
      span(
        list{Attrs.class_("text-sm text-gray-300 font-mono min-w-[60px] text-right")},
        list{text(Int.toString(repo.totalFindings))},
      ),
      // Severity pills
      severityPills(repo),
      // Files scanned
      span(
        list{Attrs.class_("text-xs text-gray-500 font-mono min-w-[40px] text-right")},
        list{text(`${Int.toString(repo.filesScanned)}f`)},
      ),
      // Duration
      span(
        list{Attrs.class_("text-xs text-gray-500 font-mono min-w-[50px] text-right")},
        list{
          text(
            switch repo.scanDuration {
            | Some(d) => `${Float.toFixed(d, ~digits=1)}s`
            | None => "-"
            },
          ),
        },
      ),
      // BLAKE3 hash indicator
      switch repo.blake3Hash {
      | Some(_) => span(list{Attrs.class_("text-xs text-emerald-600")}, list{text("#")})
      | None => noNode
      },
    },
  )
}

/// Delta comparison row.
let deltaRow = (entry: deltaEntry): Tea_Vdom.t<msg> => {
  let dirColour = switch entry.changeDirection {
  | "improved" => "text-emerald-400"
  | "regressed" => "text-red-400"
  | "new" => "text-amber-400"
  | _ => "text-gray-400"
  }
  div(
    list{Attrs.class_("flex items-center gap-3 py-1.5 px-3 border-b border-gray-700 text-sm")},
    list{
      span(
        list{Attrs.class_(`font-mono font-bold ${dirColour} min-w-[80px]`)},
        list{text(String.toUpperCase(entry.changeDirection))},
      ),
      span(
        list{Attrs.class_("flex-1 text-gray-200 font-mono truncate")},
        list{text(entry.repoName)},
      ),
      if entry.newFindings > 0 {
        span(
          list{Attrs.class_("text-red-400 font-mono")},
          list{text(`+${Int.toString(entry.newFindings)}`)},
        )
      } else {
        noNode
      },
      if entry.fixedFindings > 0 {
        span(
          list{Attrs.class_("text-emerald-400 font-mono")},
          list{text(`-${Int.toString(entry.fixedFindings)}`)},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render a filter button.
let filterBtn = (mode: repoFilterMode, lbl: string, activeMode: repoFilterMode): Tea_Vdom.t<
  msg,
> => {
  let active = activeMode == mode
  button(
    list{
      Attrs.class_(
        `px-2 py-0.5 rounded font-mono text-xs ${active
            ? "bg-amber-600 text-white"
            : "bg-gray-700 text-gray-400 hover:bg-gray-600"}`,
      ),
      Events.onClick(MassPanic(SetFilterMode(mode))),
    },
    list{text(lbl)},
  )
}

/// Render a sort button.
let sortBtn = (mode: repoSortMode, lbl: string, activeMode: repoSortMode): Tea_Vdom.t<msg> => {
  let active = activeMode == mode
  button(
    list{
      Attrs.class_(
        `px-2 py-0.5 rounded font-mono text-xs ${active
            ? "bg-gray-600 text-white"
            : "bg-gray-750 text-gray-500 hover:bg-gray-600"}`,
      ),
      Events.onClick(MassPanic(SetSortMode(mode))),
    },
    list{text(lbl)},
  )
}

/// Sub-view tab button.
let viewTab = (targetView: massPanicView, lbl: string, activeView: massPanicView): Tea_Vdom.t<
  msg,
> => {
  let active = activeView == targetView
  button(
    list{
      Attrs.class_(
        `px-3 py-1.5 rounded-t font-mono text-xs border-b-2 ${active
            ? "bg-gray-800 text-white border-amber-500"
            : "bg-gray-900 text-gray-500 border-transparent hover:text-gray-300"}`,
      ),
      Events.onClick(MassPanic(SwitchView(targetView))),
    },
    list{text(lbl)},
  )
}

/// Risk intensity bar (horizontal coloured bar for a node's risk).
let riskBar = (intensity: float): Tea_Vdom.t<msg> => {
  let pct = Int.toString(Int.fromFloat(intensity *. 100.0))
  let colour = if intensity > 0.7 {
    "bg-red-500"
  } else if intensity > 0.4 {
    "bg-orange-500"
  } else if intensity > 0.2 {
    "bg-amber-400"
  } else {
    "bg-emerald-500"
  }
  div(
    list{Attrs.class_("w-20 h-2 bg-gray-700 rounded overflow-hidden")},
    list{div(list{Attrs.class_(`h-full ${colour} w-[${pct}%]`)}, list{})},
  )
}

/// Imaging sub-view — fNIRS-style spatial health map.
let renderImagingView = (state: massPanicState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col h-full overflow-hidden")},
    list{
      // Toolbar
      div(
        list{Attrs.class_("flex items-center gap-3 px-4 py-2 border-b border-gray-700")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded bg-cyan-700 hover:bg-cyan-600 text-white font-mono disabled:opacity-50",
              ),
              Attrs.disabled(state.imagingLoading || state.reposDirectory == ""),
              Events.onClick(MassPanic(BuildImage)),
            },
            list{
              text(
                if state.imagingLoading {
                  "building..."
                } else {
                  "build image"
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded bg-gray-700 hover:bg-gray-600 text-gray-200 font-mono",
              ),
              Events.onClick(MassPanic(ImportImageFile)),
            },
            list{text("import JSON")},
          ),
          switch state.currentImage {
          | Some(img) =>
            div(
              list{Attrs.class_("flex gap-3 ml-auto text-xs font-mono text-gray-400")},
              list{
                span(list{}, list{text(`${Int.toString(img.nodeCount)} nodes`)}),
                span(list{}, list{text(`${Int.toString(img.edgeCount)} edges`)}),
                span(
                  list{
                    Attrs.class_(
                      if img.globalHealth > 0.7 {
                        "text-emerald-400"
                      } else if img.globalHealth > 0.4 {
                        "text-amber-400"
                      } else {
                        "text-red-400"
                      },
                    ),
                  },
                  list{text(`health: ${Float.toFixed(img.globalHealth *. 100.0, ~digits=1)}%`)},
                ),
                span(
                  list{},
                  list{text(`risk: ${Float.toFixed(img.globalRisk *. 100.0, ~digits=1)}%`)},
                ),
                span(list{}, list{text(`${Int.toString(img.totalCritical)} critical`)}),
              },
            )
          | None => noNode
          },
        },
      ),
      // Risk distribution bar
      switch state.currentImage {
      | Some(img) =>
        div(
          list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-700 text-xs")},
          list{
            span(list{Attrs.class_("text-gray-500 mr-2")}, list{text("Distribution:")}),
            span(
              list{Attrs.class_("text-emerald-400 font-mono")},
              list{text(`${Int.toString(img.riskDistribution.healthy)} healthy`)},
            ),
            span(
              list{Attrs.class_("text-blue-400 font-mono")},
              list{text(`${Int.toString(img.riskDistribution.low)} low`)},
            ),
            span(
              list{Attrs.class_("text-amber-400 font-mono")},
              list{text(`${Int.toString(img.riskDistribution.moderate)} mod`)},
            ),
            span(
              list{Attrs.class_("text-orange-400 font-mono")},
              list{text(`${Int.toString(img.riskDistribution.high)} high`)},
            ),
            span(
              list{Attrs.class_("text-red-400 font-mono")},
              list{text(`${Int.toString(img.riskDistribution.critical)} crit`)},
            ),
          },
        )
      | None => noNode
      },
      // Node grid
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        switch state.currentImage {
        | None =>
          list{
            div(
              list{Attrs.class_("flex items-center justify-center h-32 text-gray-500 text-sm")},
              list{text("No system image. Click 'build image' or 'import JSON' to generate one.")},
            ),
          }
        | Some(img) =>
          img.nodes
          ->Array.map(node =>
            div(
              list{
                Attrs.class_(
                  "flex items-center gap-3 py-2 px-4 border-b border-gray-700 hover:bg-gray-800/50",
                ),
              },
              list{
                // Health indicator
                span(
                  list{
                    Attrs.class_(
                      `w-2 h-2 rounded-full ${if node.healthScore > 0.7 {
                          "bg-emerald-500"
                        } else if node.healthScore > 0.4 {
                          "bg-amber-500"
                        } else {
                          "bg-red-500"
                        }}`,
                    ),
                  },
                  list{},
                ),
                // Name
                div(
                  list{Attrs.class_("flex-1 min-w-0")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-200 font-mono truncate")},
                      list{text(node.name)},
                    ),
                    if Array.length(node.topCategories) > 0 {
                      div(
                        list{Attrs.class_("text-xs text-gray-500 font-mono truncate")},
                        list{text(Array.join(node.topCategories, ", "))},
                      )
                    } else {
                      noNode
                    },
                  },
                ),
                // Risk bar
                riskBar(node.riskIntensity),
                // Metrics
                span(
                  list{Attrs.class_("text-xs text-gray-400 font-mono min-w-[60px] text-right")},
                  list{text(`${Float.toFixed(node.healthScore *. 100.0, ~digits=0)}%`)},
                ),
                span(
                  list{Attrs.class_("text-xs text-gray-500 font-mono min-w-[40px] text-right")},
                  list{text(`${Int.toString(node.weakPointCount)}wp`)},
                ),
                if node.criticalCount > 0 {
                  span(
                    list{Attrs.class_("text-xs text-red-400 font-mono")},
                    list{text(`${Int.toString(node.criticalCount)}C`)},
                  )
                } else {
                  noNode
                },
                if node.skipped {
                  span(list{Attrs.class_("text-xs text-blue-500")}, list{text("skipped")})
                } else {
                  noNode
                },
              },
            )
          )
          ->List.fromArray
        },
      ),
    },
  )
}

/// Temporal sub-view — time-series snapshot navigation.
let renderTemporalView = (state: massPanicState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col h-full overflow-hidden")},
    list{
      // Toolbar
      div(
        list{Attrs.class_("flex items-center gap-3 px-4 py-2 border-b border-gray-700")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded bg-violet-700 hover:bg-violet-600 text-white font-mono disabled:opacity-50",
              ),
              Attrs.disabled(state.temporalLoading),
              Events.onClick(MassPanic(ListSnapshots)),
            },
            list{
              text(
                if state.temporalLoading {
                  "loading..."
                } else {
                  "list snapshots"
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded bg-gray-700 hover:bg-gray-600 text-gray-200 font-mono disabled:opacity-50",
              ),
              Attrs.disabled(
                switch state.selectedSnapshots {
                | (Some(_), Some(_)) => false
                | _ => true
                },
              ),
              Events.onClick(MassPanic(DiffSnapshots)),
            },
            list{text("diff selected")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded bg-emerald-700 hover:bg-emerald-600 text-white font-mono disabled:opacity-50",
              ),
              Attrs.disabled(
                switch state.currentImage {
                | Some(_) => false
                | None => true
                },
              ),
              Events.onClick(MassPanic(TakeSnapshot("manual"))),
            },
            list{text("take snapshot")},
          ),
        },
      ),
      // Diff summary (when active)
      switch state.currentDiff {
      | Some(diff) =>
        div(
          list{Attrs.class_("px-4 py-2 border-b border-gray-700 bg-gray-800")},
          list{
            div(
              list{Attrs.class_("flex items-center gap-4 text-xs font-mono")},
              list{
                span(
                  list{Attrs.class_("text-gray-400")},
                  list{text(`${diff.fromLabel} → ${diff.toLabel}`)},
                ),
                span(
                  list{
                    Attrs.class_(
                      if diff.healthDelta > 0.0 {
                        "text-emerald-400"
                      } else if diff.healthDelta < 0.0 {
                        "text-red-400"
                      } else {
                        "text-gray-400"
                      },
                    ),
                  },
                  list{
                    text(
                      `health: ${if diff.healthDelta > 0.0 {
                          "+"
                        } else {
                          ""
                        }}${Float.toFixed(diff.healthDelta *. 100.0, ~digits=1)}%`,
                    ),
                  },
                ),
                span(
                  list{
                    Attrs.class_(
                      if diff.weakPointDelta < 0 {
                        "text-emerald-400"
                      } else if diff.weakPointDelta > 0 {
                        "text-red-400"
                      } else {
                        "text-gray-400"
                      },
                    ),
                  },
                  list{
                    text(
                      `wp: ${if diff.weakPointDelta > 0 {
                          "+"
                        } else {
                          ""
                        }}${Int.toString(diff.weakPointDelta)}`,
                    ),
                  },
                ),
                span(
                  list{
                    Attrs.class_(
                      switch diff.trend {
                      | "improving" => "text-emerald-400 font-bold"
                      | "degrading" => "text-red-400 font-bold"
                      | _ => "text-gray-400"
                      },
                    ),
                  },
                  list{text(String.toUpperCase(diff.trend))},
                ),
                span(
                  list{Attrs.class_("text-gray-500")},
                  list{
                    text(
                      `${Int.toString(Array.length(diff.improvedNodes))} improved, ${Int.toString(
                          Array.length(diff.degradedNodes),
                        )} degraded, ${Int.toString(diff.unchangedCount)} stable`,
                    ),
                  },
                ),
              },
            ),
            // Changed nodes
            if Array.length(diff.degradedNodes) > 0 {
              div(
                list{Attrs.class_("mt-2")},
                list{
                  div(
                    list{Attrs.class_("text-xs text-red-400 font-bold mb-1")},
                    list{text("Degraded:")},
                  ),
                  div(
                    list{Attrs.class_("max-h-24 overflow-y-auto")},
                    diff.degradedNodes
                    ->Array.map(nd =>
                      div(
                        list{Attrs.class_("flex items-center gap-2 text-xs font-mono py-0.5")},
                        list{
                          span(list{Attrs.class_("text-gray-200")}, list{text(nd.name)}),
                          span(
                            list{Attrs.class_("text-red-400")},
                            list{
                              text(`${Float.toFixed(nd.healthDelta *. 100.0, ~digits=1)}% health`),
                            },
                          ),
                          span(
                            list{Attrs.class_("text-gray-500")},
                            list{
                              text(
                                `${if nd.weakPointDelta > 0 {
                                    "+"
                                  } else {
                                    ""
                                  }}${Int.toString(nd.weakPointDelta)} wp`,
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
            } else {
              noNode
            },
            if Array.length(diff.improvedNodes) > 0 {
              div(
                list{Attrs.class_("mt-2")},
                list{
                  div(
                    list{Attrs.class_("text-xs text-emerald-400 font-bold mb-1")},
                    list{text("Improved:")},
                  ),
                  div(
                    list{Attrs.class_("max-h-24 overflow-y-auto")},
                    diff.improvedNodes
                    ->Array.map(nd =>
                      div(
                        list{Attrs.class_("flex items-center gap-2 text-xs font-mono py-0.5")},
                        list{
                          span(list{Attrs.class_("text-gray-200")}, list{text(nd.name)}),
                          span(
                            list{Attrs.class_("text-emerald-400")},
                            list{
                              text(`+${Float.toFixed(nd.healthDelta *. 100.0, ~digits=1)}% health`),
                            },
                          ),
                        },
                      )
                    )
                    ->List.fromArray,
                  ),
                },
              )
            } else {
              noNode
            },
          },
        )
      | None => noNode
      },
      // Snapshot timeline list
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        if Array.length(state.snapshots) == 0 {
          list{
            div(
              list{Attrs.class_("flex items-center justify-center h-32 text-gray-500 text-sm")},
              list{
                text(
                  "No snapshots. Run an image scan and click 'take snapshot', or 'list snapshots' to load existing ones.",
                ),
              },
            ),
          }
        } else {
          state.snapshots
          ->Array.map(snap => {
            let (selA, selB) = state.selectedSnapshots
            let isSelected = selA == Some(snap.sequence) || selB == Some(snap.sequence)
            div(
              list{
                Attrs.class_(
                  `flex items-center gap-3 py-2 px-4 border-b border-gray-700 cursor-pointer hover:bg-gray-800/50 ${isSelected
                      ? "bg-violet-900/20 border-l-2 border-l-violet-500"
                      : ""}`,
                ),
                Events.onClick(MassPanic(SelectSnapshot(snap.sequence, 0))),
              },
              list{
                span(
                  list{Attrs.class_("text-xs text-gray-500 font-mono min-w-[30px]")},
                  list{text(`#${Int.toString(snap.sequence)}`)},
                ),
                span(list{Attrs.class_("text-sm text-gray-200 font-mono")}, list{text(snap.label)}),
                span(
                  list{Attrs.class_("text-xs text-gray-500 font-mono")},
                  list{text(snap.timestamp)},
                ),
                span(
                  list{Attrs.class_("text-xs text-gray-400 font-mono ml-auto")},
                  list{text(`${Int.toString(snap.nodeCount)} nodes`)},
                ),
                span(
                  list{
                    Attrs.class_(
                      `text-xs font-mono ${if snap.globalHealth > 0.7 {
                          "text-emerald-400"
                        } else if snap.globalHealth > 0.4 {
                          "text-amber-400"
                        } else {
                          "text-red-400"
                        }}`,
                    ),
                  },
                  list{text(`${Float.toFixed(snap.globalHealth *. 100.0, ~digits=0)}%`)},
                ),
                span(
                  list{Attrs.class_("text-xs text-gray-500 font-mono")},
                  list{text(`${Int.toString(snap.totalWeakPoints)}wp`)},
                ),
              },
            )
          })
          ->List.fromArray
        },
      ),
    },
  )
}

/// Main panel view.
let view = (state: massPanicState): Tea_Vdom.t<msg> => {
  let filtered = filterAndSort(
    state.repoResults,
    state.filterMode,
    state.sortMode,
    state.searchText,
  )

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100 overflow-hidden")},
    list{
      // Header bar with tab navigation
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-4 py-3 bg-gray-800 border-b border-gray-700",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(list{Attrs.class_("text-lg font-bold text-red-400")}, list{text("mass-panic")}),
              // View tabs
              div(
                list{Attrs.class_("flex items-center gap-0 ml-4")},
                list{
                  viewTab(ScanView, "scan", state.activeView),
                  viewTab(ImagingView, "imaging", state.activeView),
                  viewTab(TemporalView, "temporal", state.activeView),
                },
              ),
              if state.incremental {
                span(
                  list{
                    Attrs.class_("text-xs text-blue-400 font-mono px-2 py-0.5 rounded bg-gray-700"),
                  },
                  list{text("BLAKE3 incremental")},
                )
              } else {
                noNode
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              if state.scanning {
                span(
                  list{Attrs.class_("text-xs text-amber-400 animate-pulse")},
                  list{
                    text(
                      switch state.currentRepo {
                      | Some(name) => `Scanning ${name}...`
                      | None => "Scanning..."
                      },
                    ),
                  },
                )
              } else {
                noNode
              },
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded bg-red-700 hover:bg-red-600 text-white font-mono disabled:opacity-50",
                  ),
                  Attrs.disabled(state.scanning || state.reposDirectory == ""),
                  Events.onClick(MassPanic(RunAssemblyline)),
                },
                list{text("scan all")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded bg-amber-700 hover:bg-amber-600 text-white font-mono disabled:opacity-50",
                  ),
                  Attrs.disabled(state.scanning || Array.length(state.selectedRepos) == 0),
                  Events.onClick(MassPanic(RunSelected)),
                },
                list{text(`scan ${Int.toString(Array.length(state.selectedRepos))} selected`)},
              ),
            },
          ),
        },
      ),
      // Error display (shared across all views)
      switch state.lastError {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 border-b border-red-700 text-red-300 text-sm"),
          },
          list{
            text(err),
            button(
              list{
                Attrs.class_("ml-2 text-red-400 hover:text-red-200 text-xs"),
                Events.onClick(MassPanic(DismissMassPanicError)),
              },
              list{text("[dismiss]")},
            ),
          },
        )
      | None => noNode
      },
      // Sub-view content
      switch state.activeView {
      | ImagingView => renderImagingView(state)
      | TemporalView => renderTemporalView(state)
      | ScanView =>
        // Scan view — assemblyline batch scanning
        div(
          list{Attrs.class_("flex flex-col flex-1 overflow-hidden")},
          list{
            // Directory input + controls bar
            div(
              list{Attrs.class_("flex items-center gap-2 px-4 py-2 border-b border-gray-700")},
              list{
                span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Repos:")}),
                input(
                  list{
                    Attrs.type_("text"),
                    Attrs.class_(
                      "flex-1 bg-gray-800 text-sm text-gray-200 px-2 py-1 rounded border border-gray-600 font-mono",
                    ),
                    Attrs.placeholder("/path/to/repos/"),
                    Attrs.value(state.reposDirectory),
                    Events.onInput(v => MassPanic(SetReposDirectory(v))),
                  },
                  list{},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-2 py-1 text-xs rounded bg-gray-700 hover:bg-gray-600 text-gray-200 font-mono",
                    ),
                    Attrs.disabled(state.reposDirectory == ""),
                    Events.onClick(MassPanic(DiscoverRepos)),
                  },
                  list{text("discover")},
                ),
              },
            ),
            // Options bar: incremental, storage, filter, sort
            div(
              list{
                Attrs.class_("flex items-center gap-4 px-4 py-2 border-b border-gray-700 text-xs"),
              },
              list{
                label(
                  list{Attrs.class_("flex items-center gap-1 text-gray-400 cursor-pointer")},
                  list{
                    input(
                      list{
                        Attrs.type_("checkbox"),
                        Attrs.checked(state.incremental),
                        Attrs.class_("w-3.5 h-3.5 accent-blue-500"),
                        Events.onClick(MassPanic(ToggleIncremental)),
                      },
                      list{},
                    ),
                    text("Incremental"),
                  },
                ),
                label(
                  list{Attrs.class_("flex items-center gap-1 text-gray-400 cursor-pointer")},
                  list{
                    input(
                      list{
                        Attrs.type_("checkbox"),
                        Attrs.checked(state.notifyEnabled),
                        Attrs.class_("w-3.5 h-3.5 accent-amber-500"),
                        Events.onClick(MassPanic(ToggleNotify)),
                      },
                      list{},
                    ),
                    text("Notify"),
                  },
                ),
                // Filter buttons
                div(
                  list{Attrs.class_("flex gap-1 ml-auto")},
                  list{
                    filterBtn(AllRepos, "All", state.filterMode),
                    filterBtn(FindingsOnly, "Findings", state.filterMode),
                    filterBtn(CriticalOnly, "Critical", state.filterMode),
                    filterBtn(FailedOnly, "Failed", state.filterMode),
                  },
                ),
                // Search
                input(
                  list{
                    Attrs.type_("text"),
                    Attrs.class_(
                      "w-40 bg-gray-800 text-sm text-gray-200 px-2 py-0.5 rounded border border-gray-600 font-mono",
                    ),
                    Attrs.placeholder("Search repos..."),
                    Attrs.value(state.searchText),
                    Events.onInput(v => MassPanic(SetSearchText(v))),
                  },
                  list{},
                ),
              },
            ),
            // Progress bar
            progressBar(state.progress, state.scanning),
            // Summary bar
            div(
              list{Attrs.class_("px-4 border-b border-gray-700")},
              list{summaryView(state.summary)},
            ),
            // Select-all bar
            if Array.length(state.repoResults) > 0 {
              div(
                list{
                  Attrs.class_(
                    "flex items-center gap-3 px-4 py-1.5 border-b border-gray-700 bg-gray-850 text-xs",
                  ),
                },
                list{
                  label(
                    list{Attrs.class_("flex items-center gap-1 text-gray-400 cursor-pointer")},
                    list{
                      input(
                        list{
                          Attrs.type_("checkbox"),
                          Attrs.checked(state.selectAll),
                          Attrs.class_("w-3.5 h-3.5 accent-amber-500"),
                          Events.onClick(MassPanic(ToggleSelectAll)),
                        },
                        list{},
                      ),
                      text("Select all"),
                    },
                  ),
                  span(
                    list{Attrs.class_("text-gray-500")},
                    list{
                      text(
                        `${Int.toString(Array.length(state.selectedRepos))} of ${Int.toString(
                            Array.length(state.repoResults),
                          )} selected`,
                      ),
                    },
                  ),
                  // Sort controls
                  div(
                    list{Attrs.class_("flex gap-1 ml-auto")},
                    list{
                      sortBtn(ByRisk, "Risk", state.sortMode),
                      sortBtn(ByName, "Name", state.sortMode),
                      sortBtn(ByFindings, "Findings", state.sortMode),
                      sortBtn(ByDuration, "Time", state.sortMode),
                    },
                  ),
                },
              )
            } else {
              noNode
            },
            // Delta comparison view (when active)
            if state.showDelta && Array.length(state.delta) > 0 {
              div(
                list{Attrs.class_("border-b border-gray-700")},
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-2 px-4 py-1.5 bg-gray-800 text-xs")},
                    list{
                      span(list{Attrs.class_("text-gray-400 font-bold")}, list{text("DELTA")}),
                      span(
                        list{Attrs.class_("text-gray-500")},
                        list{text("Changes since previous run")},
                      ),
                      button(
                        list{
                          Attrs.class_("ml-auto text-gray-500 hover:text-gray-300"),
                          Events.onClick(MassPanic(ToggleDelta)),
                        },
                        list{text("[close]")},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("max-h-40 overflow-y-auto")},
                    state.delta->Array.map(deltaRow)->List.fromArray,
                  ),
                },
              )
            } else {
              noNode
            },
            // Repo results list
            div(
              list{Attrs.class_("flex-1 overflow-y-auto")},
              if Array.length(filtered) == 0 && !state.scanning {
                list{
                  div(
                    list{
                      Attrs.class_("flex items-center justify-center h-32 text-gray-500 text-sm"),
                    },
                    list{
                      text(
                        if Array.length(state.repoResults) == 0 {
                          "No repos discovered. Enter a directory path and click 'discover'."
                        } else {
                          "No repos match the current filter."
                        },
                      ),
                    },
                  ),
                }
              } else {
                filtered
                ->Array.mapWithIndex((repo, index) => {
                  let isSelected = state.selectedRepos->Array.includes(index)
                  repoRow(repo, index, isSelected)
                })
                ->List.fromArray
              },
            ),
          },
        )
      },
      // Footer
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-4 py-2 bg-gray-800 border-t border-gray-700 text-xs text-gray-500",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(list{}, list{text(`${Int.toString(Array.length(state.repoResults))} repos`)}),
              switch state.storage {
              | NoStorage => noNode
              | Filesystem(path) =>
                span(list{Attrs.class_("text-emerald-600")}, list{text(`store: ${path}`)})
              | VerisimDB(path) =>
                span(list{Attrs.class_("text-cyan-500")}, list{text(`verisimdb: ${path}`)})
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              if state.showDelta {
                noNode
              } else {
                button(
                  list{
                    Attrs.class_("text-gray-500 hover:text-gray-300"),
                    Attrs.disabled(state.scanning),
                    Events.onClick(MassPanic(ToggleDelta)),
                  },
                  list{text("show delta")},
                )
              },
              span(list{}, list{text("panic-attack 2.1.0 — mass-panic mode")}),
            },
          ),
        },
      ),
    },
  )
}
