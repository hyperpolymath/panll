// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Wiring Inspector Engine — pure computation helpers for PCC state.
///
/// All functions here are pure: no side effects, no Tauri calls.
/// They transform PCC JSON into domain types and provide view helpers
/// for status labels, colours, filtering, and sorting.

open WiringInspectorModel

/// Empty state distribution — all counts zero.
let emptyDistribution: stateDistribution = {
  total: 0,
  releasable: 0,
  viable: 0,
  wired: 0,
  draft: 0,
  broken: 0,
}

/// Initial state — no results, no selection, no error.
let defaultState: wiringInspectorState = {
  loading: false,
  lastRunAt: None,
  results: [],
  selectedPanel: None,
  filterStatus: None,
  error: None,
  activeTab: Overview,
  distribution: emptyDistribution,
  bottlenecks: [],
  sortBy: "blockedCount",
}

// ════════════════════════════════════════════════════════════════════════
// Status label and colour helpers
// ════════════════════════════════════════════════════════════════════════

/// Human-readable label for an obligation status.
let statusLabel = (status: obligationStatus): string =>
  switch status {
  | Satisfied => "Satisfied"
  | Unsatisfied => "Unsatisfied"
  | Blocked => "Blocked"
  }

/// Tailwind colour class for an obligation status.
let statusColor = (status: obligationStatus): string =>
  switch status {
  | Satisfied => "text-green-400"
  | Unsatisfied => "text-red-400"
  | Blocked => "text-yellow-400"
  }

/// Human-readable label for a failure class.
let failureClassLabel = (fc: failureClass): string =>
  switch fc {
  | Root => "Root"
  | Derived => "Derived"
  | NotFailed => ""
  }

/// Human-readable label for repairability.
let repairabilityLabel = (r: repairability): string =>
  switch r {
  | Safe => "safe"
  | Unsafe => "unsafe"
  | Manual => "manual"
  }

/// Tailwind colour class for repairability.
let repairabilityColor = (r: repairability): string =>
  switch r {
  | Safe => "text-green-400"
  | Unsafe => "text-red-400"
  | Manual => "text-amber-400"
  }

// ════════════════════════════════════════════════════════════════════════
// Panel lifecycle state helpers (Phase 5)
// ════════════════════════════════════════════════════════════════════════

/// Parse a PCC state string into a panelState variant.
let parseState = (s: string): panelState =>
  switch s {
  | "draft" => Draft
  | "wired" => Wired
  | "viable" => Viable
  | "releasable" => Releasable
  | "broken" => Broken
  | _ => Draft
  }

/// Human-readable uppercase label for a panel lifecycle state.
let stateLabel = (s: panelState): string =>
  switch s {
  | Draft => "DRAFT"
  | Wired => "WIRED"
  | Viable => "VIABLE"
  | Releasable => "RELEASABLE"
  | Broken => "BROKEN"
  }

/// Tailwind text colour class for a panel lifecycle state.
let stateColor = (s: panelState): string =>
  switch s {
  | Draft => "text-yellow-400"
  | Wired => "text-blue-400"
  | Viable => "text-cyan-400"
  | Releasable => "text-green-400"
  | Broken => "text-red-400"
  }

/// Tailwind background colour class for a panel lifecycle state.
let stateBgColor = (s: panelState): string =>
  switch s {
  | Draft => "bg-yellow-900/30"
  | Wired => "bg-blue-900/30"
  | Viable => "bg-cyan-900/30"
  | Releasable => "bg-green-900/30"
  | Broken => "bg-red-900/30"
  }

/// Tailwind border colour class for a panel lifecycle state.
let stateBorderColor = (s: panelState): string =>
  switch s {
  | Draft => "border-yellow-800"
  | Wired => "border-blue-800"
  | Viable => "border-cyan-800"
  | Releasable => "border-green-800"
  | Broken => "border-red-800"
  }

/// Count panels per lifecycle state across all verification results.
let computeDistribution = (results: array<panelVerification>): stateDistribution => {
  let total = Array.length(results)
  let count = (target: panelState) =>
    results->Array.filter(v => v.policy.state == target)->Array.length
  {
    total,
    releasable: count(Releasable),
    viable: count(Viable),
    wired: count(Wired),
    draft: count(Draft),
    broken: count(Broken),
  }
}

/// Extract all root-failure obligations with blockedDownstreamCount > 0
/// across all panels, sorted by blocked count descending.
let extractBottlenecks = (results: array<panelVerification>): array<bottleneck> => {
  let all =
    results
    ->Array.flatMap(v =>
      v.obligations
      ->Array.filter(o => o.failureClass == Root && o.blockedDownstreamCount > 0)
      ->Array.map(o => {
        let bn: bottleneck = {
          panelId: v.panelId,
          obligationId: o.id,
          kind: o.kind,
          blockedCount: o.blockedDownstreamCount,
          repairability: o.repairability,
          message: o.message,
          file: o.file,
        }
        bn
      })
    )
  let copy = Array.copy(all)
  copy->Array.sort((a, b) => Int.compare(b.blockedCount, a.blockedCount))
  copy
}

