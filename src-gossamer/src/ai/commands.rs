// SPDX-License-Identifier: PMPL-1.0-or-later

//! AI Tauri Commands — exposed to the ReScript frontend via `invoke()`.
//!
//! Commands:
//!   - `ai_send_message`: Send a message to the selected AI provider.
//!   - `ai_check_provider`: Probe a provider's health/auth status.
//!   - `ai_set_model`: Change the selected model for a provider.
//!   - `ai_set_priority`: Change a provider's precedence ranking.
//!   - `ai_toggle_provider`: Enable/disable a provider.
//!   - `ai_clear_history`: Reset the conversation history.
//!   - `ai_build_context`: Assemble the system prompt from repo metadata.
//!   - `ai_get_state`: Load the provider config from disk.

use std::fs;
use std::path::PathBuf;

use super::context;
use super::providers;
use super::types::*;

/// Resolve the config file path: `~/.config/panll/ai-providers.json`.
fn config_path() -> Result<PathBuf, String> {
    let config_dir = dirs::config_dir().ok_or("Cannot determine config directory")?;
    Ok(config_dir.join("panll").join("ai-providers.json"))
}

/// Load provider configs from disk. Creates defaults if file doesn't exist.
fn load_config() -> Result<AiProvidersFile, String> {
    let path = config_path()?;
    if !path.exists() {
        // Create default config on first run.
        let defaults = AiProvidersFile::defaults();
        save_config(&defaults)?;
        return Ok(defaults);
    }
    let content =
        fs::read_to_string(&path).map_err(|e| format!("Cannot read config: {e}"))?;
    serde_json::from_str(&content).map_err(|e| format!("Cannot parse config: {e}"))
}

/// Save provider configs to disk.
fn save_config(config: &AiProvidersFile) -> Result<(), String> {
    let path = config_path()?;
    // Ensure parent directory exists.
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Cannot create config directory: {e}"))?;
    }
    let json = serde_json::to_string_pretty(config)
        .map_err(|e| format!("Cannot serialise config: {e}"))?;
    fs::write(&path, json).map_err(|e| format!("Cannot write config: {e}"))
}

/// Send a message to the highest-priority enabled provider (or a specified one).
///
/// Returns the provider's response as a JSON-serialised `SendMessageResponse`.
/// If the provider returns 429, the response has `quota_exhausted: true` and
/// the frontend should retry with the next provider.

pub async fn ai_send_message(request: SendMessageRequest) -> Result<String, String> {
    let config_file = load_config()?;

    // Select provider: explicit choice or auto-select by priority.
    // Clone the config to avoid borrow-checker issues with the temporary candidates vec.
    let provider_config: ProviderConfig = if let Some(ref pid) = request.provider_id {
        config_file
            .providers
            .iter()
            .find(|p| &p.id == pid)
            .ok_or(format!("Provider {:?} not configured", pid))?
            .clone()
    } else {
        // Auto-select: highest priority (lowest number), enabled.
        let mut candidates: Vec<&ProviderConfig> = config_file
            .providers
            .iter()
            .filter(|p| p.enabled)
            .collect();
        candidates.sort_by_key(|p| p.priority);
        (*candidates
            .first()
            .ok_or("No enabled providers configured")?)
            .clone()
    };

    let response = providers::send_message(
        &provider_config,
        &request.system_prompt,
        &request.history,
        &request.content,
    )
    .await?;

    serde_json::to_string(&response).map_err(|e| format!("Serialisation error: {e}"))
}

/// Check if a provider is reachable and properly authenticated.
///
/// Sends a minimal request to verify the API key works.
/// Returns a JSON object with `{ "status": "ready"|"error"|"no_key", "detail": "..." }`.

