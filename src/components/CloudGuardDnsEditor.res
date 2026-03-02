// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard DNS Editor — Inline DNS record table with security templates.
///
/// Renders a tabular view of all DNS records for the selected zone with inline
/// editing, creation, deletion, and one-click security record templates.
///
/// Security templates provide quick setup of:
///   - SPF: `v=spf1 -all` (deny all for domains that don't send email)
///   - DMARC: `v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; pct=100; fo=1`
///   - DKIM revocation: `v=DKIM1; p=` (revoke all DKIM keys)
///   - CAA: `0 issue "letsencrypt.org"` (restrict CA to Let's Encrypt)
///   - TLS-RPT: `v=TLSRPTv1; rua=mailto:tlsrpt@domain`
///
/// Layout:
///   +---------+--------------------+----------------------------+-----+-------+--------+
///   | Type    | Name               | Content                    | TTL | Proxy | Actions|
///   +---------+--------------------+----------------------------+-----+-------+--------+
///   | A       | example.com        | 192.0.2.1                  | Auto| ON    | [Edit][Del]
///   | AAAA    | example.com        | 2001:db8::1                | Auto| ON    | [Edit][Del]
///   | TXT     | example.com        | v=spf1 -all                | Auto| --    | [Edit][Del]
///   | TXT     | _dmarc.example.com | v=DMARC1; p=reject; ...    | Auto| --    | [Edit][Del]
///   | CAA     | example.com        | 0 issue "letsencrypt.org"  | Auto| --    | [Edit][Del]
///   +---------+--------------------+----------------------------+-----+-------+--------+
///   [+ Add Record] [SPF] [DMARC] [DKIM Revoke] [CAA] [TLS-RPT]  <-- Security templates

open Msg
open Model
open Tea.Html

// ============================================================================
// DNS record type display helpers
// ============================================================================

