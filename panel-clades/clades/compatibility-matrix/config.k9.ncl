K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Compatibility Matrix Panel Configuration
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
      name = "compatibility-matrix-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Compatibility Matrix",
    short_name = "Compat",
    description = "Browser, device, and resolution test matrix management",
    has_backend = true,
    clade_id = "compatibility-matrix",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "compatibilityMatrix",
    msg_namespace = "compatibilityMatrixMsg",
    view_route = "PanelCompatibility Matrix",
    module_name = "Compatibility Matrix",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
