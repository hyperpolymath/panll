K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: VeriSimDB Feeds Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "panel-clade-config",
    security = {
      leash = 'Kennel,
      trust_level = "data-only",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
      capabilities = [],
    },
    metadata = {
      name = "verisim-feeds-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "VerisimdbFeeds",
    short_name = "VF",
    description = "VeriSimDB data feeds — cross-repo analytics health and flow",
    has_backend = true,
    clade_id = "verisim-feeds",
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
