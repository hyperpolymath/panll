// SPDX-License-Identifier: MPL-2.0

//! PanLL VoiceTag Module — Rust backend for Code MRI Layer 0.
//!
//! Provides filesystem I/O for `.mri.json` sidecar files. The sidecar format
//! is intentionally simple so that a 20-line Python script, a `jq` command,
//! or any editor plugin can create and query tags without PanLL installed.
//!
//! Commands:
//!   - `voicetag_load`:   Read a `.mri.json` sidecar file
//!   - `voicetag_save`:   Write a `.mri.json` sidecar file
//!   - `voicetag_delete`: Remove a `.mri.json` sidecar file
//!   - `voicetag_scan`:   Find all `.mri.json` files in a directory tree

pub mod commands;
