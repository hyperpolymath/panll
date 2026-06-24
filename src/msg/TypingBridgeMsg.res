// SPDX-License-Identifier: MPL-2.0

/// Typing Bridge messages -- TypeLL type constraints for game state.

open Model

type typingBridgeMsg =
  | SetTbTab(typingBridgeTab)
  | TbStarted
  | TbCompleted(result<string, string>)
  | DismissTbError
