// SPDX-License-Identifier: MPL-2.0

/// Messages for the Feedback Routing viewer panel.

type feedbackRoutingMsg =
  | SetTab(FeedbackRoutingModel.feedbackRoutingTab)
  | RefreshReports
  | ReportsRefreshed(result<string, string>)
  | SelectReport(string)
  | ClearError
