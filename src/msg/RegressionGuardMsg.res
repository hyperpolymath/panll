// SPDX-License-Identifier: PMPL-1.0-or-later

/// Regression Guard messages -- snapshot comparison and golden-file testing.

open Model

type regressionGuardMsg =
  | SetRgTab(regressionTab)
  | RgStarted
  | RgCompleted(result<string, string>)
  | DismissRgError
  | CheckAll
  | UpdateAll
  | UpdateSnapshot(string)
  | ViewDiff(string)
  | ToggleAutoUpdate
