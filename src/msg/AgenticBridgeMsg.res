// SPDX-License-Identifier: MPL-2.0

/// Agentic Bridge messages -- automated playtesting agents with OODA loop.

open Model

type agenticBridgeMsg =
  | SetAbTab(agenticBridgeTab)
  | AbStarted
  | AbCompleted(result<string, string>)
  | DismissAbError
