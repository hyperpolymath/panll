// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Feedback Module — Persistent feedback report storage.
//!
//! Saves full feedback reports as timestamped JSON files under
//! `~/.panll/feedback/`. This complements the existing `submit_feedback`
//! command in main.rs (which appends to an NDJSON log in /tmp) by providing
//! a persistent, per-report file storage mechanism that survives reboots.

pub mod commands;
