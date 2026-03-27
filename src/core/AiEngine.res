// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL AI Engine — pure computation for the multi-provider AI panel.
///
/// All functions are pure (no side effects, no API calls). Provides:
///   - Default state initialisation
///   - Provider label, colour, and icon helpers
///   - Message formatting and token display
///   - Precedence sorting and provider selection
///   - JSON parsing for Tauri command responses

open AiModel

/// Human-readable label for a provider ID.
let providerLabel = (id: aiProviderId): string => {
  switch id {
  | Anthropic => "Anthropic"
  | Google => "Google"
  | Mistral => "Mistral"
  | OpenAI => "OpenAI"
  | Local => "Local"
  }
}

/// Short label for provider (used in message attribution).
let providerShortLabel = (id: aiProviderId): string => {
  switch id {
  | Anthropic => "Claude"
  | Google => "Gemini"
  | Mistral => "Mistral"
  | OpenAI => "GPT"
  | Local => "Ollama"
  }
}

/// Tailwind CSS colour class for a provider (conversation bubble borders).
let providerColour = (id: aiProviderId): string => {
  switch id {
  | Anthropic => "border-orange-500"
  | Google => "border-blue-500"
  | Mistral => "border-yellow-500"
  | OpenAI => "border-green-500"
  | Local => "border-purple-500"
  }
}

/// Background accent colour for provider badges.
let providerBgColour = (id: aiProviderId): string => {
  switch id {
  | Anthropic => "bg-orange-500/20 text-orange-300"
  | Google => "bg-blue-500/20 text-blue-300"
  | Mistral => "bg-yellow-500/20 text-yellow-300"
  | OpenAI => "bg-green-500/20 text-green-300"
  | Local => "bg-purple-500/20 text-purple-300"
  }
}

/// Icon identifier for a provider (for the provider selector).
let providerIcon = (id: aiProviderId): string => {
  switch id {
  | Anthropic => "brain"
  | Google => "sparkles"
  | Mistral => "wind"
  | OpenAI => "cpu"
  | Local => "server"
  }
}

/// Human-readable label for a provider status.
let statusLabel = (status: aiProviderStatus): string => {
  switch status {
  | Ready => "Ready"
  | Checking => "Checking..."
  | QuotaExhausted => "Quota Exhausted"
  | AiProviderError(msg) => `Error: ${msg}`
  | Disabled => "Disabled"
  | NoKey => "No API Key"
  }
}

/// CSS class for status indicator dot.
let statusDotClass = (status: aiProviderStatus): string => {
  switch status {
  | Ready => "bg-green-400"
  | Checking => "bg-yellow-400 animate-pulse"
  | QuotaExhausted => "bg-red-400"
  | AiProviderError(_) => "bg-red-400"
  | Disabled => "bg-gray-600"
  | NoKey => "bg-gray-500"
  }
}

/// Human-readable label for a category tab.
let categoryLabel = (cat: aiCategory): string => {
  switch cat {
  | Conversation => "Conversation"
  | SystemPrompt => "System Prompt"
  | Providers => "Providers"
  | Context => "Context"
  }
}

/// All category tabs in display order.
let allCategories: array<aiCategory> = [Conversation, SystemPrompt, Providers, Context]

/// Human-readable label for a message role.
let roleLabel = (role: aiRole): string => {
  switch role {
  | User => "You"
  | Assistant => "AI"
  | System => "System"
  }
}

/// Format a token count for display (e.g., "1.2k", "45").
let formatTokens = (count: int): string => {
  if count >= 1000 {
    let k = Int.toFloat(count) /. 1000.0
    Float.toFixed(k, ~digits=1) ++ "k"
  } else {
    Int.toString(count)
  }
}

/// Sort providers by priority (lowest number first = highest priority).
let sortByPriority = (providers: array<aiProviderConfig>): array<aiProviderConfig> => {
  let sorted = Array.copy(providers)
  sorted->Array.sort((a, b) => Int.compare(a.priority, b.priority))
  sorted
}

/// Select the best available provider: highest priority, enabled, non-exhausted.
let selectProvider = (providers: array<aiProviderConfig>): option<aiProviderConfig> => {
  let sorted = sortByPriority(providers)
  sorted->Array.find(p => p.enabled && !p.quotaExhausted)
}

/// Get the status for a provider from the status array.
let getProviderStatus = (
  statuses: array<(aiProviderId, aiProviderStatus)>,
  id: aiProviderId,
): aiProviderStatus => {
  switch statuses->Array.find(((pid, _)) => pid === id) {
  | Some((_, status)) => status
  | None => NoKey
  }
}

