# K9 Kennel: Vexometer Friction Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "vexometer-friction-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "VexometerFriction",
    short_name = "VxF",
    description = "Vexometer friction — irritation surface measurements across tools",
    has_backend = true,
    clade_id = "vexometer-friction",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "vexometerFriction",
    msg_namespace = "vexometerFrictionMsg",
    view_route = "PanelVexometerFriction",
    module_name = "VexometerFriction",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
