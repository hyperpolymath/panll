// SPDX-License-Identifier: MPL-2.0

/// PanLL BoJ Component — view for the Bundle of Joy cartridge server panel.
///
/// 5 tabs: Dashboard, Cartridges (17×10 matrix), Topology, Federation, Invoke.
/// All views use Tea_Html (no JSX). Accessible with ARIA roles and labels.

open Msg
open BojModel
open BojEngine
open Tea.Html

// ===========================================================================
// TypeLL Cross-Panel Type Intelligence
// ===========================================================================

/// Render TypeLL cross-panel type intelligence result (if available).
/// Parses the raw JSON via TypeLLEngine.parseCheckResult and displays an
/// evangeliser-style narrative with proof obligations and linearity notes.
let viewTypeCheckResult = (lastTypeCheck: option<string>): Tea_Vdom.t<msg> => {
  switch lastTypeCheck {
  | None => noNode
  | Some(json) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Error(_) => noNode
    | Ok(result) =>
      let narrative = TypeLLEngine.generateNarrative(result)
      let borderColour = if result.valid {
        "border-green-700 bg-green-900/20"
      } else {
        "border-red-700 bg-red-900/20"
      }
      let labelColour = if result.valid {
        "text-green-400"
      } else {
        "text-red-400"
      }
      let statusText = if result.valid {
        "Type-safe"
      } else {
        "Type issues detected"
      }
      div(
        list{Attrs.class_("mt-4 p-3 rounded-lg border " ++ borderColour)},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-2")},
            list{
              span(
                list{Attrs.class_("text-xs font-bold uppercase tracking-wider " ++ labelColour)},
                list{text("TypeLL")},
              ),
              span(list{Attrs.class_("text-xs text-gray-400")}, list{text(statusText)}),
            },
          ),
          div(
            list{Attrs.class_("text-sm text-gray-300 font-mono mb-1")},
            list{text(result.typeSignature)},
          ),
          div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text(narrative.celebrate)}),
          if Array.length(result.proofObligations) > 0 {
            div(
              list{Attrs.class_("text-xs text-yellow-400 mt-1")},
              list{text("Proof obligations: " ++ Array.join(result.proofObligations, ", "))},
            )
          } else {
            noNode
          },
          if Array.length(result.linearityIssues) > 0 {
            div(
              list{Attrs.class_("text-xs text-orange-400 mt-1")},
              list{text("Linearity: " ++ Array.join(result.linearityIssues, ", "))},
            )
          } else {
            noNode
          },
        },
      )
    }
  }
}

