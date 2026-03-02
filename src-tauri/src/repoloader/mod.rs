// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Repo Loader Module — repository scanning and panel configuration.
//!
//! Scans a repo's manifests (0-AI-MANIFEST.a2ml, PANELS.a2ml, STATE.scm),
//! detects languages, and suggests which PanLL panels to activate.
//! Panel configs are saved as `.machine_readable/PANELS.a2ml` portfolios.

pub mod types;
pub mod scanner;
pub mod commands;
