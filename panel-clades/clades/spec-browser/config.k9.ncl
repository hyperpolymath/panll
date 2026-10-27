K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Spec Browser Panel Configuration
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
      name = "spec-browser-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Spec Browser",
    short_name = "Spec",
    description = "Browse all 16 language specs, grammars, typing rules — side-by-side comparison and taxonomy completeness",
    has_backend = false,
    clade_id = "spec-browser",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "specBrowser",
    msg_namespace = "specBrowserMsg",
    view_route = "PanelSpec Browser",
    module_name = "Spec Browser",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
