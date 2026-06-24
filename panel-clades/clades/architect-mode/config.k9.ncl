# K9 Kennel: Architect Mode Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "architect-mode-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
