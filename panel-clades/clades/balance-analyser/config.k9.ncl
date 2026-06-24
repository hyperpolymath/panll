# K9 Kennel: Balance Analyser Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "balance-analyser-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
