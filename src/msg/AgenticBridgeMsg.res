// SPDX-License-Identifier: PMPL-1.0-or-later

/// Agentic Bridge messages -- automated playtesting agents with OODA loop.

open Model

type agenticBridgeMsg =
  | SetAbTab(agenticBridgeTab)
  | AbStarted
  | AbCompleted(result<string, string>)
  | DismissAbError
