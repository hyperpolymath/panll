# K9 Kennel: Soak Monitor Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "soak-monitor-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Soak Monitor",
    short_name = "Soak",
    description = "Long-running session memory trend analysis and leak detection",
    has_backend = true,
    clade_id = "soak-monitor",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "soakMonitor",
    msg_namespace = "soakMonitorMsg",
    view_route = "PanelSoak Monitor",
    module_name = "Soak Monitor",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
