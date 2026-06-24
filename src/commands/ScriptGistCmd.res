// SPDX-License-Identifier: MPL-2.0

/// PanLL ScriptGist Commands — backend invoke wrappers for gist persistence,
/// execution dispatch, and diachronic snapshot restoration.
///
/// Routes to Rust backend at src-gossamer/src/script_gist/commands.rs which
/// handles filesystem I/O and target dispatch.

let invoke = RuntimeBridge.invoke

/// Save a gist to persistent storage (`~/.panll/gists/<id>.json`).
/// The gist is serialised as a JSON string on the frontend side.
let saveGist = (gistJson: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("script_gist_save", {"gistJson": gistJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save gist")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Execute a gist by dispatching to its target backend.
/// Returns a JSON string representing a gistResult.
let executeGist = (gistJson: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("script_gist_execute", {"gistJson": gistJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Gist execution failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Restore a diachronic checkpoint by deserialising the snapshot.
/// Returns the validated scriptGistState JSON for the frontend to parse.
let restoreSnapshot = (snapshotJson: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("script_gist_restore_snapshot", {"snapshotJson": snapshotJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Snapshot restoration failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all saved gist files from persistent storage.
let listGists = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("script_gist_list", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list gists")))
      Promise.resolve()
    })
    ->ignore
  })
}
