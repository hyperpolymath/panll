// SPDX-License-Identifier: MPL-2.0

/// PanLL ProvenanceCmd — Backend command wrappers for git blame provenance analysis.
///
/// The Rust backend runs `git blame --porcelain` on a file and enriches each
/// region with Co-Authored-By trailer parsing. Results come back as JSON that
/// the Update layer parses into `provenanceRegion` arrays.
///
/// Pattern: `commandName(args..., tagger) => Tea_Cmd.t<'msg>`

let invoke = RuntimeBridge.invoke

/// Analyse a file's provenance via git blame + Co-Authored-By parsing.
///
/// The Rust backend runs `git blame --porcelain <path>` in the repo root,
/// parses the output, and returns a JSON array of blame regions with
/// author, co-author, and commit metadata.
let analyseFile = (
  repoPath: string,
  filePath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("provenance_analyse_file", {"repoPath": repoPath, "filePath": filePath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to analyse provenance: ${filePath}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Scan a file for unsound markers (believe_me, sorry, Admitted, assert_total).
///
/// Returns a JSON object with counts per marker type. Used to validate that
/// regions marked as Verified actually contain no proof-undermining patterns.
let scanUnsoundMarkers = (filePath: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("provenance_scan_unsound", {"filePath": filePath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to scan for unsound markers: ${filePath}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
