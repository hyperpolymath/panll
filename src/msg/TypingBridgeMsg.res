// SPDX-License-Identifier: PMPL-1.0-or-later

/// Typing Bridge messages -- TypeLL type constraints for game state.

open Model

type typingBridgeMsg =
  | SetTbTab(typingBridgeTab)
  | TbStarted
  | TbCompleted(result<string, string>)
  | DismissTbError
