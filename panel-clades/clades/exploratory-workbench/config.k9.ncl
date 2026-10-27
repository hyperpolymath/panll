K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Exploratory Workbench Panel Configuration
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
      name = "exploratory-workbench-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Exploratory Workbench",
    short_name = "Explore",
    description = "Freeform play session recording and anomaly detection",
    has_backend = true,
    clade_id = "exploratory-workbench",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "exploratoryWorkbench",
    msg_namespace = "exploratoryWorkbenchMsg",
    view_route = "PanelExploratory Workbench",
    module_name = "Exploratory Workbench",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
