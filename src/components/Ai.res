// SPDX-License-Identifier: MPL-2.0

/// PanLL AI Panel Component — Three-region multi-provider neural interface.
///
/// Layout:
///   +--sidebar--+  +--main area-----+
///   | Panel-L   |  | Conversation   |
///   | Constraints|  | or Providers   |
///   | Context   |  | or SystemPrompt|
///   +-----------+  +--input area----+
///
/// The AI panel embeds AI providers (Claude, Gemini, Mistral, GPT, local) inside
/// the PanLL environment with full repo context, active panel awareness, VoiceTag
/// data, and provenance information.

open Model
open Msg
open Tea.Html

// ===========================================================================
// Sidebar: Context summary + constraint indicators
// ===========================================================================

/// Render the left sidebar showing current context and constraint indicators.
let renderSidebar = (ai: aiState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("w-64 border-r border-gray-800 p-4 overflow-y-auto flex-shrink-0")},
    list{
      // Section: Active provider
      div(
        list{Attrs.class_("mb-6")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
            list{text("Active Provider")},
          ),
          {
            let selected = AiEngine.selectProvider(ai.providers)
            switch selected {
            | Some(p) =>
              div(
                list{
                  Attrs.class_(
                    `px-3 py-2 rounded ${AiEngine.providerBgColour(p.id)} text-sm font-medium`,
                  ),
                },
                list{text(`${AiEngine.providerShortLabel(p.id)} / ${p.selectedModel}`)},
              )
            | None =>
              div(
                list{Attrs.class_("px-3 py-2 rounded bg-red-500/20 text-red-300 text-sm")},
                list{text("No provider available")},
              )
            }
          },
        },
      ),
      // Section: Token usage
      div(
        list{Attrs.class_("mb-6")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
            list{text("Token Usage")},
          ),
          div(
            list{Attrs.class_("text-sm text-gray-400 space-y-1")},
            list{
              div(list{}, list{text(`In: ${AiEngine.formatTokens(ai.totalInputTokens)}`)}),
              div(list{}, list{text(`Out: ${AiEngine.formatTokens(ai.totalOutputTokens)}`)}),
            },
          ),
        },
      ),
      // Section: Provider status summary
      div(
        list{Attrs.class_("mb-6")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
            list{text("Providers")},
          ),
          div(
            list{Attrs.class_("space-y-2")},
            ai.providers
            ->AiEngine.sortByPriority
            ->Array.map(p => {
              let status = AiEngine.getProviderStatus(ai.providerStatuses, p.id)
              div(
                list{Attrs.class_("flex items-center gap-2 text-sm")},
                list{
                  div(
                    list{Attrs.class_(`w-2 h-2 rounded-full ${AiEngine.statusDotClass(status)}`)},
                    list{},
                  ),
                  div(
                    list{Attrs.class_(p.enabled ? "text-gray-300" : "text-gray-600")},
                    list{text(AiEngine.providerShortLabel(p.id))},
                  ),
                },
              )
            })
            ->List.fromArray,
          ),
        },
      ),
      {
        if ai.autoContext !== "" {
          div(
            list{Attrs.class_("mb-6")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
                list{text("Repo Context")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 max-h-40 overflow-y-auto")},
                list{text(String.slice(ai.autoContext, ~start=0, ~end=200) ++ "...")},
              ),
            },
          )
        } else {
          div(
            list{Attrs.class_("mb-6")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
                list{text("Repo Context")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-600 italic")},
                list{text("No repo loaded — use Repo Loader to load context")},
              ),
            },
          )
        }
      },
    },
  )
}

// ===========================================================================
// Category tab bar
// ===========================================================================

/// Render a single category tab.
let renderCategoryTab = (cat: aiCategory, isActive: bool): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        `px-4 py-2 text-sm transition-colors ${isActive
            ? "text-gray-100 border-b-2 border-orange-500"
            : "text-gray-500 hover:text-gray-300"}`,
      ),
      Events.onClick(Ai(SetAiCategory(cat))),
    },
    list{text(AiEngine.categoryLabel(cat))},
  )
}

/// Render the category tab bar.
let renderCategoryTabBar = (activeCategory: aiCategory): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex border-b border-gray-800")},
    AiEngine.allCategories
    ->Array.map(cat => renderCategoryTab(cat, cat === activeCategory))
    ->List.fromArray,
  )
}

// ===========================================================================
// Conversation view
// ===========================================================================

