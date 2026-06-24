# K9 Kennel: Neurosymbolic Bridge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "neurosym-bridge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Neurosymbolic Bridge",
    short_name = "NsB",
    description = "Guard AI behaviour reasoning via ECHIDNA neurosymbolic integration",
    has_backend = true,
    clade_id = "neurosym-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "neurosymBridge",
    msg_namespace = "neurosymBridgeMsg",
    view_route = "PanelNeurosymbolic Bridge",
    module_name = "Neurosymbolic Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
