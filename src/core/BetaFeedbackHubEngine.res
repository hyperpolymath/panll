// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Beta Feedback Hub Engine — pure computation and helpers for the
/// Beta Feedback Hub panel. Provides default state, label formatting,
/// filtering, counting, sentiment analysis, and analytics computation.

open BetaFeedbackHubModel

/// Default state for the Beta Feedback Hub panel.
/// Starts on the Inbox tab with no filters and upvote sorting disabled.
let defaultState: betaFeedbackHubState = {
  activeTab: TabInbox,
  entries: [],
  selectedEntry: None,
  filter: "",
  categoryFilter: None,
  sortByUpvotes: false,
  submitting: false,
  analytics: None,
  error: None,
}

/// Human-readable label for each tab in the Beta Feedback Hub panel.
let tabLabel = (tab: betaFeedbackTab): string =>
  switch tab {
  | TabInbox => "Inbox"
  | TabTriaged => "Triaged"
  | TabSentiment => "Sentiment"
  | TabSubmit => "Submit"
  | TabAnalytics => "Analytics"
  }

/// All tabs in display order.
let allTabs: array<betaFeedbackTab> = [TabInbox, TabTriaged, TabSentiment, TabSubmit, TabAnalytics]

/// Human-readable label for a feedback category.
let categoryLabel = (cat: feedbackCategory): string =>
  switch cat {
  | FeedbackBug => "Bug"
  | FeedbackFeature => "Feature Request"
  | FeedbackBalance => "Balance"
  | FeedbackUx => "UX"
  | FeedbackPerformance => "Performance"
  | FeedbackOther => "Other"
  }

/// CSS colour class for a feedback category.
let categoryColor = (cat: feedbackCategory): string =>
  switch cat {
  | FeedbackBug => "text-red-400"
  | FeedbackFeature => "text-blue-400"
  | FeedbackBalance => "text-yellow-400"
  | FeedbackUx => "text-purple-400"
  | FeedbackPerformance => "text-orange-400"
  | FeedbackOther => "text-gray-400"
  }

/// Human-readable label for a feedback priority.
let priorityLabel = (p: feedbackPriority): string =>
  switch p {
  | FeedbackCritical => "Critical"
  | FeedbackHigh => "High"
  | FeedbackMedium => "Medium"
  | FeedbackLow => "Low"
  }

/// CSS colour class for a feedback priority.
let priorityColor = (p: feedbackPriority): string =>
  switch p {
  | FeedbackCritical => "text-red-400"
  | FeedbackHigh => "text-orange-400"
  | FeedbackMedium => "text-yellow-400"
  | FeedbackLow => "text-green-400"
  }

/// Human-readable label for a feedback sentiment.
let sentimentLabel = (s: feedbackSentiment): string =>
  switch s {
  | SentimentPositive => "Positive"
  | SentimentNeutral => "Neutral"
  | SentimentNegative => "Negative"
  | SentimentUnknown => "Unknown"
  }

/// CSS colour class for a feedback sentiment.
let sentimentColor = (s: feedbackSentiment): string =>
  switch s {
  | SentimentPositive => "text-green-400"
  | SentimentNeutral => "text-gray-400"
  | SentimentNegative => "text-red-400"
  | SentimentUnknown => "text-gray-500"
  }

/// Human-readable label for a feedback status.
let statusLabel = (s: feedbackStatus): string =>
  switch s {
  | FeedbackNew => "New"
  | FeedbackTriaged => "Triaged"
  | FeedbackInProgress => "In Progress"
  | FeedbackResolved => "Resolved"
  | FeedbackWontFix => "Won't Fix"
  }

/// Count entries by category.
let countByCategory = (entries: array<feedbackEntry>, cat: feedbackCategory): int =>
  entries->Array.filter(e => e.category == cat)->Array.length

/// Count entries by sentiment.
let countBySentiment = (entries: array<feedbackEntry>, s: feedbackSentiment): int =>
  entries->Array.filter(e => e.sentiment == s)->Array.length

/// Count entries by status.
let countByStatus = (entries: array<feedbackEntry>, s: feedbackStatus): int =>
  entries->Array.filter(e => e.status == s)->Array.length

/// Filter entries by text search and optional category filter.
let filterEntries = (
  entries: array<feedbackEntry>,
  filter: string,
  catFilter: option<feedbackCategory>,
): array<feedbackEntry> => {
  let filtered = if filter == "" {
    entries
  } else {
    let q = filter->String.toLowerCase
    entries->Array.filter(e =>
      e.title->String.toLowerCase->String.includes(q) ||
        e.body->String.toLowerCase->String.includes(q)
    )
  }
  switch catFilter {
  | None => filtered
  | Some(cat) => filtered->Array.filter(e => e.category == cat)
  }
}

/// Net votes score (upvotes - downvotes).
let netVotes = (entry: feedbackEntry): int => entry.upvotes - entry.downvotes

/// Sort entries by net votes (descending).
let sortByVotes = (entries: array<feedbackEntry>): array<feedbackEntry> =>
  entries->Array.toSorted((a, b) => Int.compare(netVotes(b), netVotes(a)))

/// Compute analytics from all entries.
let computeAnalytics = (entries: array<feedbackEntry>): feedbackAnalytics => {
  let total = Array.length(entries)
  let resolved = countByStatus(entries, FeedbackResolved)
  let wontFix = countByStatus(entries, FeedbackWontFix)
  {
    totalEntries: total,
    byCategoryCount: [
      (FeedbackBug, countByCategory(entries, FeedbackBug)),
      (FeedbackFeature, countByCategory(entries, FeedbackFeature)),
      (FeedbackBalance, countByCategory(entries, FeedbackBalance)),
      (FeedbackUx, countByCategory(entries, FeedbackUx)),
      (FeedbackPerformance, countByCategory(entries, FeedbackPerformance)),
      (FeedbackOther, countByCategory(entries, FeedbackOther)),
    ],
    bySentimentCount: [
      (SentimentPositive, countBySentiment(entries, SentimentPositive)),
      (SentimentNeutral, countBySentiment(entries, SentimentNeutral)),
      (SentimentNegative, countBySentiment(entries, SentimentNegative)),
      (SentimentUnknown, countBySentiment(entries, SentimentUnknown)),
    ],
    avgSentimentScore: {
      let pos = Float.fromInt(countBySentiment(entries, SentimentPositive))
      let neg = Float.fromInt(countBySentiment(entries, SentimentNegative))
      if total == 0 { 0.0 } else { (pos -. neg) /. Float.fromInt(total) }
    },
    triageCompletionRate: if total == 0 {
      0.0
    } else {
      Float.fromInt(resolved + wontFix) /. Float.fromInt(total)
    },
  }
}
