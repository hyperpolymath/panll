// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for Pane-L (Symbolic) -- constraint CRUD and editor state.

open Model

type paneLMsg =
  | AddConstraint(symbolicConstraint)
  | RemoveConstraint(string)
  | ToggleConstraint(string)
  | PinConstraint(string)
  | UpdateEditorContent(string)
  | SetActiveConstraint(option<string>)
  /// TypeLL inferred type for the current editor expression.
  | ConstraintTypeInferred(result<string, string>)
