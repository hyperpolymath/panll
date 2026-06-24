// SPDX-License-Identifier: MPL-2.0

/// Team Dashboard messages -- team presence, activity feed, progress tracking.

open Model

type teamDashboardMsg =
  | SetTdTab(teamDashboardTab)
  | SetTdFilter(string)
  | DismissTdError
