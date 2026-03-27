// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL AI Commands — Backend command wrappers for the multi-provider AI panel.
///
/// Each function wraps a backend `invoke` call in a `Tea_Cmd.call`, converting
/// the Promise-based IPC into the TEA command model. Results arrive as
/// JSON strings; parsing happens in the Update layer, not here.
///
/// Pattern: `commandName(args..., tagger) => Tea_Cmd.t<'msg>`
/// where `tagger: result<string, string> => 'msg` wraps the result into
/// the panel's message type.

let invoke = RuntimeBridge.invoke

/// Send a message to the AI provider. The backend selects the highest-priority
/// enabled provider (or uses the specified one) and returns the response.
let sendMessage = (
  content: string,
  history: array<JSON.t>,
  systemPrompt: string,
  providerId: option<string>,
  broadcast: bool,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "ai_send_message",
      {
        "request": {
          "content": content,
          "history": history,
          "system_prompt": systemPrompt,
          "provider_id": providerId,
          "broadcast": broadcast,
        },
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to send AI message")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check if a provider is reachable and properly authenticated.
let checkProvider = (providerId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("ai_check_provider", {"providerId": providerId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to check provider: ${providerId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Change the selected model for a provider.
let setModel = (
  providerId: string,
  model: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ai_set_model", {"providerId": providerId, "model": model})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to set model for ${providerId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Change a provider's precedence ranking.
let setPriority = (
  providerId: string,
  priority: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ai_set_priority", {"providerId": providerId, "priority": priority})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to set priority for ${providerId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Enable or disable a provider (mute/unmute without losing the API key).
let toggleProvider = (providerId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("ai_toggle_provider", {"providerId": providerId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to toggle provider: ${providerId}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Clear the conversation history.
let clearHistory = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ai_clear_history", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to clear history")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Build the system prompt context from a repository path.
let buildContext = (repoPath: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ai_build_context", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to build context for ${repoPath}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fire-and-forget streaming message. Results arrive via backend events on
/// `ai:stream-chunk`. This command returns immediately with "streaming_started".
///
/// The streaming provider emits StreamChunk events that the frontend receives
/// via GossamerEvents.onAiStreamChunk and feeds into the TEA update loop.
///
/// @param content — the user's message text
/// @param history — conversation history (JSON-serialised AiMessages)
/// @param systemPrompt — assembled system prompt
/// @param providerId — explicit provider or None for auto-select
/// @param tools — tool definitions for Claude's tool_use (or None)
/// @param toolResults — results from previously executed tool calls (or None)
/// @param tagger — TEA message tagger for the fire-and-forget acknowledgement
let sendMessageStreaming = (
  content: string,
  history: array<JSON.t>,
  systemPrompt: string,
  providerId: option<string>,
  tools: option<JSON.t>,
  toolResults: option<JSON.t>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "ai_send_message_streaming",
      {
        "request": {
          "content": content,
          "history": history,
          "system_prompt": systemPrompt,
          "provider_id": providerId,
          "tools": tools,
          "tool_results": toolResults,
        },
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to start streaming")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load the current provider configuration state from disk.
let getState = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("ai_get_state", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load AI provider state")))
      Promise.resolve()
    })
    ->ignore
  })
}
