# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "gsa-actions-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "GsaServerActions",
    short_name = "Actions",
    description = "Start/stop/restart game servers with confirmation",
    has_backend = true,
    clade_id = "gsa-actions",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaActions",
    msg_namespace = "gsaActionsMsg",
    view_route = "PanelGsaServerActions",
    module_name = "GsaActions",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
