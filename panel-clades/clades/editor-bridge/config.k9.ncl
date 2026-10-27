K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Editor Bridge Panel Configuration
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
      name = "editor-bridge-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Editor Bridge",
    short_name = "EB",
    description = "Federate with external code editors — LSP diagnostics, symbols, open files, jump-to-line",
    has_backend = true,
    clade_id = "editor-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "editorBridge",
    msg_namespace = "editorBridgeMsg",
    view_route = "PanelEditor Bridge",
    module_name = "Editor Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
