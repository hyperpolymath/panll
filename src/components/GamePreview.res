// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Game Preview Component — renders the live IDApTIK game preview panel.
///
/// The Live Preview tab embeds the Vite dev server output via an iframe.
/// When the Gossamer multi-webview system is wired (Phase 2), the iframe
/// will be replaced by a dedicated webview for tighter integration.
///
/// Additional tabs show the device interaction log, saved gameplay clips,
/// and render performance statistics.

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Render the category tab bar.
let renderTabs = (active: gamePreviewCategory): Tea_Vdom.t<msg> => {
  let tabs: array<gamePreviewCategory> = [
    PreviewLive,
    PreviewDeviceLog,
    PreviewClips,
    PreviewPerformance,
  ]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      let label = GamePreviewEngine.categoryLabel(tab)
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900"}`,
          ),
          Events.onClick(GamePreview(SetPreviewCategory(tab))),
        },
        list{text(label)},
      )
    })
    ->List.fromArray,
  )
}

/// Render the game loop execution controls.
let renderExecutionControls = (state: gamePreviewState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2")},
    list{
      // Pause/Resume button
      button(
        list{
          Attrs.class_(
            `px-3 py-1.5 text-xs rounded font-medium ${switch state.execution {
              | GameRunning => "bg-amber-800 text-amber-200 hover:bg-amber-700"
              | GamePaused | GameStepping => "bg-emerald-800 text-emerald-200 hover:bg-emerald-700"
              }}`,
          ),
          Events.onClick(
            GamePreview(
              switch state.execution {
              | GameRunning => PauseGame
              | GamePaused | GameStepping => ResumeGame
              },
            ),
          ),
        },
        list{
          text(
            switch state.execution {
            | GameRunning => "Pause"
            | GamePaused | GameStepping => "Resume"
            },
          ),
        },
      ),
      // Step button (only when paused)
      switch state.execution {
      | GamePaused | GameStepping =>
        button(
          list{
            Attrs.class_("px-3 py-1.5 text-xs rounded bg-blue-800 text-blue-200 hover:bg-blue-700"),
            Events.onClick(GamePreview(StepFrame)),
          },
          list{text("Step Frame")},
        )
      | GameRunning => noNode
      },
      // Execution state indicator
      div(
        list{Attrs.class_("flex items-center gap-1 ml-2")},
        list{
          div(
            list{
              Attrs.class_(
                `w-2 h-2 rounded-full ${switch state.execution {
                  | GameRunning => "bg-emerald-400 animate-pulse"
                  | GamePaused => "bg-amber-400"
                  | GameStepping => "bg-blue-400"
                  }}`,
              ),
            },
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{text(GamePreviewEngine.executionLabel(state.execution))},
          ),
        },
      ),
    },
  )
}

/// Render the overlay toggle buttons.
let renderOverlayToggles = (activeOverlays: array<gameOverlay>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-wrap gap-1")},
    GamePreviewEngine.allOverlays
    ->Array.map(overlay => {
      let isActive = GamePreviewEngine.isOverlayActive(activeOverlays, overlay)
      button(
        list{
          Attrs.class_(
            `px-2 py-1 text-xs rounded transition-colors ${isActive
                ? "bg-cyan-800 text-cyan-200"
                : "bg-gray-800 text-gray-500 hover:text-gray-300"}`,
          ),
          Events.onClick(GamePreview(ToggleOverlay(overlay))),
        },
        list{text(GamePreviewEngine.overlayLabel(overlay))},
      )
    })
    ->List.fromArray,
  )
}