/// Render a tab button.
let renderTab = (label: string, active: bool, onClick: msg): Tea_Vdom.t<msg> => {
  let baseClass = "px-3 py-1.5 text-xs rounded-t border-b-2 transition-colors"
  let activeClass = active
    ? `${baseClass} text-cyan-300 border-cyan-400 bg-gray-800`
    : `${baseClass} text-gray-500 border-transparent hover:text-gray-300`
  button(
    list{
      Attrs.class_(activeClass),
      Events.onClick(onClick),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Render the connection status indicator.
let renderConnectionStatus = (state: bojState): Tea_Vdom.t<msg> => {
  let (dotClass, label) = if state.connected {
    ("bg-green-400", "Connected")
  } else {
    ("bg-red-400", "Disconnected")
  }
  div(
    list{Attrs.class_("flex items-center gap-2 text-xs")},
    list{
      div(list{Attrs.class_(`w-2 h-2 rounded-full ${dotClass}`)}, list{}),
      span(list{Attrs.class_("text-gray-400")}, list{text(label)}),
      span(list{Attrs.class_("text-gray-600 ml-2")}, list{text(state.serverUrl)}),
    },
  )
}

/// Render a stat card.
let renderStat = (label: string, value: string, colour: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-800/50 border border-gray-700 rounded p-3")},
    list{
      div(list{Attrs.class_(`text-lg font-bold ${colour}`)}, list{text(value)}),
      div(list{Attrs.class_("text-xs text-gray-500 mt-1")}, list{text(label)}),
    },
  )
}

// ============================================================================
// Dashboard Tab
// ============================================================================

let renderDashboard = (state: bojState): Tea_Vdom.t<msg> => {
  let total = Array.length(state.cartridges)
  let loaded = loadedCount(state.cartridges)
  let gradeD = countByGrade(state.cartridges, GradeD)
  let gradeC = countByGrade(state.cartridges, GradeC)
  let gradeB = countByGrade(state.cartridges, GradeB)
  let gradeA = countByGrade(state.cartridges, GradeA)
  let peerCount = Array.length(state.umoja.peers)

  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Stats grid
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3")},
        list{
          renderStat("Total Cartridges", Int.toString(total), "text-cyan-300"),
          renderStat("Loaded", Int.toString(loaded), "text-green-300"),
          renderStat("Umoja Peers", Int.toString(peerCount), "text-indigo-300"),
          renderStat("Federation", state.umoja.active ? "Active" : "Inactive", "text-amber-300"),
        },
      ),
      // Grade breakdown
      div(
        list{Attrs.class_("bg-gray-800/30 border border-gray-700 rounded p-3")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-400 mb-2")},
            list{text("Cartridge Readiness Grades")},
          ),
          div(
            list{Attrs.class_("flex gap-4 text-xs")},
            list{
              span(
                list{Attrs.class_("text-yellow-300")},
                list{text(`D(Alpha): ${Int.toString(gradeD)}`)},
              ),
              span(
                list{Attrs.class_("text-blue-300")},
                list{text(`C(Beta): ${Int.toString(gradeC)}`)},
              ),
              span(
                list{Attrs.class_("text-emerald-300")},
                list{text(`B(RC): ${Int.toString(gradeB)}`)},
              ),
              span(
                list{Attrs.class_("text-green-300")},
                list{text(`A(Prod): ${Int.toString(gradeA)}`)},
              ),
            },
          ),
        },
      ),
      // Architecture summary
      div(
        list{Attrs.class_("bg-gray-800/30 border border-gray-700 rounded p-3")},
        list{
          div(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{text("Architecture")}),
          div(
            list{Attrs.class_("text-xs text-gray-300 font-mono space-y-1")},
            list{
              div(
                list{},
                list{
                  text(
                    "Idris2 ABI (dependent types) → Zig FFI (C-compatible) → V-lang (REST+gRPC+GraphQL)",
                  ),
                },
              ),
              div(
                list{},
                list{text("Umoja: gossip protocol, SHA-256 attestation, distributed federation")},
              ),
              div(list{}, list{text("Hot-reload: unmount → verify hash → remount")}),
            },
          ),
        },
      ),
      // Latency log visualization
      if Array.length(state.latencyLog) > 0 {
        div(
          list{Attrs.class_("bg-gray-800/30 border border-gray-700 rounded p-3")},
          list{
            div(
              list{Attrs.class_("text-xs text-gray-400 mb-3")},
              list{text("Invocation Latency (last 20)")},
            ),
            // Histogram bars
            div(
              list{Attrs.class_("flex items-end gap-0.5 h-16")},
              state.latencyLog
              ->Array.slice(~start=0, ~end=20)
              ->Array.map(entry => {
                let maxMs = 500.0
                let heightPct = Math.min(entry.durationMs /. maxMs *. 100.0, 100.0)
                let colour = if entry.durationMs < 50.0 {
                  "bg-emerald-500"
                } else if entry.durationMs < 200.0 {
                  "bg-amber-500"
                } else {
                  "bg-red-500"
                }
                div(
                  list{
                    Attrs.class_(`flex-1 ${colour} rounded-t transition-all min-w-1`),
                    Attrs.style("height", `${Float.toFixed(heightPct, ~digits=0)}%`),
                    Attrs.title(
                      `${entry.cartridge}/${entry.tool}: ${Float.toFixed(
                          entry.durationMs,
                          ~digits=1,
                        )}ms`,
                    ),
                  },
                  list{},
                )
              })
              ->List.fromArray,
            ),
            {
              let totalMs = state.latencyLog->Array.reduce(0.0, (acc, e) => acc +. e.durationMs)
              let count = Float.fromInt(Array.length(state.latencyLog))
              let avgMs = totalMs /. count
              let maxEntry = state.latencyLog->Array.reduce(state.latencyLog->Array.getUnsafe(0), (
                best,
                e,
              ) =>
                if e.durationMs > best.durationMs {
                  e
                } else {
                  best
                }
              )
              let minEntry = state.latencyLog->Array.reduce(state.latencyLog->Array.getUnsafe(0), (
                best,
                e,
              ) =>
                if e.durationMs < best.durationMs {
                  e
                } else {
                  best
                }
              )
              div(
                list{Attrs.class_("flex gap-4 mt-2 text-[10px] text-gray-600")},
                list{
                  span(list{}, list{text(`Avg: ${Float.toFixed(avgMs, ~digits=1)}ms`)}),
                  span(
                    list{},
                    list{text(`Min: ${Float.toFixed(minEntry.durationMs, ~digits=1)}ms`)},
                  ),
                  span(
                    list{},
                    list{text(`Max: ${Float.toFixed(maxEntry.durationMs, ~digits=1)}ms`)},
                  ),
                  span(
                    list{},
                    list{text(`Total: ${Int.toString(Array.length(state.latencyLog))} calls`)},
                  ),
                },
              )
            },
          },
        )
      } else {
        noNode
      },
      // Hot-reload pipeline indicator
      div(
        list{Attrs.class_("bg-gray-800/30 border border-gray-700 rounded p-3")},
        list{
          div(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{text("Hot-Reload Pipeline")}),
          div(
            list{Attrs.class_("flex items-center gap-2 text-xs")},
            list{
              span(
                list{
                  Attrs.class_(
                    "px-2 py-0.5 bg-red-900/30 text-red-400 rounded border border-red-800",
                  ),
                },
                list{text("1. Unmount")},
              ),
              span(list{Attrs.class_("text-gray-700")}, list{text("→")}),
              span(
                list{
                  Attrs.class_(
                    "px-2 py-0.5 bg-amber-900/30 text-amber-400 rounded border border-amber-800",
                  ),
                },
                list{text("2. Verify SHA-256")},
              ),
              span(list{Attrs.class_("text-gray-700")}, list{text("→")}),
              span(
                list{
                  Attrs.class_(
                    "px-2 py-0.5 bg-emerald-900/30 text-emerald-400 rounded border border-emerald-800",
                  ),
                },
                list{text("3. Remount")},
              ),
              span(
                list{Attrs.class_("text-gray-600 ml-auto text-[10px]")},
                list{text("Zero-downtime cartridge replacement")},
              ),
            },
          ),
        },
      ),
      // Refresh button
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-cyan-900/50 text-cyan-300 rounded border border-cyan-700 hover:bg-cyan-800/50",
              ),
              Events.onClick(Boj(RefreshHealth)),
              KeyboardNav.onActivate(Boj(RefreshHealth)),
            },
            list{text("Check Health")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded border border-gray-600 hover:bg-gray-600",
              ),
              Events.onClick(Boj(RefreshCartridges)),
              KeyboardNav.onActivate(Boj(RefreshCartridges)),
            },
            list{text("Refresh Cartridges")},
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Cartridges Tab — Matrix View
// ============================================================================

