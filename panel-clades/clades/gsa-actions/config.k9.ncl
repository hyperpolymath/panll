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
      name = "gsa-actions-config",
      version = "1.0.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "GsaServerActions",
    short_name = "Actions",
    description = "Start/stop/restart game servers with confirmation",
    has_backend = true,
    clade_id = "gsa-actions",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gsaActions",
    msg_namespace = "gsaActionsMsg",
    view_route = "PanelGsaServerActions",
    module_name = "GsaActions",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
