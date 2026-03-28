// SPDX-License-Identifier: PMPL-1.0-or-later

/// Team Dashboard messages -- team presence, activity feed, progress tracking.

open Model

type teamDashboardMsg =
  | SetTdTab(teamDashboardTab)
  | SetTdFilter(string)
  | DismissTdError
