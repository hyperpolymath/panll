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
// JSON → cfZone parsing
// ============================================================================

/// Helper: extract a string field from a JSON object dict, with a default.
let jsonStr = (obj: Dict.t<JSON.t>, key: string, default: string): string => {
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | String(s) => s
    | _ => default
    }
  | None => default
  }
}

/// Helper: extract a bool field from a JSON object dict, with a default.
let jsonBool = (obj: Dict.t<JSON.t>, key: string, default: bool): bool => {
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | Bool(b) => b
    | _ => default
    }
  | None => default
  }
}

/// Helper: extract a string array field from a JSON object dict.
let jsonStrArray = (obj: Dict.t<JSON.t>, key: string): array<string> => {
  switch Dict.get(obj, key) {
  | Some(v) =>
    switch JSON.Classify.classify(v) {
    | Array(arr) =>
      arr->Array.filterMap(item =>
        switch JSON.Classify.classify(item) {
        | String(s) => Some(s)
        | _ => None
        }
      )
    | _ => []
    }
  | None => []
  }
}

/// Parse a single JSON object into a cfZone record.
/// Expects the shape from CF API `GET /zones` result array items.
let parseZone = (json: JSON.t): option<cfZone> => {
  switch JSON.Classify.classify(json) {
  | Object(obj) => {
      let id = jsonStr(obj, "id", "")
      let name = jsonStr(obj, "name", "")
      if id === "" || name === "" {
        None
      } else {
        // Extract plan tier from nested plan object
        let planTier = switch Dict.get(obj, "plan") {
        | Some(planJson) =>
          switch JSON.Classify.classify(planJson) {
          | Object(planObj) => parsePlanTier(jsonStr(planObj, "name", "Free"))
          | _ => Free
          }
        | None => Free
        }

        // Parse DNSSEC status (not in zone listing, default to Disabled)
        let dnssec = DnssecDisabled

        Some({
          id,
          name,
          status: jsonStr(obj, "status", "unknown"),
          paused: jsonBool(obj, "paused", false),
          plan: planTier,
          nameservers: jsonStrArray(obj, "name_servers"),
          originalNameservers: jsonStrArray(obj, "original_name_servers"),
          dnssec,
          createdOn: jsonStr(obj, "created_on", ""),
          modifiedOn: jsonStr(obj, "modified_on", ""),
        })
      }
    }
  | _ => None
  }
}

/// Parse a JSON string (array of zone objects) into cfZone records.
/// Handles both the raw result array and the full CF API envelope.
let parseZonesJson = (jsonString: string): array<cfZone> => {
  try {
    let parsed = JSON.parseExn(jsonString)
    switch JSON.Classify.classify(parsed) {
    | Array(arr) => arr->Array.filterMap(parseZone)
    | Object(obj) =>
      // Handle CF API envelope: { result: [...] }
      switch Dict.get(obj, "result") {
      | Some(resultJson) =>
        switch JSON.Classify.classify(resultJson) {
        | Array(arr) => arr->Array.filterMap(parseZone)
        | _ => []
        }
      | None => []
      }
    | _ => []
    }
  } catch {
  | _ => []
  }
}

// ============================================================================
// JSON → cfSetting parsing
// ============================================================================

/// Parse a CF API setting value (polymorphic) into a settingValue variant.
let parseSettingValue = (json: JSON.t): settingValue => {
  switch JSON.Classify.classify(json) {
  | String(s) => StringValue(s)
  | Bool(b) => BoolValue(b)
  | Number(n) => IntValue(Float.toInt(n))
  | Object(_) => ObjectValue(JSON.stringify(json))
  | Null => StringValue("")
  | Array(_) => ObjectValue(JSON.stringify(json))
  }
}

