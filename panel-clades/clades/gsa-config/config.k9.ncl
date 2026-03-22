# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "gsa-config-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "GsaConfigEditor",
    short_name = "Config",
    description = "A2ML-aware game server configuration editor",
    has_backend = true,
    clade_id = "gsa-config",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaConfig",
    msg_namespace = "gsaConfigMsg",
    view_route = "PanelGsaConfigEditor",
    module_name = "GsaConfig",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
