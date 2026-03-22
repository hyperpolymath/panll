# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "gsa-logs-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "GsaLiveLogs",
    short_name = "Logs",
    description = "Real-time game server log streaming",
    has_backend = true,
    clade_id = "gsa-logs",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaLogs",
    msg_namespace = "gsaLogsMsg",
    view_route = "PanelGsaLiveLogs",
    module_name = "GsaLogs",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
