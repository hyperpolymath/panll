// SPDX-License-Identifier: MPL-2.0

//! PanLL Security Module — redaction, vault, 2FA, and Trustfile enforcement
//! (DD-026, DD-027).
//!
//! This module provides the Tauri backend for:
//! - Pattern-based secret redaction via regex
//! - Vault integration via the reasonably-good-tool CLI
//! - TOTP-based 2FA (RFC 6238) using HMAC-SHA1
//! - Trustfile.a2ml parsing and security policy loading

pub mod types;
pub mod commands;
