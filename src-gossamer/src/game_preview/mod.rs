// SPDX-License-Identifier: MPL-2.0

//! Game Preview — IDApTIK game engine preview and recording module.
//!
//! Provides Tauri command handlers for the Game Preview panel:
//! dev-server connectivity checks, engine control (pause/resume/step),
//! screen capture, render statistics, and clip recording with filesystem
//! persistence in `/tmp/panll/game-clips/`.

pub mod commands;
