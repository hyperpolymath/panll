# K9 Kennel: Minter Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "minter-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Minter",
    short_name = "Mint",
    description = "Panel creation wizard — generate accessible panel modules from templates",
    has_backend = true,
    clade_id = "minter",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "minter",
    msg_namespace = "minterMsg",
    view_route = "PanelMinter",
    module_name = "Minter",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
