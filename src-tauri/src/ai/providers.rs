// SPDX-License-Identifier: PMPL-1.0-or-later

//! AI Provider HTTP Clients — per-provider message routing.
//!
//! Each provider implements `send_message()` with the appropriate:
//!   - Endpoint URL and HTTP method
//!   - Authentication header scheme
//!   - Request body format (Anthropic Messages, OpenAI Chat Completions, etc.)
//!   - Response parsing to extract content and token usage
//!
//! Provider selection is by priority: pick the highest-priority enabled,
//! non-exhausted provider. A 429 response sets `quota_exhausted` for
//! automatic fallthrough to the next provider.

use reqwest::Client;
use serde_json::{json, Value};
use std::env;
use std::time::Duration;

use super::types::*;

/// HTTP client timeout for AI provider requests.
const REQUEST_TIMEOUT_SECS: u64 = 120;

/// Resolve the API key for a provider: explicit key > env var > error.
fn resolve_api_key(config: &ProviderConfig) -> Result<String, String> {
    // Explicit key in config takes precedence.
    if let Some(key) = &config.api_key {
        if !key.is_empty() {
            return Ok(key.clone());
        }
    }
    // Fall back to environment variable.
    if !config.env_var.is_empty() {
        if let Ok(key) = env::var(&config.env_var) {
            if !key.is_empty() {
                return Ok(key);
            }
        }
    }
    Err(format!(
        "No API key for {:?}: set {} or provide key in config",
        config.id, config.env_var
    ))
}

/// Build a reqwest client with the standard timeout.
fn build_client() -> Result<Client, String> {
    Client::builder()
        .timeout(Duration::from_secs(REQUEST_TIMEOUT_SECS))
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))
}

/// Send a message via the Anthropic Messages API.
///
/// Endpoint: `POST https://api.anthropic.com/v1/messages`
/// Auth: `x-api-key` header
/// Body: `{ model, max_tokens, system, messages }`
pub async fn send_anthropic(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
) -> Result<SendMessageResponse, String> {
    let api_key = resolve_api_key(config)?;
    let client = build_client()?;

    // Build conversation history in Anthropic format.
    let mut api_messages: Vec<Value> = messages
        .iter()
        .filter(|m| m.role != MessageRole::System)
        .map(|m| {
            json!({
                "role": match m.role {
                    MessageRole::User => "user",
                    MessageRole::Assistant => "assistant",
                    _ => "user",
                },
                "content": m.content,
            })
        })
        .collect();

    // Append the new user message.
    api_messages.push(json!({
        "role": "user",
        "content": user_content,
    }));

    let body = json!({
        "model": config.model,
        "max_tokens": 4096,
        "system": system_prompt,
        "messages": api_messages,
    });

    let resp = client
        .post("https://api.anthropic.com/v1/messages")
        .header("x-api-key", &api_key)
        .header("anthropic-version", "2023-06-01")
        .header("content-type", "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Anthropic request failed: {e}"))?;

    let status = resp.status();
    if status.as_u16() == 429 {
        return Ok(SendMessageResponse {
            content: String::new(),
            provider: ProviderId::Anthropic,
            model: config.model.clone(),
            input_tokens: 0,
            output_tokens: 0,
            quota_exhausted: true,
        });
    }

    let resp_text = resp.text().await.map_err(|e| format!("Body read error: {e}"))?;
    if !status.is_success() {
        return Err(format!("Anthropic HTTP {}: {}", status, resp_text));
    }

    let parsed: Value =
        serde_json::from_str(&resp_text).map_err(|e| format!("JSON parse error: {e}"))?;

    // Extract content from the first content block.
    let content = parsed["content"]
        .as_array()
        .and_then(|arr| arr.first())
        .and_then(|block| block["text"].as_str())
        .unwrap_or("")
        .to_string();

    let input_tokens = parsed["usage"]["input_tokens"].as_u64().unwrap_or(0) as u32;
    let output_tokens = parsed["usage"]["output_tokens"].as_u64().unwrap_or(0) as u32;

    Ok(SendMessageResponse {
        content,
        provider: ProviderId::Anthropic,
        model: config.model.clone(),
        input_tokens,
        output_tokens,
        quota_exhausted: false,
    })
}

