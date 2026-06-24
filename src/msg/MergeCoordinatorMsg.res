// SPDX-License-Identifier: MPL-2.0

/// Merge Coordinator messages -- branch management, conflict resolution, merge queue.

open Model

type mergeCoordinatorMsg =
  | SetMcTab(mergeCoordinatorTab)
  | SelectBranch(string)
  | ResolveConflict(string, string)
  | DismissMcError
