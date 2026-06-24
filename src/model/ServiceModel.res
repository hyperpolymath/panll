// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// ServiceModel — Types for the PanLL service registry.
///
/// Tracks connection state, URLs, and health for all backend services
/// (VeriSimDB, ECHIDNA, Burble, BoJ, TypeLL). The service registry is
/// the source of truth for which services are reachable and at what URLs.
///
/// Part of Connected Workbench v0.2.0 — provides the foundation for
/// service switching, identity state capture, and the Settings panel.

/// Current status of a backend service.
type serviceStatus =
  | Running
  | Stopped
  | Checking
  | Error(string)

/// A registered backend service with its URL and current status.
type serviceEntry = {
  /// Human-readable service name (e.g. "VeriSimDB").
  name: string,
  /// Base URL including protocol and port (e.g. "http://localhost:8080").
  url: string,
  /// Path to probe for health (e.g. "/health").
  healthPath: string,
  /// Current connection status.
  status: serviceStatus,
}

/// Full state of the service registry.
type serviceRegistryState = {
  /// All registered services, keyed by identifier (e.g. "verisim").
  services: Dict.t<serviceEntry>,
  /// Timestamp of last full health check (milliseconds since epoch).
  lastChecked: option<float>,
  /// Whether a full registry refresh is currently in progress.
  isRefreshing: bool,
}
