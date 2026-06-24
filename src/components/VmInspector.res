// SPDX-License-Identifier: MPL-2.0

/// PanLL VM Inspector Component — renders the reversible VM visual debugger.
///
/// The Debugger tab shows stack, memory, instruction listing, and step
/// controls (forward AND backward). The Timeline tab provides a scrubber
/// over execution history. Call Graph shows subroutine relationships.
/// Port I/O monitors SEND/RECV buffers. Statistics shows per-instruction
/// and per-tier execution counts.

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Render the category tab bar.
let renderTabs = (active: vmInspectorCategory): Tea_Vdom.t<msg> => {
  let tabs: array<vmInspectorCategory> = [
    InspectorDebugger,
    InspectorTimeline,
    InspectorCallGraph,
    InspectorPortIO,
    InspectorStatistics,
  ]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      let label = VmInspectorEngine.categoryLabel(tab)
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-orange-400 border-b-2 border-orange-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900"}`,
          ),
          Events.onClick(VmInspector(SetInspectorCategory(tab))),
        },
        list{text(label)},
      )
    })
    ->List.fromArray,
  )
}

/// Render the step controls toolbar.
let renderStepControls = (state: vmInspectorState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2")},
    list{
      // Step backward
      button(
        list{
          Attrs.class_(
            "px-3 py-1.5 text-xs rounded bg-amber-800 text-amber-200 hover:bg-amber-700 font-medium",
          ),
          Events.onClick(VmInspector(StepBackward)),
          KeyboardNav.onActivate(VmInspector(StepBackward)),
        },
        list{text("Step Back")},
      ),
      // Step forward
      button(
        list{
          Attrs.class_(
            "px-3 py-1.5 text-xs rounded bg-emerald-800 text-emerald-200 hover:bg-emerald-700 font-medium",
          ),
          Events.onClick(VmInspector(StepForward)),
          KeyboardNav.onActivate(VmInspector(StepForward)),
        },
        list{text("Step Forward")},
      ),
      // Run to breakpoint
      button(
        list{
          Attrs.class_(
            `px-3 py-1.5 text-xs rounded font-medium ${state.running
                ? "bg-red-800 text-red-200 hover:bg-red-700"
                : "bg-blue-800 text-blue-200 hover:bg-blue-700"}`,
          ),
          Events.onClick(
            VmInspector(
              if state.running {
                PauseVm
              } else {
                RunVm
              },
            ),
          ),
        },
        list{
          text(
            if state.running {
              "Pause"
            } else {
              "Run"
            },
          ),
        },
      ),
      // Reset
      button(
        list{
          Attrs.class_("px-3 py-1.5 text-xs rounded bg-gray-800 text-gray-400 hover:text-gray-200"),
          Events.onClick(VmInspector(ResetVm)),
          KeyboardNav.onActivate(VmInspector(ResetVm)),
        },
        list{text("Reset")},
      ),
      // Step counter
      div(
        list{Attrs.class_("ml-4 flex items-center gap-2")},
        list{
          span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Step:")}),
          span(
            list{Attrs.class_("text-xs text-gray-300 font-mono")},
            list{text(Int.toString(state.totalSteps))},
          ),
          span(list{Attrs.class_("text-xs text-gray-500 ml-2")}, list{text("PC:")}),
          span(
            list{Attrs.class_("text-xs text-orange-400 font-mono")},
            list{text(Int.toString(state.pc))},
          ),
        },
      ),
    },
  )
}

