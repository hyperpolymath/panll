// SPDX-License-Identifier: PMPL-1.0-or-later

//! AI type definitions — shared across providers, context, and commands.
//!
//! These types are serialised to/from JSON for the Tauri IPC bridge.
//! The frontend's AiModel.res mirrors these types in ReScript.

#![allow(dead_code)]

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

// ---------------------------------------------------------------------------
// Streaming types — SSE streaming with tool_use for Claude Code integration
// ---------------------------------------------------------------------------

/// Stream chunk types emitted via Tauri events during streaming.
/// The frontend listens on `ai:stream-chunk` for these tagged payloads
/// and routes them through the TEA update loop.
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type", content = "data")]
pub enum StreamChunk {
    /// A text fragment from the assistant's response.
    TextDelta(String),
    /// A tool_use content block has started. Claude wants to call a tool.
    ToolUseStart { id: String, name: String },
    /// An incremental JSON fragment of the tool's input parameters.
    ToolUseDelta(String),
    /// The tool_use content block is complete; input JSON is fully accumulated.
    ToolUseEnd,
    /// The message is complete. Carries final token usage.
    Complete { input_tokens: u32, output_tokens: u32 },
    /// An error occurred during streaming.
    Error(String),
}

/// Tool definition for Claude's tool_use feature.
/// Passed in the request body so Claude knows which tools are available.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolDefinition {
    /// Tool name (must match a BoJ cartridge tool identifier).
    pub name: String,
    /// Human-readable description of what the tool does.
    pub description: String,
    /// JSON Schema for the tool's input parameters.
    pub input_schema: serde_json::Value,
}

/// Tool result returned to Claude after execution.
/// Appended as a `tool_result` content block in the next request.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolResult {
    /// The tool_use_id from the original ToolUseStart chunk.
    pub tool_use_id: String,
    /// The tool's output content (stringified).
    pub content: String,
    /// Whether the tool execution failed.
    pub is_error: bool,
}

/// Extended request for streaming with tool definitions and tool results.
/// Distinct from `SendMessageRequest` to avoid breaking the existing
/// non-streaming path.
#[derive(Debug, Clone, Deserialize)]
pub struct StreamingRequest {
    /// The user's message text.
    pub content: String,
    /// Conversation history (for context window).
    pub history: Vec<AiMessage>,
    /// Assembled system prompt.
    pub system_prompt: String,
    /// Which provider to use (or None for auto-select by priority).
    pub provider_id: Option<ProviderId>,
    /// Tool definitions available to Claude (None = no tool_use).
    pub tools: Option<Vec<ToolDefinition>>,
    /// Tool results from previously executed tool calls (None = first turn).
    pub tool_results: Option<Vec<ToolResult>>,
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

// ---------------------------------------------------------------------------
// Smoke tests — type construction, serde round-trips, and defaults
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_provider_id_all_variants_serialise() {
        let ids = [
            ProviderId::Anthropic,
            ProviderId::Google,
            ProviderId::Mistral,
            ProviderId::OpenAI,
            ProviderId::Local,
        ];
        for id in &ids {
            let json = serde_json::to_string(id).expect("ProviderId must serialise");
            let _back: ProviderId = serde_json::from_str(&json).expect("ProviderId must deserialise");
        }
    }

    #[test]
    fn smoke_ai_providers_file_defaults_has_five_providers() {
        let file = AiProvidersFile::defaults();
        assert_eq!(file.providers.len(), 5, "defaults() must return 5 providers");
    }

    #[test]
    fn smoke_ai_providers_file_defaults_anthropic_is_enabled_and_priority_one() {
        let file = AiProvidersFile::defaults();
        let anthropic = file.providers.iter().find(|p| p.id == ProviderId::Anthropic)
            .expect("Anthropic provider must exist");
        assert!(anthropic.enabled, "Anthropic must be enabled by default");
        assert_eq!(anthropic.priority, 1, "Anthropic must have priority 1");
        assert_eq!(anthropic.env_var, "ANTHROPIC_API_KEY");
    }

    #[test]
    fn smoke_ai_message_roundtrip() {
        let msg = AiMessage {
            role: MessageRole::User,
            content: "Hello, world!".to_string(),
            provider: None,
            model: None,
            input_tokens: 5,
            output_tokens: 0,
            timestamp: 1_700_000_000.0,
        };
        let json = serde_json::to_string(&msg).expect("AiMessage must serialise");
        let back: AiMessage = serde_json::from_str(&json).expect("AiMessage must deserialise");
        assert_eq!(back.role, MessageRole::User);
        assert_eq!(back.content, "Hello, world!");
        assert!(back.provider.is_none());
    }

    #[test]
    fn smoke_provider_status_variants_serialise() {
        let statuses: Vec<ProviderStatus> = vec![
            ProviderStatus::Ready,
            ProviderStatus::Checking,
            ProviderStatus::QuotaExhausted,
            ProviderStatus::Error("timeout".to_string()),
            ProviderStatus::Disabled,
            ProviderStatus::NoKey,
        ];
        for status in statuses {
            let json = serde_json::to_string(&status).expect("ProviderStatus must serialise");
            assert!(!json.is_empty());
        }
    }

    #[test]
    fn smoke_stream_chunk_text_delta() {
        let chunk = StreamChunk::TextDelta("Hello".to_string());
        let json = serde_json::to_string(&chunk).expect("StreamChunk::TextDelta must serialise");
        assert!(json.contains("Hello"));
    }

    #[test]
    fn smoke_tool_definition_serialise() {
        let tool = ToolDefinition {
            name: "boj_cartridge_invoke".to_string(),
            description: "Invoke a BoJ cartridge".to_string(),
            input_schema: serde_json::json!({"type": "object", "properties": {}}),
        };
        let json = serde_json::to_string(&tool).expect("ToolDefinition must serialise");
        assert!(json.contains("boj_cartridge_invoke"));
    }
}
