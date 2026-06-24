# K9 Kennel: Farm Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "farm-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Farm",
    short_name = "Farm",
    description = "Repository admin registry and maintenance hub",
    has_backend = false,
    clade_id = "farm",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "farm",
    msg_namespace = "farmMsg",
    view_route = "PanelFarm",
    module_name = "Farm",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
