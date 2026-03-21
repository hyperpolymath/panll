// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — Timeline Engine (Layer 2)
///
/// Pure computation for VeriSimDB-backed development timeline data. Tracks
/// snapshot-based metrics over time: lines of code, TODO/FIXME counts, tag
/// density, library count, type check failures, panic-attack findings,
/// AI attribution percentage, and vexometer readings.
///
/// Each snapshot captures a moment-in-time view of a codebase. Snapshots are
/// appended to a timeline array (capped at 1000 entries). From the timeline,
/// the engine derives trend analysis, sparkline data, and metric summaries
/// for display in the Code MRI dashboard panel.
///
/// All functions are pure — no side effects. VeriSimDB persistence and commit
/// hook integration happen in the command layer (TimelineCmd).
///
/// DESIGN NOTE: The timeline is intentionally append-only with a hard cap.
/// This matches VeriSimDB's immutable-log semantics and prevents unbounded
/// memory growth. The 1000-entry cap covers ~3 years of daily snapshots,
/// which is sufficient for trend detection. Older data lives in VeriSimDB
/// and can be queried separately for historical analysis.

// ===========================================================================
// Types
// ===========================================================================

/// A single point-in-time snapshot of codebase metrics.
///
/// Captured at each commit (or on demand) and stored in the timeline.
/// All counts are non-negative integers; percentages are 0.0–100.0.
type timelineSnapshot = {
  /// ISO 8601 timestamp of when this snapshot was taken.
  timestamp: string,
  /// Total lines of code (excluding blanks and comments where possible).
  linesOfCode: int,
  /// Number of TODO comments found in the codebase.
  todoCount: int,
  /// Number of FIXME comments found in the codebase.
  fixmeCount: int,
  /// Number of Code MRI tags (Layer 0 voice tags) present.
  tagCount: int,
  /// Number of external library dependencies.
  libraryCount: int,
  /// Number of failed type checks in the last build.
  failedTypeChecks: int,
  /// Number of findings from panic-attack security scanner.
  panicAttackFindings: int,
  /// Percentage of code attributed to AI (0.0–100.0).
  aiAttributionPercent: float,
  /// Current vexometer reading (developer friction score, 0.0–100.0).
  vexometerReading: float,
  /// Git commit hash at the time of this snapshot.
  commitHash: string,
}

/// Direction a metric is moving over recent history.
///
/// Computed from the last 3+ data points in the sparkline.
type timelineTrend =
  /// Last 3 values are monotonically increasing.
  | Rising
  /// Last 3 values are monotonically decreasing.
  | Falling
  /// Last 3 values are within 5% of each other (relative to max).
  | Stable
  /// Values are oscillating with no clear direction.
  | Volatile

/// A single named metric extracted from the timeline, with trend data.
///
/// Used by the dashboard to render metric cards with sparklines.
type timelineMetric = {
  /// Human-readable metric name (e.g. "Lines of Code").
  name: string,
  /// Current value (most recent snapshot).
  current: float,
  /// Previous value (second most recent snapshot).
  previous: float,
  /// Computed trend direction.
  trend: timelineTrend,
  /// Recent values for sparkline rendering (newest last).
  sparkline: array<float>,
}

// ===========================================================================
// Constants
// ===========================================================================

/// Maximum number of snapshots retained in a timeline.
/// Older entries are dropped when this limit is exceeded.
let maxTimelineLength = 1000

/// Number of recent values used for sparkline rendering.
let defaultSparklineCount = 20

/// Number of recent values examined when computing trend direction.
let trendWindowSize = 3

// ===========================================================================
// Snapshot operations
// ===========================================================================

/// Create a default (zeroed) snapshot with empty timestamp and commit hash.
///
/// Useful as a fallback or initial value before real data is available.
let defaultSnapshot = (): timelineSnapshot => {
  timestamp: "",
  linesOfCode: 0,
  todoCount: 0,
  fixmeCount: 0,
  tagCount: 0,
  libraryCount: 0,
  failedTypeChecks: 0,
  panicAttackFindings: 0,
  aiAttributionPercent: 0.0,
  vexometerReading: 0.0,
  commitHash: "",
}

/// Append a snapshot to the timeline, enforcing the 1000-entry cap.
///
/// If the timeline is at capacity, the oldest entry is dropped to make room.
/// The new snapshot is always appended at the end (newest-last ordering).
///
/// @param timeline The existing timeline array
/// @param snap     The new snapshot to append
/// @returns Updated timeline with the snapshot added and cap enforced
let addSnapshot = (
  timeline: array<timelineSnapshot>,
  snap: timelineSnapshot,
): array<timelineSnapshot> => {
  let combined = Array.concat(timeline, [snap])
  let len = Array.length(combined)
  if len > maxTimelineLength {
    // Drop oldest entries to stay within the cap
    combined->Array.slice(~start=len - maxTimelineLength, ~end=len)
  } else {
    combined
  }
}

