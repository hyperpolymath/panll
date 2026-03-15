// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Compatibility Matrix Engine — pure functions for test matrix state.

open CompatibilityMatrixModel

let defaultState: compatibilityMatrixState = {
  activeTab: TabMatrix,
  browsers: [
    { name: "Chrome", version: "latest", engine: "Blink" },
    { name: "Firefox", version: "latest", engine: "Gecko" },
    { name: "Safari", version: "latest", engine: "WebKit" },
  ],
  devices: [
    { name: "Desktop 1080p", category: "desktop", resolution: (1920, 1080), pixelRatio: 1.0 },
    { name: "Desktop 1440p", category: "desktop", resolution: (2560, 1440), pixelRatio: 1.0 },
    { name: "Mobile 375", category: "mobile", resolution: (375, 812), pixelRatio: 3.0 },
    { name: "Tablet 768", category: "tablet", resolution: (768, 1024), pixelRatio: 2.0 },
  ],
  cells: [],
  running: false,
  selectedBrowser: None,
  selectedDevice: None,
  error: None,
}

let tabLabel = (tab: compatibilityTab): string =>
  switch tab {
  | TabMatrix => "Matrix"
  | TabFailures => "Failures"
  | TabScreenshots => "Screenshots"
  | TabTargets => "Targets"
  }

let allTabs: array<compatibilityTab> = [TabMatrix, TabFailures, TabScreenshots, TabTargets]

/// Count cells by result type.
let countPassing = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => c.result == CompatPassing)->Array.length

let countFailing = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => switch c.result { | CompatFailing(_) => true | _ => false })->Array.length

let countUntested = (cells: array<matrixCell>): int =>
  cells->Array.filter(c => c.result == CompatUntested)->Array.length

/// Result label for display.
let resultLabel = (result: compatResult): string =>
  switch result {
  | CompatPassing => "Pass"
  | CompatFailing(reason) => "Fail: " ++ reason
  | CompatWarning(msg) => "Warn: " ++ msg
  | CompatUntested => "Untested"
  | CompatSkipped(reason) => "Skipped: " ++ reason
  }

/// Resolution as display string.
let resolutionLabel = (device: deviceTarget): string => {
  let (w, h) = device.resolution
  Int.toString(w) ++ "x" ++ Int.toString(h)
}
