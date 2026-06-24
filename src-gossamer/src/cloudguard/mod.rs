// SPDX-License-Identifier: MPL-2.0

//! CloudGuard — Cloudflare domain security management module.
//!
//! Provides Tauri command handlers for interacting with the Cloudflare API:
//! zone listing, settings read/write, DNS record CRUD, DNSSEC management,
//! bulk hardening operations, and offline config sync.
//!
//! The API client uses `reqwest::blocking` (matching the PanLL pattern from
//! VeriSimDB/ECHIDNA) with Bearer token auth and rate limiting. Credentials
//! are stored in the OS keyring via the `keyring` crate (Tauri app) or
//! `CLOUDFLARE_API_TOKEN` env var (CLI/CI).

pub mod api;
pub mod types;
pub mod commands;
pub mod config;
pub mod diff;
pub mod trustfile;
