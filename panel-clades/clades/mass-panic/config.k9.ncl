# K9 Kennel: Mass Panic Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "mass-panic-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Mass Panic",
    short_name = "MP",
    description = "Organisation-scale batch scanning — assemblyline + BLAKE3 + verisim + delta",
    has_backend = true,
    clade_id = "mass-panic",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "massPanic",
    msg_namespace = "massPanicMsg",
    view_route = "PanelMass Panic",
    module_name = "Mass Panic",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
