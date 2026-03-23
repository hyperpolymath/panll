// SPDX-License-Identifier: PMPL-1.0-or-later

/// RuntimeBridge — Unified IPC bridge for PanLL panels.
///
/// Dispatches `invoke` calls to the Gossamer backend (primary) or rejects
/// with a descriptive error in browser-only mode.
///
/// Priority order:
///   1. Gossamer (`window.__gossamer_invoke`)  — production runtime
///   2. Browser  (direct HTTP fetch)            — development fallback
///
/// All panel command modules should use:
///   `let invoke = RuntimeBridge.invoke`

// ---------------------------------------------------------------------------
// Gossamer IPC binding
// ---------------------------------------------------------------------------

/// Gossamer IPC: injected by gossamer_channel_open() into the webview.
/// Signature: (commandName: string, payload: object) => Promise<any>
%%raw(`
function isGossamerRuntime() {
  return typeof window !== 'undefined'
    && typeof window.__gossamer_invoke === 'function';
}
`)
@val external isGossamerRuntime: unit => bool = "isGossamerRuntime"

%%raw(`
function gossamerInvoke(cmd, args) {
  return window.__gossamer_invoke(cmd, args);
}
`)
@val external gossamerInvoke: (string, 'a) => promise<'b> = "gossamerInvoke"

// ---------------------------------------------------------------------------
// Unified invoke — detects runtime and dispatches
// ---------------------------------------------------------------------------

/// The runtime currently in use. Cached after first detection for performance.
type runtime =
  | Gossamer
  | BrowserOnly

%%raw(`
var _detectedRuntime = null;
function detectRuntime() {
  if (_detectedRuntime !== null) return _detectedRuntime;
  if (typeof window !== 'undefined' && typeof window.__gossamer_invoke === 'function') {
    _detectedRuntime = 'gossamer';
  } else {
    _detectedRuntime = 'browser';
  }
  return _detectedRuntime;
}
`)
@val external detectRuntimeRaw: unit => string = "detectRuntime"

/// Detect and return the current runtime as a typed variant.
let currentRuntime = (): runtime => {
  switch detectRuntimeRaw() {
  | "gossamer" => Gossamer
  | _ => BrowserOnly
  }
}

/// Invoke a backend command through Gossamer.
///
/// - On Gossamer: calls `window.__gossamer_invoke(cmd, args)`
/// - On browser:  rejects with a descriptive error
///
/// This is the primary function all panel command modules should use.
let invoke = (cmd: string, args: 'a): promise<'b> => {
  if isGossamerRuntime() {
    gossamerInvoke(cmd, args)
  } else {
    // Return a rejected promise — do NOT use JsError.throwWithMessage which
    // throws synchronously and crashes the TEA dispatch loop.
    let err: exn = %raw(`new Error('No desktop runtime — "' + cmd + '" requires Gossamer')`)
    Promise.reject(err)
  }
}

/// Check whether the Gossamer desktop runtime is available.
let hasDesktopRuntime = (): bool => {
  isGossamerRuntime()
}

/// Get a human-readable name for the current runtime.
let runtimeName = (): string => {
  switch currentRuntime() {
  | Gossamer => "Gossamer"
  | BrowserOnly => "Browser"
  }
}

// ---------------------------------------------------------------------------
// Dialog abstraction — Gossamer dialogs
// ---------------------------------------------------------------------------

module Dialog = {
  /// Open a file picker dialog through Gossamer IPC.
  let openDialog = (opts: JSON.t): promise<Nullable.t<JSON.t>> => {
    if isGossamerRuntime() {
      gossamerInvoke("__gossamer_dialog_open", opts)
    } else {
      let err: exn = %raw(`new Error('No desktop runtime — file dialogs require Gossamer')`)
      Promise.reject(err)
    }
  }

  /// Open a save dialog through Gossamer IPC.
  let save = (opts: JSON.t): promise<Nullable.t<JSON.t>> => {
    if isGossamerRuntime() {
      gossamerInvoke("__gossamer_dialog_save", opts)
    } else {
      let err: exn = %raw(`new Error('No desktop runtime — save dialogs require Gossamer')`)
      Promise.reject(err)
    }
  }
}

// ---------------------------------------------------------------------------
// Filesystem abstraction — Gossamer fs
// ---------------------------------------------------------------------------

module Fs = {
  /// Read a text file from the local filesystem via Gossamer IPC.
  let readTextFile = (path: string): promise<string> => {
    if isGossamerRuntime() {
      gossamerInvoke("__gossamer_fs_read_text", {"path": path})
    } else {
      let err: exn = %raw(`new Error('No desktop runtime — filesystem access requires Gossamer')`)
      Promise.reject(err)
    }
  }

  /// Write a text file to the local filesystem via Gossamer IPC.
  let writeTextFile = (path: string, contents: string): promise<unit> => {
    if isGossamerRuntime() {
      gossamerInvoke("__gossamer_fs_write_text", {"path": path, "contents": contents})
    } else {
      let err: exn = %raw(`new Error('No desktop runtime — filesystem access requires Gossamer')`)
      Promise.reject(err)
    }
  }
}

// ---------------------------------------------------------------------------
// Utility — decode dialog path from Gossamer response format
// ---------------------------------------------------------------------------

/// Decode a dialog result into a file path string.
/// Handles both single-path (String) and multi-path (Array) responses.
let decodeDialogPath = (value: JSON.t): option<string> => {
  switch JSON.Classify.classify(value) {
  | String(path) => Some(path)
  | Array(arr) =>
    switch Array.get(arr, 0) {
    | Some(item) =>
      switch JSON.Classify.classify(item) {
      | String(s) => Some(s)
      | _ => None
      }
    | None => None
    }
  | _ => None
  }
}
