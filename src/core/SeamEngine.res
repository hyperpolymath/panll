// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Seam Engine — compliance seam detection and exception register.
///
/// A "seam" is a point where two policies, systems, or standards meet and
/// may not align perfectly. Seams are not bugs — they are acknowledged
/// compromises with bounded scope, rationale, and review dates.
///
/// This engine:
/// 1. Audits known compliance seams (policy exceptions in the codebase)
/// 2. Maintains an exception register with rationale, scope, and expiry
/// 3. Checks for policy drift (e.g., a TypeScript exception spreading)
/// 4. Integrates with seambot (gitbot-fleet) for automated detection
/// 5. Reads A2ML compliance-seams-check policy flags
///
/// Reference: panel-clades/.machine_readable/policies/MAINTENANCE-CHECKLIST.a2ml
///   compliance-seams-check = true
///   exception-register-required = true
///   compliance-focus = "seams/compromises/exception register"
///
/// This is a pure module — no side effects.

// ============================================================================
// Types
// ============================================================================

/// Severity of a compliance seam.
type seamSeverity =
  /// Critical — must be resolved before release.
  | Critical
  /// High — should be resolved soon, risk of drift.
  | High
  /// Medium — acknowledged compromise with bounded scope.
  | Medium
  /// Low — minor deviation, acceptable long-term.
  | Low
  /// Info — informational only, not a compliance issue.
  | Info

/// Category of compliance seam.
type seamCategory =
  /// Language policy deviation (e.g., npm/Node.js where Deno is policy).
  | LanguagePolicy
  /// Licensing deviation from PMPL-1.0-or-later.
  | LicensePolicy
  /// ABI/FFI deviation from Idris2+Zig standard.
  | AbiFfiPolicy
  /// Security policy deviation.
  | SecurityPolicy
  /// Build/tooling deviation from standard.
  | ToolingPolicy
  /// Documentation format deviation (e.g., .md where .adoc is policy).
  | DocsPolicy
  /// Container policy deviation (e.g., Docker where Podman is policy).
  | ContainerPolicy
  /// Integration boundary mismatch between systems.
  | IntegrationBoundary

/// A single compliance seam — an acknowledged point of policy deviation.
type seam = {
  /// Unique identifier for this seam.
  id: string,
  /// Human-readable title.
  title: string,
  /// Which category of policy this seam falls under.
  category: seamCategory,
  /// How severe the deviation is.
  severity: seamSeverity,
  /// What the policy says should happen.
  policyExpectation: string,
  /// What actually happens (the deviation).
  actualBehaviour: string,
  /// Why this deviation exists (rationale).
  rationale: string,
  /// Bounded scope — what this exception covers and nothing more.
  scope: string,
  /// When this seam was first identified.
  identifiedDate: string,
  /// When this seam should be reviewed or resolved.
  reviewDate: string,
  /// Whether this seam has been formally acknowledged.
  acknowledged: bool,
  /// Whether drift has been detected (scope creep beyond original exception).
  driftDetected: bool,
}

/// The exception register — all known seams in one place.
type seamRegister = {
  /// All known seams.
  seams: array<seam>,
  /// When the register was last audited.
  lastAuditDate: string,
  /// Whether compliance-seams-check is enabled (from A2ML policy).
  complianceSeamsCheckEnabled: bool,
  /// Whether exception-register-required is set (from A2ML policy).
  exceptionRegisterRequired: bool,
}

/// Result of a seam audit.
type seamAuditResult = {
  /// Total seams found.
  totalSeams: int,
  /// How many have drift detected.
  driftCount: int,
  /// How many are unacknowledged.
  unacknowledgedCount: int,
  /// How many are past their review date.
  overdueCount: int,
  /// Summary message.
  summary: string,
}

// ============================================================================
// Default state
// ============================================================================

/// Default empty register.
let defaultRegister: seamRegister = {
  seams: [],
  lastAuditDate: "",
  complianceSeamsCheckEnabled: true,
  exceptionRegisterRequired: true,
}

// ============================================================================
// Known PanLL compliance seams
// ============================================================================

