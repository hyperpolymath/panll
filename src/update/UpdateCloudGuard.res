// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// Handles all CloudGuard (Cloudflare domain security management) messages.
/// Connection lifecycle, zone listing, settings read/write, DNS records,
/// DNSSEC, hardening operations, audit, and UI state toggling.
let updateCloudGuard = (model: model, msg: cloudguardMsg): (model, Tea_Cmd.t<msg>) => {
  let cg = model.cloudguard
  switch msg {
  // -- Connection lifecycle --
  | VerifyToken => (
      {...model, cloudguard: {...cg, connection: Connecting, loading: true}},
      CloudGuardCmd.verifyToken(result => CloudGuard(TokenVerified(result))),
    )
  | TokenVerified(result) =>
    switch result {
    | Ok(json) => (
        {...model, cloudguard: {...cg, connection: Connected(json), loading: false, error: None}},
        // Auto-fetch zones after successful connection
        CloudGuardCmd.listZones(result => CloudGuard(ZonesLoaded(result))),
      )
    | Error(err) => (
        {
          ...model,
          cloudguard: {...cg, connection: ConnectionError(err), loading: false, error: Some(err)},
        },
        Tea_Cmd.none,
      )
    }

  // -- Zone listing --
  | FetchZones => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.listZones(result => CloudGuard(ZonesLoaded(result))),
    )
  | ZonesLoaded(result) =>
    switch result {
    | Ok(json) => {
        let zones = CloudGuardEngine.parseZonesJson(json)
        let sorted = CloudGuardEngine.sortZonesByName(zones)
        ({...model, cloudguard: {...cg, zones: sorted, loading: false, error: None}}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Zone selection (multi-select domain ribbon) --
  | ToggleZoneSelection(zoneId) => {
      let wasSelected = Array.includes(cg.selectedZoneIds, zoneId)
      let newSelected = if wasSelected {
        cg.selectedZoneIds->Array.filter(id => id !== zoneId)
      } else {
        Array.concat(cg.selectedZoneIds, [zoneId])
      }
      // When selecting a single zone (and it wasn't already selected), auto-fetch its settings + DNS
      let cmd = if !wasSelected && Array.length(newSelected) === 1 {
        Tea_Cmd.batch(list{
          CloudGuardCmd.getSettings(zoneId, result => CloudGuard(SettingsLoaded(result))),
          CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result))),
        })
      } else {
        Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, selectedZoneIds: newSelected}}, cmd)
    }
  | SelectAllZones => {
      let allIds = cg.zones->Array.map(z => z.id)
      ({...model, cloudguard: {...cg, selectedZoneIds: allIds}}, Tea_Cmd.none)
    }
  | DeselectAllZones => ({...model, cloudguard: {...cg, selectedZoneIds: []}}, Tea_Cmd.none)

  // -- Settings read/write --
  | FetchSettings(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.getSettings(zoneId, result => CloudGuard(SettingsLoaded(result))),
    )
  | SettingsLoaded(result) =>
    switch result {
    | Ok(json) => {
        let settings = CloudGuardEngine.parseSettingsJson(json)
        ({...model, cloudguard: {...cg, settings, loading: false, error: None}}, Tea_Cmd.none)
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | ToggleSetting(settingId) => {
      let newSettings = cg.settings->Array.map(s => {
        if s.id === settingId {
          let newValue = switch s.value {
          | StringValue("on") => StringValue("off")
          | StringValue("off") => StringValue("on")
          | BoolValue(b) => BoolValue(!b)
          | other => other
          }
          {...s, value: newValue, modified: true}
        } else {
          s
        }
      })
      ({...model, cloudguard: {...cg, settings: newSettings}}, Tea_Cmd.none)
    }
  | UpdateSettingValue(settingId, value) => {
      let newSettings = cg.settings->Array.map(s => {
        if s.id === settingId {
          {...s, value: StringValue(value), modified: true}
        } else {
          s
        }
      })
      ({...model, cloudguard: {...cg, settings: newSettings}}, Tea_Cmd.none)
    }
  | PushChanges => {
      let modifiedCount = cg.settings->Array.filter(s => s.modified)->Array.length
      if modifiedCount === 0 {
        (model, Tea_Cmd.none)
      } else {
        // Get the first selected zone to push to
        switch cg.selectedZoneIds[0] {
        | Some(zoneId) => {
            let settingsJson = CloudGuardEngine.serialiseModifiedSettings(cg.settings)
            let typellCmd = TypeLLService.checkConfigTypes(
              settingsJson,
              "cloudguard",
              result => CloudGuard(TypeCheckResult(result)),
            )
            (
              {...model, cloudguard: {...cg, loading: true}},
              Tea_Cmd.batch(list{
                CloudGuardCmd.updateSettingsBatch(zoneId, settingsJson, result => CloudGuard(
                  ChangesPushed(result),
                )),
                typellCmd,
              }),
            )
          }
        | None => (model, Tea_Cmd.none)
        }
      }
    }
  | ChangesPushed(result) =>
    switch result {
    | Ok(_json) => {
        // Clear modified flags on all settings after successful push
        let clearedSettings = cg.settings->Array.map(s => {...s, modified: false})
        (
          {...model, cloudguard: {...cg, settings: clearedSettings, loading: false, error: None}},
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- DNS records --
  | FetchDnsRecords(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result))),
    )
  | DnsRecordsLoaded(result) =>
    switch result {
    | Ok(json) => {
        let records = CloudGuardEngine.parseDnsRecordsJson(json)
        (
          {...model, cloudguard: {...cg, dnsRecords: records, loading: false, error: None}},
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DeleteDnsRecord(zoneId, recordId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.deleteDnsRecord(zoneId, recordId, result => CloudGuard(
        DnsRecordDeleted(result),
      )),
    )
  | DnsRecordDeleted(result) =>
    switch result {
    | Ok(_json) =>
      // Re-fetch DNS records for the first selected zone to update the list
      let refetchCmd = switch cg.selectedZoneIds[0] {
      | Some(zoneId) =>
        CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result)))
      | None => Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, loading: false}}, refetchCmd)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | CreateDnsRecord(zoneId, recordType, name, content, ttl, proxied, priority) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.createDnsRecord(
        zoneId,
        recordType,
        name,
        content,
        ttl,
        proxied,
        priority,
        None,
        result => CloudGuard(DnsRecordCreated(result)),
      ),
    )
  | DnsRecordCreated(result) =>
    switch result {
    | Ok(_json) =>
      // Re-fetch DNS records to show the newly created record
      let refetchCmd = switch cg.selectedZoneIds[0] {
      | Some(zoneId) =>
        CloudGuardCmd.listDnsRecords(zoneId, result => CloudGuard(DnsRecordsLoaded(result)))
      | None => Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, loading: false}}, refetchCmd)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | StartEditingDnsRecord(recordId) => (
      {...model, cloudguard: {...cg, dnsEditingId: Some(recordId)}},
      Tea_Cmd.none,
    )
  | CancelEditingDnsRecord => ({...model, cloudguard: {...cg, dnsEditingId: None}}, Tea_Cmd.none)
  | ApplySecurityTemplate(
      template,
    ) => // Apply a DNS security template (SPF, DMARC, DKIM revoke, CAA, TLSRPT)
    // Requires a selected zone to know the domain name
    switch cg.selectedZoneIds[0] {
    | None => ({...model, cloudguard: {...cg, error: Some("No zone selected")}}, Tea_Cmd.none)
    | Some(zoneId) =>
      let zoneName = switch cg.zones->Array.find(z => z.id === zoneId) {
      | Some(z) => z.name
      | None => "example.com"
      }
      let cmd = switch template {
      | "spf" =>
        CloudGuardCmd.createDnsRecord(
          zoneId,
          "TXT",
          zoneName,
          "v=spf1 -all",
          1,
          None,
          None,
          Some("CloudGuard: SPF deny-all (no mail)"),
          result => CloudGuard(DnsRecordCreated(result)),
        )
      | "dmarc" =>
        CloudGuardCmd.createDnsRecord(
          zoneId,
          "TXT",
          `_dmarc.${zoneName}`,
          "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; pct=100; fo=1",
          1,
          None,
          None,
          Some("CloudGuard: DMARC reject policy"),
          result => CloudGuard(DnsRecordCreated(result)),
        )
      | "dkim_revoke" =>
        CloudGuardCmd.createDnsRecord(
          zoneId,
          "TXT",
          `*._domainkey.${zoneName}`,
          "v=DKIM1; p=",
          1,
          None,
          None,
          Some("CloudGuard: DKIM key revocation"),
          result => CloudGuard(DnsRecordCreated(result)),
        )
      | "caa" =>
        CloudGuardCmd.createDnsRecord(
          zoneId,
          "CAA",
          zoneName,
          "0 issue \"letsencrypt.org\"",
          1,
          None,
          None,
          Some("CloudGuard: CAA restrict to Let's Encrypt"),
          result => CloudGuard(DnsRecordCreated(result)),
        )
      | "tlsrpt" =>
        CloudGuardCmd.createDnsRecord(
          zoneId,
          "TXT",
          `_smtp._tls.${zoneName}`,
          "v=TLSRPTv1; rua=mailto:tlsrpt@${zoneName}",
          1,
          None,
          None,
          Some("CloudGuard: TLS-RPT reporting"),
          result => CloudGuard(DnsRecordCreated(result)),
        )
      | _ => Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, loading: true}}, cmd)
    }

  // -- DNSSEC --
  | FetchDnssec(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.getDnssec(zoneId, result => CloudGuard(DnssecLoaded(result))),
    )
  | DnssecLoaded(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | EnableDnssec(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.enableDnssec(zoneId, result => CloudGuard(DnssecEnabled(result))),
    )
  | DnssecEnabled(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Hardening --
  | HardenSelected => // Harden first selected zone; subsequent zones handled by ZoneHardened
    switch cg.selectedZoneIds[0] {
    | Some(firstZone) => (
        {
          ...model,
          cloudguard: {
            ...cg,
            loading: true,
            bulkProgress: Some({
              total: Array.length(cg.selectedZoneIds),
              completed: 0,
              failed: 0,
              currentDomain: cg.zones->Array.find(z => z.id === firstZone)->Option.map(z => z.name),
              startedAt: "",
              errors: [],
            }),
          },
        },
        CloudGuardCmd.hardenZone(firstZone, result => CloudGuard(ZoneHardened(result))),
      )
    | None => (model, Tea_Cmd.none)
    }
  | HardenSetting(_settingId) =>
    // Single setting fix — delegates to zone hardening for the first selected zone
    switch cg.selectedZoneIds[0] {
    | Some(zoneId) => (
        {...model, cloudguard: {...cg, loading: true}},
        CloudGuardCmd.hardenZone(zoneId, result => CloudGuard(ZoneHardened(result))),
      )
    | None => (model, Tea_Cmd.none)
    }
  | HardenZone(zoneId) => (
      {...model, cloudguard: {...cg, loading: true}},
      CloudGuardCmd.hardenZone(zoneId, result => CloudGuard(ZoneHardened(result))),
    )
  | ZoneHardened(result) => {
      let progress = switch cg.bulkProgress {
      | Some(p) =>
        switch result {
        | Ok(_) => Some({...p, completed: p.completed + 1})
        | Error(err) =>
          Some({
            ...p,
            completed: p.completed + 1,
            failed: p.failed + 1,
            errors: Array.concat(p.errors, [("unknown", err)]),
          })
        }
      | None => None
      }
      // Check if there are more zones to harden
      let nextIndex = switch progress {
      | Some(p) => p.completed
      | None => 0
      }
      let cmd = if nextIndex < Array.length(cg.selectedZoneIds) {
        switch cg.selectedZoneIds[nextIndex] {
        | Some(nextZone) =>
          CloudGuardCmd.hardenZone(nextZone, result => CloudGuard(ZoneHardened(result)))
        | None => Tea_Cmd.none
        }
      } else {
        Tea_Cmd.none // All done
      }
      let isDone = nextIndex >= Array.length(cg.selectedZoneIds)
      ({...model, cloudguard: {...cg, bulkProgress: progress, loading: !isDone}}, cmd)
    }

  // -- Audit --
  | RunAudit => {
      // Run the audit locally against the loaded settings using CloudGuardPolicy.
      // The audit is pure computation — no API calls needed.
      let currentDomain = switch cg.selectedZoneIds[0] {
      | Some(zoneId) =>
        switch cg.zones->Array.find(z => z.id === zoneId) {
        | Some(zone) => zone.name
        | None => "unknown"
        }
      | None => "unknown"
      }
      let auditResult = CloudGuardPolicy.auditSettings(currentDomain, cg.settings)
      (
        {
          ...model,
          cloudguard: {
            ...cg,
            showAudit: true,
            auditResult: Some(auditResult),
            constraints: CloudGuardPolicy.defaultConstraints,
          },
        },
        Tea_Cmd.none,
      )
    }
  | AuditComplete(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Offline config --
  | DownloadConfig => {
      // Download offline config for the first selected zone
      let cmd = switch cg.selectedZoneIds[0] {
      | Some(zoneId) =>
        CloudGuardCmd.downloadConfig(zoneId, result => CloudGuard(ConfigDownloaded(result)))
      | None => Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, loading: true}}, cmd)
    }
  | ConfigDownloaded(result) =>
    switch result {
    | Ok(_json) => ({...model, cloudguard: {...cg, loading: false}}, Tea_Cmd.none)
    | Error(err) => (
        {...model, cloudguard: {...cg, loading: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }

  // -- Per-domain exceptions --
  | AddException(domain, settingId, overrideValue, reason) => {
      let newException: domainException = {
        domain,
        settingId,
        overrideValue,
        reason,
        addedOn: Date.make()->Date.toISOString,
      }
      // Remove any existing exception for the same domain+setting, then add new
      let filtered =
        cg.exceptions->Array.filter(e => !(e.domain === domain && e.settingId === settingId))
      let exceptions = Array.concat(filtered, [newException])
      ({...model, cloudguard: {...cg, exceptions}}, Tea_Cmd.none)
    }
  | RemoveException(domain, settingId) => {
      let exceptions =
        cg.exceptions->Array.filter(e => !(e.domain === domain && e.settingId === settingId))
      ({...model, cloudguard: {...cg, exceptions}}, Tea_Cmd.none)
    }

  // -- UI state --
  | ToggleCloudGuard => {
      let newVisible = !cg.visible
      let cmd = if newVisible && cg.connection === Disconnected {
        // Auto-connect when opening the panel
        CloudGuardCmd.verifyToken(result => CloudGuard(TokenVerified(result)))
      } else {
        Tea_Cmd.none
      }
      ({...model, cloudguard: {...cg, visible: newVisible}}, cmd)
    }
  | SetCategory(cat) => ({...model, cloudguard: {...cg, activeCategory: cat}}, Tea_Cmd.none)
  | SetFilterText(text) => ({...model, cloudguard: {...cg, filterText: text}}, Tea_Cmd.none)
  | SetSettingFilter(text) => ({...model, cloudguard: {...cg, settingFilter: text}}, Tea_Cmd.none)
  | ToggleAuditPanel => ({...model, cloudguard: {...cg, showAudit: !cg.showAudit}}, Tea_Cmd.none)
  | ToggleDiffPanel => ({...model, cloudguard: {...cg, showDiff: !cg.showDiff}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "cloudguard", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
