// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Beta Feedback Hub Engine — pure functions for feedback triage and sentiment.

open BetaFeedbackHubModel

let defaultState: betaFeedbackHubState = {
  activeTab: TabInbox,
  entries: [],
  selectedEntry: None,
  filter: "",
  categoryFilter: None,
  sortByUpvotes: false,
  submitting: false,
  error: None,
}

let tabLabel = (tab: betaFeedbackTab): string =>
  switch tab {
  | TabInbox => "Inbox"
  | TabTriaged => "Triaged"
  | TabSentiment => "Sentiment"
  | TabSubmit => "Submit"
  | TabAnalytics => "Analytics"
  }

let allTabs: array<betaFeedbackTab> = [TabInbox, TabTriaged, TabSentiment, TabSubmit, TabAnalytics]

/// Category label.
let categoryLabel = (cat: feedbackCategory): string =>
  switch cat {
  | FeedbackBug => "Bug"
  | FeedbackFeature => "Feature Request"
  | FeedbackBalance => "Balance"
  | FeedbackUx => "UX"
  | FeedbackPerformance => "Performance"
  | FeedbackOther => "Other"
  }

/// Priority label.
let priorityLabel = (p: feedbackPriority): string =>
  switch p {
  | FeedbackCritical => "Critical"
  | FeedbackHigh => "High"
  | FeedbackMedium => "Medium"
  | FeedbackLow => "Low"
  }

/// Sentiment label.
let sentimentLabel = (s: feedbackSentiment): string =>
  switch s {
  | SentimentPositive => "Positive"
  | SentimentNeutral => "Neutral"
  | SentimentNegative => "Negative"
  | SentimentUnknown => "Unknown"
  }

/// Status label.
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

/// Filter entries.
let filterEntries = (entries: array<feedbackEntry>, filter: string, catFilter: option<feedbackCategory>): array<feedbackEntry> => {
  let filtered = if filter == "" { entries }
    else { entries->Array.filter(e => String.includes(e.title, filter) || String.includes(e.body, filter)) }
  switch catFilter {
  | None => filtered
  | Some(cat) => filtered->Array.filter(e => e.category == cat)
  }
}

/// Net votes score.
let netVotes = (entry: feedbackEntry): int => entry.upvotes - entry.downvotes
