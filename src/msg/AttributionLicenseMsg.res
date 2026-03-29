// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — Attribution-to-Licensing Messages (Layer 4)

open AttributionLicenseModel

/// Messages for the attribution-to-licensing panel.
type attributionLicenseMsg =
  /// Start a full licensing scan of the codebase.
  | StartLicenseScan
  /// Scan completed with file summaries.
  | ScanComplete(array<fileLicenseSummary>)
  /// Mark an issue as resolved.
  | ResolveIssue(string)
  /// Toggle the expanded state of the panel.
  | ToggleLicensePanel
  /// Change the minimum severity filter.
  | SetMinLicenseSeverity(licenseSeverity)
  /// Toggle showing resolved issues.
  | ToggleShowResolved
  /// Scan failed with error message.
  | ScanFailed(string)
