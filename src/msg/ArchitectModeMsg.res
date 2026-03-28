// SPDX-License-Identifier: PMPL-1.0-or-later

/// Architect Mode messages -- PixiJS fine-grained level editor with L/N/W.

open Model

type architectModeMsg =
  | SetArchModeCategory(architectModeCategory)
  | ArchModeStarted
  | ArchModeCompleted(result<string, string>)
  | DismissArchModeError