/// Render a single message in the conversation stream.
let renderMessage = (msg: aiMessage): Tea_Vdom.t<Msg.msg> => {
  let isUser = msg.role === User
  let alignment = isUser ? "justify-end" : "justify-start"
  let bgClass = isUser ? "bg-gray-800" : "bg-gray-900"
  let borderClass = switch msg.provider {
  | Some(id) => AiEngine.providerColour(id)
  | None => "border-gray-700"
  }

  div(
    list{Attrs.class_(`flex ${alignment} mb-3`)},
    list{
      div(
        list{Attrs.class_(`max-w-3xl ${bgClass} border ${borderClass} rounded-lg px-4 py-3`)},
        list{
          {
            if !isUser {
              div(
                list{Attrs.class_("flex items-center gap-2 mb-2")},
                list{
                  {
                    switch msg.provider {
                    | Some(id) =>
                      span(
                        list{
                          Attrs.class_(
                            `text-xs px-2 py-0.5 rounded ${AiEngine.providerBgColour(id)}`,
                          ),
                        },
                        list{text(AiEngine.providerShortLabel(id))},
                      )
                    | None => noNode
                    }
                  },
                  {
                    switch msg.model {
                    | Some(m) => span(list{Attrs.class_("text-xs text-gray-600")}, list{text(m)})
                    | None => noNode
                    }
                  },
                  {
                    if msg.outputTokens > 0 {
                      span(
                        list{Attrs.class_("text-xs text-gray-600")},
                        list{text(`${AiEngine.formatTokens(msg.outputTokens)} tokens`)},
                      )
                    } else {
                      noNode
                    }
                  },
                },
              )
            } else {
              noNode
            }
          },
          // Message content
          div(
            list{Attrs.class_("text-sm text-gray-200 whitespace-pre-wrap")},
            list{text(msg.content)},
          ),
        },
      ),
    },
  )
}

/// Render the conversation stream.
let renderConversation = (ai: aiState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-4")},
    list{
      {
        if Array.length(ai.messages) === 0 {
          div(
            list{Attrs.class_("flex items-center justify-center h-full")},
            list{
              div(
                list{Attrs.class_("text-center text-gray-600")},
                list{
                  div(list{Attrs.class_("text-2xl mb-4")}, list{text("Neural Interface")}),
                  div(
                    list{Attrs.class_("text-sm")},
                    list{text("Start a conversation with your AI providers.")},
                  ),
                  div(
                    list{Attrs.class_("text-sm mt-2")},
                    list{text("Load a repo to give the AI full project context.")},
                  ),
                },
              ),
            },
          )
        } else {
          div(
            list{Attrs.class_("space-y-1")},
            ai.messages->Array.map(renderMessage)->List.fromArray,
          )
        }
      },
      {
        if ai.loading {
          div(
            list{Attrs.class_("flex justify-start mb-3")},
            list{
              div(
                list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg px-4 py-3")},
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-500 animate-pulse")},
                    list{text("Thinking...")},
                  ),
                },
              ),
            },
          )
        } else {
          noNode
        }
      },
      {
        switch ai.error {
        | Some(e) =>
          div(
            list{
              Attrs.class_(
                "mx-4 mb-2 px-3 py-2 bg-red-900/30 border border-red-700 rounded text-sm text-red-300",
              ),
            },
            list{text(e)},
          )
        | None => noNode
        }
      },
    },
  )
}

// ===========================================================================
// Input area
// ===========================================================================

