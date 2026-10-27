K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Device Network Designer Panel Configuration
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
      name = "device-network-designer-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Device Network Designer",
    short_name = "DND",
    description = "Wire devices together, configure security levels and zones",
    has_backend = true,
    clade_id = "device-network-designer",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "deviceNetworkDesigner",
    msg_namespace = "deviceNetworkDesignerMsg",
    view_route = "PanelDevice Network Designer",
    module_name = "Device Network Designer",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
