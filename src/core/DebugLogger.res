// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Debug Logger — structured logging routed through Observatory.
///
/// Replaces ad-hoc console.log with structured, observable debug output.
/// All log entries become OTLP spans visible in Observatory panel.

/// Log level for structured debug output.
type logLevel =
  | Debug
  | Info
  | Warn
  | Error

/// A structured log entry.
type logEntry = {
  level: logLevel,
  source: string,
  message: string,
  timestamp: float,
  metadata: array<(string, string)>,
}

/// Format log level as string.
let levelLabel = (level: logLevel): string =>
  switch level {
  | Debug => "DEBUG"
  | Info => "INFO"
  | Warn => "WARN"
  | Error => "ERROR"
  }

/// Format log level as OTLP severity number.
let levelToOtelSeverity = (level: logLevel): int =>
  switch level {
  | Debug => 5
  | Info => 9
  | Warn => 13
  | Error => 17
  }

/// Create a log entry.
let makeEntry = (
  level: logLevel,
  source: string,
  message: string,
  ~metadata: array<(string, string)>=[],
): logEntry => {
  level,
  source,
  message,
  timestamp: Date.now(),
  metadata,
}

/// Format entry as OTLP log record (for ObservabilityEngine export).
let toOtelLogRecord = (entry: logEntry): Dict.t<JSON.t> => {
  let dict = Dict.make()
  Dict.set(dict, "timeUnixNano", JSON.Encode.float(entry.timestamp *. 1000000.0))
  Dict.set(dict, "severityNumber", JSON.Encode.int(levelToOtelSeverity(entry.level)))
  Dict.set(dict, "severityText", JSON.Encode.string(levelLabel(entry.level)))
  Dict.set(dict, "body", JSON.Encode.string(entry.message))
  dict
}

/// Ring buffer for recent log entries (last 200).
let maxEntries = 200

/// Add entry to ring buffer.
let addEntry = (entries: array<logEntry>, entry: logEntry): array<logEntry> => {
  let next = Array.concat(entries, [entry])
  if Array.length(next) > maxEntries {
    next->Array.sliceToEnd(~start=Array.length(next) - maxEntries)
  } else {
    next
  }
}

/// Filter entries by level.
let filterByLevel = (entries: array<logEntry>, minLevel: logLevel): array<logEntry> => {
  let minSev = levelToOtelSeverity(minLevel)
  entries->Array.filter(e => levelToOtelSeverity(e.level) >= minSev)
}

/// Filter entries by source.
let filterBySource = (entries: array<logEntry>, source: string): array<logEntry> =>
  entries->Array.filter(e => e.source == source)
