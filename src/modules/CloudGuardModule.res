// SPDX-License-Identifier: MPL-2.0

/// PanLL CloudGuard Module Registration — Capability-driven module protocol.
///
/// Registers CloudGuard as a PanLL panel module with its capabilities,
/// configuration, and metadata. This follows the DatabaseModule.res pattern
/// but adapted for the Cloudflare domain management use case.
///
/// CloudGuard provides:
///   - Domain inventory and status monitoring
///   - SSL/TLS and security header configuration
///   - DNS record management with security templates
///   - WAF and bot defense configuration
///   - DNSSEC management
///   - Compliance auditing against Trustfile policy
///   - Offline config download/upload with three-way diff
///   - Bulk hardening operations across all domains
///   - Cloudflare Pages / GitHub Pages integration

/// Capabilities that CloudGuard provides to the PanLL ecosystem.
type cloudguardCapability =
  | DomainInventory // List and monitor all Cloudflare zones
  | SecurityHardening // Apply security settings (SSL, HSTS, headers)
  | DnsManagement // DNS record CRUD with security templates
  | ComplianceAudit // Evaluate settings against Trustfile policy
  | OfflineConfig // Download/upload config with three-way diff
  | BulkOperations // Apply settings across multiple domains at once
  | PagesIntegration // Cloudflare Pages / GitHub Pages setup
  | DnssecManagement // DNSSEC enable/verify/DS record management

/// CloudGuard module configuration.
type cloudguardModuleConfig = {
  id: string, // Module identifier
  name: string, // Display name
  version: string, // Module version
  description: string, // Module description
  apiEndpoint: string, // Cloudflare API base URL
  capabilities: array<cloudguardCapability>, // What this module can do
  icon: option<string>, // Icon identifier for module switcher
}

/// The CloudGuard module registration.
let config: cloudguardModuleConfig = {
  id: "cloudguard",
  name: "CloudGuard",
  version: "0.1.0",
  description: "Cloudflare domain security management. Automates SSL/TLS hardening, DNS security records, WAF configuration, DNSSEC, and compliance auditing across all domains.",
  apiEndpoint: "https://api.cloudflare.com/client/v4",
  capabilities: [
    DomainInventory,
    SecurityHardening,
    DnsManagement,
    ComplianceAudit,
    OfflineConfig,
    BulkOperations,
    PagesIntegration,
    DnssecManagement,
  ],
  icon: Some("shield"),
}

/// Check if CloudGuard has a specific capability.
let hasCapability = (cap: cloudguardCapability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a CloudGuard capability.
let capabilityLabel = (cap: cloudguardCapability): string => {
  switch cap {
  | DomainInventory => "Domain Inventory"
  | SecurityHardening => "Security Hardening"
  | DnsManagement => "DNS Management"
  | ComplianceAudit => "Compliance Audit"
  | OfflineConfig => "Offline Config"
  | BulkOperations => "Bulk Operations"
  | PagesIntegration => "Pages Integration"
  | DnssecManagement => "DNSSEC Management"
  }
}

/// Short description for each capability (for tooltip/Panel-N).
let capabilityDescription = (cap: cloudguardCapability): string => {
  switch cap {
  | DomainInventory => "List and monitor all Cloudflare zones with plan tier, status, and nameserver info"
  | SecurityHardening => "Apply SSL Full (Strict), HSTS, min TLS 1.2, security headers, and other hardening defaults"
  | DnsManagement => "Create, update, and delete DNS records with templates for SPF, DMARC, DKIM, CAA, and TLSRPT"
  | ComplianceAudit => "Evaluate live Cloudflare settings against Trustfile/Nickel security policy constraints"
  | OfflineConfig => "Download zone configs as JSON, edit offline, upload with three-way diff and dry-run preview"
  | BulkOperations => "Apply hardening settings across all selected domains with real-time progress tracking"
  | PagesIntegration => "Set up Cloudflare Pages projects from GitHub repos with auto-detected SSG framework"
  | DnssecManagement => "Enable DNSSEC, verify DS records at registrar, monitor key rotation status"
  }
}
