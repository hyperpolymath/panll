// SPDX-License-Identifier: MPL-2.0

/// PanLL Compatibility Matrix Model — browser/device/resolution cross-testing
/// matrix with pass/fail/untested cell colouring and failure detail drill-down.
///
/// Defines target browsers and devices, then runs automated tests via Playwright
/// to populate a green/red/grey matrix showing which environment combinations
/// pass IDApTIK's rendering and interaction requirements.
///
/// Clade: Scanner. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Test Targets
// ============================================================================

/// A target browser to test against.
type browserTarget = {
  /// Browser name (e.g., "Chrome", "Firefox", "Safari").
  name: string,
  /// Browser version string (e.g., "latest", "120").
  version: string,
  /// Rendering engine (e.g., "Blink", "Gecko", "WebKit").
  engine: string,
}

/// A target device/resolution to test against.
type deviceTarget = {
  /// Device name (e.g., "Desktop 1080p", "iPhone 15 Pro").
  name: string,
  /// Device category (e.g., "desktop", "mobile", "tablet").
  category: string,
  /// Screen resolution as (width, height) in logical pixels.
  resolution: (int, int),
  /// Device pixel ratio (e.g., 1.0 for standard, 2.0 for Retina).
  pixelRatio: float,
}

// ============================================================================
// Test Results
// ============================================================================

/// Result of a compatibility test for a single browser+device combination.
type compatResult =
  /// Test passed — game renders and interacts correctly.
  | CompatPassing
  /// Test failed — payload is the failure reason.
  | CompatFailing(string)
  /// Test passed with warnings — payload is the warning message.
  | CompatWarning(string)
  /// Not yet tested.
  | CompatUntested
  /// Deliberately skipped — payload is the skip reason.
  | CompatSkipped(string)

/// A single cell in the compatibility matrix (browser x device).
type matrixCell = {
  /// The browser for this cell.
  browser: browserTarget,
  /// The device for this cell.
  device: deviceTarget,
  /// Test result for this combination.
  result: compatResult,
  /// Path to the captured screenshot (if available).
  screenshotPath: option<string>,
  /// ISO 8601 timestamp of the last test run.
  testedAt: option<string>,
  /// Free-text notes for this cell.
  notes: string,
}

/// Aggregate statistics for the compatibility matrix.
type matrixSummary = {
  /// Total number of cells in the matrix.
  totalCells: int,
  /// Number of passing cells.
  passing: int,
  /// Number of failing cells.
  failing: int,
  /// Number of warning cells.
  warnings: int,
  /// Number of untested cells.
  untested: int,
  /// Number of skipped cells.
  skipped: int,
  /// Overall pass rate as a percentage (0.0 to 100.0).
  passRate: float,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Compatibility Matrix panel.
type compatibilityTab =
  /// Matrix — the full browser x device grid with colour-coded cells.
  | TabMatrix
  /// Failures — filtered list of failing cells with failure details.
  | TabFailures
  /// Screenshots — gallery of captured screenshots for visual comparison.
  | TabScreenshots
  /// Targets — manage browser and device target lists.
  | TabTargets

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Compatibility Matrix panel.
type compatibilityMatrixState = {
  /// Active tab within the panel.
  activeTab: compatibilityTab,
  /// Target browsers to test against.
  browsers: array<browserTarget>,
  /// Target devices to test against.
  devices: array<deviceTarget>,
  /// Matrix cells (one per browser x device combination).
  cells: array<matrixCell>,
  /// Whether a test suite is currently running.
  running: bool,
  /// Currently selected browser for drill-down.
  selectedBrowser: option<string>,
  /// Currently selected device for drill-down.
  selectedDevice: option<string>,
  /// Error from the last operation.
  error: option<string>,
}
