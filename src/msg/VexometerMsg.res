// SPDX-License-Identifier: MPL-2.0

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
