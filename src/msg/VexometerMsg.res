// SPDX-License-Identifier: PMPL-1.0-or-later

/// Vexometer messages -- cognitive load tracking and anti-inflammatory controls.

type vexometerMsg =
  | RecordCancellation
  | RecordCorrection
  /// Record a VQL query execution for cognitive load tracking.
  | RecordVqlQuery
  | RequestVexationIndex
  | UpdateVexationIndex(float)
  | ToggleAntiInflammatory(bool)
  | SetInertiaDetected(bool)
  | ResetVexometer
