// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playtest Recorder Engine — pure computation and helpers for
/// recording, replaying, and annotating gameplay sessions.
///
/// Provides default state, tab labels, and utility functions for formatting
/// duration, counting annotations, and computing playback progress.

open PlaytestRecorderModel

/// Default state for the Playtest Recorder panel.
let defaultState: playtestRecorderState = {
  activeTab: Record,
  currentSession: None,
  sessions: [],
  playback: Stopped,
  annotations: [],
  selectedAnnotation: None,
  error: None,
}

/// Human-readable label for a playtest recorder category tab.
let tabLabel = (cat: playtestRecorderCategory): string =>
  switch cat {
  | Record => "Record"
  | Replay => "Replay"
  | Annotations => "Annotations"
  | Sessions => "Sessions"
  }

/// All category tabs in display order.
let allTabs: array<playtestRecorderCategory> = [Record, Replay, Annotations, Sessions]

/// Format a duration in milliseconds as "Xm Ys" or "Xh Ym Zs".
let formatDuration = (ms: float): string => {
  let totalSeconds = ms /. 1000.0
  let hours = Math.floor(totalSeconds /. 3600.0)
  let minutes = Math.floor(mod_float(totalSeconds, 3600.0) /. 60.0)
  let seconds = Math.floor(mod_float(totalSeconds, 60.0))
  if hours > 0.0 {
    `${Float.toInt(hours)->Int.toString}h ${Float.toInt(minutes)->Int.toString}m ${Float.toInt(seconds)->Int.toString}s`
  } else {
    `${Float.toInt(minutes)->Int.toString}m ${Float.toInt(seconds)->Int.toString}s`
  }
}

/// Count total annotations in the current state.
let countAnnotations = (annotations: array<annotation>): int =>
  annotations->Array.length

/// Compute playback progress as a percentage (0.0–100.0).
/// Returns 0.0 if no session is loaded or playback is stopped/recording.
let playbackProgressPercent = (
  playback: playbackState,
  session: option<recordedSession>,
): float =>
  switch (playback, session) {
  | (Playing(t), Some(s)) | (Paused(t), Some(s)) =>
    if s.durationMs > 0.0 {
      t *. 1000.0 /. s.durationMs *. 100.0
    } else {
      0.0
    }
  | _ => 0.0
  }
