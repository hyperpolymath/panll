// SPDX-License-Identifier: MPL-2.0

/// PanLL Hypatia Engine — pure computation for the Hypatia panel.
///
/// Parses Elixir API responses, computes aggregate metrics, filters
/// and sorts scan results, and provides display helpers.

open HypatiaModel
open FleetModel

/// Human-readable label for a neural network ID.
let netLabel = (id: neuralNetId): string =>
  switch id {
  | GraphOfTrust => "Graph of Trust"
  | MixtureOfExperts => "Mixture of Experts"
  | LiquidStateMachine => "Liquid State Machine"
  | EchoStateNetwork => "Echo State Network"
  | RadialNeuralNetwork => "Radial Neural Network"
  }

/// Description of what each network does.
let netDescription = (id: neuralNetId): string =>
  switch id {
  | GraphOfTrust => "PageRank trust over repos/bots/recipes"
  | MixtureOfExperts => "Domain-specific confidence (7 experts)"
  | LiquidStateMachine => "Temporal anomaly detection"
  | EchoStateNetwork => "Confidence trajectory forecasting"
  | RadialNeuralNetwork => "Finding similarity + novelty detection"
  }

/// CSS class for network status indicator.
let netStatusColor = (status: neuralNetStatus): string =>
  switch status {
  | NetActive => "bg-green-400"
  | NetTraining => "bg-blue-400 animate-pulse"
  | NetOffline => "bg-gray-500"
  | NetError(_) => "bg-red-400"
  }

/// Human-readable label for a pipeline stage.
let stageLabel = (stage: pipelineStage): string =>
  switch stage {
  | Ingestion => "Ingestion"
  | Analysis => "Analysis"
  | Routing => "Routing"
  | Dispatch => "Dispatch"
  | Complete => "Complete"
  }

/// Category tab label.
let categoryLabel = (cat: hypatiaCategory): string =>
  switch cat {
  | HypatiaDashboard => "Dashboard"
  | HypatiaScans => "Scans"
  | HypatiaQuarantine => "Quarantine"
  | HypatiaNeural => "Neural"
  | HypatiaRecipes => "Recipes"
  }

/// Filter scan results by text search.
let filterScans = (scans: array<scanResult>, query: string): array<scanResult> => {
  if query === "" {
    scans
  } else {
    let q = String.toLowerCase(query)
    scans->Array.filter(s => String.includes(String.toLowerCase(s.repoName), q))
  }
}

/// Compute average confidence across all active networks.
let avgConfidence = (networks: array<neuralNetState>): float => {
  let active = networks->Array.filter(n =>
    switch n.status {
    | NetActive => true
    | _ => false
    }
  )
  if Array.length(active) > 0 {
    active->Array.map(n => n.confidence)->Array.reduce(0.0, (a, b) => a +. b) /.
      Int.toFloat(Array.length(active))
  } else {
    0.0
  }
}

/// Parse a neural network ID string into a neuralNetId variant.
let parseNetId = (s: string): option<neuralNetId> =>
  switch s {
  | "graph_of_trust" => Some(GraphOfTrust)
  | "mixture_of_experts" => Some(MixtureOfExperts)
  | "liquid_state_machine" => Some(LiquidStateMachine)
  | "echo_state_network" => Some(EchoStateNetwork)
  | "radial_neural_network" => Some(RadialNeuralNetwork)
  | _ => None
  }

/// Parse a neural network status string into a neuralNetStatus variant.
let parseNetStatus = (s: string): neuralNetStatus =>
  switch s {
  | "active" => NetActive
  | "training" => NetTraining
  | "offline" => NetOffline
  | _ => NetError(s)
  }

/// Tea_Json decoder for a single neural network state.
/// Validates the network ID, skipping unknown networks.
let networkDecoder: Tea_Json.decoder<neuralNetState> = json => {
  open Decoders
  open Tea_Json
  let inner = map5(
    (idStr, statusStr, confidence, inferenceCount, version) => (
      idStr,
      statusStr,
      confidence,
      inferenceCount,
      version,
    ),
    stringField("id"),
    stringField("status"),
    floatField("confidence"),
    intField("inference_count"),
    stringField("version"),
  )
  switch inner(json) {
  | Ok((idStr, statusStr, confidence, inferenceCount, version)) =>
    switch parseNetId(idStr) {
    | Some(netId) =>
      Ok(
        (
          {
            id: netId,
            status: parseNetStatus(statusStr),
            confidence,
            inferenceCount,
            version,
          }: neuralNetState
        ),
      )
    | None => Error(Failure(`Unknown neural net id: ${idStr}`, json))
    }
  | Error(e) => Error(e)
  }
}

