// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// ServiceMsg — TEA messages for the PanLL service registry.
///
/// Drives health checks, URL updates, and registry refresh cycles.

/// Messages that update the service registry state.
type serviceMsg =
  | /// Request a health check of all registered services.
  RefreshAll
  | /// Result of a full registry refresh (JSON from backend).
  RefreshAllResult(result<string, string>)
  | /// Request a health check of a specific service by key.
  CheckService(string)
  | /// Result of a single service health check.
  CheckServiceResult(string, result<string, string>)
  | /// Update the URL of a service (key, newUrl).
  UpdateServiceUrl(string, string)
  | /// Result of a URL update.
  UpdateServiceUrlResult(result<string, string>)
  | /// Registry loaded from backend at startup.
  RegistryLoaded(result<string, string>)
