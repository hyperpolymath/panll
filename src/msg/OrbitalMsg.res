// SPDX-License-Identifier: MPL-2.0

/// Orbital stability messages -- stability, divergence, and drift aura.

type orbitalMsg =
  | UpdateStability(float)
  | UpdateDivergence(float)
  | SetDriftAura(string)
