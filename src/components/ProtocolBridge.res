// SPDX-License-Identifier: MPL-2.0

/// PanLL Protocol Bridge Component — multiplayer sync protocol analysis.
/// Displays channel list with status dots, message log, latency display,
/// and protocol rules.

open Model
open Msg
open Tea.Html

/// Render a channel status dot (green for active, red for error/disconnected).
let channelStatusDot = (status: channelStatus): Tea_Vdom.t<msg> => {
  let color = switch status {
  | ChannelActive => "bg-green-500"
  | ChannelIdle => "bg-green-700"
  | ChannelDegraded => "bg-yellow-500"
  | ChannelDisconnected => "bg-red-500"
  | ChannelError => "bg-red-600 animate-pulse"
  }
  span(list{Attrs.class_("w-2.5 h-2.5 rounded-full inline-block " ++ color)}, list{})
}

/// Render a channel status label.
let channelStatusLabel = (status: channelStatus): string => {
  switch status {
  | ChannelActive => "Active"
  | ChannelIdle => "Idle"
  | ChannelDegraded => "Degraded"
  | ChannelDisconnected => "Disconnected"
  | ChannelError => "Error"
  }
}

/// Render a protocol rule status badge.
let ruleStatusBadge = (status: protocolRuleStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | RuleVerified => ("bg-green-700 text-green-100", "Verified")
  | RuleUnverified => ("bg-gray-700 text-gray-300", "Unverified")
  | RuleViolated => ("bg-red-700 text-red-100", "Violated")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Main view function for the Protocol Bridge panel.
let view = (state: protocolBridgeState): Tea_Vdom.t<msg> => {
  let activeChannels = state.channels->Array.filter(c => c.status == ChannelActive)->Array.length
  let totalChannels = Array.length(state.channels)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Protocol Bridge — Multiplayer Sync Protocol Analysis"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-sky-300")},
                list{text("Protocol Bridge")},
              ),
              span(
                list{
                  Attrs.class_(
                    "text-xs " ++ if state.connected {
                      "text-green-400"
                    } else {
                      "text-red-400"
                    },
                  ),
                },
                list{
                  text(
                    if state.connected {
                      "Monitor active"
                    } else {
                      "Disconnected"
                    },
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(activeChannels) ++
                    "/" ++
                    Int.toString(totalChannels) ++ " channels active",
                  ),
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-sky-800 hover:bg-sky-700 text-white rounded"),
              Events.onClick(ProtocolBridge(PbStarted)),
              KeyboardNav.onActivate(ProtocolBridge(PbStarted)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Channels {
                  "bg-sky-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProtocolBridge(SetPbTab(Channels))),
            },
            list{text("Channels")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Messages {
                  "bg-sky-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProtocolBridge(SetPbTab(Messages))),
            },
            list{text("Messages")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Latency {
                  "bg-sky-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProtocolBridge(SetPbTab(Latency))),
            },
            list{text("Latency")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Rules {
                  "bg-sky-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(ProtocolBridge(SetPbTab(Rules))),
            },
            list{text("Rules")},
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center",
            ),
          },
          list{
            text(err),
            button(
              list{
                Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"),
                Events.onClick(ProtocolBridge(DismissPbError)),
                KeyboardNav.onActivate(ProtocolBridge(DismissPbError)),
              },
              list{text("Dismiss")},
            ),
          },
        )
      | None => Tea_Html.noNode
      },
      // Content area
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-4")},
        list{
          switch state.activeTab {
          | Channels =>
            div(
              list{Attrs.class_("space-y-2")},
              state.channels
              ->Array.map(ch =>
                div(
                  list{
                    Attrs.class_(
                      "flex items-center gap-3 px-3 py-2 bg-gray-900 border border-gray-800 rounded",
                    ),
                  },
                  list{
                    channelStatusDot(ch.status),
                    div(
                      list{Attrs.class_("flex-1 min-w-0")},
                      list{
                        div(list{Attrs.class_("text-sm text-gray-200")}, list{text(ch.name)}),
                        div(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{
                            text(
                              ch.protocol ++
                              " | " ++
                              Int.toString(ch.subscribers) ++ " subscribers",
                            ),
                          },
                        ),
                      },
                    ),
                    span(
                      list{Attrs.class_("text-xs text-gray-400")},
                      list{text(channelStatusLabel(ch.status))},
                    ),
                    span(
                      list{
                        Attrs.class_(
                          "text-xs font-mono " ++ if ch.latencyMs > 100.0 {
                            "text-red-400"
                          } else if ch.latencyMs > 50.0 {
                            "text-yellow-400"
                          } else {
                            "text-green-400"
                          },
                        ),
                      },
                      list{text(Float.toFixed(ch.latencyMs, ~digits=1) ++ "ms")},
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          | Messages =>
            div(
              list{Attrs.class_("space-y-1")},
              state.messageLog
              ->Array.map(m => {
                let dirLabel = switch m.direction {
                | MessageInbound => "IN"
                | MessageOutbound => "OUT"
                }
                let dirColor = switch m.direction {
                | MessageInbound => "text-blue-400"
                | MessageOutbound => "text-green-400"
                }
                div(
                  list{
                    Attrs.class_(
                      "flex items-center gap-2 py-1 border-b border-gray-800/30 text-xs",
                    ),
                  },
                  list{
                    span(list{Attrs.class_("font-mono w-8 " ++ dirColor)}, list{text(dirLabel)}),
                    span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(m.messageType)}),
                    span(
                      list{Attrs.class_("text-gray-500 font-mono")},
                      list{text(Int.toString(m.payloadBytes) ++ "B")},
                    ),
                    if !m.valid {
                      span(list{Attrs.class_("text-red-400")}, list{text("INVALID")})
                    } else {
                      span(list{Attrs.class_("text-green-600")}, list{text("OK")})
                    },
                  },
                )
              })
              ->List.fromArray,
            )
          | Latency =>
            div(
              list{Attrs.class_("space-y-1")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-400 mb-3")},
                  list{
                    text(
                      Int.toString(
                        Array.length(state.latencySamples),
                      ) ++ " latency samples recorded",
                    ),
                  },
                ),
                div(
                  list{},
                  state.latencySamples
                  ->Array.map(sample =>
                    div(
                      list{
                        Attrs.class_("flex items-center gap-3 py-1 border-b border-gray-800/30"),
                      },
                      list{
                        span(
                          list{Attrs.class_("text-xs text-gray-500 font-mono w-24")},
                          list{text(sample.channelId)},
                        ),
                        // Latency bar
                        div(
                          list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded overflow-hidden")},
                          list{
                            div(
                              list{
                                Attrs.class_(
                                  "h-full " ++ if sample.exceededThreshold {
                                    "bg-red-500"
                                  } else {
                                    "bg-sky-500"
                                  },
                                ),
                                Attrs.style(
                                  "width",
                                  Float.toFixed(
                                    Math.min(sample.latencyMs /. 2.0, 100.0),
                                    ~digits=1,
                                  ) ++ "%",
                                ),
                              },
                              list{},
                            ),
                          },
                        ),
                        span(
                          list{
                            Attrs.class_(
                              "text-xs font-mono w-16 text-right " ++ if sample.exceededThreshold {
                                "text-red-400"
                              } else {
                                "text-gray-400"
                              },
                            ),
                          },
                          list{text(Float.toFixed(sample.latencyMs, ~digits=1) ++ "ms")},
                        ),
                      },
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          | Rules =>
            div(
              list{Attrs.class_("space-y-2")},
              state.protocolRules
              ->Array.map(r =>
                div(
                  list{Attrs.class_("flex items-center gap-3 py-2 border-b border-gray-800/50")},
                  list{
                    ruleStatusBadge(r.status),
                    div(
                      list{Attrs.class_("flex-1 min-w-0")},
                      list{
                        div(list{Attrs.class_("text-sm text-gray-200")}, list{text(r.name)}),
                        div(list{Attrs.class_("text-xs text-gray-500")}, list{text(r.description)}),
                      },
                    ),
                    span(
                      list{Attrs.class_("text-xs text-sky-400 font-mono")},
                      list{text(r.expression)},
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          },
        },
      ),
    },
  )
}
