// SPDX-License-Identifier: MPL-2.0

/// Feedback-O-Tron messages -- user feedback submission lifecycle.

type feedbackMsg =
  | OpenFeedback
  | SubmitFeedback(string)
  | CancelFeedback
  | SetReportType(string)
  | FeedbackSubmitted
  | FeedbackSubmissionResult(result<string, string>)
