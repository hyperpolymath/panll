// SPDX-License-Identifier: PMPL-1.0-or-later

//! Release Manager — IDApTIK versioning, changelog, and distribution module.
//!
//! Provides Tauri command handlers for the Release Manager panel:
//! changelog generation from git history, artifact building for target
//! platforms, release publishing, version history, and semver bumping.

pub mod commands;
