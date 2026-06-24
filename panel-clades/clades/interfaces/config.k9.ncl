# K9 Kennel: Interfaces Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "interfaces-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Interfaces",
    short_name = "FFI",
    description = "Language bridges, ABI/FFI inventory",
    has_backend = false,
    clade_id = "interfaces",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "interfaces",
    msg_namespace = "interfacesMsg",
    view_route = "PanelInterfaces",
    module_name = "Interfaces",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
