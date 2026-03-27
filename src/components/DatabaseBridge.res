// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Database Bridge Component — VeriSimDB game state persistence.
/// Displays schema tree, query history, game state snapshot viewer, and
/// proof obligation badges for data integrity.

open Model
open Msg
open Tea.Html

/// Render a proof obligation status badge.
let obligationBadge = (status: proofObligationStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | ObligationProven => ("bg-green-700 text-green-100", "Proven")
  | ObligationUnproven => ("bg-gray-700 text-gray-300", "Unproven")
  | ObligationViolated => ("bg-red-700 text-red-100", "Violated")
  | ObligationTimeout => ("bg-yellow-700 text-yellow-100", "Timeout")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Render a query status indicator.
let queryStatusIndicator = (status: queryStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | QuerySuccess => ("text-green-400", "OK")
  | QueryFailed => ("text-red-400", "Fail")
  | QueryRunning => ("text-yellow-400 animate-pulse", "Running")
  | QueryCancelled => ("text-gray-500", "Cancelled")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a column data type label.
let colTypeLabel = (dt: columnDataType): string => {
  switch dt {
  | ColInt => "Int"
  | ColFloat => "Float"
  | ColString => "String"
  | ColBool => "Bool"
  | ColTimestamp => "Timestamp"
  | ColBlob => "Blob"
  | ColJson => "JSON"
  }
}

/// Main view function for the Database Bridge panel.
let view = (state: databaseBridgeState): Tea_Vdom.t<msg> => {
  let provenCount =
    state.proofObligations->Array.filter(o => o.status == ObligationProven)->Array.length
  let totalObligations = Array.length(state.proofObligations)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Database Bridge — VeriSimDB Game State Persistence"),
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
                list{Attrs.class_("text-lg font-bold text-teal-300")},
                list{text("Database Bridge")},
              ),
              span(
                list{
                  Attrs.class_(
                    "text-xs " ++ if state.connected {
                      "text-green-400"
                    } else {
                      "text-red-400"
                    },
                  ),
                },
                list{
                  text(
                    if state.connected {
                      "Connected"
                    } else {
                      "Disconnected"
                    },
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(Int.toString(Array.length(state.schemas)) ++ " schemas")},
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-teal-800 hover:bg-teal-700 text-white rounded"),
              Events.onClick(DatabaseBridge(DbBStarted)),
            },
            list{text("Refresh")},
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
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Schema {
                  "bg-teal-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DatabaseBridge(SetDbBTab(Schema))),
            },
            list{text("Schema")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Queries {
                  "bg-teal-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DatabaseBridge(SetDbBTab(Queries))),
            },
            list{text("Queries")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == GameState {
                  "bg-teal-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DatabaseBridge(SetDbBTab(GameState))),
            },
            list{text("Game State")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == ProofObligations {
                  "bg-teal-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DatabaseBridge(SetDbBTab(ProofObligations))),
            },
            list{
              text(
                "Proofs (" ++
                Int.toString(provenCount) ++
                "/" ++
                Int.toString(totalObligations) ++ ")",
              ),
            },
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
                Events.onClick(DatabaseBridge(DismissDbBError)),
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
          | Schema =>
            div(
              list{Attrs.class_("space-y-3")},
              state.schemas
              ->Array.map(s =>
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("text-sm font-bold text-teal-300 mb-1")},
                      list{text(s.name)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mb-2")},
                      list{text(s.description)},
                    ),
                    div(
                      list{Attrs.class_("space-y-1")},
                      s.columns
                      ->Array.map(col =>
                        div(
                          list{Attrs.class_("flex items-center gap-2 text-xs")},
                          list{
                            span(
                              list{Attrs.class_("font-mono text-gray-300 w-32")},
                              list{
                                text(
                                  col.name ++ if col.primaryKey {
                                    " (PK)"
                                  } else {
                                    ""
                                  },
                                ),
                              },
                            ),
                            span(
                              list{Attrs.class_("text-teal-400 w-16")},
                              list{text(colTypeLabel(col.dataType))},
                            ),
                            span(
                              list{Attrs.class_("text-gray-600")},
                              list{
                                text(
                                  if col.nullable {
                                    "nullable"
                                  } else {
                                    "not null"
                                  },
                                ),
                              },
                            ),
                            switch col.constraint_ {
                            | Some(c) => span(list{Attrs.class_("text-yellow-400")}, list{text(c)})
                            | None => Tea_Html.noNode
                            },
                          },
                        )
                      )
                      ->List.fromArray,
                    ),
                    if Array.length(s.invariants) > 0 {
                      div(
                        list{Attrs.class_("mt-2 pt-2 border-t border-gray-800")},
                        s.invariants
                        ->Array.map(inv =>
                          div(
                            list{Attrs.class_("text-xs text-yellow-400 font-mono")},
                            list{text("INV: " ++ inv)},
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
          | Queries =>
            div(
              list{Attrs.class_("space-y-1")},
              state.queries
              ->Array.map(q =>
                div(
                  list{Attrs.class_("py-2 border-b border-gray-800/50")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        queryStatusIndicator(q.status),
                        span(
                          list{Attrs.class_("text-sm font-mono text-gray-300 flex-1 truncate")},
                          list{text(q.queryText)},
                        ),
                        span(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(Int.toString(q.rowCount) ++ " rows")},
                        ),
                        span(
                          list{Attrs.class_("text-xs text-gray-600")},
                          list{text(Float.toFixed(q.durationMs, ~digits=1) ++ "ms")},
                        ),
                      },
                    ),
                    if Array.length(q.optimisationHints) > 0 {
                      div(
                        list{Attrs.class_("flex flex-wrap gap-1 mt-1")},
                        q.optimisationHints
                        ->Array.map(h =>
                          span(
                            list{
                              Attrs.class_(
                                "px-2 py-0.5 text-xs bg-teal-900/50 text-teal-300 rounded",
                              ),
                            },
                            list{text(h)},
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
          | GameState =>
            switch state.gameStateSnapshot {
            | Some(snap) =>
              div(
                list{Attrs.class_("space-y-3")},
                list{
                  div(
                    list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
                    list{
                      span(list{}, list{text("Snapshot: " ++ snap.snapshotId)}),
                      span(list{}, list{text("Tables: " ++ Int.toString(snap.tableCount))}),
                      span(list{}, list{text("Total rows: " ++ Int.toString(snap.totalRows))}),
                      span(
                        list{},
                        list{text("Size: " ++ Int.toString(snap.sizeBytes / 1024) ++ " KB")},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("space-y-1")},
                    snap.tableSizes
                    ->Array.map(((tName, rowCount)) =>
                      div(
                        list{Attrs.class_("flex items-center gap-3 py-1")},
                        list{
                          span(
                            list{Attrs.class_("text-sm font-mono text-gray-300 w-40")},
                            list{text(tName)},
                          ),
                          span(
                            list{Attrs.class_("text-xs text-gray-500")},
                            list{text(Int.toString(rowCount) ++ " rows")},
                          ),
                          // Simple bar
                          div(
                            list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded overflow-hidden")},
                            list{
                              div(
                                list{
                                  Attrs.class_("h-full bg-teal-600"),
                                  Attrs.style(
                                    "width",
                                    Float.toFixed(
                                      if snap.totalRows > 0 {
                                        Int.toFloat(rowCount) /.
                                        Int.toFloat(snap.totalRows) *. 100.0
                                      } else {
                                        0.0
                                      },
                                      ~digits=1,
                                    ) ++ "%",
                                  ),
                                },
                                list{},
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
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{
                  text(
                    "No game state snapshot available. Take a snapshot to inspect persisted data.",
                  ),
                },
              )
            }
          | ProofObligations =>
            div(
              list{Attrs.class_("space-y-2")},
              state.proofObligations
              ->Array.map(o =>
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        obligationBadge(o.status),
                        span(
                          list{Attrs.class_("text-sm text-gray-200")},
                          list{text(o.description)},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 font-mono mt-1")},
                      list{text(o.schemaName ++ ": " ++ o.statement)},
                    ),
                    switch o.counterexample {
                    | Some(ce) =>
                      div(
                        list{Attrs.class_("text-xs text-red-400 mt-1")},
                        list{text("Counterexample: " ++ ce)},
                      )
                    | None => Tea_Html.noNode
                    },
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
