// SPDX-License-Identifier: PMPL-1.0-or-later

/// Vexometer messages -- cognitive load tracking and anti-inflammatory controls.

type vexometerMsg =
  | RecordCancellation
  | RecordCorrection
  /// Record a VCL query execution for cognitive load tracking.
  | RecordVclQuery
  | RequestVexationIndex
  | UpdateVexationIndex(float)
  | ToggleAntiInflammatory(bool)
  | SetInertiaDetected(bool)
  | ResetVexometer
