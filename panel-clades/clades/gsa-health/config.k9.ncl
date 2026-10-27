K9!
# SPDX-License-Identifier: MPL-2.0
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
      name = "gsa-health-config",
      version = "1.0.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "GsaHealthDashboard",
    short_name = "Health",
    description = "Server health and config drift detection dashboard",
    has_backend = true,
    clade_id = "gsa-health",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaHealth",
    msg_namespace = "gsaHealthMsg",
    view_route = "PanelGsaHealthDashboard",
    module_name = "GsaHealth",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
