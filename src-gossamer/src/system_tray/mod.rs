// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! System Tray Integration
//!
//! Provides system tray icon and menu for PanLL, including service toggling
//! for Burble and Gossamer.

use std::sync::{Arc, Mutex};

/// System tray state
struct SystemTrayState {
    tray_handle: Option<u64>,
    burble_enabled: bool,
    gossamer_enabled: bool,
}

impl SystemTrayState {
    fn new() -> Self {
        Self {
            tray_handle: None,
            burble_enabled: true,
            gossamer_enabled: true,
        }
    }
}

/// Global system tray state
lazy_static::lazy_static! {
    static ref SYSTEM_TRAY_STATE: Arc<Mutex<SystemTrayState>> = {
        Arc::new(Mutex::new(SystemTrayState::new()))
    };
}

/// Initialize the system tray
pub fn init(app: &gossamer_rs::App) -> Result<(), String> {
    // Create system tray icon
    let tray_handle = app.tray_create("PanLL eNSAID").map_err(|e| e.to_string())?;

    // Set tray icon
    app.tray_set_icon(tray_handle, "preferences-system-network")
        .map_err(|e| e.to_string())?;

    // Attach main window to tray
    app.tray_set_window(tray_handle).map_err(|e| e.to_string())?;

    // Add menu items
    app.tray_add_menu_item(tray_handle, "Show PanLL")
        .map_err(|e| e.to_string())?;
    app.tray_add_separator(tray_handle)
        .map_err(|e| e.to_string())?;
    app.tray_add_menu_item(tray_handle, "Burble: ON")
        .map_err(|e| e.to_string())?;
    app.tray_add_menu_item(tray_handle, "Gossamer: ON")
        .map_err(|e| e.to_string())?;
    app.tray_add_separator(tray_handle)
        .map_err(|e| e.to_string())?;
    app.tray_add_menu_item(tray_handle, "Quit")
        .map_err(|e| e.to_string())?;

    // Store tray handle
    {
        let mut state = SYSTEM_TRAY_STATE.lock().unwrap();
        state.tray_handle = Some(tray_handle);
    }

    Ok(())
}

/// Toggle Burble service
pub fn toggle_burble() -> Result<bool, String> {
    let mut state = SYSTEM_TRAY_STATE.lock().unwrap();
    state.burble_enabled = !state.burble_enabled;
    Ok(state.burble_enabled)
}

/// Toggle Gossamer service
pub fn toggle_gossamer() -> Result<bool, String> {
    let mut state = SYSTEM_TRAY_STATE.lock().unwrap();
    state.gossamer_enabled = !state.gossamer_enabled;
    Ok(state.gossamer_enabled)
}

/// Get Burble service status
pub fn get_burble_status() -> bool {
    let state = SYSTEM_TRAY_STATE.lock().unwrap();
    state.burble_enabled
}

/// Get Gossamer service status
pub fn get_gossamer_status() -> bool {
    let state = SYSTEM_TRAY_STATE.lock().unwrap();
    state.gossamer_enabled
}

/// Clean up system tray
pub fn cleanup(app: &gossamer_rs::App) {
    let state = SYSTEM_TRAY_STATE.lock().unwrap();
    if let Some(tray_handle) = state.tray_handle {
        let _ = app.tray_destroy(tray_handle);
    }
}
