# K9 Kennel: Multiplayer Monitor Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "multiplayer-monitor-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Multiplayer Monitor",
    short_name = "MP",
    description = "Monitor Elixir/Phoenix sync server — WebSocket, channels, player state, Lamport clocks, latency",
    has_backend = true,
    clade_id = "multiplayer-monitor",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "multiplayerMonitor",
    msg_namespace = "multiplayerMonitorMsg",
    view_route = "PanelMultiplayer Monitor",
    module_name = "Multiplayer Monitor",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
