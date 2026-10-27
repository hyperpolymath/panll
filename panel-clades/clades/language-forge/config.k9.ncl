K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Language Forge Panel Configuration
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
      name = "language-forge-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
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