let renderCartridgeRow = (cartridge: bojCartridge): Tea_Vdom.t<msg> => {
  let gradeBadge = {
    let colour = gradeColour(cartridge.grade)
    span(
      list{Attrs.class_(`px-1.5 py-0.5 text-xs rounded border ${colour}`)},
      list{text(gradeLabel(cartridge.grade))},
    )
  }
  let loadedBadge = if cartridge.loaded {
    span(list{Attrs.class_("text-green-400 text-xs")}, list{text("●")})
  } else {
    span(list{Attrs.class_("text-gray-600 text-xs")}, list{text("○")})
  }
  let protoCells =
    allProtocols
    ->Array.map(proto => {
      let has = hasProtocol(cartridge, proto)
      td(
        list{Attrs.class_("px-1 py-1 text-center text-xs")},
        list{
          if has {
            span(list{Attrs.class_("text-cyan-400")}, list{text("██")})
          } else {
            span(list{Attrs.class_("text-gray-800")}, list{text("  ")})
          },
        },
      )
    })
    ->List.fromArray

  tr(
    list{
      Attrs.class_("border-b border-gray-800 hover:bg-gray-800/30 cursor-pointer"),
      Events.onClick(Boj(SelectCartridge(cartridge.name))),
    },
    list{
      td(list{Attrs.class_("px-2 py-1 text-xs")}, list{loadedBadge}),
      td(list{Attrs.class_("px-2 py-1 text-xs text-gray-200")}, list{text(cartridge.displayName)}),
      td(list{Attrs.class_("px-2 py-1")}, list{gradeBadge}),
      td(
        list{Attrs.class_("px-2 py-1 text-xs text-gray-500")},
        list{text(layerProgress(cartridge.layers))},
      ),
      ...protoCells,
    },
  )
}

