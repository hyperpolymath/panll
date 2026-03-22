// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — VoiceTag Commands (Layer 0)
///
/// Backend command wrappers for .mri.json file I/O and Web Speech API voice input.
/// The file format is portable — any tool can read/write .mri.json files. PanLL
/// adds voice input and agentic integration on top.
///
/// .mri.json sidecar convention:
///   Source file: `src/Model.res`
///   Sidecar:     `src/Model.res.mri.json`
///
/// The sidecar lives alongside the source file. It's a plain JSON file that
/// editors, CLI tools, and CI pipelines can all consume without PanLL installed.

let invoke = RuntimeBridge.invoke

/// Load tags from a .mri.json sidecar file.
/// Returns the raw JSON string; parsing happens in the Update layer.
let loadTags = (
  filePath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let sidecarPath = filePath ++ ".mri.json"
    let _ = invoke("voicetag_load", {"path": sidecarPath})
    ->Promise.thenResolve(result => {
      callbacks.enqueue(tagger(Ok(result)))
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load .mri.json")))
      Promise.resolve()
    })
  })
}

/// Save tags to a .mri.json sidecar file.
/// Takes a JSON string (serialised in the Update layer).
let saveTags = (
  filePath: string,
  jsonContent: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let sidecarPath = filePath ++ ".mri.json"
    let _ = invoke("voicetag_save", {"path": sidecarPath, "content": jsonContent})
    ->Promise.thenResolve(result => {
      callbacks.enqueue(tagger(Ok(result)))
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save .mri.json")))
      Promise.resolve()
    })
  })
}

/// Delete a .mri.json sidecar file (when all tags are removed).
let deleteSidecar = (
  filePath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let sidecarPath = filePath ++ ".mri.json"
    let _ = invoke("voicetag_delete", {"path": sidecarPath})
    ->Promise.thenResolve(result => {
      callbacks.enqueue(tagger(Ok(result)))
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to delete .mri.json")))
      Promise.resolve()
    })
  })
}

/// Scan a directory for all .mri.json sidecar files (for project-wide tag summary).
let scanProject = (
  dirPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let _ = invoke("voicetag_scan", {"path": dirPath})
    ->Promise.thenResolve(result => {
      callbacks.enqueue(tagger(Ok(result)))
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to scan for .mri.json files")))
      Promise.resolve()
    })
  })
}
