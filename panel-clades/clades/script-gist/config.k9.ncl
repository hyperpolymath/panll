K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Script Gist Panel Configuration
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
      name = "script-gist-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Script Gist",
    short_name = "Gist",
    description = "Portable computation gists — Minskian diachronic scripts (time) and synchronic schemata (space) as cardfiles, LLM-callable via MCP",
    has_backend = false,
    clade_id = "script-gist",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "scriptGist",
    msg_namespace = "scriptGistMsg",
    view_route = "PanelScript Gist",
    module_name = "Script Gist",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
