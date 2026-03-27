// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard Model Types — Cloudflare domain security management.
///
/// CloudGuard automates Cloudflare domain hardening: SSL/TLS, HSTS, security
/// headers, WAF, bot defense, DNSSEC, DNS security records (SPF/DMARC/DKIM/CAA/
/// TLSRPT), managed transforms, performance, and network settings. It integrates
/// as a PanLL panel module with a toggle-based dashboard, bulk operations, offline
/// config management, and Trustfile compliance enforcement.
///
/// Three-panel model:
///   Panel-L → Trustfile-derived security constraints (parsed from .a2ml + Nickel)
///   Panel-N → AI gap analysis (why settings matter, anomaly detection, exceptions)
///   Panel-W → Main dashboard (domain ribbon, category tabs, settings grid, actions)
///
/// This module has NO dependencies on other PanLL modules — leaf of the
/// type dependency graph, following the same pattern as VabModel.

// ============================================================================
// Cloudflare Plan Tiers — determines which features are available
// ============================================================================

/// Cloudflare plan tier. Each setting in the catalog is gated by plan tier,
/// so the UI can grey out unavailable features with "Requires Pro" badges.
type cfPlanTier =
  | Free // Free plan — most basic settings
  | Pro // Pro plan — WAF, Polish, Mirage, etc.
  | Business // Business plan — custom WAF rules, Railgun, etc.
  | Enterprise // Enterprise plan — everything

// ============================================================================
// Setting categories — the tab bar in Panel-W
// ============================================================================

/// Top-level categories for the settings grid. Each tab shows a group of
/// related Cloudflare settings with toggles, dropdowns, and text inputs.
type settingCategory =
  | SslTls // SSL mode, min TLS version, HSTS, OCSP, CT logging
  | Headers // Security headers (CSP, X-Frame-Options, etc.) via transforms
  | Waf // Web Application Firewall rules and managed rulesets
  | BotDefense // Bot Fight Mode, Super Bot Fight Mode, JS challenges
  | Dns // DNS record management (A, AAAA, CNAME, MX, TXT, SRV, etc.)
  | EmailSec // Email security: SPF, DMARC, DKIM revocation, TLSRPT
  | Performance // Caching, minification, Polish, Mirage, Early Hints, HTTP/3
  | Network // IP geolocation, WebSockets, gRPC, Onion Routing, 0-RTT
  | Pages // Cloudflare Pages / GitHub Pages integration
  | Dnssec // DNSSEC enable, DS record status, key rotation

// ============================================================================
// Setting availability — plan-tier gating for the catalog
// ============================================================================

/// Whether a setting is available on the user's plan. The catalog marks each
/// setting with one of these. UI renders unavailable settings greyed-out.
type settingAvailability =
  | Available // Setting works on any plan
  | Unavailable(cfPlanTier) // Requires this plan tier or higher
  | Limited(string) // Available but with limitations (description)

// ============================================================================
// Setting value types — the actual data each toggle/dropdown/input holds
// ============================================================================

/// The value of a single Cloudflare setting. Variants cover all the shapes
/// that CF API returns: booleans, enums (strings), integers, nested objects.
type settingValue =
  | BoolValue(bool) // On/off toggles (e.g. always_use_https)
  | StringValue(string) // Enum/string settings (e.g. ssl mode "full_strict")
  | IntValue(int) // Numeric settings (e.g. max_upload MB, browser_cache_ttl)
  | ObjectValue(string) // Complex nested JSON (serialised; e.g. security_header HSTS)

/// A single Cloudflare zone setting with its current value and metadata.
/// This maps directly to the CF API `/zones/{zone_id}/settings/{setting_id}` shape.
type cfSetting = {
  id: string, // CF setting ID (e.g. "ssl", "always_use_https", "min_tls_version")
  label: string, // Human-readable label for the UI
  description: string, // Tooltip/help text explaining the setting
  category: settingCategory, // Which tab this appears under
  value: settingValue, // Current value from CF API
  defaultValue: settingValue, // Policy default (from Trustfile/Nickel)
  editable: bool, // Whether the user can change this (some are read-only)
  modified: bool, // Whether the value differs from the last-pushed state
  availability: settingAvailability, // Plan tier gating
}

// ============================================================================
// DNS record types — for the inline DNS editor
// ============================================================================

