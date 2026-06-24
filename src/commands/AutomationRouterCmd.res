// SPDX-License-Identifier: MPL-2.0

/// PanLL Automation Router Commands — backend invoke wrappers for loading,
/// saving, and executing automation workflow rules.

let invoke = RuntimeBridge.invoke

/// Load automation rules from .machine_readable/ENSAID_CONFIG.a2ml or local storage.
let loadRules = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("automation_load_rules", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load automation rules")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Save automation rules to local storage.
let saveRules = (rulesJson: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("automation_save_rules", {"rulesJson": rulesJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save automation rules")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Execute an automation rule's actions.
let executeRule = (ruleId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("automation_execute_rule", {"ruleId": ruleId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to execute automation rule")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load rules from .machine_readable/ENSAID_CONFIG.a2ml in the current repo.
let loadFromRepo = (repoPath: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("automation_load_from_repo", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("No ENSAID_CONFIG.a2ml found in repo")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read execution history.
let readHistory = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("automation_read_history", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read execution history")))
      Promise.resolve()
    })
    ->ignore
  })
}
