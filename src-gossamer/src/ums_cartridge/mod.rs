// SPDX-License-Identifier: MPL-2.0

//! UMS Cartridge — BoJ cartridge backend for ums-mcp routing.
//!
//! When PanLL routes through BoJ (Barrel of Jelly) to `ums-mcp`, this module
//! handles the request. It bridges PanLL's Level Architect panel to IDApTIK's
//! Universal Modding Studio validation layer.
//!
//! The cartridge reads and writes level data JSON via a shared bridge directory
//! (`/tmp/panll/ums-bridge/`), runs the same five ABI validation checks that
//! the `idaptik-ums` Tauri shell performs, and returns results in the same
//! JSON format so frontends see identical responses regardless of whether they
//! invoke the UMS directly or through the BoJ cartridge proxy.
//!
//! ## Shared bridge directory
//!
//! `/tmp/panll/ums-bridge/` is distinct from `/tmp/panll/ums-projects/` (UMS
//! panel storage). The bridge directory is ephemeral and used exclusively for
//! cross-process communication between PanLL and IDApTIK UMS.
//!
//! ## ABI validation checks
//!
//! Five proof obligations mirroring `src/abi/Validation.idr`:
//!
//!   1. **GuardsInZones** — all guards reference valid zones
//!   2. **DefenceTargetsValid** — failover/cascade/mirror IPs exist in registry
//!   3. **ZonesOrdered** — zone transitions are monotonically increasing by X
//!   4. **PBXConsistent** — when PBX is enabled, its IP is in the registry
//!   5. **DevicesExist** — all defence config IPs exist in the registry

pub mod commands;
