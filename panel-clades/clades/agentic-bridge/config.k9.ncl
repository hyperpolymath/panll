# K9 Kennel: Agentic Bridge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "agentic-bridge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Agentic Bridge",
    short_name = "AgB",
    description = "Automated playtesting agents with OODA loop reasoning",
    has_backend = true,
    clade_id = "agentic-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "agenticBridge",
    msg_namespace = "agenticBridgeMsg",
    view_route = "PanelAgentic Bridge",
    module_name = "Agentic Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
