// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard Catalog — Complete Cloudflare settings reference.
///
/// Hardcoded catalog of all Cloudflare zone settings, organised by category.
/// Each entry declares the CF API setting ID, display label, description,
/// plan tier requirement, value type, and default hardening value.
///
/// This is the single source of truth for what settings exist, what plan
/// they require, and what value the security policy expects. The catalog
/// drives the settings grid UI (which settings to show, how to render them)
/// and the compliance engine (what the expected value is).
///
/// Plan tier gating: each setting has an `availability` that determines
/// whether it renders as interactive or greyed-out with a "Requires Pro" badge.

/// Uses CloudGuardModel types directly (not Model) to avoid dependency cycles.
open CloudGuardModel

// ============================================================================
// Setting definition — a catalog entry (NOT live data, just metadata)
// ============================================================================

/// A catalog entry describing one Cloudflare setting. This is metadata about
/// what the setting IS, not what it's currently set to. Live values come from
/// the API and are stored in `cfSetting.value`.
type catalogEntry = {
  id: string,                      // CF API setting ID
  label: string,                   // Human-readable display label
  description: string,             // Tooltip/help text
  category: settingCategory,       // Which tab this appears under
  availability: settingAvailability, // Plan tier gating
  valueType: string,               // "toggle" | "select" | "number" | "object"
  options: option<array<string>>,  // Valid options for "select" type
  defaultValue: settingValue,      // Hardening default (policy default)
}

// ============================================================================
// SSL/TLS settings
// ============================================================================

/// SSL/TLS-related settings for the first tab.
let sslTlsSettings: array<catalogEntry> = [
  {
    id: "ssl",
    label: "SSL Mode",
    description: "Encryption mode between visitors and Cloudflare, and between Cloudflare and your origin server.",
    category: SslTls,
    availability: Available,
    valueType: "select",
    options: Some(["off", "flexible", "full", "full_strict", "strict"]),
    defaultValue: StringValue("full_strict"),
  },
  {
    id: "min_tls_version",
    label: "Minimum TLS Version",
    description: "The minimum TLS version allowed for HTTPS connections. TLS 1.2 blocks TLS 1.0/1.1 downgrade attacks.",
    category: SslTls,
    availability: Available,
    valueType: "select",
    options: Some(["1.0", "1.1", "1.2", "1.3"]),
    defaultValue: StringValue("1.2"),
  },
  {
    id: "always_use_https",
    label: "Always Use HTTPS",
    description: "Redirect all HTTP requests to HTTPS. Critical for preventing credential sniffing.",
    category: SslTls,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "automatic_https_rewrites",
    label: "Automatic HTTPS Rewrites",
    description: "Rewrite HTTP URLs in page content to HTTPS, fixing mixed content issues.",
    category: SslTls,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "opportunistic_encryption",
    label: "Opportunistic Encryption",
    description: "Enable HTTPS for HTTP/2 connections via Alt-Svc header.",
    category: SslTls,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "tls_1_3",
    label: "TLS 1.3",
    description: "Enable TLS 1.3 with 0-RTT resumption for fastest and most secure connections.",
    category: SslTls,
    availability: Available,
    valueType: "select",
    options: Some(["off", "on", "zrt"]),
    defaultValue: StringValue("zrt"),
  },
]

// ============================================================================
// Security headers settings
// ============================================================================

/// Security header settings for the Headers tab.
let headerSettings: array<catalogEntry> = [
  {
    id: "security_header",
    label: "HSTS (HTTP Strict Transport Security)",
    description: "Force browsers to only connect via HTTPS. Prevents SSL stripping. max-age=31536000, includeSubDomains, preload, nosniff.",
    category: Headers,
    availability: Available,
    valueType: "object",
    options: None,
    defaultValue: ObjectValue("{\"strict_transport_security\":{\"enabled\":true,\"max_age\":31536000,\"include_subdomains\":true,\"preload\":true,\"nosniff\":true}}"),
  },
]

// ============================================================================
// WAF / Bot defense settings
// ============================================================================

