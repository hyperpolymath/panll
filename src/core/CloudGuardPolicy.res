// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard Policy — Security policy constraint definitions.
///
/// Defines the hardcoded security policy constraints that CloudGuard audits
/// against. These represent the "Trustfile" — the security posture that all
/// domains should comply with. Each constraint maps to a Cloudflare setting
/// and specifies the expected value and severity of deviation.
///
/// In the future, these constraints will be loaded from Nickel (.k9.ncl)
/// policy files and/or A2ML Trustfile definitions. For now, they are
/// hardcoded to match the manual hardening session that motivated CloudGuard.
///
/// Constraints are displayed in Panel-L as a scrollable list with
/// enable/disable toggles.

open CloudGuardModel

// ============================================================================
// Default policy constraints — the security posture all domains should match
// ============================================================================

/// The default security policy, matching the hardening done in the manual
/// session across 36 Cloudflare domains. Each constraint specifies:
///   - id: matches the CF API setting ID
///   - expression: human-readable rule for Panel-L display
///   - category: which settings tab it belongs to
///   - enabled: whether it's active for auditing (default: true)
///   - severity: how bad a violation is
///   - description: explanation of why this matters
let defaultConstraints: array<policyConstraint> = [
  // --- SSL/TLS ---
  {
    id: "ssl",
    expression: "ssl.mode == \"full_strict\"",
    category: SslTls,
    enabled: true,
    severity: Critical,
    description: "Full (Strict) SSL ensures end-to-end encryption with validated origin certificates. Prevents MITM attacks.",
  },
  {
    id: "min_tls_version",
    expression: "min_tls_version >= \"1.2\"",
    category: SslTls,
    enabled: true,
    severity: High,
    description: "TLS 1.0 and 1.1 have known vulnerabilities. Minimum TLS 1.2 blocks downgrade attacks.",
  },
  {
    id: "always_use_https",
    expression: "always_use_https == \"on\"",
    category: SslTls,
    enabled: true,
    severity: Critical,
    description: "Redirects all HTTP to HTTPS. Without this, credentials can be sniffed on insecure connections.",
  },
  {
    id: "automatic_https_rewrites",
    expression: "automatic_https_rewrites == \"on\"",
    category: SslTls,
    enabled: true,
    severity: Medium,
    description: "Fixes mixed content by rewriting HTTP URLs to HTTPS in page content.",
  },
  {
    id: "opportunistic_encryption",
    expression: "opportunistic_encryption == \"on\"",
    category: SslTls,
    enabled: true,
    severity: Low,
    description: "Enables HTTPS via Alt-Svc header for HTTP/2 connections.",
  },
  {
    id: "tls_1_3",
    expression: "tls_1_3 == \"zrt\"",
    category: SslTls,
    enabled: true,
    severity: Medium,
    description: "TLS 1.3 with 0-RTT provides the fastest and most secure handshake.",
  },

  // --- Security Headers ---
  {
    id: "security_header",
    expression: "hsts.enabled && hsts.max_age >= 31536000 && hsts.include_subdomains && hsts.preload && hsts.nosniff",
    category: Headers,
    enabled: true,
    severity: Critical,
    description: "HSTS forces browsers to use HTTPS only. max-age=1yr, includeSubDomains, preload, and nosniff are all required.",
  },

  // --- WAF ---
  {
    id: "browser_check",
    expression: "browser_check == \"on\"",
    category: Waf,
    enabled: true,
    severity: Medium,
    description: "Browser integrity check evaluates HTTP headers to block bad bots.",
  },
  {
    id: "hotlink_protection",
    expression: "hotlink_protection == \"on\"",
    category: Waf,
    enabled: true,
    severity: Low,
    description: "Prevents bandwidth theft from hotlinked images.",
  },
  {
    id: "email_obfuscation",
    expression: "email_obfuscation == \"on\"",
    category: Waf,
    enabled: true,
    severity: Low,
    description: "Hides email addresses from scrapers and spam bots.",
  },
  {
    id: "security_level",
    expression: "security_level == \"medium\"",
    category: Waf,
    enabled: true,
    severity: Medium,
    description: "Medium security level provides a good balance of protection without excessive challenges.",
  },

  // --- Performance ---
  {
    id: "brotli",
    expression: "brotli == \"on\"",
    category: Performance,
    enabled: true,
    severity: Low,
    description: "Brotli compression reduces bandwidth and improves page load times.",
  },
  {
    id: "early_hints",
    expression: "early_hints == \"on\"",
    category: Performance,
    enabled: true,
    severity: Low,
    description: "103 Early Hints allow browsers to preload resources before the full response.",
  },
  {
    id: "http3",
    expression: "http3 == \"on\"",
    category: Performance,
    enabled: true,
    severity: Low,
    description: "HTTP/3 over QUIC improves performance, especially on mobile networks.",
  },

  // --- Network ---
  {
    id: "websockets",
    expression: "websockets == \"on\"",
    category: Network,
    enabled: true,
    severity: Low,
    description: "Allow WebSocket connections through Cloudflare's proxy.",
  },
  {
    id: "opportunistic_onion",
    expression: "opportunistic_onion == \"on\"",
    category: Network,
    enabled: true,
    severity: Low,
    description: "Onion routing allows Tor users to access your site via .onion address.",
  },
]

