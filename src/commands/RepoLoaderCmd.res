// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Repo Loader Commands — Backend command wrappers for the repo loading panel.
///
/// Each function wraps a backend `invoke` call in a `Tea_Cmd.call`, converting
/// the Promise-based IPC into the TEA command model.

let invoke = RuntimeBridge.invoke

let openDialog = RuntimeBridge.Dialog.openDialog

/// Scan a repository directory and return info + panel suggestions.
let scan = (repoPath: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("repoloader_scan", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to scan repo: ${repoPath}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Save panel configuration to PANELS.a2ml in the repo.
let savePanels = (
  repoPath: string,
  panelsJson: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("repoloader_save_panels", {"repoPath": repoPath, "panelsJson": panelsJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save panel configuration")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List recently loaded repositories.
let listRecent = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("repoloader_list_recent", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load recent repos")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Search the git-private-farm for repos matching a query.
let searchFarm = (query: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("repoloader_search_farm", {"query": query})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to search farm for: ${query}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Open a directory picker dialog for the user to select a repo.
let pickDirectory = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let options: JSON.t = %raw(`({ directory: true, multiple: false, title: "Select Repository" })`)
    openDialog(options)
    ->Promise.then(result => {
      switch Nullable.toOption(result) {
      | Some(value) => switch JSON.Classify.classify(value) {
        | String(path) => callbacks.enqueue(tagger(Ok(path)))
        | _ => callbacks.enqueue(tagger(Error("Unexpected dialog result type")))
        }
      | None => callbacks.enqueue(tagger(Error("No directory selected")))
      }
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Directory selection failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
