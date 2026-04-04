// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// IdentityModel — Types for PanLL identity snapshots and team replication.
///
/// An identity snapshot captures the full user configuration (panel state,
/// settings, service URLs) as a named entity that can be restored locally
/// or broadcast to team members.
///
/// Part of Connected Workbench v0.2.0.

/// Metadata for an identity snapshot (compact form for listing).
type identitySnapshot = {
  /// Unique snapshot identifier (UUID v4).
  id: string,
  /// Human-readable snapshot name.
  name: string,
  /// ISO 8601 creation timestamp.
  createdAt: string,
}

/// Full state of the identity management system.
type identityState = {
  /// Known snapshots (metadata only — full payload loaded on demand).
  snapshots: array<identitySnapshot>,
  /// Currently active snapshot ID (if the user loaded one).
  activeSnapshotId: option<string>,
  /// Whether a capture operation is in progress.
  isCapturing: bool,
  /// Whether a restore operation is in progress.
  isRestoring: bool,
  /// Error message from last identity operation.
  error: option<string>,
}
