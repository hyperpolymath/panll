# K9 Kennel: 7-Tentacles Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "tentacles-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "7-Tentacles",
    short_name = "Tentacles",
    description = "Compiler agent orchestra — 7 colour-coded agents with OODA reasoning, progressive cephalopod staging, and ECHIDNA FFI bridge",
    has_backend = true,
    clade_id = "tentacles",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "tentacles",
    msg_namespace = "tentaclesMsg",
    view_route = "Panel7-Tentacles",
    module_name = "7-Tentacles",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