/// Get the most recent snapshot from a timeline.
///
/// @param timeline The timeline to query
/// @returns Some(snapshot) if the timeline is non-empty, None otherwise
let latestSnapshot = (timeline: array<timelineSnapshot>): option<timelineSnapshot> => {
  let len = Array.length(timeline)
  if len === 0 {
    None
  } else {
    Some(timeline->Array.getUnsafe(len - 1))
  }
}

/// Compute the delta (difference) between two snapshots.
///
/// For integer fields, returns (b - a). For float fields, returns (b -. a).
/// String fields (timestamp, commitHash) are taken from snapshot `b`.
/// This is useful for showing "what changed since last snapshot".
///
/// @param a The earlier snapshot (baseline)
/// @param b The later snapshot (current)
/// @returns A snapshot where each numeric field is the difference (b - a)
let snapshotDelta = (a: timelineSnapshot, b: timelineSnapshot): timelineSnapshot => {
  {
    timestamp: b.timestamp,
    linesOfCode: b.linesOfCode - a.linesOfCode,
    todoCount: b.todoCount - a.todoCount,
    fixmeCount: b.fixmeCount - a.fixmeCount,
    tagCount: b.tagCount - a.tagCount,
    libraryCount: b.libraryCount - a.libraryCount,
    failedTypeChecks: b.failedTypeChecks - a.failedTypeChecks,
    panicAttackFindings: b.panicAttackFindings - a.panicAttackFindings,
    aiAttributionPercent: b.aiAttributionPercent -. a.aiAttributionPercent,
    vexometerReading: b.vexometerReading -. a.vexometerReading,
    commitHash: b.commitHash,
  }
}

// ===========================================================================
// Trend computation
// ===========================================================================

/// Determine the trend direction from an array of recent float values.
///
/// Examines the last 3 values (configurable via trendWindowSize):
///   - Rising:   each value > previous value
///   - Falling:  each value < previous value
///   - Stable:   all values within 5% of max value in window
///   - Volatile: none of the above patterns match
///
/// Returns Stable for arrays shorter than 2 elements (insufficient data).
///
/// @param values Array of metric values (oldest first, newest last)
/// @returns The detected trend direction
let computeTrend = (values: array<float>): timelineTrend => {
  let len = Array.length(values)
  if len < 2 {
    Stable
  } else {
    // Take the last `trendWindowSize` values (or all if fewer)
    let windowStart = if len > trendWindowSize { len - trendWindowSize } else { 0 }
    let window = values->Array.slice(~start=windowStart, ~end=len)
    let windowLen = Array.length(window)

    if windowLen < 2 {
      Stable
    } else {
      // Check if monotonically rising
      let rising = ref(true)
      // Check if monotonically falling
      let falling = ref(true)
      for i in 1 to windowLen - 1 {
        let prev = window->Array.getUnsafe(i - 1)
        let curr = window->Array.getUnsafe(i)
        if curr <= prev {
          rising := false
        }
        if curr >= prev {
          falling := false
        }
      }

      if rising.contents {
        Rising
      } else if falling.contents {
        Falling
      } else {
        // Check for stability: all values within 5% of max
        let maxVal = window->Array.reduce(0.0, (acc, v) =>
          if v > acc { v } else { acc }
        )
        let threshold = if maxVal === 0.0 { 0.05 } else { maxVal *. 0.05 }
        let minVal = window->Array.reduce(maxVal, (acc, v) =>
          if v < acc { v } else { acc }
        )
        if maxVal -. minVal <= threshold {
          Stable
        } else {
          Volatile
        }
      }
    }
  }
}

// ===========================================================================
// Sparkline extraction
// ===========================================================================

/// Extract the last N values of a metric from the timeline.
///
/// Applies the `extract` function to each snapshot to pull out the desired
/// metric, then returns the last `count` values (or fewer if the timeline
/// is shorter). Result is ordered oldest-first for sparkline rendering.
///
/// @param timeline The timeline to extract from
/// @param extract  Function that pulls a float metric from a snapshot
/// @param count    Maximum number of recent values to return
/// @returns Array of float values (oldest first, newest last)
let sparklineData = (
  timeline: array<timelineSnapshot>,
  extract: timelineSnapshot => float,
  count: int,
): array<float> => {
  let allValues = timeline->Array.map(extract)
  let len = Array.length(allValues)
  if len <= count {
    allValues
  } else {
    allValues->Array.slice(~start=len - count, ~end=len)
  }
}

