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
    title: "TypeLL covers 7/41 panels",
    category: IntegrationBoundary,
    severity: Medium,
    policyExpectation: "TypeLL cross-panel type intelligence should cover all panels",
    actualBehaviour: "TypeLL wired for 7 panels: VeriSimDB, Protocol-Squisher, My-Lang, Anti-Crash, Pane-L, BoJ, ECHIDNA",
    rationale: "TypeLL integration is incremental. The 7 most type-sensitive panels were prioritised. Remaining 34 panels need integration.",
    scope: "34 panels without TypeLL integration. No type intelligence degradation for those panels — they just lack TypeLL enhancement.",
    identifiedDate: "2026-03-08",
    reviewDate: "2026-06-01",
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
    `exception-register-required = true\n` ++
    `compliance-focus = "seams/compromises/exception register"\n\n`

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

  `Seam Register: ${Int.toString(audit.totalSeams)} seam(s) across ${Int.toString(categoryCount)} categories\n` ++
  `Drift: ${Int.toString(audit.driftCount)} | Unacknowledged: ${Int.toString(audit.unacknowledgedCount)} | Overdue: ${Int.toString(audit.overdueCount)}\n` ++
  audit.summary
}
