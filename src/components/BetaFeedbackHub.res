// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL BetaFeedbackHub — feedback-o-tron integration and player feedback
/// triage for IDApTIK beta testing programmes.
///
/// Five tabs: Inbox (feedback list with upvote/downvote), Triaged (processed
/// entries), Sentiment (chart placeholder), Submit (new feedback form), and
/// Analytics (aggregate statistics).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for betaFeedbackTab variants.
let tabLabel = (tab: betaFeedbackTab): string =>
  switch tab {
  | TabInbox => "Inbox"
  | TabTriaged => "Triaged"
  | TabSentiment => "Sentiment"
  | TabSubmit => "Submit"
  | TabAnalytics => "Analytics"
  }

/// Render the tab bar.
let renderTabs = (active: betaFeedbackTab): Tea_Vdom.t<msg> => {
  let tabs: array<betaFeedbackTab> = [TabInbox, TabTriaged, TabSentiment, TabSubmit, TabAnalytics]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-3 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(BetaFeedbackHub(SetBfhTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Category badge colour.
let categoryBadge = (cat: feedbackCategory): Tea_Vdom.t<msg> => {
  let (colour, lbl) = switch cat {
  | FeedbackBug => ("bg-red-600 text-white", "BUG")
  | FeedbackFeature => ("bg-blue-600 text-white", "FEAT")
  | FeedbackBalance => ("bg-purple-600 text-white", "BAL")
  | FeedbackUx => ("bg-cyan-600 text-white", "UX")
  | FeedbackPerformance => ("bg-amber-600 text-white", "PERF")
  | FeedbackOther => ("bg-gray-600 text-gray-200", "OTHER")
  }
  span(list{Attrs.class_(`px-1.5 py-0.5 text-xs rounded font-mono ${colour}`)}, list{text(lbl)})
}

/// Priority indicator.
let priorityIndicator = (priority: feedbackPriority): Tea_Vdom.t<msg> => {
  let (colour, lbl) = switch priority {
  | FeedbackCritical => ("text-red-400", "P0")
  | FeedbackHigh => ("text-orange-400", "P1")
  | FeedbackMedium => ("text-amber-400", "P2")
  | FeedbackLow => ("text-gray-400", "P3")
  }
  span(list{Attrs.class_(`text-xs font-mono ${colour}`)}, list{text(lbl)})
}

/// Sentiment icon.
let sentimentIcon = (sentiment: feedbackSentiment): Tea_Vdom.t<msg> => {
  let (colour, sym) = switch sentiment {
  | SentimentPositive => ("text-emerald-400", "+")
  | SentimentNeutral => ("text-gray-400", "=")
  | SentimentNegative => ("text-red-400", "-")
  | SentimentUnknown => ("text-gray-600", "?")
  }
  span(list{Attrs.class_(`text-xs font-mono ${colour}`)}, list{text(sym)})
}

/// Status label.
let statusLabel = (status: feedbackStatus): string =>
  switch status {
  | FeedbackNew => "NEW"
  | FeedbackTriaged => "TRIAGED"
  | FeedbackInProgress => "IN PROGRESS"
  | FeedbackResolved => "RESOLVED"
  | FeedbackWontFix => "WON'T FIX"
  }

// =========================================================================
// Tab content views
// =========================================================================

/// Render a feedback entry row with upvote/downvote buttons.
let feedbackRow = (entry: feedbackEntry): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 px-3 py-2 bg-gray-800 rounded text-sm cursor-pointer hover:bg-gray-750",
      ),
      Events.onClick(BetaFeedbackHub(SelectFeedback(entry.id))),
    },
    list{
      // Vote buttons
      div(
        list{Attrs.class_("flex flex-col items-center gap-0.5")},
        list{
          button(
            list{
              Attrs.class_("text-xs text-gray-500 hover:text-emerald-400 cursor-pointer"),
              Events.onClick(BetaFeedbackHub(Upvote(entry.id))),
            },
            list{text("^")},
          ),
          span(
            list{Attrs.class_("text-xs font-mono text-gray-400")},
            list{text(Int.toString(entry.upvotes - entry.downvotes))},
          ),
          button(
            list{
              Attrs.class_("text-xs text-gray-500 hover:text-red-400 cursor-pointer"),
              Events.onClick(BetaFeedbackHub(Downvote(entry.id))),
            },
            list{text("v")},
          ),
        },
      ),
      // Priority and category
      priorityIndicator(entry.priority),
      categoryBadge(entry.category),
      sentimentIcon(entry.sentiment),
      // Title
      span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(entry.title)}),
      // Submitter and platform
      span(
        list{Attrs.class_("text-gray-600 text-xs")},
        list{text(`${entry.submittedBy} (${entry.platform})`)},
      ),
    },
  )
}

/// Inbox tab: all feedback entries sorted by newest or votes.
let renderInboxTab = (state: betaFeedbackHubState): Tea_Vdom.t<msg> => {
  let newEntries = state.entries->Array.filter(e =>
    switch e.status {
    | FeedbackNew => true
    | _ => false
    }
  )
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      // Controls
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(
            list{Attrs.class_("text-sm text-gray-400")},
            list{text(`${Int.toString(Array.length(newEntries))} new feedback item(s)`)},
          ),
          button(
            list{
              Attrs.class_(
                `px-2 py-1 text-xs rounded cursor-pointer ${state.sortByUpvotes
                    ? "bg-cyan-700 text-white"
                    : "bg-gray-700 text-gray-400"}`,
              ),
              Events.onClick(BetaFeedbackHub(ToggleSortByVotes)),
            },
            list{text(state.sortByUpvotes ? "Sort: Votes" : "Sort: Recent")},
          ),
        },
      ),
      // Entry list
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-96 overflow-y-auto")},
        newEntries->Array.map(entry => feedbackRow(entry))->List.fromArray,
      ),
    },
  )
}

