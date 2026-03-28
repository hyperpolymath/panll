// SPDX-License-Identifier: PMPL-1.0-or-later

/// Automation Bridge messages -- CI/CD pipeline orchestration for game builds.

open Model

type automationBridgeMsg =
  | SetAutoBTab(automationBridgeTab)
  | AutoBStarted
  | AutoBCompleted(result<string, string>)
  | DismissAutoBError