/// Send a message via the Google Generative Language API (Gemini).
///
/// Endpoint: `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
/// Auth: `x-goog-api-key` header
pub async fn send_google(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
) -> Result<SendMessageResponse, String> {
    let api_key = resolve_api_key(config)?;
    let client = build_client()?;

    // Build conversation parts in Gemini format.
    let mut contents: Vec<Value> = Vec::new();

    for msg in messages.iter().filter(|m| m.role != MessageRole::System) {
        let role = match msg.role {
            MessageRole::User => "user",
            MessageRole::Assistant => "model",
            _ => "user",
        };
        contents.push(json!({
            "role": role,
            "parts": [{ "text": msg.content }],
        }));
    }

    // Append new user message.
    contents.push(json!({
        "role": "user",
        "parts": [{ "text": user_content }],
    }));

    let body = json!({
        "system_instruction": {
            "parts": [{ "text": system_prompt }]
        },
        "contents": contents,
    });

    let url = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/{}:generateContent",
        config.model
    );

    let resp = client
        .post(&url)
        .header("x-goog-api-key", &api_key)
        .header("content-type", "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Google request failed: {e}"))?;

    let status = resp.status();
    if status.as_u16() == 429 {
        return Ok(SendMessageResponse {
            content: String::new(),
            provider: ProviderId::Google,
            model: config.model.clone(),
            input_tokens: 0,
            output_tokens: 0,
            quota_exhausted: true,
        });
    }

    let resp_text = resp.text().await.map_err(|e| format!("Body read error: {e}"))?;
    if !status.is_success() {
        return Err(format!("Google HTTP {}: {}", status, resp_text));
    }

    let parsed: Value =
        serde_json::from_str(&resp_text).map_err(|e| format!("JSON parse error: {e}"))?;

    // Extract text from first candidate's first part.
    let content = parsed["candidates"]
        .as_array()
        .and_then(|arr| arr.first())
        .and_then(|c| c["content"]["parts"].as_array())
        .and_then(|parts| parts.first())
        .and_then(|p| p["text"].as_str())
        .unwrap_or("")
        .to_string();

    let input_tokens = parsed["usageMetadata"]["promptTokenCount"]
        .as_u64()
        .unwrap_or(0) as u32;
    let output_tokens = parsed["usageMetadata"]["candidatesTokenCount"]
        .as_u64()
        .unwrap_or(0) as u32;

    Ok(SendMessageResponse {
        content,
        provider: ProviderId::Google,
        model: config.model.clone(),
        input_tokens,
        output_tokens,
        quota_exhausted: false,
    })
}

/// Send a message via the Mistral Chat Completions API.
///
/// Endpoint: `POST https://api.mistral.ai/v1/chat/completions`
/// Auth: `Authorization: Bearer` header
pub async fn send_mistral(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
) -> Result<SendMessageResponse, String> {
    send_openai_compatible(
        config,
        system_prompt,
        messages,
        user_content,
        "https://api.mistral.ai/v1/chat/completions",
        ProviderId::Mistral,
    )
    .await
}

/// Send a message via the OpenAI Chat Completions API.
///
/// Endpoint: `POST https://api.openai.com/v1/chat/completions`
/// Auth: `Authorization: Bearer` header
pub async fn send_openai(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
) -> Result<SendMessageResponse, String> {
    send_openai_compatible(
        config,
        system_prompt,
        messages,
        user_content,
        "https://api.openai.com/v1/chat/completions",
        ProviderId::OpenAI,
    )
    .await
}

