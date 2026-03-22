// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// RuntimeBridge — Gossamer-native IPC bridge for the Clade Portal.
///
/// Gossamer-only bridge for the third Gossamer-native application. The Clade
/// Portal reads clade A2ML files from the PanLL panel-clades directory via
/// filesystem capability tokens, and checks panel health via network tokens.
///
/// The bridge communicates with the Gossamer runtime via the injected
/// `window.__gossamer_invoke` function. All IPC uses JSON protocol as
/// configured in gossamer.conf.json.
///
/// Capability tokens:
///   - filesystem: Required to read clade directories and A2ML files
///   - network: Required to fetch panel health status from running services

// ---------------------------------------------------------------------------
// Gossamer runtime detection
// ---------------------------------------------------------------------------

/// Check whether the Gossamer runtime is available in this webview.
/// Returns true when `window.__gossamer_invoke` has been injected by
/// the gossamer_channel_open() call during webview initialisation.
%%raw(`
function isGossamerRuntime() {
  return typeof window !== 'undefined'
    && typeof window.__gossamer_invoke === 'function';
}
`)
@val external isGossamerRuntime: unit => bool = "isGossamerRuntime"

/// Raw Gossamer IPC call. Sends a command name and JSON payload to the
/// Gossamer runtime and returns a promise with the response.
%%raw(`
function gossamerInvoke(cmd, args) {
  return window.__gossamer_invoke(cmd, args);
}
`)
@val external gossamerInvoke: (string, 'a) => promise<'b> = "gossamerInvoke"

// ---------------------------------------------------------------------------
// Runtime type (Gossamer-only, no Tauri path)
// ---------------------------------------------------------------------------

/// The runtime environment. For the Clade Portal, this is always Gossamer
/// or an error state (dev browser without the runtime).
type runtime =
  | /// Running inside the Gossamer webview shell (production).
    Gossamer
  | /// Running in a plain browser (development only — most features disabled).
    BrowserDev

/// Detect the current runtime environment.
let detectRuntime = (): runtime => {
  if isGossamerRuntime() {
    Gossamer
  } else {
    BrowserDev
  }
}

// ---------------------------------------------------------------------------
// Unified invoke — Gossamer-native with dev fallback
// ---------------------------------------------------------------------------

/// Invoke a Gossamer IPC command.
///
/// In production (Gossamer runtime), this calls `window.__gossamer_invoke`.
/// In development (browser), this rejects with a descriptive error so the
/// developer knows to run inside Gossamer.
///
/// All command modules (CladeCmd, Capabilities) use this function.
let invoke = (cmd: string, args: 'a): promise<'b> => {
  if isGossamerRuntime() {
    gossamerInvoke(cmd, args)
  } else {
    Promise.reject(
      JsError.throwWithMessage(
        `Gossamer runtime required — "${cmd}" cannot run in a plain browser. ` ++
        `Launch via: gossamer run --config gossamer.conf.json`,
      ),
    )
  }
}

/// Invoke a command that requires a capability token.
///
/// This is the security-critical path. The token is included in the IPC
/// payload so the Gossamer runtime can verify the caller holds the
/// required capability before executing the command.
///
/// @param cmd   - The IPC command name
/// @param args  - The command payload
/// @param token - The capability token (obtained from __gossamer_cap_grant)
let invokeWithToken = (cmd: string, args: 'a, token: float): promise<'b> => {
  if isGossamerRuntime() {
    gossamerInvoke(cmd, {"__cap_token": token, "payload": args})
  } else {
    Promise.reject(
      JsError.throwWithMessage(
        `Gossamer runtime required — "${cmd}" needs a capability token`,
      ),
    )
  }
}

/// Check whether the Gossamer runtime is available.
let hasRuntime = (): bool => isGossamerRuntime()

/// Human-readable runtime name for display in the UI.
let runtimeName = (): string => {
  switch detectRuntime() {
  | Gossamer => "Gossamer"
  | BrowserDev => "Browser (dev)"
  }
}
