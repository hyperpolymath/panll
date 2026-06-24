// SPDX-License-Identifier: MPL-2.0

/// Architect Mode messages -- PixiJS fine-grained level editor with L/N/W.

open Model

type architectModeMsg =
  | SetArchModeCategory(architectModeCategory)
  | ArchModeStarted
  | ArchModeCompleted(result<string, string>)
  | DismissArchModeError
