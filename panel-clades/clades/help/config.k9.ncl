K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Help Panel Configuration
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
      name = "help-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Help",
    short_name = "Help",
    description = "In-application help — searchable guides, neurosymbolic glossary, keyboard shortcuts, onboarding walkthrough",
    has_backend = false,
    clade_id = "help",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "help",
    msg_namespace = "helpMsg",
    view_route = "PanelHelp",
    module_name = "Help",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
