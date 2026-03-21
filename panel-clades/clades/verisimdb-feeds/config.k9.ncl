# K9 Kennel: VeriSimDB Feeds Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "verisimdb-feeds-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "VerisimdbFeeds",
    short_name = "VF",
    description = "VeriSimDB data feeds — cross-repo analytics health and flow",
    has_backend = true,
    clade_id = "verisimdb-feeds",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "verisimdbFeeds",
    msg_namespace = "verisimdbFeedsMsg",
    view_route = "PanelVerisimdbFeeds",
    module_name = "VerisimdbFeeds",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
