// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Valence Shell Component — renders the embedded terminal panel.
///
/// The Valence Shell is a full-screen overlay panel providing:
///
/// 1. **Terminal** — PTY-backed terminal emulator with Claude Code integration.
///    When the xterm.js widget is wired (Phase 2), the terminal area will be
///    replaced by the real PTY. For now, it renders a styled output buffer
///    with an input line and command history navigation.
///
/// 2. **Recordings** — Browse, replay, export, and delete asciinema .cast
///    session recordings. Each recording shows duration, size, and creation date.
///
/// 3. **Checkpoints** — Valence filesystem save/restore points with formal
///    reversibility proofs. Create, list, and restore checkpoints.
///
/// 4. **History** — Command history with timestamps and reversibility markers.
///
/// 5. **Settings** — Shell backend selection, approval gate configuration,
///    split view toggle, and IDApTIK-specific completions.
///
/// Collaborative features:
/// - **Approval gate**: When enabled, commands queue for parent review before
///   execution. The child types, the parent approves — every command becomes
///   a teaching moment.
/// - **Session recording**: Record terminal sessions to .cast files for replay,
///   sharing, and teaching.
/// - **Screenshots**: Capture terminal state to the PanLL Capture panel.

open Model
open Msg
open Tea.Html

// =========================================================================
// Helper renderers
// =========================================================================

/// Render the category tab bar.
let renderTabs = (active: valenceShellCategory): Tea_Vdom.t<msg> => {
  let tabs: array<valenceShellCategory> = [
    ShellTerminal,
    ShellRecordings,
    ShellCheckpoints,
    ShellHistory,
    ShellSettings,
  ]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      let label = ValenceShellEngine.categoryLabel(tab)
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-emerald-400 border-b-2 border-emerald-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900"}`,
          ),
          Events.onClick(ValenceShell(SetShellCategory(tab))),
        },
        list{text(label)},
      )
    })
    ->List.fromArray,
  )
}

/// Render a single terminal output line.
let renderOutputLine = (line: terminalLine): Tea_Vdom.t<msg> => {
  let colour = line.isStdout ? "text-gray-200" : "text-red-400"
  div(
    list{Attrs.class_(`font-mono text-sm ${colour} whitespace-pre-wrap px-4 py-0.5`)},
    list{text(line.content)},
  )
}

