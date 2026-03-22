// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Minter Commands — Backend command wrappers for panel scaffolding.
///
/// The minter backend generates ReScript source files and Rust backend
/// stubs, then patches the global wiring files to register the new panel.

let invoke = RuntimeBridge.invoke

/// Mint a new panel from the given form data.
/// The backend generates all files and patches wiring.
/// Returns a JSON-serialised MintResult.
let mintPanel = (
  panelName: string,
  shortName: string,
  description: string,
  icon: string,
  backendKind: string,
  accessibility: string,
  capabilities: string,
  endpoint: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("minter_mint_panel", {
      "panelName": panelName,
      "shortName": shortName,
      "description": description,
      "icon": icon,
      "backendKind": backendKind,
      "accessibility": accessibility,
      "capabilities": capabilities,
      "endpoint": endpoint,
    })
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to mint panel")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Validate a panel name against the existing registry.
/// Returns "valid" or an error description.
let validateName = (
  name: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("minter_validate_name", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Validation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
