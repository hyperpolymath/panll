// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Mass Panic command wrappers — Tauri invoke bridge for the
/// organisation-scale batch scanning panel (assemblyline + incremental
/// BLAKE3 + verisimdb + delta reporting + notifications).
///
/// All commands invoke panic-attack assemblyline via the Tauri backend.
/// Uses `Tea_Cmd.call` for async operations.

@val external invoke: (string, 'a) => promise<string> = "__TAURI__.core.invoke"

/// Discover git repos in a directory.
/// Returns JSON array of { path, name, has_git } objects.
let discoverRepos = (
  directory: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mass_panic_discover_repos", {"directory": directory})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to discover repos — check directory path")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Run assemblyline scan on selected repos.
/// Accepts configuration for incremental scanning, cache, storage, and filtering.
/// Returns JSON with per-repo results and aggregate summary.
let runAssemblyline = (
  directory: string,
  incremental: bool,
  cachePath: option<string>,
  storePath: option<string>,
  minFindings: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "mass_panic_run_assemblyline",
      {
        "directory": directory,
        "incremental": incremental,
        "cache_path": cachePath,
        "store_path": storePath,
        "min_findings": minFindings,
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Assemblyline scan failed — is panic-attack installed?")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get scan progress (polled during long-running assemblyline scans).
/// Returns JSON with { repos_done, repos_total, current_repo, elapsed_seconds }.
let getProgress = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mass_panic_get_progress", Dict.make())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch scan progress")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Diff two assemblyline reports (delta reporting).
/// Returns JSON array of { repo, new_findings, fixed_findings, direction }.
let diffReports = (
  leftPath: string,
  rightPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mass_panic_diff_reports", {"left_path": leftPath, "right_path": rightPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to compare reports")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Generate notification summary (markdown + optional GitHub issues).
/// Returns the markdown content as a string.
let generateNotification = (
  reportPath: string,
  criticalOnly: bool,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "mass_panic_generate_notification",
      {"report_path": reportPath, "critical_only": criticalOnly},
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to generate notification")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load the BLAKE3 fingerprint cache (shows which repos have changed).
/// Returns JSON with { cached_repos, total_entries }.
let loadCache = (
  cachePath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mass_panic_load_cache", {"cache_path": cachePath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load fingerprint cache")))
      Promise.resolve()
    })
    ->ignore
  })
}
