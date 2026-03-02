// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Interfaces Commands — Tauri wrappers for ABI/FFI scanning.
///
/// Scans src/abi/ for Idris2 definitions and ffi/zig/ for implementations.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Scan ABI/FFI definitions and binding coverage.
let scanInterfaces = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("interfaces_scan", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Interface scan failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
