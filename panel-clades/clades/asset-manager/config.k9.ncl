K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Asset Manager Panel Configuration
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
      name = "asset-manager-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Asset Manager",
    short_name = "Asset",
    description = "PixiJS sprites, sounds, level templates, and asset pipeline",
    has_backend = true,
    clade_id = "asset-manager",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "assetManager",
    msg_namespace = "assetManagerMsg",
    view_route = "PanelAsset Manager",
    module_name = "Asset Manager",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
