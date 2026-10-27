K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: VM Inspector Panel Configuration
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
      name = "vm-inspector-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "VM Inspector",
    short_name = "VM",
    description = "Reversible VM visual debugger — stack, memory, instructions, step forward and backward",
    has_backend = true,
    clade_id = "vm-inspector",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "vmInspector",
    msg_namespace = "vmInspectorMsg",
    view_route = "PanelVM Inspector",
    module_name = "VM Inspector",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