// ===========================================================================
// Metric builders
//
// Each function extracts a specific metric from the timeline, computing
// current/previous values, trend, and sparkline data. They all follow
// the same structure to keep the dashboard rendering uniform.
// ===========================================================================

/// Helper: build a timelineMetric from a timeline and an extractor function.
///
/// @param timeline The timeline data source
/// @param name     Human-readable metric name
/// @param extract  Function to pull a float value from a snapshot
/// @returns A fully populated timelineMetric
let buildMetric = (
  timeline: array<timelineSnapshot>,
  name: string,
  extract: timelineSnapshot => float,
): timelineMetric => {
  let len = Array.length(timeline)
  let current = if len > 0 {
    extract(timeline->Array.getUnsafe(len - 1))
  } else {
    0.0
  }
  let previous = if len > 1 {
    extract(timeline->Array.getUnsafe(len - 2))
  } else {
    0.0
  }
  let sparkline = sparklineData(timeline, extract, defaultSparklineCount)
  let trend = computeTrend(sparkline)
  { name, current, previous, trend, sparkline }
}

/// Lines of code metric — tracks codebase size over time.
let locMetric = (timeline: array<timelineSnapshot>): timelineMetric => {
  buildMetric(timeline, "Lines of Code", snap => Float.fromInt(snap.linesOfCode))
}

/// TODO count metric — tracks outstanding TODO comments.
let todoMetric = (timeline: array<timelineSnapshot>): timelineMetric => {
  buildMetric(timeline, "TODO Count", snap => Float.fromInt(snap.todoCount))
}

/// AI attribution metric — percentage of code attributed to AI tools.
let aiAttributionMetric = (timeline: array<timelineSnapshot>): timelineMetric => {
  buildMetric(timeline, "AI Attribution %", snap => snap.aiAttributionPercent)
}

/// Vexometer metric — developer friction score (lower is better).
let vexometerMetric = (timeline: array<timelineSnapshot>): timelineMetric => {
  buildMetric(timeline, "Vexometer", snap => snap.vexometerReading)
}

/// Panic-attack findings metric — security scanner issue count.
let panicMetric = (timeline: array<timelineSnapshot>): timelineMetric => {
  buildMetric(timeline, "Panic-Attack Findings", snap =>
    Float.fromInt(snap.panicAttackFindings)
  )
}

/// All tracked metrics in a single array, for dashboard rendering.
///
/// Returns metrics in display order: LOC, TODO, AI Attribution,
/// Vexometer, Panic-Attack Findings.
///
/// @param timeline The timeline data source
/// @returns Array of all five core metrics
let allMetrics = (timeline: array<timelineSnapshot>): array<timelineMetric> => {
  [
    locMetric(timeline),
    todoMetric(timeline),
    aiAttributionMetric(timeline),
    vexometerMetric(timeline),
    panicMetric(timeline),
  ]
}

// ===========================================================================
// Trend display helpers
// ===========================================================================

/// Human-readable label for a trend direction.
///
/// @param trend The trend to label
/// @returns One of "Rising", "Falling", "Stable", "Volatile"
let trendLabel = (trend: timelineTrend): string => {
  switch trend {
  | Rising => "Rising"
  | Falling => "Falling"
  | Stable => "Stable"
  | Volatile => "Volatile"
  }
}

/// Unicode arrow icon for a trend direction.
///
/// Used in compact metric displays alongside the numeric value.
///
/// @param trend The trend to represent
/// @returns Unicode arrow character
let trendIcon = (trend: timelineTrend): string => {
  switch trend {
  | Rising => "\u2191"    // ↑ upwards arrow
  | Falling => "\u2193"   // ↓ downwards arrow
  | Stable => "\u2192"    // → rightwards arrow
  | Volatile => "\u2195"  // ↕ up down arrow
  }
}

/// Tailwind CSS colour class for a trend direction.
///
/// Used to colour-code trend indicators in the dashboard:
///   - Rising:   amber (could be good or bad depending on metric)
///   - Falling:  blue (could be good or bad depending on metric)
///   - Stable:   green (consistency is generally good)
///   - Volatile: red (instability is generally concerning)
///
/// Note: The caller should invert semantics for metrics where "rising"
/// is bad (e.g. TODO count, vexometer, panic findings).
///
/// @param trend The trend to colour
/// @returns Tailwind text colour class
let trendColor = (trend: timelineTrend): string => {
  switch trend {
  | Rising => "text-amber-400"
  | Falling => "text-blue-400"
  | Stable => "text-green-400"
  | Volatile => "text-red-400"
  }
}
