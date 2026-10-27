K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Repo Loader Panel Configuration
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
      name = "repoloader-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Repo Loader",
    short_name = "Repo",
    description = "Repository scanner and panel configuration — load a repo, configure panels",
    has_backend = true,
    clade_id = "repoloader",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "repoLoader",
    msg_namespace = "repoLoaderMsg",
    view_route = "PanelRepo Loader",
    module_name = "Repo Loader",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