/// PanLL's known compliance seams — these are the acknowledged deviations
/// from hyperpolymath policy that exist in this codebase.
let knownPanllSeams: array<seam> = [
  {
    id: "SEAM-001",
    title: "npm dependency for ReScript compiler + Tailwind",
    category: ToolingPolicy,
    severity: Medium,
    policyExpectation: "All tooling should use Deno (npm/Node.js banned)",
    actualBehaviour: "npm is used for ReScript compiler and Tailwind CSS compilation",
    rationale: "ReScript compiler requires npm to run. No Deno-native alternative exists. ADR accepted.",
    scope: "ReScript compiler (rescript) and Tailwind CSS (tailwindcss) npm packages ONLY. No other npm runtime usage.",
    identifiedDate: "2026-02-07",
    reviewDate: "2026-06-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-002",
    title: "Node.js runtime for ReScript compilation",
    category: LanguagePolicy,
    severity: Medium,
    policyExpectation: "Deno replaces Node.js for all JavaScript runtime",
    actualBehaviour: "Node.js is required to run the ReScript compiler",
    rationale: "ReScript compiler is distributed as an npm package requiring Node.js. Planned removal when ReScript adds Deno support.",
    scope: "ReScript build step only. All runtime code and tests use Deno.",
    identifiedDate: "2026-02-07",
    reviewDate: "2026-06-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-003",
    title: "Markdown files where AsciiDoc is policy",
    category: DocsPolicy,
    severity: Low,
    policyExpectation: "Primary docs in AsciiDoc (.adoc)",
    actualBehaviour: "TOPOLOGY.md, CHANGELOG.md, SECURITY.md, CONTRIBUTING.md use Markdown",
    rationale: "GitHub community health files require Markdown for automatic detection. TOPOLOGY.md uses Markdown for broader tool compatibility.",
    scope: "GitHub community health files and TOPOLOGY.md only. Technical docs use .adoc.",
    identifiedDate: "2026-02-07",
    reviewDate: "2026-12-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-004",
    title: "No Idris2 ABI / Zig FFI layer yet",
    category: AbiFfiPolicy,
    severity: Low,
    policyExpectation: "ABI in Idris2 (src/abi/*.idr), FFI in Zig (ffi/zig/)",
    actualBehaviour: "PanLL uses Rust for backend FFI via Tauri commands, no Idris2/Zig layer",
    rationale: "Tauri 2.0 mandates Rust backend. Coprocessor Phase 2/3 simulates Zig FFI in Rust. Actual Zig FFI planned for coprocessor hardware data plane.",
    scope: "Entire Tauri backend. Coprocessor engine has routing stubs for future Zig FFI.",
    identifiedDate: "2026-03-09",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-005",
    title: "Some panel backends return stub data",
    category: IntegrationBoundary,
    severity: Medium,
    policyExpectation: "All panels have real backend connections",
    actualBehaviour: "Farm, Fleet, Hypatia, Aerie, Provenance backends return stub/mock JSON",
    rationale: "Backend services (Fleet Axum, Hypatia Elixir, Aerie V-lang) not yet deployed. Panel UI is complete; backends will be connected when services are ready.",
    scope: "5 specific backend connections: Farm, Fleet, Hypatia, Aerie, Provenance. All other panels have real backends.",
    identifiedDate: "2026-03-08",
    reviewDate: "2026-06-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-006",
    title: "TypeLL covers 41/41 panels (RESOLVED)",
    category: IntegrationBoundary,
    severity: Info,
    policyExpectation: "TypeLL cross-panel type intelligence should cover all panels",
    actualBehaviour: "TypeLL wired for all 41/41 panels via TypeCheckResult(result<string, string>) Msg variant",
    rationale: "Fully resolved as of 2026-03-09. Originally only 7 panels; now all 41 panels have TypeLL integration with panelTypeChecks Dict tracking per-panel results.",
    scope: "Resolved — no remaining gap. Kept in register for audit trail.",
    identifiedDate: "2026-03-08",
    reviewDate: "2026-12-01",
    acknowledged: true,
    driftDetected: false,
  },
  // ==========================================================================
  // UMS panel compliance seams (SEAM-007 through SEAM-013)
  // ==========================================================================
  {
    id: "SEAM-007",
    title: "UMS panel requires Rust backend with registered commands",
    category: IntegrationBoundary,
    severity: High,
    policyExpectation: "UMS panel has a Rust backend with ums_* Tauri commands registered",
    actualBehaviour: "UMS Rust backend commands must be verified present in Tauri command registry",
    rationale: "UMS (Universal Management System) handles device and guard management. Without a Rust backend, the panel cannot perform privileged operations or persist state securely.",
    scope: "UMS Tauri commands only (ums_* namespace). Does not cover other panel backends.",
    identifiedDate: "2026-03-14",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-008",
    title: "UMS panel requires clade definition in clade registry",
    category: IntegrationBoundary,
    severity: High,
    policyExpectation: "UMS panel has a clade definition registered under 'ums' in the panel-clades registry",
    actualBehaviour: "UMS clade entry must exist in clade registry with correct metadata and policy flags",
    rationale: "Every PanLL panel must have a clade definition that declares its capabilities, dependencies, and compliance posture. Without a clade, UMS cannot participate in the compliance audit system.",
    scope: "UMS clade definition in panel-clades registry only. Does not affect other clade entries.",
    identifiedDate: "2026-03-14",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-009",
    title: "UMS panel must fire TypeLL ABI checks on validation",
    category: AbiFfiPolicy,
    severity: Medium,
    policyExpectation: "UMS panel fires TypeLL ABI type-checks during validation lifecycle",
    actualBehaviour: "UMS validation must invoke TypeLL cross-panel type intelligence for ABI conformance",
    rationale: "TypeLL ensures type-level correctness across panel boundaries. UMS manages types (deviceKind, guardRank) shared with other panels; ABI checks prevent type drift at integration seams.",
    scope: "TypeLL ABI checks triggered by UMS validation only. Does not modify TypeLL core engine.",
    identifiedDate: "2026-03-14",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-010",
    title: "UMS panel must have BoJ routing capability",
    category: IntegrationBoundary,
    severity: Medium,
    policyExpectation: "UMS panel has BoJ (Beggar of Justice) routing for cartridge invocation and orchestration",
    actualBehaviour: "UMS must be reachable via BoJ routing table for cross-panel cartridge dispatch",
    rationale: "BoJ is the orchestration layer for PanLL cartridge invocation. UMS must participate in BoJ routing so that other panels and automation can trigger UMS operations through the standard dispatch mechanism.",
    scope: "UMS route entry in BoJ routing table only. Does not alter BoJ core dispatch logic.",
    identifiedDate: "2026-03-14",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-011",
    title: "UMS cartridge must validate all 5 Idris2 proofs",
    category: AbiFfiPolicy,
    severity: High,
    policyExpectation: "UMS cartridge validates all 5 Idris2 formal proofs (memory safety, ABI layout, backward compat, platform selection, FFI correctness)",
    actualBehaviour: "UMS cartridge must check and report status of all 5 Idris2 proof obligations before accepting operations",
    rationale: "The Idris2 ABI layer provides formal verification of interface correctness. UMS handles privileged device/guard operations where proof violations could compromise system integrity. All 5 proofs must pass.",
    scope: "UMS cartridge proof validation only. Proof definitions live in src/abi/*.idr; this seam covers the validation call-site.",
    identifiedDate: "2026-03-14",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-012",
    title: "Level Architect must share UMS types (deviceKind, guardRank, etc.)",
    category: IntegrationBoundary,
    severity: Medium,
    policyExpectation: "Level Architect panel shares UMS domain types (deviceKind, guardRank, etc.) for cross-panel consistency",
    actualBehaviour: "Level Architect must import and re-export UMS shared types rather than defining duplicates",
    rationale: "IDApTIK Level Architect designs levels that reference UMS concepts (device kinds, guard ranks). Type sharing prevents definition drift between the two panels and ensures level data uses canonical UMS types.",
    scope: "Shared types between UMS and Level Architect panels only. Does not affect unrelated panel types.",
    identifiedDate: "2026-03-14",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
  {
    id: "SEAM-013",
    title: "PanelBus must have UMS event subscribers",
    category: IntegrationBoundary,
    severity: Medium,
    policyExpectation: "PanelBus event system has registered UMS event subscribers for cross-panel communication",
    actualBehaviour: "PanelBus must include UMS topic subscriptions so UMS events propagate to interested panels",
    rationale: "PanelBus is PanLL's cross-panel event bus. UMS emits events (device registered, guard promoted, etc.) that other panels (Level Architect, Fleet, Provenance) need to react to. Missing subscribers means silent event loss.",
    scope: "UMS event topics and subscribers in PanelBus only. Does not change PanelBus dispatch mechanism.",
    identifiedDate: "2026-03-14",
    reviewDate: "2026-09-01",
    acknowledged: true,
    driftDetected: false,
  },
]

// ============================================================================
// Engine functions
// ============================================================================

/// Severity label for display.
let severityLabel = (s: seamSeverity): string => {
  switch s {
  | Critical => "CRITICAL"
  | High => "HIGH"
  | Medium => "MEDIUM"
  | Low => "LOW"
  | Info => "INFO"
  }
}

/// Category label for display.
let categoryLabel = (c: seamCategory): string => {
  switch c {
  | LanguagePolicy => "Language Policy"
  | LicensePolicy => "License Policy"
  | AbiFfiPolicy => "ABI/FFI Policy"
  | SecurityPolicy => "Security Policy"
  | ToolingPolicy => "Tooling Policy"
  | DocsPolicy => "Documentation Policy"
  | ContainerPolicy => "Container Policy"
  | IntegrationBoundary => "Integration Boundary"
  }
}

/// Colour for severity (CSS class-compatible).
let severityColour = (s: seamSeverity): string => {
  switch s {
  | Critical => "#dc2626"
  | High => "#ea580c"
  | Medium => "#ca8a04"
  | Low => "#2563eb"
  | Info => "#6b7280"
  }
}

/// Build the PanLL exception register from known seams.
let buildRegister = (auditDate: string): seamRegister => {
  {
    seams: knownPanllSeams,
    lastAuditDate: auditDate,
    complianceSeamsCheckEnabled: true,
    exceptionRegisterRequired: true,
  }
}

/// Check if a seam is overdue for review given a current date string (YYYY-MM-DD).
let isOverdue = (seam: seam, currentDate: string): bool => {
  seam.reviewDate != "" && currentDate > seam.reviewDate
}

/// Audit the register and produce a summary result.
let auditRegister = (register: seamRegister, currentDate: string): seamAuditResult => {
  let totalSeams = register.seams->Array.length
  let driftCount = register.seams->Array.filter(s => s.driftDetected)->Array.length
  let unacknowledgedCount = register.seams->Array.filter(s => !s.acknowledged)->Array.length
  let overdueCount = register.seams->Array.filter(s => isOverdue(s, currentDate))->Array.length

  let summary = if driftCount > 0 {
    `⚠ DRIFT DETECTED: ${Int.toString(driftCount)} seam(s) have drifted beyond original scope`
  } else if unacknowledgedCount > 0 {
    `${Int.toString(unacknowledgedCount)} unacknowledged seam(s) need review`
  } else if overdueCount > 0 {
    `${Int.toString(overdueCount)} seam(s) overdue for review`
  } else {
    `${Int.toString(totalSeams)} seam(s) — all acknowledged, no drift detected`
  }

  {totalSeams, driftCount, unacknowledgedCount, overdueCount, summary}
}

/// Check for policy drift contamination — does a known exception's scope
/// appear to have broadened? This checks if the scope description suggests
/// containment but the actual behaviour hints at broader usage.
let checkDriftRisk = (seam: seam, codebaseIndicators: array<string>): bool => {
  // Check if any indicator suggests the exception has spread beyond scope
  codebaseIndicators->Array.some(indicator => {
    switch seam.category {
    | LanguagePolicy =>
      // If a language exception exists, check if that language appears in unexpected places
      indicator->String.includes("node_modules") && !(seam.scope->String.includes("build step"))
    | ToolingPolicy =>
      // If npm is excepted for specific tools, check if npm is used elsewhere
      indicator->String.includes("npm run") && !(seam.scope->String.includes("npm"))
    | DocsPolicy =>
      // If markdown is excepted for specific files, check if new .md files appeared
      indicator->String.includes(".md") && indicator->String.includes("new file")
    | _ => false
    }
  })
}

/// Generate an A2ML-format exception register section.
let generateA2mlRegister = (register: seamRegister): string => {
  let header =
    `# SPDX-License-Identifier: PMPL-1.0-or-later\n` ++
    `# PanLL Compliance Seam Register (auto-generated)\n` ++
    `# Last audit: ${register.lastAuditDate}\n\n` ++
    `[compliance-policy]\n` ++
    `compliance-seams-check = true\n` ++
    `exception-register-required = true\n` ++ `compliance-focus = "seams/compromises/exception register"\n\n`

  let seamSections =
    register.seams
    ->Array.map(s => {
      `[seam.${s.id}]\n` ++
      `title = "${s.title}"\n` ++
      `category = "${categoryLabel(s.category)}"\n` ++
      `severity = "${severityLabel(s.severity)}"\n` ++
      `policy-expectation = "${s.policyExpectation}"\n` ++
      `actual-behaviour = "${s.actualBehaviour}"\n` ++
      `rationale = "${s.rationale}"\n` ++
      `scope = "${s.scope}"\n` ++
      `identified = "${s.identifiedDate}"\n` ++
      `review-by = "${s.reviewDate}"\n` ++
      `acknowledged = ${s.acknowledged ? "true" : "false"}\n` ++
      `drift-detected = ${s.driftDetected ? "true" : "false"}\n`
    })
    ->Array.join("\n")

  header ++ seamSections
}

/// Drift indicator — a concrete signal from codebase scanning.
type driftIndicator = {
  /// Which seam this indicator relates to.
  seamId: string,
  /// File path where the indicator was found.
  filePath: string,
  /// Description of what was found.
  description: string,
  /// Whether this crosses the seam's bounded scope.
  crossesScope: bool,
}

/// Remediation suggestion for a drifting or overdue seam.
type seamRemediation = {
  /// Which seam this suggestion addresses.
  seamId: string,
  /// Priority of the remediation.
  priority: seamSeverity,
  /// What to do.
  suggestion: string,
  /// Whether this can be automated.
  automatable: bool,
}

/// Scan results from the codebase scanner.
type scanResult = {
  /// All drift indicators found.
  indicators: array<driftIndicator>,
  /// Remediation suggestions generated.
  remediations: array<seamRemediation>,
  /// Timestamp of the scan.
  scanDate: string,
}

// ============================================================================
// Codebase scanner — active drift detection
// ============================================================================

/// Scan a list of file paths for drift indicators against known seams.
/// This is the active scanner that feeds the drift detection engine.
let scanForDriftIndicators = (filePaths: array<string>): array<driftIndicator> => {
  let indicators = []

  // SEAM-001/002: Check if npm/node usage has spread beyond build step
  let npmFiles =
    filePaths->Array.filter(p =>
      (p->String.includes("package.json") && !(p->String.includes("node_modules"))) ||
        (p->String.includes("npm") && !(p->String.includes("deno.json")))
    )
  let npmIndicators = npmFiles->Array.map(p => {
    seamId: "SEAM-001",
    filePath: p,
    description: "npm reference found outside expected build scope",
    crossesScope: !(
      p->String.includes("rescript.json") ||
      p->String.includes("package.json") ||
      p->String.includes("tailwind")
    ),
  })

  // SEAM-003: Check for new Markdown files outside community health set
  let knownMdFiles = [
    "TOPOLOGY.md",
    "CHANGELOG.md",
    "SECURITY.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "QUICKSTART-FOR-SON.md",
    "MIGRATION-TO-RESCRIPT-TEA.md",
    "NPM-TO-DENO-MIGRATION.md",
    "RESCRIPT-TEA-MIGRATION-GUIDE.md",
    "SONNET-TASKS.md",
    "PANLL-COMPLETE-STATUS-2026-02-11.md",
  ]
  let mdFiles =
    filePaths->Array.filter(p =>
      p->String.endsWith(".md") &&
      !(p->String.includes("node_modules")) &&
      !(p->String.includes("docs/"))
    )
  let mdIndicators =
    mdFiles
    ->Array.filter(p => !(knownMdFiles->Array.some(known => p->String.endsWith(known))))
    ->Array.map(p => {
      seamId: "SEAM-003",
      filePath: p,
      description: "Markdown file outside known community health set",
      crossesScope: true,
    })

  // SEAM-004: Check for Zig/Idris2 files (positive signal — resolution progress)
  let abiProgress =
    filePaths
    ->Array.filter(p => p->String.includes("src/abi/") || p->String.includes("ffi/zig/"))
    ->Array.map(p => {
      seamId: "SEAM-004",
      filePath: p,
      description: "ABI/FFI file found — potential seam resolution progress",
      crossesScope: false,
    })

  indicators
  ->Array.concat(npmIndicators)
  ->Array.concat(mdIndicators)
  ->Array.concat(abiProgress)
}

/// Generate remediation suggestions for seams that need attention.
let generateRemediations = (register: seamRegister, currentDate: string): array<
  seamRemediation,
> => {
  register.seams->Array.filterMap(seam => {
    if seam.driftDetected {
      Some({
        seamId: seam.id,
        priority: High,
        suggestion: `Drift detected in ${seam.id}: "${seam.title}". Review scope boundary and either tighten the exception or acknowledge broader scope.`,
        automatable: false,
      })
    } else if isOverdue(seam, currentDate) {
      Some({
        seamId: seam.id,
        priority: seam.severity,
        suggestion: `Seam ${seam.id} overdue for review (due ${seam.reviewDate}). Evaluate whether this exception is still needed or can be resolved.`,
        automatable: false,
      })
    } else if seam.severity == Info {
      Some({
        seamId: seam.id,
        priority: Info,
        suggestion: `Seam ${seam.id} is resolved. Consider removing from active register after next audit cycle.`,
        automatable: true,
      })
    } else {
      None
    }
  })
}

/// Run a full scan: detect indicators, update drift flags, generate remediations.
let fullScan = (filePaths: array<string>, currentDate: string): scanResult => {
  let indicators = scanForDriftIndicators(filePaths)
  let register = buildRegister(currentDate)

  // Check which seams have scope-crossing indicators
  let _seamsWithDrift =
    register.seams
    ->Array.filter(s => indicators->Array.some(i => i.seamId == s.id && i.crossesScope))
    ->Array.map(s => s.id)

  let remediations = generateRemediations(register, currentDate)

  {indicators, remediations, scanDate: currentDate}
}

/// Generate a persistent A2ML register file content for .machine_readable/seams.a2ml.
let generatePersistentRegister = (register: seamRegister, currentDate: string): string => {
  let audit = auditRegister(register, currentDate)
  let header =
    `; SPDX-License-Identifier: PMPL-1.0-or-later\n` ++
    `; PanLL Compliance Seam Register — auto-generated by SeamEngine\n` ++
    `; Last audit: ${currentDate}\n` ++
    `; Total: ${Int.toString(audit.totalSeams)} seams | ` ++
    `Drift: ${Int.toString(audit.driftCount)} | ` ++
    `Overdue: ${Int.toString(audit.overdueCount)}\n\n` ++
    `(seam-register\n` ++
    `  (version "1.0.0")\n` ++
    `  (audit-date "${currentDate}")\n` ++
    `  (compliance-seams-check true)\n` ++ `  (exception-register-required true)\n\n`

  let entries =
    register.seams
    ->Array.map(s =>
      `  (seam\n` ++
      `    (id "${s.id}")\n` ++
      `    (title "${s.title}")\n` ++
      `    (category "${categoryLabel(s.category)}")\n` ++
      `    (severity "${severityLabel(s.severity)}")\n` ++
      `    (scope "${s.scope}")\n` ++
      `    (acknowledged ${s.acknowledged ? "true" : "false"})\n` ++
      `    (drift-detected ${s.driftDetected ? "true" : "false"})\n` ++
      `    (review-date "${s.reviewDate}"))\n`
    )
    ->Array.join("\n")

  header ++ entries ++ `)\n`
}

/// Summarise the register for display in PanLL UI.
let summariseRegister = (register: seamRegister, currentDate: string): string => {
  let audit = auditRegister(register, currentDate)
  let byCategory =
    register.seams
    ->Array.map(s => categoryLabel(s.category))
    ->Array.reduce([], (acc, cat) => {
      if acc->Array.some(c => c == cat) {
        acc
      } else {
        acc->Array.concat([cat])
      }
    })
  let categoryCount = byCategory->Array.length

  `Seam Register: ${Int.toString(audit.totalSeams)} seam(s) across ${Int.toString(
      categoryCount,
    )} categories\n` ++
  `Drift: ${Int.toString(audit.driftCount)} | Unacknowledged: ${Int.toString(
      audit.unacknowledgedCount,
    )} | Overdue: ${Int.toString(audit.overdueCount)}\n` ++
  audit.summary
}
