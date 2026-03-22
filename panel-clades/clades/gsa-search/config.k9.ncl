# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "gsa-search-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "GsaCrossSearch",
    short_name = "Search",
    description = "VQL-powered cross-server config search",
    has_backend = true,
    clade_id = "gsa-search",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaSearch",
    msg_namespace = "gsaSearchMsg",
    view_route = "PanelGsaCrossSearch",
    module_name = "GsaSearch",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
