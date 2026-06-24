# K9 Kennel: Playgrounds Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "playgrounds-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Playgrounds",
    short_name = "Play",
    description = "Code sandbox, NQC console, tutorials",
    has_backend = true,
    clade_id = "playgrounds",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "playgrounds",
    msg_namespace = "playgroundsMsg",
    view_route = "PanelPlaygrounds",
    module_name = "Playgrounds",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
