K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Clade Browser Panel Configuration
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
      name = "clade-browser-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Clade Browser",
    short_name = "Clade",
    description = "Explore and customise panel clades — taxonomy, traits, kind filtering, panel-to-clade mapping",
    has_backend = false,
    clade_id = "clade-browser",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "cladeBrowser",
    msg_namespace = "cladeBrowserMsg",
    view_route = "PanelClade Browser",
    module_name = "Clade Browser",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
