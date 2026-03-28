// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the 007 Toolchain panel.

type oo7Msg =
  | SetCategory(Oo7ToolchainModel.oo7Category)
  | ConnectDaemon
  | DisconnectDaemon
  | SetPermissions(Oo7ToolchainModel.daemonPermission)
  | RunStage(Oo7ToolchainModel.oo7Stage)
  | StageResult(Oo7ToolchainModel.oo7Stage, result<string, string>)
  | UpdateSource(string)
  | LoadToolchain
  | ClearError
