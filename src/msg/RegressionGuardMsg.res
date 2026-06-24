// SPDX-License-Identifier: MPL-2.0

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
