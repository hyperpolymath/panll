// SPDX-License-Identifier: PMPL-1.0-or-later

/// Guard AI Tuner messages -- guard patrol, alert threshold, spawn rate tuning.

open Model

type guardAiTunerMsg =
  | SetGatCategory(guardAiTunerCategory)
  | GatStarted
  | GatCompleted(result<string, string>)
  | DismissGatError
