// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the Feedback Routing viewer panel.

type feedbackRoutingMsg =
  | SetTab(FeedbackRoutingModel.feedbackRoutingTab)
  | RefreshReports
  | ReportsRefreshed(result<string, string>)
  | SelectReport(string)
  | ClearError
