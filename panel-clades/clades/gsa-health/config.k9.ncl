# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "gsa-health-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
