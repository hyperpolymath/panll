// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Stapeln Model Types — Container stack assembly and orchestration.
///
/// State types for the Stapeln container assembly pipeline panel. Stapeln is
/// the hyperpolymath container ecosystem (Podman-based, Chainguard images,
/// Containerfile-native) and this panel provides PanLL's view into container
/// stack assembly: constraints, validation, artifact generation, and deploy
/// readiness.
///
/// Three-panel model:
///   Panel-L -> Security and resource constraints (SLSA, SBOM, signatures,
///              base image policy, network policy, resource limits)
///   Panel-N -> Assembly reasoning (pipeline state, optimisation suggestions,
///              security posture, dependency resolution, auto-layout)
///   Panel-W -> Generated artifacts (Containerfile preview, compose preview,
///              scan results, gap analysis, deploy readiness, export actions)
///
/// This module has NO dependencies on other PanLL modules — leaf of the
/// type dependency graph, following the same pattern as VabModel.

// ============================================================================
// Security Constraints — Panel-L configuration for supply chain policy
// ============================================================================

/// SLSA (Supply-chain Levels for Software Artifacts) compliance level.
/// Determines how strict the build provenance and attestation requirements are.
type slsaLevel =
  | SlsaNone     // No SLSA requirements
  | Slsa1        // Documentation of the build process
  | Slsa2        // Hosted build platform, signed provenance
  | Slsa3        // Hardened builds, non-falsifiable provenance
  | Slsa4        // Two-party review, hermetic/reproducible builds

/// Signature requirement for container images.
type signaturePolicy =
  | NoSignature        // No signature required
  | Cosign             // Sigstore cosign signature
  | Notary             // Docker Content Trust / Notary v2
  | CerroTorre         // cerro-torre sign (hyperpolymath tooling)

/// SBOM (Software Bill of Materials) format requirement.
type sbomFormat =
  | SbomNone           // No SBOM required
  | Spdx               // SPDX JSON/TV format
  | CycloneDx          // CycloneDX JSON/XML format
  | SbomBoth           // Both SPDX and CycloneDX

/// Network protocol allowed in container network policies.
type networkProtocol =
  | Tcp
  | Udp
  | Sctp

/// A single network policy rule (port + protocol allow/deny).
type networkPolicyRule = {
  port: int,
  protocol: networkProtocol,
  direction: string,       // "ingress" | "egress"
  description: string,
}

/// A single base image registry constraint.
type registryConstraint = {
  registry: string,        // e.g. "cgr.dev/chainguard", "docker.io"
  allowed: bool,           // true = allowed, false = denied
}

/// The full set of assembly constraints visible in Panel-L.
type stapelnConstraints = {
  minSlsaLevel: slsaLevel,
  signaturePolicy: signaturePolicy,
  sbomFormat: sbomFormat,
  maxImageSizeMb: int,
  memoryLimitMb: int,
  cpuLimit: float,              // CPU cores (e.g. 2.0)
  networkRules: array<networkPolicyRule>,
  registryConstraints: array<registryConstraint>,
  deniedImages: array<string>,  // Specific image:tag patterns to deny
  requireHealthcheck: bool,
  requireNonRoot: bool,
}

// ============================================================================
// Pipeline Status — Panel-N reasoning state
// ============================================================================

/// Overall pipeline health indicator.
type pipelineHealth =
  | PipelineHealthy       // All checks passing
  | PipelineWarning       // Non-blocking issues detected
  | PipelineFailing       // Blocking issues present
  | PipelineUnknown       // Status not yet determined

/// A single optimisation suggestion from the reasoning engine.
type optimisationSuggestion = {
  id: string,
  severity: string,        // "info" | "warning" | "critical"
  category: string,        // "size" | "security" | "performance" | "compliance"
  message: string,
  autoFixAvailable: bool,
}

/// Dependency resolution status for a single dependency.
type depResolutionStatus =
  | DepResolved(string)     // Resolved to version
  | DepUnresolved(string)   // Cannot resolve (reason)
  | DepConflict(string)     // Version conflict (details)

/// Security posture summary from the reasoning engine.
type securityPosture = {
  score: float,              // 0.0 - 1.0
  slsaCompliant: bool,
  sbomPresent: bool,
  signatureValid: bool,
  vulnerabilities: int,      // Known CVE count
  criticalVulns: int,        // Critical/High CVE count
}

/// Pipeline status as reported by the stapeln backend.
type pipelineStatus = {
  health: pipelineHealth,
  nodeCount: int,
  connectionCount: int,
  validationPassing: bool,
  suggestions: array<optimisationSuggestion>,
  securityPosture: securityPosture,
  dependencies: array<(string, depResolutionStatus)>,
  lastUpdated: float,        // Timestamp
}

// ============================================================================
// Validation Summary — shared between Panel-N reasoning and Panel-W results
// ============================================================================

/// A single validation finding (error, warning, or info).
type validationFinding = {
  id: string,
  level: string,             // "error" | "warning" | "info"
  rule: string,              // Rule identifier (e.g. "DL3006", "SC2086")
  message: string,
  line: option<int>,         // Line number in Containerfile (if applicable)
  autoFixAvailable: bool,
}

/// Summary of all validation results for the current assembly.
type validationSummary = {
  passed: bool,
  errorCount: int,
  warningCount: int,
  infoCount: int,
  findings: array<validationFinding>,
  scanTimestamp: float,
}

// ============================================================================
// Artifact Formats — Panel-W output options
// ============================================================================

/// Output format for generated container artifacts.
type artifactFormat =
  | FormatContainerfile    // Single Containerfile
  | FormatCompose          // compose.yaml (Podman Compose / docker-compose)
  | FormatKubernetes       // Kubernetes manifests (Pod, Deployment, Service)
  | FormatQuadlet          // Systemd Quadlet (.container, .kube)

// ============================================================================
// Stapeln Panel State — the top-level state record
// ============================================================================

/// Available container components in the stapeln stack catalog.
type stapelnComponent = {
  id: string,
  name: string,
  baseImage: string,         // e.g. "cgr.dev/chainguard/wolfi-base:latest"
  description: string,
  tags: array<string>,       // e.g. ["runtime", "build", "security"]
  sizeEstimateMb: int,
}

/// The complete Stapeln panel state, stored as a sub-record in the main model.
type stapelnState = {
  // Connection
  pipelineUrl: string,           // URL to stapeln backend API
  connected: bool,               // Whether backend is reachable

  // Panel-L: Constraints
  constraints: stapelnConstraints,

  // Panel-N: Assembly reasoning
  pipelineStatus: option<pipelineStatus>,
  catalog: array<stapelnComponent>,  // Available components from stack

  // Panel-W: Results and artifacts
  lastValidation: option<validationSummary>,
  generatedArtifact: option<string>,   // Generated artifact content (preview)
  selectedFormat: artifactFormat,       // Which format to generate

  // UI state
  activeTab: string,              // "constraints" | "reasoning" | "results"
  loading: bool,
  error: option<string>,
}