/// Render the message input area with send button and provider indicator.
let renderInputArea = (ai: aiState): Tea_Vdom.t<msg> => {
  let selectedProvider = AiEngine.selectProvider(ai.providers)
  div(
    list{Attrs.class_("border-t border-gray-800 p-4")},
    list{
      // Input row
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 bg-gray-900 border border-gray-700 rounded-lg px-4 py-3 text-sm text-gray-200 placeholder-gray-600 focus:outline-none focus:border-orange-500",
              ),
              Attrs.placeholder("Type a message..."),
              Attrs.value(ai.inputText),
              Events.onInput(text => Ai(SetAiInput(text))),
              KeyboardUtil.onEnterOrSpace(Ai(SendMessage)),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_(
                "px-6 py-3 bg-orange-600 hover:bg-orange-500 text-white rounded-lg text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed",
              ),
              Attrs.disabled(ai.loading || ai.inputText === ""),
              Events.onClick(Ai(SendMessage)),
              KeyboardNav.onActivate(Ai(SendMessage)),
            },
            list{text("Send")},
          ),
        },
      ),
      // Status bar
      div(
        list{Attrs.class_("flex items-center justify-between mt-2 text-xs text-gray-600")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              {
                switch selectedProvider {
                | Some(p) =>
                  span(
                    list{},
                    list{text(`${AiEngine.providerShortLabel(p.id)}: ${p.selectedModel}`)},
                  )
                | None => span(list{}, list{text("No provider")})
                }
              },
              span(
                list{},
                list{
                  text(
                    `${AiEngine.formatTokens(ai.totalInputTokens)} in / ${AiEngine.formatTokens(
                        ai.totalOutputTokens,
                      )} out`,
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    `px-2 py-1 rounded transition-colors ${ai.broadcastMode
                        ? "bg-orange-500/20 text-orange-300"
                        : "text-gray-600 hover:text-gray-400"}`,
                  ),
                  Events.onClick(Ai(ToggleBroadcast)),
                  KeyboardNav.onActivate(Ai(ToggleBroadcast)),
                },
                list{text("Broadcast")},
              ),
              button(
                list{
                  Attrs.class_("text-gray-600 hover:text-gray-400 transition-colors"),
                  Events.onClick(Ai(ClearAiHistory)),
                  KeyboardNav.onActivate(Ai(ClearAiHistory)),
                },
                list{text("Clear")},
              ),
            },
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Providers view
// ===========================================================================

/// Render the provider management view.
let renderProviders = (ai: aiState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-4")},
    list{
      div(
        list{Attrs.class_("space-y-4")},
        ai.providers
        ->AiEngine.sortByPriority
        ->Array.map(p => {
          let status = AiEngine.getProviderStatus(ai.providerStatuses, p.id)
          div(
            list{
              Attrs.class_(
                `border ${p.enabled ? "border-gray-700" : "border-gray-800"} rounded-lg p-4`,
              ),
            },
            list{
              // Provider header
              div(
                list{Attrs.class_("flex items-center justify-between mb-3")},
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-3")},
                    list{
                      div(
                        list{
                          Attrs.class_(`w-3 h-3 rounded-full ${AiEngine.statusDotClass(status)}`),
                        },
                        list{},
                      ),
                      div(
                        list{Attrs.class_("text-lg font-medium text-gray-200")},
                        list{text(AiEngine.providerLabel(p.id))},
                      ),
                      span(
                        list{
                          Attrs.class_(
                            `text-xs px-2 py-0.5 rounded ${AiEngine.providerBgColour(p.id)}`,
                          ),
                        },
                        list{text(`#${Int.toString(p.priority)}`)},
                      ),
                    },
                  ),
                  button(
                    list{
                      Attrs.class_(
                        `px-3 py-1 rounded text-sm transition-colors ${p.enabled
                            ? "bg-green-500/20 text-green-300 hover:bg-green-500/30"
                            : "bg-gray-700 text-gray-400 hover:bg-gray-600"}`,
                      ),
                      Events.onClick(Ai(ToggleAiProvider(p.id))),
                    },
                    list{text(p.enabled ? "Enabled" : "Disabled")},
                  ),
                },
              ),
              // Model selector
              div(
                list{Attrs.class_("flex items-center gap-2 mb-2")},
                list{
                  span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Model:")}),
                  div(
                    list{Attrs.class_("flex gap-1 flex-wrap")},
                    AiEngine.providerModels(p.id)
                    ->Array.map(m => {
                      button(
                        list{
                          Attrs.class_(
                            `px-2 py-1 text-xs rounded transition-colors ${p.selectedModel === m
                                ? "bg-orange-500/20 text-orange-300"
                                : "text-gray-500 hover:text-gray-300 hover:bg-gray-800"}`,
                          ),
                          Events.onClick(Ai(SetAiModel(p.id, m))),
                        },
                        list{text(m)},
                      )
                    })
                    ->List.fromArray,
                  ),
                },
              ),
              // Status line
              div(
                list{Attrs.class_("text-xs text-gray-600")},
                list{text(`Status: ${AiEngine.statusLabel(status)} | Env: ${p.envVar}`)},
              ),
              // Health check button
              button(
                list{
                  Attrs.class_("mt-2 text-xs text-gray-500 hover:text-gray-300 transition-colors"),
                  Events.onClick(Ai(CheckProvider(p.id))),
                },
                list{text("Check health")},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

// ===========================================================================
// System prompt view
// ===========================================================================

/// Render the system prompt editor.
let renderSystemPrompt = (ai: aiState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-4")},
    list{
      div(
        list{Attrs.class_("mb-4")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400 mb-2")},
            list{text("System Prompt (editable)")},
          ),
          textarea(
            list{
              Attrs.class_(
                "w-full h-48 bg-gray-900 border border-gray-700 rounded-lg px-4 py-3 text-sm text-gray-200 font-mono resize-y focus:outline-none focus:border-orange-500",
              ),
              Attrs.value(ai.systemPrompt),
              Events.onInput(text => Ai(SetSystemPrompt(text))),
            },
            list{},
          ),
        },
      ),
      {
        if ai.autoContext !== "" {
          div(
            list{Attrs.class_("mb-4")},
            list{
              div(
                list{Attrs.class_("text-sm text-gray-400 mb-2")},
                list{text("Auto-generated Context (from loaded repo)")},
              ),
              div(
                list{
                  Attrs.class_(
                    "w-full bg-gray-900/50 border border-gray-800 rounded-lg px-4 py-3 text-xs text-gray-500 font-mono max-h-96 overflow-y-auto whitespace-pre-wrap",
                  ),
                },
                list{text(ai.autoContext)},
              ),
            },
          )
        } else {
          noNode
        }
      },
    },
  )
}

// ===========================================================================
// Context view
// ===========================================================================

/// Render the context inspector.
let renderContext = (ai: aiState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-400 mb-4")},
        list{text("What the AI knows about the current session:")},
      ),
      div(
        list{Attrs.class_("space-y-4")},
        list{
          // Context sections
          div(
            list{Attrs.class_("border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
                list{text("Conversation History")},
              ),
              div(
                list{Attrs.class_("text-sm text-gray-300")},
                list{text(`${Int.toString(Array.length(ai.messages))} messages`)},
              ),
            },
          ),
          div(
            list{Attrs.class_("border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
                list{text("System Prompt Size")},
              ),
              div(
                list{Attrs.class_("text-sm text-gray-300")},
                list{text(`${Int.toString(String.length(ai.systemPrompt))} characters`)},
              ),
            },
          ),
          div(
            list{Attrs.class_("border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
                list{text("Auto Context")},
              ),
              div(
                list{Attrs.class_("text-sm text-gray-300")},
                list{
                  text(
                    ai.autoContext === ""
                      ? "None — load a repo to populate"
                      : `${Int.toString(String.length(ai.autoContext))} characters from repo`,
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
                list{text("Broadcast Mode")},
              ),
              div(
                list{Attrs.class_("text-sm text-gray-300")},
                list{
                  text(
                    ai.broadcastMode
                      ? "Enabled — sending to multiple providers"
                      : "Disabled — single provider",
                  ),
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Main view (full panel overlay)
// ===========================================================================

/// Render the full AI panel overlay with three-region layout.
let view = (ai: aiState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col")},
    list{
      // Header bar
      div(
        list{Attrs.class_("flex items-center justify-between px-6 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(list{Attrs.class_("text-lg font-light text-gray-200")}, list{text("AI Panel")}),
              {
                let selected = AiEngine.selectProvider(ai.providers)
                switch selected {
                | Some(p) =>
                  span(
                    list{
                      Attrs.class_(
                        `text-xs px-2 py-0.5 rounded ${AiEngine.providerBgColour(p.id)}`,
                      ),
                    },
                    list{text(AiEngine.providerShortLabel(p.id))},
                  )
                | None => noNode
                }
              },
              {
                if ai.broadcastMode {
                  span(
                    list{
                      Attrs.class_("text-xs px-2 py-0.5 rounded bg-orange-500/20 text-orange-300"),
                    },
                    list{text("Broadcast")},
                  )
                } else {
                  noNode
                }
              },
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
              KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
      // Category tabs
      renderCategoryTabBar(ai.activeCategory),
      // Main content area (sidebar + main region)
      div(
        list{Attrs.class_("flex-1 flex overflow-hidden")},
        list{
          // Left sidebar (always visible)
          renderSidebar(ai),
          // Main content (switches by category)
          div(
            list{Attrs.class_("flex-1 flex flex-col")},
            list{
              {
                switch ai.activeCategory {
                | Conversation => renderConversation(ai)
                | SystemPrompt => renderSystemPrompt(ai)
                | Providers => renderProviders(ai)
                | Context => renderContext(ai)
                }
              },
              {
                if ai.activeCategory === Conversation {
                  renderInputArea(ai)
                } else {
                  noNode
                }
              },
            },
          ),
        },
      ),
    },
  )
}
