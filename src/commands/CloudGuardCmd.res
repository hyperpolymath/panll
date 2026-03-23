// SPDX-License-Identifier: PMPL-1.0-or-later

/// CloudGuard Backend Command Wrappers — TEA commands for Cloudflare API operations.
///
/// Each function wraps a backend command handler from
/// `src-gossamer/src/cloudguard/commands.rs`, using the `Tea_Cmd.call` pattern
/// to bridge async backend invocations into the TEA update loop.
///
/// Pattern:
///   1. Call `invoke("cloudguard_*", params)` → returns Promise
///   2. On success: `callbacks.enqueue(tagger(Ok(jsonString)))`
///   3. On failure: `callbacks.enqueue(tagger(Error(errorMessage)))`
///
/// The frontend parses JSON strings from `Ok(...)` results in the Update.res
/// sub-updater using `JSON.parseExn` and `JSON.Classify.classify`.

/// Backend invoke binding via RuntimeBridge.
let invoke = RuntimeBridge.invoke

// ============================================================================
// Token verification (health check / connection)
// ============================================================================

/// Verify the Cloudflare API token. Returns connection status JSON.
/// Called when the CloudGuard panel opens and periodically to maintain state.
let verifyToken = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_verify_token", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Cloudflare token verification failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Zone operations
// ============================================================================

/// List all Cloudflare zones (domains) in the account.
/// Returns JSON array of zone objects.
let listZones = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_list_zones", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list Cloudflare zones")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get details for a single zone by ID.
/// Returns JSON zone object.
let getZone = (zoneId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_get_zone", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get zone details")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Settings operations
// ============================================================================

/// Get all settings for a zone.
/// Returns JSON array of setting objects.
let getSettings = (zoneId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_get_settings", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get zone settings")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Update a single zone setting.
/// `value` is a JSON-encoded string of the new value.
/// Returns JSON of the updated setting.
let updateSetting = (
  zoneId: string,
  settingId: string,
  value: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "cloudguard_update_setting",
      {"zone_id": zoneId, "setting_id": settingId, "value": value},
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to update setting " ++ settingId)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Batch-update multiple settings for a zone.
/// `settingsJson` is a JSON array of `[{id, value}]` objects.
/// Returns JSON of the updated settings.
let updateSettingsBatch = (
  zoneId: string,
  settingsJson: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "cloudguard_update_settings_batch",
      {"zone_id": zoneId, "settings_json": settingsJson},
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to batch-update settings")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// DNS record operations
// ============================================================================

/// List all DNS records for a zone.
/// Returns JSON array of DNS record objects.
let listDnsRecords = (
  zoneId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_list_dns_records", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list DNS records")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Create a new DNS record.
/// Payload fields: zone_id, record_type, name, content, ttl, proxied, priority, comment.
let createDnsRecord = (
  zoneId: string,
  recordType: string,
  name: string,
  content: string,
  ttl: int,
  proxied: option<bool>,
  priority: option<int>,
  comment: option<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let payload = Dict.fromArray([
      ("zone_id", JSON.Encode.string(zoneId)),
      ("record_type", JSON.Encode.string(recordType)),
      ("name", JSON.Encode.string(name)),
      ("content", JSON.Encode.string(content)),
      ("ttl", JSON.Encode.int(ttl)),
    ])
    // Add optional fields
    switch proxied {
    | Some(p) => Dict.set(payload, "proxied", JSON.Encode.bool(p))
    | None => ()
    }
    switch priority {
    | Some(p) => Dict.set(payload, "priority", JSON.Encode.int(p))
    | None => ()
    }
    switch comment {
    | Some(c) => Dict.set(payload, "comment", JSON.Encode.string(c))
    | None => ()
    }

    invoke("cloudguard_create_dns_record", JSON.Encode.object(payload))
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to create DNS record")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Delete a DNS record from a zone.
/// Returns a success/failure result.
let deleteDnsRecord = (
  zoneId: string,
  recordId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "cloudguard_delete_dns_record",
      {"zone_id": zoneId, "record_id": recordId},
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to delete DNS record")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// DNSSEC operations
// ============================================================================

/// Get DNSSEC status for a zone.
/// Returns JSON with status, DS record info, algorithm, etc.
let getDnssec = (
  zoneId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_get_dnssec", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get DNSSEC status")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Enable DNSSEC for a zone.
/// Returns the updated DNSSEC status JSON.
let enableDnssec = (
  zoneId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_enable_dnssec", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to enable DNSSEC")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Offline config — download/upload zone configurations
// ============================================================================

/// Download the offline configuration for a zone (settings + DNS records).
/// Saves to ~/.config/cloudguard/configs/{domain}.json and returns the path.
let downloadConfig = (
  zoneId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_download_config", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to download config")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Hardening — one-click security defaults
// ============================================================================

/// Apply the standard hardening settings to a zone.
/// This is the "Harden" button — applies SSL/TLS, HSTS, headers, etc.
/// Returns JSON with status and number of settings updated.
/// Compute a diff between current live settings and a saved configuration.
/// Returns JSON with the list of changed, added, and removed settings.
let computeDiff = (
  zoneId: string,
  savedConfigId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_compute_diff", {"zone_id": zoneId, "config_id": savedConfigId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to compute config diff")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all saved configurations for a zone.
/// Returns JSON array of saved config metadata (id, name, timestamp).
let listSavedConfigs = (
  zoneId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_list_saved_configs", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list saved configs")))
      Promise.resolve()
    })
    ->ignore
  })
}

let hardenZone = (
  zoneId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("cloudguard_harden_zone", {"zone_id": zoneId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Zone hardening failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
