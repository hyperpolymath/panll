K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Wiring Inspector Panel Configuration
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
      name = "wiring-inspector-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Wiring Inspector",
    short_name = "Wiring",
    description = "Constraint-aware panel wiring verification and bottleneck analysis",
    has_backend = true,
    clade_id = "wiring-inspector",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "wiringInspector",
    msg_namespace = "wiringInspectorMsg",
    view_route = "PanelWiring Inspector",
    module_name = "Wiring Inspector",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
