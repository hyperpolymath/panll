# K9 Kennel: Floor Raise Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "floor-raise-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "FloorRaise",
    short_name = "FR",
    description = "Floor Raise campaign — foundational tool adoption dashboard",
    has_backend = true,
    clade_id = "floor-raise",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "floorRaise",
    msg_namespace = "floorRaiseMsg",
    view_route = "PanelFloorRaise",
    module_name = "FloorRaise",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
