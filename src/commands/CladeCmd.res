// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Clade Commands — Backend command wrappers for scanning `.a2ml` clade files.
///
/// Invokes `scan_clade_files` on the Rust backend to read all clade definitions
/// from `panel-clades/clades/`. Returns a JSON array of `{id, content}` objects.

let invoke = RuntimeBridge.invoke

/// Scan all `.a2ml` clade files from the panel-clades directory.
/// Returns a JSON string: `[{"id": "...", "content": "..."}]`.
let scanCladeFiles = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("scan_clade_files", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to scan clade files")))
      Promise.resolve()
    })
    ->ignore
  })
}
