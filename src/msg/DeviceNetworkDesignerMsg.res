// SPDX-License-Identifier: MPL-2.0

/// Device Network Designer messages -- wire devices, configure security levels.

open Model

type deviceNetworkDesignerMsg =
  | SetDndCategory(deviceNetworkDesignerCategory)
  | DndStarted
  | DndCompleted(result<string, string>)
  | DismissDndError
