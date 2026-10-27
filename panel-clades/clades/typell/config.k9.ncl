K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: TypeLL Panel Configuration
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
      name = "typell-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "TypeLL",
    short_name = "TypeLL",
    description = "Verification kernel — dependent, linear, affine, session, and refinement types with progressive disclosure and cross-panel type intelligence",
    has_backend = true,
    clade_id = "typell",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "typeLL",
    msg_namespace = "typeLLMsg",
    view_route = "PanelTypeLL",
    module_name = "TypeLL",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
