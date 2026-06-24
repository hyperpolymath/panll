// SPDX-License-Identifier: MPL-2.0

//! PanLL Provenance Module — Git blame analysis and unsound marker scanning.
//!
//! Runs `git blame --porcelain` via std::process::Command to extract authorship
//! data, and scans files for dangerous patterns (believe_me, sorry, Admitted,
//! assert_total, unsafeCoerce, unsafePerformIO, Obj.magic) that undermine
//! formal verification.

pub mod commands;
