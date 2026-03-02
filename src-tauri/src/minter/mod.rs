// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Minter Module — Rust backend for the Panel Minter.
//!
//! Generates ReScript source files and Rust backend stubs from templates,
//! then patches the global wiring files (PanelSwitcherModel, PanelRegistry,
//! Model, Msg, Update, View, main.rs) to register the new panel. Every
//! generated panel includes accessibility, ARIA semantics, and keyboard
//! navigation by default — it is structurally harder to create an
//! inaccessible panel than an accessible one.

pub mod types;
pub mod commands;
