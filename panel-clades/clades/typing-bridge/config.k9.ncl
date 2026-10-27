K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Typing Bridge Panel Configuration
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
      name = "typing-bridge-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Typing Bridge",
    short_name = "TyB",
    description = "TypeLL type constraints for game state — cross-panel type intelligence bridge",
    has_backend = true,
    clade_id = "typing-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "typingBridge",
    msg_namespace = "typingBridgeMsg",
    view_route = "PanelTyping Bridge",
    module_name = "Typing Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
