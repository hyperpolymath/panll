// SPDX-License-Identifier: MPL-2.0

/// PanLL Migration Component — ReScript Migration Observatory dashboard.
///
/// Three-panel mapping visualised as a tabbed full-screen overlay:
///   Dashboard  — Panel-W health scores, version brackets, aggregate metrics
///   Timeline   — Panel-W session history, before/after snapshots
///   Reports    — Panel-W generated reports (per-repo, cross-repo, v13 trial)
///   Submissions— Panel-W review queue with approve/reject for ReScript team
///   Merge      — Panel-N/W merge conflict resolution timeline + rollback
///
/// Panel-L constraints and Panel-N reasoning are woven into each tab
/// as inline indicators rather than separate views.

open Model
open Msg
open Tea.Html

/// Render a health bar — a thin coloured bar proportional to 0.0–1.0.
let renderHealthBar = (score: float): Tea_Vdom.t<msg> => {
  let pct = Float.toFixed(score *. 100.0, ~digits=0)
  let barColor = if score >= 0.8 {
    "bg-green-500"
  } else if score >= 0.5 {
    "bg-amber-500"
  } else {
    "bg-red-500"
  }
  div(
    list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-2")},
    list{
      div(
        list{
          Attrs.class_(`${barColor} h-full rounded-full transition-all`),
          Attrs.prop("style", `width: ${pct}%`),
        },
        list{},
      ),
    },
  )
}

/// Render a single repo row in the dashboard table.
let renderRepoRow = (repo: migrationRepoSummary): Tea_Vdom.t<msg> => {
  let trendClass = MigrationEngine.trendIndicator(repo.trend)
  let versionColor = MigrationEngine.versionBracketColor(repo.versionBracket)
  div(
    list{
      Attrs.class_("flex items-center gap-3 p-2 border-b border-gray-800 hover:bg-gray-900/50"),
      Attrs.role("row"),
    },
    list{
      // Blocked indicator
      if repo.blocked {
        span(list{Attrs.class_("text-xs text-red-400 w-8")}, list{text("BLK")})
      } else {
        span(list{Attrs.class_("text-xs text-green-400 w-8")}, list{text("OK")})
      },
      // Repo name
      span(
        list{Attrs.class_("text-sm text-gray-200 w-40 truncate font-medium")},
        list{text(repo.name)},
      ),
      // Version bracket badge
      span(
        list{Attrs.class_(`text-xs text-gray-900 px-2 py-0.5 rounded ${versionColor}`)},
        list{text(MigrationEngine.versionBracketLabel(repo.versionBracket))},
      ),
      // Health bar
      div(
        list{Attrs.class_("flex-1 flex items-center gap-2")},
        list{
          renderHealthBar(repo.healthScore),
          span(
            list{
              Attrs.class_(
                `text-xs w-10 text-right ${MigrationEngine.healthColor(repo.healthScore)}`,
              ),
            },
            list{text(MigrationEngine.healthPercent(repo.healthScore))},
          ),
        },
      ),
      // Trend
      span(
        list{Attrs.class_(`text-xs w-12 ${trendClass}`)},
        list{text(MigrationEngine.trendLabel(repo.trend))},
      ),
      // Deprecated / modern counts
      span(
        list{Attrs.class_("text-xs text-red-400 w-16 text-right")},
        list{text(`${Int.toString(repo.deprecatedCount)} dep`)},
      ),
      span(
        list{Attrs.class_("text-xs text-green-400 w-16 text-right")},
        list{text(`${Int.toString(repo.modernCount)} mod`)},
      ),
      // Config format
      span(
        list{Attrs.class_("text-xs text-gray-500 w-24 text-right")},
        list{text(MigrationEngine.configFormatLabel(repo.configFormat))},
      ),
    },
  )
}

