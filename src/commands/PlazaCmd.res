// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Palimpsest Plaza Commands — Backend command wrappers for the
/// PMPL licensing panel.
///
/// Each function wraps a backend `invoke` call for license compliance
/// scanning, adoption statistics, and compatibility checking.

let invoke = RuntimeBridge.invoke

/// Scan a single repository for PMPL compliance indicators.
/// Returns JSON with license detection, SPDX header counts, exhibit status.
let scanRepo = (
  repoName: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("plaza_scan_repo", {"repo_name": repoName})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to scan repo: ${repoName}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Compute adoption statistics across the entire ecosystem.
/// Scans all repos under the canonical path and returns aggregate counts.
let adoptionStats = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("plaza_adoption_stats", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to compute adoption statistics")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check PMPL compatibility with another license.
/// Returns JSON with compatible (bool) and notes.
let checkCompatibility = (
  license: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("plaza_check_compatibility", {"license": license})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Compatibility check failed for: ${license}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
