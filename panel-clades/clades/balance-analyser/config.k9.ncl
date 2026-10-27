K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Balance Analyser Panel Configuration
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
      name = "balance-analyser-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Balance Analyser",
    short_name = "Bal",
    description = "Game balance stats, Monte Carlo simulation, difficulty curves",
    has_backend = true,
    clade_id = "balance-analyser",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "balanceAnalyser",
    msg_namespace = "balanceAnalyserMsg",
    view_route = "PanelBalance Analyser",
    module_name = "Balance Analyser",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
