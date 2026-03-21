// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Compatibility Matrix Engine — pure computation and helpers for the
/// Compatibility Matrix panel. Provides default state, cell counting,
/// result formatting, resolution display, and matrix summary computation.

open CompatibilityMatrixModel

/// Default state for the Compatibility Matrix panel.
/// Pre-loaded with standard browser and device targets.
let defaultState: compatibilityMatrixState = {
  activeTab: TabMatrix,
  browsers: [
    {name: "Chrome", version: "latest", engine: "Blink"},
    {name: "Firefox", version: "latest", engine: "Gecko"},
    {name: "Safari", version: "latest", engine: "WebKit"},
  ],
  devices: [
    {name: "Desktop 1080p", category: "desktop", resolution: (1920, 1080), pixelRatio: 1.0},
    {name: "Desktop 1440p", category: "desktop", resolution: (2560, 1440), pixelRatio: 1.0},
    {name: "Mobile 375", category: "mobile", resolution: (375, 812), pixelRatio: 3.0},
    {name: "Tablet 768", category: "tablet", resolution: (768, 1024), pixelRatio: 2.0},
  ],
  cells: [],
  running: false,
  selectedBrowser: None,
  selectedDevice: None,
  error: None,
}

/// Human-readable label for each tab in the Compatibility Matrix panel.
let tabLabel = (tab: compatibilityTab): string =>
  switch tab {
  | TabMatrix => "Matrix"
  | TabFailures => "Failures"
  | TabScreenshots => "Screenshots"
  | TabTargets => "Targets"
  }

/// All tabs in display order.
let allTabs: array<compatibilityTab> = [TabMatrix, TabFailures, TabScreenshots, TabTargets]

/// Count passing cells in the matrix.
let countPassing = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => c.result == CompatPassing)->Array.length

/// Count failing cells in the matrix.
let countFailing = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => switch c.result {
  | CompatFailing(_) => true
  | _ => false
  })->Array.length

/// Count warning cells.
let countWarnings = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => switch c.result {
  | CompatWarning(_) => true
  | _ => false
  })->Array.length

/// Count untested cells in the matrix.
let countUntested = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => c.result == CompatUntested)->Array.length

/// Count skipped cells.
let countSkipped = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => switch c.result {
  | CompatSkipped(_) => true
  | _ => false
  })->Array.length

/// Human-readable result label for display.
let resultLabel = (result: compatResult): string =>
  switch result {
  | CompatPassing => "Pass"
  | CompatFailing(reason) => "Fail: " ++ reason
  | CompatWarning(msg) => "Warn: " ++ msg
  | CompatUntested => "Untested"
  | CompatSkipped(reason) => "Skipped: " ++ reason
  }

/// CSS colour class for a compatibility result.
let resultColor = (result: compatResult): string =>
  switch result {
  | CompatPassing => "text-green-400"
  | CompatFailing(_) => "text-red-400"
  | CompatWarning(_) => "text-yellow-400"
  | CompatUntested => "text-gray-500"
  | CompatSkipped(_) => "text-gray-400"
  }

/// CSS background colour class for matrix cell colouring.
let cellBgColor = (result: compatResult): string =>
  switch result {
  | CompatPassing => "bg-green-900/30"
  | CompatFailing(_) => "bg-red-900/30"
  | CompatWarning(_) => "bg-yellow-900/30"
  | CompatUntested => "bg-gray-900/30"
  | CompatSkipped(_) => "bg-gray-800/30"
  }

/// Device resolution as display string (e.g., "1920x1080").
let resolutionLabel = (device: deviceTarget): string => {
  let (w, h) = device.resolution
  Int.toString(w) ++ "x" ++ Int.toString(h)
}

/// Compute a matrix summary from the current cell data.
let computeSummary = (cells: array<matrixCell>): matrixSummary => {
  let total = Array.length(cells)
  let passing = countPassing(cells)
  let failing = countFailing(cells)
  let warnings = countWarnings(cells)
  let untested = countUntested(cells)
  let skipped = countSkipped(cells)
  let tested = total - untested - skipped
  {
    totalCells: total,
    passing,
    failing,
    warnings,
    untested,
    skipped,
    passRate: if tested == 0 { 0.0 } else { Float.fromInt(passing) /. Float.fromInt(tested) *. 100.0 },
  }
}

/// Filter cells to only show failures.
let failingCells = (cells: array<matrixCell>): array<matrixCell> =>
  cells->Array.filter(c => switch c.result {
  | CompatFailing(_) => true
  | _ => false
  })
