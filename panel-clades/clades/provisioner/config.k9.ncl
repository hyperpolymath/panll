K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Provisioner Panel Configuration
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
      name = "provisioner-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Provisioner",
    short_name = "Prov",
    description = "Portfolio bundles, panel configuration, and isolation tier management",
    has_backend = false,
    clade_id = "provisioner",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "provisioner",
    msg_namespace = "provisionerMsg",
    view_route = "PanelProvisioner",
    module_name = "Provisioner",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