// ============================================================================
// Policy evaluation helpers
// ============================================================================

/// Get all enabled constraints from the default policy.
let enabledConstraints = (): array<policyConstraint> => {
  defaultConstraints->Array.filter(c => c.enabled)
}

/// Get constraints for a specific category.
let constraintsByCategory = (cat: settingCategory): array<policyConstraint> => {
  defaultConstraints->Array.filter(c => c.category === cat)
}

/// Find a constraint by its setting ID.
let findConstraint = (id: string): option<policyConstraint> => {
  defaultConstraints->Array.find(c => c.id === id)
}

/// Evaluate a single setting against the policy. Returns Some(finding) if
/// the setting deviates from the constraint, None if it matches.
let evaluateSettingAgainstPolicy = (
  domain: string,
  setting: cfSetting,
): option<auditFinding> => {
  switch findConstraint(setting.id) {
  | None => None // No constraint for this setting — passes by default
  | Some(constraint) =>
    if !constraint.enabled {
      None // Constraint disabled — passes
    } else {
      let currentStr = CloudGuardEngine.settingValueToString(setting.value)
      let expectedStr = CloudGuardEngine.settingValueToString(setting.defaultValue)

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
  }
}

/// Run a full audit of all settings against the policy for a given domain.
/// Returns a complete auditResult with score, findings, and counts.
let auditSettings = (
  domain: string,
  settings: array<cfSetting>,
): auditResult => {
  let enabledC = enabledConstraints()
  let findings = ref([])

  // Evaluate each setting against its constraint
  Array.forEach(settings, setting => {
    switch evaluateSettingAgainstPolicy(domain, setting) {
    | Some(finding) => findings := Array.concat(findings.contents, [finding])
    | None => ()
    }
  })

  // Count settings that have constraints
  let totalConstrained = enabledC->Array.length
  let failedCount = Array.length(findings.contents)
  let passedCount = totalConstrained - failedCount
  let warningCount = findings.contents->Array.filter(f =>
    switch f.severity {
    | Medium | Low => true
    | _ => false
    }
  )->Array.length

  let score = if totalConstrained > 0 {
    Int.toFloat(passedCount) /. Int.toFloat(totalConstrained)
  } else {
    1.0
  }

  {
    timestamp: "now", // TODO: use Date.now() ISO 8601
    domains: [domain],
    findings: CloudGuardEngine.sortFindingsBySeverity(findings.contents),
    passed: passedCount,
    failed: failedCount,
    warnings: warningCount,
    score,
  }
}

/// Run an audit across multiple domains. Combines findings from all domains
/// into a single auditResult.
let auditMultipleDomains = (
  domains: array<string>,
  settingsPerDomain: array<(string, array<cfSetting>)>,
): auditResult => {
  let allFindings = ref([])
  let totalPassed = ref(0)
  let totalFailed = ref(0)

  Array.forEach(settingsPerDomain, ((domain, settings)) => {
    let result = auditSettings(domain, settings)
    allFindings := Array.concat(allFindings.contents, result.findings)
    totalPassed := totalPassed.contents + result.passed
    totalFailed := totalFailed.contents + result.failed
  })

  let total = totalPassed.contents + totalFailed.contents
  let score = if total > 0 {
    Int.toFloat(totalPassed.contents) /. Int.toFloat(total)
  } else {
    1.0
  }

  {
    timestamp: "now",
    domains,
    findings: CloudGuardEngine.sortFindingsBySeverity(allFindings.contents),
    passed: totalPassed.contents,
    failed: totalFailed.contents,
    warnings: allFindings.contents->Array.filter(f =>
      switch f.severity {
      | Medium | Low => true
      | _ => false
      }
    )->Array.length,
    score,
  }
}
