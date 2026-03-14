// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Aerie Engine — pure computation for network diagnostics.

open AerieModel

/// Human-readable label for an Aerie category tab.
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

/// Average jitter across all results.
let avgJitter = (results: array<latencyResult>): float => {
  if Array.length(results) > 0 {
    results->Array.map(r => r.jitterMs)->Array.reduce(0.0, (a, b) => a +. b) /.
      Int.toFloat(Array.length(results))
  } else {
    0.0
  }
}

/// Average packet loss across all results.
let avgPacketLoss = (results: array<latencyResult>): float => {
  if Array.length(results) > 0 {
    results->Array.map(r => r.packetLoss)->Array.reduce(0.0, (a, b) => a +. b) /.
      Int.toFloat(Array.length(results))
  } else {
    0.0
  }
}

/// Classify jitter quality.
let jitterQuality = (jitterMs: float): string =>
  if jitterMs < 5.0 { "Excellent" }
  else if jitterMs < 20.0 { "Good" }
  else if jitterMs < 50.0 { "Fair" }
  else { "Poor" }

/// MTU mismatch severity label.
let mtuStatus = (result: option<mtuResult>): string =>
  switch result {
  | None => "Not tested"
  | Some(r) =>
    if r.mismatch {
      "Mismatch: " ++ Int.toString(r.interfaceMtu) ++ " > " ++ Int.toString(r.pathMtu)
    } else {
      "OK: " ++ Int.toString(r.pathMtu) ++ " bytes"
    }
  }

/// CSS color for MTU status.
let mtuColor = (result: option<mtuResult>): string =>
  switch result {
  | None => "text-gray-500"
  | Some(r) => if r.mismatch { "text-red-400" } else { "text-green-400" }
  }

/// Count interfaces that are up.
let interfacesUp = (ifaces: array<interfaceSummary>): int =>
  ifaces->Array.filter(i => i.isUp)->Array.length

/// Extended latency quality (adds "Very poor" for mobile/satellite).
let latencyQualityExtended = (rttMs: float): string =>
  if rttMs < 20.0 { "Excellent" }
  else if rttMs < 50.0 { "Good" }
  else if rttMs < 100.0 { "Fair" }
  else if rttMs < 300.0 { "Poor" }
  else { "Very poor" }

/// Default Aerie panel state — disconnected, no data loaded.
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
  mtuResult: None,
  interfaces: [],
  bojRouting: false,
}
