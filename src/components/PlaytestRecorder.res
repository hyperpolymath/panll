// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playtest Recorder Component — record, replay, and annotate gameplay
/// sessions. Displays Record/Stop/Play buttons, session timeline, annotation
/// list with timestamps, and session library.

open Model
open Msg
open Tea.Html

/// Render a playback state indicator.
let playbackIndicator = (pb: playbackState): Tea_Vdom.t<msg> => {
  let (color, label) = switch pb {
  | Stopped => ("text-gray-500", "Stopped")
  | Playing(t) => ("text-green-400 animate-pulse", "Playing " ++ Float.toFixed(t, ~digits=1) ++ "s")
  | Paused(t) => ("text-yellow-400", "Paused " ++ Float.toFixed(t, ~digits=1) ++ "s")
  | Recording => ("text-red-400 animate-pulse", "Recording")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Format duration from milliseconds to human-readable form.
let formatDuration = (ms: float): string => {
  let seconds = ms /. 1000.0
  if seconds >= 60.0 {
    let mins = Math.floor(seconds /. 60.0)
    let secs = seconds -. mins *. 60.0
    Float.toFixed(mins, ~digits=0) ++ "m " ++ Float.toFixed(secs, ~digits=0) ++ "s"
  } else {
    Float.toFixed(seconds, ~digits=1) ++ "s"
  }
}

/// Render an annotation category badge.
let categoryBadge = (cat: string): Tea_Vdom.t<msg> => {
  let color = switch cat {
  | "bug" => "bg-red-700 text-red-100"
  | "balance" => "bg-yellow-700 text-yellow-100"
  | "design" => "bg-blue-700 text-blue-100"
  | "ux" => "bg-purple-700 text-purple-100"
  | _ => "bg-gray-700 text-gray-300"
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(cat)})
}

/// Main view function for the Playtest Recorder panel.
let view = (state: playtestRecorderState): Tea_Vdom.t<msg> => {
  let sessionCount = Array.length(state.sessions)
  let annotationCount = Array.length(state.annotations)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Playtest Recorder — Session Recording and Replay"),
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
                list{Attrs.class_("text-lg font-bold text-red-300")},
                list{text("Playtest Recorder")},
              ),
              playbackIndicator(state.playback),
            },
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              // Record button
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded " ++
                    switch state.playback {
                    | Recording => "bg-red-600 text-white"
                    | _ => "bg-red-800 hover:bg-red-700 text-white"
                    },
                  ),
                  Events.onClick(PlaytestRecorder(PrStarted)),
                },
                list{
                  text(
                    switch state.playback {
                    | Recording => "Stop"
                    | _ => "Record"
                    },
                  ),
                },
              ),
              // Play button
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded " ++
                    switch state.playback {
                    | Playing(_) => "bg-green-600 text-white"
                    | _ => "bg-green-800 hover:bg-green-700 text-white"
                    },
                  ),
                },
                list{text("Play")},
              ),
            },
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
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Record {
                  "bg-red-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(PlaytestRecorder(SetPrCategory(Record))),
            },
            list{text("Record")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Replay {
                  "bg-red-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(PlaytestRecorder(SetPrCategory(Replay))),
            },
            list{text("Replay")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Annotations {
                  "bg-red-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(PlaytestRecorder(SetPrCategory(Annotations))),
            },
            list{text("Annotations (" ++ Int.toString(annotationCount) ++ ")")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Sessions {
                  "bg-red-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(PlaytestRecorder(SetPrCategory(Sessions))),
            },
            list{text("Sessions (" ++ Int.toString(sessionCount) ++ ")")},
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
                Events.onClick(PlaytestRecorder(DismissPrError)),
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
          | Record =>
            switch state.currentSession {
            | Some(session) =>
              div(
                list{Attrs.class_("space-y-3")},
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-4 text-xs text-gray-400")},
                    list{
                      span(list{}, list{text("Session: " ++ session.name)}),
                      span(list{}, list{text("Duration: " ++ formatDuration(session.durationMs))}),
                      span(list{}, list{text("Actions: " ++ Int.toString(session.actionCount))}),
                    },
                  ),
                  // Timeline placeholder
                  div(
                    list{
                      Attrs.class_(
                        "w-full h-8 bg-gray-900 border border-gray-800 rounded relative overflow-hidden",
                      ),
                    },
                    list{
                      div(list{Attrs.class_("h-full bg-red-800/30")}, list{}),
                      // Annotation markers
                      div(
                        list{Attrs.class_("absolute inset-0 flex items-center")},
                        session.annotations
                        ->Array.map(ann => {
                          let pos = if session.durationMs > 0.0 {
                            ann.timestamp *. 1000.0 /. session.durationMs *. 100.0
                          } else {
                            0.0
                          }
                          div(
                            list{
                              Attrs.class_("absolute w-1 h-full bg-yellow-500 opacity-70"),
                              Attrs.style("left", Float.toFixed(pos, ~digits=1) ++ "%"),
                            },
                            list{},
                          )
                        })
                        ->List.fromArray,
                      ),
                    },
                  ),
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("Press Record to begin capturing a playtest session.")},
              )
            }
          | Replay =>
            switch state.currentSession {
            | Some(session) =>
              div(
                list{Attrs.class_("space-y-3")},
                list{
                  div(
                    list{Attrs.class_("text-sm text-red-300 font-bold")},
                    list{text(session.name)},
                  ),
                  div(
                    list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
                    list{
                      span(list{}, list{text("Started: " ++ session.startedAt)}),
                      span(list{}, list{text("Duration: " ++ formatDuration(session.durationMs))}),
                      span(list{}, list{text("Actions: " ++ Int.toString(session.actionCount))}),
                    },
                  ),
                  // Playback timeline
                  div(
                    list{Attrs.class_("w-full h-3 bg-gray-800 rounded overflow-hidden")},
                    list{
                      div(
                        list{
                          Attrs.class_("h-full bg-green-500 transition-all"),
                          Attrs.style(
                            "width",
                            switch state.playback {
                            | Playing(t) | Paused(t) =>
                              Float.toFixed(
                                if session.durationMs > 0.0 {
                                  t *. 1000.0 /. session.durationMs *. 100.0
                                } else {
                                  0.0
                                },
                                ~digits=1,
                              ) ++ "%"
                            | _ => "0%"
                            },
                          ),
                        },
                        list{},
                      ),
                    },
                  ),
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("Select a session to replay.")},
              )
            }
          | Annotations =>
            div(
              list{Attrs.class_("space-y-2")},
              state.annotations
              ->Array.map(ann => {
                let isSelected = state.selectedAnnotation == Some(ann.id)
                div(
                  list{
                    Attrs.class_(
                      "px-3 py-2 border rounded " ++ if isSelected {
                        "bg-red-900/20 border-red-700"
                      } else {
                        "bg-gray-900 border-gray-800"
                      },
                    ),
                  },
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        span(
                          list{Attrs.class_("text-xs text-gray-500 font-mono w-16")},
                          list{text(Float.toFixed(ann.timestamp, ~digits=1) ++ "s")},
                        ),
                        categoryBadge(ann.category),
                        span(
                          list{Attrs.class_("text-sm text-gray-200 flex-1")},
                          list{text(ann.text)},
                        ),
                      },
                    ),
                    switch ann.screenshotPath {
                    | Some(path) =>
                      div(
                        list{Attrs.class_("text-xs text-gray-500 mt-1 font-mono")},
                        list{text("Screenshot: " ++ path)},
                      )
                    | None => Tea_Html.noNode
                    },
                  },
                )
              })
              ->List.fromArray,
            )
          | Sessions =>
            div(
              list{Attrs.class_("space-y-2")},
              state.sessions
              ->Array.map(s =>
                div(
                  list{
                    Attrs.class_(
                      "px-3 py-2 bg-gray-900 border border-gray-800 rounded cursor-pointer hover:border-gray-700",
                    ),
                  },
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between")},
                      list{
                        span(
                          list{Attrs.class_("text-sm font-bold text-gray-200")},
                          list{text(s.name)},
                        ),
                        span(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(formatDuration(s.durationMs))},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("flex gap-4 text-xs text-gray-500 mt-1")},
                      list{
                        span(list{}, list{text("Started: " ++ s.startedAt)}),
                        span(list{}, list{text(Int.toString(s.actionCount) ++ " actions")}),
                        span(
                          list{},
                          list{text(Int.toString(Array.length(s.annotations)) ++ " annotations")},
                        ),
                      },
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
