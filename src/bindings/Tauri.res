// SPDX-License-Identifier: AGPL-3.0-or-later

/// Tauri Bindings for ReScript
///
/// FFI bindings to the Tauri backend for native operations,
/// including Anti-Crash validation and system integration.

/// Tauri invoke result type
type invokeResult<'a> = promise<'a>

/// Validate inference through Tauri backend
@module("@tauri-apps/api/core")
external invoke: (string, 'params) => invokeResult<'result> = "invoke"

/// Validate a neural token against constraints
let validateInference = (token: string, constraints: array<string>): invokeResult<bool> => {
  invoke("validate_inference", {"token": token, "constraints": constraints})
}

/// Get the current vexation index from the backend
let getVexationIndex = (): invokeResult<float> => {
  invoke("get_vexation_index", {})
}

/// Submit feedback to the Feedback-O-Tron
let submitFeedback = (
  paneLState: string,
  paneNState: string,
  paneWState: string,
  reportType: string,
): invokeResult<string> => {
  invoke("submit_feedback", {
    "pane_l_state": paneLState,
    "pane_n_state": paneNState,
    "pane_w_state": paneWState,
    "report_type": reportType,
  })
}

/// Event listener types
type eventPayload<'a> = {payload: 'a}
type unlisten = unit => unit

/// Listen for events from the Tauri backend
@module("@tauri-apps/api/event")
external listen: (string, eventPayload<'a> => unit) => invokeResult<unlisten> = "listen"

/// Emit events to the Tauri backend
@module("@tauri-apps/api/event")
external emit: (string, 'payload) => invokeResult<unit> = "emit"

/// Window operations
module Window = {
  type windowLabel = string

  @module("@tauri-apps/api/window")
  external getCurrent: unit => {"label": windowLabel} = "getCurrent"

  @module("@tauri-apps/api/window")
  external setTitle: string => invokeResult<unit> = "setTitle"

  @module("@tauri-apps/api/window")
  external setFullscreen: bool => invokeResult<unit> = "setFullscreen"

  @module("@tauri-apps/api/window")
  external minimize: unit => invokeResult<unit> = "minimize"

  @module("@tauri-apps/api/window")
  external maximize: unit => invokeResult<unit> = "maximize"

  @module("@tauri-apps/api/window")
  external close: unit => invokeResult<unit> = "close"
}

/// Shell operations (for running external tools)
module Shell = {
  type command
  type childProcess = {
    code: int,
    stdout: string,
    stderr: string,
  }

  @module("@tauri-apps/plugin-shell")
  external command: (string, array<string>) => command = "Command"

  @send
  external execute: command => invokeResult<childProcess> = "execute"
}

/// Path operations
module Path = {
  @module("@tauri-apps/api/path")
  external appDataDir: unit => invokeResult<string> = "appDataDir"

  @module("@tauri-apps/api/path")
  external appConfigDir: unit => invokeResult<string> = "appConfigDir"

  @module("@tauri-apps/api/path")
  external homeDir: unit => invokeResult<string> = "homeDir"
}
