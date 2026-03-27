// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for AI panel — multi-provider neural interface.
///
/// Handles message sending to AI providers, provider management (enable/disable,
/// model selection, priority), system prompt context building, and conversation
/// state. Provider precedence with automatic 429 fallthrough ensures continuous
/// service even when a provider's quota is exhausted.

open Model
open Msg

let updateAi = (model: model, msg: aiMsg): (model, Tea_Cmd.t<msg>) => {
  let ai = model.ai
  switch msg {
  | SendMessage => if ai.inputText === "" {
      (model, Tea_Cmd.none)
    } else {
      // Create the user message.
      let userMsg: aiMessage = {
        role: User,
        content: ai.inputText,
        provider: None,
        model: None,
        inputTokens: 0,
        outputTokens: 0,
        timestamp: Date.now(),
      }
      let newMessages = Array.concat(ai.messages, [userMsg])
      // Select provider by priority.
      let selectedProvider = AiEngine.selectProvider(ai.providers)
      let providerId = switch selectedProvider {
      | Some(p) => Some(AiEngine.providerIdToString(p.id))
      | None => None
      }
      // Build history as a simple JSON array for the Tauri backend.
      // We pass an empty array; the backend rebuilds from the request.
      let history: array<JSON.t> = []
      (
        {
          ...model,
          ai: {
            ...ai,
            messages: newMessages,
            inputText: "",
            loading: true,
            error: None,
          },
        },
        Tea_Cmd.batch(list{
          AiCmd.sendMessage(
            userMsg.content,
            history,
            ai.systemPrompt,
            providerId,
            ai.broadcastMode,
            result => Ai(MessageReceived(result)),
          ),
          TypeLLService.checkCodeTypes(userMsg.content, "prompt", result => Ai(
            TypeCheckResult(result),
          )),
        }),
      )
    }
  | MessageReceived(result) =>
    switch result {
    | Ok(jsonStr) => switch AiEngine.parseMessageResponse(jsonStr) {
      | Ok(aiMessage) => (
          {
            ...model,
            ai: {
              ...ai,
              messages: Array.concat(ai.messages, [aiMessage]),
              loading: false,
              error: None,
              totalInputTokens: ai.totalInputTokens + aiMessage.inputTokens,
              totalOutputTokens: ai.totalOutputTokens + aiMessage.outputTokens,
            },
          },
          Tea_Cmd.none,
        )
      | Error("quota_exhausted") => {
          // Mark provider as exhausted and auto-retry with next provider.
          let exhaustedProvider = AiEngine.selectProvider(ai.providers)
          switch exhaustedProvider {
          | Some(p) => {
              let newProviders = ai.providers->Array.map(pc =>
                if pc.id === p.id {
                  {...pc, quotaExhausted: true}
                } else {
                  pc
                }
              )
              let newStatuses = ai.providerStatuses->Array.map(((id, status)) =>
                if id === p.id {
                  (id, (QuotaExhausted: aiProviderStatus))
                } else {
                  (id, status)
                }
              )
              (
                {
                  ...model,
                  ai: {
                    ...ai,
                    providers: newProviders,
                    providerStatuses: newStatuses,
                    loading: false,
                    error: Some(
                      `${AiEngine.providerShortLabel(
                          p.id,
                        )} quota exhausted — falling through to next provider`,
                    ),
                  },
                },
                Tea_Cmd.none,
              )
            }
          | None => (
              {...model, ai: {...ai, loading: false, error: Some("All providers exhausted")}},
              Tea_Cmd.none,
            )
          }
        }
      | Error(e) => ({...model, ai: {...ai, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, ai: {...ai, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetAiInput(text) => ({...model, ai: {...ai, inputText: text}}, Tea_Cmd.none)
  | SetAiCategory(cat) => ({...model, ai: {...ai, activeCategory: cat}}, Tea_Cmd.none)
  | ToggleBroadcast => ({...model, ai: {...ai, broadcastMode: !ai.broadcastMode}}, Tea_Cmd.none)
  | CheckProvider(id) => {
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id {
          (pid, (Checking: aiProviderStatus))
        } else {
          (pid, status)
        }
      )
      (
        {...model, ai: {...ai, providerStatuses: newStatuses}},
        AiCmd.checkProvider(AiEngine.providerIdToString(id), result => Ai(
          ProviderChecked(id, result),
        )),
      )
    }
  | ProviderChecked(id, result) => {
      let newStatus = switch result {
      | Ok(jsonStr) => switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(parsed) =>
          switch JSON.Classify.classify(parsed) {
          | Object(obj) =>
            switch Dict.get(obj, "status") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | String("ready") => (Ready: aiProviderStatus)
              | String("no_key") => NoKey
              | String("disabled") => Disabled
              | String("error") => {
                  let detail = switch Dict.get(obj, "detail") {
                  | Some(d) =>
                    switch JSON.Classify.classify(d) {
                    | String(s) => s
                    | _ => "Unknown error"
                    }
                  | None => "Unknown error"
                  }
                  AiProviderError(detail)
                }
              | _ => AiProviderError("Unknown status")
              }
            | None => AiProviderError("Missing status")
            }
          | _ => AiProviderError("Invalid response")
          }

        | None => AiProviderError("Parse error")
        }
      | Error(e) => AiProviderError(e)
      }
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id {
          (pid, newStatus)
        } else {
          (pid, status)
        }
      )
      ({...model, ai: {...ai, providerStatuses: newStatuses}}, Tea_Cmd.none)
    }
  | SetAiModel(id, newModel) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id {
          {...p, selectedModel: newModel}
        } else {
          p
        }
      )
      (
        {...model, ai: {...ai, providers: newProviders}},
        AiCmd.setModel(AiEngine.providerIdToString(id), newModel, result => Ai(ModelSet(result))),
      )
    }
  | ModelSet(_result) => (model, Tea_Cmd.none)
  | SetAiPriority(id, priority) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id {
          {...p, priority}
        } else {
          p
        }
      )
      (
        {...model, ai: {...ai, providers: newProviders}},
        AiCmd.setPriority(AiEngine.providerIdToString(id), priority, result => Ai(
          PrioritySet(result),
        )),
      )
    }
  | PrioritySet(_result) => (model, Tea_Cmd.none)
  | ToggleAiProvider(id) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id {
          {...p, enabled: !p.enabled}
        } else {
          p
        }
      )
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id {
          let provider = newProviders->Array.find(p => p.id === id)
          let isEnabled = switch provider {
          | Some(p) => p.enabled
          | None => false
          }
          (pid, isEnabled ? (Ready: aiProviderStatus) : Disabled)
        } else {
          (pid, status)
        }
      )
      (
        {...model, ai: {...ai, providers: newProviders, providerStatuses: newStatuses}},
        AiCmd.toggleProvider(AiEngine.providerIdToString(id), result => Ai(
          ProviderToggled(result),
        )),
      )
    }
  | ProviderToggled(_result) => (model, Tea_Cmd.none)
  | ClearAiHistory => (
      {
        ...model,
        ai: {
          ...ai,
          messages: [],
          totalInputTokens: 0,
          totalOutputTokens: 0,
          error: None,
        },
      },
      AiCmd.clearHistory(result => Ai(HistoryCleared(result))),
    )
  | HistoryCleared(_result) => (model, Tea_Cmd.none)
  | BuildContext(repoPath) => (
      model,
      AiCmd.buildContext(repoPath, result => Ai(ContextBuilt(result))),
    )
  | ContextBuilt(result) =>
    switch result {
    | Ok(jsonStr) => switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(parsed) =>
        switch JSON.Classify.classify(parsed) {
        | Object(obj) =>
          switch Dict.get(obj, "context") {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(ctx) => (
                {
                  ...model,
                  ai: {
                    ...ai,
                    autoContext: ctx,
                    systemPrompt: ai.systemPrompt ++ "\n\n" ++ ctx,
                  },
                },
                Tea_Cmd.none,
              )
            | _ => (model, Tea_Cmd.none)
            }
          | None => (model, Tea_Cmd.none)
          }
        | _ => (model, Tea_Cmd.none)
        }

      | None => (model, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | LoadProviderState => (model, AiCmd.getState(result => Ai(ProviderStateLoaded(result))))
  | ProviderStateLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch AiEngine.parseProviderState(jsonStr) {
      | Ok(providers) => ({...model, ai: {...ai, providers}}, Tea_Cmd.none)
      | Error(_) => (model, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | SetSystemPrompt(prompt) => ({...model, ai: {...ai, systemPrompt: prompt}}, Tea_Cmd.none)
  | MarkQuotaExhausted(id) => {
      let newProviders = ai.providers->Array.map(p =>
        if p.id === id {
          {...p, quotaExhausted: true}
        } else {
          p
        }
      )
      let newStatuses = ai.providerStatuses->Array.map(((pid, status)) =>
        if pid === id {
          (pid, (QuotaExhausted: aiProviderStatus))
        } else {
          (pid, status)
        }
      )
      (
        {...model, ai: {...ai, providers: newProviders, providerStatuses: newStatuses}},
        Tea_Cmd.none,
      )
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "ai", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)

  // =========================================================================
  // Streaming + tool_use handlers (Claude Code integration)
  // =========================================================================

  | StreamingStarted(Ok(
      _,
    )) => // Streaming acknowledged — state already set to active in SendMessage handler.
    (model, Tea_Cmd.none)
  | StreamingStarted(Error(e)) => (
      {
        ...model,
        ai: {...ai, loading: false, error: Some(e), streaming: {...ai.streaming, active: false}},
      },
      Tea_Cmd.none,
    )

  | AiStreamChunkReceived(json) => switch AiEngine.parseStreamChunk(json) {
    | Ok(("TextDelta", Some(data))) => {
        let text = switch JSON.Classify.classify(data) {
        | String(s) => s
        | _ => ""
        }
        let newStreaming = AiEngine.appendTextDelta(ai.streaming, text)
        // Emit a neuralToken to Panel-N for real-time streaming display.
        let tokenId = "stream-" ++ Int.toString(Array.length(model.paneN.tokens))
        let token: neuralToken = {
          id: tokenId,
          content: text,
          timestamp: Date.now(),
          confidence: 0.95,
          validated: false,
          source: NeuralInference,
          category: Observation,
          emittedDuring: model.paneN.agency.phase,
          causedBy: model.paneN.activeCausalChain,
          proofHash: None,
        }
        (
          {...model, ai: {...ai, streaming: newStreaming}},
          Tea_Cmd.batch(list{
            Tea_Cmd.call(callbacks => {
              callbacks.enqueue(PaneN(ReceiveToken(token)))
            }),
          }),
        )
      }
    | Ok(("ToolUseStart", Some(data))) => {
        // Parse {id, name} from the data object.
        let (id, name) = switch JSON.Classify.classify(data) {
        | Object(obj) => {
            let id = switch Dict.get(obj, "id") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | String(s) => s
              | _ => ""
              }
            | None => ""
            }
            let name = switch Dict.get(obj, "name") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | String(s) => s
              | _ => ""
              }
            | None => ""
            }
            (id, name)
          }
        | _ => ("", "")
        }
        let newStreaming = AiEngine.startToolCall(ai.streaming, id, name)
        ({...model, ai: {...ai, streaming: newStreaming}}, Tea_Cmd.none)
      }
    | Ok(("ToolUseDelta", Some(data))) => {
        let partialJson = switch JSON.Classify.classify(data) {
        | String(s) => s
        | _ => ""
        }
        let newStreaming = AiEngine.appendToolInput(ai.streaming, partialJson)
        ({...model, ai: {...ai, streaming: newStreaming}}, Tea_Cmd.none)
      }
    | Ok(("ToolUseEnd", _)) => {
        let (newStreaming, maybeCall) = AiEngine.finalizeToolCall(ai.streaming)
        let cmd = switch maybeCall {
        | Some(call) =>
          // Dispatch tool call to BoJ via BojLiveCmd.
          Tea_Cmd.call(callbacks => {
            callbacks.enqueue(
              Ai(
                AiToolCallRequested({id: call.callId, name: call.callName, input: call.callInput}),
              ),
            )
          })
        | None => Tea_Cmd.none
        }
        ({...model, ai: {...ai, streaming: newStreaming}}, cmd)
      }
    | Ok(("Complete", Some(data))) => {
        // Parse {input_tokens, output_tokens} from data.
        let (inputTokens, outputTokens) = switch JSON.Classify.classify(data) {
        | Object(obj) => {
            let inp = switch Dict.get(obj, "input_tokens") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | Number(n) => Float.toInt(n)
              | _ => 0
              }
            | None => 0
            }
            let out = switch Dict.get(obj, "output_tokens") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | Number(n) => Float.toInt(n)
              | _ => 0
              }
            | None => 0
            }
            (inp, out)
          }
        | _ => (0, 0)
        }
        // Finalize: add the full response as an AiMessage to history.
        let responseMsg: aiMessage = {
          role: Assistant,
          content: ai.streaming.currentText,
          provider: Some(Anthropic),
          model: Some("claude-opus-4-6"),
          inputTokens,
          outputTokens,
          timestamp: Date.now(),
        }
        let newMessages = Array.concat(ai.messages, [responseMsg])
        (
          {
            ...model,
            ai: {
              ...ai,
              messages: newMessages,
              loading: false,
              error: None,
              totalInputTokens: ai.totalInputTokens + inputTokens,
              totalOutputTokens: ai.totalOutputTokens + outputTokens,
              streaming: AiEngine.defaultStreamingState(),
            },
          },
          Tea_Cmd.none,
        )
      }
    | Ok(("Error", Some(data))) => {
        let errorMsg = switch JSON.Classify.classify(data) {
        | String(s) => s
        | _ => "Unknown streaming error"
        }
        (
          {
            ...model,
            ai: {
              ...ai,
              loading: false,
              error: Some(errorMsg),
              streaming: AiEngine.defaultStreamingState(),
            },
          },
          Tea_Cmd.none,
        )
      }
    | Ok(_) | Error(_) => // Unknown chunk type or parse error — ignore gracefully.
      (model, Tea_Cmd.none)
    }

  | AiToolCallRequested({id, name, input}) => {
      // Route the tool call through BoJ Live (MCP cartridge runtime).
      // The cartridge name is derived from the tool name prefix (e.g. "database_query" → "database").
      let cartridgeName = switch String.split(name, "_")[0] {
      | Some(prefix) => prefix
      | None => name
      }
      (
        model,
        BojLiveCmd.invokeCartridge(cartridgeName, name, input, result => Ai(
          AiToolCallResult({toolUseId: id, result}),
        )),
      )
    }

  | AiToolCallResult({toolUseId, result}) => {
      let (content, isError) = switch result {
      | Ok(c) => (c, false)
      | Error(e) => (e, true)
      }
      // Update the tool call status and add to completed results.
      let newPendingCalls = ai.streaming.pendingToolCalls->Array.map(tc =>
        if tc.id === toolUseId {
          tc.status = isError ? Failed(content) : Completed(content)
          tc
        } else {
          tc
        }
      )
      let newCompleted = Array.concat(
        ai.streaming.completedToolResults,
        [({id: toolUseId, content, isError}: completedToolResult)],
      )
      let newStreaming = {
        ...ai.streaming,
        pendingToolCalls: newPendingCalls,
        completedToolResults: newCompleted,
      }
      let updatedModel = {...model, ai: {...ai, streaming: newStreaming}}

      // Check if all tool calls are complete — if so, continue the conversation.
      if AiEngine.allToolCallsComplete(newStreaming) {
        (
          updatedModel,
          Tea_Cmd.call(callbacks => {
            callbacks.enqueue(Ai(AiContinueAfterToolUse))
          }),
        )
      } else {
        (updatedModel, Tea_Cmd.none)
      }
    }

  | AiContinueAfterToolUse => {
      // Send a new streaming request with the tool results appended.
      let toolResultsJson =
        ai.streaming.completedToolResults->Array.map(tr =>
          JSON.Encode.object(
            Dict.fromArray([
              ("tool_use_id", JSON.Encode.string(tr.id)),
              ("content", JSON.Encode.string(tr.content)),
              ("is_error", JSON.Encode.bool(tr.isError)),
            ]),
          )
        )
      let selectedProvider = AiEngine.selectProvider(ai.providers)
      let providerId = switch selectedProvider {
      | Some(p) => Some(AiEngine.providerIdToString(p.id))
      | None => None
      }
      // Reset streaming state for the continuation turn.
      let newStreaming: streamingState = {
        active: true,
        currentText: "",
        pendingToolCalls: [],
        completedToolResults: [],
      }
      (
        {...model, ai: {...ai, streaming: newStreaming}},
        AiCmd.sendMessageStreaming(
          "",
          [],
          ai.systemPrompt,
          providerId,
          None,
          Some(JSON.Encode.array(toolResultsJson)),
          result => Ai(StreamingStarted(result)),
        ),
      )
    }
  }
}
