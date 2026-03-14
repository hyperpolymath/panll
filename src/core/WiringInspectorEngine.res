// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Wiring Inspector Engine — pure computation helpers for PCC state.
///
/// All functions here are pure: no side effects, no Tauri calls.
/// They transform PCC JSON into domain types and provide view helpers
/// for status labels, colours, filtering, and sorting.

open WiringInspectorModel

/// Initial state — no results, no selection, no error.
let defaultState: wiringInspectorState = {
  loading: false,
  lastRunAt: None,
  results: [],
  selectedPanel: None,
  filterStatus: None,
  error: None,
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
    return {
      panelId: obj.panel_id || "",
      status: obj.status || "incomplete",
      total: summary.total || 0,
      satisfied: summary.satisfied || 0,
      unsatisfied: summary.unsatisfied || 0,
      blocked: summary.blocked || 0,
      primaryBottleneck: obj.primary_bottleneck || undefined,
      obligations: obligations,
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
