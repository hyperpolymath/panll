// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL WatcherCmd — Tauri command wrappers for filesystem observation.
///
/// These wrap the Rust `watcher_*` commands using the same `callbacks.enqueue`
/// pattern as FarmCmd and other panel commands. The watcher runs in a Rust
/// background thread and emits `watcher://event` Tauri events.
///
/// Pattern: `commandName(args..., tagger) => Tea_Cmd.t<'msg>`
/// where `tagger: result<string, string> => 'msg` wraps the result into
/// the Watcher message type.

open Model

/// External binding to Tauri's invoke (shared across all Cmd modules).
@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Parse a watch event kind string from JSON into the typed variant.
let parseEventKind = (kind: string): watchEventKind => {
  switch kind {
  | "created" => Created
  | "modified" => Modified
  | "removed" => Removed
  | "renamed" => Renamed
  | _ => Other
  }
}

/// Parse a raw JSON string into a `watchEvent`.
///
/// The Rust side emits events as JSON-serialised `WatchEvent` structs.
/// This parses the JSON and maps field names (snake_case → camelCase).
let parseEvent = (jsonStr: string): option<watchEvent> => {
  try {
    let json = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(json) {
    | JSON.Classify.Object(dict) => {
        let getString = key =>
          switch dict->Dict.get(key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | JSON.Classify.String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getBool = key =>
          switch dict->Dict.get(key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | JSON.Classify.Bool(b) => b
            | _ => false
            }
          | None => false
          }
        let getFloat = key =>
          switch dict->Dict.get(key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | JSON.Classify.Number(n) => n
            | _ => 0.0
            }
          | None => 0.0
          }
        Some({
          path: getString("path"),
          kind: parseEventKind(getString("kind")),
          isDir: getBool("is_dir"),
          timestamp: getFloat("timestamp"),
          extension: getString("extension"),
          filename: getString("filename"),
        })
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

/// Start the filesystem watcher on the given paths.
///
/// The watcher runs in a background Rust thread and emits events via the
/// Tauri event bus. Paths are watched recursively with 500ms debounce.
let start = (
  paths: array<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("watcher_start", {"paths": paths})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to start watcher")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Stop the filesystem watcher. Idempotent — safe to call when not running.
let stop = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("watcher_stop", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to stop watcher")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get the current watcher status (running, watched paths, event count).
let status = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("watcher_status", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get watcher status")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Add a path to the running watcher dynamically.
let addPath = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("watcher_add_path", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to add watch path: ${path}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Remove a path from the running watcher.
let removePath = (
  path: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("watcher_remove_path", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to remove watch path: ${path}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
