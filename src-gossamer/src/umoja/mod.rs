// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Umoja — peer management module for the Umoja gossip federation layer.
//!
//! Provides Tauri command handlers for managing federation peers:
//! add, disconnect, gossip trigger, catalogue sync, and metrics retrieval.
//! These complement the existing BoJ Umoja status query in boj::commands.

pub mod commands;
