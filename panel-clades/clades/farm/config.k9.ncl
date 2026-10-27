K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Farm Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "panel-clade-config",
    security = {
      leash = 'Kennel,
      trust_level = "data-only",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
      capabilities = [],
    },
    metadata = {
      name = "farm-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
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