/// Map a CF setting ID to its display category.
/// Uses the catalog as primary source; falls back to heuristic grouping.
let settingIdToCategory = (settingId: string): settingCategory => {
  switch CloudGuardCatalog.findById(settingId) {
  | Some(entry) => entry.category
  | None =>
    // Heuristic fallback for settings not yet in the catalog
    if String.includes(settingId, "ssl") || String.includes(settingId, "tls") || settingId === "always_use_https" || settingId === "automatic_https_rewrites" || settingId === "opportunistic_encryption" {
      SslTls
    } else if String.includes(settingId, "security") || String.includes(settingId, "waf") || String.includes(settingId, "browser_check") || String.includes(settingId, "challenge") || String.includes(settingId, "hotlink") || String.includes(settingId, "email_obfuscation") || String.includes(settingId, "server_side") {
      Waf
    } else if String.includes(settingId, "cache") || String.includes(settingId, "minify") || String.includes(settingId, "polish") || String.includes(settingId, "mirage") || String.includes(settingId, "brotli") || String.includes(settingId, "early_hints") || String.includes(settingId, "http3") || String.includes(settingId, "0rtt") || String.includes(settingId, "h2") {
      Performance
    } else if String.includes(settingId, "ip_geo") || String.includes(settingId, "websocket") || String.includes(settingId, "pseudo") || String.includes(settingId, "onion") || String.includes(settingId, "max_upload") || String.includes(settingId, "grpc") {
      Network
    } else {
      SslTls // Default fallback
    }
  }
}

/// Parse a single JSON object into a cfSetting record.
let parseSetting = (json: JSON.t): option<cfSetting> => {
  switch JSON.Classify.classify(json) {
  | Object(obj) => {
      let id = jsonStr(obj, "id", "")
      if id === "" {
        None
      } else {
        let value = switch Dict.get(obj, "value") {
        | Some(v) => parseSettingValue(v)
        | None => StringValue("")
        }

        // Look up catalog entry for label, description, and default
        let catalogEntry = CloudGuardCatalog.findById(id)
        let label = switch catalogEntry {
        | Some(entry) => entry.label
        | None => id
        }
        let description = switch catalogEntry {
        | Some(entry) => entry.description
        | None => ""
        }
        let defaultValue = switch catalogEntry {
        | Some(entry) => entry.defaultValue
        | None => value
        }
        let availability = switch catalogEntry {
        | Some(entry) => entry.availability
        | None => Available
        }

        Some({
          id,
          label,
          description,
          category: settingIdToCategory(id),
          value,
          defaultValue,
          editable: jsonBool(obj, "editable", true),
          modified: false,
          availability,
        })
      }
    }
  | _ => None
  }
}

/// Parse a JSON string (array of setting objects) into cfSetting records.
let parseSettingsJson = (jsonString: string): array<cfSetting> => {
  try {
    let parsed = JSON.parseExn(jsonString)
    switch JSON.Classify.classify(parsed) {
    | Array(arr) => arr->Array.filterMap(parseSetting)
    | Object(obj) =>
      switch Dict.get(obj, "result") {
      | Some(resultJson) =>
        switch JSON.Classify.classify(resultJson) {
        | Array(arr) => arr->Array.filterMap(parseSetting)
        | _ => []
        }
      | None => []
      }
    | _ => []
    }
  } catch {
  | _ => []
  }
}

// ============================================================================
// JSON → cfDnsRecord parsing
// ============================================================================

/// Parse a single JSON object into a cfDnsRecord record.
let parseDnsRecord = (json: JSON.t): option<cfDnsRecord> => {
  switch JSON.Classify.classify(json) {
  | Object(obj) => {
      let id = jsonStr(obj, "id", "")
      let typeStr = jsonStr(obj, "type", "")
      if id === "" || typeStr === "" {
        None
      } else {
        switch parseDnsRecordType(typeStr) {
        | None => None
        | Some(recordType) => {
            let priority = switch Dict.get(obj, "priority") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | Number(n) => Some(Float.toInt(n))
              | _ => None
              }
            | None => None
            }

            let comment = switch Dict.get(obj, "comment") {
            | Some(v) =>
              switch JSON.Classify.classify(v) {
              | String(s) => if String.length(s) > 0 { Some(s) } else { None }
              | _ => None
              }
            | None => None
            }

            Some({
              id,
              zoneId: jsonStr(obj, "zone_id", ""),
              recordType,
              name: jsonStr(obj, "name", ""),
              content: jsonStr(obj, "content", ""),
              ttl: switch Dict.get(obj, "ttl") {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => Float.toInt(n)
                | _ => 1
                }
              | None => 1
              },
              proxied: jsonBool(obj, "proxied", false),
              priority,
              comment,
              tags: jsonStrArray(obj, "tags"),
              locked: jsonBool(obj, "locked", false),
              createdOn: jsonStr(obj, "created_on", ""),
              modifiedOn: jsonStr(obj, "modified_on", ""),
            })
          }
        }
      }
    }
  | _ => None
  }
}

