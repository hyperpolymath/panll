// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// UpdateSettings — TEA state transitions for PanLL settings.
///
/// Pure updater for settings load, individual setting changes, and bulk save.

open Model
open Msg

/// Parse settings JSON from the backend into a settingsState.
let parseSettingsJson = (jsonStr: string, current: settingsState): settingsState => {
  try {
    switch JSON.parseExn(jsonStr)->JSON.Classify.classify {
    | Object(d) => {
        let getString = (key: string, default: string) =>
          d
          ->Dict.get(key)
          ->Option.flatMap(v =>
            switch JSON.Classify.classify(v) {
            | String(s) => Some(s)
            | _ => None
            }
          )
          ->Option.getOr(default)
        let getInt = (key: string, default: int) =>
          d
          ->Dict.get(key)
          ->Option.flatMap(v =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Some(Float.toInt(n))
            | _ => None
            }
          )
          ->Option.getOr(default)
        let getBool = (key: string, default: bool) =>
          d
          ->Dict.get(key)
          ->Option.flatMap(v =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => Some(b)
            | _ => None
            }
          )
          ->Option.getOr(default)
        {
          verisimdbUrl: getString("verisimdb_url", current.verisimdbUrl),
          echidnaUrl: getString("echidna_url", current.echidnaUrl),
          burbleUrl: getString("burble_url", current.burbleUrl),
          bojUrl: getString("boj_url", current.bojUrl),
          typellUrl: getString("typell_url", current.typellUrl),
          configDir: getString("config_dir", current.configDir),
          theme: getString("theme", current.theme),
          autoSaveIntervalMs: getInt("auto_save_interval_ms", current.autoSaveIntervalMs),
          autoConnectServices: getBool("auto_connect_services", current.autoConnectServices),
          isLoading: false,
          error: None,
          isDirty: false,
        }
      }
    | _ => {...current, isLoading: false, error: Some("Invalid settings response")}
    }
  } catch {
  | _ => {...current, isLoading: false, error: Some("Failed to parse settings")}
  }
}

/// Settings updater — routes settings messages to state transitions.
let updateSettings = (model: model, subMsg: settingsMsg): (model, Tea_Cmd.t<msg>) => {
  let settings = model.settings
  switch subMsg {
  | LoadSettings => (
      {...model, settings: {...settings, isLoading: true, error: None}},
      SettingsCmd.getSettings(result => Settings(SettingsLoaded(result))),
    )
  | SettingsLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let newSettings = parseSettingsJson(jsonStr, settings)
        ({...model, settings: newSettings}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, settings: {...settings, isLoading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | SetSetting(key, value) => {
      // Optimistically update the local setting
      let updated = switch key {
      | "verisimdb_url" => {...settings, verisimdbUrl: value, isDirty: true}
      | "echidna_url" => {...settings, echidnaUrl: value, isDirty: true}
      | "burble_url" => {...settings, burbleUrl: value, isDirty: true}
      | "boj_url" => {...settings, bojUrl: value, isDirty: true}
      | "typell_url" => {...settings, typellUrl: value, isDirty: true}
      | "theme" => {...settings, theme: value, isDirty: true}
      | _ => {...settings, isDirty: true}
      }
      (
        {...model, settings: updated},
        SettingsCmd.setSetting(key, value, result => Settings(SetSettingResult(result))),
      )
    }
  | SetSettingResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let newSettings = parseSettingsJson(jsonStr, settings)
        ({...model, settings: {...newSettings, isDirty: false}}, Tea_Cmd.none)
      }
    | Error(err) => ({...model, settings: {...settings, error: Some(err)}}, Tea_Cmd.none)
    }
  | SaveAllSettings => {
      let settingsJson = JSON.stringifyAny({
        "verisimdb_url": settings.verisimdbUrl,
        "echidna_url": settings.echidnaUrl,
        "burble_url": settings.burbleUrl,
        "boj_url": settings.bojUrl,
        "typell_url": settings.typellUrl,
        "config_dir": settings.configDir,
        "theme": settings.theme,
        "auto_save_interval_ms": settings.autoSaveIntervalMs,
        "auto_connect_services": settings.autoConnectServices,
      })->Option.getOr("{}")
      (
        {...model, settings: {...settings, isLoading: true}},
        SettingsCmd.saveAllSettings(settingsJson, result => Settings(SaveAllResult(result))),
      )
    }
  | SaveAllResult(result) =>
    switch result {
    | Ok(jsonStr) => {
        let newSettings = parseSettingsJson(jsonStr, settings)
        ({...model, settings: {...newSettings, isDirty: false}}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, settings: {...settings, isLoading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  }
}
