# K9 Kennel: DLC Workshop Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "dlc-workshop-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "DLC Workshop",
    short_name = "DLC",
    description = "Create, test, and package DLC puzzle packs — VM composer, solution testing, asset bundling",
    has_backend = true,
    clade_id = "dlc-workshop",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "dlcWorkshop",
    msg_namespace = "dlcWorkshopMsg",
    view_route = "PanelDLC Workshop",
    module_name = "DLC Workshop",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
