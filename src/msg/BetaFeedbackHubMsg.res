// SPDX-License-Identifier: PMPL-1.0-or-later

/// Beta Feedback Hub messages -- feedback-o-tron integration, sentiment, triage.

open Model

type betaFeedbackHubMsg =
  | SetBfhTab(betaFeedbackTab)
  | BfhStarted
  | BfhCompleted(result<string, string>)
  | DismissBfhError
  | SelectFeedback(string)
  | Upvote(string)
  | Downvote(string)
  | SubmitFeedback
  | UpdateSubmitTitle(string)
  | UpdateSubmitBody(string)
  | ToggleSortByVotes
