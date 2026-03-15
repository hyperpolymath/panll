# K9 Kennel: Team Dashboard Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "team-dashboard-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Team Dashboard",
    short_name = "Team",
    description = "Team presence, activity feed, progress tracking, and schedule",
    has_backend = false,
    clade_id = "team-dashboard",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "teamDashboard",
    msg_namespace = "teamDashboardMsg",
    view_route = "PanelTeam Dashboard",
    module_name = "Team Dashboard",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
