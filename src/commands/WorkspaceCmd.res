// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Workspace Commands — Tauri IPC wrappers for workspace operations.
///
/// These functions bridge the ReScript TEA loop with the Rust backend
/// for workspace persistence (arrangements, sessions) and system info
/// queries (status bar widgets). Each function returns a Tea_Cmd that
/// dispatches a result message back into the update loop via
/// `callbacks.enqueue`.

open Msg

/// External binding to Tauri's invoke function.
/// All Tauri commands return Promise<string> or throw on error.
@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<string> = "invoke"

/// Save an arrangement to disk via Tauri backend.
let saveArrangement = (arrangementJson: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(_callbacks => {
    invoke("save_arrangement", {"arrangement": arrangementJson})->ignore
    // Fire-and-forget — arrangement save errors are non-critical.
  })
}

/// Load all saved arrangements from disk.
let loadArrangements = (): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("load_arrangements", ())
    ->Promise.then(result => {
      callbacks.enqueue(Workspace(ArrangementsLoaded(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Workspace(ArrangementsLoaded(Error("Failed to load arrangements"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete an arrangement from disk.
let deleteArrangement = (arrangementId: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(_callbacks => {
    invoke("delete_arrangement", {"arrangementId": arrangementId})->ignore
  })
}

/// Save a session to disk via Tauri backend.
let saveSession = (sessionJson: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(_callbacks => {
    invoke("save_session", {"session": sessionJson})->ignore
  })
}

/// Load all saved sessions from disk.
let loadSessions = (): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("load_sessions", ())
    ->Promise.then(result => {
      callbacks.enqueue(Workspace(SessionsLoaded(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Workspace(SessionsLoaded(Error("Failed to load sessions"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete a session from disk.
let deleteSession = (sessionId: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(_callbacks => {
    invoke("delete_session", {"sessionId": sessionId})->ignore
  })
}

/// Query system information (CPU, memory, disk, uptime) for status bar widgets.
let getSystemInfo = (): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("get_system_info", ())
    ->Promise.then(result => {
      callbacks.enqueue(Workspace(SystemInfoLoaded(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Workspace(SystemInfoLoaded(Error("Failed to get system info"))))
      Promise.resolve()
    })
    ->ignore
  })
}
