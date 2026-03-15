# K9 Kennel: Functional Tester Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "functional-tester-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Functional Tester",
    short_name = "FT",
    description = "End-to-end game workflow simulation and assertion checking",
    has_backend = true,
    clade_id = "functional-tester",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "functionalTester",
    msg_namespace = "functionalTesterMsg",
    view_route = "PanelFunctional Tester",
    module_name = "Functional Tester",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
