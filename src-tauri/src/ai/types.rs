// SPDX-License-Identifier: PMPL-1.0-or-later

//! AI type definitions — shared across providers, context, and commands.
//!
//! These types are serialised to/from JSON for the Tauri IPC bridge.
//! The frontend's AiModel.res mirrors these types in ReScript.

use serde::{Deserialize, Serialize};

/// Supported AI provider identifiers.
/// Maps 1:1 to the ReScript `aiProviderId` variant type.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum ProviderId {
    Anthropic,
    Google,
    Mistral,
    #[serde(rename = "openai")]
    OpenAI,
    Local,
}

/// Per-provider configuration. Stored in `~/.config/panll/ai-providers.json`.
/// Each user has their own key ring — not committed to repos.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderConfig {
    /// Which provider this config belongs to.
    pub id: ProviderId,
    /// API key override. `None` = read from environment variable.
    pub api_key: Option<String>,
    /// Environment variable name holding the API key.
    pub env_var: String,
    /// Whether this provider is enabled (mute/unmute without losing key).
    pub enabled: bool,
    /// Priority in the precedence chain (1 = first choice).
    pub priority: u32,
    /// Currently selected model identifier.
    pub model: String,
}

/// Provider runtime status (not persisted — computed at runtime).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "status", content = "detail")]
pub enum ProviderStatus {
    Ready,
    Checking,
    QuotaExhausted,
    Error(String),
    Disabled,
    NoKey,
}

/// Role of a conversation participant.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    User,
    Assistant,
    System,
}

/// A single message in the conversation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiMessage {
    /// Role of the message author.
    pub role: MessageRole,
    /// Text content.
    pub content: String,
    /// Which provider generated this (None for user messages).
    pub provider: Option<ProviderId>,
    /// Which model generated this (None for user messages).
    pub model: Option<String>,
    /// Input tokens consumed.
    pub input_tokens: u32,
    /// Output tokens generated.
    pub output_tokens: u32,
    /// Unix timestamp in milliseconds.
    pub timestamp: f64,
}

/// Request payload from the frontend for sending a message.
#[derive(Debug, Clone, Deserialize)]
pub struct SendMessageRequest {
    /// The user's message text.
    pub content: String,
    /// Conversation history (for context window).
    pub history: Vec<AiMessage>,
    /// Assembled system prompt.
    pub system_prompt: String,
    /// Which provider to use (or None for auto-select by priority).
    pub provider_id: Option<ProviderId>,
    /// Whether to broadcast to multiple providers.
    pub broadcast: bool,
}

/// Response payload sent back to the frontend after a message completes.
#[derive(Debug, Clone, Serialize)]
pub struct SendMessageResponse {
    /// The assistant's response text.
    pub content: String,
    /// Which provider generated this response.
    pub provider: ProviderId,
    /// Which model was used.
    pub model: String,
    /// Input tokens consumed by this request.
    pub input_tokens: u32,
    /// Output tokens in the response.
    pub output_tokens: u32,
    /// Whether the provider hit a quota limit (429).
    pub quota_exhausted: bool,
}

/// Top-level config file structure (`~/.config/panll/ai-providers.json`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiProvidersFile {
    /// All configured providers.
    pub providers: Vec<ProviderConfig>,
}

impl AiProvidersFile {
    /// Default provider configurations with common env var names.
    /// API keys default to None (read from env).
    pub fn defaults() -> Self {
        Self {
            providers: vec![
                ProviderConfig {
                    id: ProviderId::Anthropic,
                    api_key: None,
                    env_var: "ANTHROPIC_API_KEY".to_string(),
                    enabled: true,
                    priority: 1,
                    model: "claude-opus-4-6".to_string(),
                },
                ProviderConfig {
                    id: ProviderId::Google,
                    api_key: None,
                    env_var: "GOOGLE_AI_KEY".to_string(),
                    enabled: true,
                    priority: 2,
                    model: "gemini-2.5-pro".to_string(),
                },
                ProviderConfig {
                    id: ProviderId::Mistral,
                    api_key: None,
                    env_var: "MISTRAL_API_KEY".to_string(),
                    enabled: false,
                    priority: 3,
                    model: "mistral-large-latest".to_string(),
                },
                ProviderConfig {
                    id: ProviderId::OpenAI,
                    api_key: None,
                    env_var: "OPENAI_API_KEY".to_string(),
                    enabled: false,
                    priority: 4,
                    model: "gpt-4o".to_string(),
                },
                ProviderConfig {
                    id: ProviderId::Local,
                    api_key: None,
                    env_var: "".to_string(),
                    enabled: false,
                    priority: 5,
                    model: "llama3".to_string(),
                },
            ],
        }
    }
}
