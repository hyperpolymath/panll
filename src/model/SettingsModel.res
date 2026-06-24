// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// SettingsModel — Types for PanLL user configuration.
///
/// Captures service URLs, paths, theme, and preferences. Backed by
/// `~/.panll/config.json` with optional VeriSimDB sync.
///
/// Part of Connected Workbench v0.2.0.

/// PanLL user settings — mirrors the Rust `PanllSettings` struct.
type settingsState = {
  /// VeriSimDB base URL.
  verisimdbUrl: string,
  /// ECHIDNA theorem prover base URL.
  echidnaUrl: string,
  /// Burble voice server base URL.
  burbleUrl: string,
  /// BoJ cartridge server base URL.
  bojUrl: string,
  /// TypeLL type verification kernel base URL.
  typellUrl: string,
  /// PanLL configuration directory path.
  configDir: string,
  /// UI theme name.
  theme: string,
  /// Auto-save interval in milliseconds.
  autoSaveIntervalMs: int,
  /// Whether to auto-connect to services on startup.
  autoConnectServices: bool,
  /// Whether settings are being loaded from backend.
  isLoading: bool,
  /// Error message from last settings operation.
  error: option<string>,
  /// Whether settings have unsaved changes.
  isDirty: bool,
}
