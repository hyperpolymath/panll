K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Capture Panel Configuration
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
      name = "capture-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Capture",
    short_name = "Cap",
    description = "Screenshots, recordings, demos, panel cloning, and comparison views",
    has_backend = true,
    clade_id = "capture",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "capture",
    msg_namespace = "captureMsg",
    view_route = "PanelCapture",
    module_name = "Capture",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
