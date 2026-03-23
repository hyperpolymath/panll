// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Capture Module — screenshots, recordings, and demo packages (DD-022).
//!
//! This module provides the Tauri backend for:
//! - Saving screenshot data (PNG/PDF) to disk
//! - Managing screen recordings via ffmpeg subprocess
//! - Packaging and loading .panll-demo files (ZIP archives)
//!
//! Screenshots are captured in the frontend via html2canvas (JS library)
//! and sent to Rust for file I/O. Recordings use ffmpeg as an external
//! subprocess for screen capture.

pub mod types;
pub mod commands;