let renderCartridgesMatrix = (state: bojState): Tea_Vdom.t<msg> => {
  let filtered = filterCartridges(state.cartridges, state.filterText)
  let protoHeaders =
    allProtocols
    ->Array.map(proto => {
      th(
        list{Attrs.class_("px-1 py-1 text-xs text-gray-500 font-normal text-center")},
        list{text(protocolShort(proto))},
      )
    })
    ->List.fromArray

  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Filter
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 text-xs bg-gray-800 text-gray-200 rounded border border-gray-700",
              ),
              Attrs.placeholder("Filter cartridges..."),
              Attrs.value(state.filterText),
              Events.onInput(t => Boj(SetBojFilter(t))),
            },
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{
              text(
                `${Int.toString(Array.length(filtered))} of ${Int.toString(
                    Array.length(state.cartridges),
                  )}`,
              ),
            },
          ),
        },
      ),
      // Matrix table
      div(
        list{Attrs.class_("overflow-x-auto")},
        list{
          table(
            list{
              Attrs.class_("w-full text-left"),
              Attrs.role("grid"),
              Attrs.ariaLabel("Cartridge capability matrix"),
            },
            list{
              thead(
                list{},
                list{
                  tr(
                    list{Attrs.class_("border-b border-gray-700")},
                    list{
                      th(list{Attrs.class_("px-2 py-1 text-xs text-gray-500 font-normal")}, list{}),
                      th(
                        list{Attrs.class_("px-2 py-1 text-xs text-gray-500 font-normal")},
                        list{text("Cartridge")},
                      ),
                      th(
                        list{Attrs.class_("px-2 py-1 text-xs text-gray-500 font-normal")},
                        list{text("Grade")},
                      ),
                      th(
                        list{Attrs.class_("px-2 py-1 text-xs text-gray-500 font-normal")},
                        list{text("Layers")},
                      ),
                      ...protoHeaders,
                    },
                  ),
                },
              ),
              tbody(list{}, filtered->Array.map(renderCartridgeRow)->List.fromArray),
            },
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Cartridge Detail (shown when a cartridge is selected)
// ============================================================================

let renderCartridgeDetail = (state: bojState, name: string): Tea_Vdom.t<msg> => {
  let cartOpt = state.cartridges->Array.find(c => c.name === name)
  switch cartOpt {
  | None => div(list{}, list{text("Cartridge not found")})
  | Some(cart) =>
    div(
      list{Attrs.class_("bg-gray-800/30 border border-gray-700 rounded p-4 space-y-3")},
      list{
        // Header
        div(
          list{Attrs.class_("flex items-center justify-between")},
          list{
            div(
              list{Attrs.class_("flex items-center gap-3")},
              list{
                span(
                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                  list{text(cart.displayName)},
                ),
                span(
                  list{
                    Attrs.class_(`px-1.5 py-0.5 text-xs rounded border ${gradeColour(cart.grade)}`),
                  },
                  list{text(gradeLabel(cart.grade))},
                ),
              },
            ),
            button(
              list{
                Attrs.class_("text-xs text-gray-500 hover:text-gray-300"),
                Events.onClick(Boj(SelectCartridge(""))),
                Attrs.ariaLabel("Close detail"),
              },
              list{text("✕")},
            ),
          },
        ),
        // Description
        div(list{Attrs.class_("text-xs text-gray-400")}, list{text(cart.description)}),
        // Layer status
        div(
          list{Attrs.class_("grid grid-cols-4 gap-2 text-xs")},
          list{
            div(
              list{Attrs.class_(cart.layers.abiReady ? "text-green-400" : "text-gray-600")},
              list{text(cart.layers.abiReady ? "✓ ABI (Idris2)" : "○ ABI (Idris2)")},
            ),
            div(
              list{Attrs.class_(cart.layers.ffiReady ? "text-green-400" : "text-gray-600")},
              list{text(cart.layers.ffiReady ? "✓ FFI (Zig)" : "○ FFI (Zig)")},
            ),
            div(
              list{Attrs.class_(cart.layers.adapterReady ? "text-green-400" : "text-gray-600")},
              list{text(cart.layers.adapterReady ? "✓ Adapter (V)" : "○ Adapter (V)")},
            ),
            div(
              list{Attrs.class_(cart.layers.sharedLibReady ? "text-green-400" : "text-gray-600")},
              list{text(cart.layers.sharedLibReady ? "✓ .so built" : "○ .so pending")},
            ),
          },
        ),
        // Ports
        if cart.restPort > 0 || cart.grpcPort > 0 || cart.graphqlPort > 0 {
          div(
            list{Attrs.class_("flex gap-4 text-xs text-gray-500")},
            list{
              if cart.restPort > 0 {
                span(list{}, list{text(`REST :${Int.toString(cart.restPort)}`)})
              } else {
                noNode
              },
              if cart.grpcPort > 0 {
                span(list{}, list{text(`gRPC :${Int.toString(cart.grpcPort)}`)})
              } else {
                noNode
              },
              if cart.graphqlPort > 0 {
                span(list{}, list{text(`GraphQL :${Int.toString(cart.graphqlPort)}`)})
              } else {
                noNode
              },
            },
          )
        } else {
          noNode
        },
        // Load/Unload buttons
        div(
          list{Attrs.class_("flex gap-2")},
          list{
            if cart.loaded {
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-red-900/50 text-red-300 rounded border border-red-700 hover:bg-red-800/50",
                  ),
                  Events.onClick(Boj(UnloadCartridge(cart.name))),
                },
                list{text("Unload")},
              )
            } else {
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-cyan-900/50 text-cyan-300 rounded border border-cyan-700 hover:bg-cyan-800/50",
                  ),
                  Events.onClick(Boj(LoadCartridge(cart.name))),
                },
                list{text("Load")},
              )
            },
            button(
              list{
                Attrs.class_(
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded border border-gray-600 hover:bg-gray-600",
                ),
                Events.onClick(Boj(SetBojCategory(Invoke))),
              },
              list{text("Invoke →")},
            ),
          },
        ),
        // SHA hash
        if cart.soHash !== "" {
          div(
            list{Attrs.class_("text-xs text-gray-600 font-mono truncate")},
            list{text(`SHA-256: ${cart.soHash}`)},
          )
        } else {
          noNode
        },
      },
    )
  }
}

