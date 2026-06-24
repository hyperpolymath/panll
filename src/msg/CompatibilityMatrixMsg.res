// SPDX-License-Identifier: MPL-2.0

/// Compatibility Matrix messages -- browser/device/resolution test matrix.

open Model

type compatibilityMatrixMsg =
  | SetCmTab(compatibilityTab)
  | CmStarted
  | CmCompleted(result<string, string>)
  | DismissCmError
  | RunAll
  | SelectCell(string, string)
