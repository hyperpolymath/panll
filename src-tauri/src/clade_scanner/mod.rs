// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Clade Scanner Module — reads `.a2ml` clade definition files from
//! `panel-clades/clades/` and returns them as JSON for the ReScript frontend.
//!
//! Commands:
//!   - `scan_clade_files`: Walks `panel-clades/clades/*/` and returns all
//!     `.a2ml` file contents as a JSON array of `{id, content}` objects.

pub mod commands;
