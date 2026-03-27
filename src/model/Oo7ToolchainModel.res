// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL 007 Toolchain Model — types for the agentic compiler panel.
///
/// This panel provides control and monitoring for the 007 agent toolchain,
/// including the Groove daemon lifecycle, stage execution, and linear
/// type analysis.

/// Toolchain stage categories.
type oo7Stage =
  | Oo7Lexer
  | Oo7Parser
  | Oo7Analyser
  | Oo7Evaluator
  | Oo7Linker

/// Daemon permission levels.
type daemonPermission =
  | PermissionReadOnly
  | PermissionExecute
  | PermissionAdministrative

/// Category tabs for the 007 Toolchain panel.
type oo7Category =
  | Oo7Dashboard
  | Oo7ControlPlane
  | Oo7Permissions
  | Oo7Monitoring

/// Root state for the 007 Toolchain panel.
type oo7State = {
  loaded: bool,
  loading: bool,
  error: option<string>,
  /// Groove daemon connection status.
  isConnected: bool,
  /// Current daemon permissions for this session.
  permissions: daemonPermission,
  /// Active stage results (indexed by stage).
  stageOutputs: array<(oo7Stage, string)>,
  /// Source code being edited.
  sourceCode: string,
  /// Active category tab.
  activeCategory: oo7Category,
  /// Neurosymbolic status from Echidna/TypeLL.
  nesyStatus: string,
}
