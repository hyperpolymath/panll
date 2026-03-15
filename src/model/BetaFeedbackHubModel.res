// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Beta Feedback Hub Model — feedback-o-tron integration and player feedback triage.
/// This module has NO dependencies on other PanLL modules.

/// Feedback priority.
type feedbackPriority =
  | FeedbackCritical
  | FeedbackHigh
  | FeedbackMedium
  | FeedbackLow

/// Feedback category.
type feedbackCategory =
  | FeedbackBug
  | FeedbackFeature
  | FeedbackBalance
  | FeedbackUx
  | FeedbackPerformance
  | FeedbackOther

/// Feedback sentiment.
type feedbackSentiment =
  | SentimentPositive
  | SentimentNeutral
  | SentimentNegative
  | SentimentUnknown

/// Feedback processing status.
type feedbackStatus =
  | FeedbackNew
  | FeedbackTriaged
  | FeedbackInProgress
  | FeedbackResolved
  | FeedbackWontFix

/// A single feedback entry.
type feedbackEntry = {
  id: string,
  title: string,
  body: string,
  category: feedbackCategory,
  priority: feedbackPriority,
  sentiment: feedbackSentiment,
  submittedBy: string,
  submittedAt: string,
  upvotes: int,
  downvotes: int,
  status: feedbackStatus,
  platform: string,
}

/// Active tab.
type betaFeedbackTab =
  | TabInbox
  | TabTriaged
  | TabSentiment
  | TabSubmit
  | TabAnalytics

/// Beta feedback hub state.
type betaFeedbackHubState = {
  activeTab: betaFeedbackTab,
  entries: array<feedbackEntry>,
  selectedEntry: option<string>,
  filter: string,
  categoryFilter: option<feedbackCategory>,
  sortByUpvotes: bool,
  submitting: bool,
  error: option<string>,
}
