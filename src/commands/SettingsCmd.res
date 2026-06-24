// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// SettingsCmd — TEA command wrappers for PanLL settings operations.

let invoke = RuntimeBridge.invoke

/// Load all settings from the backend.
let getSettings = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("settings_get", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Settings load failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Set a single setting by key.
let setSetting = (
  key: string,
  value: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("settings_set", {"key": key, "value": value})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Setting update failed for " ++ key)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Save all settings as a complete JSON blob.
let saveAllSettings = (settingsJson: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("settings_save", {"settings": settingsJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Settings save failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
