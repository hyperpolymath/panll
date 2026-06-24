// SPDX-License-Identifier: MPL-2.0

/// PanLL Interfaces Commands — Backend wrappers for ABI/FFI scanning.
///
/// Scans src/abi/ for Idris2 definitions and ffi/zig/ for implementations.

let invoke = RuntimeBridge.invoke

/// Scan ABI/FFI definitions and binding coverage.
let scanInterfaces = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
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