/// Shared implementation for OpenAI-compatible Chat Completions APIs
/// (OpenAI, Mistral, and potentially others).
async fn send_openai_compatible(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
    endpoint: &str,
    provider_id: ProviderId,
) -> Result<SendMessageResponse, String> {
    let api_key = resolve_api_key(config)?;
    let client = build_client()?;

    // Build messages array in OpenAI Chat Completions format.
    let mut api_messages: Vec<Value> = vec![json!({
        "role": "system",
        "content": system_prompt,
    })];

    for msg in messages.iter().filter(|m| m.role != MessageRole::System) {
        let role = match msg.role {
            MessageRole::User => "user",
            MessageRole::Assistant => "assistant",
            _ => "user",
        };
        api_messages.push(json!({
            "role": role,
            "content": msg.content,
        }));
    }

    api_messages.push(json!({
        "role": "user",
        "content": user_content,
    }));

    let body = json!({
        "model": config.model,
        "messages": api_messages,
        "max_tokens": 4096,
    });

    let resp = client
        .post(endpoint)
        .header("Authorization", format!("Bearer {}", api_key))
        .header("content-type", "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("{:?} request failed: {e}", provider_id))?;

    let status = resp.status();
    if status.as_u16() == 429 {
        return Ok(SendMessageResponse {
            content: String::new(),
            provider: provider_id,
            model: config.model.clone(),
            input_tokens: 0,
            output_tokens: 0,
            quota_exhausted: true,
        });
    }

    let resp_text = resp.text().await.map_err(|e| format!("Body read error: {e}"))?;
    if !status.is_success() {
        return Err(format!("{:?} HTTP {}: {}", provider_id, status, resp_text));
    }

    let parsed: Value =
        serde_json::from_str(&resp_text).map_err(|e| format!("JSON parse error: {e}"))?;

    let content = parsed["choices"]
        .as_array()
        .and_then(|arr| arr.first())
        .and_then(|c| c["message"]["content"].as_str())
        .unwrap_or("")
        .to_string();

    let input_tokens = parsed["usage"]["prompt_tokens"].as_u64().unwrap_or(0) as u32;
    let output_tokens = parsed["usage"]["completion_tokens"]
        .as_u64()
        .unwrap_or(0) as u32;

    Ok(SendMessageResponse {
        content,
        provider: provider_id,
        model: config.model.clone(),
        input_tokens,
        output_tokens,
        quota_exhausted: false,
    })
}

/// Send a message via a local Ollama instance.
///
/// Endpoint: `POST http://localhost:11434/api/chat`
/// Auth: none
pub async fn send_local(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
) -> Result<SendMessageResponse, String> {
    let client = build_client()?;

    let mut api_messages: Vec<Value> = vec![json!({
        "role": "system",
        "content": system_prompt,
    })];

    for msg in messages.iter().filter(|m| m.role != MessageRole::System) {
        let role = match msg.role {
            MessageRole::User => "user",
            MessageRole::Assistant => "assistant",
            _ => "user",
        };
        api_messages.push(json!({
            "role": role,
            "content": msg.content,
        }));
    }

    api_messages.push(json!({
        "role": "user",
        "content": user_content,
    }));

    let body = json!({
        "model": config.model,
        "messages": api_messages,
        "stream": false,
    });

    let resp = client
        .post("http://localhost:11434/api/chat")
        .header("content-type", "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Local (Ollama) request failed: {e}"))?;

    let status = resp.status();
    let resp_text = resp.text().await.map_err(|e| format!("Body read error: {e}"))?;
    if !status.is_success() {
        return Err(format!("Local HTTP {}: {}", status, resp_text));
    }

    let parsed: Value =
        serde_json::from_str(&resp_text).map_err(|e| format!("JSON parse error: {e}"))?;

    let content = parsed["message"]["content"]
        .as_str()
        .unwrap_or("")
        .to_string();

    // Ollama provides eval_count (output) and prompt_eval_count (input).
    let input_tokens = parsed["prompt_eval_count"].as_u64().unwrap_or(0) as u32;
    let output_tokens = parsed["eval_count"].as_u64().unwrap_or(0) as u32;

    Ok(SendMessageResponse {
        content,
        provider: ProviderId::Local,
        model: config.model.clone(),
        input_tokens,
        output_tokens,
        quota_exhausted: false,
    })
}

