// SPDX-License-Identifier: MPL-2.0

/// Automation Bridge messages -- CI/CD pipeline orchestration for game builds.

open Model

type automationBridgeMsg =
  | SetAutoBTab(automationBridgeTab)
  | AutoBStarted
  | AutoBCompleted(result<string, string>)
  | DismissAutoBError
