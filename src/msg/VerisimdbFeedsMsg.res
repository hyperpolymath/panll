// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the VeriSimDB Feeds viewer panel.

type verisimdbFeedsMsg =
  | SetTab(VerisimdbFeedsModel.verisimdbFeedsTab)
  | CheckFeeds
  | FeedsChecked(result<string, string>)
  | SelectFeed(string)
  | ClearError
