// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL AI Model — leaf types for the multi-provider AI panel.
///
/// Provider-agnostic AI interface that speaks to any LLM backend (Anthropic,
/// Google, Mistral, OpenAI, local Ollama). Each provider is a slot in a key
/// ring with enable/disable, priority, and quota tracking.
///
/// Dependency: none (leaf module in the type DAG).

/// Supported AI provider backends. Each has its own auth scheme, endpoint,
/// and model catalog. The provider ID is the discriminant for routing
/// messages through the correct HTTP client.
type aiProviderId =
  /// Anthropic (Claude) — x-api-key header, Messages API.
  | Anthropic
  /// Google (Gemini) — x-goog-api-key header, GenerativeLanguage API.
  | Google
  /// Mistral AI — Bearer token, Chat Completions API.
  | Mistral
  /// OpenAI (GPT) — Bearer token, Chat Completions API.
  | OpenAI
  /// Local models (Ollama) — no auth, localhost:11434.
  | Local

/// Per-provider configuration stored per-user (NOT per-repo).
/// Lives in `~/.config/panll/ai-providers.json` so each co-developer
/// has their own provider key ring.
type aiProviderConfig = {
  /// Which provider this configuration belongs to.
  id: aiProviderId,
  /// API key override. None = read from environment variable.
  apiKey: option<string>,
  /// Environment variable name holding the API key (e.g. "ANTHROPIC_API_KEY").
  envVar: string,
  /// Whether this provider is enabled. Toggle without losing the key.
  enabled: bool,
  /// Priority in the precedence chain (1 = first choice, 2 = fallback, etc.).
  priority: int,
  /// Currently selected model identifier (e.g. "claude-opus-4-6", "gemini-2.5-pro").
  selectedModel: string,
  /// Set to true when a 429 response is received — auto-fallthrough to next provider.
  quotaExhausted: bool,
}

/// Provider operational status — distinct from config because this changes
/// at runtime as health checks, quota probes, and messages complete.
type aiProviderStatus =
  /// Provider is configured, keyed, and responding.
  | Ready
  /// Health check in progress.
  | Checking
  /// 429 received — quota exhausted, waiting for reset.
  | QuotaExhausted
  /// Provider returned an error (non-429).
  | AiProviderError(string)
  /// User has disabled this provider (muted).
  | Disabled
  /// No API key configured and env var is empty.
  | NoKey

/// Role of a participant in the AI conversation.
type aiRole =
  /// Human operator message.
  | User
  /// AI assistant response.
  | Assistant
  /// System prompt (not shown in conversation, assembled from context).
  | System

/// A single message in the AI conversation stream.
type aiMessage = {
  /// Role of the message author.
  role: aiRole,
  /// The text content of the message.
  content: string,
  /// Which provider generated this response (None for user messages).
  provider: option<aiProviderId>,
  /// Which model generated this response (None for user messages).
  model: option<string>,
  /// Input tokens consumed (0 for user messages).
  inputTokens: int,
  /// Output tokens generated (0 for user messages).
  outputTokens: int,
  /// Unix timestamp in milliseconds.
  timestamp: float,
}

/// Category tabs for the AI panel — each shows a different region
/// of the three-region layout.
type aiCategory =
  /// Main conversation view with the message stream and input area.
  | Conversation
  /// System prompt editor — shows the assembled context and allows overrides.
  | SystemPrompt
  /// Provider management — enable/disable, priority, model selection, status.
  | Providers
  /// Context inspector — shows what repo data, panel state, and VoiceTags
  /// are included in the system prompt.
  | Context

/// Root state for the AI panel module.
type aiState = {
  /// Per-provider configurations (user's key ring).
  providers: array<aiProviderConfig>,
  /// Runtime status for each provider (health check results, quota state).
  providerStatuses: array<(aiProviderId, aiProviderStatus)>,
  /// Conversation history (user + assistant messages).
  messages: array<aiMessage>,
  /// Current input text in the message composer.
  inputText: string,
  /// Assembled system prompt (repo context + panel state + constraints).
  systemPrompt: string,
  /// Auto-generated context from repo SCM files, active panels, VoiceTags.
  autoContext: string,
  /// Whether a message is currently being sent/awaited.
  loading: bool,
  /// Active category tab in the AI panel.
  activeCategory: aiCategory,
  /// Broadcast mode: send to top N enabled providers simultaneously,
  /// showing all responses side-by-side.
  broadcastMode: bool,
  /// Last error from a failed provider call.
  error: option<string>,
  /// Cumulative input tokens across all providers this session.
  totalInputTokens: int,
  /// Cumulative output tokens across all providers this session.
  totalOutputTokens: int,
}
