K9!
# SPDX-License-Identifier: MPL-2.0
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
      name = "gsa-browser-config",
      version = "1.0.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "GsaServerBrowser",
    short_name = "Servers",
    description = "Discover and fingerprint game servers",
    has_backend = true,
    clade_id = "gsa-browser",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaBrowser",
    msg_namespace = "gsaBrowserMsg",
    view_route = "PanelGsaServerBrowser",
    module_name = "GsaBrowser",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
