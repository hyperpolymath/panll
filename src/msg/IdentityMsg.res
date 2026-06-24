// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// IdentityMsg — TEA messages for identity snapshots and team replication.

/// Messages that update the identity state.
type identityMsg =
  | /// Capture a new snapshot with the given name.
  CaptureSnapshot(string)
  | /// Result of snapshot capture.
  CaptureResult(result<string, string>)
  | /// Restore a snapshot by ID.
  RestoreSnapshot(string)
  | /// Result of snapshot restore (full snapshot JSON).
  RestoreResult(result<string, string>)
  | /// List all available snapshots.
  ListSnapshots
  | /// Snapshot list loaded from backend.
  SnapshotsLoaded(result<string, string>)
  | /// Delete a snapshot by ID.
  DeleteSnapshot(string)
  | /// Result of snapshot deletion.
  DeleteResult(result<string, string>)
  | /// Broadcast current snapshot to team members.
  BroadcastSnapshot(string)
  | /// Result of team broadcast.
  BroadcastResult(result<string, string>)
  | /// Team state received from another member.
  TeamStateReceived(result<string, string>)