/// Render the live preview tab — embedded game + toolbar.
let renderLivePreview = (state: gamePreviewState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 flex flex-col")},
    list{
      // Toolbar
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-4 py-2 bg-gray-900/50 border-b border-gray-800",
          ),
        },
        list{
          renderExecutionControls(state),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              // Recording controls
              switch state.gameRecording {
              | GameRecordingActive(_) =>
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
                        Events.onClick(GamePreview(StopGameRecording)),
                      },
                      list{text("Stop")},
                    ),
                  },
                )
              | GameRecordingPaused(_) =>
                span(list{Attrs.class_("text-xs text-yellow-400")}, list{text("REC PAUSED")})
              | GameRecordingIdle =>
                button(
                  list{
                    Attrs.class_(
                      "text-xs text-gray-500 hover:text-gray-300 px-2 py-1 rounded bg-gray-800",
                    ),
                    Events.onClick(GamePreview(StartGameRecording)),
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
                  Events.onClick(GamePreview(ScreenshotGame)),
                },
                list{text("Screenshot")},
              ),
              // Zoom controls
              div(
                list{Attrs.class_("flex items-center gap-1")},
                list{
                  button(
                    list{
                      Attrs.class_("text-xs text-gray-500 hover:text-gray-300 px-1"),
                      Events.onClick(GamePreview(SetZoom(state.zoomLevel -. 0.25))),
                    },
                    list{text("-")},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-400 w-10 text-center")},
                    list{text(`${Float.toFixed(state.zoomLevel *. 100.0, ~digits=0)}%`)},
                  ),
                  button(
                    list{
                      Attrs.class_("text-xs text-gray-500 hover:text-gray-300 px-1"),
                      Events.onClick(GamePreview(SetZoom(state.zoomLevel +. 0.25))),
                    },
                    list{text("+")},
                  ),
                },
              ),
              // Multiplayer view toggle
              button(
                list{
                  Attrs.class_(
                    `text-xs px-2 py-1 rounded ${state.multiplayerView
                        ? "bg-purple-800 text-purple-200"
                        : "bg-gray-800 text-gray-500"}`,
                  ),
                  Events.onClick(GamePreview(ToggleMultiplayerView)),
                },
                list{text("Co-op View")},
              ),
            },
          ),
        },
      ),
      // Overlay toggles
      div(
        list{Attrs.class_("px-4 py-2 border-b border-gray-800 bg-gray-900/30")},
        list{renderOverlayToggles(state.activeOverlays)},
      ),
      // Game iframe
      if state.devServerConnected {
        div(
          list{
            Attrs.class_("flex-1 relative bg-black"),
            Attrs.style("transform", `scale(${Float.toString(state.zoomLevel)})`),
            Attrs.style("transform-origin", "center center"),
          },
          list{
            node(
              "iframe",
              list{
                Attrs.src(state.devServerUrl),
                Attrs.class_("w-full h-full border-0"),
                Attrs.title("IDApTIK Game Preview"),
              },
              list{},
            ),
          },
        )
      } else {
        div(
          list{Attrs.class_("flex-1 flex items-center justify-center bg-gray-950")},
          list{
            div(
              list{Attrs.class_("text-center")},
              list{
                div(list{Attrs.class_("text-gray-600 text-lg mb-2")}, list{text("Game Preview")}),
                div(
                  list{Attrs.class_("text-gray-700 text-sm mb-4")},
                  list{text(`Dev server not detected at ${state.devServerUrl}`)},
                ),
                div(
                  list{Attrs.class_("text-gray-700 text-xs mb-4")},
                  list{text("Run `deno task dev` or `./start-game-only.sh` to start the game.")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-sm rounded bg-cyan-900 text-cyan-200 hover:bg-cyan-800",
                    ),
                    Events.onClick(GamePreview(CheckDevServer)),
                  },
                  list{text("Retry Connection")},
                ),
              },
            ),
          },
        )
      },
    },
  )
}