/// Standard DNS record type enum covering all Cloudflare-supported types.
type dnsRecordType = A | AAAA | CNAME | MX | TXT | SRV | NS | CAA | TLSA | HTTPS | SVCB | PTR | LOC

/// A single DNS record within a zone. Maps to CF API `/zones/{zone_id}/dns_records`.
type cfDnsRecord = {
  id: string, // Record ID from CF API
  zoneId: string, // Parent zone ID
  recordType: dnsRecordType, // DNS record type
  name: string, // Hostname (e.g. "www.example.com")
  content: string, // Record value (IP, CNAME target, TXT data, etc.)
  ttl: int, // TTL in seconds (1 = automatic/proxied)
  proxied: bool, // Whether Cloudflare proxies this record (orange cloud)
  priority: option<int>, // Priority for MX/SRV records
  comment: option<string>, // Optional record comment (CF API v4 feature)
  tags: array<string>, // Record tags for filtering
  locked: bool, // Whether the record is locked (managed by CF)
  createdOn: string, // ISO 8601 timestamp
  modifiedOn: string, // ISO 8601 timestamp
}

// ============================================================================
// Zone (domain) types
// ============================================================================

/// DNSSEC status for a zone.
type dnssecStatus =
  | DnssecActive // DNSSEC enabled and DS record verified
  | DnssecPending // DNSSEC enabled, awaiting DS record at registrar
  | DnssecDisabled // DNSSEC not enabled
  | DnssecError(string) // DNSSEC configuration error

/// A single Cloudflare zone (domain). Core entity for the domain ribbon.
type cfZone = {
  id: string, // Zone ID from CF API
  name: string, // Domain name (e.g. "axel-protocol.org")
  status: string, // "active" | "pending" | "moved" | "deleted"
  paused: bool, // Whether the zone is paused
  plan: cfPlanTier, // Current plan tier
  nameservers: array<string>, // Assigned Cloudflare nameservers
  originalNameservers: array<string>, // Original registrar nameservers (for migration)
  dnssec: dnssecStatus, // DNSSEC status
  createdOn: string, // ISO 8601 timestamp
  modifiedOn: string, // ISO 8601 timestamp
}

// ============================================================================
// Audit and compliance types
// ============================================================================

/// Severity level for audit findings, following standard security rating scale.
type auditSeverity =
  | Critical // Must fix immediately (e.g. SSL mode "off", no HSTS)
  | High // Should fix soon (e.g. TLS 1.0 allowed, no DMARC reject)
  | Medium // Recommended improvement (e.g. no CAA record, old cache TTL)
  | Low // Minor enhancement (e.g. missing TLSRPT, no Brotli)
  | Info // Informational (e.g. DNSSEC pending DS record)

/// A single audit finding — one setting that deviates from policy.
type auditFinding = {
  domain: string, // Which domain this applies to
  settingId: string, // CF setting ID
  category: settingCategory, // Which tab group
  severity: auditSeverity, // How bad is it
  message: string, // Human-readable finding (e.g. "SSL mode is 'flexible', expected 'full_strict'")
  currentValue: string, // What the setting currently is (stringified)
  expectedValue: string, // What the policy says it should be (stringified)
  autoFixable: bool, // Whether CloudGuard can fix this automatically
}

/// Overall audit result for a zone or set of zones.
type auditResult = {
  timestamp: string, // ISO 8601 when the audit ran
  domains: array<string>, // Which domains were audited
  findings: array<auditFinding>, // All findings across all domains
  passed: int, // Number of settings that matched policy
  failed: int, // Number of settings that deviated
  warnings: int, // Number of medium/low findings
  score: float, // Overall compliance score (0.0 - 1.0)
}

// ============================================================================
// Config diff types — three-way comparison (offline vs live vs policy)
// ============================================================================

/// Which side of the diff a change comes from.
type diffSource =
  | Offline // Value from locally saved config file
  | Live // Value currently on Cloudflare
  | Policy // Value from Trustfile/Nickel policy

/// A single diff entry — one setting that differs between two sources.
type configDiffEntry = {
  settingId: string, // CF setting ID
  domain: string, // Which domain
  category: settingCategory, // Which tab group
  offlineValue: option<string>, // Value in offline config (None if absent)
  liveValue: option<string>, // Value on Cloudflare (None if absent)
  policyValue: option<string>, // Value from policy (None if not specified)
  resolution: option<diffSource>, // Which source to use (None = unresolved)
}