/// WAF and bot defense settings.
let wafSettings: array<catalogEntry> = [
  {
    id: "browser_check",
    label: "Browser Integrity Check",
    description: "Evaluate HTTP headers from visitors' browsers for threats. Blocks bad bots.",
    category: Waf,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "hotlink_protection",
    label: "Hotlink Protection",
    description: "Prevent other websites from linking to your images and consuming bandwidth.",
    category: Waf,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "email_obfuscation",
    label: "Email Address Obfuscation",
    description: "Hide email addresses on your site from scrapers and bots.",
    category: Waf,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "server_side_exclude",
    label: "Server Side Excludes (SSE)",
    description: "Hide specific content from suspicious visitors based on threat score.",
    category: Waf,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "security_level",
    label: "Security Level",
    description: "Security level determines the threshold for challenging visitors. Higher = more challenges.",
    category: Waf,
    availability: Available,
    valueType: "select",
    options: Some(["off", "essentially_off", "low", "medium", "high", "under_attack"]),
    defaultValue: StringValue("medium"),
  },
  {
    id: "challenge_ttl",
    label: "Challenge Passage TTL",
    description: "How long a visitor who passed a challenge can access your site before being challenged again.",
    category: Waf,
    availability: Available,
    valueType: "number",
    options: None,
    defaultValue: IntValue(1800),
  },
  {
    id: "waf",
    label: "WAF Managed Rules",
    description: "Cloudflare WAF managed ruleset — blocks common exploits (SQLi, XSS, etc.).",
    category: Waf,
    availability: Unavailable(Pro),
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
]

// ============================================================================
// Performance settings
// ============================================================================

/// Performance-related settings.
let performanceSettings: array<catalogEntry> = [
  {
    id: "brotli",
    label: "Brotli Compression",
    description: "Enable Brotli compression for faster page loads (better ratio than gzip).",
    category: Performance,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "early_hints",
    label: "Early Hints (103)",
    description: "Send 103 Early Hints to preload resources before the full response. Improves LCP.",
    category: Performance,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "http3",
    label: "HTTP/3 (QUIC)",
    description: "Enable HTTP/3 over QUIC for improved performance, especially on mobile networks.",
    category: Performance,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "0rtt",
    label: "0-RTT Connection Resumption",
    description: "Allow TLS 1.3 0-RTT handshakes for faster initial connection on return visits.",
    category: Performance,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "minify",
    label: "Auto Minify",
    description: "Automatically minify JavaScript, CSS, and HTML to reduce file sizes.",
    category: Performance,
    availability: Available,
    valueType: "object",
    options: None,
    defaultValue: ObjectValue("{\"js\":true,\"css\":true,\"html\":true}"),
  },
  {
    id: "browser_cache_ttl",
    label: "Browser Cache TTL",
    description: "How long browsers cache static resources (seconds). 0 = respect origin headers.",
    category: Performance,
    availability: Available,
    valueType: "number",
    options: None,
    defaultValue: IntValue(14400),
  },
  {
    id: "polish",
    label: "Polish (Image Optimisation)",
    description: "Automatically optimise images: lossless or lossy compression, WebP conversion.",
    category: Performance,
    availability: Unavailable(Pro),
    valueType: "select",
    options: Some(["off", "lossless", "lossy"]),
    defaultValue: StringValue("lossless"),
  },
  {
    id: "mirage",
    label: "Mirage (Image Lazy Loading)",
    description: "Lazy-load images and optimise delivery for mobile devices.",
    category: Performance,
    availability: Unavailable(Pro),
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
]

// ============================================================================
// Network settings
// ============================================================================

/// Network-related settings.
let networkSettings: array<catalogEntry> = [
  {
    id: "ip_geolocation",
    label: "IP Geolocation",
    description: "Add CF-IPCountry header to requests for geo-aware applications.",
    category: Network,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "websockets",
    label: "WebSockets",
    description: "Allow WebSocket connections through Cloudflare's proxy.",
    category: Network,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "pseudo_ipv4",
    label: "Pseudo IPv4",
    description: "Map IPv6 addresses to IPv4 for compatibility with legacy analytics.",
    category: Network,
    availability: Available,
    valueType: "select",
    options: Some(["off", "add_header", "overwrite_header"]),
    defaultValue: StringValue("off"),
  },
  {
    id: "opportunistic_onion",
    label: "Onion Routing",
    description: "Allow Tor users to access your site via .onion address for improved privacy.",
    category: Network,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "max_upload",
    label: "Maximum Upload Size (MB)",
    description: "Maximum file upload size allowed through Cloudflare's proxy.",
    category: Network,
    availability: Available,
    valueType: "number",
    options: None,
    defaultValue: IntValue(100),
  },
]

// ============================================================================
// Bot defense settings
// ============================================================================

/// Bot management and defense settings.
let botDefenseSettings: array<catalogEntry> = [
  {
    id: "browser_check",
    label: "Browser Integrity Check",
    description: "Evaluate HTTP headers from visitors' browsers for threats. Blocks bad bots and scrapers.",
    category: BotDefense,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "challenge_ttl",
    label: "Challenge Passage TTL",
    description: "How long a visitor who passed a bot challenge can access your site before re-challenge.",
    category: BotDefense,
    availability: Available,
    valueType: "number",
    options: None,
    defaultValue: IntValue(1800),
  },
  {
    id: "security_level",
    label: "Bot Challenge Threshold",
    description: "Threat score threshold for issuing bot challenges. Higher levels = more aggressive filtering.",
    category: BotDefense,
    availability: Available,
    valueType: "select",
    options: Some(["off", "essentially_off", "low", "medium", "high", "under_attack"]),
    defaultValue: StringValue("medium"),
  },
  {
    id: "bot_management",
    label: "Bot Management (Super Bot Fight Mode)",
    description: "Enterprise-grade bot management with ML-based classification. Requires Bot Management add-on.",
    category: BotDefense,
    availability: Unavailable(Enterprise),
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
]

// ============================================================================
// DNS info settings (informational — actual records managed via DnsEditor)
// ============================================================================

/// DNS-related informational settings. Actual DNS record CRUD happens via
/// the CloudGuardDnsEditor component; these are zone-level DNS behaviours.
let dnsInfoSettings: array<catalogEntry> = [
  {
    id: "cname_flattening",
    label: "CNAME Flattening",
    description: "Flatten CNAME records at the zone apex to return A/AAAA records directly. Required for root domain CNAMEs.",
    category: Dns,
    availability: Available,
    valueType: "select",
    options: Some(["flatten_at_root", "flatten_all"]),
    defaultValue: StringValue("flatten_at_root"),
  },
  {
    id: "flatten_all_cnames",
    label: "Flatten All CNAMEs",
    description: "Flatten ALL CNAME records, not just apex. Hides CNAME targets from DNS queries.",
    category: Dns,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("off"),
  },
]

// ============================================================================
// Email security settings (informational — actual records via DnsEditor)
// ============================================================================

/// Email security configuration indicators. The real SPF/DMARC/DKIM records
/// are DNS TXT records managed via CloudGuardDnsEditor, but these entries
/// provide status visibility and quick-setup templates.
let emailSecSettings: array<catalogEntry> = [
  {
    id: "email_spf",
    label: "SPF Record",
    description: "Sender Policy Framework — declares which mail servers can send on behalf of your domain. Prevents spoofing.",
    category: EmailSec,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "email_dmarc",
    label: "DMARC Policy",
    description: "Domain-based Message Authentication — tells receivers how to handle SPF/DKIM failures. Policy: reject recommended.",
    category: EmailSec,
    availability: Available,
    valueType: "select",
    options: Some(["none", "quarantine", "reject"]),
    defaultValue: StringValue("reject"),
  },
  {
    id: "email_dkim",
    label: "DKIM Signing",
    description: "DomainKeys Identified Mail — cryptographic signature on outbound email. Proves authenticity.",
    category: EmailSec,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "email_mta_sts",
    label: "MTA-STS",
    description: "SMTP MTA Strict Transport Security — forces TLS for inbound mail delivery. Prevents downgrade attacks.",
    category: EmailSec,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "email_tlsrpt",
    label: "TLS-RPT",
    description: "TLS Reporting — receive reports about TLS failures in email delivery to your domain.",
    category: EmailSec,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "email_caa",
    label: "CAA Records",
    description: "Certificate Authority Authorization — restricts which CAs can issue certificates for your domain.",
    category: EmailSec,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
]

// ============================================================================
// Pages settings (Cloudflare Pages / GitHub Pages integration)
// ============================================================================

/// Cloudflare Pages project management settings. These are informational
/// indicators; actual Pages CRUD happens via the CloudGuardPagesSetup component.
let pagesSettings: array<catalogEntry> = [
  {
    id: "pages_project",
    label: "Pages Project",
    description: "Cloudflare Pages deployment project connected to a GitHub repository.",
    category: Pages,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("off"),
  },
  {
    id: "pages_custom_domain",
    label: "Custom Domain Binding",
    description: "Bind a custom domain to your Pages project with automatic CNAME and SSL.",
    category: Pages,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("off"),
  },
  {
    id: "pages_headers",
    label: "Security Headers (_headers file)",
    description: "Deploy security headers via _headers file — free, no Workers needed. CSP, X-Frame-Options, etc.",
    category: Pages,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
]

// ============================================================================
// DNSSEC settings
// ============================================================================

/// DNSSEC settings. DNSSEC is a zone-level toggle managed via the CF API.
/// DS record propagation to the registrar is a separate step.
let dnssecSettings: array<catalogEntry> = [
  {
    id: "dnssec",
    label: "DNSSEC",
    description: "DNS Security Extensions — cryptographically signs DNS records to prevent spoofing and cache poisoning.",
    category: Dnssec,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
  {
    id: "dnssec_ds_record",
    label: "DS Record at Registrar",
    description: "DS (Delegation Signer) record must be added at your domain registrar to complete the DNSSEC chain of trust.",
    category: Dnssec,
    availability: Available,
    valueType: "toggle",
    options: None,
    defaultValue: StringValue("on"),
  },
]

// ============================================================================
// Aggregate catalog
// ============================================================================

/// All settings in the catalog, combined from all categories.
let allSettings: array<catalogEntry> = Array.flat([
  sslTlsSettings,
  headerSettings,
  wafSettings,
  botDefenseSettings,
  dnsInfoSettings,
  emailSecSettings,
  performanceSettings,
  networkSettings,
  pagesSettings,
  dnssecSettings,
])

/// Find a catalog entry by its CF setting ID.
let findById = (id: string): option<catalogEntry> => {
  allSettings->Array.find(entry => entry.id === id)
}

/// Filter catalog entries by category.
let byCategory = (cat: settingCategory): array<catalogEntry> => {
  allSettings->Array.filter(entry => entry.category === cat)
}

/// Get all catalog entries that are available on a given plan tier.
let availableOnPlan = (tier: cfPlanTier): array<catalogEntry> => {
  allSettings->Array.filter(entry => {
    switch entry.availability {
    | Available => true
    | Limited(_) => true
    | Unavailable(required) =>
      switch (tier, required) {
      | (Enterprise, _) => true
      | (Business, Enterprise) => false
      | (Business, _) => true
      | (Pro, Enterprise) => false
      | (Pro, Business) => false
      | (Pro, _) => true
      | (Free, Free) => true
      | (Free, _) => false
      }
    }
  })
}

/// Get the number of settings in each category.
let categoryCounts = (): array<(settingCategory, int)> => {
  [
    (SslTls, Array.length(sslTlsSettings)),
    (Headers, Array.length(headerSettings)),
    (Waf, Array.length(wafSettings)),
    (BotDefense, Array.length(botDefenseSettings)),
    (Dns, Array.length(dnsInfoSettings)),
    (EmailSec, Array.length(emailSecSettings)),
    (Performance, Array.length(performanceSettings)),
    (Network, Array.length(networkSettings)),
    (Pages, Array.length(pagesSettings)),
    (Dnssec, Array.length(dnssecSettings)),
  ]
}

/// Human-readable label for a setting category.
let categoryLabel = (cat: settingCategory): string => {
  switch cat {
  | SslTls => "SSL/TLS"
  | Headers => "Headers"
  | Waf => "WAF"
  | BotDefense => "Bot Defense"
  | Dns => "DNS"
  | EmailSec => "Email Security"
  | Performance => "Performance"
  | Network => "Network"
  | Pages => "Pages"
  | Dnssec => "DNSSEC"
  }
}

/// Human-readable label for a plan tier.
let planLabel = (tier: cfPlanTier): string => {
  switch tier {
  | Free => "Free"
  | Pro => "Pro"
  | Business => "Business"
  | Enterprise => "Enterprise"
  }
}
