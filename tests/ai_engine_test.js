// SPDX-License-Identifier: MPL-2.0

/**
 * AiEngine Tests — provider labels/colours/icons, status labels/dots,
 * category labels, role labels, token formatting, priority sorting,
 * provider selection, provider ID serialisation, default providers/state,
 * model lists, and JSON response parsing.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  providerLabel,
  providerShortLabel,
  providerColour,
  providerBgColour,
  providerIcon,
  statusLabel,
  statusDotClass,
  categoryLabel,
  allCategories,
  roleLabel,
  formatTokens,
  sortByPriority,
  selectProvider,
  getProviderStatus,
  providerIdToString,
  providerIdFromString,
  defaultProviders,
  defaultState,
  providerModels,
  parseMessageResponse,
  parseProviderState,
} from "../src/core/AiEngine.res.js";

// -- providerLabel --

Deno.test("providerLabel returns correct strings", () => {
  assertEquals(providerLabel("Anthropic"), "Anthropic");
  assertEquals(providerLabel("Google"), "Google");
  assertEquals(providerLabel("Mistral"), "Mistral");
  assertEquals(providerLabel("OpenAI"), "OpenAI");
  assertEquals(providerLabel("Local"), "Local");
});

// -- providerShortLabel --

Deno.test("providerShortLabel returns product names", () => {
  assertEquals(providerShortLabel("Anthropic"), "Claude");
  assertEquals(providerShortLabel("Google"), "Gemini");
  assertEquals(providerShortLabel("Mistral"), "Mistral");
  assertEquals(providerShortLabel("OpenAI"), "GPT");
  assertEquals(providerShortLabel("Local"), "Ollama");
});

// -- providerColour --

Deno.test("providerColour returns border colour classes", () => {
  assertEquals(providerColour("Anthropic"), "border-orange-500");
  assertEquals(providerColour("Google"), "border-blue-500");
  assertEquals(providerColour("Mistral"), "border-yellow-500");
  assertEquals(providerColour("OpenAI"), "border-green-500");
  assertEquals(providerColour("Local"), "border-purple-500");
});

// -- providerBgColour --

Deno.test("providerBgColour returns background + text classes", () => {
  assertEquals(providerBgColour("Anthropic"), "bg-orange-500/20 text-orange-300");
  assertEquals(providerBgColour("Google"), "bg-blue-500/20 text-blue-300");
  assertEquals(providerBgColour("Mistral"), "bg-yellow-500/20 text-yellow-300");
  assertEquals(providerBgColour("OpenAI"), "bg-green-500/20 text-green-300");
  assertEquals(providerBgColour("Local"), "bg-purple-500/20 text-purple-300");
});

// -- providerIcon --

Deno.test("providerIcon returns correct icon ids", () => {
  assertEquals(providerIcon("Anthropic"), "brain");
  assertEquals(providerIcon("Google"), "sparkles");
  assertEquals(providerIcon("Mistral"), "wind");
  assertEquals(providerIcon("OpenAI"), "cpu");
  assertEquals(providerIcon("Local"), "server");
});

// -- statusLabel --

Deno.test("statusLabel returns correct strings for simple statuses", () => {
  assertEquals(statusLabel("Ready"), "Ready");
  assertEquals(statusLabel("Checking"), "Checking...");
  assertEquals(statusLabel("QuotaExhausted"), "Quota Exhausted");
  assertEquals(statusLabel("Disabled"), "Disabled");
  assertEquals(statusLabel("NoKey"), "No API Key");
});

Deno.test("statusLabel returns error message for AiProviderError", () => {
  const result = statusLabel({ TAG: "AiProviderError", _0: "rate limited" });
  assertEquals(result, "Error: rate limited");
});

// -- statusDotClass --

Deno.test("statusDotClass returns correct classes", () => {
  assertEquals(statusDotClass("Ready"), "bg-green-400");
  assertEquals(statusDotClass("Checking"), "bg-yellow-400 animate-pulse");
  assertEquals(statusDotClass("QuotaExhausted"), "bg-red-400");
  assertEquals(statusDotClass("Disabled"), "bg-gray-600");
  assertEquals(statusDotClass("NoKey"), "bg-gray-500");
});

Deno.test("statusDotClass returns red for AiProviderError", () => {
  assertEquals(statusDotClass({ TAG: "AiProviderError", _0: "timeout" }), "bg-red-400");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings for AI categories", () => {
  assertEquals(categoryLabel("Conversation"), "Conversation");
  assertEquals(categoryLabel("SystemPrompt"), "System Prompt");
  assertEquals(categoryLabel("Providers"), "Providers");
  assertEquals(categoryLabel("Context"), "Context");
});

// -- allCategories --

Deno.test("allCategories has 4 entries in order", () => {
  assertEquals(allCategories.length, 4);
  assertEquals(allCategories, ["Conversation", "SystemPrompt", "Providers", "Context"]);
});

// -- roleLabel --

Deno.test("roleLabel returns correct display names", () => {
  assertEquals(roleLabel("User"), "You");
  assertEquals(roleLabel("Assistant"), "AI");
  assertEquals(roleLabel("System"), "System");
});

// -- formatTokens --

Deno.test("formatTokens returns raw number for < 1000", () => {
  assertEquals(formatTokens(0), "0");
  assertEquals(formatTokens(42), "42");
  assertEquals(formatTokens(999), "999");
});

Deno.test("formatTokens returns k suffix for >= 1000", () => {
  assertEquals(formatTokens(1000), "1.0k");
  assertEquals(formatTokens(1500), "1.5k");
  assertEquals(formatTokens(10000), "10.0k");
});

// -- sortByPriority --

Deno.test("sortByPriority sorts by ascending priority", () => {
  const providers = [
    { id: "Local", priority: 5, enabled: true, quotaExhausted: false },
    { id: "Anthropic", priority: 1, enabled: true, quotaExhausted: false },
    { id: "Google", priority: 3, enabled: true, quotaExhausted: false },
  ];
  const sorted = sortByPriority(providers);
  assertEquals(sorted[0].id, "Anthropic");
  assertEquals(sorted[1].id, "Google");
  assertEquals(sorted[2].id, "Local");
});

Deno.test("sortByPriority does not mutate original array", () => {
  const providers = [
    { id: "Local", priority: 5, enabled: true, quotaExhausted: false },
    { id: "Anthropic", priority: 1, enabled: true, quotaExhausted: false },
  ];
  sortByPriority(providers);
  assertEquals(providers[0].id, "Local");
});

// -- selectProvider --

Deno.test("selectProvider returns highest priority enabled provider", () => {
  const providers = [
    { id: "Google", priority: 2, enabled: true, quotaExhausted: false },
    { id: "Anthropic", priority: 1, enabled: true, quotaExhausted: false },
    { id: "Local", priority: 3, enabled: false, quotaExhausted: false },
  ];
  const selected = selectProvider(providers);
  assertEquals(selected.id, "Anthropic");
});

Deno.test("selectProvider skips disabled providers", () => {
  const providers = [
    { id: "Anthropic", priority: 1, enabled: false, quotaExhausted: false },
    { id: "Google", priority: 2, enabled: true, quotaExhausted: false },
  ];
  const selected = selectProvider(providers);
  assertEquals(selected.id, "Google");
});

Deno.test("selectProvider skips quota-exhausted providers", () => {
  const providers = [
    { id: "Anthropic", priority: 1, enabled: true, quotaExhausted: true },
    { id: "Google", priority: 2, enabled: true, quotaExhausted: false },
  ];
  const selected = selectProvider(providers);
  assertEquals(selected.id, "Google");
});

Deno.test("selectProvider returns undefined when none available", () => {
  const providers = [
    { id: "Anthropic", priority: 1, enabled: false, quotaExhausted: false },
    { id: "Google", priority: 2, enabled: false, quotaExhausted: false },
  ];
  assertEquals(selectProvider(providers), undefined);
});

// -- getProviderStatus --

Deno.test("getProviderStatus finds matching status", () => {
  const statuses = [
    ["Anthropic", "Ready"],
    ["Google", "Disabled"],
  ];
  assertEquals(getProviderStatus(statuses, "Anthropic"), "Ready");
  assertEquals(getProviderStatus(statuses, "Google"), "Disabled");
});

Deno.test("getProviderStatus returns NoKey for unknown provider", () => {
  assertEquals(getProviderStatus([], "Mistral"), "NoKey");
});

// -- providerIdToString --

Deno.test("providerIdToString returns lowercase strings", () => {
  assertEquals(providerIdToString("Anthropic"), "anthropic");
  assertEquals(providerIdToString("Google"), "google");
  assertEquals(providerIdToString("Mistral"), "mistral");
  assertEquals(providerIdToString("OpenAI"), "openai");
  assertEquals(providerIdToString("Local"), "local");
});

// -- providerIdFromString --

Deno.test("providerIdFromString parses valid strings", () => {
  assertEquals(providerIdFromString("anthropic"), "Anthropic");
  assertEquals(providerIdFromString("google"), "Google");
  assertEquals(providerIdFromString("mistral"), "Mistral");
  assertEquals(providerIdFromString("openai"), "OpenAI");
  assertEquals(providerIdFromString("local"), "Local");
});

Deno.test("providerIdFromString is case-insensitive", () => {
  assertEquals(providerIdFromString("ANTHROPIC"), "Anthropic");
  assertEquals(providerIdFromString("Google"), "Google");
});

Deno.test("providerIdFromString returns undefined for unknown", () => {
  assertEquals(providerIdFromString("unknown"), undefined);
  assertEquals(providerIdFromString(""), undefined);
});

// -- defaultProviders --

Deno.test("defaultProviders has 5 entries", () => {
  assertEquals(defaultProviders.length, 5);
});

Deno.test("defaultProviders Anthropic is first with priority 1", () => {
  assertEquals(defaultProviders[0].id, "Anthropic");
  assertEquals(defaultProviders[0].priority, 1);
  assertEquals(defaultProviders[0].enabled, true);
});

Deno.test("defaultProviders all have apiKey undefined (None)", () => {
  for (const p of defaultProviders) {
    assertEquals(p.apiKey, undefined);
  }
});

// -- defaultState --

Deno.test("defaultState activeCategory is Conversation", () => {
  assertEquals(defaultState.activeCategory, "Conversation");
});

Deno.test("defaultState messages is empty", () => {
  assertEquals(defaultState.messages.length, 0);
});

Deno.test("defaultState inputText is empty", () => {
  assertEquals(defaultState.inputText, "");
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState broadcastMode is false", () => {
  assertEquals(defaultState.broadcastMode, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState token counters are 0", () => {
  assertEquals(defaultState.totalInputTokens, 0);
  assertEquals(defaultState.totalOutputTokens, 0);
});

Deno.test("defaultState has systemPrompt", () => {
  assert(defaultState.systemPrompt.length > 0);
  assert(defaultState.systemPrompt.includes("PanLL"));
});

Deno.test("defaultState providerStatuses has 5 entries", () => {
  assertEquals(defaultState.providerStatuses.length, 5);
});

// -- providerModels --

Deno.test("providerModels returns models for Anthropic", () => {
  const models = providerModels("Anthropic");
  assertEquals(models.length, 3);
  assert(models.includes("claude-opus-4-6"));
});

Deno.test("providerModels returns models for Google", () => {
  const models = providerModels("Google");
  assertEquals(models.length, 2);
  assert(models.includes("gemini-2.5-pro"));
});

Deno.test("providerModels returns models for Local", () => {
  const models = providerModels("Local");
  assertEquals(models.length, 4);
  assert(models.includes("llama3"));
});

// -- parseMessageResponse --

Deno.test("parseMessageResponse parses valid response", () => {
  const json = JSON.stringify({
    provider: "anthropic",
    content: "Hello!",
    model: "claude-opus-4-6",
    input_tokens: 10,
    output_tokens: 20,
    quota_exhausted: false,
  });
  const result = parseMessageResponse(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.role, "Assistant");
  assertEquals(result._0.content, "Hello!");
  assertEquals(result._0.provider, "Anthropic");
  assertEquals(result._0.inputTokens, 10);
  assertEquals(result._0.outputTokens, 20);
});

Deno.test("parseMessageResponse returns error for quota exhausted", () => {
  const json = JSON.stringify({
    provider: "anthropic",
    content: "",
    model: "",
    quota_exhausted: true,
  });
  const result = parseMessageResponse(json);
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "quota_exhausted");
});

Deno.test("parseMessageResponse returns error for invalid JSON", () => {
  const result = parseMessageResponse("not json");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

Deno.test("parseMessageResponse returns Ok with defaults for non-object JSON", () => {
  const result = parseMessageResponse("42");
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.role, "Assistant");
  assertEquals(result._0.content, "");
});

// -- parseProviderState --

Deno.test("parseProviderState parses valid provider config", () => {
  const json = JSON.stringify({
    providers: [
      { id: "anthropic", env_var: "ANTHROPIC_API_KEY", enabled: true, priority: 1, model: "claude-opus-4-6" },
      { id: "google", env_var: "GOOGLE_AI_KEY", enabled: false, priority: 2, model: "gemini-2.5-pro" },
    ],
  });
  const result = parseProviderState(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.length, 2);
  assertEquals(result._0[0].id, "Anthropic");
  assertEquals(result._0[0].enabled, true);
  assertEquals(result._0[1].id, "Google");
});

Deno.test("parseProviderState returns error for missing providers field", () => {
  const result = parseProviderState(JSON.stringify({}));
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, 'providers: Field "providers" not found');
});

Deno.test("parseProviderState returns error for invalid JSON", () => {
  const result = parseProviderState("nope");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

Deno.test("parseProviderState skips entries with unknown provider IDs", () => {
  const json = JSON.stringify({
    providers: [
      { id: "anthropic", env_var: "X", enabled: true, priority: 1, model: "m" },
      { id: "unknown_provider", env_var: "Y", enabled: true, priority: 2, model: "n" },
    ],
  });
  const result = parseProviderState(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.length, 1);
});
