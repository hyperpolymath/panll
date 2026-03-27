// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Mass Panic command wrappers — invoke bridge for the
/// organisation-scale batch scanning panel (assemblyline + incremental
/// BLAKE3 + verisimdb + delta reporting + notifications).
///
/// All commands invoke panic-attack assemblyline via the backend.
/// Uses `Tea_Cmd.call` for async operations.

let invoke = RuntimeBridge.invoke

/// Discover git repos in a directory.
/// Returns JSON array of { path, name, has_git } objects.
let discoverRepos = (directory: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
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
let getProgress = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
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

// ---------------------------------------------------------------------------
// Imaging — fNIRS-style spatial health map
// ---------------------------------------------------------------------------

/// Build a system image from an assemblyline scan.
/// Runs assemblyline internally, then builds the fNIRS-style image.
/// Returns panll.system-image.v0 JSON.
let buildImage = (
  directory: string,
  incremental: bool,
  cachePath: option<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "mass_panic_build_image",
      {
        "directory": directory,
        "incremental": incremental,
        "cache_path": cachePath,
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to build system image")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ---------------------------------------------------------------------------
// Temporal — time-series navigation
// ---------------------------------------------------------------------------

/// List temporal snapshots in VeriSimDB.
/// Returns JSON array of snapshot entries.
let listSnapshots = (verisimdbDir: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("mass_panic_list_snapshots", {"verisimdb_dir": verisimdbDir})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list temporal snapshots")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Diff two temporal snapshots.
/// Returns panll.temporal-diff.v0 JSON.
let diffSnapshots = (
  verisimdbDir: string,
  fromSeq: int,
  toSeq: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "mass_panic_diff_snapshots",
      {"verisimdb_dir": verisimdbDir, "from_seq": fromSeq, "to_seq": toSeq},
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to diff temporal snapshots")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Take a temporal snapshot of the current image.
/// Returns snapshot entry JSON.
let takeSnapshot = (
  verisimdbDir: string,
  label: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mass_panic_take_snapshot", {"verisimdb_dir": verisimdbDir, "label": label})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to take temporal snapshot")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load the BLAKE3 fingerprint cache (shows which repos have changed).
/// Returns JSON with { cached_repos, total_entries }.
let loadCache = (cachePath: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
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
