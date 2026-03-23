// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL K9 Commands — backend invoke wrappers for K9 contractile operations.
/// These call into the Rust backend at src-gossamer/src/k9/commands.rs which
/// handles filesystem access for loading, validating, and applying K9
/// contractile files (.k9.ncl).
///
/// The Rust backend reads files and returns content as JSON strings. The
/// ReScript K9Engine then handles the actual parsing and validation logic
/// on the client side for maximum testability.

let invoke = RuntimeBridge.invoke

/// Load a K9 contractile file from disk. Returns the raw file content
/// as a JSON-wrapped string for client-side parsing by K9Engine.
let loadContractile = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("k9_load_contractile", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to load K9 contractile: ${path}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Validate a K9 contractile file on the backend. The Rust side performs
/// basic structural checks (file exists, non-empty, valid encoding, K9
/// magic header presence) and returns a JSON validation result. Deeper
/// semantic validation (security level, pedigree checks) is done
/// client-side by K9Engine.validateContractile.
let validateContractileFile = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("k9_validate", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to validate K9 contractile: ${path}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Apply a K9 layout preset by name. The Rust backend locates the layout
/// file in the `layouts/` directory, reads it, and returns the parsed
/// layout configuration as JSON. The client side then applies the panel
/// arrangement to the PanLL workspace.
let applyLayout = (
  name: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("k9_apply_layout", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to apply K9 layout: ${name}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
