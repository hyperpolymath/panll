// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Compatibility Matrix Model — browser/device/resolution test matrix.
/// This module has NO dependencies on other PanLL modules.

/// Target browser.
type browserTarget = {
  name: string,
  version: string,
  engine: string,
}

/// Target device.
type deviceTarget = {
  name: string,
  category: string,
  resolution: (int, int),
  pixelRatio: float,
}

/// Result of a compatibility test.
type compatResult =
  | CompatPassing
  | CompatFailing(string)
  | CompatWarning(string)
  | CompatUntested
  | CompatSkipped(string)

/// A single cell in the compatibility matrix.
type matrixCell = {
  browser: browserTarget,
  device: deviceTarget,
  result: compatResult,
  screenshotPath: option<string>,
  testedAt: option<string>,
  notes: string,
}

/// Active tab.
type compatibilityTab =
  | TabMatrix
  | TabFailures
  | TabScreenshots
  | TabTargets

/// Compatibility matrix state.
type compatibilityMatrixState = {
  activeTab: compatibilityTab,
  browsers: array<browserTarget>,
  devices: array<deviceTarget>,
  cells: array<matrixCell>,
  running: bool,
  selectedBrowser: option<string>,
  selectedDevice: option<string>,
  error: option<string>,
}
