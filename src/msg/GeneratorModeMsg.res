// SPDX-License-Identifier: MPL-2.0

/// Generator Mode messages -- parametric procedural world builder.

open Model

type generatorModeMsg =
  | SetGenCategory(generatorModeCategory)
  | GenStarted
  | GenCompleted(result<string, string>)
  | DismissGenError
