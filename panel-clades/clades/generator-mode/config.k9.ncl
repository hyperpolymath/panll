K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Generator Mode Panel Configuration
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
      name = "generator-mode-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Generator Mode",
    short_name = "Gen",
    description = "Parametric procedural world builder with constraint-based generation",
    has_backend = true,
    clade_id = "generator-mode",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "generatorMode",
    msg_namespace = "generatorModeMsg",
    view_route = "PanelGenerator Mode",
    module_name = "Generator Mode",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
