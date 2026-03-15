# K9 Kennel: Database Bridge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "database-bridge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Database Bridge",
    short_name = "DbB",
    description = "VeriSimDB game state persistence and query bridge",
    has_backend = true,
    clade_id = "database-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "databaseBridge",
    msg_namespace = "databaseBridgeMsg",
    view_route = "PanelDatabase Bridge",
    module_name = "Database Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
