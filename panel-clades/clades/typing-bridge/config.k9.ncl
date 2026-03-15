# K9 Kennel: Typing Bridge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "typing-bridge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
