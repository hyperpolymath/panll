K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Merge Coordinator Panel Configuration
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
      name = "merge-coordinator-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Merge Coordinator",
    short_name = "Merge",
    description = "Branch management, conflict resolution, merge queue, and history",
    has_backend = true,
    clade_id = "merge-coordinator",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "mergeCoordinator",
    msg_namespace = "mergeCoordinatorMsg",
    view_route = "PanelMerge Coordinator",
    module_name = "Merge Coordinator",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
