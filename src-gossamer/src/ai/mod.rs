// SPDX-License-Identifier: MPL-2.0

//! PanLL AI Module — Multi-provider AI backend for the neural interface panel.
//!
//! Provider-agnostic: speaks to Anthropic, Google, Mistral, OpenAI, and local
//! Ollama models. Each provider has its own HTTP client with provider-appropriate
//! headers and request/response format.
//!
//! Architecture:
//!   - `types.rs`: Serde types for provider config, messages, session state
//!   - `providers.rs`: Per-provider HTTP clients (each implements `send_message`)
//!   - `context.rs`: System prompt assembly from repo SCM files, panels, VoiceTags
//!   - `commands.rs`: Tauri command handlers exposed to the ReScript frontend

pub mod types;
pub mod providers;
pub mod context;
pub mod commands;
