K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: CloudGuard Panel Configuration
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
      name = "cloudguard-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "CloudGuard",
    short_name = "CG",
    description = "Cloudflare domain security management",
    has_backend = true,
    clade_id = "cloudguard",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "cloudGuard",
    msg_namespace = "cloudGuardMsg",
    view_route = "PanelCloudGuard",
    module_name = "CloudGuard",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
