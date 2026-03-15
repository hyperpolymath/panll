# K9 Kennel: Automation Router Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "automation-router-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Automation Router",
    short_name = "Auto",
    description = "Hybrid cross-panel workflow orchestration — event-driven rules with approval gates",
    has_backend = true,
    clade_id = "automation-router",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "automationRouter",
    msg_namespace = "automationRouterMsg",
    view_route = "PanelAutomation Router",
    module_name = "Automation Router",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
