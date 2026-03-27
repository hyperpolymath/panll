// SPDX-License-Identifier: PMPL-1.0-or-later

/// VideoCoordination Engine — pure computation for the video coordination logic.
///
/// Implements state transitions for batches and quota management.

open VideoCoordinationModel

let defaultState: videoCoordinationState = {
  activeBatches: list{},
  loading: false,
  error: None,
  totalBytesMoved: 0.0,
  quotaRemaining: 750.0 *. 1024.0 *. 1024.0 *. 1024.0, // 750 GB in bytes
}

/// Update a batch status within the list of active batches.
let updateBatch = (batches, updatedBatch) => {
  batches->List.map(b => b.id == updatedBatch.id ? updatedBatch : b)
}

/// Add a new transfer batch.
let addBatch = (state, source, destination, totalFiles) => {
  let newBatch = {
    id: Date.now()->Float.toString,
    source,
    destination,
    totalFiles,
    processedFiles: 0,
    failedFiles: 0,
    status: "Idle",
    startTime: None,
  }
  {...state, activeBatches: list{newBatch, ...state.activeBatches}}
}

/// Calculate percentage completion for a batch.
let batchProgress = batch => {
  if batch.totalFiles == 0 {
    100.0
  } else {
    batch.processedFiles->Belt.Int.toFloat /. batch.totalFiles->Belt.Int.toFloat *. 100.0
  }
}
