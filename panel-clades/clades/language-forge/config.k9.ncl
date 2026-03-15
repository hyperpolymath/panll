# K9 Kennel: Language Forge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "language-forge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Language Forge",
    short_name = "Forge",
    description = "Monitor and develop the 14 nextgen-languages portfolio — scores, phases, WASM readiness",
    has_backend = false,
    clade_id = "language-forge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "languageForge",
    msg_namespace = "languageForgeMsg",
    view_route = "PanelLanguage Forge",
    module_name = "Language Forge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