/// Take the top N bottlenecks from a sorted array.
let topBottlenecks = (bottlenecks: array<bottleneck>, n: int): array<bottleneck> =>
  bottlenecks->Array.slice(~start=0, ~end=n)

/// Filter verification results to only those with the given lifecycle state.
let panelsByState = (results: array<panelVerification>, state: panelState): array<panelVerification> =>
  results->Array.filter(v => v.policy.state == state)

/// Health score: percentage of panels at Viable or above (Viable + Releasable).
/// Returns 0 when there are no panels.
let healthScore = (dist: stateDistribution): int =>
  if dist.total == 0 {
    0
  } else {
    (dist.releasable + dist.viable) * 100 / dist.total
  }

/// Human-readable label for an audit tab.
let tabLabel = (tab: auditTab): string =>
  switch tab {
  | Overview => "Overview"
  | ByState => "By State"
  | Bottlenecks => "Bottlenecks"
  | History => "History"
  }

/// Colour class for the health score badge.
let healthScoreColor = (score: int): string =>
  if score > 80 {
    "text-green-400"
  } else if score > 50 {
    "text-yellow-400"
  } else {
    "text-red-400"
  }

/// Background colour class for the health score badge.
let healthScoreBgColor = (score: int): string =>
  if score > 80 {
    "bg-green-900/30 border-green-800"
  } else if score > 50 {
    "bg-yellow-900/30 border-yellow-800"
  } else {
    "bg-red-900/30 border-red-800"
  }

// ════════════════════════════════════════════════════════════════════════
// Panel verification helpers
// ════════════════════════════════════════════════════════════════════════

/// Whether all obligations for a panel are satisfied.
let isComplete = (v: panelVerification): bool =>
  v.unsatisfied == 0 && v.blocked == 0

/// Summary label: "COMPLETE (6/6)" or "INCOMPLETE (4/6)".
let summaryLabel = (v: panelVerification): string => {
  let tag = if isComplete(v) { "COMPLETE" } else { "INCOMPLETE" }
  `${tag} (${Int.toString(v.satisfied)}/${Int.toString(v.total)})`
}

/// Filter obligations where failureClass == Root.
let rootFailures = (v: panelVerification): array<obligation> =>
  v.obligations->Array.filter(o => o.failureClass == Root)

/// Filter obligations where failureClass == Derived.
let derivedFailures = (v: panelVerification): array<obligation> =>
  v.obligations->Array.filter(o => o.failureClass == Derived)

/// Filter obligations where status == Satisfied.
let satisfiedObligations = (v: panelVerification): array<obligation> =>
  v.obligations->Array.filter(o => o.status == Satisfied)

/// Sort obligations by blockedDownstreamCount descending (worst bottlenecks first).
let sortByBottleneck = (obligations: array<obligation>): array<obligation> => {
  let copy = Array.copy(obligations)
  copy->Array.sort((a, b) => Int.compare(b.blockedDownstreamCount, a.blockedDownstreamCount))
  copy
}

// ════════════════════════════════════════════════════════════════════════
// Aggregate helpers
// ════════════════════════════════════════════════════════════════════════

/// Total number of panels in the results.
let totalPanels = (results: array<panelVerification>): int =>
  Array.length(results)

/// Number of panels where all obligations are satisfied.
let completePanels = (results: array<panelVerification>): int =>
  results->Array.filter(isComplete)->Array.length

/// Number of panels with at least one unsatisfied or blocked obligation.
let incompletePanels = (results: array<panelVerification>): int =>
  results->Array.filter(v => !isComplete(v))->Array.length

/// Filter results to a specific panel (by panelId string).
let filterByPanel = (results: array<panelVerification>, selectedPanel: option<string>): array<panelVerification> =>
  switch selectedPanel {
  | None => results
  | Some(pid) => results->Array.filter(v => v.panelId == pid)
  }

/// Filter results by completion status string ("Complete" or "Incomplete").
let filterByStatus = (results: array<panelVerification>, filterStatus: option<string>): array<panelVerification> =>
  switch filterStatus {
  | None => results
  | Some("Complete") => results->Array.filter(isComplete)
  | Some("Incomplete") => results->Array.filter(v => !isComplete(v))
  | Some(_) => results
  }

// ════════════════════════════════════════════════════════════════════════
// JSON parsing — PCC output to domain types
// ════════════════════════════════════════════════════════════════════════

