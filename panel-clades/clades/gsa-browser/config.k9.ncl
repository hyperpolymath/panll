# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "gsa-browser-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "GsaServerBrowser",
    short_name = "Servers",
    description = "Discover and fingerprint game servers",
    has_backend = true,
    clade_id = "gsa-browser",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaBrowser",
    msg_namespace = "gsaBrowserMsg",
    view_route = "PanelGsaServerBrowser",
    module_name = "GsaBrowser",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