/// Parse a JSON string (array of DNS record objects) into cfDnsRecord records.
let parseDnsRecordsJson = (jsonString: string): array<cfDnsRecord> => {
  try {
    let parsed = JSON.parseExn(jsonString)
    switch JSON.Classify.classify(parsed) {
    | Array(arr) => arr->Array.filterMap(parseDnsRecord)
    | Object(obj) =>
      switch Dict.get(obj, "result") {
      | Some(resultJson) =>
        switch JSON.Classify.classify(resultJson) {
        | Array(arr) => arr->Array.filterMap(parseDnsRecord)
        | _ => []
        }
      | None => []
      }
    | _ => []
    }
  } catch {
  | _ => []
  }
}

// ============================================================================
// cfSetting → JSON serialisation (for push changes)
// ============================================================================

/// Serialise modified settings into a JSON string for the batch update API.
/// Produces a JSON array of `[{id, value}]` items.
let serialiseModifiedSettings = (settings: array<cfSetting>): string => {
  let modified = settings->Array.filter(s => s.modified)
  let items = modified->Array.map(s => {
    let valueJson = switch s.value {
    | BoolValue(b) => if b { "\"on\"" } else { "\"off\"" }
    | StringValue(str) => `"${str}"`
    | IntValue(n) => Int.toString(n)
    | ObjectValue(json) => json
    }
    `{"id":"${s.id}","value":${valueJson}}`
  })
  `[${Array.join(items, ",")}]`
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
  rule: policyConstraint,
): option<auditFinding> => {
  let currentStr = settingValueToString(setting.value)
  let expectedStr = settingValueToString(setting.defaultValue)

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
      severity: rule.severity,
      message: `${rule.expression}: expected ${expectedStr}, got ${currentStr}`,
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

  Array.forEach(constraints, rule => {
    let matchingSetting = Array.find(settings, s => s.id === rule.id)
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

// ============================================================================
// Per-domain exception helpers
// ============================================================================

/// Find the exception for a specific domain + setting, if any.
let findException = (
  exceptions: array<domainException>,
  domain: string,
  settingId: string,
): option<domainException> => {
  exceptions->Array.find(e => e.domain === domain && e.settingId === settingId)
}

/// Check whether a setting has an exception for a given domain.
let hasException = (
  exceptions: array<domainException>,
  domain: string,
  settingId: string,
): bool => {
  exceptions->Array.some(e => e.domain === domain && e.settingId === settingId)
}

/// Get all exceptions for a specific domain.
let exceptionsForDomain = (
  exceptions: array<domainException>,
  domain: string,
): array<domainException> => {
  exceptions->Array.filter(e => e.domain === domain)
}

/// Get all exceptions for a specific setting across all domains.
let exceptionsForSetting = (
  exceptions: array<domainException>,
  settingId: string,
): array<domainException> => {
  exceptions->Array.filter(e => e.settingId === settingId)
}

/// Apply exceptions to a setting for a given domain. If an exception exists,
/// returns the setting with the override value applied. Otherwise returns as-is.
let applyException = (
  setting: cfSetting,
  exceptions: array<domainException>,
  domain: string,
): cfSetting => {
  switch findException(exceptions, domain, setting.id) {
  | Some(exc) => {...setting, value: exc.overrideValue, modified: true}
  | None => setting
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