/// Render the version bracket distribution as horizontal stacked segments.
let renderVersionDistribution = (repos: array<migrationRepoSummary>): Tea_Vdom.t<msg> => {
  let groups = MigrationEngine.groupByVersion(repos)
  let total = Array.length(repos)
  if total === 0 {
    div(list{Attrs.class_("text-gray-500 text-sm")}, list{text("No repos loaded")})
  } else {
    div(
      list{Attrs.class_("space-y-2")},
      list{
        div(list{Attrs.class_("text-sm text-gray-400 mb-2")}, list{text("Version Distribution")}),
        div(
          list{Attrs.class_("flex h-6 rounded overflow-hidden")},
          groups
          ->Array.map(((bracket, rs)) => {
            let count = Array.length(rs)
            let pct = Float.toFixed(Int.toFloat(count) /. Int.toFloat(total) *. 100.0, ~digits=0)
            let color = MigrationEngine.versionBracketColor(bracket)
            div(
              list{
                Attrs.class_(`${color} flex items-center justify-center`),
                Attrs.prop("style", `width: ${pct}%`),
                Attrs.title(
                  `${MigrationEngine.versionBracketLabel(bracket)}: ${Int.toString(count)} repos`,
                ),
              },
              list{
                if count > 2 {
                  span(
                    list{Attrs.class_("text-xs text-gray-900 font-medium")},
                    list{text(Int.toString(count))},
                  )
                } else {
                  noNode
                },
              },
            )
          })
          ->List.fromArray,
        ),
        // Legend
        div(
          list{Attrs.class_("flex flex-wrap gap-3 mt-2")},
          groups
          ->Array.map(((bracket, rs)) => {
            let color = MigrationEngine.versionBracketColor(bracket)
            div(
              list{Attrs.class_("flex items-center gap-1")},
              list{
                div(list{Attrs.class_(`w-3 h-3 rounded ${color}`)}, list{}),
                span(
                  list{Attrs.class_("text-xs text-gray-400")},
                  list{
                    text(
                      `${MigrationEngine.versionBracketLabel(bracket)} (${Int.toString(
                          Array.length(rs),
                        )})`,
                    ),
                  },
                ),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render the constraint summary strip (Panel-L inline).
let renderConstraintStrip = (constraints: array<migrationConstraint>): Tea_Vdom.t<msg> => {
  let unsatisfied = constraints->Array.filter(c => !c.satisfied)
  let count = Array.length(unsatisfied)
  if count === 0 {
    div(
      list{
        Attrs.class_(
          "text-xs text-green-400 px-3 py-1 bg-green-900/20 border border-green-800 rounded",
        ),
      },
      list{text("All migration constraints satisfied")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-wrap gap-2")},
      list{
        span(
          list{Attrs.class_("text-xs text-red-400 font-medium")},
          list{text(`${Int.toString(count)} constraints remaining:`)},
        ),
        ...unsatisfied
        ->Array.map(c =>
          span(
            list{Attrs.class_("text-xs px-2 py-0.5 bg-red-900/30 border border-red-800 rounded")},
            list{
              text(
                `${c.pattern} (${Int.toString(c.totalCount)} in ${Int.toString(
                    c.repoCount,
                  )} repos)`,
              ),
            },
          )
        )
        ->List.fromArray,
      },
    )
  }
}

/// Render proof obligation indicators (Panel-L inline).
let renderObligations = (obligations: array<migrationObligation>): Tea_Vdom.t<msg> => {
  if Array.length(obligations) === 0 {
    noNode
  } else {
    let met = obligations->Array.filter(o => o.met)->Array.length
    let total = Array.length(obligations)
    div(
      list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
      list{
        div(
          list{Attrs.class_("flex items-center gap-2 mb-3")},
          list{
            span(
              list{Attrs.class_("text-sm font-medium text-gray-300")},
              list{text("Proof Obligations")},
            ),
            span(
              list{Attrs.class_("text-xs text-gray-500")},
              list{text(`${Int.toString(met)}/${Int.toString(total)} met`)},
            ),
          },
        ),
        div(
          list{Attrs.class_("space-y-1")},
          obligations
          ->Array.map(o => {
            let icon = o.met ? "text-green-400" : "text-red-400"
            let mark = o.met ? "[OK]" : "[!!]"
            div(
              list{Attrs.class_("flex items-center gap-2 text-xs")},
              list{
                span(list{Attrs.class_(icon)}, list{text(mark)}),
                span(list{Attrs.class_("text-gray-400")}, list{text(o.repo)}),
                span(list{Attrs.class_("text-gray-500")}, list{text(o.property)}),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render a migration session row.
let renderSessionRow = (session: migrationSession): Tea_Vdom.t<msg> => {
  let statusClass = session.active ? "text-amber-400" : "text-gray-400"
  let statusText = session.active ? "In Progress" : "Complete"
  div(
    list{Attrs.class_("flex items-center gap-3 p-3 border-b border-gray-800")},
    list{
      span(list{Attrs.class_(`text-xs ${statusClass} w-16`)}, list{text(statusText)}),
      span(list{Attrs.class_("text-sm text-gray-200 w-32 truncate")}, list{text(session.label)}),
      span(list{Attrs.class_("text-xs text-gray-500 w-40 truncate")}, list{text(session.repoPath)}),
      div(
        list{Attrs.class_("flex items-center gap-2 flex-1")},
        list{
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{text(`Before: ${MigrationEngine.healthPercent(session.beforeHealth)}`)},
          ),
          switch session.afterHealth {
          | Some(after) =>
            span(
              list{Attrs.class_("text-xs text-gray-400")},
              list{text(`After: ${MigrationEngine.healthPercent(after)}`)},
            )
          | None => noNode
          },
          switch session.healthDelta {
          | Some(delta) =>
            let deltaClass = delta > 0.0 ? "text-green-400" : "text-red-400"
            let sign = delta > 0.0 ? "+" : ""
            span(
              list{Attrs.class_(`text-xs font-medium ${deltaClass}`)},
              list{text(`${sign}${Float.toFixed(delta *. 100.0, ~digits=1)}%`)},
            )
          | None => noNode
          },
        },
      ),
      span(
        list{Attrs.class_("text-xs text-gray-500 w-20 text-right")},
        list{text(`${Int.toString(session.issueCount)} issues`)},
      ),
      span(
        list{Attrs.class_("text-xs text-gray-600 w-28 text-right")},
        list{text(session.startedAt)},
      ),
    },
  )
}

/// Render a submission row with approve/reject controls.
let renderSubmissionRow = (sub: migrationSubmission): Tea_Vdom.t<msg> => {
  let statusColor = MigrationEngine.submissionStatusColor(sub.status)
  div(
    list{Attrs.class_("flex items-center gap-3 p-3 border-b border-gray-800")},
    list{
      span(
        list{Attrs.class_(`text-xs ${statusColor} w-16`)},
        list{text(MigrationEngine.submissionStatusLabel(sub.status))},
      ),
      div(
        list{Attrs.class_("flex-1")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200")}, list{text(sub.title)}),
          div(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`${sub.repo} | ${sub.severity}`)},
          ),
        },
      ),
      if sub.status == SubmissionPending {
        div(
          list{Attrs.class_("flex gap-2")},
          list{
            button(
              list{
                Attrs.class_(
                  "px-2 py-1 text-xs bg-green-700 text-white rounded hover:bg-green-600",
                ),
                Events.onClick(Migration(ApproveSubmission(sub.id))),
              },
              list{text("Approve")},
            ),
            button(
              list{
                Attrs.class_("px-2 py-1 text-xs bg-red-700 text-white rounded hover:bg-red-600"),
                Events.onClick(Migration(RejectSubmission(sub.id))),
              },
              list{text("Reject")},
            ),
          },
        )
      } else {
        noNode
      },
    },
  )
}

/// Render a merge resolution row.
let renderMergeRow = (merge: mergeResolution): Tea_Vdom.t<msg> => {
  let statusColor = switch merge.status {
  | "in_progress" => "text-amber-400"
  | "accepted" => "text-green-400"
  | "rolled_back" => "text-red-400"
  | _ => "text-gray-400"
  }
  let confColor = if merge.avgConfidence >= 0.9 {
    "text-green-400"
  } else if merge.avgConfidence >= 0.7 {
    "text-amber-400"
  } else {
    "text-red-400"
  }
  div(
    list{Attrs.class_("flex items-center gap-3 p-3 border-b border-gray-800")},
    list{
      span(list{Attrs.class_(`text-xs ${statusColor} w-16`)}, list{text(merge.status)}),
      span(list{Attrs.class_("text-sm text-gray-200 w-32 truncate")}, list{text(merge.repo)}),
      span(
        list{Attrs.class_("text-xs text-gray-500 w-40")},
        list{text(`${merge.sourceBranch} -> ${merge.targetBranch}`)},
      ),
      span(
        list{Attrs.class_("text-xs text-gray-400 w-24")},
        list{
          text(
            `${Int.toString(merge.resolvedCount)}/${Int.toString(merge.conflictCount)} resolved`,
          ),
        },
      ),
      span(
        list{Attrs.class_(`text-xs w-16 ${confColor}`)},
        list{text(`${Float.toFixed(merge.avgConfidence *. 100.0, ~digits=0)}% conf`)},
      ),
      if merge.status === "in_progress" {
        div(
          list{Attrs.class_("flex gap-2")},
          list{
            button(
              list{
                Attrs.class_(
                  "px-2 py-1 text-xs bg-green-700 text-white rounded hover:bg-green-600",
                ),
                Events.onClick(Migration(AcceptMerge(merge.sessionId))),
              },
              list{text("Accept")},
            ),
            button(
              list{
                Attrs.class_("px-2 py-1 text-xs bg-red-700 text-white rounded hover:bg-red-600"),
                Events.onClick(Migration(RollbackMerge(merge.sessionId))),
              },
              list{text("Rollback")},
            ),
          },
        )
      } else {
        noNode
      },
      span(
        list{Attrs.class_("text-xs text-gray-600 w-28 text-right")},
        list{text(merge.timestamp)},
      ),
    },
  )
}

/// Render the category tabs.
let renderTabs = (active: migrationCategory): Tea_Vdom.t<msg> => {
  let tabs: array<migrationCategory> = [
    MigrationDashboard,
    MigrationTimeline,
    MigrationReports,
    MigrationSubmissions,
    MigrationMergeResolver,
  ]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-indigo-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Migration(SetMigrationCategory(tab))),
        },
        list{text(MigrationEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Render the report type selector pills.
let renderReportTypeSelector = (active: migrationReportType): Tea_Vdom.t<msg> => {
  let types: array<migrationReportType> = [PerRepoReport, CrossRepoReport, V13TrialReport]
  div(
    list{Attrs.class_("flex gap-2 mb-4")},
    types
    ->Array.map(rt => {
      let isActive = rt === active
      button(
        list{
          Attrs.class_(
            `px-3 py-1 text-xs rounded transition-colors ${isActive
                ? "bg-indigo-600 text-white"
                : "bg-gray-800 text-gray-400 hover:text-gray-200"}`,
          ),
          Events.onClick(Migration(SetMigrationReportType(rt))),
        },
        list{text(MigrationEngine.reportTypeLabel(rt))},
      )
    })
    ->List.fromArray,
  )
}

/// Dashboard tab — aggregate stats + version distribution + repo table.
let renderDashboard = (mig: migrationState): Tea_Vdom.t<msg> => {
  let filtered = MigrationEngine.filterRepos(mig.repos, mig.filterText)
  div(
    list{Attrs.class_("space-y-6")},
    list{
      // Stat cards
      div(
        list{Attrs.class_("flex gap-4 text-sm")},
        list{
          div(
            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 flex-1")},
            list{
              div(
                list{Attrs.class_("text-gray-500 text-xs uppercase tracking-wider mb-1")},
                list{text("Repos")},
              ),
              div(
                list{Attrs.class_("text-2xl font-light text-gray-200")},
                list{text(Int.toString(mig.totalRepos))},
              ),
            },
          ),
          div(
            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 flex-1")},
            list{
              div(
                list{Attrs.class_("text-gray-500 text-xs uppercase tracking-wider mb-1")},
                list{text("Avg Health")},
              ),
              div(
                list{
                  Attrs.class_(`text-2xl font-light ${MigrationEngine.healthColor(mig.avgHealth)}`),
                },
                list{text(MigrationEngine.healthPercent(mig.avgHealth))},
              ),
            },
          ),
          div(
            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 flex-1")},
            list{
              div(
                list{Attrs.class_("text-gray-500 text-xs uppercase tracking-wider mb-1")},
                list{text("Ready")},
              ),
              div(
                list{Attrs.class_("text-2xl font-light text-green-400")},
                list{text(Int.toString(mig.readyCount))},
              ),
            },
          ),
          div(
            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 flex-1")},
            list{
              div(
                list{Attrs.class_("text-gray-500 text-xs uppercase tracking-wider mb-1")},
                list{text("Blocked")},
              ),
              div(
                list{Attrs.class_("text-2xl font-light text-red-400")},
                list{text(Int.toString(mig.blockedCount))},
              ),
            },
          ),
          div(
            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 flex-1")},
            list{
              div(
                list{Attrs.class_("text-gray-500 text-xs uppercase tracking-wider mb-1")},
                list{text("Velocity")},
              ),
              div(
                list{Attrs.class_("text-2xl font-light text-indigo-400")},
                list{text(`${Float.toFixed(mig.velocity *. 100.0, ~digits=1)}%/sess`)},
              ),
            },
          ),
        },
      ),
      // Constraints strip (Panel-L inline)
      renderConstraintStrip(mig.constraints),
      // Version distribution
      renderVersionDistribution(mig.repos),
      // Proof obligations
      renderObligations(mig.obligations),
      // Repo table
      div(
        list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(
                "flex items-center gap-3 p-3 border-b border-gray-700 text-xs text-gray-500 uppercase tracking-wider",
              ),
            },
            list{
              span(list{Attrs.class_("w-8")}, list{text("St")}),
              span(list{Attrs.class_("w-40")}, list{text("Repository")}),
              span(list{Attrs.class_("w-20")}, list{text("Version")}),
              span(list{Attrs.class_("flex-1")}, list{text("Health")}),
              span(list{Attrs.class_("w-12")}, list{text("Trend")}),
              span(list{Attrs.class_("w-16 text-right")}, list{text("Depr.")}),
              span(list{Attrs.class_("w-16 text-right")}, list{text("Modern")}),
              span(list{Attrs.class_("w-24 text-right")}, list{text("Config")}),
            },
          ),
          div(
            list{Attrs.class_("max-h-96 overflow-y-auto")},
            filtered->Array.map(r => renderRepoRow(r))->List.fromArray,
          ),
        },
      ),
    },
  )
}

/// Timeline tab — session history.
let renderTimeline = (mig: migrationState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400")},
            list{
              text(`${Int.toString(MigrationEngine.activeSessions(mig.sessions))} active sessions`),
            },
          ),
        },
      ),
      if Array.length(mig.sessions) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 mt-8")},
          list{
            div(list{Attrs.class_("text-lg mb-2")}, list{text("No observation sessions")}),
            div(
              list{Attrs.class_("text-sm")},
              list{text("Use feedback-o-tron to begin a migration observation")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg overflow-hidden")},
          list{
            div(
              list{Attrs.class_("max-h-96 overflow-y-auto")},
              mig.sessions->Array.map(s => renderSessionRow(s))->List.fromArray,
            ),
          },
        )
      },
    },
  )
}

/// Reports tab — report type selector + placeholder for generated content.
let renderReports = (mig: migrationState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      renderReportTypeSelector(mig.activeReportType),
      div(
        list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-6")},
        list{
          switch mig.activeReportType {
          | PerRepoReport =>
            div(
              list{},
              list{
                div(
                  list{Attrs.class_("text-sm font-medium text-gray-300 mb-2")},
                  list{text("Per-Repository Reports")},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-4")},
                  list{text("Before/after migration tables, issues, recommendations per repo")},
                ),
                if Array.length(mig.repos) > 0 {
                  div(
                    list{Attrs.class_("space-y-2")},
                    mig.repos
                    ->Array.map(r =>
                      div(
                        list{
                          Attrs.class_("flex items-center gap-3 p-2 hover:bg-gray-800/50 rounded"),
                        },
                        list{
                          span(
                            list{Attrs.class_("text-sm text-gray-300 w-40")},
                            list{text(r.name)},
                          ),
                          renderHealthBar(r.healthScore),
                          span(
                            list{
                              Attrs.class_(`text-xs ${MigrationEngine.healthColor(r.healthScore)}`),
                            },
                            list{text(MigrationEngine.healthPercent(r.healthScore))},
                          ),
                          span(
                            list{Attrs.class_("text-xs text-gray-500")},
                            list{text(`${Int.toString(r.deprecatedCount)} deprecated`)},
                          ),
                        },
                      )
                    )
                    ->List.fromArray,
                  )
                } else {
                  div(
                    list{Attrs.class_("text-gray-500 text-sm")},
                    list{
                      text("No repo data available. Run panic-attack migration-snapshot first."),
                    },
                  )
                },
              },
            )
          | CrossRepoReport =>
            div(
              list{},
              list{
                div(
                  list{Attrs.class_("text-sm font-medium text-gray-300 mb-2")},
                  list{text("Cross-Repository Aggregation")},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-4")},
                  list{text("Common pain points, average health improvement, migration velocity")},
                ),
                div(
                  list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
                  list{
                    span(list{}, list{text(`${Int.toString(mig.totalRepos)} repos tracked`)}),
                    span(
                      list{},
                      list{text(`Avg health: ${MigrationEngine.healthPercent(mig.avgHealth)}`)},
                    ),
                    span(
                      list{},
                      list{
                        text(
                          `Velocity: ${Float.toFixed(mig.velocity *. 100.0, ~digits=1)}%/session`,
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          | V13TrialReport =>
            div(
              list{},
              list{
                div(
                  list{Attrs.class_("text-sm font-medium text-gray-300 mb-2")},
                  list{text("v13 Pre-Release Trial Report")},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-4")},
                  list{text("Performance data, regressions, missing features for ReScript team")},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text("Generate report after completing v13 migration sessions")},
                ),
              },
            )
          },
        },
      ),
    },
  )
}

/// Submissions tab — review queue.
let renderSubmissions = (mig: migrationState): Tea_Vdom.t<msg> => {
  let pending = MigrationEngine.pendingSubmissions(mig.submissions)
  div(
    list{Attrs.class_("space-y-4")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400")},
            list{text(`${Int.toString(pending)} pending review`)},
          ),
          if pending > 0 {
            button(
              list{
                Attrs.class_(
                  "px-3 py-1 text-xs bg-indigo-600 text-white rounded hover:bg-indigo-500",
                ),
                Events.onClick(Migration(SubmitApproved)),
                KeyboardNav.onActivate(Migration(SubmitApproved)),
              },
              list{text("Submit Approved")},
            )
          } else {
            noNode
          },
        },
      ),
      if Array.length(mig.submissions) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 mt-8")},
          list{
            div(list{Attrs.class_("text-lg mb-2")}, list{text("No submissions")}),
            div(
              list{Attrs.class_("text-sm")},
              list{text("Issues discovered during migration observations will appear here")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg overflow-hidden")},
          list{
            div(
              list{Attrs.class_("max-h-96 overflow-y-auto")},
              mig.submissions->Array.map(s => renderSubmissionRow(s))->List.fromArray,
            ),
          },
        )
      },
    },
  )
}

/// Merge Resolver tab — conflict resolution timeline.
let renderMergeResolver = (mig: migrationState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400")},
            list{text(`${Int.toString(Array.length(mig.mergeResolutions))} merge sessions`)},
          ),
        },
      ),
      if Array.length(mig.mergeResolutions) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 mt-8")},
          list{
            div(list{Attrs.class_("text-lg mb-2")}, list{text("No merge resolutions")}),
            div(
              list{Attrs.class_("text-sm mb-4")},
              list{text("Use merge-resolver to begin resolving conflicts with rollback support")},
            ),
            div(
              list{Attrs.class_("text-xs text-gray-600")},
              list{text("merge-resolver begin <REPO> <BRANCH>")},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg overflow-hidden")},
          list{
            div(
              list{Attrs.class_("max-h-96 overflow-y-auto")},
              mig.mergeResolutions->Array.map(m => renderMergeRow(m))->List.fromArray,
            ),
          },
        )
      },
    },
  )
}

/// Main view for the Migration Observatory panel.
let view = (mig: migrationState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Migration Observatory panel"),
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
                list{text("Migration Observatory")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("ReScript migration health, sessions, submissions")},
              ),
              if mig.loaded {
                span(
                  list{Attrs.class_("text-xs text-indigo-400 ml-2")},
                  list{
                    text(
                      `${Int.toString(mig.totalRepos)} repos | ${MigrationEngine.healthPercent(
                          mig.avgHealth,
                        )} avg`,
                    ),
                  },
                )
              } else {
                noNode
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              // Filter input
              if mig.loaded {
                input(
                  list{
                    Attrs.class_(
                      "px-3 py-1 text-xs bg-gray-800 border border-gray-700 rounded text-gray-300 w-48 placeholder-gray-600",
                    ),
                    Attrs.placeholder("Filter repos..."),
                    Attrs.value(mig.filterText),
                    Events.onInput(text => Migration(SetMigrationFilter(text))),
                  },
                  list{},
                )
              } else {
                noNode
              },
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs bg-indigo-600 text-white rounded hover:bg-indigo-500",
                  ),
                  Events.onClick(Migration(RefreshMigrationHealth)),
                  KeyboardNav.onActivate(Migration(RefreshMigrationHealth)),
                },
                list{text(mig.loaded ? "Refresh" : "Load Data")},
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
          if !mig.loaded {
            div(
              list{Attrs.class_("text-center text-gray-500 mt-12")},
              list{
                div(list{Attrs.class_("text-4xl mb-2")}, list{text("Migration Observatory")}),
                div(
                  list{Attrs.class_("text-sm mb-6")},
                  list{
                    text(
                      "Track ReScript migration health across 54+ repos with before/after snapshots, session observation, issue submission, and merge conflict resolution",
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-600 mb-4")},
                  list{
                    text(
                      "Data from panic-attack + feedback-o-tron + merge-resolver + Hypatia + VeriSimDB",
                    ),
                  },
                ),
                button(
                  list{
                    Attrs.class_("px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-500"),
                    Events.onClick(Migration(LoadMigrationData)),
                    KeyboardNav.onActivate(Migration(LoadMigrationData)),
                  },
                  list{text("Load Migration Data")},
                ),
              },
            )
          } else if mig.loading {
            div(
              list{Attrs.class_("text-center text-gray-400 mt-12"), Attrs.role("status")},
              list{
                div(
                  list{Attrs.class_("text-sm animate-pulse")},
                  list{text("Loading migration data...")},
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("space-y-4")},
              list{
                renderTabs(mig.activeCategory),
                switch mig.activeCategory {
                | MigrationDashboard => renderDashboard(mig)
                | MigrationTimeline => renderTimeline(mig)
                | MigrationReports => renderReports(mig)
                | MigrationSubmissions => renderSubmissions(mig)
                | MigrationMergeResolver => renderMergeResolver(mig)
                },
              },
            )
          },
        },
      ),
      // Error display
      switch mig.error {
      | Some(e) =>
        div(
          list{Attrs.class_("p-3 bg-red-900/30 border-t border-red-700"), Attrs.role("alert")},
          list{span(list{Attrs.class_("text-xs text-red-400")}, list{text(e)})},
        )
      | None => noNode
      },
    },
  )
}
