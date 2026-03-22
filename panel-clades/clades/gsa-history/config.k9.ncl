# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "gsa-history-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "GsaConfigHistory",
    short_name = "History",
    description = "Config version timeline with provenance chain",
    has_backend = true,
    clade_id = "gsa-history",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaHistory",
    msg_namespace = "gsaHistoryMsg",
    view_route = "PanelGsaConfigHistory",
    module_name = "GsaHistory",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
