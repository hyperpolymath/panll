// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Aerie Engine — pure computation for network diagnostics.

open AerieModel

let categoryLabel = (cat: aerieCategory): string =>
  switch cat {
  | AerieDashboard => "Dashboard"
  | AerieSpeedTests => "Speed Tests"
  | AerieBgp => "BGP Analysis"
  | AerieProbes => "Probes"
  }

/// Classify latency quality.
let latencyQuality = (rttMs: float): string =>
  if rttMs < 20.0 { "Excellent" }
  else if rttMs < 50.0 { "Good" }
  else if rttMs < 100.0 { "Fair" }
  else { "Poor" }

/// CSS color for latency quality.
let latencyColor = (rttMs: float): string =>
  if rttMs < 20.0 { "text-green-400" }
  else if rttMs < 50.0 { "text-emerald-400" }
  else if rttMs < 100.0 { "text-amber-400" }
  else { "text-red-400" }

/// Average latency across all results.
let avgLatency = (results: array<latencyResult>): float => {
  if Array.length(results) > 0 {
    results->Array.map(r => r.rttMs)->Array.reduce(0.0, (a, b) => a +. b) /.
      Int.toFloat(Array.length(results))
  } else {
    0.0
  }
}

let defaultState: aerieState = {
  loaded: false,
  loading: false,
  error: None,
  probes: [],
  latencyResults: [],
  speedTests: [],
  bgpRoutes: [],
  activeCategory: AerieDashboard,
  bgpAnomalyCount: 0,
  bojRouting: false,
}
