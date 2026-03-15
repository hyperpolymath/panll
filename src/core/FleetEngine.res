// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Fleet Engine — pure computation for the Gitbot-Fleet panel.
///
/// Parses fleet API responses, computes health aggregates, filters and
/// sorts findings, and provides display helpers for the view layer.
/// No side effects — all state transitions are deterministic.

open FleetModel

/// Human-readable label for a bot ID.
let botLabel = (id: botId): string =>
  switch id {
  | Rhodibot => "Rhodibot"
  | Echidnabot => "Echidnabot"
  | Sustainabot => "Sustainabot"
  | Glambot => "Glambot"
  | Seambot => "Seambot"
  | Finishbot => "Finishbot"
  }

/// Short description of what each bot does.
let botDescription = (id: botId): string =>
  switch id {
  | Rhodibot => "Code quality & style enforcement"
  | Echidnabot => "Security vulnerability detection"
  | Sustainabot => "Dependency health & sustainability"
  | Glambot => "Documentation & presentation quality"
  | Seambot => "Integration & API compatibility"
  | Finishbot => "CI/CD completion & release readiness"
  }

/// Icon identifier for each bot.
let botIcon = (id: botId): string =>
  switch id {
  | Rhodibot => "shield-check"
  | Echidnabot => "bug"
  | Sustainabot => "leaf"
  | Glambot => "sparkles"
  | Seambot => "link"
  | Finishbot => "flag"
  }

/// Human-readable label for a bot status.
let statusLabel = (status: botStatus): string =>
  switch status {
  | BotActive => "Active"
  | BotIdle => "Idle"
  | BotOffline => "Offline"
  | BotError(e) => `Error: ${e}`
  }

/// CSS class for bot status indicator dot.
let statusColor = (status: botStatus): string =>
  switch status {
  | BotActive => "bg-green-400"
  | BotIdle => "bg-yellow-400"
  | BotOffline => "bg-gray-500"
  | BotError(_) => "bg-red-400"
  }

/// Human-readable label for a safety tier.
let tierLabel = (tier: safetyTier): string =>
  switch tier {
  | Eliminate => "Eliminate"
  | Substitute => "Substitute"
  | Control => "Control"
  }

/// CSS class for safety tier badge.
let tierColor = (tier: safetyTier): string =>
  switch tier {
  | Eliminate => "bg-red-600 text-red-100"
  | Substitute => "bg-amber-600 text-amber-100"
  | Control => "bg-blue-600 text-blue-100"
  }

/// Human-readable label for a fleet category tab.
let categoryLabel = (cat: fleetCategory): string =>
  switch cat {
  | FleetDashboard => "Dashboard"
  | FleetFindings => "Findings"
  | FleetDispatch => "Dispatch"
  }

/// Compute aggregate health from bot states and findings.
let computeHealth = (bots: array<botState>, findings: array<fleetFinding>): fleetHealth => {
  let activeBots = bots->Array.filter(b =>
    switch b.status {
    | BotActive => true
    | _ => false
    }
  )->Array.length

  let totalQueued = findings->Array.filter(f => !f.resolved)->Array.length
  let totalProcessed = findings->Array.filter(f => f.resolved)->Array.length

  let confidences = findings->Array.filter(f => !f.resolved)->Array.map(f => f.confidence)
  let avgConfidence = if Array.length(confidences) > 0 {
    confidences->Array.reduce(0.0, (acc, c) => acc +. c) /. Int.toFloat(Array.length(confidences))
  } else {
    0.0
  }

  let elim = findings->Array.filter(f => f.tier === Eliminate && !f.resolved)->Array.length
  let sub = findings->Array.filter(f => f.tier === Substitute && !f.resolved)->Array.length
  let ctrl = findings->Array.filter(f => f.tier === Control && !f.resolved)->Array.length

  {
    activeBots,
    totalQueued,
    totalProcessed,
    avgConfidence,
    triangleCounts: (elim, sub, ctrl),
  }
}

/// Filter findings by text search across repo name and summary.
let filterFindings = (findings: array<fleetFinding>, query: string): array<fleetFinding> => {
  if query === "" {
    findings
  } else {
    let q = String.toLowerCase(query)
    findings->Array.filter(f =>
      String.includes(String.toLowerCase(f.repoName), q) ||
      String.includes(String.toLowerCase(f.summary), q)
    )
  }
}

/// Parse a bot ID string into a botId variant.
let parseBotId = (s: string): option<botId> =>
  switch s {
  | "rhodibot" => Some(Rhodibot)
  | "echidnabot" => Some(Echidnabot)
  | "sustainabot" => Some(Sustainabot)
  | "glambot" => Some(Glambot)
  | "seambot" => Some(Seambot)
  | "finishbot" => Some(Finishbot)
  | _ => None
  }

/// Parse a bot status string into a botStatus variant.
let parseBotStatus = (s: string): botStatus =>
  switch s {
  | "active" => BotActive
  | "idle" => BotIdle
  | "offline" => BotOffline
  | _ => BotError(s)
  }

/// Tea_Json decoder for a single bot state.
/// Uses map6 to decode fields, then validates the bot ID.
let botStateDecoder: Tea_Json.decoder<botState> = json => {
  open Decoders
  open Tea_Json
  let inner = map6(
    (idStr, statusStr, queued, processed, confThresh, lastAct) =>
      (idStr, statusStr, queued, processed, confThresh, lastAct),
    stringField("id"),
    stringField("status"),
    intField("queued"),
    intField("processed"),
    floatField("confidence_threshold"),
    stringField("last_activity"),
  )
  switch inner(json) {
  | Ok((idStr, statusStr, queued, processed, confThresh, lastAct)) =>
    switch parseBotId(idStr) {
    | Some(botId) =>
      Ok({
        id: botId,
        status: parseBotStatus(statusStr),
        queuedFindings: queued,
        processedFindings: processed,
        confidenceThreshold: confThresh,
        lastActivity: lastAct,
      }: botState)
    | None => Error(Failure(`Unknown bot id: ${idStr}`, json))
    }
  | Error(e) => Error(e)
  }
}

/// Parse bot status from the fleet API JSON response.
/// Expected shape: [{ "id": "rhodibot", "status": "active", "queued": 5, ... }]
let parseBots = (json: string): result<array<botState>, string> =>
  Decoders.decode(Decoders.lenientArray(botStateDecoder), json)

/// Parse a safety tier string into a safetyTier variant.
let parseSafetyTier = (s: string): safetyTier =>
  switch s {
  | "eliminate" => Eliminate
  | "substitute" => Substitute
  | _ => Control
  }

/// Tea_Json decoder for a single fleet finding.
let findingDecoder: Tea_Json.decoder<fleetFinding> = {
  open Decoders
  open Tea_Json
  map7(
    (id, repoName, summary, tierStr, confidence, assignedStr, resolved) => ({
      id,
      repoName,
      summary,
      tier: parseSafetyTier(tierStr),
      confidence,
      assignedBot: parseBotId(assignedStr),
      resolved,
    }: fleetFinding),
    stringField("id"),
    stringField("repo_name"),
    stringField("summary"),
    stringField("tier"),
    floatField("confidence"),
    stringField("assigned_bot"),
    boolField("resolved"),
  )
}

/// Parse findings from the fleet API JSON response.
let parseFindings = (json: string): result<array<fleetFinding>, string> =>
  Decoders.decode(Decoders.lenientArray(findingDecoder), json)

/// Default initial state.
let defaultState: fleetState = {
  loaded: false,
  loading: false,
  error: None,
  bots: [],
  findings: [],
  health: None,
  activeCategory: FleetDashboard,
  filterText: "",
}
