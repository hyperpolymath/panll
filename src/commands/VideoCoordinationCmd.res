// SPDX-License-Identifier: PMPL-1.0-or-later

/// VideoCoordination Cmd — side effects for video transfers.
///
/// Calls backend commands for rclone and laminar orchestration.

open RuntimeBridge

/// Start a new rclone transfer batch.
let startTransfer = (source, destination, options) => {
  invoke("video_start_transfer", {
    "source": source,
    "destination": destination,
    "options": options,
  })
}

/// Fetch the latest status of all active transfers.
let fetchStatus = () => {
  invoke("video_fetch_status", ())
}

/// Pause an ongoing transfer batch.
let pauseTransfer = (batchId) => {
  invoke("video_pause_transfer", {"id": batchId})
}
