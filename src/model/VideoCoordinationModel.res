// SPDX-License-Identifier: MPL-2.0

/// VideoCoordination Model — types for the Video Move Coordination panel.
///
/// Manages the state of video transfers between Google Drive and Google Photos.

type transferBatch = {
  id: string,
  source: string,
  destination: string,
  totalFiles: int,
  processedFiles: int,
  failedFiles: int,
  status: string, // "Idle", "Active", "Paused", "Completed"
  startTime: option<float>,
}

/// State for the VideoCoordination panel.
type videoCoordinationState = {
  activeBatches: list<transferBatch>,
  loading: bool,
  error: option<string>,
  totalBytesMoved: float,
  quotaRemaining: float, // Daily 750GB limit tracking
}