/// Triaged tab: entries that have been processed.
let renderTriagedTab = (state: betaFeedbackHubState): Tea_Vdom.t<msg> => {
  let processed = state.entries->Array.filter(e =>
    switch e.status {
    | FeedbackNew => false
    | _ => true
    }
  )
  if Array.length(processed) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No triaged feedback yet.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-1 p-4 max-h-96 overflow-y-auto")},
      processed
      ->Array.map(entry => {
        div(
          list{Attrs.class_("flex items-center gap-3 px-3 py-2 bg-gray-800 rounded text-sm")},
          list{
            categoryBadge(entry.category),
            span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(entry.title)}),
            span(
              list{Attrs.class_("text-xs text-gray-500 font-mono")},
              list{text(statusLabel(entry.status))},
            ),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Sentiment tab: chart placeholder showing positive/neutral/negative distribution.
let renderSentimentTab = (state: betaFeedbackHubState): Tea_Vdom.t<msg> => {
  let positive = state.entries->Array.filter(e => e.sentiment === SentimentPositive)->Array.length
  let neutral = state.entries->Array.filter(e => e.sentiment === SentimentNeutral)->Array.length
  let negative = state.entries->Array.filter(e => e.sentiment === SentimentNegative)->Array.length
  let total = Array.length(state.entries)

  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      // Sentiment summary
      div(
        list{Attrs.class_("grid grid-cols-3 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-emerald-400")},
                list{text(Int.toString(positive))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Positive")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-300")},
                list{text(Int.toString(neutral))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Neutral")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-red-400")},
                list{text(Int.toString(negative))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Negative")}),
            },
          ),
        },
      ),
      // Chart placeholder
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-32 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{text(`Sentiment distribution chart (${Int.toString(total)} entries)`)},
          ),
        },
      ),
    },
  )
}

/// Submit tab: new feedback form.
let renderSubmitTab = (state: betaFeedbackHubState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      h3(
        list{Attrs.class_("text-sm font-medium text-gray-300")},
        list{text("Submit New Feedback")},
      ),
      // Title input
      div(
        list{Attrs.class_("flex flex-col gap-1")},
        list{
          label(list{Attrs.class_("text-xs text-gray-500")}, list{text("Title")}),
          input(
            list{
              Attrs.class_(
                "w-full bg-gray-800 text-gray-200 text-sm rounded px-3 py-2 border border-gray-700 focus:border-cyan-600 focus:outline-none",
              ),
              Attrs.placeholder("Brief description of the feedback..."),
              Events.onInput(text => BetaFeedbackHub(UpdateSubmitTitle(text))),
            },
            list{},
          ),
        },
      ),
      // Body textarea
      div(
        list{Attrs.class_("flex flex-col gap-1")},
        list{
          label(list{Attrs.class_("text-xs text-gray-500")}, list{text("Details")}),
          textarea(
            list{
              Attrs.class_(
                "w-full h-24 bg-gray-800 text-gray-200 text-sm rounded p-3 border border-gray-700 focus:border-cyan-600 focus:outline-none resize-y",
              ),
              Attrs.placeholder("Describe the feedback in detail..."),
              Events.onInput(text => BetaFeedbackHub(UpdateSubmitBody(text))),
            },
            list{},
          ),
        },
      ),
      // Submit button
      div(
        list{Attrs.class_("flex justify-end")},
        list{
          button(
            list{
              Attrs.class_(
                `px-4 py-2 text-sm rounded font-medium cursor-pointer ${state.submitting
                    ? "bg-gray-600 text-gray-400"
                    : "bg-emerald-700 text-white hover:bg-emerald-600"}`,
              ),
              Events.onClick(BetaFeedbackHub(SubmitFeedback)),
            },
            list{text(state.submitting ? "Submitting..." : "Submit Feedback")},
          ),
        },
      ),
    },
  )
}

/// Analytics tab: aggregate statistics from all feedback.
let renderAnalyticsTab = (state: betaFeedbackHubState): Tea_Vdom.t<msg> => {
  let total = Array.length(state.entries)
  let bugs = state.entries->Array.filter(e => e.category === FeedbackBug)->Array.length
  let features = state.entries->Array.filter(e => e.category === FeedbackFeature)->Array.length
  let balance = state.entries->Array.filter(e => e.category === FeedbackBalance)->Array.length

  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-300")},
                list{text(Int.toString(total))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Total")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-red-400")},
                list{text(Int.toString(bugs))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Bugs")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-blue-400")},
                list{text(Int.toString(features))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Features")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-purple-400")},
                list{text(Int.toString(balance))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Balance")}),
            },
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
let view = (state: betaFeedbackHubState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabInbox => renderInboxTab(state)
  | TabTriaged => renderTriagedTab(state)
  | TabSentiment => renderSentimentTab(state)
  | TabSubmit => renderSubmitTab(state)
  | TabAnalytics => renderAnalyticsTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Beta Feedback Hub")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`${Int.toString(Array.length(state.entries))} entries`)},
          ),
        },
      ),
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800"),
          },
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