// ============================================================================
// Topology Tab — Interactive Layered Architecture View
// ============================================================================

/// Render a single topology layer card with detail metrics.
let renderTopologyLayer = (
  title: string,
  subtitle: string,
  colour: string,
  borderColour: string,
  metrics: array<(string, string)>,
  readyCount: int,
  totalCount: int,
): Tea_Vdom.t<msg> => {
  let pct = if totalCount > 0 {
    readyCount * 100 / totalCount
  } else {
    0
  }
  div(
    list{
      Attrs.class_(
        `bg-gray-800/40 border rounded-lg p-4 ${borderColour} hover:bg-gray-800/60 transition-colors`,
      ),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(list{Attrs.class_(`text-sm font-bold ${colour}`)}, list{text(title)}),
              span(list{Attrs.class_("text-[10px] text-gray-600")}, list{text(subtitle)}),
            },
          ),
          // Readiness gauge
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              div(
                list{Attrs.class_("w-20 h-2 bg-gray-700 rounded-full overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        `h-full rounded-full ${if pct >= 80 {
                            "bg-emerald-500"
                          } else if pct >= 50 {
                            "bg-amber-500"
                          } else {
                            "bg-red-500"
                          }}`,
                      ),
                      Attrs.style("width", `${Int.toString(pct)}%`),
                    },
                    list{},
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-[10px] text-gray-500 font-mono")},
                list{text(`${Int.toString(readyCount)}/${Int.toString(totalCount)}`)},
              ),
            },
          ),
        },
      ),
      // Metrics grid
      div(
        list{Attrs.class_("grid grid-cols-3 gap-2 mt-2")},
        metrics
        ->Array.map(((label, value)) =>
          div(
            list{Attrs.class_("text-xs")},
            list{
              div(list{Attrs.class_("text-gray-600")}, list{text(label)}),
              div(list{Attrs.class_("text-gray-300 font-mono")}, list{text(value)}),
            },
          )
        )
        ->List.fromArray,
      ),
    },
  )
}

/// Render the data flow arrow between layers.
let renderFlowArrow = (label: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center justify-center py-1")},
    list{
      div(
        list{Attrs.class_("text-gray-700 text-xs flex items-center gap-1")},
        list{
          span(list{}, list{text("▼")}),
          span(list{Attrs.class_("text-[10px] text-gray-600")}, list{text(label)}),
          span(list{}, list{text("▼")}),
        },
      ),
    },
  )
}

let renderTopology = (state: bojState): Tea_Vdom.t<msg> => {
  let abiReady = state.cartridges->Array.filter(c => c.layers.abiReady)->Array.length
  let ffiReady = state.cartridges->Array.filter(c => c.layers.ffiReady)->Array.length
  let adapterReady = state.cartridges->Array.filter(c => c.layers.adapterReady)->Array.length
  let soReady = state.cartridges->Array.filter(c => c.layers.sharedLibReady)->Array.length
  let total = Array.length(state.cartridges)
  let restPorts = state.cartridges->Array.filter(c => c.restPort > 0)->Array.length
  let grpcPorts = state.cartridges->Array.filter(c => c.grpcPort > 0)->Array.length
  let gqlPorts = state.cartridges->Array.filter(c => c.graphqlPort > 0)->Array.length

  div(
    list{Attrs.class_("space-y-1")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-400 mb-3")},
        list{text("BoJ Architecture — Interactive 3-Layer Cartridge Stack")},
      ),
      // Layer 1: V-lang Adapter
      renderTopologyLayer(
        "V-lang Triple Adapter",
        "REST + gRPC + GraphQL",
        "text-violet-400",
        "border-violet-800",
        [
          ("REST endpoints", Int.toString(restPorts)),
          ("gRPC endpoints", Int.toString(grpcPorts)),
          ("GraphQL endpoints", Int.toString(gqlPorts)),
        ],
        adapterReady,
        total,
      ),
      renderFlowArrow("C ABI calls"),
      // Layer 2: Zig FFI
      renderTopologyLayer(
        "Zig FFI",
        "C-compatible, zero-cost",
        "text-amber-400",
        "border-amber-800",
        [
          (".so files built", Int.toString(soReady)),
          ("State machines", Int.toString(ffiReady)),
          ("Hash verified", Int.toString(soReady)),
        ],
        ffiReady,
        total,
      ),
      renderFlowArrow("dependent type proofs"),
      // Layer 3: Idris2 ABI
      renderTopologyLayer(
        "Idris2 ABI",
        "Dependent types, formal proofs",
        "text-cyan-400",
        "border-cyan-800",
        [
          ("Definitions ready", Int.toString(abiReady)),
          ("Safe* modules", "7"),
          ("Proof strategy", "compile-time"),
        ],
        abiReady,
        total,
      ),
      renderFlowArrow("UDP gossip protocol"),
      // Layer 4: Umoja Federation
      renderTopologyLayer(
        "Umoja Federation",
        "IPv6 UDP gossip, SHA-256 attestation",
        "text-indigo-400",
        "border-indigo-800",
        [
          ("Active peers", Int.toString(Array.length(state.umoja.peers))),
          ("Gossip round", Int.toString(state.umoja.currentRound)),
          (
            "Status",
            if state.umoja.active {
              "Active"
            } else {
              "Inactive"
            },
          ),
        ],
        if state.umoja.active {
          1
        } else {
          0
        },
        1,
      ),
      // Refresh
      div(
        list{Attrs.class_("flex gap-2 mt-3")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded border border-gray-600 hover:bg-gray-600",
              ),
              Events.onClick(Boj(RefreshTopology)),
              KeyboardNav.onActivate(Boj(RefreshTopology)),
            },
            list{text("Refresh Topology")},
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Federation Tab
// ============================================================================

/// Format a relative time string from a Unix timestamp (seconds).
let relativeTime = (timestamp: float): string => {
  let now = Date.now() /. 1000.0
  let diff = now -. timestamp
  if diff < 0.0 {
    "just now"
  } else if diff < 60.0 {
    `${Int.toString(Float.toInt(diff))}s ago`
  } else if diff < 3600.0 {
    `${Int.toString(Float.toInt(diff /. 60.0))}m ago`
  } else if diff < 86400.0 {
    `${Int.toString(Float.toInt(diff /. 3600.0))}h ago`
  } else {
    `${Int.toString(Float.toInt(diff /. 86400.0))}d ago`
  }
}

/// Determine catalogue sync status by comparing a peer's digest against
/// the local node's digest (first peer with Verified state, or local node).
let catalogueSyncLabel = (state: bojState, peer: umojaPeer): (string, string) => {
  // Compare against the first verified peer's digest as a proxy for local.
  // If the local catalogue digest is not tracked separately, we compare
  // against the most common digest among verified peers.
  let localDigest =
    state.umoja.peers
    ->Array.find(p => p.state === PeerVerified && p.nodeId !== peer.nodeId)
    ->Option.map(p => p.catalogueDigest)
    ->Option.getOr("")
  if peer.catalogueDigest === "" {
    ("unknown", "text-gray-600")
  } else if localDigest === "" || peer.catalogueDigest === localDigest {
    ("in sync", "text-green-400")
  } else {
    ("differs", "text-amber-400")
  }
}

/// Render per-peer action buttons based on peer state.
let renderPeerActions = (peer: umojaPeer): Tea_Vdom.t<msg> => {
  let disconnectBtn = switch peer.state {
  | PeerVerified | PeerExchanged =>
    button(
      list{
        Attrs.class_(
          "px-2 py-0.5 text-xs bg-red-900/40 text-red-300 rounded border border-red-800 hover:bg-red-800/50",
        ),
        Events.onClick(Boj(UmojaDisconnectPeer(peer.nodeId))),
        Attrs.ariaLabel(`Disconnect peer ${peer.nodeId}`),
      },
      list{text("Disconnect")},
    )
  | PeerPending | PeerRejected | PeerStale => noNode
  }
  let syncBtn = switch peer.state {
  | PeerVerified =>
    button(
      list{
        Attrs.class_(
          "px-2 py-0.5 text-xs bg-cyan-900/40 text-cyan-300 rounded border border-cyan-800 hover:bg-cyan-800/50",
        ),
        Events.onClick(Boj(UmojaSyncCatalogue(peer.nodeId))),
        Attrs.ariaLabel(`Sync catalogue with peer ${peer.nodeId}`),
      },
      list{text("Sync Catalogue")},
    )
  | PeerPending | PeerExchanged | PeerRejected | PeerStale => noNode
  }
  let metricsBtn = button(
    list{
      Attrs.class_(
        "px-2 py-0.5 text-xs bg-gray-700 text-gray-300 rounded border border-gray-600 hover:bg-gray-600",
      ),
      Events.onClick(Boj(UmojaPeerMetrics(peer.nodeId))),
      Attrs.ariaLabel(`View metrics for peer ${peer.nodeId}`),
    },
    list{text("Metrics")},
  )
  div(list{Attrs.class_("flex gap-1 ml-auto")}, list{syncBtn, disconnectBtn, metricsBtn})
}

let renderFederation = (state: bojState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Status bar
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          div(
            list{
              Attrs.class_(
                state.umoja.active
                  ? "px-2 py-1 text-xs bg-green-900/50 text-green-300 rounded border border-green-700"
                  : "px-2 py-1 text-xs bg-gray-800 text-gray-500 rounded border border-gray-700",
              ),
            },
            list{text(state.umoja.active ? "Federation Active" : "Federation Inactive")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`Node: ${state.umoja.localNodeId}`)},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`Round: ${Int.toString(state.umoja.currentRound)}`)},
          ),
        },
      ),
      // Add Peer section
      div(
        list{Attrs.class_("bg-gray-800/30 border border-gray-700 rounded p-3")},
        list{
          div(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{text("Add Peer")}),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              input(
                list{
                  Attrs.class_(
                    "flex-1 px-3 py-1.5 text-xs bg-gray-800 text-gray-200 rounded border border-gray-700",
                  ),
                  Attrs.placeholder("Peer address (e.g. 192.168.1.100:9876 or [::1]:9876)"),
                  Attrs.value(state.umojaAddPeerInput),
                  Events.onInput(v => Boj(UmojaAddPeerInput(v))),
                },
                list{},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-indigo-900/50 text-indigo-300 rounded border border-indigo-700 hover:bg-indigo-800/50",
                  ),
                  Events.onClick(Boj(UmojaAddPeer(state.umojaAddPeerInput))),
                  Attrs.disabled(state.umojaAddPeerInput === ""),
                  Attrs.ariaLabel("Add peer to federation"),
                },
                list{text("Add")},
              ),
            },
          ),
        },
      ),
      // Peer list with management controls
      if Array.length(state.umoja.peers) > 0 {
        div(
          list{Attrs.class_("space-y-1")},
          state.umoja.peers
          ->Array.map(peer => {
            let (syncStatus, syncColour) = catalogueSyncLabel(state, peer)
            div(
              list{
                Attrs.class_(
                  "flex items-center gap-3 bg-gray-800/30 border border-gray-700 rounded px-3 py-2",
                ),
              },
              list{
                // Peer state badge
                span(
                  list{Attrs.class_(`text-xs font-medium ${peerStateColour(peer.state)}`)},
                  list{text(peerStateLabel(peer.state))},
                ),
                // Node ID
                span(list{Attrs.class_("text-xs text-gray-300")}, list{text(peer.nodeId)}),
                // Address
                span(list{Attrs.class_("text-xs text-gray-500")}, list{text(peer.address)}),
                // Last seen (relative time)
                span(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{text(peer.lastSeen > 0.0 ? relativeTime(peer.lastSeen) : "never")},
                ),
                // Catalogue sync status
                span(list{Attrs.class_(`text-xs ${syncColour}`)}, list{text(syncStatus)}),
                // Catalogue digest (truncated)
                span(
                  list{Attrs.class_("text-xs text-gray-700 font-mono truncate max-w-32")},
                  list{text(peer.catalogueDigest)},
                ),
                // Per-peer action buttons
                renderPeerActions(peer),
              },
            )
          })
          ->List.fromArray,
        )
      } else {
        div(
          list{Attrs.class_("text-xs text-gray-500 italic")},
          list{
            text(
              "No peers discovered. Add a peer or start the Umoja federation layer to begin gossip.",
            ),
          },
        )
      },
      // Action buttons row
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-amber-900/50 text-amber-300 rounded border border-amber-700 hover:bg-amber-800/50",
              ),
              Events.onClick(Boj(UmojaTriggerGossip)),
              KeyboardNav.onActivate(Boj(UmojaTriggerGossip)),
              Attrs.ariaLabel("Trigger manual gossip round"),
            },
            list{text("Trigger Gossip Round")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-indigo-900/50 text-indigo-300 rounded border border-indigo-700 hover:bg-indigo-800/50",
              ),
              Events.onClick(Boj(RefreshUmoja)),
              KeyboardNav.onActivate(Boj(RefreshUmoja)),
            },
            list{text("Refresh Federation")},
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Invoke Tab
// ============================================================================

let renderInvoke = (state: bojState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Cartridge selector
      div(
        list{Attrs.class_("space-y-1")},
        list{
          label(list{Attrs.class_("text-xs text-gray-400")}, list{text("Cartridge")}),
          select(
            list{
              Attrs.class_(
                "w-full px-3 py-1.5 text-xs bg-gray-800 text-gray-200 rounded border border-gray-700",
              ),
              Events.onChange(v => Boj(SetInvokeCartridge(v))),
            },
            list{
              option'(list{Attrs.value("")}, list{text("Select cartridge...")}),
              ...state.cartridges
              ->Array.filter(c => c.loaded)
              ->Array.map(c => option'(list{Attrs.value(c.name)}, list{text(c.displayName)}))
              ->List.fromArray,
            },
          ),
        },
      ),
      // Tool name
      div(
        list{Attrs.class_("space-y-1")},
        list{
          label(list{Attrs.class_("text-xs text-gray-400")}, list{text("Tool")}),
          input(
            list{
              Attrs.class_(
                "w-full px-3 py-1.5 text-xs bg-gray-800 text-gray-200 rounded border border-gray-700",
              ),
              Attrs.placeholder("Tool name (e.g. query, connect, status)"),
              Attrs.value(state.invokeTool),
              Events.onInput(v => Boj(SetInvokeTool(v))),
            },
            list{},
          ),
        },
      ),
      // Args (JSON)
      div(
        list{Attrs.class_("space-y-1")},
        list{
          label(list{Attrs.class_("text-xs text-gray-400")}, list{text("Arguments (JSON)")}),
          textarea(
            list{
              Attrs.class_(
                "w-full px-3 py-1.5 text-xs bg-gray-800 text-gray-200 rounded border border-gray-700 font-mono h-20",
              ),
              Attrs.placeholder(`{"key": "value"}`),
              Events.onInput(v => Boj(SetInvokeArgs(v))),
            },
            list{},
          ),
        },
      ),
      // Execute button
      button(
        list{
          Attrs.class_(
            "px-4 py-2 text-xs bg-cyan-900/50 text-cyan-300 rounded border border-cyan-700 hover:bg-cyan-800/50",
          ),
          Events.onClick(Boj(ExecuteInvoke)),
          KeyboardNav.onActivate(Boj(ExecuteInvoke)),
          Attrs.disabled(state.invokeCartridge === "" || state.invokeTool === ""),
        },
        list{text(state.loading ? "Invoking..." : "Invoke")},
      ),
      // Result
      switch state.invokeResult {
      | None => noNode
      | Some(result) =>
        div(
          list{
            Attrs.class_(
              result.success
                ? "bg-green-900/20 border border-green-800 rounded p-3"
                : "bg-red-900/20 border border-red-800 rounded p-3",
            ),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-2")},
              list{
                span(
                  list{
                    Attrs.class_(
                      result.success ? "text-xs text-green-400" : "text-xs text-red-400",
                    ),
                  },
                  list{text(result.success ? "Success" : "Failed")},
                ),
                span(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text(`${Int.toString(result.durationMs)}ms`)},
                ),
              },
            ),
            pre(
              list{
                Attrs.class_(
                  "text-xs text-gray-300 font-mono whitespace-pre-wrap overflow-auto max-h-40",
                ),
              },
              list{text(result.payload)},
            ),
          },
        )
      },
      // TypeLL type-check result
      viewTypeCheckResult(state.lastTypeCheck),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

let view = (state: bojState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 z-40 bg-gray-950/95 flex flex-col overflow-hidden"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Bundle of Joy — Cartridge Server"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("px-4 py-3 border-b border-gray-800 flex items-center justify-between")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-sm font-medium text-cyan-300")},
                list{text("BoJ — Bundle of Joy")},
              ),
              renderConnectionStatus(state),
            },
          ),
          // Close button
          button(
            list{
              Attrs.class_("text-gray-500 hover:text-gray-300 text-sm"),
              Events.onClick(PanelSwitcher(ClosePanels)),
              KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
              Attrs.ariaLabel("Close BoJ panel"),
            },
            list{text("✕")},
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("px-4 pt-2 flex gap-1 border-b border-gray-800"), Attrs.role("tablist")},
        list{
          renderTab(
            "Dashboard",
            state.activeCategory === Dashboard,
            Boj(SetBojCategory(Dashboard)),
          ),
          renderTab(
            "Cartridges",
            state.activeCategory === Cartridges,
            Boj(SetBojCategory(Cartridges)),
          ),
          renderTab("Topology", state.activeCategory === Topology, Boj(SetBojCategory(Topology))),
          renderTab(
            "Federation",
            state.activeCategory === Federation,
            Boj(SetBojCategory(Federation)),
          ),
          renderTab("Invoke", state.activeCategory === Invoke, Boj(SetBojCategory(Invoke))),
        },
      ),
      // Error banner
      switch state.error {
      | None => noNode
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/30 border border-red-800 rounded text-xs text-red-300 flex justify-between",
            ),
          },
          list{
            span(list{}, list{text(err)}),
            button(
              list{
                Attrs.class_("text-red-500 hover:text-red-300 ml-2"),
                Events.onClick(Boj(DismissBojError)),
                KeyboardNav.onActivate(Boj(DismissBojError)),
              },
              list{text("✕")},
            ),
          },
        )
      },
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          // Selected cartridge detail (shown above matrix)
          switch state.selectedCartridge {
          | Some(name) if name !== "" => renderCartridgeDetail(state, name)
          | _ => noNode
          },
          // Tab content
          switch state.activeCategory {
          | Dashboard => renderDashboard(state)
          | Cartridges => renderCartridgesMatrix(state)
          | Topology => renderTopology(state)
          | Federation => renderFederation(state)
          | Invoke => renderInvoke(state)
          },
        },
      ),
    },
  )
}
