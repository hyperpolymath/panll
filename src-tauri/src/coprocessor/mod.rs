// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Coprocessor Control Plane — queries external compute engines
//! (Axiom.jl, BoJ cartridges) and discovers available devices.
//!
//! This is the control plane (Phase 1): it orchestrates external compute
//! rather than dispatching compute directly. The data plane (Phase 2)
//! will add local GPU/CPU dispatch via Zig FFI.

pub mod commands;
