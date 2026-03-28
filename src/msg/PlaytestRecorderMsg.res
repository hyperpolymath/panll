// SPDX-License-Identifier: PMPL-1.0-or-later

/// Playtest Recorder messages -- record + replay sessions, annotate moments.

open Model

type playtestRecorderMsg =
  | SetPrCategory(playtestRecorderCategory)
  | PrStarted
  | PrCompleted(result<string, string>)
  | DismissPrError
