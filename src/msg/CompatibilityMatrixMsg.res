// SPDX-License-Identifier: PMPL-1.0-or-later

/// Compatibility Matrix messages -- browser/device/resolution test matrix.

open Model

type compatibilityMatrixMsg =
  | SetCmTab(compatibilityTab)
  | CmStarted
  | CmCompleted(result<string, string>)
  | DismissCmError
  | RunAll
  | SelectCell(string, string)