/// Serialise a provider ID to a string for the Tauri command bridge.
let providerIdToString = (id: aiProviderId): string => {
  switch id {
  | Anthropic => "anthropic"
  | Google => "google"
  | Mistral => "mistral"
  | OpenAI => "openai"
  | Local => "local"
  }
}

/// Parse a provider ID from a string.
let providerIdFromString = (s: string): option<aiProviderId> => {
  switch String.toLowerCase(s) {
  | "anthropic" => Some(Anthropic)
  | "google" => Some(Google)
  | "mistral" => Some(Mistral)
  | "openai" => Some(OpenAI)
  | "local" => Some(Local)
  | _ => None
  }
}

/// Default provider configurations. Matches the Rust `AiProvidersFile::defaults()`.
let defaultProviders: array<aiProviderConfig> = [
  {
    id: Anthropic,
    apiKey: None,
    envVar: "ANTHROPIC_API_KEY",
    enabled: true,
    priority: 1,
    selectedModel: "claude-opus-4-6",
    quotaExhausted: false,
  },
  {
    id: Google,
    apiKey: None,
    envVar: "GOOGLE_AI_KEY",
    enabled: true,
    priority: 2,
    selectedModel: "gemini-2.5-pro",
    quotaExhausted: false,
  },
  {
    id: Mistral,
    apiKey: None,
    envVar: "MISTRAL_API_KEY",
    enabled: false,
    priority: 3,
    selectedModel: "mistral-large-latest",
    quotaExhausted: false,
  },
  {
    id: OpenAI,
    apiKey: None,
    envVar: "OPENAI_API_KEY",
    enabled: false,
    priority: 4,
    selectedModel: "gpt-4o",
    quotaExhausted: false,
  },
  {
    id: Local,
    apiKey: None,
    envVar: "",
    enabled: false,
    priority: 5,
    selectedModel: "llama3",
    quotaExhausted: false,
  },
]

/// Default initial state for the AI panel.
let defaultState: aiState = {
  providers: defaultProviders,
  providerStatuses: [
    (Anthropic, NoKey),
    (Google, NoKey),
    (Mistral, Disabled),
    (OpenAI, Disabled),
    (Local, Disabled),
  ],
  messages: [],
  inputText: "",
  systemPrompt: "You are an AI assistant embedded in PanLL, a neurosymbolic development environment. You have access to the loaded repository's context, constraints, and panel state.",
  autoContext: "",
  loading: false,
  activeCategory: Conversation,
  broadcastMode: false,
  error: None,
  totalInputTokens: 0,
  totalOutputTokens: 0,
  streaming: {
    active: false,
    currentText: "",
    pendingToolCalls: [],
    completedToolResults: [],
  },
}

/// Available models for each provider.
let providerModels = (id: aiProviderId): array<string> => {
  switch id {
  | Anthropic => ["claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5-20251001"]
  | Google => ["gemini-2.5-pro", "gemini-2.5-flash"]
  | Mistral => ["mistral-large-latest", "mistral-medium-latest", "mistral-small-latest"]
  | OpenAI => ["gpt-4o", "o3", "gpt-4o-mini"]
  | Local => ["llama3", "mistral", "codellama", "phi3"]
  }
}

/// Tea_Json decoder for a message response.
/// Returns Error("quota_exhausted") if the quota_exhausted field is true.
let messageResponseDecoder: Tea_Json.decoder<aiMessage> = json => {
  open Decoders
  open Tea_Json
  let inner = map6(
    (providerStr, content, model, inputTokens, outputTokens, quotaExhausted) => (
      providerStr,
      content,
      model,
      inputTokens,
      outputTokens,
      quotaExhausted,
    ),
    stringField("provider"),
    stringField("content"),
    stringField("model"),
    intField("input_tokens"),
    intField("output_tokens"),
    boolField("quota_exhausted"),
  )
  switch inner(json) {
  | Ok((_, _, _, _, _, true)) => Error(Failure("quota_exhausted", json))
  | Ok((providerStr, content, model, inputTokens, outputTokens, _)) =>
    Ok(
      (
        {
          role: Assistant,
          content,
          provider: providerIdFromString(providerStr),
          model: Some(model),
          inputTokens,
          outputTokens,
          timestamp: Date.now(),
        }: aiMessage
      ),
    )
  | Error(e) => Error(e)
  }
}

/// Parse a SendMessageResponse from the Tauri backend JSON.
let parseMessageResponse = (jsonStr: string): result<aiMessage, string> =>
  Decoders.decode(messageResponseDecoder, jsonStr)

