# K9 Kennel: panic-attack Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "panic-attack-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "panic-attack",
    short_name = "PA",
    description = "Stress testing and logic-based bug signature detection — 47 languages, 20 categories",
    has_backend = true,
    clade_id = "panic-attack",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "panicAttack",
    msg_namespace = "panicAttackMsg",
    view_route = "Panelpanic-attack",
    module_name = "panic-attack",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
