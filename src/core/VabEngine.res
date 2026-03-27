// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL VAB Engine — Dependency checking and capability computation.
///
/// Pure functions that analyse an assembled server's component list against
/// the full catalog, producing dependency warnings (like KSP's "No engine!")
/// and a capability enumeration (what the server CAN and CANNOT do).
///
/// No side effects — these functions are called after every assembly change
/// to recompute the status bar and warning list.

/// Uses VabModel types directly (not Model) to avoid dependency cycles.
/// Model includes VabModel, but also references VabEngine — so we go
/// straight to the leaf module.
open VabModel

// ===========================================================================
// Dependency Checking
// ===========================================================================

/// Check all dependency constraints for the assembled server.
/// Returns warnings for missing required deps, missing recommended deps,
/// port conflicts, and security advisories.
///
/// Rules:
///   - Each component's `dependencies` must ALL be present → MissingRequired
///   - Each component's `softDependencies` SHOULD be present → MissingRecommended
///   - Two components sharing a port number → PortConflict
///   - Assembly with 3+ components but no audit → SecurityWarning
///   - Assembly with 3+ components but no config → SecurityWarning
let checkDependencies = (assembledIds: array<string>, catalog: array<vabComponent>): array<
  vabWarning,
> => {
  let warnings: ref<array<vabWarning>> = ref([])

  // Collect all assembled components
  let assembledComponents = Array.filterMap(assembledIds, id => VabCatalog.findById(catalog, id))

  // Check required dependencies
  Array.forEach(assembledComponents, comp => {
    Array.forEach(comp.dependencies, depId => {
      let depPresent = Array.some(assembledIds, id => id === depId)
      if !depPresent {
        warnings := Array.concat(warnings.contents, [MissingRequired(comp.id, depId)])
      }
    })
  })

  // Check soft dependencies (recommended)
  Array.forEach(assembledComponents, comp => {
    Array.forEach(comp.softDependencies, depId => {
      let depPresent = Array.some(assembledIds, id => id === depId)
      if !depPresent {
        warnings := Array.concat(warnings.contents, [MissingRecommended(comp.id, depId)])
      }
    })
  })

  // Check port conflicts: two different components claiming the same port
  let portMap: ref<array<(int, string)>> = ref([])
  Array.forEach(assembledComponents, comp => {
    Array.forEach(comp.ports, port => {
      let existing = Array.find(portMap.contents, ((p, _)) => p === port)
      switch existing {
      | Some((_, existingId)) =>
        if existingId !== comp.id {
          warnings := Array.concat(warnings.contents, [PortConflict(port, existingId, comp.id)])
        }
      | None => portMap := Array.concat(portMap.contents, [(port, comp.id)])
      }
    })
  })

  // Security advisories for non-trivial assemblies
  let componentCount = Array.length(assembledIds)
  if componentCount >= 3 {
    let hasAudit = Array.some(assembledIds, id => id === "proven-audit")
    if !hasAudit {
      warnings :=
        Array.concat(
          warnings.contents,
          [SecurityWarning("No audit logger — operations will not be logged for compliance")],
        )
    }

    let hasConfig = Array.some(assembledIds, id => id === "proven-config")
    if !hasConfig {
      warnings :=
        Array.concat(
          warnings.contents,
          [SecurityWarning("No configuration management — settings will be hardcoded")],
        )
    }
  }

  // Warn if any TLS-capable service lacks TLS
  let hasTls = Array.some(assembledIds, id => id === "proven-tls")
  if !hasTls {
    let needsTls = Array.some(assembledComponents, comp =>
      Array.some(comp.ports, port => port === 443 || port === 993 || port === 8443 || port === 636)
    )
    if needsTls {
      warnings :=
        Array.concat(
          warnings.contents,
          [SecurityWarning("Components use secure ports but TLS engine is not installed")],
        )
    }
  }

  warnings.contents
}

// ===========================================================================
// Capability Computation
// ===========================================================================

