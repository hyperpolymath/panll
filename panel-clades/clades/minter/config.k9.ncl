K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Minter Panel Configuration
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
      name = "minter-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
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
