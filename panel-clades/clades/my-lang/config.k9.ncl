# K9 Kennel: My-Lang Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "my-lang-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "My-Lang",
    short_name = "My-Lang",
    description = "AI-native language workbench — 4 dialects (Solo, Duet, Ensemble, Me), REPL, compiler, and LSP integration",
    has_backend = true,
    clade_id = "my-lang",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "myLang",
    msg_namespace = "myLangMsg",
    view_route = "PanelMy-Lang",
    module_name = "My-Lang",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
