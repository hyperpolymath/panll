// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// SettingsMsg — TEA messages for PanLL user configuration.

/// Messages that update the settings state.
type settingsMsg =
  | /// Load settings from the backend.
  LoadSettings
  | /// Settings loaded from backend.
  SettingsLoaded(result<string, string>)
  | /// Update a single setting (key, value).
  SetSetting(string, string)
  | /// Result of a single setting update.
  SetSettingResult(result<string, string>)
  | /// Save all settings to backend.
  SaveAllSettings
  | /// Result of saving all settings.
  SaveAllResult(result<string, string>)
