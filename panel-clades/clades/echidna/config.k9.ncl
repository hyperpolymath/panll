# K9 Kennel: ECHIDNA Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "echidna-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "ECHIDNA",
    short_name = "ECH",
    description = "Multi-solver theorem prover — proof dispatch, tactic suggestions, enterprise model checking",
    has_backend = true,
    clade_id = "echidna",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "echidna",
    msg_namespace = "echidnaMsg",
    view_route = "PanelECHIDNA",
    module_name = "ECHIDNA",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