/// Render the device interaction log tab.
let renderDeviceLog = (state: gamePreviewState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          h3(
            list{Attrs.class_("text-sm font-medium text-gray-300")},
            list{text(`Device Interactions (${Int.toString(Array.length(state.deviceLog))})`)},
          ),
          button(
            list{
              Attrs.class_(
                "text-xs text-gray-400 hover:text-gray-200 px-3 py-1 rounded bg-gray-800",
              ),
              Events.onClick(GamePreview(ClearDeviceLog)),
            },
            list{text("Clear")},
          ),
        },
      ),
      if Array.length(state.deviceLog) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No device interactions recorded. Play the game to see interactions here.")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1")},
          state.deviceLog
          ->Array.map(entry => {
            div(
              list{
                Attrs.class_(
                  "flex items-center gap-3 font-mono text-sm px-3 py-1.5 rounded bg-gray-900/50",
                ),
              },
              list{
                span(
                  list{Attrs.class_("text-cyan-400 w-32 truncate")},
                  list{text(entry.deviceType)},
                ),
                span(list{Attrs.class_("text-gray-500 w-20")}, list{text(entry.deviceId)}),
                span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(entry.interaction)}),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the gameplay clips tab.
let renderClips = (state: gamePreviewState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          h3(list{Attrs.class_("text-sm font-medium text-gray-300")}, list{text("Gameplay Clips")}),
          button(
            list{
              Attrs.class_(
                "text-xs text-gray-400 hover:text-gray-200 px-3 py-1 rounded bg-gray-800",
              ),
              Events.onClick(GamePreview(LoadClips)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      if Array.length(state.clips) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No clips yet. Record gameplay from the Live Preview tab.")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          state.clips
          ->Array.map(clip => {
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
                      list{text(clip.name)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mt-1")},
                      list{
                        text(
                          `${Float.toString(clip.durationSecs)}s | ${Int.toString(
                              clip.sizeBytes,
                            )} bytes`,
                        ),
                      },
                    ),
                  },
                ),
                button(
                  list{
                    Attrs.class_(
                      "text-xs text-red-400 hover:text-red-300 px-2 py-1 bg-gray-800 rounded",
                    ),
                    Events.onClick(GamePreview(DeleteClip(clip.id))),
                  },
                  list{text("Delete")},
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

/// Render the performance/render stats tab.
let renderPerformance = (state: gamePreviewState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-auto p-6")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          h3(
            list{Attrs.class_("text-sm font-medium text-gray-300")},
            list{text("Render Performance")},
          ),
          button(
            list{
              Attrs.class_(
                "text-xs text-gray-400 hover:text-gray-200 px-3 py-1 rounded bg-gray-800",
              ),
              Events.onClick(GamePreview(RefreshStats)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      switch state.stats {
      | None =>
        div(
          list{Attrs.class_("text-center text-gray-600 text-sm py-8")},
          list{text("No render stats available. Connect to the running game.")},
        )
      | Some(stats) =>
        div(
          list{Attrs.class_("grid grid-cols-2 gap-4")},
          list{
            // FPS card
            div(
              list{Attrs.class_("bg-gray-900 rounded-lg p-4 border border-gray-800")},
              list{
                div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("FPS")}),
                div(
                  list{
                    Attrs.class_(
                      `text-2xl font-bold ${stats.fps >= 55.0
                          ? "text-emerald-400"
                          : stats.fps >= 30.0
                          ? "text-amber-400"
                          : "text-red-400"}`,
                    ),
                  },
                  list{text(Float.toFixed(stats.fps, ~digits=1))},
                ),
              },
            ),
            // Draw calls card
            div(
              list{Attrs.class_("bg-gray-900 rounded-lg p-4 border border-gray-800")},
              list{
                div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Draw Calls")}),
                div(
                  list{Attrs.class_("text-2xl font-bold text-gray-200")},
                  list{text(Int.toString(stats.drawCalls))},
                ),
              },
            ),
            // Texture memory card
            div(
              list{Attrs.class_("bg-gray-900 rounded-lg p-4 border border-gray-800")},
              list{
                div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Texture Memory")}),
                div(
                  list{Attrs.class_("text-2xl font-bold text-gray-200")},
                  list{
                    text(
                      `${Float.toFixed(
                          Int.toFloat(stats.textureMemory) /. 1048576.0,
                          ~digits=1,
                        )} MB`,
                    ),
                  },
                ),
              },
            ),
            // Sprite count card
            div(
              list{Attrs.class_("bg-gray-900 rounded-lg p-4 border border-gray-800")},
              list{
                div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Active Sprites")}),
                div(
                  list{Attrs.class_("text-2xl font-bold text-gray-200")},
                  list{text(Int.toString(stats.spriteCount))},
                ),
              },
            ),
          },
        )
      },
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Render the Game Preview panel as a full-screen overlay.
let view = (state: gamePreviewState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/98 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Game Preview — live IDApTIK game preview with hot-reload"),
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
                list{Attrs.class_("w-6 h-6 rounded bg-cyan-900 flex items-center justify-center")},
                list{span(list{Attrs.class_("text-cyan-400 text-xs font-bold")}, list{text("GP")})},
              ),
              div(
                list{},
                list{
                  h2(
                    list{Attrs.class_("text-lg font-medium text-gray-200")},
                    list{text("Game Preview")},
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{
                      text(
                        if state.devServerConnected {
                          `Connected to ${state.devServerUrl}`
                        } else {
                          "Dev server not connected"
                        },
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
          list{span(list{Attrs.class_("text-red-400 text-sm")}, list{text(err)})},
        )
      | None => noNode
      },
      // Tab bar
      renderTabs(state.activeCategory),
      // Content
      switch state.activeCategory {
      | PreviewLive => renderLivePreview(state)
      | PreviewDeviceLog => renderDeviceLog(state)
      | PreviewClips => renderClips(state)
      | PreviewPerformance => renderPerformance(state)
      },
    },
  )
}
