# K9 Kennel: Protocol-Squisher Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "protocol-squisher-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Protocol-Squisher",
    short_name = "Squisher",
    description = "13-format schema analysis — transport class classification, compatibility comparison, adapter cost estimation",
    has_backend = true,
    clade_id = "protocol-squisher",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "protocolSquisher",
    msg_namespace = "protocolSquisherMsg",
    view_route = "PanelProtocol-Squisher",
    module_name = "Protocol-Squisher",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