/// Render the stack visualisation.
let renderStack = (stack: array<int>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-3")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2 font-medium")},
        list{text(`Stack (${Int.toString(Array.length(stack))})`)},
      ),
      if Array.length(stack) === 0 {
        div(list{Attrs.class_("text-gray-600 text-xs italic")}, list{text("(empty)")})
      } else {
        div(
          list{Attrs.class_("space-y-0.5")},
          // Show stack top-first (reversed)
          stack
          ->Array.toReversed
          ->Array.mapWithIndex((value, idx) => {
            div(
              list{
                Attrs.class_(
                  `flex items-center gap-2 font-mono text-sm px-2 py-0.5 rounded ${idx === 0
                      ? "bg-orange-900/30 text-orange-300"
                      : "text-gray-300"}`,
                ),
              },
              list{
                span(
                  list{Attrs.class_("text-gray-600 w-6 text-right text-xs")},
                  list{
                    text(
                      if idx === 0 {
                        "TOS"
                      } else {
                        Int.toString(Array.length(stack) - 1 - idx)
                      },
                    ),
                  },
                ),
                span(list{}, list{text(Int.toString(value))}),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the memory grid.
let renderMemory = (memory: array<vmMemoryCell>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-3")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2 font-medium")},
        list{text(`Memory (${Int.toString(Array.length(memory))} cells)`)},
      ),
      if Array.length(memory) === 0 {
        div(list{Attrs.class_("text-gray-600 text-xs italic")}, list{text("No memory allocated")})
      } else {
        div(
          list{Attrs.class_("grid grid-cols-8 gap-0.5")},
          memory
          ->Array.map(cell => {
            let bgClass = if cell.recentWrite {
              "bg-red-900/50"
            } else if cell.recentRead {
              "bg-blue-900/50"
            } else if cell.value !== 0 {
              "bg-gray-800"
            } else {
              "bg-gray-900"
            }
            div(
              list{
                Attrs.class_(`${bgClass} rounded px-1 py-0.5 text-center font-mono text-xs`),
                Attrs.title(
                  `Address: ${Int.toString(cell.address)}, Value: ${Int.toString(cell.value)}`,
                ),
              },
              list{
                span(
                  list{
                    Attrs.class_(
                      if cell.value !== 0 {
                        "text-gray-200"
                      } else {
                        "text-gray-700"
                      },
                    ),
                  },
                  list{text(Int.toString(cell.value))},
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

/// Render the instruction listing.
let renderInstructions = (instructions: array<vmInstruction>, pc: int): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-3")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2 font-medium")},
        list{text(`Instructions (${Int.toString(Array.length(instructions))})`)},
      ),
      if Array.length(instructions) === 0 {
        div(list{Attrs.class_("text-gray-600 text-xs italic")}, list{text("No program loaded")})
      } else {
        div(
          list{Attrs.class_("space-y-0.5 max-h-64 overflow-auto")},
          instructions
          ->Array.map(instr => {
            let isCurrentPc = instr.index === pc
            let tierColour = VmInspectorEngine.tierColour(instr.tier)
            div(
              list{
                Attrs.class_(
                  `flex items-center gap-2 font-mono text-sm px-2 py-0.5 rounded cursor-pointer hover:bg-gray-800 ${isCurrentPc
                      ? "bg-orange-900/40 border-l-2 border-orange-400"
                      : ""}`,
                ),
                Events.onClick(VmInspector(ToggleBreakpoint(instr.index))),
              },
              list{
                // Breakpoint indicator
                div(
                  list{
                    Attrs.class_(
                      `w-2 h-2 rounded-full ${instr.hasBreakpoint
                          ? "bg-red-500"
                          : "bg-transparent"}`,
                    ),
                  },
                  list{},
                ),
                // Address
                span(
                  list{Attrs.class_("text-gray-600 w-8 text-right text-xs")},
                  list{text(Int.toString(instr.index))},
                ),
                // Tier badge
                span(
                  list{Attrs.class_(`text-xs ${tierColour} w-6`)},
                  list{text(VmInspectorEngine.tierShortLabel(instr.tier))},
                ),
                // Mnemonic
                span(
                  list{
                    Attrs.class_(
                      if isCurrentPc {
                        "text-orange-300 font-bold"
                      } else {
                        "text-gray-300"
                      },
                    ),
                  },
                  list{text(instr.mnemonic)},
                ),
                // Execution count
                if instr.executionCount > 0 {
                  span(
                    list{Attrs.class_("text-gray-600 text-xs ml-auto")},
                    list{text(`x${Int.toString(instr.executionCount)}`)},
                  )
                } else {
                  noNode
                },
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the main debugger view — stack + memory + instructions + controls.
let renderDebugger = (state: vmInspectorState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 flex flex-col")},
    list{
      // Step controls toolbar
      div(
        list{
          Attrs.class_(
            "px-4 py-2 bg-gray-900/50 border-b border-gray-800 flex items-center justify-between",
          ),
        },
        list{
          renderStepControls(state),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              // Connection status
              div(
                list{Attrs.class_("flex items-center gap-1")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        `w-2 h-2 rounded-full ${switch state.connection {
                          | VmLiveConnection => "bg-emerald-400"
                          | VmFileConnection(_) => "bg-blue-400"
                          | VmDisconnected => "bg-gray-600"
                          }}`,
                      ),
                    },
                    list{},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-400")},
                    list{text(VmInspectorEngine.connectionLabel(state.connection))},
                  ),
                },
              ),
              // Export snapshot button
              button(
                list{
                  Attrs.class_(
                    "text-xs text-gray-500 hover:text-gray-300 px-2 py-1 rounded bg-gray-800",
                  ),
                  Events.onClick(VmInspector(ExportSnapshot)),
                  KeyboardNav.onActivate(VmInspector(ExportSnapshot)),
                },
                list{text("Export State")},
              ),
              // Multi-VM toggle
              button(
                list{
                  Attrs.class_(
                    `text-xs px-2 py-1 rounded ${state.multiVmView
                        ? "bg-purple-800 text-purple-200"
                        : "bg-gray-800 text-gray-500"}`,
                  ),
                  Events.onClick(VmInspector(ToggleMultiVm)),
                  KeyboardNav.onActivate(VmInspector(ToggleMultiVm)),
                },
                list{text("Multi-VM")},
              ),
              // BoJ routing toggle
              button(
                list{
                  Attrs.class_(
                    if state.bojRouting {
                      "px-3 py-1.5 text-xs bg-blue-700 text-white rounded"
                    } else {
                      "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600"
                    },
                  ),
                  Attrs.ariaLabel(
                    if state.bojRouting {
                      "Disable BoJ routing"
                    } else {
                      "Enable BoJ routing"
                    },
                  ),
                  Events.onClick(VmInspector(ToggleVmBojRouting)),
                  KeyboardNav.onActivate(VmInspector(ToggleVmBojRouting)),
                },
                list{
                  text(
                    if state.bojRouting {
                      "BoJ On"
                    } else {
                      "BoJ"
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Three-column layout: Stack | Instructions | Memory
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4 grid grid-cols-3 gap-4")},
        list{
          renderStack(state.stack),
          renderInstructions(state.instructions, state.pc),
          renderMemory(state.memory),
        },
      ),
    },
  )
}

/// Render the execution timeline tab.
let renderTimeline = (state: vmInspectorState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      h3(
        list{Attrs.class_("text-sm font-medium text-gray-300 mb-4")},
        list{text(`Execution Timeline (${Int.toString(Array.length(state.history))} snapshots)`)},
      ),
      if Array.length(state.history) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No execution history. Step through instructions to build the timeline.")},
        )
      } else {
        div(
          list{},
          list{
            // Timeline scrubber
            div(
              list{Attrs.class_("mb-4")},
              list{
                div(
                  list{
                    Attrs.class_("flex items-center justify-between text-xs text-gray-500 mb-1"),
                  },
                  list{
                    text("Step 0"),
                    text(`Step ${Int.toString(Array.length(state.history) - 1)}`),
                  },
                ),
                div(
                  list{Attrs.class_("h-2 bg-gray-800 rounded-full relative")},
                  list{
                    div(
                      list{
                        Attrs.class_("absolute top-0 left-0 h-2 bg-orange-500 rounded-full"),
                        Attrs.style(
                          "width",
                          `${if Array.length(state.history) > 0 {
                              Float.toString(
                                Int.toFloat(state.timelinePosition) /.
                                Int.toFloat(Array.length(state.history) - 1) *. 100.0,
                              )
                            } else {
                              "0"
                            }}%`,
                        ),
                      },
                      list{},
                    ),
                  },
                ),
              },
            ),
            // Current snapshot details
            switch state.history->Array.get(state.timelinePosition) {
            | Some(snapshot) =>
              div(
                list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-4")},
                list{
                  div(
                    list{Attrs.class_("grid grid-cols-3 gap-4 text-sm")},
                    list{
                      div(
                        list{},
                        list{
                          div(list{Attrs.class_("text-gray-500 text-xs mb-1")}, list{text("Step")}),
                          div(
                            list{Attrs.class_("font-mono text-gray-200")},
                            list{text(Int.toString(snapshot.step))},
                          ),
                        },
                      ),
                      div(
                        list{},
                        list{
                          div(
                            list{Attrs.class_("text-gray-500 text-xs mb-1")},
                            list{text("Instruction")},
                          ),
                          div(
                            list{Attrs.class_("font-mono text-orange-300")},
                            list{text(snapshot.instructionMnemonic)},
                          ),
                        },
                      ),
                      div(
                        list{},
                        list{
                          div(
                            list{Attrs.class_("text-gray-500 text-xs mb-1")},
                            list{text("Stack")},
                          ),
                          div(
                            list{Attrs.class_("font-mono text-gray-200")},
                            list{text(VmInspectorEngine.formatStack(snapshot.stack))},
                          ),
                        },
                      ),
                    },
                  ),
                },
              )
            | None => noNode
            },
            // Navigation buttons
            div(
              list{Attrs.class_("flex items-center justify-center gap-4 mt-4")},
              list{
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-sm rounded bg-gray-800 text-gray-300 hover:bg-gray-700",
                    ),
                    Events.onClick(VmInspector(SeekTimeline(0))),
                  },
                  list{text("Start")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-sm rounded bg-gray-800 text-gray-300 hover:bg-gray-700",
                    ),
                    Events.onClick(
                      VmInspector(
                        SeekTimeline(
                          if state.timelinePosition > 0 {
                            state.timelinePosition - 1
                          } else {
                            0
                          },
                        ),
                      ),
                    ),
                  },
                  list{text("Prev")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-sm rounded bg-gray-800 text-gray-300 hover:bg-gray-700",
                    ),
                    Events.onClick(VmInspector(SeekTimeline(state.timelinePosition + 1))),
                  },
                  list{text("Next")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-sm rounded bg-gray-800 text-gray-300 hover:bg-gray-700",
                    ),
                    Events.onClick(VmInspector(SeekTimeline(Array.length(state.history) - 1))),
                  },
                  list{text("End")},
                ),
              },
            ),
          },
        )
      },
    },
  )
}

/// Render the port I/O tab.
let renderPortIO = (state: vmInspectorState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      h3(
        list{Attrs.class_("text-sm font-medium text-gray-300 mb-4")},
        list{text(`Port I/O (${Int.toString(Array.length(state.portLog))} entries)`)},
      ),
      if Array.length(state.portLog) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No port I/O recorded. Execute SEND/RECV instructions.")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-0.5")},
          state.portLog
          ->Array.map(entry => {
            div(
              list{
                Attrs.class_(
                  "flex items-center gap-3 font-mono text-sm px-3 py-1 rounded bg-gray-900/50",
                ),
              },
              list{
                span(
                  list{Attrs.class_("text-gray-600 w-12 text-right text-xs")},
                  list{text(`@${Int.toString(entry.atStep)}`)},
                ),
                span(
                  list{
                    Attrs.class_(
                      if entry.isSend {
                        "text-red-400 w-12"
                      } else {
                        "text-emerald-400 w-12"
                      },
                    ),
                  },
                  list{
                    text(
                      if entry.isSend {
                        "SEND"
                      } else {
                        "RECV"
                      },
                    ),
                  },
                ),
                span(
                  list{Attrs.class_("text-gray-500 w-12")},
                  list{text(`port ${Int.toString(entry.port)}`)},
                ),
                span(list{Attrs.class_("text-gray-300")}, list{text(Int.toString(entry.value))}),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the statistics tab — placeholder for charts.
let renderStatistics = (state: vmInspectorState): Tea_Vdom.t<msg> => {
  let tiers: array<vmInstructionTier> = [
    TierArithmetic,
    TierConditionals,
    TierStackMemory,
    TierSubroutines,
    TierIO,
  ]
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      h3(
        list{Attrs.class_("text-sm font-medium text-gray-300 mb-4")},
        list{text("Execution Statistics")},
      ),
      // Tier usage cards
      div(
        list{Attrs.class_("grid grid-cols-5 gap-3 mb-6")},
        tiers
        ->Array.mapWithIndex((tier, idx) => {
          let count = switch state.tierCounts->Array.get(idx) {
          | Some(c) => c
          | None => 0
          }
          let colour = VmInspectorEngine.tierColour(tier)
          div(
            list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-3 text-center")},
            list{
              div(
                list{Attrs.class_(`text-xs ${colour} mb-1`)},
                list{text(VmInspectorEngine.tierShortLabel(tier))},
              ),
              div(
                list{Attrs.class_("text-lg font-bold text-gray-200")},
                list{text(Int.toString(count))},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-600 mt-1")},
                list{text(VmInspectorEngine.tierLabel(tier))},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
      // Total steps
      div(
        list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-4")},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between")},
            list{
              span(list{Attrs.class_("text-sm text-gray-400")}, list{text("Total Steps")}),
              span(
                list{Attrs.class_("text-xl font-bold text-gray-200 font-mono")},
                list{text(Int.toString(state.totalSteps))},
              ),
            },
          ),
        },
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Render the VM Inspector panel as a full-screen overlay.
let view = (state: vmInspectorState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/98 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel(
        "VM Inspector — reversible VM visual debugger with step forward and backward",
      ),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(
                list{
                  Attrs.class_("w-6 h-6 rounded bg-orange-900 flex items-center justify-center"),
                },
                list{
                  span(list{Attrs.class_("text-orange-400 text-xs font-bold")}, list{text("VM")}),
                },
              ),
              div(
                list{},
                list{
                  h2(
                    list{Attrs.class_("text-lg font-medium text-gray-200")},
                    list{text("VM Inspector")},
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{
                      text(
                        "Reversible VM debugger — 23 instructions, 5 tiers, step forward and backward",
                      ),
                    },
                  ),
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                "text-gray-500 hover:text-gray-300 px-3 py-1.5 text-sm rounded bg-gray-800 hover:bg-gray-700",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
              KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
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
                    Events.onClick(VmInspector(DismissVmError)),
                    KeyboardNav.onActivate(VmInspector(DismissVmError)),
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
      // Content
      switch state.activeCategory {
      | InspectorDebugger => renderDebugger(state)
      | InspectorTimeline => renderTimeline(state)
      | InspectorCallGraph =>
        div(
          list{Attrs.class_("flex-1 flex items-center justify-center")},
          list{
            div(
              list{Attrs.class_("text-gray-600 text-sm")},
              list{text("Call graph visualisation — coming in Phase 2.")},
            ),
          },
        )
      | InspectorPortIO => renderPortIO(state)
      | InspectorStatistics => renderStatistics(state)
      },
    },
  )
}
