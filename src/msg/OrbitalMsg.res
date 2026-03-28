// SPDX-License-Identifier: PMPL-1.0-or-later

/// Orbital stability messages -- stability, divergence, and drift aura.

type orbitalMsg =
  | UpdateStability(float)
  | UpdateDivergence(float)
  | SetDriftAura(string)
