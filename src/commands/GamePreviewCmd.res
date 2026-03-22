// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Game Preview Commands — Backend async bindings for the live game
/// preview panel. Handles dev server health checks, game loop control,
/// gameplay recording, and render stats polling.

let invoke = RuntimeBridge.invoke

/// Check whether the Vite dev server is running and responding.
let checkDevServer = (
  url: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_check_server", {"url": url})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Dev server not responding")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Send a game loop control command (pause, resume, step).
let controlGameLoop = (
  command: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_control", {"command": command})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to control game loop")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Start recording gameplay to WebM.
let startGameRecording = (
  name: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_record_start", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to start gameplay recording")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Stop gameplay recording.
let stopGameRecording = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_record_stop", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to stop gameplay recording")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Take a screenshot of the current game frame.
let screenshotGameFrame = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_screenshot", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to capture game screenshot")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch current render statistics from the game engine.
let fetchRenderStats = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_stats", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch render stats")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List saved gameplay clips.
let listClips = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_clips_list", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list gameplay clips")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete a gameplay clip by ID.
let deleteClip = (
  id: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("game_preview_clip_delete", {"id": id})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to delete clip")))
      Promise.resolve()
    })
    ->ignore
  })
}
