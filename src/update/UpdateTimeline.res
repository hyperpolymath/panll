// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

// ===========================================================================
// Code MRI Timeline Sub-Updater (Layer 2)
//
// Handles VeriSimDB connection, snapshot capture/load, scrubber navigation,
// and export. All metric computation is delegated to TimelineEngine (pure).
// ===========================================================================

let updateTimeline = (model: model, msg: timelineMsg): (model, Tea_Cmd.t<msg>) => {
  let tl = model.codeMriTimeline
  switch msg {
  | Connect => (
      {...model, codeMriTimeline: {...tl, error: None}},
      TimelineCmd.connect(".", result => Timeline(Connected(result))),
    )
  | Connected(Ok(dbPath)) => (
      {...model, codeMriTimeline: {...tl, dbPath: Some(dbPath), connected: true, error: None}},
      Tea_Cmd.none,
    )
  | Connected(Error(err)) => (
      {...model, codeMriTimeline: {...tl, connected: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | CaptureSnapshot => (
      {...model, codeMriTimeline: {...tl, capturing: true, error: None}},
      TimelineCmd.captureSnapshot(".", result => Timeline(SnapshotCaptured(result))),
    )
  | SnapshotCaptured(Ok(_json)) => {
      // Parse snapshot from JSON and add to timeline
      // For now, create a snapshot from current model state
      let snap: TimelineEngine.timelineSnapshot = {
        timestamp: Float.toString(Date.now()),
        linesOfCode: 0, // Will be populated by Rust backend
        todoCount: model.voiceTag.summary.todoCount,
        fixmeCount: model.voiceTag.summary.fixmeCount,
        tagCount: model.voiceTag.summary.totalTags,
        libraryCount: 0,
        failedTypeChecks: 0,
        panicAttackFindings: 0,
        aiAttributionPercent: 0.0,
        vexometerReading: model.vexometer.index,
        commitHash: "",
      }
      let newSnapshots = TimelineEngine.addSnapshot(tl.snapshots, snap)
      let newMetrics = TimelineEngine.allMetrics(newSnapshots)
      (
        {
          ...model,
          codeMriTimeline: {
            ...tl,
            snapshots: newSnapshots,
            cachedMetrics: newMetrics,
            capturing: false,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    }
  | SnapshotCaptured(Error(err)) => (
      {...model, codeMriTimeline: {...tl, capturing: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadHistory => (
      model,
      TimelineCmd.loadHistory(".", result => Timeline(HistoryLoaded(result))),
    )
  | HistoryLoaded(Ok(_json)) => {
      // Parsing will be done properly when VeriSimDB backend is wired.
      // For now, refresh metrics from existing snapshots.
      let newMetrics = TimelineEngine.allMetrics(tl.snapshots)
      (
        {...model, codeMriTimeline: {...tl, cachedMetrics: newMetrics, error: None}},
        Tea_Cmd.none,
      )
    }
  | HistoryLoaded(Error(err)) => (
      {...model, codeMriTimeline: {...tl, error: Some(err)}},
      Tea_Cmd.none,
    )
  | QueryRange(startDate, endDate) => (
      model,
      TimelineCmd.queryRange(".", startDate, endDate, result => Timeline(RangeLoaded(result))),
    )
  | RangeLoaded(Ok(_json)) => (model, Tea_Cmd.none)
  | RangeLoaded(Error(err)) => (
      {...model, codeMriTimeline: {...tl, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SeekScrubber(pos) => (
      {...model, codeMriTimeline: {...tl, scrubberPosition: pos}},
      Tea_Cmd.none,
    )
  | ToggleDashboard => (
      {...model, codeMriTimeline: {...tl, dashboardExpanded: !tl.dashboardExpanded}},
      Tea_Cmd.none,
    )
  | ExportTimeline(outputPath) => (
      model,
      TimelineCmd.exportTimeline(".", outputPath, result => Timeline(TimelineExported(result))),
    )
  | TimelineExported(Ok(_path)) => (model, Tea_Cmd.none)
  | TimelineExported(Error(err)) => (
      {...model, codeMriTimeline: {...tl, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissError => (
      {...model, codeMriTimeline: {...tl, error: None}},
      Tea_Cmd.none,
    )
  }
}
