// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Hypatia Commands — Tauri command wrappers for the Hypatia scanner.
///
/// The Hypatia backend is an Elixir Phoenix API at /api/v1/.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Fetch the status of all 5 neural networks.
let fetchNetworks = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("hypatia_get_networks", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch network status")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch scan results across all repos.
let fetchScans = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("hypatia_get_scans", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch scan results")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Trigger a scan on a specific repo.
let scanRepo = (
  repoName: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("hypatia_scan_repo", {"repoName": repoName})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Scan failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
