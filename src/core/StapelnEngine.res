// SPDX-License-Identifier: MPL-2.0

/// PanLL Stapeln Engine — pure computation and helpers for
/// the container stack assembly pipeline panel.

open StapelnModel

/// Default security constraints — opinionated secure defaults following
/// hyperpolymath container ecosystem standards (Chainguard base images,
/// cosign signatures, SPDX SBOM, non-root, healthchecks required).
let defaultConstraints: stapelnConstraints = {
  minSlsaLevel: Slsa2,
  signaturePolicy: CerroTorre,
  sbomFormat: Spdx,
  maxImageSizeMb: 256,
  memoryLimitMb: 512,
  cpuLimit: 2.0,
  networkRules: [
    {port: 443, protocol: Tcp, direction: "egress", description: "HTTPS outbound"},
    {port: 80, protocol: Tcp, direction: "ingress", description: "HTTP inbound"},
  ],
  registryConstraints: [
    {registry: "cgr.dev/chainguard", allowed: true},
    {registry: "ghcr.io", allowed: true},
    {registry: "docker.io", allowed: false},
  ],
  deniedImages: ["ubuntu:latest", "alpine:latest", "node:*"],
  requireHealthcheck: true,
  requireNonRoot: true,
}

/// Default initial state for the stapeln panel.
let defaultState: stapelnState = {
  pipelineUrl: "http://localhost:8420",
  connected: false,
  constraints: defaultConstraints,
  pipelineStatus: None,
  catalog: [],
  lastValidation: None,
  generatedArtifact: None,
  selectedFormat: FormatContainerfile,
  activeTab: "constraints",
  loading: false,
  error: None,
}

/// Human-readable label for SLSA levels.
let slsaLabel = (level: slsaLevel): string =>
  switch level {
  | SlsaNone => "None"
  | Slsa1 => "SLSA 1"
  | Slsa2 => "SLSA 2"
  | Slsa3 => "SLSA 3"
  | Slsa4 => "SLSA 4"
  }

/// Human-readable label for signature policy.
let signaturePolicyLabel = (policy: signaturePolicy): string =>
  switch policy {
  | NoSignature => "None"
  | Cosign => "Cosign (Sigstore)"
  | Notary => "Notary v2"
  | CerroTorre => "cerro-torre sign"
  }

/// Human-readable label for SBOM format.
let sbomFormatLabel = (fmt: sbomFormat): string =>
  switch fmt {
  | SbomNone => "None"
  | Spdx => "SPDX"
  | CycloneDx => "CycloneDX"
  | SbomBoth => "SPDX + CycloneDX"
  }

/// Human-readable label for artifact format.
let artifactFormatLabel = (fmt: artifactFormat): string =>
  switch fmt {
  | FormatContainerfile => "Containerfile"
  | FormatCompose => "compose.yaml"
  | FormatKubernetes => "Kubernetes"
  | FormatQuadlet => "Quadlet"
  }

/// Human-readable label for pipeline health.
let healthLabel = (h: pipelineHealth): string =>
  switch h {
  | PipelineHealthy => "Healthy"
  | PipelineWarning => "Warning"
  | PipelineFailing => "Failing"
  | PipelineUnknown => "Unknown"
  }

/// Tailwind colour class for pipeline health indicator.
let healthColour = (h: pipelineHealth): string =>
  switch h {
  | PipelineHealthy => "text-emerald-400"
  | PipelineWarning => "text-amber-400"
  | PipelineFailing => "text-red-400"
  | PipelineUnknown => "text-gray-400"
  }

/// Tailwind colour class for validation finding level.
let findingLevelColour = (level: string): string =>
  switch level {
  | "error" => "text-red-400"
  | "warning" => "text-amber-400"
  | _ => "text-blue-400"
  }

/// Count findings by level.
let countFindings = (findings: array<validationFinding>, level: string): int =>
  findings->Array.filter(f => f.level === level)->Array.length

/// Security posture score as a percentage string.
let posturePercentage = (posture: securityPosture): string =>
  Int.toString(Float.toInt(posture.score *. 100.0)) ++ "%"

/// All artifact format options (for dropdown/tab rendering).
let allFormats: array<artifactFormat> = [
  FormatContainerfile,
  FormatCompose,
  FormatKubernetes,
  FormatQuadlet,
]

/// All SLSA levels (for dropdown rendering).
let allSlsaLevels: array<slsaLevel> = [SlsaNone, Slsa1, Slsa2, Slsa3, Slsa4]
