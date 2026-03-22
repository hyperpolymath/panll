// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — Timeline Commands (Layer 2)
///
/// backend invoke wrappers for VeriSimDB-backed development timeline persistence.
/// The Rust backend manages the VeriSimDB connection, stores timeline snapshots,
/// and retrieves historical data for the "time machine" scrubber.
///
/// Command pattern follows PanLL convention:
///   `commandName(args..., tagger) => Tea_Cmd.t<'msg>`
///
/// DESIGN NOTE: Snapshots are captured on commit hooks (via the Watcher panel)
/// and on-demand via the Code MRI dashboard. The backend aggregates metrics
/// from git, panic-attack findings, Vexometer readings, and .mri.json tag
/// counts into a single TimelineEngine.timelineSnapshot struct.

let invoke = RuntimeBridge.invoke

/// Connect to the VeriSimDB timeline database for the current repo.
///
/// Creates the database file if it doesn't exist. The path is derived from
/// the repo root: `<repo>/.panll/timeline.verisimdb`.
///
/// @param repoPath  Root path of the repository
/// @param tagger    Callback receiving Ok(dbPath) or Error(message)
/// @returns TEA command that initiates the connection
let connect = (
  repoPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("timeline_connect", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to connect to timeline database")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Capture a new timeline snapshot for the current repo state.
///
/// The Rust backend gathers metrics from:
///   - git (lines of code, commit hash)
///   - panic-attack (finding count)
///   - .mri.json sidecars (tag count)
///   - Vexometer state (friction reading)
///   - AI attribution from provenance data
///
/// The snapshot is stored in VeriSimDB and returned as JSON.
///
/// @param repoPath  Root path of the repository
/// @param tagger    Callback receiving Ok(snapshotJson) or Error(message)
/// @returns TEA command that triggers snapshot capture
let captureSnapshot = (
  repoPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("timeline_capture_snapshot", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to capture timeline snapshot")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load all timeline snapshots from VeriSimDB for the current repo.
///
/// Returns a JSON array of snapshot objects, ordered oldest-first.
/// The caller should parse these into TimelineEngine.timelineSnapshot values.
///
/// @param repoPath  Root path of the repository
/// @param tagger    Callback receiving Ok(snapshotsJson) or Error(message)
/// @returns TEA command that loads the timeline history
let loadHistory = (
  repoPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("timeline_load_history", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load timeline history")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Query timeline snapshots within a date range.
///
/// Returns snapshots where timestamp is between startDate and endDate
/// (inclusive, ISO 8601 format). Useful for zoomed timeline views.
///
/// @param repoPath   Root path of the repository
/// @param startDate  ISO 8601 start date (inclusive)
/// @param endDate    ISO 8601 end date (inclusive)
/// @param tagger     Callback receiving Ok(snapshotsJson) or Error(message)
/// @returns TEA command that queries the range
let queryRange = (
  repoPath: string,
  startDate: string,
  endDate: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("timeline_query_range", {
      "repoPath": repoPath,
      "startDate": startDate,
      "endDate": endDate,
    })
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to query timeline range")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export the full timeline as a JSON file for external analysis.
///
/// Writes a standalone JSON file to the specified path, containing all
/// snapshots and computed metrics. This file can be consumed by Hypatia
/// for pattern analysis or by external tools.
///
/// @param repoPath   Root path of the repository
/// @param outputPath Path where the exported JSON file will be written
/// @param tagger     Callback receiving Ok(outputPath) or Error(message)
/// @returns TEA command that triggers the export
let exportTimeline = (
  repoPath: string,
  outputPath: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("timeline_export", {
      "repoPath": repoPath,
      "outputPath": outputPath,
    })
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export timeline")))
      Promise.resolve()
    })
    ->ignore
  })
}
