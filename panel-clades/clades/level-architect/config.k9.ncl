# K9 Kennel: Level Architect Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "level-architect-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Level Architect",
    short_name = "Lvl",
    description = "Visual level design — device placement, guard patrols, defence flags, validation, LevelConfig export",
    has_backend = true,
    clade_id = "level-architect",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "levelArchitect",
    msg_namespace = "levelArchitectMsg",
    view_route = "PanelLevel Architect",
    module_name = "Level Architect",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
