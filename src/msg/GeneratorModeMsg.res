// SPDX-License-Identifier: PMPL-1.0-or-later

/// Generator Mode messages -- parametric procedural world builder.

open Model

type generatorModeMsg =
  | SetGenCategory(generatorModeCategory)
  | GenStarted
  | GenCompleted(result<string, string>)
  | DismissGenError
