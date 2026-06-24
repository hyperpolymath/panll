// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// Capabilities — Gossamer capability token management for the Clade Portal.
///
/// The Clade Portal requires two capabilities:
///   - filesystem (kind 2): Read clade directories and A2ML metadata files
///     from the panel-clades path on disk.
///   - network (kind 1): Fetch health status from running panel services
///     to display live health indicators in the portal.
///
/// Flow:
///   1. App starts with NO capabilities (sandbox by default)
///   2. User sees the capability grant panel
///   3. User clicks "Grant Filesystem" -> Gossamer shows consent dialog
///   4. Runtime returns a token (float) valid for TTL seconds
///   5. All subsequent file reads include the token in the IPC payload
///   6. Token expires -> app must re-request or operations fail

/// Capability kind identifiers matching the Gossamer runtime's internal enum.
module Kind = {
  /// Filesystem access — read clade directories and A2ML files.
  let filesystem = 2

  /// Network access — fetch panel health status from running services.
  let network = 1

  /// Human-readable name for a capability kind.
  let toString = (kind: int): string => {
    switch kind {
    | 1 => "network"
    | 2 => "filesystem"
    | k => `unknown(${Int.toString(k)})`
    }
  }

  /// Description of why the Clade Portal needs this capability.
  let description = (kind: int): string => {
    switch kind {
    | 1 => "Check health of running panel services to display live status indicators."
    | 2 => "Read clade directories and A2ML metadata files from the panel-clades path."
    | _ => "Unknown capability."
    }
  }
}

/// Request a capability token from the Gossamer runtime.
///
/// This triggers Gossamer's consent dialog. The user must approve the
/// request before the runtime issues a token. Returns a promise that
/// resolves to the token value (float) on success.
///
/// @param kind - The capability kind (use Kind.filesystem, Kind.network)
let requestCapability = (kind: int): promise<float> => {
  RuntimeBridge.invoke("__gossamer_cap_grant", {"kind": kind})
}

/// Request filesystem capability — needed to read clade A2ML files.
///
/// Without this token, no clade metadata can be loaded from disk.
/// This is the first capability users should grant.
let requestFilesystemAccess = (): promise<float> => {
  requestCapability(Kind.filesystem)
}

/// Request network capability — needed for panel health checks.
///
/// Health indicators show which panels are running, degraded, or offline.
/// This capability is optional but recommended for full portal features.
let requestNetworkAccess = (): promise<float> => {
  requestCapability(Kind.network)
}

/// Revoke a previously granted capability.
///
/// After revocation, any IPC calls using the old token will fail.
///
/// @param kind - The capability kind to revoke
let revokeCapability = (kind: int): promise<unit> => {
  RuntimeBridge.invoke("__gossamer_cap_revoke", {"kind": kind})
}

/// Check whether a token is still valid.
///
/// Tokens expire after the TTL defined in gossamer.conf.json (default:
/// 3600 seconds). This lets the app proactively check and re-request
/// before a critical operation fails.
///
/// @param token - The capability token to validate
let validateToken = (token: float): promise<bool> => {
  RuntimeBridge.invoke("__gossamer_cap_validate", {"token": token})
}
