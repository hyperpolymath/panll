# K9 Kennel: Reposystem Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "reposystem-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Reposystem",
    short_name = "RSR",
    description = "RSR compliance and template management",
    has_backend = false,
    clade_id = "reposystem",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "reposystem",
    msg_namespace = "reposystemMsg",
    view_route = "PanelReposystem",
    module_name = "Reposystem",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
