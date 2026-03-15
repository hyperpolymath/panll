# K9 Kennel: Script Gist Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "script-gist-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