/// Render the terminal view — output buffer + input line + toolbar.
let renderTerminal = (state: valenceShellState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 flex flex-col bg-gray-950")},
    list{
      // Backend status bar
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-4 py-2 bg-gray-900/50 border-b border-gray-800",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              // Connection indicator
              div(
                list{
                  Attrs.class_(
                    `w-2 h-2 rounded-full ${state.ptyConnected ? "bg-emerald-400" : "bg-gray-600"}`,
                  ),
                },
                list{},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(ValenceShellEngine.backendLabel(state.backend))},
              ),
              // CWD display
              span(list{Attrs.class_("text-xs text-gray-500 font-mono")}, list{text(state.cwd)}),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              // Recording indicator
              switch state.recording {
              | RecordingActive(_) =>
                div(
                  list{Attrs.class_("flex items-center gap-1")},
                  list{
                    div(
                      list{Attrs.class_("w-2 h-2 rounded-full bg-red-500 animate-pulse")},
                      list{},
                    ),
                    span(list{Attrs.class_("text-xs text-red-400")}, list{text("REC")}),
                    button(
                      list{
                        Attrs.class_("text-xs text-gray-400 hover:text-gray-200 px-2 py-1"),
                        Events.onClick(ValenceShell(StopRecordingSession)),
                      },
                      list{text("Stop")},
                    ),
                  },
                )
              | RecordingPaused(_) =>
                div(
                  list{Attrs.class_("flex items-center gap-1")},
                  list{
                    div(list{Attrs.class_("w-2 h-2 rounded-full bg-yellow-500")}, list{}),
                    span(list{Attrs.class_("text-xs text-yellow-400")}, list{text("PAUSED")}),
                  },
                )
              | RecordingIdle =>
                button(
                  list{
                    Attrs.class_(
                      "text-xs text-gray-500 hover:text-gray-300 px-2 py-1 rounded bg-gray-800",
                    ),
                    Events.onClick(ValenceShell(StartRecordingSession)),
                  },
                  list{text("Record")},
                )
              },
              // Screenshot button
              button(
                list{
                  Attrs.class_(
                    "text-xs text-gray-500 hover:text-gray-300 px-2 py-1 rounded bg-gray-800",
                  ),
                  Events.onClick(ValenceShell(ScreenshotTerminal)),
                },
                list{text("Screenshot")},
              ),
              // Approval gate indicator
              switch state.approvalGate {
              | GateDisabled => noNode
              | GateEnabled =>
                div(
                  list{Attrs.class_("flex items-center gap-1")},
                  list{
                    div(list{Attrs.class_("w-2 h-2 rounded-full bg-amber-400")}, list{}),
                    span(list{Attrs.class_("text-xs text-amber-400")}, list{text("GATE ON")}),
                  },
                )
              | GateLearning =>
                div(
                  list{Attrs.class_("flex items-center gap-1")},
                  list{
                    div(list{Attrs.class_("w-2 h-2 rounded-full bg-blue-400")}, list{}),
                    span(list{Attrs.class_("text-xs text-blue-400")}, list{text("LEARNING")}),
                  },
                )
              },
              // Claude Code indicator
              if state.claudeCodeActive {
                div(
                  list{Attrs.class_("flex items-center gap-1")},
                  list{
                    span(
                      list{Attrs.class_("text-xs text-purple-400 font-medium")},
                      list{text("Claude")},
                    ),
                  },
                )
              } else {
                noNode
              },
            },
          ),
        },
      ),
      // Terminal output area
      div(
        list{
          Attrs.class_("flex-1 overflow-auto bg-gray-950 py-2"),
          Attrs.id("valence-terminal-output"),
        },
        if Array.length(state.outputBuffer) === 0 {
          list{
            div(
              list{Attrs.class_("px-4 py-8 text-center")},
              list{
                div(list{Attrs.class_("text-gray-600 text-sm mb-2")}, list{text("Valence Shell")}),
                div(
                  list{Attrs.class_("text-gray-700 text-xs")},
                  list{
                    text(
                      state.valenceAvailable
                        ? "Formally verified reversible shell ready."
                        : "System shell mode (install valence-shell for reversible ops).",
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("text-gray-700 text-xs mt-1")},
                  list{text("Type a command or run `claude` to start Claude Code.")},
                ),
              },
            ),
          }
        } else {
          state.outputBuffer->Array.map(renderOutputLine)->List.fromArray
        },
      ),
      // Pending commands (approval gate)
      if Array.length(state.pendingCommands) > 0 {
        div(
          list{Attrs.class_("border-t border-amber-800/50 bg-amber-950/20 px-4 py-2")},
          list{
            div(
              list{Attrs.class_("text-xs text-amber-400 mb-2 font-medium")},
              list{
                text(
                  `${Int.toString(
                      Array.length(state.pendingCommands),
                    )} command(s) awaiting approval`,
                ),
              },
            ),
            div(
              list{Attrs.class_("space-y-1")},
              state.pendingCommands
              ->Array.mapWithIndex((cmd, idx) => {
                div(
                  list{
                    Attrs.class_("flex items-center justify-between bg-gray-900 rounded px-3 py-1"),
                  },
                  list{
                    span(
                      list{Attrs.class_("font-mono text-sm text-amber-200")},
                      list{text(cmd.command)},
                    ),
                    div(
                      list{Attrs.class_("flex gap-2")},
                      list{
                        button(
                          list{
                            Attrs.class_(
                              "text-xs px-2 py-1 rounded bg-emerald-800 text-emerald-200 hover:bg-emerald-700",
                            ),
                            Events.onClick(ValenceShell(ApproveCommand(idx))),
                          },
                          list{text("Approve")},
                        ),
                        button(
                          list{
                            Attrs.class_(
                              "text-xs px-2 py-1 rounded bg-red-800 text-red-200 hover:bg-red-700",
                            ),
                            Events.onClick(ValenceShell(RejectCommand(idx))),
                          },
                          list{text("Reject")},
                        ),
                      },
                    ),
                  },
                )
              })
              ->List.fromArray,
            ),
          },
        )
      } else {
        noNode
      },
      // Input line
      div(
        list{
          Attrs.class_("border-t border-gray-800 bg-gray-900 px-4 py-2 flex items-center gap-2"),
        },
        list{
          span(list{Attrs.class_("text-emerald-400 font-mono text-sm")}, list{text("$")}),
          input(
            list{
              Attrs.class_(
                "flex-1 bg-transparent text-gray-200 font-mono text-sm outline-none placeholder-gray-600",
              ),
              Attrs.type_("text"),
              Attrs.value(state.inputLine),
              Attrs.placeholder("Type a command..."),
              Events.onInput(value => ValenceShell(UpdateInput(value))),
              KeyboardUtil.onEnterOrSpace(ValenceShell(SubmitInput)),
              Attrs.id("valence-shell-input"),
              Attrs.ariaLabel("Shell command input"),
            },
            list{},
          ),
        },
      ),
      // Completions popup
      if (
        state.completionsVisible &&
        Array.length(ValenceShellEngine.filterCompletions(state.inputLine, state.completions)) > 0
      ) {
        let filtered = ValenceShellEngine.filterCompletions(state.inputLine, state.completions)
        div(
          list{
            Attrs.class_(
              "absolute bottom-16 left-4 right-16 bg-gray-800 border border-gray-700 rounded shadow-lg max-h-48 overflow-auto z-50",
            ),
          },
          filtered
          ->Array.map(completion => {
            button(
              list{
                Attrs.class_(
                  "block w-full text-left px-3 py-1.5 font-mono text-sm text-gray-300 hover:bg-gray-700 hover:text-gray-100",
                ),
                Events.onClick(ValenceShell(SelectCompletion(completion))),
              },
              list{text(completion)},
            )
          })
          ->List.fromArray,
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the recordings browser tab.
let renderRecordings = (state: valenceShellState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          h3(
            list{Attrs.class_("text-sm font-medium text-gray-300")},
            list{text("Session Recordings")},
          ),
          button(
            list{
              Attrs.class_(
                "text-xs text-gray-400 hover:text-gray-200 px-3 py-1 rounded bg-gray-800",
              ),
              Events.onClick(ValenceShell(LoadRecordings)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      if Array.length(state.recordings) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No recordings yet. Start one from the Terminal tab.")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          state.recordings
          ->Array.map(recording => {
            div(
              list{
                Attrs.class_(
                  "flex items-center justify-between bg-gray-900 rounded-lg px-4 py-3 border border-gray-800",
                ),
              },
              list{
                div(
                  list{Attrs.class_("flex-1")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-200 font-medium")},
                      list{text(recording.name)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mt-1")},
                      list{
                        text(
                          `${Float.toString(recording.durationSecs)}s | ${Int.toString(
                              recording.sizeBytes,
                            )} bytes`,
                        ),
                      },
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("flex gap-2")},
                  list{
                    button(
                      list{
                        Attrs.class_(
                          "text-xs text-gray-400 hover:text-gray-200 px-2 py-1 bg-gray-800 rounded",
                        ),
                        Events.onClick(ValenceShell(ExportRecordingAs(recording.id, "html"))),
                      },
                      list{text("Export HTML")},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          "text-xs text-red-400 hover:text-red-300 px-2 py-1 bg-gray-800 rounded",
                        ),
                        Events.onClick(ValenceShell(DeleteRecordingById(recording.id))),
                      },
                      list{text("Delete")},
                    ),
                  },
                ),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the checkpoints tab.
let renderCheckpoints = (state: valenceShellState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          h3(
            list{Attrs.class_("text-sm font-medium text-gray-300")},
            list{text("Valence Filesystem Checkpoints")},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    `text-xs px-3 py-1 rounded ${state.valenceAvailable
                        ? "bg-emerald-800 text-emerald-200 hover:bg-emerald-700"
                        : "bg-gray-800 text-gray-600 cursor-not-allowed"}`,
                  ),
                  Events.onClick(ValenceShell(CreateCheckpointWithLabel("manual"))),
                },
                list{text("Create Checkpoint")},
              ),
              button(
                list{
                  Attrs.class_(
                    "text-xs text-gray-400 hover:text-gray-200 px-3 py-1 rounded bg-gray-800",
                  ),
                  Events.onClick(ValenceShell(LoadCheckpoints)),
                },
                list{text("Refresh")},
              ),
            },
          ),
        },
      ),
      if !state.valenceAvailable {
        div(
          list{Attrs.class_("bg-amber-950/30 border border-amber-800/30 rounded-lg p-4 mb-4")},
          list{
            div(
              list{Attrs.class_("text-amber-400 text-sm font-medium mb-1")},
              list{text("Valence shell not installed")},
            ),
            div(
              list{Attrs.class_("text-amber-500/70 text-xs")},
              list{
                text("Checkpoints require the Valence shell binary for reversible filesystem ops."),
              },
            ),
          },
        )
      } else {
        noNode
      },
      if Array.length(state.checkpoints) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No checkpoints. Create one to save the current filesystem state.")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          state.checkpoints
          ->Array.map(cp => {
            div(
              list{
                Attrs.class_(
                  "flex items-center justify-between bg-gray-900 rounded-lg px-4 py-3 border border-gray-800",
                ),
              },
              list{
                div(
                  list{Attrs.class_("flex-1")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-200 font-medium")},
                      list{text(cp.label)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mt-1")},
                      list{
                        text(`${Int.toString(cp.opsSinceCheckpoint)} ops since this checkpoint`),
                      },
                    ),
                  },
                ),
                button(
                  list{
                    Attrs.class_(
                      "text-xs text-blue-400 hover:text-blue-300 px-3 py-1 bg-gray-800 rounded",
                    ),
                    Events.onClick(ValenceShell(RestoreCheckpointById(cp.id))),
                  },
                  list{text("Restore")},
                ),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the command history tab.
let renderHistory = (state: valenceShellState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      h3(
        list{Attrs.class_("text-sm font-medium text-gray-300 mb-4")},
        list{text("Command History")},
      ),
      if Array.length(state.commandHistory) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No commands executed yet.")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1")},
          state.commandHistory
          ->Array.mapWithIndex((cmd, idx) => {
            div(
              list{
                Attrs.class_(
                  "flex items-center gap-3 font-mono text-sm px-3 py-1.5 rounded hover:bg-gray-900",
                ),
              },
              list{
                span(
                  list{Attrs.class_("text-gray-600 w-8 text-right")},
                  list{text(Int.toString(idx + 1))},
                ),
                span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(cmd)}),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the settings tab.
let renderSettings = (state: valenceShellState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6 space-y-6")},
    list{
      // Shell backend section
      div(
        list{Attrs.class_("space-y-2")},
        list{
          h3(list{Attrs.class_("text-sm font-medium text-gray-300")}, list{text("Shell Backend")}),
          div(
            list{Attrs.class_("flex items-center gap-3 bg-gray-900 rounded-lg px-4 py-3")},
            list{
              div(
                list{
                  Attrs.class_(
                    `w-2 h-2 rounded-full ${state.valenceAvailable
                        ? "bg-emerald-400"
                        : "bg-gray-600"}`,
                  ),
                },
                list{},
              ),
              div(
                list{},
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-200")},
                    list{text(ValenceShellEngine.backendLabel(state.backend))},
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
                    list{
                      text(
                        state.valenceAvailable
                          ? "Valence shell provides formally verified reversible filesystem operations."
                          : "Install valence-shell for reversible ops, MAA audit trail, and checkpoints.",
                      ),
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Approval gate section
      div(
        list{Attrs.class_("space-y-2")},
        list{
          h3(
            list{Attrs.class_("text-sm font-medium text-gray-300")},
            list{text("Approval Gate (Collaborative Mode)")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500 mb-2")},
            list{
              text(
                "When enabled, commands must be approved before execution. Ideal for parent-child collaborative sessions.",
              ),
            },
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    `px-3 py-1.5 text-xs rounded ${state.approvalGate === GateDisabled
                        ? "bg-gray-700 text-gray-200"
                        : "bg-gray-900 text-gray-500"}`,
                  ),
                  Events.onClick(ValenceShell(SetApprovalGate(GateDisabled))),
                },
                list{text("Disabled")},
              ),
              button(
                list{
                  Attrs.class_(
                    `px-3 py-1.5 text-xs rounded ${state.approvalGate === GateEnabled
                        ? "bg-amber-800 text-amber-200"
                        : "bg-gray-900 text-gray-500"}`,
                  ),
                  Events.onClick(ValenceShell(SetApprovalGate(GateEnabled))),
                },
                list{text("Enabled")},
              ),
              button(
                list{
                  Attrs.class_(
                    `px-3 py-1.5 text-xs rounded ${state.approvalGate === GateLearning
                        ? "bg-blue-800 text-blue-200"
                        : "bg-gray-900 text-gray-500"}`,
                  ),
                  Events.onClick(ValenceShell(SetApprovalGate(GateLearning))),
                },
                list{text("Learning")},
              ),
            },
          ),
        },
      ),
      // Split view section
      div(
        list{Attrs.class_("flex items-center justify-between bg-gray-900 rounded-lg px-4 py-3")},
        list{
          div(
            list{},
            list{
              div(list{Attrs.class_("text-sm text-gray-200")}, list{text("Split View")}),
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
                list{text("Show two terminal instances side by side.")},
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                `px-3 py-1.5 text-xs rounded ${state.splitView
                    ? "bg-emerald-800 text-emerald-200"
                    : "bg-gray-800 text-gray-500"}`,
              ),
              Events.onClick(ValenceShell(ToggleSplitView)),
            },
            list{text(state.splitView ? "On" : "Off")},
          ),
        },
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Render the Valence Shell panel as a full-screen overlay.
let view = (state: valenceShellState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/98 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Valence Shell — embedded terminal with Claude Code integration"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              // Terminal icon placeholder (text-based for now)
              div(
                list{
                  Attrs.class_("w-6 h-6 rounded bg-emerald-900 flex items-center justify-center"),
                },
                list{
                  span(list{Attrs.class_("text-emerald-400 text-xs font-bold")}, list{text(">_")}),
                },
              ),
              div(
                list{},
                list{
                  h2(
                    list{Attrs.class_("text-lg font-medium text-gray-200")},
                    list{text("Valence Shell")},
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{text("Embedded terminal with Claude Code integration")},
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              // Claude Code quick-launch button
              if !state.claudeCodeActive {
                button(
                  list{
                    Attrs.class_(
                      "text-xs px-3 py-1.5 rounded bg-purple-900 text-purple-200 hover:bg-purple-800",
                    ),
                    Events.onClick(ValenceShell(LaunchClaudeCode)),
                  },
                  list{text("Launch Claude")},
                )
              } else {
                noNode
              },
              // Close button
              button(
                list{
                  Attrs.class_(
                    "text-gray-500 hover:text-gray-300 px-3 py-1.5 text-sm rounded bg-gray-800 hover:bg-gray-700",
                  ),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("px-4 py-2 bg-red-950 border-b border-red-900")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                span(list{Attrs.class_("text-red-400 text-sm")}, list{text(err)}),
                button(
                  list{
                    Attrs.class_("text-red-500 hover:text-red-400 text-xs"),
                    Events.onClick(ValenceShell(DismissError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Tab bar
      renderTabs(state.activeCategory),
      // Content area — switches on active category
      switch state.activeCategory {
      | ShellTerminal => renderTerminal(state)
      | ShellRecordings => renderRecordings(state)
      | ShellCheckpoints => renderCheckpoints(state)
      | ShellHistory => renderHistory(state)
      | ShellSettings => renderSettings(state)
      },
    },
  )
}