/// Parse an obligation status string from PCC JSON.
let parseObligationStatus = (s: string): obligationStatus =>
  switch s {
  | "satisfied" => Satisfied
  | "blocked" => Blocked
  | _ => Unsatisfied
  }

/// Parse a failure class string from PCC JSON.
let parseFailureClass = (s: option<string>): failureClass =>
  switch s {
  | Some("root") => Root
  | Some("derived") => Derived
  | _ => NotFailed
  }

/// Parse a repairability string from PCC JSON.
let parseRepairability = (s: string): repairability =>
  switch s {
  | "unsafe" => Unsafe
  | "manual" => Manual
  | _ => Safe
  }

/// Parse a single obligation JSON object.
/// Uses raw JS interop for JSON field access.
let parseObligation: JSON.t => obligation = %raw(`
  function parseObligation(obj) {
    return {
      id: obj.id || "",
      kind: obj.kind || "",
      panelId: obj.panel_id || "",
      status: obj.status || "unsatisfied",
      failureClass: obj.failure_class || null,
      repairability: obj.repairability || "safe",
      message: obj.message || "",
      file: obj.file || undefined,
      expected: obj.expected || undefined,
      dependsOn: obj.depends_on || [],
      blockedDownstreamCount: obj.blocked_downstream_count || 0,
    };
  }
`)

/// Transform a raw parsed obligation (with string status fields) into the typed domain model.
let typedObligation = (raw: obligation): obligation => {
  ...raw,
  status: parseObligationStatus(statusLabel(raw.status)),
  failureClass: parseFailureClass(
    switch raw.failureClass {
    | Root => Some("root")
    | Derived => Some("derived")
    | NotFailed => None
    }
  ),
  repairability: parseRepairability(repairabilityLabel(raw.repairability)),
}

/// Parse a single panel verification JSON object into typed domain model.
/// The raw parsing uses JS interop, then we refine the typed fields.
/// Extracts Phase 5 policy fields (state, visible, releasable, next_requirement).
let parseSingleVerification: JSON.t => panelVerification = %raw(`
  function parseSingleVerification(obj) {
    var summary = obj.summary || {};
    var obligations = (obj.obligations || []).map(function(o) {
      return {
        id: o.id || "",
        kind: o.kind || "",
        panelId: o.panel_id || obj.panel_id || "",
        status: o.status === "satisfied" ? "Satisfied" : o.status === "blocked" ? "Blocked" : "Unsatisfied",
        failureClass: o.failure_class === "root" ? "Root" : o.failure_class === "derived" ? "Derived" : "NotFailed",
        repairability: o.repairability === "unsafe" ? "Unsafe" : o.repairability === "manual" ? "Manual" : "Safe",
        message: o.message || "",
        file: o.file || undefined,
        expected: o.expected || undefined,
        dependsOn: o.depends_on || [],
        blockedDownstreamCount: o.blocked_downstream_count || 0,
      };
    });
    // Parse lifecycle state — default to "draft" if missing.
    var rawState = obj.state || "draft";
    var stateMap = { draft: "Draft", wired: "Wired", viable: "Viable", releasable: "Releasable", broken: "Broken" };
    var parsedState = stateMap[rawState] || "Draft";
    return {
      panelId: obj.panel_id || "",
      status: obj.status || "incomplete",
      total: summary.total || 0,
      satisfied: summary.satisfied || 0,
      unsatisfied: summary.unsatisfied || 0,
      blocked: summary.blocked || 0,
      primaryBottleneck: obj.primary_bottleneck || undefined,
      obligations: obligations,
      policy: {
        state: parsedState,
        visible: obj.visible !== undefined ? obj.visible : true,
        releasable: obj.releasable !== undefined ? obj.releasable : false,
        nextRequirement: obj.next_requirement || undefined,
      },
    };
  }
`)

/// Parse PCC JSON output (single or multi-panel) into an array of panel verifications.
/// Handles both `{ "panel_id": ... }` (single) and `{ "panels": [...] }` (multi) formats,
/// as well as a bare JSON array.
let parseVerificationJson: string => array<panelVerification> = %raw(`
  function parseVerificationJson(jsonStr) {
    try {
      var parsed = JSON.parse(jsonStr);
      // Array of panel results
      if (Array.isArray(parsed)) {
        return parsed.map(parseSingleVerification);
      }
      // Object with "panels" array
      if (parsed.panels && Array.isArray(parsed.panels)) {
        return parsed.panels.map(parseSingleVerification);
      }
      // Single panel result
      if (parsed.panel_id) {
        return [parseSingleVerification(parsed)];
      }
      return [];
    } catch (_e) {
      return [];
    }
  }
`)
