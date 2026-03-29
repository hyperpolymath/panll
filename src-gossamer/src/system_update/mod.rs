// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! System Update — component update management for PanLL.
//!
//! Discovers and manages updatable system components:
//!   - rpm-ostree (Fedora Atomic base OS)
//!   - Flatpak (sandboxed desktop apps)
//!   - asdf plugins (33+ language toolchains)
//!   - Cargo binaries (Rust CLI tools)
//!   - Deno/Bun (JS runtimes)
//!   - GHCup (Haskell toolchain)
//!   - opam (OCaml packages)
//!   - mix (Elixir/Hex)
//!   - Julia packages
//!   - pipx (Python CLI tools)
//!   - fwupd (firmware)

pub mod commands;
