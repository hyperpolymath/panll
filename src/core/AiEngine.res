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
let allCategories: array<aiCategory> = [
  Conversation,
  SystemPrompt,
  Providers,
  Context,
]

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

/// Parse a SendMessageResponse from the Tauri backend JSON.
let parseMessageResponse = (jsonStr: string): result<aiMessage, string> => {
  try {
    let parsed = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getString = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getInt = (key: string): int =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Float.toInt(n)
            | _ => 0
            }
          | None => 0
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        let providerId = providerIdFromString(getString("provider"))
        let isExhausted = getBool("quota_exhausted")

        if isExhausted {
          Error("quota_exhausted")
        } else {
          Ok({
            role: Assistant,
            content: getString("content"),
            provider: providerId,
            model: Some(getString("model")),
            inputTokens: getInt("input_tokens"),
            outputTokens: getInt("output_tokens"),
            timestamp: Date.now(),
          })
        }
      }
    | _ => Error("Expected object in message response")
    }
  } catch {
  | _ => Error("Failed to parse message response JSON")
  }
}

/// Parse provider config state from the Tauri backend JSON.
let parseProviderState = (jsonStr: string): result<array<aiProviderConfig>, string> => {
  try {
    let parsed = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        switch Dict.get(obj, "providers") {
        | Some(arr) =>
          switch JSON.Classify.classify(arr) {
          | Array(providers) => {
              let configs = providers->Array.filterMap(p => {
                switch JSON.Classify.classify(p) {
                | Object(pObj) => {
                    let getString = (key: string): string =>
                      switch Dict.get(pObj, key) {
                      | Some(v) =>
                        switch JSON.Classify.classify(v) {
                        | String(s) => s
                        | _ => ""
                        }
                      | None => ""
                      }
                    let getBool = (key: string): bool =>
                      switch Dict.get(pObj, key) {
                      | Some(v) =>
                        switch JSON.Classify.classify(v) {
                        | Bool(b) => b
                        | _ => false
                        }
                      | None => false
                      }
                    let getInt = (key: string): int =>
                      switch Dict.get(pObj, key) {
                      | Some(v) =>
                        switch JSON.Classify.classify(v) {
                        | Number(n) => Float.toInt(n)
                        | _ => 0
                        }
                      | None => 0
                      }
                    switch providerIdFromString(getString("id")) {
                    | Some(id) =>
                      Some({
                        id,
                        apiKey: None,
                        envVar: getString("env_var"),
                        enabled: getBool("enabled"),
                        priority: getInt("priority"),
                        selectedModel: getString("model"),
                        quotaExhausted: false,
                      })
                    | None => None
                    }
                  }
                | _ => None
                }
              })
              Ok(configs)
            }
          | _ => Error("Expected array for providers")
          }
        | None => Error("Missing providers field")
        }
      }
    | _ => Error("Expected object in provider state response")
    }
  } catch {
  | _ => Error("Failed to parse provider state JSON")
  }
}
