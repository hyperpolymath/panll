# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 kennel configuration for GSA root panel clade
{
  pedigree = {
    name = "gsa-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Gsa",
    short_name = "GSA",
    description = "Universal game server probe, config management, and administration",
    has_backend = true,
    clade_id = "gsa",
    isolation_tier = "process",
  },
  wiring = {
    model_slice = "gsa",
    msg_namespace = "gsaMsg",
    view_route = "PanelGsa",
    module_name = "Gsa",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