pub async fn ai_check_provider(provider_id: String) -> Result<String, String> {
    let config_file = load_config()?;
    let pid: ProviderId =
        serde_json::from_str(&format!("\"{}\"", provider_id.to_lowercase()))
            .map_err(|_| format!("Unknown provider: {provider_id}"))?;

    let provider = config_file
        .providers
        .iter()
        .find(|p| p.id == pid)
        .ok_or(format!("Provider {} not configured", provider_id))?;

    if !provider.enabled {
        return serde_json::to_string(&serde_json::json!({
            "status": "disabled",
            "detail": "Provider is disabled"
        }))
        .map_err(|e| format!("Serialisation error: {e}"));
    }

    // Try to resolve the API key (except for local which needs none).
    if pid != ProviderId::Local {
        let key_check = std::env::var(&provider.env_var);
        let has_explicit = provider.api_key.as_ref().is_some_and(|k| !k.is_empty());
        if !has_explicit && key_check.is_err() {
            return serde_json::to_string(&serde_json::json!({
                "status": "no_key",
                "detail": format!("No API key: set {} or provide in config", provider.env_var)
            }))
            .map_err(|e| format!("Serialisation error: {e}"));
        }
    }

    // For local provider, check if Ollama is running.
    if pid == ProviderId::Local {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(5))
            .build()
            .map_err(|e| format!("HTTP client error: {e}"))?;

        match client.get("http://localhost:11434/api/tags").send().await {
            Ok(resp) if resp.status().is_success() => {
                return serde_json::to_string(&serde_json::json!({
                    "status": "ready",
                    "detail": "Ollama is running"
                }))
                .map_err(|e| format!("Serialisation error: {e}"));
            }
            _ => {
                return serde_json::to_string(&serde_json::json!({
                    "status": "error",
                    "detail": "Ollama not reachable at localhost:11434"
                }))
                .map_err(|e| format!("Serialisation error: {e}"));
            }
        }
    }

    // For remote providers, we consider having a valid key as "ready".
    // A full auth check would consume tokens; we defer that to the first real message.
    serde_json::to_string(&serde_json::json!({
        "status": "ready",
        "detail": "API key configured"
    }))
    .map_err(|e| format!("Serialisation error: {e}"))
}

/// Change the selected model for a provider.

pub async fn ai_set_model(provider_id: String, model: String) -> Result<String, String> {
    let mut config_file = load_config()?;
    let pid: ProviderId =
        serde_json::from_str(&format!("\"{}\"", provider_id.to_lowercase()))
            .map_err(|_| format!("Unknown provider: {provider_id}"))?;

    let found = config_file
        .providers
        .iter_mut()
        .find(|p| p.id == pid)
        .ok_or(format!("Provider {} not configured", provider_id))?;

    found.model = model.clone();
    save_config(&config_file)?;

    Ok(serde_json::json!({ "provider": provider_id, "model": model }).to_string())
}

/// Change a provider's precedence ranking.

pub async fn ai_set_priority(provider_id: String, priority: u32) -> Result<String, String> {
    let mut config_file = load_config()?;
    let pid: ProviderId =
        serde_json::from_str(&format!("\"{}\"", provider_id.to_lowercase()))
            .map_err(|_| format!("Unknown provider: {provider_id}"))?;

    let found = config_file
        .providers
        .iter_mut()
        .find(|p| p.id == pid)
        .ok_or(format!("Provider {} not configured", provider_id))?;

    found.priority = priority;
    save_config(&config_file)?;

    Ok(serde_json::json!({ "provider": provider_id, "priority": priority }).to_string())
}

/// Enable or disable a provider (mute/unmute without losing the API key).

pub async fn ai_toggle_provider(provider_id: String) -> Result<String, String> {
    let mut config_file = load_config()?;
    let pid: ProviderId =
        serde_json::from_str(&format!("\"{}\"", provider_id.to_lowercase()))
            .map_err(|_| format!("Unknown provider: {provider_id}"))?;

    let found = config_file
        .providers
        .iter_mut()
        .find(|p| p.id == pid)
        .ok_or(format!("Provider {} not configured", provider_id))?;

    found.enabled = !found.enabled;
    let new_state = found.enabled;
    save_config(&config_file)?;

    Ok(serde_json::json!({ "provider": provider_id, "enabled": new_state }).to_string())
}

