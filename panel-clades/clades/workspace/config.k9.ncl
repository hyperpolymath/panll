# K9 Kennel: Workspace Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "workspace-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Workspace",
    short_name = "WS",
    description = "Panel arrangements, groups, sessions, modes, and configurator",
    has_backend = true,
    clade_id = "workspace",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "workspace",
    msg_namespace = "workspaceMsg",
    view_route = "PanelWorkspace",
    module_name = "Workspace",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