/// A complete three-way config diff for one or more domains.
type configDiff = {
  timestamp: string, // When the diff was computed
  entries: array<configDiffEntry>, // All diff entries
  conflictCount: int, // Number of three-way conflicts
  driftCount: int, // Number of live-vs-offline drifts
}

// ============================================================================
// Policy constraint types — Panel-L content
// ============================================================================

/// A single policy constraint derived from the Trustfile and Nickel config.
/// These are displayed in Panel-L as a scrollable list with enable/disable toggles.
type policyConstraint = {
  id: string, // Unique constraint ID (e.g. "ssl.mode.full_strict")
  expression: string, // Human-readable rule (e.g. "ssl.mode == \"full_strict\"")
  category: settingCategory, // Which settings group this constrains
  enabled: bool, // Whether the constraint is active for auditing
  severity: auditSeverity, // How severe a violation would be
  description: string, // Explanation of why this matters
}

// ============================================================================
// Per-domain exception types
// ============================================================================

/// An exception override for a specific domain. Policy defines defaults;
/// exceptions allow per-domain deviations with documented reasoning.
type domainException = {
  domain: string, // Which domain this exception applies to
  settingId: string, // Which setting is overridden
  overrideValue: settingValue, // The override value for this domain
  reason: string, // Why this domain differs from the bulk default
  addedOn: string, // ISO 8601 when the exception was created
}

// ============================================================================
// Cloudflare Pages integration types
// ============================================================================

/// A Cloudflare Pages project associated with the account.
type cfPagesProject = {
  name: string, // Project name
  subdomain: string, // *.pages.dev subdomain
  customDomains: array<string>, // Custom domains bound to this project
  productionBranch: string, // Git branch for production deploys
  framework: option<string>, // Detected SSG framework (e.g. "jekyll", "hugo")
  createdOn: string, // ISO 8601 timestamp
}

// ============================================================================
// Bulk operation progress tracking
// ============================================================================

/// Progress state for a bulk operation (e.g. "Harden All 36 domains").
type bulkProgress = {
  total: int, // Total number of operations
  completed: int, // Number completed so far
  failed: int, // Number that failed
  currentDomain: option<string>, // Which domain is currently being processed
  startedAt: string, // ISO 8601 when the operation started
  errors: array<(string, string)>, // (domain, error message) for failures
}

// ============================================================================
// Connection and loading state
// ============================================================================

/// API connection status — tracks whether the CF API token is valid.
type cfConnectionStatus =
  | Disconnected // No API token configured or token cleared
  | Connecting // Token verification in progress
  | Connected(string) // Connected — parameter is account email
  | ConnectionError(string) // Token verification failed — parameter is error

// ============================================================================
// Root panel state — composed into Model.model
// ============================================================================

/// The complete CloudGuard panel state. Stored as a sub-record in Model.model,
/// this tracks the API connection, loaded zones, settings, DNS records, audit
/// results, diff state, policy constraints, and UI state for all sub-components.
type cloudguardState = {
  // Connection
  connection: cfConnectionStatus, // API connection lifecycle
  loading: bool, // Whether an API call is in flight
  error: option<string>, // Last error message (None = no error)
  // Data
  zones: array<cfZone>, // All zones in the account
  selectedZoneIds: array<string>, // Currently selected zone IDs (multi-select)
  settings: array<cfSetting>, // Settings for the currently viewed zone(s)
  dnsRecords: array<cfDnsRecord>, // DNS records for the currently viewed zone
  pagesProjects: array<cfPagesProject>, // CF Pages projects in the account
  // Audit and compliance
  auditResult: option<auditResult>, // Latest audit result
  constraints: array<policyConstraint>, // Policy constraints for Panel-L
  exceptions: array<domainException>, // Per-domain exceptions
  // Diff
  configDiff: option<configDiff>, // Three-way diff result
  // Bulk operations
  bulkProgress: option<bulkProgress>, // Current bulk operation progress
  // UI state
  visible: bool, // Whether the CloudGuard overlay is shown
  activeCategory: settingCategory, // Currently active settings tab
  filterText: string, // Domain filter text in the ribbon
  settingFilter: string, // Setting filter text within the grid
  showDiff: bool, // Whether the diff viewer side panel is open
  showAudit: bool, // Whether the audit results side panel is open
  dnsEditingId: option<string>, // DNS record ID being edited (None = not editing)
}
