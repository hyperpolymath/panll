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

/// Parse bot status from the fleet API JSON response.
/// Expected shape: [{ "id": "rhodibot", "status": "active", "queued": 5, ... }]
let parseBots = (json: string): result<array<botState>, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(items) =>
      let bots = items->Array.filterMap(item => {
        switch JSON.Classify.classify(item) {
        | Object(obj) => {
            let getString = (key: string): string =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | String(s) => s
                | _ => ""
                }
              | None => ""
              }
            let getInt = (key: string): int =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => Float.toInt(n)
                | _ => 0
                }
              | None => 0
              }
            let getFloat = (key: string): float =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => n
                | _ => 0.0
                }
              | None => 0.0
              }

            let idStr = getString("id")
            let id = switch idStr {
            | "rhodibot" => Some(Rhodibot)
            | "echidnabot" => Some(Echidnabot)
            | "sustainabot" => Some(Sustainabot)
            | "glambot" => Some(Glambot)
            | "seambot" => Some(Seambot)
            | "finishbot" => Some(Finishbot)
            | _ => None
            }

            let statusStr = getString("status")
            let status = switch statusStr {
            | "active" => BotActive
            | "idle" => BotIdle
            | "offline" => BotOffline
            | _ => BotError(statusStr)
            }

            switch id {
            | Some(botId) =>
              Some({
                id: botId,
                status,
                queuedFindings: getInt("queued"),
                processedFindings: getInt("processed"),
                confidenceThreshold: getFloat("confidence_threshold"),
                lastActivity: getString("last_activity"),
              })
            | None => None
            }
          }
        | _ => None
        }
      })
      Ok(bots)
    | _ => Error("Expected array of bot states")
    }
  } catch {
  | _ => Error("Failed to parse fleet status JSON")
  }
}

/// Parse findings from the fleet API JSON response.
let parseFindings = (json: string): result<array<fleetFinding>, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(items) =>
      let findings = items->Array.filterMap(item => {
        switch JSON.Classify.classify(item) {
        | Object(obj) => {
            let getString = (key: string): string =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | String(s) => s
                | _ => ""
                }
              | None => ""
              }
            let getFloat = (key: string): float =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => n
                | _ => 0.0
                }
              | None => 0.0
              }
            let getBool = (key: string): bool =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Bool(b) => b
                | _ => false
                }
              | None => false
              }

            let tierStr = getString("tier")
            let tier = switch tierStr {
            | "eliminate" => Eliminate
            | "substitute" => Substitute
            | _ => Control
            }

            let assignedStr = getString("assigned_bot")
            let assignedBot = switch assignedStr {
            | "rhodibot" => Some(Rhodibot)
            | "echidnabot" => Some(Echidnabot)
            | "sustainabot" => Some(Sustainabot)
            | "glambot" => Some(Glambot)
            | "seambot" => Some(Seambot)
            | "finishbot" => Some(Finishbot)
            | _ => None
            }

            Some({
              id: getString("id"),
              repoName: getString("repo_name"),
              summary: getString("summary"),
              tier,
              confidence: getFloat("confidence"),
              assignedBot,
              resolved: getBool("resolved"),
            })
          }
        | _ => None
        }
      })
      Ok(findings)
    | _ => Error("Expected array of findings")
    }
  } catch {
  | _ => Error("Failed to parse findings JSON")
  }
}

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
