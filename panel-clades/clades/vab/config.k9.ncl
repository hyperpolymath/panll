K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: VAB Panel Configuration
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
      name = "vab-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "VAB",
    short_name = "VAB",
    description = "Verified Assembly Building — server component composer",
    has_backend = false,
    clade_id = "vab",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "vab",
    msg_namespace = "vabMsg",
    view_route = "PanelVAB",
    module_name = "VAB",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
