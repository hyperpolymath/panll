// SPDX-License-Identifier: PMPL-1.0-or-later

/// Feedback-O-Tron messages -- user feedback submission lifecycle.

type feedbackMsg =
  | OpenFeedback
  | SubmitFeedback(string)
  | CancelFeedback
  | SetReportType(string)
  | FeedbackSubmitted
  | FeedbackSubmissionResult(result<string, string>)
