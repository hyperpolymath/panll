K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Architect Mode Panel Configuration
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
      name = "architect-mode-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Architect Mode",
    short_name = "Arch",
    description = "PixiJS fine-grained level editor with L/N/W pane integration",
    has_backend = true,
    clade_id = "architect-mode",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "architectMode",
    msg_namespace = "architectModeMsg",
    view_route = "PanelArchitect Mode",
    module_name = "Architect Mode",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
