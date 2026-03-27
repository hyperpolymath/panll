// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Protocol-Squisher Commands — Backend wrappers for format analysis.
///
/// Invokes the protocol-squisher CLI through backend commands.
/// The Rust backend shells out to `protocol-squisher analyze`, `compare`, etc.

let invoke = RuntimeBridge.invoke

/// Check whether the protocol-squisher CLI binary is available.
let checkCli = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("protocol_squisher_check", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("protocol-squisher CLI not found")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Analyse a schema file. Returns JSON analysis result.
let analyse = (filePath: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("protocol_squisher_analyze", {"file_path": filePath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Schema analysis failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Compare two schema files for compatibility. Returns JSON comparison result.
let compare = (
  leftPath: string,
  rightPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("protocol_squisher_compare", {"left_path": leftPath, "right_path": rightPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Schema comparison failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
