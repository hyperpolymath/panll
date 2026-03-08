// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Coprocessors Engine — pure computation and helpers for the
/// IDApTIK coprocessor monitoring dashboard.

open CoprocessorsModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: coprocessorsCategory): string =>
  switch cat {
  | CoprocDashboard => "Dashboard"
  | CoprocCallLog => "Call Log"
  | CoprocHeatmap => "Heatmap"
  | CoprocSettings => "Settings"
  }

/// Human-readable labels for coprocessor backends.
let backendLabel = (backend: coprocessorBackend): string =>
  switch backend {
  | CoprocMaths => "Maths"
  | CoprocVector => "Vector"
  | CoprocTensor => "Tensor"
  | CoprocPhysics => "Physics"
  | CoprocCrypto => "Crypto"
  | CoprocNeural => "Neural"
  | CoprocQuantum => "Quantum"
  | CoprocAudio => "Audio"
  | CoprocGraphics => "Graphics"
  | CoprocIO => "I/O"
  }

/// Short labels for compact display.
let backendShortLabel = (backend: coprocessorBackend): string =>
  switch backend {
  | CoprocMaths => "MAT"
  | CoprocVector => "VEC"
  | CoprocTensor => "TEN"
  | CoprocPhysics => "PHY"
  | CoprocCrypto => "CRY"
  | CoprocNeural => "NEU"
  | CoprocQuantum => "QUA"
  | CoprocAudio => "AUD"
  | CoprocGraphics => "GFX"
  | CoprocIO => "I/O"
  }

/// Tailwind colour class for each backend.
let backendColour = (backend: coprocessorBackend): string =>
  switch backend {
  | CoprocMaths => "text-blue-400"
  | CoprocVector => "text-cyan-400"
  | CoprocTensor => "text-indigo-400"
  | CoprocPhysics => "text-amber-400"
  | CoprocCrypto => "text-red-400"
  | CoprocNeural => "text-emerald-400"
  | CoprocQuantum => "text-purple-400"
  | CoprocAudio => "text-pink-400"
  | CoprocGraphics => "text-orange-400"
  | CoprocIO => "text-gray-400"
  }

/// Health status label.
let healthLabel = (health: coprocHealth): string =>
  switch health {
  | CoprocHealthy => "Healthy"
  | CoprocDegraded => "Degraded"
  | CoprocFailed => "Failed"
  | CoprocDisabled => "Disabled"
  }

/// Health status colour.
let healthColour = (health: coprocHealth): string =>
  switch health {
  | CoprocHealthy => "text-emerald-400"
  | CoprocDegraded => "text-amber-400"
  | CoprocFailed => "text-red-400"
  | CoprocDisabled => "text-gray-500"
  }

/// All coprocessor backends.
let allBackends: array<coprocessorBackend> = [
  CoprocMaths,
  CoprocVector,
  CoprocTensor,
  CoprocPhysics,
  CoprocCrypto,
  CoprocNeural,
  CoprocQuantum,
  CoprocAudio,
  CoprocGraphics,
  CoprocIO,
]

/// Filter call log by backend.
let filterByBackend = (log: array<coprocCallEntry>, backend: coprocessorBackend): array<coprocCallEntry> =>
  log->Array.filter(entry => entry.backend === backend)

/// Human-readable label for a compute engine.
let engineLabel = (engine: computeEngine): string =>
  switch engine {
  | EngineAxiom => "Axiom.jl"
  | EngineBoJ => "BoJ Cartridge"
  | EngineLocal => "Local CPU/WASM"
  }

/// Parse a compute engine query result from JSON.
let parseComputeResult = (json: string, engine: computeEngine): result<computeQueryResult, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
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
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        Ok({
          engineId: engine,
          operation: getString("operation"),
          result: getString("result"),
          durationMs: getFloat("duration_ms"),
          success: getBool("success"),
        })
      }
    | _ => Error("Expected JSON object for compute result")
    }
  } catch {
  | _ => Error("Failed to parse compute result JSON")
  }
}

/// Parse discovered devices from JSON array.
let parseDevices = (json: string): array<computeDevice> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(items) =>
      items->Array.filterMap(item => {
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
            let getBool = (key: string): bool =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Bool(b) => b
                | _ => false
                }
              | None => false
              }
            let engineStr = getString("engine")
            let engineId = switch engineStr {
            | "axiom" => EngineAxiom
            | "boj" => EngineBoJ
            | _ => EngineLocal
            }
            Some({
              engineId,
              deviceName: getString("device_name"),
              deviceType: getString("device_type"),
              available: getBool("available"),
              capabilities: [],
            })
          }
        | _ => None
        }
      })
    | _ => []
    }
  } catch {
  | _ => []
  }
}

/// Default state for the Coprocessors panel.
let defaultState: coprocessorsState = {
  activeCategory: CoprocDashboard,
  metrics: [],
  callLog: [],
  heatmap: [],
  enabledBackends: allBackends,
  selectedBackend: None,
  filterText: "",
  autoRefresh: true,
  refreshIntervalMs: 2000,
  loading: false,
  error: None,
  discoveredDevices: [],
  lastComputeResult: None,
}
