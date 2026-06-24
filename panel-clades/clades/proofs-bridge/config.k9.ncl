# K9 Kennel: Proofs Bridge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "proofs-bridge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Proofs Bridge",
    short_name = "PfB",
    description = "Proven repo formal verification integration bridge",
    has_backend = true,
    clade_id = "proofs-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "proofsBridge",
    msg_namespace = "proofsBridgeMsg",
    view_route = "PanelProofs Bridge",
    module_name = "Proofs Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
