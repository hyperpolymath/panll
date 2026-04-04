// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// UpdateIdentity — TEA state transitions for identity snapshots and team replication.
///
/// Handles capture, restore, list, delete, broadcast, and team state receive.

open Model
open Msg

/// Parse the snapshot list from backend JSON into an array of identitySnapshot.
let parseSnapshotList = (jsonStr: string): array<identitySnapshot> => {
  try {
    switch JSON.parseExn(jsonStr)->JSON.Classify.classify {
    | Array(arr) =>
      arr->Array.filterMap(item => {
        switch JSON.Classify.classify(item) {
        | Object(d) => {
            let getString = key =>
              d
              ->Dict.get(key)
              ->Option.flatMap(v =>
                switch JSON.Classify.classify(v) {
                | String(s) => Some(s)
                | _ => None
                }
              )
            switch (getString("id"), getString("name"), getString("created_at")) {
            | (Some(id), Some(name), Some(createdAt)) => Some({id, name, createdAt})
            | _ => None
            }
          }
        | _ => None
        }
      })
    | _ => []
    }
  } catch {
  | _ => []
  }
}

/// Identity updater — routes identity messages to state transitions.
let rec updateIdentity = (model: model, subMsg: identityMsg): (model, Tea_Cmd.t<msg>) => {
  let ident = model.identity
  switch subMsg {
  | CaptureSnapshot(name) => {
      // Serialize current panel state, settings, and service URLs
      let panllState = Storage.serialize(Storage.extractPersistedState(model))
      let settingsJson =
        JSON.stringifyAny({
          "verisimdb_url": model.settings.verisimdbUrl,
          "echidna_url": model.settings.echidnaUrl,
          "burble_url": model.settings.burbleUrl,
          "boj_url": model.settings.bojUrl,
          "typell_url": model.settings.typellUrl,
          "theme": model.settings.theme,
        })->Option.getOr("{}")
      let serviceUrls =
        JSON.stringifyAny(model.serviceRegistry.services)->Option.getOr("{}")
      (
        {...model, identity: {...ident, isCapturing: true, error: None}},
        IdentityCmd.captureSnapshot(name, panllState, settingsJson, serviceUrls, result =>
          Identity(CaptureResult(result))
        ),
      )
    }
  | CaptureResult(result) =>
    switch result {
    | Ok(_jsonStr) => (
        {...model, identity: {...ident, isCapturing: false}},
        // Refresh the snapshot list after capture
        IdentityCmd.listSnapshots(result => Identity(SnapshotsLoaded(result))),
      )
    | Error(err) => (
        {...model, identity: {...ident, isCapturing: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | RestoreSnapshot(id) => (
      {...model, identity: {...ident, isRestoring: true, error: None}},
      IdentityCmd.loadSnapshot(id, result => Identity(RestoreResult(result))),
    )
  | RestoreResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        // Parse the full snapshot and apply panel state
        try {
          switch JSON.parseExn(jsonStr)->JSON.Classify.classify {
          | Object(d) => {
              let getString = key =>
                d
                ->Dict.get(key)
                ->Option.flatMap(v =>
                  switch JSON.Classify.classify(v) {
                  | String(s) => Some(s)
                  | _ => None
                  }
                )
              let snapshotId = getString("id")
              let panllStateJson = getString("panll_state")
              // Apply the panel state through the same decoder as VeriSimDBStateLoaded
              let restoredModel = switch panllStateJson {
              | Some(stateStr) =>
                switch Decoders.decodeOption(Storage.persistedStateDecoder, stateStr) {
                | Some(state) => Some(Storage.modelFromPersisted(state))
                | None => None
                }
              | None => None
              }
              switch restoredModel {
              | Some(restored) => (
                  {
                    ...model,
                    paneL: restored.paneL,
                    paneN: restored.paneN,
                    paneW: restored.paneW,
                    viewMode: restored.viewMode,
                    paneLVisible: restored.paneLVisible,
                    paneNVisible: restored.paneNVisible,
                    paneWVisible: restored.paneWVisible,
                    humidity: restored.humidity,
                    vexometer: {...model.vexometer, index: restored.vexometer.index},
                    orbital: {...model.orbital, stability: restored.orbital.stability},
                    identity: {
                      ...ident,
                      isRestoring: false,
                      activeSnapshotId: snapshotId,
                    },
                  },
                  Tea_Cmd.none,
                )
              | None => (
                  {
                    ...model,
                    identity: {
                      ...ident,
                      isRestoring: false,
                      error: Some("Failed to decode snapshot state"),
                    },
                  },
                  Tea_Cmd.none,
                )
              }
            }
          | _ => (
              {
                ...model,
                identity: {...ident, isRestoring: false, error: Some("Invalid snapshot format")},
              },
              Tea_Cmd.none,
            )
          }
        } catch {
        | _ => (
            {
              ...model,
              identity: {...ident, isRestoring: false, error: Some("Snapshot parse failed")},
            },
            Tea_Cmd.none,
          )
        }
      }
    | Error(err) => (
        {...model, identity: {...ident, isRestoring: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ListSnapshots => (model, IdentityCmd.listSnapshots(result => Identity(SnapshotsLoaded(result))))
  | SnapshotsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let snapshots = parseSnapshotList(jsonStr)
        ({...model, identity: {...ident, snapshots}}, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | DeleteSnapshot(id) => (
      model,
      IdentityCmd.deleteSnapshot(id, result => Identity(DeleteResult(result))),
    )
  | DeleteResult(result) =>
    switch result {
    | Ok(_) =>
      // Refresh list after deletion
      (model, IdentityCmd.listSnapshots(result => Identity(SnapshotsLoaded(result))))
    | Error(err) => ({...model, identity: {...ident, error: Some(err)}}, Tea_Cmd.none)
    }
  | BroadcastSnapshot(snapshotJson) => (
      model,
      IdentityCmd.broadcastSnapshot(snapshotJson, result => Identity(BroadcastResult(result))),
    )
  | BroadcastResult(_) => (model, Tea_Cmd.none)
  | TeamStateReceived(result) =>
    // Reuse the RestoreResult handler logic
    switch result {
    | Ok(jsonStr) => updateIdentity(model, RestoreResult(Ok(jsonStr)))
    | Error(_) => (model, Tea_Cmd.none)
    }
  }
}
