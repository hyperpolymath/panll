# K9 Kennel: Asset Manager Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "asset-manager-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
