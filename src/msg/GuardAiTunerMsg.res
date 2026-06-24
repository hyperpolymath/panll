// SPDX-License-Identifier: MPL-2.0

/// Guard AI Tuner messages -- guard patrol, alert threshold, spawn rate tuning.

open Model

type guardAiTunerMsg =
  | SetGatCategory(guardAiTunerCategory)
  | GatStarted
  | GatCompleted(result<string, string>)
  | DismissGatError
