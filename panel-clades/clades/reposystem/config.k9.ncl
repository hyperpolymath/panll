K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Reposystem Panel Configuration
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
      name = "reposystem-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Reposystem",
    short_name = "RSR",
    description = "RSR compliance and template management",
    has_backend = false,
    clade_id = "reposystem",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "reposystem",
    msg_namespace = "reposystemMsg",
    view_route = "PanelReposystem",
    module_name = "Reposystem",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
