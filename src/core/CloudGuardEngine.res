// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard Engine — Pure computation for compliance evaluation and diff.
///
/// All functions here are pure (no side effects, no API calls). They operate
/// on model data to produce audit findings, compliance scores, setting diffs,
/// and domain filter results.
///
/// This is the computation backend for Panel-W's audit side panel and
/// Panel-L's constraint evaluation. The engine takes live settings + policy
/// constraints and produces structured results for the view layer.

open CloudGuardModel

// ============================================================================
// JSON parsing helpers — extract CF API response data into model types
// ============================================================================

/// Parse a plan name string into a cfPlanTier variant.
let parsePlanTier = (planName: string): cfPlanTier => {
  let lower = String.toLowerCase(planName)
  if String.includes(lower, "enterprise") {
    Enterprise
  } else if String.includes(lower, "business") {
    Business
  } else if String.includes(lower, "pro") {
    Pro
  } else {
    Free
  }
}

/// Parse a DNS record type string into a dnsRecordType variant.
let parseDnsRecordType = (typeStr: string): option<dnsRecordType> => {
  switch String.toUpperCase(typeStr) {
  | "A" => Some(A)
  | "AAAA" => Some(AAAA)
  | "CNAME" => Some(CNAME)
  | "MX" => Some(MX)
  | "TXT" => Some(TXT)
  | "SRV" => Some(SRV)
  | "NS" => Some(NS)
  | "CAA" => Some(CAA)
  | "TLSA" => Some(TLSA)
  | "HTTPS" => Some(HTTPS)
  | "SVCB" => Some(SVCB)
  | "PTR" => Some(PTR)
  | "LOC" => Some(LOC)
  | _ => None
  }
}

/// Stringify a dnsRecordType for display.
let dnsRecordTypeLabel = (rt: dnsRecordType): string => {
  switch rt {
  | A => "A"
  | AAAA => "AAAA"
  | CNAME => "CNAME"
  | MX => "MX"
  | TXT => "TXT"
  | SRV => "SRV"
  | NS => "NS"
  | CAA => "CAA"
  | TLSA => "TLSA"
  | HTTPS => "HTTPS"
  | SVCB => "SVCB"
  | PTR => "PTR"
  | LOC => "LOC"
  }
}

// ============================================================================
// Setting value helpers
// ============================================================================

/// Stringify a settingValue for display in the UI.
let settingValueToString = (v: settingValue): string => {
  switch v {
  | BoolValue(b) => b ? "On" : "Off"
  | StringValue(s) => s
  | IntValue(n) => Int.toString(n)
  | ObjectValue(json) => json
  }
}

/// Check if a setting value represents "on" / "enabled" / true.
let isSettingEnabled = (v: settingValue): bool => {
  switch v {
  | BoolValue(b) => b
  | StringValue(s) => s === "on" || s === "true" || s === "1"
  | IntValue(n) => n > 0
  | ObjectValue(_) => true
  }
}

// ============================================================================
// Compliance evaluation
// ============================================================================

/// Evaluate a single setting against its policy constraint.
/// Returns Some(finding) if the setting violates the constraint, None if it passes.
let evaluateSetting = (
  domain: string,
  setting: cfSetting,
  constraint: policyConstraint,
): option<auditFinding> => {
  let currentStr = settingValueToString(setting.value)
  let expectedStr = settingValueToString(constraint.severity === "critical"
    ? setting.defaultValue
    : setting.defaultValue)

  // Compare current value to default (policy) value
  let matches = switch (setting.value, setting.defaultValue) {
  | (BoolValue(a), BoolValue(b)) => a === b
  | (StringValue(a), StringValue(b)) => a === b
  | (IntValue(a), IntValue(b)) => a === b
  | _ => currentStr === expectedStr
  }

  if matches {
    None
  } else {
    Some({
      domain,
      settingId: setting.id,
      category: setting.category,
      severity: constraint.severity,
      message: `${constraint.expression}: expected ${expectedStr}, got ${currentStr}`,
      currentValue: currentStr,
      expectedValue: expectedStr,
      autoFixable: setting.editable,
    })
  }
}

