// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Build Dashboard Commands — backend invoke wrappers for triggering
/// builds, reading build status, and running tests.

let invoke = RuntimeBridge.invoke

/// Trigger a build for a specific target.
let triggerBuild = (
  target: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("build_trigger", {"target": target})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Build trigger failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read the current build status for all targets.
let readBuildStatus = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("build_read_status", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read build status")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run the test suite for a target.
let runTests = (
  target: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("build_run_tests", {"target": target})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Test run failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Cancel a running build.
let cancelBuild = (
  target: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("build_cancel", {"target": target})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to cancel build")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read build history.
let readHistory = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("build_read_history", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read build history")))
      Promise.resolve()
    })
    ->ignore
  })
}
