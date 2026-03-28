// SPDX-License-Identifier: PMPL-1.0-or-later

/// CloudGuard Cloudflare domain security management messages -- connection
/// lifecycle, zone listing, settings read/write, DNS records, DNSSEC,
/// hardening operations, audit, and UI state toggling.

open Model

type cloudguardMsg =
  // Connection lifecycle
  | VerifyToken
  | TokenVerified(result<string, string>)
  // Zone listing
  | FetchZones
  | ZonesLoaded(result<string, string>)
  // Zone selection (multi-select domain ribbon)
  | ToggleZoneSelection(string)
  | SelectAllZones
  | DeselectAllZones
  // Settings read/write
  | FetchSettings(string)
  | SettingsLoaded(result<string, string>)
  | ToggleSetting(string)
  | UpdateSettingValue(string, string)
  | PushChanges
  | ChangesPushed(result<string, string>)
  // DNS records
  | FetchDnsRecords(string)
  | DnsRecordsLoaded(result<string, string>)
  | CreateDnsRecord(string, string, string, string, int, option<bool>, option<int>) // zoneId, type, name, content, ttl, proxied, priority
  | DnsRecordCreated(result<string, string>)
  | DeleteDnsRecord(string, string)
  | DnsRecordDeleted(result<string, string>)
  | StartEditingDnsRecord(string) // record ID to edit
  | CancelEditingDnsRecord
  | ApplySecurityTemplate(string) // template name: "spf", "dmarc", "dkim_revoke", "caa", "tlsrpt"
  // DNSSEC
  | FetchDnssec(string)
  | DnssecLoaded(result<string, string>)
  | EnableDnssec(string)
  | DnssecEnabled(result<string, string>)
  // Hardening
  | HardenSelected
  | HardenZone(string)
  | HardenSetting(string) // Fix a single audit finding by settingId
  | ZoneHardened(result<string, string>)
  // Audit
  | RunAudit
  | AuditComplete(result<string, string>)
  // Offline config
  | DownloadConfig
  | ConfigDownloaded(result<string, string>)
  // Per-domain exceptions
  | AddException(string, string, settingValue, string) // domain, settingId, overrideValue, reason
  | RemoveException(string, string) // domain, settingId
  // UI state
  | ToggleCloudGuard
  | SetCategory(settingCategory)
  | SetFilterText(string)
  | SetSettingFilter(string)
  | ToggleAuditPanel
  | ToggleDiffPanel
  /// TypeLL cross-panel type check result for settings JSON types.
  | TypeCheckResult(result<string, string>)
