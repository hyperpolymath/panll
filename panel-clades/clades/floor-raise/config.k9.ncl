K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Floor Raise Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "panel-clade-config",
    security = {
      leash = 'Kennel,
      trust_level = "data-only",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
      capabilities = [],
    },
    metadata = {
      name = "floor-raise-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
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
