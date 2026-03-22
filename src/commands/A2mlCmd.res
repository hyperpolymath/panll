// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL A2ML Commands — backend invoke wrappers for A2ML manifest operations.
/// These call into the Rust backend at src-tauri/src/a2ml/commands.rs which
/// handles filesystem access for loading, validating, and listing .a2ml files.
///
/// The Rust backend reads files and returns content as JSON strings. The
/// ReScript A2mlEngine then handles the actual parsing and validation logic
/// on the client side for maximum testability.

let invoke = RuntimeBridge.invoke

/// Load an A2ML manifest file from disk. Returns the raw file content
/// as a JSON-wrapped string for client-side parsing by A2mlEngine.
let loadManifest = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("a2ml_load_manifest", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to load A2ML manifest: ${path}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Validate an A2ML manifest file on the backend. The Rust side performs
/// basic structural checks (file exists, non-empty, valid encoding) and
/// returns a JSON validation result. Deeper semantic validation is done
/// client-side by A2mlEngine.validateManifest.
let validateManifestFile = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("a2ml_validate", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to validate A2ML manifest: ${path}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all .a2ml files found in the current repository. Returns a JSON
/// array of file paths relative to the repo root.
let listManifests = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("a2ml_list", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list A2ML manifests")))
      Promise.resolve()
    })
    ->ignore
  })
}
