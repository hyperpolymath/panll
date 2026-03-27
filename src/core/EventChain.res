// SPDX-License-Identifier: PMPL-1.0-or-later

/// Event-chain parsing helpers for PanLL.
///
/// Parses panic-attack PanLL export JSON into lightweight model state.

open Model

type payload = {
  summary: option<eventChainSummary>,
  timeline: option<eventChainTimeline>,
  events: array<eventChainEvent>,
}

/// Tea_Json decoder for an event chain summary.
let summaryDecoder: Tea_Json.decoder<eventChainSummary> = {
  open Decoders
  open Tea_Json
  map5(
    (program, weakPoints, criticalWeakPoints, totalCrashes, robustnessScore): eventChainSummary => {
      program,
      weakPoints,
      criticalWeakPoints,
      totalCrashes,
      robustnessScore,
    },
    stringField("program"),
    intField("weak_points"),
    intField("critical_weak_points"),
    intField("total_crashes"),
    floatField("robustness_score"),
  )
}

/// Tea_Json decoder for an event chain timeline.
let timelineDecoder: Tea_Json.decoder<eventChainTimeline> = {
  open Decoders
  open Tea_Json
  map2((durationMs, events): eventChainTimeline => {
    durationMs,
    events,
  }, floatField("duration_ms"), intField("events"))
}

/// Tea_Json decoder for a single event chain event.
let eventDecoder: Tea_Json.decoder<eventChainEvent> = {
  open Decoders
  open Tea_Json
  map8((id, axis, startMs, durationMs, intensity, status, peakMemory, notes): eventChainEvent => {
    id,
    axis,
    startMs,
    durationMs,
    intensity,
    status,
    peakMemory,
    notes,
  }, stringField(
    "id",
  ), fieldWithDefault(
    "axis",
    string,
    "unknown",
  ), optionalFieldDecoder(
    "start_ms",
    float,
  ), floatField(
    "duration_ms",
  ), fieldWithDefault(
    "intensity",
    string,
    "unknown",
  ), fieldWithDefault(
    "status",
    string,
    "unknown",
  ), optionalFieldDecoder("peak_memory", float), optionalFieldDecoder("notes", string))
}

/// Tea_Json decoder for the full event-chain payload.
let payloadDecoder: Tea_Json.decoder<payload> = {
  open Decoders
  open Tea_Json
  map3((summary, timeline, events): payload => {
    summary,
    timeline,
    events,
  }, optionalFieldDecoder(
    "summary",
    summaryDecoder,
  ), optionalFieldDecoder(
    "timeline",
    timelineDecoder,
  ), fieldWithDefault("event_chain", lenientArray(eventDecoder), []))
}

/// Parse a panic-attack PanLL export JSON into a payload.
let parse = (raw: string): result<payload, string> => Decoders.decode(payloadDecoder, raw)
