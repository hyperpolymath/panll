// SPDX-License-Identifier: MPL-2.0

/// AI panel messages -- multi-provider neural interface for sending messages,
/// managing providers, building context, and controlling the conversation.

open Model

type aiMsg =
  /// Send a message to the current provider (or broadcast to all enabled).
  | SendMessage
  /// Message response received from a provider.
  | MessageReceived(result<string, string>)
  /// Update the input text field.
  | SetAiInput(string)
  /// Switch the active category tab.
  | SetAiCategory(aiCategory)
  /// Toggle broadcast mode (send to multiple providers simultaneously).
  | ToggleBroadcast
  /// Check provider health/auth status.
  | CheckProvider(aiProviderId)
  /// Provider health check result.
  | ProviderChecked(aiProviderId, result<string, string>)
  /// Change the selected model for a provider.
  | SetAiModel(aiProviderId, string)
  /// Model change confirmed.
  | ModelSet(result<string, string>)
  /// Change a provider's precedence ranking.
  | SetAiPriority(aiProviderId, int)
  /// Priority change confirmed.
  | PrioritySet(result<string, string>)
  /// Enable or disable a provider (mute/unmute).
  | ToggleAiProvider(aiProviderId)
  /// Provider toggle confirmed.
  | ProviderToggled(result<string, string>)
  /// Clear the conversation history.
  | ClearAiHistory
  /// History cleared confirmed.
  | HistoryCleared(result<string, string>)
  /// Build context from a loaded repo.
  | BuildContext(string)
  /// Context built.
  | ContextBuilt(result<string, string>)
  /// Load provider state from disk.
  | LoadProviderState
  /// Provider state loaded.
  | ProviderStateLoaded(result<string, string>)
  /// Update the system prompt override.
  | SetSystemPrompt(string)
  /// Mark a provider as quota-exhausted (429 received).
  | MarkQuotaExhausted(aiProviderId)
  /// TypeLL cross-panel type check result for prompt types.
  | TypeCheckResult(result<string, string>)
  // ---------------------------------------------------------------------------
  // Streaming + tool_use messages (Claude Code integration)
  // ---------------------------------------------------------------------------
  /// A stream chunk arrived from the Gossamer `ai:stream-chunk` event.
  /// Payload is the raw JSON string from the StreamChunk enum.
  | AiStreamChunkReceived(string)
  /// Streaming session started (fire-and-forget acknowledgement).
  | StreamingStarted(result<string, string>)
  /// A tool call has been fully accumulated and needs execution via BoJ.
  /// Dispatched when a ToolUseEnd chunk completes a pending tool call.
  | AiToolCallRequested({id: string, name: string, input: string})
  /// A tool call result arrived from BoJ cartridge execution.
  | AiToolCallResult({toolUseId: string, result: result<string, string>})
  /// All pending tool calls are complete -- continue the conversation
  /// by sending a new streaming request with the tool results.
  | AiContinueAfterToolUse
