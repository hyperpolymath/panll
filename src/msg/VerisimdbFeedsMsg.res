// SPDX-License-Identifier: MPL-2.0

/// Messages for the VeriSimDB Feeds viewer panel.

type verisimdbFeedsMsg =
  | SetTab(VerisimdbFeedsModel.verisimdbFeedsTab)
  | CheckFeeds
  | FeedsChecked(result<string, string>)
  | SelectFeed(string)
  | ClearError
