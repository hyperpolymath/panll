// SPDX-License-Identifier: MPL-2.0

//! PanLL Wiring Inspector Module — Panel Contract Compiler (PCC) bridge.
//!
//! Runs the PCC binary against the PanLL source tree and returns JSON
//! constraint state for the frontend to render. Supports both full
//! verification (all panels) and single-panel verification.

pub mod commands;
