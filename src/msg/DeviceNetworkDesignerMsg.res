// SPDX-License-Identifier: PMPL-1.0-or-later

/// Device Network Designer messages -- wire devices, configure security levels.

open Model

type deviceNetworkDesignerMsg =
  | SetDndCategory(deviceNetworkDesignerCategory)
  | DndStarted
  | DndCompleted(result<string, string>)
  | DismissDndError
