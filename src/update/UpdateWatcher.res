// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Watcher — filesystem observation.
///
/// Handles watcher lifecycle (start/stop/status) and incoming filesystem events.
/// FileEvent is the key message — it carries a `watchEvent` that panels can
/// react to. The watcher maintains a ring buffer of the last 50 events so
/// panels opened after events occur can still see recent activity.

open Model
open Msg

let updateWatcher = (model: model, msg: watcherMsg): (model, Tea_Cmd.t<msg>) => {
  let w = model.watcher
  switch msg {
  | StartWatcher(paths) => (
      {...model, watcher: {...w, error: None}},
      WatcherCmd.start(paths, result => Watcher(WatcherResult(result))),
    )
  | StopWatcher => (
      model,
      WatcherCmd.stop(result => Watcher(WatcherResult(result))),
    )
  | RequestStatus => (
      model,
      WatcherCmd.status(result => Watcher(StatusLoaded(result))),
    )
  | WatcherResult(result) =>
    switch result {
    | Ok(_json) => (
        {...model, watcher: {...w, running: true, error: None}},
        Tea_Cmd.none,
      )
    | Error(e) => (
        {...model, watcher: {...w, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | StatusLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        // Parse the status JSON to update watcher state.
        // The Rust side returns { running, watched_paths, event_count }.
                switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>

          switch JSON.Classify.classify(json) {
          | JSON.Classify.Object(dict) => {
              let running = switch dict->Dict.get("running") {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | JSON.Classify.Bool(b) => b
                | _ => false
                }
              | None => false
              }
              let eventCount = switch dict->Dict.get("event_count") {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | JSON.Classify.Number(n) => Float.toInt(n)
                | _ => 0
                }
              | None => 0
              }
              (
                {
                  ...model,
                  watcher: {
                    ...w,
                    running,
                    eventCount,
                    error: None,
                  },
                },
                Tea_Cmd.none,
              )
            }
          | _ => (model, Tea_Cmd.none)
          }

        | None => (model, Tea_Cmd.none)
        }
      }
    | Error(e) => (
        {...model, watcher: {...w, error: Some(e)}},
        Tea_Cmd.none,
      )
    }
  | FileEvent(event) => {
      // Add to ring buffer (keep last 50 events).
      let maxEvents = 50
      let updated = Array.concat(w.recentEvents, [event])
      let trimmed = if Array.length(updated) > maxEvents {
        updated->Array.sliceToEnd(~start=Array.length(updated) - maxEvents)
      } else {
        updated
      }
      (
        {
          ...model,
          watcher: {
            ...w,
            eventCount: w.eventCount + 1,
            recentEvents: trimmed,
          },
        },
        Tea_Cmd.none,
      )
    }
  }
}
