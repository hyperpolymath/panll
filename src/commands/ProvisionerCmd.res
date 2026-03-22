// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ProvisionerCmd — Backend command wrappers for portfolio provisioning.
///
/// Handles panel installation (native or containerised), configuration
/// persistence, and portfolio management. Container operations route through
/// Stapeln when available, falling back to direct Podman commands.

let invoke = RuntimeBridge.invoke

/// Install a panel. For native panels this is a no-op (they're built in).
/// For podded panels, this pulls/builds the container image.
let installPanel = (
  panelName: string,
  isolation: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("provisioner_install_panel", {"panelName": panelName, "isolation": isolation})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to install panel: ${panelName}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Remove a panel. For native panels, just disables it. For podded panels,
/// deletes the container and all its data — clean uninstall, everything gone.
let removePanel = (
  panelName: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("provisioner_remove_panel", {"panelName": panelName})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to remove panel: ${panelName}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Save panel configuration to persistent storage.
let saveConfig = (
  configJson: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("provisioner_save_config", {"config": configJson})
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

/// Load panel configuration from persistent storage.
let loadConfig = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("provisioner_load_config", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load panel configuration")))
      Promise.resolve()
    })
    ->ignore
  })
}
