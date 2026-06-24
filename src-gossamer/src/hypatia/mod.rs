// SPDX-License-Identifier: MPL-2.0

//! PanLL Hypatia Module — Rust backend for the Hypatia neurosymbolic scanner panel.
//!
//! Connects to the Hypatia Elixir Phoenix API at /api/v1 for neural network
//! status, scan results, and triggering repo scans. When the Hypatia server is
//! offline, commands return empty fallback data so the panel degrades gracefully.

pub mod commands;
