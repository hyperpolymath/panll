K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Debugging Workbench Panel Configuration
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
      name = "debugging-workbench-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Debugging Workbench",
    short_name = "Debug",
    description = "Time-travel debugging, state tree inspection, watch expressions, and console",
    has_backend = false,
    clade_id = "debugging-workbench",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "debuggingWorkbench",
    msg_namespace = "debuggingWorkbenchMsg",
    view_route = "PanelDebugging Workbench",
    module_name = "Debugging Workbench",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
