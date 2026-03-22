// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ENSAID_CONFIG Commands — backend invoke wrappers for reading and writing
/// .machine_readable/ENSAID_CONFIG.a2ml files.
///
/// Used by Minter, Provisioner, Workspace, and Automation Router to export
/// the current PanLL configuration as a well-annotated, human-editable file.

let invoke = RuntimeBridge.invoke

/// Write ENSAID_CONFIG.a2ml to a repo's .machine_readable/ directory.
/// Creates the directory if it doesn't exist.
let writeConfig = (
  repoPath: string,
  content: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ensaid_config_write", {"repoPath": repoPath, "content": content})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to write ENSAID_CONFIG.a2ml")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read ENSAID_CONFIG.a2ml from a repo's .machine_readable/ directory.
/// Returns the file content as a string, or an error if not found.
let readConfig = (
  repoPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ensaid_config_read", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("No ENSAID_CONFIG.a2ml found")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Preview what the generated ENSAID_CONFIG would look like (pure, no I/O).
/// This is used by the "Preview" button in the export UI to show the file
/// content before writing it.
let preview = (
  ~repoName: string,
  ~workspace: option<WorkspaceModel.workspaceState>=?,
  ~humidity: string="medium",
  ~panelConfigs: array<ProvisionerModel.panelConfig>=[],
  ~portfolios: array<ProvisionerModel.portfolio>=[],
  ~automationRules: array<AutomationRouterModel.automationRule>=[],
  (),
): string => {
  EnsaidConfigEngine.generate(
    ~repoName,
    ~workspace?,
    ~humidity,
    ~panelConfigs,
    ~portfolios,
    ~automationRules,
    (),
  )
}
