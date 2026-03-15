# K9 Kennel: Hypatia Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "hypatia-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Hypatia",
    short_name = "Hyp",
    description = "Neurosymbolic CI/CD intelligence",
    has_backend = true,
    clade_id = "hypatia",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "hypatia",
    msg_namespace = "hypatiaMsg",
    view_route = "PanelHypatia",
    module_name = "Hypatia",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
