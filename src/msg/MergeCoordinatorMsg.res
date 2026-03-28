// SPDX-License-Identifier: PMPL-1.0-or-later

/// Merge Coordinator messages -- branch management, conflict resolution, merge queue.

open Model

type mergeCoordinatorMsg =
  | SetMcTab(mergeCoordinatorTab)
  | SelectBranch(string)
  | ResolveConflict(string, string)
  | DismissMcError
