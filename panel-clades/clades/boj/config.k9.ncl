# K9 Kennel: BoJ Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "boj-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "BoJ",
    short_name = "BoJ",
    description = "Bundle of Joy — unified cartridge server with 17 domains (incl. LSP/DAP/BSP), 3-layer ABI/FFI/Adapter, Umoja federation",
    has_backend = true,
    clade_id = "boj",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "boj",
    msg_namespace = "bojMsg",
    view_route = "PanelBoJ",
    module_name = "BoJ",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