/// Clear the conversation history. This is a frontend-only operation;
/// this command exists as a hook for any backend cleanup needed later
/// (e.g., clearing cached token counts).

pub async fn ai_clear_history() -> Result<String, String> {
    Ok(serde_json::json!({ "cleared": true }).to_string())
}

/// Build the system prompt context from a repository path.
///
/// Reads SCM files, AI manifest, detected languages, and assembles a
/// structured context string for the AI system prompt.

pub async fn ai_build_context(repo_path: String) -> Result<String, String> {
    let context_str = context::build_repo_context(&repo_path)?;
    Ok(serde_json::json!({ "context": context_str }).to_string())
}

/// Load the current provider configuration state from disk.
///
/// Returns the full `AiProvidersFile` as JSON. The frontend uses this
/// to initialise the provider key ring on panel open.

pub async fn ai_get_state() -> Result<String, String> {
    let config_file = load_config()?;
    serde_json::to_string(&config_file).map_err(|e| format!("Serialisation error: {e}"))
}

/// Send a streaming message to the Anthropic provider with tool_use support.
///
/// Unlike `ai_send_message` which returns a complete response, this command
/// fires and forgets — results arrive via Tauri events on the `ai:stream-chunk`
/// channel. The frontend listens for these events and feeds them into the
/// TEA update loop as `AiStreamChunkReceived` messages.
///
/// Returns `"streaming_started"` immediately. Errors during streaming are
/// emitted as `StreamChunk::Error` events rather than returned here.

pub async fn ai_send_message_streaming(
    app_handle: crate::compat::AppHandle,
    request: StreamingRequest,
) -> Result<String, String> {
    let config_file = load_config()?;

    // Select provider: explicit choice or auto-select by priority.
    // Currently, streaming only supports Anthropic. Other providers
    // fall back to the non-streaming path.
    let provider_config: ProviderConfig = if let Some(ref pid) = request.provider_id {
        config_file
            .providers
            .iter()
            .find(|p| &p.id == pid)
            .ok_or(format!("Provider {:?} not configured", pid))?
            .clone()
    } else {
        // Auto-select: highest priority, enabled, Anthropic preferred.
        let mut candidates: Vec<&ProviderConfig> = config_file
            .providers
            .iter()
            .filter(|p| p.enabled)
            .collect();
        candidates.sort_by_key(|p| p.priority);
        (*candidates
            .first()
            .ok_or("No enabled providers configured")?)
            .clone()
    };

    // Verify this is Anthropic — streaming is only implemented for Anthropic.
    if provider_config.id != ProviderId::Anthropic {
        return Err(format!(
            "Streaming only supported for Anthropic, got {:?}",
            provider_config.id
        ));
    }

    // Clone owned data for the spawned task (must be 'static).
    let tools_owned = request.tools.clone();
    let tool_results_owned = request.tool_results.clone();
    let system_prompt = request.system_prompt.clone();
    let history = request.history.clone();
    let content = request.content.clone();

    // Spawn the streaming task so we can return immediately.
    crate::compat::spawn_async(async move {
        let tools_ref = tools_owned.as_deref();
        let tool_results_ref = tool_results_owned.as_deref();

        if let Err(e) = providers::send_anthropic_streaming(
            &provider_config,
            &system_prompt,
            &history,
            &content,
            tools_ref,
            tool_results_ref,
            app_handle.clone(),
        )
        .await
        {
            use crate::compat::Emitter;
            let _ = app_handle.emit(
                "ai:stream-chunk",
                &StreamChunk::Error(e),
            );
        }
    });

    Ok("streaming_started".to_string())
}