/// Human-readable label for a DNS record type.
let recordTypeLabel = (rt: dnsRecordType): string => {
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

/// CSS colour class for a DNS record type badge.
let recordTypeBadgeClass = (rt: dnsRecordType): string => {
  switch rt {
  | A | AAAA => "bg-blue-900/50 text-blue-300 border-blue-700/50"
  | CNAME => "bg-green-900/50 text-green-300 border-green-700/50"
  | MX => "bg-purple-900/50 text-purple-300 border-purple-700/50"
  | TXT => "bg-yellow-900/50 text-yellow-300 border-yellow-700/50"
  | CAA => "bg-orange-900/50 text-orange-300 border-orange-700/50"
  | NS => "bg-gray-800/50 text-gray-300 border-gray-700/50"
  | SRV => "bg-indigo-900/50 text-indigo-300 border-indigo-700/50"
  | _ => "bg-gray-800/50 text-gray-400 border-gray-700/50"
  }
}

// ============================================================================
// Security status indicators
// ============================================================================

/// Check if a record is a security-relevant TXT record (SPF, DMARC, DKIM, TLSRPT).
let isSecurityRecord = (record: cfDnsRecord): bool => {
  switch record.recordType {
  | TXT =>
    String.includes(record.content, "v=spf1")
    || (String.includes(record.name, "_dmarc") && String.includes(record.content, "v=DMARC1"))
    || (String.includes(record.name, "_domainkey") && String.includes(record.content, "v=DKIM1"))
    || (String.includes(record.name, "_smtp._tls") && String.includes(record.content, "v=TLSRPTv1"))
  | CAA => true
  | _ => false
  }
}

/// Get a security label for a record if it's a known security record.
let securityLabel = (record: cfDnsRecord): option<string> => {
  switch record.recordType {
  | TXT =>
    if String.includes(record.content, "v=spf1") {
      Some("SPF")
    } else if String.includes(record.name, "_dmarc") {
      Some("DMARC")
    } else if String.includes(record.name, "_domainkey") {
      Some("DKIM")
    } else if String.includes(record.name, "_smtp._tls") {
      Some("TLS-RPT")
    } else {
      None
    }
  | CAA => Some("CAA")
  | _ => None
  }
}

// ============================================================================
// Table header
// ============================================================================

/// Render the DNS records table header row.
let renderTableHeader = (): Tea_Vdom.t<msg> => {
  let headerCell = (label: string, width: string) =>
    th(
      list{Attrs.class_(`text-left text-xs text-gray-500 font-medium py-2 px-2 ${width}`)},
      list{text(label)},
    )

  thead(
    list{Attrs.class_("border-b border-gray-800")},
    list{
      tr(
        list{},
        list{
          headerCell("Type", "w-16"),
          headerCell("Name", "w-48"),
          headerCell("Content", ""),
          headerCell("TTL", "w-16"),
          headerCell("Proxy", "w-14"),
          headerCell("", "w-20"), // Actions column
        },
      ),
    },
  )
}

// ============================================================================
// Individual record row
// ============================================================================

/// Render a single DNS record row in the table.
let renderRecordRow = (
  record: cfDnsRecord,
  isEditing: bool,
): Tea_Vdom.t<msg> => {
  let editingClass = isEditing ? " bg-gray-800/80 ring-1 ring-indigo-500/50" : ""
  let secLabel = securityLabel(record)

  tr(
    list{
      Attrs.class_(`hover:bg-gray-800/30 transition-colors${editingClass}`),
      Attrs.ariaLabel(`DNS record ${recordTypeLabel(record.recordType)} ${record.name}`),
    },
    list{
      // Type badge
      td(
        list{Attrs.class_("py-1.5 px-2")},
        list{
          span(
            list{
              Attrs.class_(
                `text-xs font-mono px-1.5 py-0.5 rounded border ${recordTypeBadgeClass(record.recordType)}`,
              ),
            },
            list{text(recordTypeLabel(record.recordType))},
          ),
        },
      ),
      // Name
      td(
        list{Attrs.class_("py-1.5 px-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-1.5")},
            list{
              span(
                list{Attrs.class_("text-sm text-gray-200 font-mono truncate max-w-48")},
                list{text(record.name)},
              ),
              // Security label badge
              switch secLabel {
              | Some(label) =>
                span(
                  list{Attrs.class_("text-xs text-green-400 font-medium px-1 py-0.5 bg-green-900/30 rounded")},
                  list{text(label)},
                )
              | None => noNode
              },
            },
          ),
        },
      ),
      // Content (truncated for long TXT records)
      td(
        list{Attrs.class_("py-1.5 px-2")},
        list{
          div(
            list{
              Attrs.class_("text-sm text-gray-300 font-mono truncate max-w-96"),
              Attrs.title(record.content), // Full content on hover
            },
            list{text(record.content)},
          ),
        },
      ),
      // TTL
      td(
        list{Attrs.class_("py-1.5 px-2 text-xs text-gray-500")},
        list{text(if record.ttl === 1 { "Auto" } else { Int.toString(record.ttl) })},
      ),
      // Proxied status
      td(
        list{Attrs.class_("py-1.5 px-2")},
        list{
          switch record.recordType {
          | A | AAAA | CNAME =>
            span(
              list{
                Attrs.class_(
                  if record.proxied {
                    "text-xs text-orange-400 font-medium"
                  } else {
                    "text-xs text-gray-500"
                  },
                ),
              },
              list{text(if record.proxied { "ON" } else { "OFF" })},
            )
          | _ =>
            span(
              list{Attrs.class_("text-xs text-gray-600")},
              list{text("--")},
            )
          },
        },
      ),
      // Actions
      td(
        list{Attrs.class_("py-1.5 px-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-1")},
            list{
              // Edit button
              if !record.locked {
                button(
                  list{
                    Attrs.class_("text-xs text-gray-500 hover:text-indigo-400 cursor-pointer px-1"),
                    Attrs.ariaLabel(`Edit ${record.name}`),
                    Events.onClick(CloudGuard(StartEditingDnsRecord(record.id))),
                  },
                  list{text("Edit")},
                )
              } else {
                noNode
              },
              // Delete button
              if !record.locked {
                button(
                  list{
                    Attrs.class_("text-xs text-gray-500 hover:text-red-400 cursor-pointer px-1"),
                    Attrs.ariaLabel(`Delete ${record.name}`),
                    Events.onClick(CloudGuard(DeleteDnsRecord(record.zoneId, record.id))),
                  },
                  list{text("Del")},
                )
              } else {
                span(
                  list{Attrs.class_("text-xs text-gray-600 italic")},
                  list{text("Locked")},
                )
              },
            },
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Security template buttons
// ============================================================================

/// Render the security record template buttons.
/// These provide one-click creation of SPF, DMARC, DKIM revocation, CAA, TLS-RPT records.
let renderSecurityTemplates = (
  records: array<cfDnsRecord>,
  hasSelectedZone: bool,
): Tea_Vdom.t<msg> => {
  // Check which security records already exist
  let hasSpf = records->Array.some(r =>
    switch r.recordType {
    | TXT => String.includes(r.content, "v=spf1")
    | _ => false
    }
  )
  let hasDmarc = records->Array.some(r =>
    switch r.recordType {
    | TXT => String.includes(r.name, "_dmarc") && String.includes(r.content, "v=DMARC1")
    | _ => false
    }
  )
  let hasDkim = records->Array.some(r =>
    switch r.recordType {
    | TXT => String.includes(r.name, "_domainkey")
    | _ => false
    }
  )
  let hasCaa = records->Array.some(r =>
    switch r.recordType {
    | CAA => true
    | _ => false
    }
  )
  let hasTlsrpt = records->Array.some(r =>
    switch r.recordType {
    | TXT => String.includes(r.name, "_smtp._tls")
    | _ => false
    }
  )

  /// Render a single template button. Green if record exists, amber if missing.
  let templateButton = (label: string, templateName: string, exists: bool) => {
    let (bgClass, labelSuffix) = if exists {
      ("bg-green-900/30 text-green-400 border-green-700/40 cursor-default", " OK")
    } else {
      ("bg-amber-900/30 text-amber-400 border-amber-700/40 hover:bg-amber-900/50 cursor-pointer", "")
    }

    button(
      list{
        Attrs.class_(`text-xs font-medium px-2 py-1 rounded border ${bgClass}`),
        Attrs.ariaLabel(
          if exists {
            `${label} record already exists`
          } else {
            `Add ${label} security record`
          },
        ),
        if !exists && hasSelectedZone {
          Events.onClick(CloudGuard(ApplySecurityTemplate(templateName)))
        } else {
          Attrs.noProp
        },
      },
      list{text(`${label}${labelSuffix}`)},
    )
  }

  div(
    list{Attrs.class_("flex items-center gap-2 flex-wrap")},
    list{
      span(
        list{Attrs.class_("text-xs text-gray-500 mr-1")},
        list{text("Security:")},
      ),
      templateButton("SPF", "spf", hasSpf),
      templateButton("DMARC", "dmarc", hasDmarc),
      templateButton("DKIM", "dkim_revoke", hasDkim),
      templateButton("CAA", "caa", hasCaa),
      templateButton("TLS-RPT", "tlsrpt", hasTlsrpt),
    },
  )
}

// ============================================================================
// Record count summary
// ============================================================================

/// Render a compact summary showing counts by record type.
let renderRecordSummary = (records: array<cfDnsRecord>): Tea_Vdom.t<msg> => {
  let counts = CloudGuardEngine.countRecordsByType(records)

  div(
    list{Attrs.class_("flex items-center gap-2 flex-wrap")},
    counts
    ->Array.map(((typeName, count)) =>
      span(
        list{Attrs.class_("text-xs text-gray-500")},
        list{text(`${typeName}: ${Int.toString(count)}`)},
      )
    )
    ->List.fromArray,
  )
}

// ============================================================================
// Main DNS editor view
// ============================================================================

/// Render the complete DNS editor for the currently selected zone.
/// Shows the record table, security templates, and record count summary.
let view = (
  records: array<cfDnsRecord>,
  editingId: option<string>,
  hasSelectedZone: bool,
  loading: bool,
): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex-1 flex flex-col"),
      Attrs.role("region"),
      Attrs.ariaLabel("DNS Record Editor"),
    },
    list{
      // Header with record count and security templates
      div(
        list{Attrs.class_("flex items-center justify-between px-3 py-2 border-b border-gray-800/50")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-sm text-gray-300 font-medium")},
                list{text(`${Int.toString(Array.length(records))} records`)},
              ),
              renderRecordSummary(records),
            },
          ),
          renderSecurityTemplates(records, hasSelectedZone),
        },
      ),

      // Loading indicator
      if loading {
        div(
          list{Attrs.class_("text-sm text-gray-500 italic px-3 py-2")},
          list{text("Loading DNS records...")},
        )
      } else {
        noNode
      },

      // Records table
      if Array.length(records) > 0 {
        div(
          list{Attrs.class_("flex-1 overflow-y-auto")},
          list{
            table(
              list{Attrs.class_("w-full text-left")},
              list{
                renderTableHeader(),
                tbody(
                  list{},
                  records
                  ->Array.map(record => {
                    let isEditing = switch editingId {
                    | Some(id) => id === record.id
                    | None => false
                    }
                    renderRecordRow(record, isEditing)
                  })
                  ->List.fromArray,
                ),
              },
            ),
          },
        )
      } else if !loading {
        div(
          list{Attrs.class_("text-sm text-gray-600 italic px-3 py-4")},
          list{text("No DNS records found for this zone.")},
        )
      } else {
        noNode
      },

      // Missing security records warning
      {
        let missing = CloudGuardEngine.checkEmailSecurityRecords(records)
        if Array.length(missing) > 0 && Array.length(records) > 0 {
          div(
            list{Attrs.class_("border-t border-gray-800/50 px-3 py-2")},
            list{
              div(
                list{Attrs.class_("text-xs text-amber-400 font-medium mb-1")},
                list{text("Missing Security Records:")},
              ),
              div(
                list{Attrs.class_("space-y-0.5")},
                missing
                ->Array.map(msg =>
                  div(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{text(`- ${msg}`)},
                  )
                )
                ->List.fromArray,
              ),
            },
          )
        } else {
          noNode
        }
      },
    },
  )
}