/// Parse neural network states from API JSON.
let parseNetworks = (json: string): result<array<neuralNetState>, string> =>
  Decoders.decode(Decoders.lenientArray(networkDecoder), json)

/// Tea_Json decoder for a single scan result.
let scanResultDecoder: Tea_Json.decoder<scanResult> = {
  open Decoders
  map6((repoName, riskScore, findingCount, quarantineCount, lastScanned, passed): scanResult => {
    repoName,
    riskScore,
    findingCount,
    quarantineCount,
    lastScanned,
    passed,
  }, stringField(
    "repo_name",
  ), floatField(
    "risk_score",
  ), intField(
    "finding_count",
  ), intField("quarantine_count"), stringField("last_scanned"), boolField("passed"))
}

/// Parse scan results from API JSON.
let parseScans = (json: string): result<array<scanResult>, string> =>
  Decoders.decode(Decoders.lenientArray(scanResultDecoder), json)

/// Safety tier label.
let tierLabel = (tier: safetyTier): string =>
  switch tier {
  | Eliminate => "Eliminate"
  | Substitute => "Substitute"
  | Control => "Control"
  }

/// Safety tier colour class.
let tierColor = (tier: safetyTier): string =>
  switch tier {
  | Eliminate => "text-red-400"
  | Substitute => "text-amber-400"
  | Control => "text-blue-400"
  }

/// Safety tier background colour class.
let tierBg = (tier: safetyTier): string =>
  switch tier {
  | Eliminate => "bg-red-900/30 border-red-800"
  | Substitute => "bg-amber-900/30 border-amber-800"
  | Control => "bg-blue-900/30 border-blue-800"
  }

