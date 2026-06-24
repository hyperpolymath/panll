// SPDX-License-Identifier: MPL-2.0

/// Playtest Recorder messages -- record + replay sessions, annotate moments.

open Model

type playtestRecorderMsg =
  | SetPrCategory(playtestRecorderCategory)
  | PrStarted
  | PrCompleted(result<string, string>)
  | DismissPrError