// ---------------------------------------------------------------------------
// Streaming provider — Anthropic Messages API with SSE + tool_use
// ---------------------------------------------------------------------------

/// Send a streaming message via the Anthropic Messages API.
///
/// Instead of waiting for a complete response, this function reads
/// Server-Sent Events (SSE) from the Anthropic API and emits each
/// chunk to the frontend as a Tauri event (`ai:stream-chunk`).
///
/// Supports tool_use: if `tools` is provided, Claude may request tool
/// calls which the frontend routes through BoJ MCP cartridges.
pub async fn send_anthropic_streaming(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
    tools: Option<&[ToolDefinition]>,
    tool_results: Option<&[ToolResult]>,
    app_handle: tauri::AppHandle,
) -> Result<(), String> {
    use futures::StreamExt;
    use tauri::Emitter;

    let api_key = resolve_api_key(config)?;

    // Build a client without the standard timeout — streaming responses
    // can take longer than 120s for large generations.
    let client = Client::builder()
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))?;

    // Build conversation history in Anthropic format.
    let mut api_messages: Vec<Value> = messages
        .iter()
        .filter(|m| m.role != MessageRole::System)
        .map(|m| {
            json!({
                "role": match m.role {
                    MessageRole::User => "user",
                    MessageRole::Assistant => "assistant",
                    _ => "user",
                },
                "content": m.content,
            })
        })
        .collect();

    // If tool_results are provided, append them as a user message with
    // tool_result content blocks (Anthropic's multi-turn tool_use format).
    if let Some(results) = tool_results {
        let tool_result_blocks: Vec<Value> = results
            .iter()
            .map(|tr| {
                json!({
                    "type": "tool_result",
                    "tool_use_id": tr.tool_use_id,
                    "content": tr.content,
                    "is_error": tr.is_error,
                })
            })
            .collect();
        api_messages.push(json!({
            "role": "user",
            "content": tool_result_blocks,
        }));
    } else {
        // Append the new user message.
        api_messages.push(json!({
            "role": "user",
            "content": user_content,
        }));
    }

    let mut body = json!({
        "model": config.model,
        "max_tokens": 4096,
        "system": system_prompt,
        "messages": api_messages,
        "stream": true,
    });

    // Include tool definitions if provided.
    if let Some(tool_defs) = tools {
        let tools_json: Vec<Value> = tool_defs
            .iter()
            .map(|t| {
                json!({
                    "name": t.name,
                    "description": t.description,
                    "input_schema": t.input_schema,
                })
            })
            .collect();
        body["tools"] = json!(tools_json);
    }

    let resp = client
        .post("https://api.anthropic.com/v1/messages")
        .header("x-api-key", &api_key)
        .header("anthropic-version", "2023-06-01")
        .header("content-type", "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Anthropic streaming request failed: {e}"))?;

    let status = resp.status();
    if !status.is_success() {
        let error_text = resp.text().await.unwrap_or_default();
        let _ = app_handle.emit(
            "ai:stream-chunk",
            &StreamChunk::Error(format!("Anthropic HTTP {}: {}", status, error_text)),
        );
        return Err(format!("Anthropic HTTP {}: {}", status, error_text));
    }

    // Read SSE stream line by line.
    let mut stream = resp.bytes_stream();
    let mut buffer = String::new();
    let mut input_tokens: u32 = 0;
    let mut output_tokens: u32 = 0;
    let mut in_tool_use = false;

    while let Some(chunk_result) = stream.next().await {
        let chunk_bytes = chunk_result.map_err(|e| format!("Stream read error: {e}"))?;
        let chunk_str = String::from_utf8_lossy(&chunk_bytes);
        buffer.push_str(&chunk_str);

        // Process complete lines in the buffer.
        while let Some(newline_pos) = buffer.find('\n') {
            let line = buffer[..newline_pos].trim().to_string();
            buffer = buffer[newline_pos + 1..].to_string();

            // SSE format: lines starting with "data: " contain JSON.
            if !line.starts_with("data: ") {
                continue;
            }
            let json_str = &line[6..];
            if json_str == "[DONE]" {
                continue;
            }

            let parsed: Value = match serde_json::from_str(json_str) {
                Ok(v) => v,
                Err(_) => continue,
            };

            let event_type = parsed["type"].as_str().unwrap_or("");

            match event_type {
                "message_start" => {
                    // Extract input token usage from the message start event.
                    input_tokens = parsed["message"]["usage"]["input_tokens"]
                        .as_u64()
                        .unwrap_or(0) as u32;
                }
                "content_block_start" => {
                    let block_type = parsed["content_block"]["type"].as_str().unwrap_or("");
                    if block_type == "tool_use" {
                        in_tool_use = true;
                        let id = parsed["content_block"]["id"]
                            .as_str()
                            .unwrap_or("")
                            .to_string();
                        let name = parsed["content_block"]["name"]
                            .as_str()
                            .unwrap_or("")
                            .to_string();
                        let _ = app_handle.emit(
                            "ai:stream-chunk",
                            &StreamChunk::ToolUseStart { id, name },
                        );
                    }
                    // text blocks: wait for deltas
                }
                "content_block_delta" => {
                    let delta_type = parsed["delta"]["type"].as_str().unwrap_or("");
                    match delta_type {
                        "text_delta" => {
                            let text = parsed["delta"]["text"]
                                .as_str()
                                .unwrap_or("")
                                .to_string();
                            let _ = app_handle
                                .emit("ai:stream-chunk", &StreamChunk::TextDelta(text));
                        }
                        "input_json_delta" => {
                            let partial_json = parsed["delta"]["partial_json"]
                                .as_str()
                                .unwrap_or("")
                                .to_string();
                            let _ = app_handle.emit(
                                "ai:stream-chunk",
                                &StreamChunk::ToolUseDelta(partial_json),
                            );
                        }
                        _ => {}
                    }
                }
                "content_block_stop" => {
                    if in_tool_use {
                        let _ =
                            app_handle.emit("ai:stream-chunk", &StreamChunk::ToolUseEnd);
                        in_tool_use = false;
                    }
                }
                "message_delta" => {
                    output_tokens = parsed["usage"]["output_tokens"]
                        .as_u64()
                        .unwrap_or(0) as u32;
                }
                "message_stop" => {
                    let _ = app_handle.emit(
                        "ai:stream-chunk",
                        &StreamChunk::Complete {
                            input_tokens,
                            output_tokens,
                        },
                    );
                }
                "error" => {
                    let error_msg = parsed["error"]["message"]
                        .as_str()
                        .unwrap_or("Unknown streaming error")
                        .to_string();
                    let _ = app_handle
                        .emit("ai:stream-chunk", &StreamChunk::Error(error_msg));
                }
                _ => {}
            }
        }
    }

    Ok(())
}

/// Route a message to the correct provider's send function.
pub async fn send_message(
    config: &ProviderConfig,
    system_prompt: &str,
    messages: &[AiMessage],
    user_content: &str,
) -> Result<SendMessageResponse, String> {
    match config.id {
        ProviderId::Anthropic => send_anthropic(config, system_prompt, messages, user_content).await,
        ProviderId::Google => send_google(config, system_prompt, messages, user_content).await,
        ProviderId::Mistral => send_mistral(config, system_prompt, messages, user_content).await,
        ProviderId::OpenAI => send_openai(config, system_prompt, messages, user_content).await,
        ProviderId::Local => send_local(config, system_prompt, messages, user_content).await,
    }
}