/// Tea_Json decoder for a single AI provider config.
/// Validates the provider ID, skipping unknown providers.
let providerConfigDecoder: Tea_Json.decoder<aiProviderConfig> = json => {
  open Decoders
  open Tea_Json
  let inner = map5(
    (idStr, envVar, enabled, priority, model) => (idStr, envVar, enabled, priority, model),
    stringField("id"),
    stringField("env_var"),
    boolField("enabled"),
    intField("priority"),
    stringField("model"),
  )
  switch inner(json) {
  | Ok((idStr, envVar, enabled, priority, model)) =>
    switch providerIdFromString(idStr) {
    | Some(id) =>
      Ok(
        (
          {
            id,
            apiKey: None,
            envVar,
            enabled,
            priority,
            selectedModel: model,
            quotaExhausted: false,
          }: aiProviderConfig
        ),
      )
    | None => Error(Failure(`Unknown provider id: ${idStr}`, json))
    }
  | Error(e) => Error(e)
  }
}

/// Tea_Json decoder for the provider state response envelope.
let providerStateDecoder: Tea_Json.decoder<array<aiProviderConfig>> = Tea_Json.field(
  "providers",
  Decoders.lenientArray(providerConfigDecoder),
)

/// Parse provider config state from the Tauri backend JSON.
let parseProviderState = (jsonStr: string): result<array<aiProviderConfig>, string> =>
  Decoders.decode(providerStateDecoder, jsonStr)

// ---------------------------------------------------------------------------
// Streaming helpers — parse stream chunks and manage streaming state
// ---------------------------------------------------------------------------

/// Parse a stream chunk JSON from a Tauri event payload.
/// Returns `(chunkType, optionalData)` where chunkType is one of:
/// "TextDelta", "ToolUseStart", "ToolUseDelta", "ToolUseEnd", "Complete", "Error".
let parseStreamChunk = (json: string): result<(string, option<JSON.t>), string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let chunkType = switch Dict.get(obj, "type") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | String(s) => s
          | _ => "unknown"
          }
        | None => "unknown"
        }
        let data = Dict.get(obj, "data")
        Ok((chunkType, data))
      }
    | _ => Error("Stream chunk is not an object: " ++ json)
    }
  } catch {
  | _ => Error("Failed to parse stream chunk: " ++ json)
  }
}

/// Create default streaming state (inactive, no accumulated data).
let defaultStreamingState = (): streamingState => {
  active: false,
  currentText: "",
  pendingToolCalls: [],
  completedToolResults: [],
}

/// Append a text delta to the streaming state's accumulated text.
let appendTextDelta = (state: streamingState, text: string): streamingState => {
  ...state,
  currentText: state.currentText ++ text,
}

/// Start a new tool call (ToolUseStart received).
let startToolCall = (state: streamingState, id: string, name: string): streamingState => {
  let newCall: toolCallState = {
    id,
    name,
    accumulatedInput: "",
    status: Accumulating,
  }
  {
    ...state,
    pendingToolCalls: Array.concat(state.pendingToolCalls, [newCall]),
  }
}

/// Append JSON input to the most recent pending tool call (ToolUseDelta).
let appendToolInput = (state: streamingState, partialJson: string): streamingState => {
  let len = Array.length(state.pendingToolCalls)
  if len === 0 {
    state
  } else {
    let calls = Array.copy(state.pendingToolCalls)
    switch calls[len - 1] {
    | Some(last) =>
      last.accumulatedInput = last.accumulatedInput ++ partialJson
      {...state, pendingToolCalls: calls}
    | None => state
    }
  }
}

/// Info needed to dispatch a tool call to BoJ.
type toolCallDispatchInfo = {
  /// The tool_use_id from Claude.
  callId: string,
  /// The tool name (maps to a BoJ cartridge tool).
  callName: string,
  /// The accumulated JSON input for the tool.
  callInput: string,
}

/// Mark the most recent pending tool call as ready for execution (ToolUseEnd).
/// Returns the tool call info for dispatch, if any.
let finalizeToolCall = (state: streamingState): (streamingState, option<toolCallDispatchInfo>) => {
  let len = Array.length(state.pendingToolCalls)
  if len === 0 {
    (state, None)
  } else {
    let calls = Array.copy(state.pendingToolCalls)
    switch calls[len - 1] {
    | Some(last) =>
      last.status = Executing
      (
        {...state, pendingToolCalls: calls},
        Some({callId: last.id, callName: last.name, callInput: last.accumulatedInput}),
      )
    | None => (state, None)
    }
  }
}

/// Check if all pending tool calls have completed (Completed or Failed).
let allToolCallsComplete = (state: streamingState): bool => {
  Array.every(state.pendingToolCalls, tc =>
    switch tc.status {
    | Completed(_) | Failed(_) => true
    | Accumulating | Executing => false
    }
  )
}
