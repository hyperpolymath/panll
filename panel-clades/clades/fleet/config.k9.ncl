# K9 Kennel: Fleet Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "fleet-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Fleet",
    short_name = "Fleet",
    description = "Gitbot fleet orchestration and dispatch",
    has_backend = true,
    clade_id = "fleet",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "fleet",
    msg_namespace = "fleetMsg",
    view_route = "PanelFleet",
    module_name = "Fleet",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
