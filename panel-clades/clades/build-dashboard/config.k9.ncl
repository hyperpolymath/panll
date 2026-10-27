K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Build Dashboard Panel Configuration
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
      name = "build-dashboard-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Build Dashboard",
    short_name = "Bld",
    description = "Monitor builds, tests, errors, and compilation status across IDApTIK sub-projects",
    has_backend = true,
    clade_id = "build-dashboard",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "buildDashboard",
    msg_namespace = "buildDashboardMsg",
    view_route = "PanelBuild Dashboard",
    module_name = "Build Dashboard",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
