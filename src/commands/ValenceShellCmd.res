// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Valence Shell Commands — Tauri async bindings for PTY, Valence
/// shell binary, session recording, and checkpoint operations.
///
/// Each function returns a `Tea_Cmd.t<'msg>` that wraps a Tauri invoke
/// call in a Promise, tagging the result back into the TEA message loop.
///
/// The terminal PTY is managed by @tauri-apps/plugin-shell. The Valence
/// shell binary handles reversible filesystem ops. Recordings use the
/// asciinema .cast format for portability.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Check whether the Valence shell binary is available on PATH.
/// Returns the version string on success, or an error if not found.
let checkValenceAvailability = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_check", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Valence shell binary not found on PATH")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Spawn a PTY process with the given shell command.
/// Returns a session ID on success that can be used for subsequent I/O.
let spawnPty = (
  shellCommand: string,
  cwd: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_spawn", {"shell": shellCommand, "cwd": cwd})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to spawn PTY")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Send input to the running PTY session.
let sendInput = (
  input: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_input", {"input": input})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to send input to PTY")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Start recording the terminal session to an asciinema .cast file.
let startRecording = (
  name: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_record_start", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to start recording")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Stop the current recording and save the .cast file.
let stopRecording = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_record_stop", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to stop recording")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all saved recordings.
let listRecordings = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_recordings_list", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list recordings")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete a recording by ID.
let deleteRecording = (
  id: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_recording_delete", {"id": id})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to delete recording")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Create a Valence filesystem checkpoint.
let createCheckpoint = (
  label: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_checkpoint_create", {"label": label})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to create checkpoint")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Restore a Valence filesystem checkpoint by ID.
let restoreCheckpoint = (
  id: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_checkpoint_restore", {"id": id})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to restore checkpoint")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all Valence filesystem checkpoints.
let listCheckpoints = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_checkpoints_list", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list checkpoints")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Take a screenshot of the terminal state and save to the Capture panel.
let screenshotTerminal = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_screenshot", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to capture terminal screenshot")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export a recording as HTML replay (self-contained, shareable).
let exportRecording = (
  id: string,
  format: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("valence_shell_recording_export", {"id": id, "format": format})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export recording")))
      Promise.resolve()
    })
    ->ignore
  })
}
