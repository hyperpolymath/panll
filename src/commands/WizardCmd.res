// SPDX-License-Identifier: MPL-2.0

/// PanLL Wizard Commands — Backend command wrappers for plugin/panel generation.

let invoke = RuntimeBridge.invoke

/// Generate a new plugin or panel based on wizard configuration.
/// The backend handles the actual file generation and registration.
/// Returns a JSON-serialised generation result.
let generate = (
  creationType: string,
  capabilities: string,
  dependencies: string,
  securityConfig: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "wizard_generate",
      {
        "creationType": creationType,
        "capabilities": capabilities,
        "dependencies": dependencies,
        "securityConfig": securityConfig,
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to generate plugin/panel")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Validate wizard configuration before generation.
/// Checks for capability conflicts, dependency issues, etc.
let validateConfig = (
  creationType: string,
  capabilities: string,
  dependencies: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "wizard_validate_config",
      {
        "creationType": creationType,
        "capabilities": capabilities,
        "dependencies": dependencies,
      },
    )
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