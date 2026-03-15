# K9 Kennel: Observatory Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "observatory-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Observatory",
    short_name = "Obs",
    description = "Integrative dashboard — cross-panel health, service status, resource usage, ambient metrics",
    has_backend = true,
    clade_id = "observatory",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "observatory",
    msg_namespace = "observatoryMsg",
    view_route = "PanelObservatory",
    module_name = "Observatory",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
