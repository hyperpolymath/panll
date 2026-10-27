K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Coprocessors Panel Configuration
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
      name = "coprocessors-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Coprocessors",
    short_name = "CoPr",
    description = "Monitor IDApTIK's 10 coprocessor backends — call log, heatmap, performance, health",
    has_backend = true,
    clade_id = "coprocessors",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "coprocessors",
    msg_namespace = "coprocessorsMsg",
    view_route = "PanelCoprocessors",
    module_name = "Coprocessors",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
