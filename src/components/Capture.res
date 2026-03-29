// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Capture Panel — gallery, recordings, demos, cloning, comparisons (DD-022).
///
/// The capture panel provides a gallery view of all screenshots and recordings,
/// demo package management, panel clone tracking, and comparison mode controls.

open Model
open Msg
open Tea.Html

/// Render the capture gallery — thumbnails of all screenshots.
let renderGallery = (capture: captureState): Tea_Vdom.t<msg> => {
  if Array.length(capture.captures) === 0 {
    div(
      list{
        Attrs.class_("p-8 text-center text-gray-600 text-sm"),
        Attrs.title("Use the capture bar (camera icon) on any panel to take screenshots"),
      },
      list{text("No captures yet — use the capture bar on any panel to start")},
    )
  } else {
    div(
      list{Attrs.class_("grid grid-cols-3 gap-4")},
      Array.map(capture.captures, entry =>
        div(
          list{
            Attrs.class_(
              "bg-gray-900 rounded border border-gray-800 p-3 hover:border-gray-600 transition-colors",
            ),
            Attrs.title(
              `${entry.label} — ${entry.panelId} (${Float.toFixed(entry.timestamp, ~digits=0)})`,
            ),
          },
          list{
            div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text(entry.label)}),
            div(
              list{Attrs.class_("text-xs text-gray-600")},
              list{text(entry.panelId ++ " " ++ (entry.isRecording ? "recording" : "screenshot"))},
            ),
            button(
              list{
                Attrs.class_("mt-2 text-xs text-red-500 hover:text-red-400"),
                Events.onClick(Capture(RemoveCapture(entry.id))),
              },
              list{text("Remove")},
            ),
          },
        )
      )->List.fromArray,
    )
  }
}

/// Render recording status.
let renderRecordingStatus = (recording: recordingState): Tea_Vdom.t<msg> => {
  switch recording {
  | NotRecording => div(list{Attrs.class_("text-xs text-gray-600")}, list{text("Not recording")})
  | Recording(panelId, _startTime) =>
    div(
      list{Attrs.class_("flex items-center gap-2")},
      list{
        div(list{Attrs.class_("w-2 h-2 rounded-full bg-red-500 animate-pulse")}, list{}),
        div(list{Attrs.class_("text-xs text-red-400")}, list{text("Recording: " ++ panelId)}),
        button(
          list{
            Attrs.class_("text-xs text-gray-400 hover:text-gray-300"),
            Events.onClick(Capture(StopRecording)),
            KeyboardNav.onActivate(Capture(StopRecording)),
          },
          list{text("Stop")},
        ),
      },
    )
  | Paused(panelId, _elapsed) =>
    div(
      list{Attrs.class_("flex items-center gap-2")},
      list{
        div(list{Attrs.class_("w-2 h-2 rounded-full bg-yellow-500")}, list{}),
        div(list{Attrs.class_("text-xs text-yellow-400")}, list{text("Paused: " ++ panelId)}),
        button(
          list{
            Attrs.class_("text-xs text-gray-400 hover:text-gray-300"),
            Events.onClick(Capture(TogglePauseRecording)),
            KeyboardNav.onActivate(Capture(TogglePauseRecording)),
          },
          list{text("Resume")},
        ),
      },
    )
  }
}

/// Full Capture panel view.
let view = (capture: captureState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 overflow-auto"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Capture panel"),
    },
    list{
      // Header
      div(
        list{
          Attrs.class_(
            "sticky top-0 bg-gray-950 border-b border-gray-800 p-4 flex items-center justify-between z-10",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-4")},
            list{
              div(list{Attrs.class_("text-lg font-light text-gray-300")}, list{text("Capture")}),
              renderRecordingStatus(capture.recording),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(Int.toString(Array.length(capture.captures)) ++ " captures")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    `px-2 py-1 rounded text-xs ${capture.captureBarVisible
                        ? "bg-blue-700 text-white"
                        : "bg-gray-800 text-gray-400"}`,
                  ),
                  Events.onClick(Capture(ToggleCaptureBar)),
                  KeyboardNav.onActivate(Capture(ToggleCaptureBar)),
                  Attrs.title("Toggle capture bar visibility on all panels"),
                },
                list{text("Capture Bars")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 bg-gray-800 text-gray-400 rounded hover:bg-gray-700 transition-colors text-sm",
                  ),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                  KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Body
      div(
        list{Attrs.class_("p-6 max-w-5xl mx-auto")},
        list{
          // Category tabs
          div(
            list{Attrs.class_("flex gap-2 mb-6")},
            [
              (CaptureGallery, "Gallery"),
              (CaptureRecordings, "Recordings"),
              (CaptureDemos, "Demos"),
              (CaptureClones, "Clones"),
              (CaptureComparison, "Comparison"),
            ]
            ->Array.map(((cat, label)) =>
              button(
                list{
                  Attrs.class_(
                    `px-3 py-1 rounded text-xs ${capture.activeCategory === cat
                        ? "bg-blue-700 text-white"
                        : "bg-gray-800 text-gray-400 hover:bg-gray-700"}`,
                  ),
                  Events.onClick(Capture(SetCaptureCategory(cat))),
                },
                list{text(label)},
              )
            )
            ->List.fromArray,
          ),
          // Content based on active tab
          switch capture.activeCategory {
          | CaptureGallery => renderGallery(capture)
          | CaptureRecordings =>
            div(
              list{
                Attrs.class_(
                  "p-4 bg-gray-900/50 rounded border border-gray-800 text-xs text-gray-600",
                ),
                Attrs.title(
                  "Start a recording from any panel's capture bar (record icon on panel edge)",
                ),
              },
              list{
                text(
                  "Recordings captured via panel capture bars appear here. Use the record button on any panel edge.",
                ),
              },
            )
          | CaptureDemos =>
            div(
              list{
                Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800"),
                Attrs.title(
                  "Demo packages: instructor records steps, student replays and compares",
                ),
              },
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-2")},
                  list{text(Int.toString(Array.length(capture.demos)) ++ " demos loaded")},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{
                    text(
                      "Record a panel session as a .panll-demo package for teaching. Students load the demo, see golden output in a locked reference panel, and work alongside it.",
                    ),
                  },
                ),
              },
            )
          | CaptureClones =>
            div(
              list{
                Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800"),
                Attrs.title(
                  "Clone a panel to create an independent copy for before/after comparison",
                ),
              },
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-2")},
                  list{text(Int.toString(Array.length(capture.clones)) ++ " clones")},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{
                    text(
                      "Clone any panel's state for before/after analysis. Clones are independent — changes in one don't affect the other.",
                    ),
                  },
                ),
              },
            )
          | CaptureComparison =>
            div(
              list{
                Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800"),
                Attrs.title(
                  "Compare two panels side-by-side, or a student's work against a demo's golden output",
                ),
              },
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{
                    text(
                      switch capture.comparison {
                      | NoComparison => "No comparison active — select two panels or a demo to compare"
                      | SideBySide(l, r) => "Side-by-side: " ++ l ++ " vs " ++ r
                      | DemoComparison(s, d) =>
                        "Demo comparison: student " ++ s ++ " vs golden " ++ d
                      | BeforeAfter(b, a) => "Before/after: " ++ b ++ " vs " ++ a
                      },
                    ),
                  },
                ),
              },
            )
          },
        },
      ),
    },
  )
}
