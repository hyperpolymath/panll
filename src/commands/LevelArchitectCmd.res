// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Level Architect Commands — backend invoke wrappers for level
/// file I/O, asset browsing, level validation, and LevelConfig export.

let invoke = RuntimeBridge.invoke

/// Load a level from a JSON file.
let loadLevel = (path: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("load_level", {"path": path})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load level")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Save the current level to a JSON file.
let saveLevel = (path: string, data: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("save_level", {"path": path, "data": data})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save level")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export the level as a LevelConfig.res source file.
let exportLevelConfig = (data: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("export_level_config", {"data": data})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export LevelConfig")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Browse available game assets.
let browseAssets = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("browse_level_assets", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to browse assets")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Validate the current level design.
let validateLevel = (data: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("validate_level", {"data": data})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to validate level")))
      Promise.resolve()
    })
    ->ignore
  })
}
