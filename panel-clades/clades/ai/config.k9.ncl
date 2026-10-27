K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: AI Panel Configuration
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
      name = "ai-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "AI",
    short_name = "AI",
    description = "Multi-provider AI neural interface — Claude, Gemini, Mistral, GPT, local models",
    has_backend = true,
    clade_id = "ai",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "ai",
    msg_namespace = "aiMsg",
    view_route = "PanelAI",
    module_name = "AI",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
