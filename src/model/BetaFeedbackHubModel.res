// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Beta Feedback Hub Model — feedback-o-tron integration and player
/// feedback triage for IDApTIK beta testing programmes.
///
/// Connects to the Feedback-o-Tron service for community-driven feedback
/// collection. Supports sentiment analysis, priority triage, upvote/downvote
/// ranking, and category filtering. Integrates with VeriSimDB for persistence.
///
/// Clade: Viewer. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Feedback Classification
// ============================================================================

/// Priority level for a feedback entry.
type feedbackPriority =
  /// Critical — game-breaking issue requiring immediate attention.
  | FeedbackCritical
  /// High — significant issue affecting many players.
  | FeedbackHigh
  /// Medium — noticeable issue with available workarounds.
  | FeedbackMedium
  /// Low — minor polish or cosmetic issue.
  | FeedbackLow

/// Category classification for feedback entries.
type feedbackCategory =
  /// Bug report — something is broken.
  | FeedbackBug
  /// Feature request — something is desired.
  | FeedbackFeature
  /// Balance concern — game difficulty or fairness issue.
  | FeedbackBalance
  /// UX issue — confusing or frustrating interaction pattern.
  | FeedbackUx
  /// Performance complaint — lag, stuttering, or loading times.
  | FeedbackPerformance
  /// Uncategorised or does not fit other categories.
  | FeedbackOther

/// Sentiment analysis result from the Feedback-o-Tron NLP pipeline.
type feedbackSentiment =
  /// Positive — player is happy or satisfied.
  | SentimentPositive
  /// Neutral — factual report without strong emotion.
  | SentimentNeutral
  /// Negative — player is frustrated or dissatisfied.
  | SentimentNegative
  /// Unknown — sentiment could not be determined.
  | SentimentUnknown

/// Processing status in the triage workflow.
type feedbackStatus =
  /// New — just arrived, not yet reviewed.
  | FeedbackNew
  /// Triaged — reviewed and assigned a priority/category.
  | FeedbackTriaged
  /// In Progress — being worked on by a developer.
  | FeedbackInProgress
  /// Resolved — fix shipped or request fulfilled.
  | FeedbackResolved
  /// Won't Fix — declined with explanation.
  | FeedbackWontFix

// ============================================================================
// Feedback Entries
// ============================================================================

/// A single feedback entry from a beta tester or player.
type feedbackEntry = {
  /// Unique feedback identifier.
  id: string,
  /// Short title summarising the feedback.
  title: string,
  /// Full feedback body text.
  body: string,
  /// Category classification.
  category: feedbackCategory,
  /// Priority level.
  priority: feedbackPriority,
  /// Sentiment analysis result.
  sentiment: feedbackSentiment,
  /// Username or identifier of the submitter.
  submittedBy: string,
  /// ISO 8601 timestamp of submission.
  submittedAt: string,
  /// Community upvote count.
  upvotes: int,
  /// Community downvote count.
  downvotes: int,
  /// Current processing status.
  status: feedbackStatus,
  /// Platform the feedback was submitted from (e.g., "web", "discord", "in-game").
  platform: string,
}

/// Aggregate analytics for the feedback hub.
type feedbackAnalytics = {
  /// Total number of feedback entries.
  totalEntries: int,
  /// Breakdown by category.
  byCategoryCount: array<(feedbackCategory, int)>,
  /// Breakdown by sentiment.
  bySentimentCount: array<(feedbackSentiment, int)>,
  /// Average sentiment score (-1.0 negative to +1.0 positive).
  avgSentimentScore: float,
  /// Triage completion rate (resolved + won't fix) / total.
  triageCompletionRate: float,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Beta Feedback Hub panel.
type betaFeedbackTab =
  /// Inbox — new unreviewed feedback entries.
  | TabInbox
  /// Triaged — reviewed entries grouped by priority.
  | TabTriaged
  /// Sentiment — sentiment analysis dashboard with charts.
  | TabSentiment
  /// Submit — form for submitting new feedback (developer testing).
  | TabSubmit
  /// Analytics — aggregate statistics and trend charts.
  | TabAnalytics

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Beta Feedback Hub panel.
type betaFeedbackHubState = {
  /// Active tab within the panel.
  activeTab: betaFeedbackTab,
  /// All feedback entries.
  entries: array<feedbackEntry>,
  /// Currently selected entry ID for detail view.
  selectedEntry: option<string>,
  /// Text search filter for title and body.
  filter: string,
  /// Optional category filter to narrow the list.
  categoryFilter: option<feedbackCategory>,
  /// Whether to sort by upvote count (descending).
  sortByUpvotes: bool,
  /// Whether a feedback submission is in progress.
  submitting: bool,
  /// Cached analytics (recomputed on tab switch).
  analytics: option<feedbackAnalytics>,
  /// Error from the last operation.
  error: option<string>,
}
