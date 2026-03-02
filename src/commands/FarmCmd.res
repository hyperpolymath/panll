// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Farm Commands — Tauri command wrappers for the Git-Private-Farm panel.
///
/// Each function wraps a Tauri `invoke` call in a `Tea_Cmd.call`, converting
/// the Promise-based Tauri IPC into the TEA command model. Results arrive as
/// JSON strings; parsing happens in the Update layer, not here.
///
/// Pattern: `commandName(args..., tagger) => Tea_Cmd.t<'msg>`
/// where `tagger: result<string, string> => 'msg` wraps the result into
/// the panel's message type.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Load the full repo inventory from farm-manifest.json.
/// Returns a JSON string containing the FarmInventory structure
/// (total, repos array, groups, languages, forge_names).
let listRepos = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("farm_list_repos", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load farm manifest")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get details for a single repo by name.
/// Returns a JSON string containing the FarmRepoEntry.
let getRepo = (
  name: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("farm_get_repo", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to load repo: ${name}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get aggregate statistics from the manifest (counts by language,
/// forge, priority, group).
let getStats = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("farm_get_stats", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load farm statistics")))
      Promise.resolve()
    })
    ->ignore
  })
}
