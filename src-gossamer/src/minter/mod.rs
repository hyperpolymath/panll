// SPDX-License-Identifier: MPL-2.0

//! PanLL Minter Module — Rust backend for the Panel Minter.
//!
//! Generates Gossamer-native ReScript source files and Rust backend stubs
//! from templates, then patches the global wiring files (PanelSwitcherModel,
//! PanelRegistry, Model, Msg, Update, View, main.rs) to register the new
//! panel. Generated code uses RuntimeBridge.invoke for runtime-agnostic IPC
//! (Gossamer or Tauri) and panll-harness/v2 manifests with panll://
//! endpoints and per-runtime endpoint declarations.
//!
//! Every generated panel includes accessibility, ARIA semantics, and keyboard
//! navigation by default — it is structurally harder to create an
//! inaccessible panel than an accessible one.

pub mod types;
pub mod commands;
