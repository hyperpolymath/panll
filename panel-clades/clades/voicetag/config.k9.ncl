K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Code MRI Panel Configuration
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
      name = "voicetag-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Code MRI",
    short_name = "MRI",
    description = "Voice-activated code annotation — tags stored as portable .mri.json sidecars",
    has_backend = false,
    clade_id = "voicetag",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "codeMri",
    msg_namespace = "codeMriMsg",
    view_route = "PanelCode MRI",
    module_name = "Code MRI",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
