// SPDX-License-Identifier: MPL-2.0

/// PanLL VeriSimDB Feeds Component — cross-repo analytics health and flow.
///
/// Two-column layout: left sidebar with feed list, right content with
/// detail view showing feed health, record count, and throughput.

open Model
open Msg
open Tea.Html

/// Render a feed health badge.
let healthBadge = (health: feedHealth): Tea_Vdom.t<msg> => {
  let (color, label) = switch health {
  | FeedHealthy => ("text-green-400", "Healthy")
  | FeedStale => ("text-amber-400", "Stale")
  | FeedError(reason) => ("text-red-400", "Error: " ++ reason)
  | FeedUnknown => ("text-gray-500", "Unknown")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a feed row in the sidebar.
let feedRow = (feed: dataFeed, selected: bool): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        "w-full text-left px-3 py-2 border-b border-gray-800 hover:bg-gray-800/60 transition-colors " ++ if (
          selected
        ) {
          "bg-gray-800/80 border-l-2 border-l-blue-500"
        } else {
          ""
        },
      ),
      Events.onClick(VerisimdbFeeds(SelectFeed(feed.feedId))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(feed.name)}),
          healthBadge(feed.health),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
        list{text(`${Int.toString(feed.recordCount)} records`)},
      ),
    },
  )
}

/// Render a tab button.
let tabBtn = (current: verisimdbFeedsTab, target: verisimdbFeedsTab, label: string): Tea_Vdom.t<
  msg,
> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++ if active {
          "bg-blue-600 text-white"
        } else {
          "bg-gray-800 text-gray-400 hover:bg-gray-700"
        },
      ),
      Events.onClick(VerisimdbFeeds(SetTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the VeriSimDB Feeds panel.
let view = (state: verisimdbFeedsState): Tea_Vdom.t<msg> => {
  let healthy = VerisimdbFeedsEngine.healthyFeedCount(state.feeds)
  let total = Array.length(state.feeds)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("VeriSimDB Feeds — Data Feed Health and Flow"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-cyan-300")},
                list{text("VeriSimDB Feeds")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(healthy)}/${Int.toString(total)} healthy`)},
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600"),
              Events.onClick(VerisimdbFeeds(CheckFeeds)),
              KeyboardNav.onActivate(VerisimdbFeeds(CheckFeeds)),
            },
            list{
              text(
                if state.checking {
                  "Checking..."
                } else {
                  "Check Health"
                },
              ),
            },
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        VerisimdbFeedsEngine.allTabs
        ->Array.map(t => tabBtn(state.activeTab, t, VerisimdbFeedsEngine.tabLabel(t)))
        ->List.fromArray,
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200",
            ),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Two-column layout
      div(
        list{Attrs.class_("flex flex-1 overflow-hidden")},
        list{
          // Left sidebar
          div(
            list{Attrs.class_("w-64 border-r border-gray-800 overflow-y-auto")},
            state.feeds
            ->Array.map(f => feedRow(f, state.selectedFeed == Some(f.feedId)))
            ->List.fromArray,
          ),
          // Right content
          div(
            list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
            list{
              switch state.selectedFeed {
              | None =>
                div(
                  list{Attrs.class_("flex items-center justify-center h-full text-gray-600")},
                  list{text("Select a feed to view details")},
                )
              | Some(feedId) =>
                switch state.feeds->Array.find(f => f.feedId == feedId) {
                | None => div(list{}, list{text("Feed not found")})
                | Some(feed) =>
                  div(
                    list{},
                    list{
                      h3(
                        list{Attrs.class_("text-md font-semibold text-gray-200 mb-3")},
                        list{text(feed.name)},
                      ),
                      div(
                        list{Attrs.class_("space-y-2")},
                        list{
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Source:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300")},
                                list{text(feed.source)},
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Health:")},
                              ),
                              healthBadge(feed.health),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Records:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300")},
                                list{text(Int.toString(feed.recordCount))},
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Throughput:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300")},
                                list{text(`${Float.toFixed(feed.throughput, ~digits=1)} rec/day`)},
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Last Update:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300 font-mono")},
                                list{text(feed.lastUpdate)},
                              ),
                            },
                          ),
                        },
                      ),
                    },
                  )
                }
              },
            },
          ),
        },
      ),
      // Footer
      div(
        list{Attrs.class_("px-4 py-2 border-t border-gray-800 text-xs text-gray-500")},
        list{
          text(
            `${Int.toString(
                VerisimdbFeedsEngine.totalRecords(state.feeds),
              )} total records across all feeds`,
          ),
        },
      ),
    },
  )
}
