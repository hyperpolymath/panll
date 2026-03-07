// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Hypatia Engine — pure computation for the Hypatia panel.
///
/// Parses Elixir API responses, computes aggregate metrics, filters
/// and sorts scan results, and provides display helpers.

open HypatiaModel

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

/// Parse neural network states from API JSON.
let parseNetworks = (json: string): result<array<neuralNetState>, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(items) =>
      let nets = items->Array.filterMap(item => {
        switch JSON.Classify.classify(item) {
        | Object(obj) => {
            let getString = (key: string): string =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | String(s) => s
                | _ => ""
                }
              | None => ""
              }
            let getFloat = (key: string): float =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => n
                | _ => 0.0
                }
              | None => 0.0
              }
            let getInt = (key: string): int =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => Float.toInt(n)
                | _ => 0
                }
              | None => 0
              }

            let idStr = getString("id")
            let id = switch idStr {
            | "graph_of_trust" => Some(GraphOfTrust)
            | "mixture_of_experts" => Some(MixtureOfExperts)
            | "liquid_state_machine" => Some(LiquidStateMachine)
            | "echo_state_network" => Some(EchoStateNetwork)
            | "radial_neural_network" => Some(RadialNeuralNetwork)
            | _ => None
            }

            let statusStr = getString("status")
            let status = switch statusStr {
            | "active" => NetActive
            | "training" => NetTraining
            | "offline" => NetOffline
            | _ => NetError(statusStr)
            }

            switch id {
            | Some(netId) =>
              Some({
                id: netId,
                status,
                confidence: getFloat("confidence"),
                inferenceCount: getInt("inference_count"),
                version: getString("version"),
              })
            | None => None
            }
          }
        | _ => None
        }
      })
      Ok(nets)
    | _ => Error("Expected array of network states")
    }
  } catch {
  | _ => Error("Failed to parse networks JSON")
  }
}

/// Parse scan results from API JSON.
let parseScans = (json: string): result<array<scanResult>, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(items) =>
      let scans = items->Array.filterMap(item => {
        switch JSON.Classify.classify(item) {
        | Object(obj) => {
            let getString = (key: string): string =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | String(s) => s
                | _ => ""
                }
              | None => ""
              }
            let getFloat = (key: string): float =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => n
                | _ => 0.0
                }
              | None => 0.0
              }
            let getInt = (key: string): int =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => Float.toInt(n)
                | _ => 0
                }
              | None => 0
              }
            let getBool = (key: string): bool =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Bool(b) => b
                | _ => false
                }
              | None => false
              }

            Some({
              repoName: getString("repo_name"),
              riskScore: getFloat("risk_score"),
              findingCount: getInt("finding_count"),
              quarantineCount: getInt("quarantine_count"),
              lastScanned: getString("last_scanned"),
              passed: getBool("passed"),
            })
          }
        | _ => None
        }
      })
      Ok(scans)
    | _ => Error("Expected array of scan results")
    }
  } catch {
  | _ => Error("Failed to parse scans JSON")
  }
}

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
}
