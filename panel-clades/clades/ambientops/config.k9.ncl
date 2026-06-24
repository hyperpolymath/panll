# K9 Kennel: AmbientOps Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "ambientops-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "AmbientOps",
    short_name = "Ops",
    description = "Hospital-model sysadmin — clinician, network ambulance, hardware crash team, emergency room",
    has_backend = true,
    clade_id = "ambientops",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "ambientOps",
    msg_namespace = "ambientOpsMsg",
    view_route = "PanelAmbientOps",
    module_name = "AmbientOps",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
