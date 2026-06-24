// SPDX-License-Identifier: MPL-2.0

/// VAB (Verified Assembly Building) messages -- server component assembly,
/// category navigation, dependency-driven recomputation, and assembly management.

open Model

type vabMsg =
  | ToggleVab
  | SelectCategory(vabCategory)
  | AddComponent(string)
  | RemoveComponent(string)
  | RenameServer(string)
  | ClearAssembly
  | SetFilterText(string)
  | SetSortBy(vabSortBy)
  | HoverComponent(option<string>)
  /// TypeLL cross-panel type check result for assembly config types.
  | TypeCheckResult(result<string, string>)
