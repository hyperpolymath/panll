// SPDX-License-Identifier: MPL-2.0

//! PanLL Workspace Module — panel arrangements, groups, sessions, and system info.
//!
//! This module provides the Tauri backend for the workspace management layer
//! (DD-024, DD-025). It handles:
//! - Saving/loading named panel arrangements to disk
//! - Session persistence and forking
//! - System information queries (CPU, memory, disk) for status bar widgets
//!
//! All state serialisation uses JSON files in the PanLL config directory.

pub mod types;
pub mod commands;
pub mod sysinfo;
