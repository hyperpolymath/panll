# K9 Kennel: Network Topology Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "network-topology-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Network Topology",
    short_name = "Topo",
    description = "Force-directed graph of IDApTIK in-game network — devices, zones, security levels, packet flow",
    has_backend = true,
    clade_id = "network-topology",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "networkTopology",
    msg_namespace = "networkTopologyMsg",
    view_route = "PanelNetwork Topology",
    module_name = "Network Topology",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
