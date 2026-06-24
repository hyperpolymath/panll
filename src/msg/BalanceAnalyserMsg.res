// SPDX-License-Identifier: MPL-2.0

/// Balance Analyser messages -- game balance stats, Monte Carlo, difficulty curves.

open Model

type balanceAnalyserMsg =
  | SetBaTab(balanceTab)
  | BaStarted
  | BaCompleted(result<string, string>)
  | DismissBaError
  | RunSimulation
  | SelectLevel(string)
  | ApplyRecommendation(string, string, float)
