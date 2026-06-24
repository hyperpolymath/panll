# K9 Kennel: Device Network Designer Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "device-network-designer-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
