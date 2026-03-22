# SPDX-License-Identifier: PMPL-1.0-or-later
# Abstract game profile clade — children inherit this configuration
{
  pedigree = {
    name = "gsa-game-config",
    version = "1.0.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "GsaGame",
    short_name = "Game",
    description = "Abstract parent for game server profiles — inherit, do not instantiate directly",
    has_backend = true,
    clade_id = "gsa-game",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "",
    msg_namespace = "",
    view_route = "",
    module_name = "",
    # Abstract — no wiring. Children provide their own via profile A2ML.
  },
  obligations = {
    requires_tests = false,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