/// The 19 capability categories that a server can fulfil.
/// Each maps to one or more capability tags from the component catalog.
let capabilityCategories: array<(string, array<string>)> = [
  ("HTTP serving", ["http", "web-serving"]),
  ("Encryption (TLS)", ["encryption", "tls"]),
  ("DNS resolution", ["dns-resolution"]),
  ("Database queries", ["database", "sql", "database-connectivity"]),
  ("Caching", ["caching", "in-memory"]),
  ("Email (send)", ["email-send", "smtp"]),
  ("Email (receive)", ["email-receive", "imap", "pop3"]),
  ("Authentication", ["authentication", "oauth", "oidc", "kerberos", "sso"]),
  ("Audit logging", ["audit-logging", "compliance"]),
  ("Load balancing", ["load-balancing"]),
  ("Proxying", ["proxying"]),
  ("Real-time messaging", ["websocket", "real-time", "real-time-messaging"]),
  ("File transfer", ["ftp", "file-transfer", "nfs", "smb", "file-sharing"]),
  ("IoT messaging", ["mqtt", "coap", "iot-messaging"]),
  ("VPN / tunnelling", ["vpn", "tunnelling"]),
  ("Container isolation", ["containers", "sandboxing"]),
  ("Monitoring", ["monitoring", "health-checks", "metrics"]),
  ("Intrusion detection", ["ids", "intrusion-detection", "siem"]),
  ("AI / neurosymbolic", ["ai-agents", "neurosymbolic", "mcp"]),
  ("AI manifests (A2ML)", ["a2ml", "ai-manifest"]),
  ("K9 contractiles", ["k9-contractiles", "deployment-config"]),
  ("Internationalisation", ["i18n"]),
  (
    "Document formats",
    [
      "document-json",
      "document-yaml",
      "document-toml",
      "document-xml",
      "document-adoc",
      "document-djot",
      "document-markdown",
      "document-pdf",
      "document-a2ml",
    ],
  ),
]

/// Compute the capability status list for the assembled server.
/// For each of the 19 capability categories, checks whether any assembled
/// component provides a matching capability tag. Incorporates warnings
/// to produce WarningCap for partially-fulfilled capabilities.
let computeCapabilities = (
  assembledIds: array<string>,
  catalog: array<vabComponent>,
  warnings: array<vabWarning>,
): array<capabilityStatus> => {
  // Collect all capability tags from assembled components
  let assembledComponents = Array.filterMap(assembledIds, id => VabCatalog.findById(catalog, id))
  let allCaps = Array.flatMap(assembledComponents, comp => comp.capabilities)

  // For each capability category, determine status
  Array.map(capabilityCategories, ((name, tags)) => {
    let hasTag = Array.some(tags, tag => Array.some(allCaps, cap => cap === tag))

    if hasTag {
      // Check if any warnings affect this capability
      let hasRelatedWarning = Array.some(warnings, w =>
        switch w {
        | MissingRequired(compId, _) =>
          // Find the component and check if its capabilities overlap with this category
          switch VabCatalog.findById(catalog, compId) {
          | Some(comp) => Array.some(comp.capabilities, cap => Array.some(tags, tag => tag === cap))
          | None => false
          }
        | SecurityWarning(_) =>
          // Security warnings affect encryption and audit categories
          name === "Encryption (TLS)" || name === "Audit logging"
        | _ => false
        }
      )
      if hasRelatedWarning {
        WarningCap(name)
      } else {
        CanDo(name)
      }
    } else {
      CannotDo(name)
    }
  })
}

/// Count warnings by severity for the status bar display.
let countWarnings = (warnings: array<vabWarning>): (int, int, int) => {
  let required = ref(0)
  let recommended = ref(0)
  let security = ref(0)

  Array.forEach(warnings, w =>
    switch w {
    | MissingRequired(_, _) => required := required.contents + 1
    | MissingRecommended(_, _) => recommended := recommended.contents + 1
    | SecurityWarning(_) => security := security.contents + 1
    | PortConflict(_, _, _) => required := required.contents + 1
    }
  )

  (required.contents, recommended.contents, security.contents)
}

/// Get a human-readable label for a warning.
let warningLabel = (w: vabWarning, catalog: array<vabComponent>): string => {
  let nameOf = (id: string): string =>
    switch VabCatalog.findById(catalog, id) {
    | Some(c) => c.name
    | None => id
    }

  switch w {
  | MissingRequired(comp, dep) => `${nameOf(comp)} requires ${nameOf(dep)}`
  | MissingRecommended(comp, dep) => `${nameOf(comp)} recommends ${nameOf(dep)}`
  | SecurityWarning(msg) => msg
  | PortConflict(port, a, b) => `Port ${Int.toString(port)} conflict: ${nameOf(a)} vs ${nameOf(b)}`
  }
}

/// Determine severity class for a warning (for colour coding).
let warningSeverity = (w: vabWarning): string =>
  switch w {
  | MissingRequired(_, _) => "error"
  | PortConflict(_, _, _) => "error"
  | SecurityWarning(_) => "warning"
  | MissingRecommended(_, _) => "info"
  }
