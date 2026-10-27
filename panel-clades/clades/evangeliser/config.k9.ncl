K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Evangeliser Panel Configuration
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
      name = "evangeliser-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Evangeliser",
    short_name = "Evan",
    description = "ReScript Evangeliser — JS-to-ReScript transformation teaching with 52 patterns, Makaton glyphs, and celebrate/minimize/better narratives",
    has_backend = false,
    clade_id = "evangeliser",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "evangeliser",
    msg_namespace = "evangeliserMsg",
    view_route = "PanelEvangeliser",
    module_name = "Evangeliser",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