/// Built-in sample recipe entries (the 34-recipe Hypatia inventory).
let sampleRecipes = (): array<recipeEntry> => [
  {
    id: "hyp-001",
    name: "believe_me detector",
    description: "Flags Idris2 believe_me — proof-hole that compiles silently",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["Idris2"],
    timesTriggered: 4566,
    lastTriggered: "2026-02-22",
  },
  {
    id: "hyp-002",
    name: "sorry detector",
    description: "Flags Lean sorry — incomplete proof placeholder",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["Lean"],
    timesTriggered: 0,
    lastTriggered: "never",
  },
  {
    id: "hyp-003",
    name: "Admitted detector",
    description: "Flags Coq Admitted — unproven theorem accepted",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: false,
    languages: ["Coq"],
    timesTriggered: 22,
    lastTriggered: "2026-02-18",
  },
  {
    id: "hyp-004",
    name: "unsafeCoerce detector",
    description: "Flags Haskell unsafeCoerce — type-system bypass",
    confidence: 0.98,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["Haskell"],
    timesTriggered: 3,
    lastTriggered: "2026-01-15",
  },
  {
    id: "hyp-005",
    name: "Obj.magic detector",
    description: "Flags OCaml Obj.magic — unsafe type coercion",
    confidence: 0.98,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["OCaml"],
    timesTriggered: 1,
    lastTriggered: "2026-02-10",
  },
  {
    id: "hyp-006",
    name: "assert_total guard",
    description: "Flags Idris2 assert_total — totality escape hatch",
    confidence: 0.97,
    tier: Substitute,
    hasFixScript: true,
    languages: ["Idris2"],
    timesTriggered: 0,
    lastTriggered: "never",
  },
  {
    id: "hyp-007",
    name: "SPDX header check",
    description: "Verifies SPDX-License-Identifier present in all source files",
    confidence: 0.99,
    tier: Control,
    hasFixScript: true,
    languages: ["*"],
    timesTriggered: 892,
    lastTriggered: "2026-03-14",
  },
  {
    id: "hyp-008",
    name: "SHA pin validator",
    description: "Ensures GitHub Actions use SHA-pinned versions",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["YAML"],
    timesTriggered: 341,
    lastTriggered: "2026-03-14",
  },
  {
    id: "hyp-009",
    name: "permissions: read-all",
    description: "Verifies workflow-level read-all permissions",
    confidence: 0.98,
    tier: Control,
    hasFixScript: true,
    languages: ["YAML"],
    timesTriggered: 257,
    lastTriggered: "2026-03-13",
  },
  {
    id: "hyp-010",
    name: "npm/bun blocker",
    description: "Blocks npm/bun usage — enforces Deno-first policy",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: false,
    languages: ["JSON", "YAML"],
    timesTriggered: 45,
    lastTriggered: "2026-03-10",
  },
  {
    id: "hyp-011",
    name: "TypeScript blocker",
    description: "Blocks .ts/.tsx files — enforces ReScript-first policy",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: false,
    languages: ["TypeScript"],
    timesTriggered: 12,
    lastTriggered: "2026-03-08",
  },
  {
    id: "hyp-012",
    name: "SCM file location",
    description: "Ensures STATE/META/ECOSYSTEM.scm are in .machine_readable/ only",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["Scheme"],
    timesTriggered: 15,
    lastTriggered: "2026-02-20",
  },
  {
    id: "hyp-013",
    name: "secret scanner",
    description: "Detects API keys, tokens, passwords in source code",
    confidence: 0.95,
    tier: Eliminate,
    hasFixScript: false,
    languages: ["*"],
    timesTriggered: 7,
    lastTriggered: "2026-03-01",
  },
  {
    id: "hyp-014",
    name: "unsafe block auditor",
    description: "Audits Rust unsafe blocks for // SAFETY: comments",
    confidence: 0.97,
    tier: Substitute,
    hasFixScript: true,
    languages: ["Rust"],
    timesTriggered: 28,
    lastTriggered: "2026-03-12",
  },
  {
    id: "hyp-015",
    name: "editorconfig check",
    description: "Validates .editorconfig present and correct",
    confidence: 0.99,
    tier: Control,
    hasFixScript: true,
    languages: ["*"],
    timesTriggered: 8,
    lastTriggered: "2026-02-14",
  },
  {
    id: "hyp-016",
    name: "CODEQL matrix",
    description: "Validates CodeQL language matrix matches repo languages",
    confidence: 0.96,
    tier: Control,
    hasFixScript: true,
    languages: ["YAML"],
    timesTriggered: 34,
    lastTriggered: "2026-03-14",
  },
  {
    id: "hyp-017",
    name: "Trustfile validator",
    description: "Validates Trustfile.a2ml structure and security level",
    confidence: 0.93,
    tier: Control,
    hasFixScript: false,
    languages: ["A2ML"],
    timesTriggered: 4,
    lastTriggered: "2026-02-22",
  },
  {
    id: "hyp-018",
    name: "TOPOLOGY.md checker",
    description: "Verifies TOPOLOGY.md has architecture diagram + dashboard",
    confidence: 0.91,
    tier: Control,
    hasFixScript: true,
    languages: ["Markdown"],
    timesTriggered: 261,
    lastTriggered: "2026-03-14",
  },
  {
    id: "hyp-019",
    name: "mirror sync check",
    description: "Ensures GitLab/Bitbucket mirrors are in sync",
    confidence: 0.95,
    tier: Control,
    hasFixScript: true,
    languages: ["YAML"],
    timesTriggered: 19,
    lastTriggered: "2026-03-13",
  },
  {
    id: "hyp-020",
    name: "Justfile present",
    description: "Validates justfile exists with standard recipes",
    confidence: 0.97,
    tier: Control,
    hasFixScript: true,
    languages: ["Just"],
    timesTriggered: 190,
    lastTriggered: "2026-03-14",
  },
  {
    id: "hyp-021",
    name: "AI manifest check",
    description: "Verifies 0-AI-MANIFEST.a2ml or AI.a2ml present",
    confidence: 0.98,
    tier: Control,
    hasFixScript: true,
    languages: ["A2ML"],
    timesTriggered: 173,
    lastTriggered: "2026-03-14",
  },
  {
    id: "hyp-022",
    name: "branch protection",
    description: "Checks main branch protection rules enabled",
    confidence: 0.94,
    tier: Substitute,
    hasFixScript: true,
    languages: ["*"],
    timesTriggered: 8,
    lastTriggered: "2026-02-14",
  },
  {
    id: "hyp-023",
    name: "scorecard >= 7.0",
    description: "Ensures OpenSSF Scorecard passes with score >= 7.0",
    confidence: 0.92,
    tier: Substitute,
    hasFixScript: false,
    languages: ["*"],
    timesTriggered: 52,
    lastTriggered: "2026-03-13",
  },
  {
    id: "hyp-024",
    name: "TruffleHog scan",
    description: "Runs TruffleHog for leaked credentials in history",
    confidence: 0.95,
    tier: Eliminate,
    hasFixScript: false,
    languages: ["*"],
    timesTriggered: 3,
    lastTriggered: "2026-02-28",
  },
  {
    id: "hyp-025",
    name: "Guix/Nix policy",
    description: "Enforces Guix/Nix packaging policy",
    confidence: 0.90,
    tier: Control,
    hasFixScript: false,
    languages: ["Nix", "Guile"],
    timesTriggered: 0,
    lastTriggered: "never",
  },
  {
    id: "hyp-026",
    name: "workflow linter",
    description: "Validates GitHub Actions workflow syntax and best practices",
    confidence: 0.97,
    tier: Control,
    hasFixScript: true,
    languages: ["YAML"],
    timesTriggered: 67,
    lastTriggered: "2026-03-14",
  },
  {
    id: "hyp-027",
    name: "RSR antipattern",
    description: "Detects Rhodium Standard Repository antipatterns",
    confidence: 0.94,
    tier: Substitute,
    hasFixScript: true,
    languages: ["*"],
    timesTriggered: 31,
    lastTriggered: "2026-03-12",
  },
  {
    id: "hyp-028",
    name: "SECURITY.md check",
    description: "Validates SECURITY.md present with proper disclosure policy",
    confidence: 0.98,
    tier: Control,
    hasFixScript: true,
    languages: ["Markdown"],
    timesTriggered: 15,
    lastTriggered: "2026-02-22",
  },
  {
    id: "hyp-029",
    name: ".well-known check",
    description: "Validates .well-known/ directory contents",
    confidence: 0.91,
    tier: Control,
    hasFixScript: true,
    languages: ["*"],
    timesTriggered: 8,
    lastTriggered: "2026-02-14",
  },
  {
    id: "hyp-030",
    name: "author attribution",
    description: "Validates author name/email in package manifests",
    confidence: 0.97,
    tier: Control,
    hasFixScript: true,
    languages: ["TOML", "JSON"],
    timesTriggered: 42,
    lastTriggered: "2026-03-10",
  },
  {
    id: "hyp-031",
    name: "duplicate workflow",
    description: "Detects duplicate GitHub Actions workflows",
    confidence: 0.96,
    tier: Substitute,
    hasFixScript: true,
    languages: ["YAML"],
    timesTriggered: 5,
    lastTriggered: "2026-02-22",
  },
  {
    id: "hyp-032",
    name: "transmute ban",
    description: "Bans std::mem::transmute in Rust except FFI boundaries",
    confidence: 0.98,
    tier: Eliminate,
    hasFixScript: false,
    languages: ["Rust"],
    timesTriggered: 0,
    lastTriggered: "never",
  },
  {
    id: "hyp-033",
    name: "nested .git detector",
    description: "Detects rogue .git directories inside monorepo subdirectories",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["*"],
    timesTriggered: 117,
    lastTriggered: "2026-02-20",
  },
  {
    id: "hyp-034",
    name: "SLSA provenance",
    description: "Validates SLSA build provenance attestation",
    confidence: 0.90,
    tier: Substitute,
    hasFixScript: false,
    languages: ["*"],
    timesTriggered: 2,
    lastTriggered: "2026-03-01",
  },
  {
    id: "hyp-035",
    name: "innerHTML ban (SafeDOM)",
    description: "Flags innerHTML/outerHTML usage outside SafeDOMCore — all DOM mounts must use SafeDOM defence-in-depth",
    confidence: 0.99,
    tier: Eliminate,
    hasFixScript: true,
    languages: ["ReScript", "JavaScript"],
    timesTriggered: 0,
    lastTriggered: "never",
  },
]

/// Filter recipes by text search.
let filterRecipes = (recipes: array<recipeEntry>, query: string): array<recipeEntry> => {
  if query === "" {
    recipes
  } else {
    let q = String.toLowerCase(query)
    recipes->Array.filter(r =>
      String.includes(String.toLowerCase(r.name), q) ||
      String.includes(String.toLowerCase(r.description), q) ||
      r.languages->Array.some(l => String.includes(String.toLowerCase(l), q))
    )
  }
}

/// Find a recipe by id.
let findRecipe = (recipes: array<recipeEntry>, id: string): option<recipeEntry> =>
  recipes->Array.find(r => r.id === id)

/// Default initial state.
let defaultState: hypatiaState = {
  loaded: false,
  loading: false,
  error: None,
  networks: [],
  scans: [],
  learningCycle: None,
  activeCategory: HypatiaDashboard,
  filterText: "",
  totalRepos: 0,
  quarantinedCount: 0,
  triangleCounts: None,
  recipes: None,
  recipeEntries: sampleRecipes(),
  selectedRecipe: None,
  recipeFilter: "",
  outcomes: None,
}
