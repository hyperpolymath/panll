# K9 Kennel: Scripting Bridge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "scripting-bridge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Scripting Bridge",
    short_name = "ScB",
    description = "VM instruction scripting REPL for game logic development",
    has_backend = true,
    clade_id = "scripting-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "scriptingBridge",
    msg_namespace = "scriptingBridgeMsg",
    view_route = "PanelScripting Bridge",
    module_name = "Scripting Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
