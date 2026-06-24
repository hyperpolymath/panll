# K9 Kennel: Merge Coordinator Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "merge-coordinator-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
