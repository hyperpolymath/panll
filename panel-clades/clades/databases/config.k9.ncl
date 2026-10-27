K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Databases Panel Configuration
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
      name = "databases-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Databases",
    short_name = "DB",
    description = "VeriSimDB, QuandleDB, LithoGlyph management",
    has_backend = true,
    clade_id = "databases",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "databases",
    msg_namespace = "databasesMsg",
    view_route = "PanelDatabases",
    module_name = "Databases",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