/// Compute the overall compliance score for a set of settings against constraints.
/// Returns (passed_count, failed_count, score_0_to_1).
let computeComplianceScore = (
  settings: array<cfSetting>,
  constraints: array<policyConstraint>,
): (int, int, float) => {
  let passed = ref(0)
  let failed = ref(0)

  Array.forEach(constraints, constraint => {
    let matchingSetting = Array.find(settings, s => s.id === constraint.id)
    switch matchingSetting {
    | Some(setting) => {
        let currentStr = settingValueToString(setting.value)
        let expectedStr = settingValueToString(setting.defaultValue)
        if currentStr === expectedStr {
          passed := passed.contents + 1
        } else {
          failed := failed.contents + 1
        }
      }
    | None => failed := failed.contents + 1
    }
  })

  let total = Int.toFloat(passed.contents + failed.contents)
  let score = if total > 0.0 { Int.toFloat(passed.contents) /. total } else { 0.0 }
  (passed.contents, failed.contents, score)
}

// ============================================================================
// Domain filtering and sorting
// ============================================================================

/// Filter zones by search text (matches domain name).
let filterZones = (zones: array<cfZone>, searchText: string): array<cfZone> => {
  if String.length(searchText) === 0 {
    zones
  } else {
    let lower = String.toLowerCase(searchText)
    zones->Array.filter(zone => String.includes(String.toLowerCase(zone.name), lower))
  }
}

/// Sort zones alphabetically by name.
let sortZonesByName = (zones: array<cfZone>): array<cfZone> => {
  let copy = Array.copy(zones)
  Array.sort(copy, (a, b) => String.compare(a.name, b.name))
  copy
}

// ============================================================================
// DNS record analysis
// ============================================================================

/// Check whether a zone has the required email security DNS records.
/// Returns a list of missing record descriptions.
let checkEmailSecurityRecords = (records: array<cfDnsRecord>): array<string> => {
  let missing = ref([])

  // Check for SPF record
  let hasSpf = Array.some(records, r => {
    switch r.recordType {
    | TXT => String.includes(r.content, "v=spf1")
    | _ => false
    }
  })
  if !hasSpf {
    missing := Array.concat(missing.contents, ["SPF (TXT): No v=spf1 record found"])
  }

  // Check for DMARC record
  let hasDmarc = Array.some(records, r => {
    switch r.recordType {
    | TXT => String.includes(r.name, "_dmarc") && String.includes(r.content, "v=DMARC1")
    | _ => false
    }
  })
  if !hasDmarc {
    missing := Array.concat(missing.contents, ["DMARC (TXT): No _dmarc record with v=DMARC1"])
  }

  // Check for CAA record
  let hasCaa = Array.some(records, r => {
    switch r.recordType {
    | CAA => true
    | _ => false
    }
  })
  if !hasCaa {
    missing := Array.concat(missing.contents, ["CAA: No Certificate Authority Authorization record"])
  }

  missing.contents
}

/// Count DNS records by type for the summary badge display.
let countRecordsByType = (records: array<cfDnsRecord>): array<(string, int)> => {
  let counts: Dict.t<int> = Dict.make()

  Array.forEach(records, r => {
    let key = dnsRecordTypeLabel(r.recordType)
    let current = switch Dict.get(counts, key) {
    | Some(n) => n
    | None => 0
    }
    Dict.set(counts, key, current + 1)
  })

  Dict.toArray(counts)
}

// ============================================================================
// Severity helpers
// ============================================================================

/// Severity label for display.
let severityLabel = (sev: auditSeverity): string => {
  switch sev {
  | Critical => "CRITICAL"
  | High => "HIGH"
  | Medium => "MEDIUM"
  | Low => "LOW"
  | Info => "INFO"
  }
}

/// CSS colour class for a severity level (Tailwind).
let severityColour = (sev: auditSeverity): string => {
  switch sev {
  | Critical => "text-red-400"
  | High => "text-orange-400"
  | Medium => "text-yellow-400"
  | Low => "text-blue-400"
  | Info => "text-gray-400"
  }
}

/// Sort audit findings by severity (Critical first, Info last).
let sortFindingsBySeverity = (findings: array<auditFinding>): array<auditFinding> => {
  let severityOrder = (sev: auditSeverity): int => {
    switch sev {
    | Critical => 0
    | High => 1
    | Medium => 2
    | Low => 3
    | Info => 4
    }
  }
  let copy = Array.copy(findings)
  Array.sort(copy, (a, b) => Int.compare(severityOrder(a.severity), severityOrder(b.severity)))
  copy
}
